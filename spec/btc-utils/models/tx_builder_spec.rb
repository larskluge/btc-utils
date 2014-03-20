require 'spec_helper'

describe BtcUtils::Models::TxBuilder do

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
  }
]
END


  describe '#selected_inputs' do

    let(:change_address) { 'myV2smAaVzYfRAtbfuwQ6ePJJXRRquUCMm' }


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

end

