class BtcUtils::Client

  def initialize
    @bitcoin_client = ::Bitcoin::Client.new ENV['RPC_USER'], ENV['RPC_PASS'], port: ENV['RPC_PORT']
  end


  def decode_raw_transaction hexstring
    api.request 'decoderawtransaction', hexstring
  end

  def raw_transaction txid
    api.request 'getrawtransaction', txid
  end

  def raw_decoded_tx txid
    raw_tx = raw_transaction txid
    decode_raw_transaction raw_tx
  end

  def tx_out txid, idx, include_mem_pool = true
    api.request 'gettxout', txid, idx, include_mem_pool
  end


  def api
    @bitcoin_client.instance_eval('@api')
  end

  def method_missing method, *args
    @bitcoin_client.send method, *args
  end

end

