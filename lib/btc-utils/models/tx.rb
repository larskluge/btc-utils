class BtcUtils::Models::Tx
  attr_reader :raw

  def self.find id
    self.new BtcUtils.client.raw_decoded_tx id
  end


  def initialize raw
    @raw = raw
  end

  def id
    @raw['txid']
  end

  def in
    @in ||= @raw['vin'].map do |input|
      BtcUtils::Models::TxIn.new input
    end
  end

  def out
    @out ||= @raw['vout'].map do |output|
      BtcUtils::Models::TxOut.new self, output
    end
  end

  def out_at idx
    out.detect { |txout| txout.idx == idx }
  end

  def total_in
    self.in.sum { |txin| txin.tx.out_at(txin.idx).amount }
  end

  def total_out
    self.out.sum(&:amount)
  end

  def fee
    total_in - total_out
  end

  # 148 * number_of_inputs + 34 * number_of_outputs + 10
  #
  # in bytes
  #
  def size
    148 * self.in.size + 34 * self.out.size + 10
  end

  def estimated_from_address
    addresses = self.in.map(&:estimated_from_address).uniq
    if addresses.size == 1
      addresses.first
    else
      fail "ambiguous; multiple different input addresses: #{addresses.inspect}"
    end
  end

  def wallet_tx
    @wallet_tx ||= BtcUtils::Models::WalletTx.find(id)
  end

  def wallet_tx?
    !!wallet_tx
  end

end

