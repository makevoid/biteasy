require 'json'
require 'net/http'

class Blockchain

end


###

# utils - net

class Neat

  def self.get(url)
    Net::HTTP.get_response(URI.parse url).body
  end

  def self.getj(url)
    JSON.parse get url
  end

end


# utils - cache

CACHE_TIME = Time.now - 64800 # 1 day ago # cache + update via async watcher

def cache(name, &block)
  filename = "cache/#{name}.json"
  cached_file_is_good = File.exist?(filename) && File.mtime(filename) > CACHE_TIME
  if cached_file_is_good
    JSON.parse File.read filename
  else
    value = block.call
    File.open(filename, "w") do |f|
      f.write value.to_json
    end
    value
  end
end



# config

@contacts_backup = "./config/kryptokit_backup.json"

def contacts_import
  contacts = JSON.parse File.read @contacts_backup
  cont = {}
  contacts.each do |c|
    cont[c["address"]] = c["name"]
  end
  @contacts = cont
end

# import contacts

CONTACTS_ALL = contacts_import


# blockchain external api

class BlockchainApi

  def address_spents

  end

end

###

# internal api

require 'pp'

class Numeric
  def to_mbtc
    (self.to_f * 10 ** -5).round(2)
  end

  def to_btc
    (self.to_f * 10 ** -8).round(4)
  end
end

class Blockchain

  attr_reader :transactions

  def from_address(address)
    @address = address
  end

  def spents_get
    transactions = Neat.getj url_address_transactions @address
  end


  def initialize(tx_count_limit) # TODO: transaction#initialize
    from_address "1EiNgZmQsFN4rJLZJWt93quMEz3X82FJd2"

    @contacts = CONTACTS_ALL
    @contacts[@address] = "this"


    puts "address: #{@address}"
    address = cache(:"bchain_address_#{@address[0..7]}"){ spents_get }

    puttb( address, :final_balance  ){ |v| v.to_mbtc }
    putt address, :n_tx
    # putt address, :n_unredeemed # ?
    puttb( address, :total_received ){ |v| v.to_mbtc }
    # puttb( address, :total_sent     ){ |v| v.to_mbtc }

    puts
    puts "transactions: "
    puts

    transactions = address.fetch "txs"
    transactions.reverse!
    transactions = transactions.map{ |tx| transaction_object tx }
    transactions.select!{ |tx| tx[:result] != 0 }
    # exclude transactions with more than 2 different addresses
    transactions.reject!{ |tx| tx[:addresses].size > 2 }

    transactions.each_with_index do |transaction, idx|
      return if idx > tx_count_limit

      # transaction_puts transaction
      puts transaction_labelize transaction_object_to_s transaction
      puts "--"
    end

    @transactions = transactions
    self
  end

  private


  def transaction_labelize(tx)
    tx[:addresses] = tx[:addresses].map do |trans|
      "#{trans} (#{labels[trans]})"
    end
    tx
  end

  def transaction_object(tx)
    # addresses
    inputs    = tx["inputs"].map{ |t| t["addr"] }
    outputs   = tx["out"].map{ |t| t["addr"] }
    addresses = inputs + outputs - [@address]
    addresses.uniq!
    addresses.compact!

    # time
    hours_diff = 2 # is blockchain GMT -1 ?
    time = tx["time"]
    time = Time.at(time-3600*hours_diff).strftime "%Y-%m-%d %H:%M:%S"

    { result: tx["result"].to_mbtc, time: time, addresses: addresses }
  end

  def transaction_object_to_s(tx)
    # unconfirmed = "no confirmations yet" if tx[:confirmations] == 0
    "
result: #{tx[:result]} mBTC
time: #{tx[:time]}
addresses: #{tx[:addresses].join(", ")}
    ".strip
  end


  def transaction_puts(tx)

    # wtf???? ....

    # return if [tx["inputs"].size, tx["out"].size].max > 2


    # puts "#{inputs.fetch(@address, 0).to_mbtc} - #{outputs.fetch(@address, 0).to_mbtc}"

    # type = total_value > 0 ? :receive : :send
    # puts "type: #{type}"


    # puts "total_value: #{total_value.to_mbtc} mBTC"
    # puttb(tx, :hash){ |v| v[0..5] }

    # # pp inputs
    # # pp outputs

    # # more useful infos:
    # #
    # # puttb(tx, :transacted_value, &:to_mbtc)#{ |v| v.to_mbtc }
    # # puttb(tx, :transacted_value){ |v| type == :receive ? v.to_mbtc : -(v.to_mbtc) }
    # # puttb(tx, :inputs_value){  |v| v.to_mbtc }
    # # puttb(tx, :outputs_value){ |v| v.to_mbtc }

    # hours_diff = 2 # is blockchain GMT -1 ?
    # puttb(tx, :time){    |v| Time.at(v-3600*hours_diff).strftime "%Y-%m-%d %H:%M:%S" }
    # # putt tx, :confirmations


  end


  def putt(tx, value) # put_transaction
    puts "#{value}: #{tx[value.to_s]}"
  end

  def puttb(tx, value, &block) # put_transaction
    val = tx[value.to_s]
    val = block.call val
    puts "#{value}: #{val}"
  end



  def url_api_root
    "https://blockchain.info"
  end

  def url_address_transactions(address)
    "#{url_api_root}/address/#{address}?format=json&limit=50&offset=0" # limit = 50 (max), offset = 100 (for the second page)
  end

end

tx_count_limit = 50
tx_count_limit = ARGV[0].to_i if ARGV[0]
bc = Blockchain.new tx_count_limit


