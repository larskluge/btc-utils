require 'spec_helper'

describe BtcUtils::Models::TxBuilder do

  let(:change_address) { 'myV2smAaVzYfRAtbfuwQ6ePJJXRRquUCMm' }
  let(:listunspent3) { amounts = [1.0, 2.0, 3.0]; listunspent.map { |utxout| utxout.merge('amount' => amounts.shift) } }
  let(:listunspent) { JSON.parse(<<-END) }
[
  {
      "txid" : "bbf56db603a9e375773182d0dd7c9dc439170bf7f3b05ab73713a7c1b84973e5",
      "vout" : 0,
      "address" : "mjarwx1WtETteGo3Vx9YVWGz3pxxuW246z",
      "account" : "",
      "scriptPubKey" : "76a9142c9db42ea80320c5e901dd30d07855478d34ba0d88ac",
      "amount" : 0.12200000,
      "confirmations" : 2
  },
  {
      "txid" : "dfed6d905cff2b9a7fd3fdb6a805fbbac0065d0781210ce5346ce934761cf446",
      "vout" : 3,
      "address" : "mpot8pmoPzBczjUbKnwRXinvMBzpNidBsQ",
      "account" : "",
      "scriptPubKey" : "76a91465ecbb460ab84c0884452c33bdf0d36d2ff76eb888ac",
      "amount" : 0.02949958,
      "confirmations" : 13
  },
  {
      "txid" : "dfed6d905cff2b9a7fd3fdb6a805fbbac0065d0781210ce5346ce934761cf447",
      "vout" : 2,
      "address" : "mpot8pmoPzBczjUbKnwRXinvMBzpNidBsQ",
      "account" : "",
      "scriptPubKey" : "76a91465ecbb460ab84c0884452c33bdf0d36d2ff76eb888ac",
      "amount" : 1.02949958,
      "confirmations" : 20
  }
]
END

  def tx to, opts = {}
    unspent_list = opts.delete(:listunspent) || listunspent
    t = BtcUtils::Models::TxBuilder.new to, 'change_address', opts
    t.instance_variable_set(:@unspent_list, BtcUtils::Models::UnspentList.new(unspent_list))
    t.check_fee!
    t
  end



  describe '#selected_inputs' do

    it 'selects enough funds to also pay tx fee' do
      to = {'mprjctVh1kUPUAGMg9AoCBTtNkwzkhA13P' => 854_0000, 'mhouseyRNBMq23DjUANB6jvywA4zzEeyTJ' => 6_1000, 'mkmJwhCQV4Xu4aJ7CHLyuwAeNpS371oLqt' => 42, 'mpot8pmoPzBczjUbKnwRXinvMBzpNidBsQ' => 359_8958}
      tx = BtcUtils::Models::TxBuilder.new to, change_address,
        required_spent: ['bbf56db603a9e375773182d0dd7c9dc439170bf7f3b05ab73713a7c1b84973e5', 0],
        only_spend_from_address: 'mpot8pmoPzBczjUbKnwRXinvMBzpNidBsQ'

      tx.instance_variable_set(:@unspent_list, BtcUtils::Models::UnspentList.new(listunspent))

      expect(tx.fee).to be(1_0000)
      expect(tx.amount).to be(1220_0000)

      expect(tx.selected_amount).to be >= 1221_0000
      expect(tx.selected_inputs.size).to be(2)
      expect(tx.total_amount).to be(1221_0000)
    end

    it 'still ends recursion if started with wrong parameter' do
      to = {'mprjctVh1kUPUAGMg9AoCBTtNkwzkhA13P' => 854_0000, 'mhouseyRNBMq23DjUANB6jvywA4zzEeyTJ' => 6_1000, 'mkmJwhCQV4Xu4aJ7CHLyuwAeNpS371oLqt' => 42, 'mpot8pmoPzBczjUbKnwRXinvMBzpNidBsQ' => 359_8958}
      tx = BtcUtils::Models::TxBuilder.new to, change_address
      tx.instance_variable_set(:@unspent_list, BtcUtils::Models::UnspentList.new(listunspent))

      expect(tx.selected_inputs(-1).size).to be(2)
    end

  end

  describe '#amount' do

    it 'has one recipient' do
      expect(tx('foo' => 42).amount).to be 42
    end

    it 'has 3 recipients' do
      expect(tx('foo' => 42, 'bar' => 1_0000_0000, 'baz' => 256_0000).amount).to be 1_0256_0042
    end

  end

  describe '#fee' do

    it 'has minimum fee due to low # of inputs and outputs' do
      t = tx({'foo' => 5000_0000}, listunspent: listunspent3)
      expect(t.number_of_inputs).to be 1
      expect(t.number_of_outputs).to be 2 # one for the change
      expect(t.change_amount).to be 4999_0000
      expect(t.fee).to be 1_0000 # min fee
    end

    it 'has exceeds the min fee due to 1,000 byte tx size limit' do
      to = 40.times.inject({}){|h| h[rand(36**4).to_s(36)] = 42; h}
      t = tx(to, listunspent: listunspent3)
      expect(t.fee).to be 2_0000
    end

  end

  describe '#tx_params' do

    it 'spends only the first input' do
      t = tx({'foo' => 5000_0000}, listunspent: listunspent3)
      expect(t.tx_params).to eq([{txid: 'bbf56db603a9e375773182d0dd7c9dc439170bf7f3b05ab73713a7c1b84973e5', vout: 0}])
    end

    it 'spends both inputs' do
      t = tx({'bar' => 2_5000_0000}, listunspent: listunspent3)
      expect(t.tx_params).to eq([{txid: 'bbf56db603a9e375773182d0dd7c9dc439170bf7f3b05ab73713a7c1b84973e5', vout: 0}, {txid: 'dfed6d905cff2b9a7fd3fdb6a805fbbac0065d0781210ce5346ce934761cf446', vout: 3}])
    end

    it 'spends exactly the first input amount' do
      t = tx({'foo' => 1_0000_0000}, listunspent: listunspent3)
      expect(t.tx_params).to eq([{txid: 'bbf56db603a9e375773182d0dd7c9dc439170bf7f3b05ab73713a7c1b84973e5', vout: 0}, {txid: 'dfed6d905cff2b9a7fd3fdb6a805fbbac0065d0781210ce5346ce934761cf446', vout: 3}])
    end

    context 'with required_spent' do

      it 'spends only the second input since its required' do
        t = tx({'foo' => 5000_0000}, listunspent: listunspent3, required_spent: 'dfed6d905cff2b9a7fd3fdb6a805fbbac0065d0781210ce5346ce934761cf446')
        expect(t.tx_params).to eq([{txid: 'dfed6d905cff2b9a7fd3fdb6a805fbbac0065d0781210ce5346ce934761cf446', vout: 3}])
      end

      it 'uses required input plus first to match amount' do
        t = tx({'foo' => 3_5000_0000}, listunspent: listunspent3, required_spent: 'dfed6d905cff2b9a7fd3fdb6a805fbbac0065d0781210ce5346ce934761cf447')
        expect(t.tx_params).to eq([{txid: 'dfed6d905cff2b9a7fd3fdb6a805fbbac0065d0781210ce5346ce934761cf447', vout: 2}, {txid: 'bbf56db603a9e375773182d0dd7c9dc439170bf7f3b05ab73713a7c1b84973e5', vout: 0}])
      end

    end

    context 'with only_spend_from_address' do

      it 'spends only the second input b/c of its address' do
        t = tx({'foo' => 5000_0000}, listunspent: listunspent3, only_spend_from_address: 'mpot8pmoPzBczjUbKnwRXinvMBzpNidBsQ')
        expect(t.tx_params).to eq([{txid: 'dfed6d905cff2b9a7fd3fdb6a805fbbac0065d0781210ce5346ce934761cf446', vout: 3}])
      end

      it 'needs to spend both inputs from the required address b/c of tx fee' do
        t = tx({'foo' => 2_0000_0000}, listunspent: listunspent3, only_spend_from_address: 'mpot8pmoPzBczjUbKnwRXinvMBzpNidBsQ')
        expect(t.tx_params).to eq([{txid: 'dfed6d905cff2b9a7fd3fdb6a805fbbac0065d0781210ce5346ce934761cf446', vout: 3}, {txid: 'dfed6d905cff2b9a7fd3fdb6a805fbbac0065d0781210ce5346ce934761cf447', vout: 2}])
      end

    end

  end

  describe '#address_params' do

    it 'sends to one recipient and some change back' do
      t = tx({'foo' => 5000_0000}, listunspent: listunspent3)
      expect(t.address_params).to eq({'foo' => 0.5, 'change_address' => 0.4999})
    end

    it 'spends both inputs to one recipient' do
      t = tx({'foo' => 1_5000_0000}, listunspent: listunspent3)
      expect(t.address_params).to eq({'foo' => 1.5, 'change_address' => 1.4999})
    end

    it 'spends exactly the first input amount, so needs to spend another input too to cover tx fee' do
      t = tx({'foo' => 1_0000_0000}, listunspent: listunspent3)
      expect(t.address_params).to eq({'foo' => 1.0, 'change_address' => 1.9999})
    end

    context 'with required_spent' do

      it 'uses only the required input' do
        t = tx({'foo' => 5000_0000}, listunspent: listunspent3, required_spent: 'dfed6d905cff2b9a7fd3fdb6a805fbbac0065d0781210ce5346ce934761cf446')
        expect(t.address_params).to eq({'foo' => 0.5, 'change_address' => 1.4999})
      end

      it 'uses required input plus first to match amount' do
        t = tx({'foo' => 3_5000_0000}, listunspent: listunspent3, required_spent: 'dfed6d905cff2b9a7fd3fdb6a805fbbac0065d0781210ce5346ce934761cf447')
        expect(t.address_params).to eq({'foo' => 3.5, 'change_address' => 0.4999})
      end

    end

    context 'with only_spend_from_address' do

      it 'spends only the second input b/c of its address' do
        t = tx({'foo' => 5000_0000}, listunspent: listunspent3, only_spend_from_address: 'mpot8pmoPzBczjUbKnwRXinvMBzpNidBsQ')
        expect(t.address_params).to eq({'foo' => 0.5, 'change_address' => 1.4999})
      end

      it 'needs to spend both inputs from the required address b/c of tx fee' do
        t = tx({'foo' => 2_0000_0000}, listunspent: listunspent3, only_spend_from_address: 'mpot8pmoPzBczjUbKnwRXinvMBzpNidBsQ')
        expect(t.address_params).to eq({'foo' => 2.0, 'change_address' => 2.9999})
      end

    end

  end

end

