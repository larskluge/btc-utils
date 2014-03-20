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

    Log.info context: 'TxBuilder', to: to, change_address: change_address, opts: opts

    case opts[:required_spent]
    when String
      @required_spent_txid = opts[:required_spent]
    when Array
      @required_spent_txid, @required_spent_idx = opts[:required_spent]
    end

    @only_spend_from_address = opts[:only_spend_from_address]
  end

  def amount
    @to.values.sum
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

  # Estimates the tx size by the following formular:
  #
  # size in bytes = 148 * number_of_inputs + 34 * number_of_outputs + 10
  #
  # for_n_inputs
  #
  def estimated_size for_n_inputs = nil
    # to addresses + 1 for change
    number_of_outputs = @to.keys.size + 1
    number_of_inputs  = for_n_inputs || selected_inputs.size

    148 * number_of_inputs + 34 * number_of_outputs + 10
  end

  # fee calulation is based on tx size *only*
  #
  # it always includes at least the minimum tx fee
  #
  # MIN_FEE per 1,000 bytes
  #
  def fee for_n_inputs = nil
    (estimated_size(for_n_inputs) / 1_000 + 1) * MIN_FEE
  end

  def send!
    tx_param = selected_inputs.map { |utxout| {txid: utxout.txid, vout: utxout.vout} }
    # address_param = to.dup{to => BtcUtils::Convert.satoshi_to_btc(amount), change_address => BtcUtils::Convert.satoshi_to_btc(change_amount)}
    address_param = to.inject({}) do |h,(address, amount)|
      h[address] = BtcUtils::Convert.satoshi_to_btc(amount)
      h
    end
    address_param[change_address] = BtcUtils::Convert.satoshi_to_btc(change_amount) if change_amount > 0

    Log.info total_amount_selected: selected_amount, total_out: BtcUtils::Convert.btc_to_satoshi(address_param.values.sum), change_amount: change_amount, tx_param: tx_param, address_param: address_param

    # createrawtransaction [{"txid":txid,"vout":n},...] {address:amount,...}
    raw_tx = BtcUtils.client.api.request 'createrawtransaction', tx_param, address_param
    Log.info 'createrawtransaction', raw_tx: raw_tx

    resp = BtcUtils.client.api.request 'signrawtransaction', raw_tx
    Log.info 'signrawtransaction', response: resp
    signed_raw_tx = resp['hex']

    if resp['complete']
      txid = BtcUtils.client.api.request 'sendrawtransaction', signed_raw_tx, false
      Log.info 'Transaction successfully submitted', txid: txid
    else
      fail "Signing process failed with #{resp.inspect}"
    end
  end

end

