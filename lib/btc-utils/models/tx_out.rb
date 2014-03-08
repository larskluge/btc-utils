class BtcUtils::Models::TxOut
  attr_reader :parent_tx

  def initialize parent_tx, raw
    @parent_tx = parent_tx
    @raw = raw
  end

  def amount
    BtcUtils::Convert.btc_to_satoshi @raw['value']
  end

  def idx
    @raw['n']
  end

  def addresses
    @raw['scriptPubKey']['addresses']
  end

  def spent?
    resp = BtcUtils.client.tx_out @parent_tx.id, idx
    !resp
  end

end

