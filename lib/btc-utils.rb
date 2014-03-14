require 'bitcoin-client'
require 'active_support/core_ext/enumerable'


module BtcUtils

  autoload :VERSION, 'btc-utils/version'
  autoload :Client, 'btc-utils/client'
  autoload :Convert, 'btc-utils/convert'

  def self.client
    @client ||= Client.new
  end

  module Models

    autoload :Tx,           'btc-utils/models/tx'
    autoload :TxBuilder,    'btc-utils/models/tx_builder'
    autoload :TxIn,         'btc-utils/models/tx_in'
    autoload :TxOut,        'btc-utils/models/tx_out'
    autoload :UnspentList,  'btc-utils/models/unspent_list'
    autoload :UnspentTxOut, 'btc-utils/models/unspent_tx_out'
    autoload :WalletTx,     'btc-utils/models/wallet_tx'

  end

end

