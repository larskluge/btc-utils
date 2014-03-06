class BtcUtils::Models::Tx
  attr_reader :raw

  def self.find id
    self.new $bitcoin_client.raw_transaction id
  end


  def initialize raw
    @raw = raw
  end

  def id
    @raw['txid']
  end

  def in
    @raw['vin'].map do |input|
      TxIn.new input
    end
  end

  def out only_idx = nil
    @out ||= @raw['vout'].map do |output|
      TxOut.new output
    end

    if only_idx
      @out.select { |txout| txout.idx == only_idx }
    else
      @out
    end
  end

  def out_at idx
    out.detect { |txout| txout.idx == idx }
  end

  def vin
    @raw['vin']
  end

  def vout
    @raw['vout']
  end

  def total_in
    self.in.sum { |txin| txin.tx.total_out txin.idx }
  end

  def total_out only_idx = nil
    self.out(only_idx).sum(&:amount)
  end

  def fee
    total_in - total_out
  end

end

