class BtcUtils::Models::TxOut

  def initialize raw
    @raw = raw
  end

  def id
    @raw['txid']
  end

  def tx
    @tx ||= BtcUtils::Models::Tx.find id
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

end

