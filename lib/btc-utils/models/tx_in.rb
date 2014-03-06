class BtcUtils::Models::TxIn

  def initialize raw
    @raw = raw
  end

  def id
    @raw['txid']
  end

  def tx
    @tx ||= Tx.find id
  end

  def idx
    @raw['vout']
  end

  def estimated_from_address
    as = tx.out_at(idx).addresses
    if as.size == 1
      as.first
    else
      raise "Multiple addresses found! #{as.inspect}"
    end
  end

end

