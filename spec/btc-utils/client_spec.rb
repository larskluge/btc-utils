require 'spec_helper'

describe BtcUtils::Client do

  it 'creates a client with properties from ENV' do
    mock(::Bitcoin::Client).new 'user', 'pass', hash_including(port: "10099")
    user, pass, port = ENV.values_at(*%w<RPC_USER RPC_PASS RPC_PORT>)
    ENV['RPC_USER'], ENV['RPC_PASS'], ENV['RPC_PORT'] = %w(user pass 10099)
    BtcUtils::Client.new
    ENV['RPC_USER'], ENV['RPC_PASS'], ENV['RPC_PORT'] = user, pass, port
  end

  it 'delegates missing methods to the related Bitcoin client instance' do
    client = BtcUtils::Client.new
    bitcoin_client = client.instance_variable_get(:@bitcoin_client)
    mock(bitcoin_client).missing_method(:arg1, :arg2, :arg3)
    client.missing_method :arg1, :arg2, :arg3
  end

  describe 'api calls' do

    let(:client) { BtcUtils::Client.new }

    it { expect(client.api).to_not be_nil }

    it '#decode_raw_transaction calls decoderawtransaction' do
      mock(client.api).request 'decoderawtransaction', anything
      client.decode_raw_transaction 'hexstr'
    end

    it '#raw_transaction calls getrawtransaction' do
      mock(client.api).request 'getrawtransaction', anything
      client.raw_transaction 'txid'
    end

    it '#raw_decoded_tx decodes raw txid' do
      mock(client).raw_transaction('some txid').returns('hexstr')
      mock(client).decode_raw_transaction('hexstr')
      client.raw_decoded_tx 'some txid'
    end

    it '#tx_out calls gettxout' do
      mock(client.api).request 'gettxout', 'some txid', 'some idx', true
      client.tx_out 'some txid', 'some idx', true
    end

    it '#list_unspent calls listunspent' do
      mock(client.api).request 'listunspent', 1, 9999
      client.list_unspent 1, 9999
    end

    it '#list_lock_unspent calls listlockunspent' do
      mock(client.api).request 'listlockunspent'
      client.list_lock_unspent
    end

  end

end

