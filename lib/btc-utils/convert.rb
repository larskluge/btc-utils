module BtcUtils::Convert

  def self.btc_to_satoshi btc
    (btc * 1_0000_0000).round
  end

  def self.satoshi_to_btc satoshis
    satoshis / 1_0000_0000.0
  end

end

