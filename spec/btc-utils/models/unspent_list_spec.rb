require 'spec_helper'

describe BtcUtils::Models::UnspentList do

  describe '#select_for_amount' do


    let(:raw) { JSON.parse(<<-END) }
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

    it 'selects the right one' do
      ul = BtcUtils::Models::UnspentList.new raw
      ul.mark_required_spent! 'bbf56db603a9e375773182d0dd7c9dc439170bf7f3b05ab73713a7c1b84973e5', 0
      utxouts = ul.select_for_amount 1220_0000

      expect(utxouts.size).to be(1)
    end


  end

end

