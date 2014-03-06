class BtcUtils::Models::TxOut

  def initialize raw
    @raw = raw
  end

  def id
    @raw['txid']
  end

  def tx
    @tx ||= Tx.find id
  end

  def amount
    (@raw['value'].to_f * 100_000_000).round
  end

  def idx
    @raw['n']
  end

  def addresses
    @raw['scriptPubKey']['addresses']
  end

end

