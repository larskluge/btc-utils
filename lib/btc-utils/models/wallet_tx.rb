class BtcUtils::Models::WalletTx
  attr_reader :raw

  def self.find id
    begin
      self.new BtcUtils.client.transaction id
    rescue Bitcoin::Errors::RPCError => e
      msg = JSON.parse(e.message.gsub('=>', ':'))['message']
      if msg =~ /\AInvalid or non-wallet transaction id\z/
        nil
      else
        raise
      end
    end
  end


  def initialize raw
    @raw = raw
  end

  def id
    @raw['txid']
  end

  def amount
    BtcUtils::Convert.btc_to_satoshi @raw['amount']
  end

  def category
    if amount > 0
      :received
    else
      :sent
    end
  end

  def addresses
    @raw['details'].map { |detail| detail['address'] }.uniq
  end

  def address
    if addresses.size == 1
      addresses.first
    else
      fail "Multiple wallet addresses involved #{self.inspect}"
    end
  end

end

