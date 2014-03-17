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

  def selected_inputs
    @selected_inputs ||= begin
      Log.info unspent_count: unspent_list.size

      unspent_list.mark_required_spent!(required_spent_txid, required_spent_idx) if required_spent_txid

      utxouts = unspent_list.select_for_amount amount, only_address: @only_spend_from_address
      Log.info spend_select_count: utxouts.size
      utxouts
    end
  end

  def selected_amount
    selected_inputs.sum(&:amount)
  end

  def change_amount
    selected_amount - amount - fee
  end

  # 148 * number_of_inputs + 34 * number_of_outputs + 10
  #
  def estimated_size
    # probably there always will be a change output; can't call #change_amount or would end up in recursion
    number_of_outputs = 2

    148 * selected_inputs.size + 34 * number_of_outputs + 10
  end

  # fee calulation is based on tx size *only*
  #
  # it always includes at least the minimum tx fee
  #
  # MIN_FEE per 1,000 bytes
  #
  def fee
    (estimated_size / 1_000 + 1) * MIN_FEE
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

