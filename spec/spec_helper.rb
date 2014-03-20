ENV['ENV'] ||= 'test'

$: << File.expand_path('../../lib', __FILE__)

require 'bundler/setup'
Bundler.require(:default, ENV['ENV'])

require 'rr'
require 'yaml'
require 'json'
require 'logger'

require 'btc-utils'


RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'


  config.mock_framework = :rr

  config.before :suite do
    Log = Logger.new(STDOUT)
  end

  config.before do
    module BtcUtils
      @client = BasicObject.new
      def @client.to_s
        @client.inspect
      end
    end
    rpc_responses = YAML.load(File.read(File.expand_path('../support/fixtures.yml', __FILE__)))
    rpc_responses.each do |(method, responses)|
      responses.each do |(key, resp)|
        stub(BtcUtils.client).__send__(method, key) { resp }
      end
    end
    stub(BtcUtils.client).raw_decoded_tx('doesnotexist') { raise Bitcoin::Errors::RPCError }
  end
end

