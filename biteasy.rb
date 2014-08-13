require 'json'
require 'net/http'

class Biteasy

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

def cache(name, &block)
  filename = "cache/#{name}.json"
  if File.exist? filename
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


# biteasy external api

class BitEasyApi

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

class BitEasy

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
    puts
    puts
    puts "transactions: "
    puts
    spents = cache(:"spents_#{@address[0..7]}"){ spents_get }
    spents = spents.fetch "data"
    transactions = spents.fetch "transactions"


    transactions.each_with_index do |transaction, idx|
      return if idx > tx_count_limit
      transaction_puts transaction
      puts "--"
    end

  end

  private

  require 'date'

  def transaction_puts(tx)
    return if [tx["inputs"].size, tx["outputs"].size].max > 2



    inputs, outputs = {}, {}
    tx["inputs"].each do |trx|
      outputs[trx["from_address"]] = trx["outpoint_value"].to_f
    end
    tx["outputs"].each do |trx|
      inputs[trx["to_address"]] = trx["value"].to_f
    end
    # trans_total = outputs + inputs
    # pp trans_total

    # pp inputs
    # pp outputs

    total_value = inputs.fetch(@address, 0) - outputs.fetch(@address, 0)

    type = total_value > 0 ? :receive : :send
    puts "type: #{type}"


    puts "total_value: #{total_value.to_mbtc} mBTC"

    # more useful infos:
    #
    # puttb(tx, :transacted_value, &:to_mbtc)#{ |v| v.to_mbtc }
    # puttb(tx, :transacted_value){ |v| type == :receive ? v.to_mbtc : -(v.to_mbtc) }
    # puttb(tx, :inputs_value){  |v| v.to_mbtc }
    # puttb(tx, :outputs_value){ |v| v.to_mbtc }
    puttb(tx, :created_at){    |v| DateTime.parse(v).strftime "%Y-%m-%d %H:%M:%S" }
    # putt tx, :confirmations


    # inputs & outputs
    #
    # tx_type = "inputs"
    # transactions_sub tx, tx_type
    # tx_type = "outputs"
    # transactions_sub tx, tx_type
  end

  def transactions_sub(tx, tx_type) # sub transactions
    transactions = tx[tx_type]
    puts "#{tx_type}:"
    for transaction in transactions
      if tx_type == "outputs"
        # puts @contacts
        aliased = @contacts.fetch transaction["to_address"], "<not found>"
        puts "  #{transaction["to_address"]} -> #{transaction["value"].to_mbtc} mBTC - #{aliased}"
      else
        aliased = @contacts.fetch transaction["from_address"], "<not found>"
        puts "  #{transaction["from_address"]} -> #{transaction["outpoint_value"].to_mbtc} mBTC - #{aliased}"
      end
    end
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
    "https://api.biteasy.com/blockchain/v1"
  end

  def url_address_transactions(address)
    "#{url_api_root}/transactions?address=#{address}&per_page=199" # page = 0
  end

end

tx_count_limit = ARGV[0].to_i
be = BitEasy.new tx_count_limit


