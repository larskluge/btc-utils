class BtcUtils::Models::TxBuilder
  MIN_FEE = 1_0000 # satoshis

  attr_reader :to, :amount, :change_address, :required_spent_txid


  # to: {address => amount, another_address => amount, ...}
  #
  # amount in satoshis
  #
  def initialize to, change_address, opts = {}
    @to = to
    @change_address = change_address

    Log.info context: 'TxBuilder#initialize', to: to, change_address: change_address, opts: opts

    case opts[:required_spent]
    when String
      @required_spent_txid = opts[:required_spent]
    when Array
      @required_spent_txid, @required_spent_idx = opts[:required_spent]
    end

    @only_spend_from_address = opts[:only_spend_from_address]
  end

  def amount
    to.values.sum
  end

  # amount incl fee
  #
  def total_amount
    amount + fee
  end

  def unspent_list
    @unspent_list ||= BtcUtils::Models::UnspentList.create
  end

  def required_spent_idx
    @required_spent_idx ||= begin
      if @required_spent_txid
        outs = unspent_list.select { |utxout| utxout.txid == required_spent_txid }
        if outs.size == 1
          outs.first.vout
        else
          fail "#TxBuilder#required_spent_idx: Many potential transactions found, abort! #{outs.inspect}"
        end
      end
    end
  end

  def selected_inputs estimated_number_of_inputs = 2
    @selected_inputs ||= begin
      Log.info context: 'TxBuilder#selected_inputs', unspent_count: unspent_list.size, estimated_number_of_inputs: estimated_number_of_inputs

      unspent_list.mark_required_spent!(required_spent_txid, required_spent_idx) if required_spent_txid

      utxouts = unspent_list.select_for_amount amount + fee(estimated_number_of_inputs), only_address: @only_spend_from_address
      Log.info spend_select_count: utxouts.size
      if estimated_number_of_inputs != utxouts.size
        Log.info msg: 'Estimated number of inputs is wrong, recalculating', context: 'TxBuilder#selected_inputs', estimated_number_of_inputs: estimated_number_of_inputs, number_of_selected_inputs: utxouts.size
        selected_inputs utxouts.size
      else
        utxouts
      end
    end
  end

  def selected_amount
    selected_inputs.sum(&:amount)
  end

  def change_amount
    selected_amount - amount - fee
  end

  def number_of_inputs
    selected_inputs.size
  end

  # number of to addresses + 1 for change
  #
  def number_of_outputs
    to.keys.size + 1
  end

  # Estimates the tx size by the following formular:
  #
  # size in bytes = 148 * number_of_inputs + 34 * number_of_outputs + 10
  #
  # overwrite_n_inputs
  #
  def estimated_size overwrite_n_inputs = nil
    148 * (overwrite_n_inputs or number_of_inputs) + 34 * number_of_outputs + 10
  end

  # fee calulation is based on tx size *only*
  #
  # it always includes at least the minimum tx fee
  #
  # MIN_FEE per 1,000 bytes
  #
  def fee overwrite_n_inputs = nil
    (estimated_size(overwrite_n_inputs) / 1_000 + 1) * MIN_FEE
  end

  def tx_params
    selected_inputs.map { |utxout| {txid: utxout.txid, vout: utxout.vout} }
  end

  def address_params
    res = to.inject({}) do |h,(address, amount)|
      h[address] = BtcUtils::Convert.satoshi_to_btc(amount)
      h
    end
    res[change_address] = BtcUtils::Convert.satoshi_to_btc(change_amount) if change_amount > 0
    res
  end

  def check_fee!
    total_amount_of_inputs  = tx_params.sum { |tx| unspent_list.find(tx[:txid], tx[:vout]).amount }
    total_amount_of_outputs = address_params.values.sum { |btc| BtcUtils::Convert.btc_to_satoshi(btc) }
    fee = total_amount_of_inputs - total_amount_of_outputs

    if fee > MIN_FEE * 10
      fail "There is something wrong with the fee"
    else
      true
    end
  end

  def send!
    check_fee!
    Log.info context: 'TxBuilder#send!', total_amount_selected: selected_amount, total_out: BtcUtils::Convert.btc_to_satoshi(address_params.values.sum), change_amount: change_amount, tx_params: tx_params, address_params: address_params

    # createrawtransaction [{"txid":txid,"vout":n},...] {address:amount,...}
    raw_tx = BtcUtils.client.api.request 'createrawtransaction', tx_params, address_params
    Log.info 'createrawtransaction', context: 'TxBuilder#send!', raw_tx: raw_tx

    resp = BtcUtils.client.api.request 'signrawtransaction', raw_tx
    Log.info 'signrawtransaction', context: 'TxBuilder#send!', signed_tx: resp
    signed_raw_tx = resp['hex']

    if resp['complete']
      txid = BtcUtils.client.api.request 'sendrawtransaction', signed_raw_tx
      Log.info 'Transaction successfully submitted', context: 'TxBuilder#send!', txid: txid
    else
      fail "Signing process failed with #{resp.inspect}"
    end
  end

end

