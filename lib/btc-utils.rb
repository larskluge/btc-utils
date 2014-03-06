module BtcUtils

  autoload :VERSION, 'btc-utils/version'

  module Models

    autoload :Tx,    'btc-utils/models/tx'
    autoload :TxIn,  'btc-utils/models/tx_in'
    autoload :TxOut, 'btc-utils/models/tx_out'

  end

end

