class BtcUtils::Models::UnspentTxOut
  attr_reader :raw
  attr_accessor :required_spent

  def initialize raw
    @raw = raw
    self.required_spent = false
  end

  %w(txid vout address scriptPubKey confirmations).each do |m|
    define_method m do
      @raw[m]
    end
  end

  def amount
    BtcUtils::Convert.btc_to_satoshi @raw['amount']
  end

end

