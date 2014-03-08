require 'spec_helper'

describe BtcUtils::Convert do

  describe '.btc_to_satoshi' do

    it '0.0000 0001 BTC => 1 Satoshi' do
      expect(BtcUtils::Convert.btc_to_satoshi 0.000_000_01).to be(1)
    end

    it '42 BTC => 42 0000 0000 Satoshis' do
      expect(BtcUtils::Convert.btc_to_satoshi 42.0).to be(42_0000_0000)
    end

  end

  describe '.satoshi_to_btc' do

    it '1 Satoshi => 0.0000 0001 BTC' do
      expect(BtcUtils::Convert.satoshi_to_btc 1).to eq(0.0000_0001)
    end

    it '6,6733,8923 Satoshis => 6.6733 8923 BTC' do
      expect(BtcUtils::Convert.satoshi_to_btc 6_6733_8923).to eq(6.6733_8923)
    end

  end

end

