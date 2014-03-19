class BtcUtils::Models::UnspentList
  include Enumerable

  attr_reader :list


  def self.create min_conf = 0
    unspent = BtcUtils.client.list_unspent min_conf
    self.new unspent
  end


  def initialize raw
    @list = raw.map { |entry| BtcUtils::Models::UnspentTxOut.new(entry) }
  end

  def each
    @list.each do |utxout|
      yield utxout
    end
  end

  def size
    @list.size
  end

  def find txid, vout
    @list.detect do |utxout|
      utxout.txid == txid and utxout.vout.to_s == vout.to_s
    end
  end

  def mark_required_spent! txid, vout
    if utxout = find(txid, vout)
      utxout.required_spent = true
    else
      fail "Required tx out not found! txid=#{txid} vout=#{vout}"
    end
  end

  def required_spents
    @list.select(&:required_spent)
  end

  def select_for_amount satoshis, opts = {}
    only_address = opts[:only_address]
    utxouts = required_spents
    left = @list - utxouts

    while utxouts.sum(&:amount) < satoshis and !left.empty? do
      utxout = left.shift
      if only_address.nil? or utxout.address == only_address
        utxouts.push utxout
      end
    end

    if utxouts.sum(&:amount) < satoshis
      fail "Not sufficiant funds available to spent amount=#{satoshis}"
    else
      utxouts
    end
  end

end

