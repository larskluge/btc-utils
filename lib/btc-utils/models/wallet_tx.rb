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
    @raw['amount']
    # ds = @raw['details']
    # if ds.size == 1
    #   BtcUtils::Convert.btc_to_satoshi ds.first['amount']
    # else
    #   raise @raw.inspect
    # end
  end


end

