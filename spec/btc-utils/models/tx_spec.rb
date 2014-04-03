require 'spec_helper'

describe BtcUtils::Models::Tx do

  let(:transaction_42_mbtc) { BtcUtils::Models::Tx.find('e6b64534b48c1ace27b987859ab6112f2835b0656f79080cf9f81697f115c20a') }


  describe '.find' do

    it 'returns a transaction' do
      t = BtcUtils::Models::Tx.find('e6b64534b48c1ace27b987859ab6112f2835b0656f79080cf9f81697f115c20a')
      expect(t).to be_kind_of(BtcUtils::Models::Tx)
    end

    it 'raises RPCError if transaction not found' do
      expect {
        BtcUtils::Models::Tx.find('doesnotexist')
      }.to raise_error(Bitcoin::Errors::RPCError)
    end

  end


  describe '#id' do

    it 'returns correct transaction id hash' do
      expect(transaction_42_mbtc.id).to eq('e6b64534b48c1ace27b987859ab6112f2835b0656f79080cf9f81697f115c20a')
    end

  end

  describe '#in' do

    it 'has only one input' do
      expect(transaction_42_mbtc.in.size).to be(1)
    end

    it 'entries are of type TxIn' do
      expect(transaction_42_mbtc.in.first).to be_kind_of(BtcUtils::Models::TxIn)
    end

  end

  describe '#out' do

    it 'has two outputs' do
      expect(transaction_42_mbtc.out.size).to be(2)
    end

    it 'entries are of type TxOut' do
      expect(transaction_42_mbtc.out.first).to be_kind_of(BtcUtils::Models::TxOut)
    end

  end

  describe '#size' do

    it 'calculates properly' do
      expect(transaction_42_mbtc.size).to eq(148 + 34 * 2 + 10) # 1 x in, 2 x out
    end

  end

  describe '#total_in' do

    it 'is 19.9984 BTC' do
      expect(transaction_42_mbtc.total_in).to eq(19_9984_0000)
    end

  end

  describe '#total_out' do

    it 'is 19.9983 BTC' do
      expect(transaction_42_mbtc.total_out).to eq(19_9983_0000)
    end

  end

  describe '#fee' do

    it 'is 0.0001 BTC' do
      expect(transaction_42_mbtc.fee).to eq(1_0000)
    end

  end

  describe '#estimated_from_address' do

    it 'is mkmJwhCQV4Xu4aJ7CHLyuwAeNpS371oLqt' do
      expect(transaction_42_mbtc.estimated_from_address).to eq('mkmJwhCQV4Xu4aJ7CHLyuwAeNpS371oLqt')
    end

  end

end

