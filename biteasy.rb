require 'json'
require 'net/http'

class Biteasy

end


###

# utils

class Neat

  def self.get(url)
    Net::HTTP.get_response(URI.parse url).body
  end

  def self.getj(url)
    JSON.parse get url
  end

end



# config

@contacts_backup = "./config/kryptokit_backup.json"

def contacts_import
  @contacts = JSON.parse File.read @contacts_backup
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
    (self.to_f * 10 ** -6).round(2)
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


  def initialize
    from_address "1EiNgZmQsFN4rJLZJWt93quMEz3X82FJd2"

    @contacts = CONTACTS_ALL


    spents = spents_get
    spents = spents.fetch "data"
    transactions = spents.fetch "transactions"

    for transaction in transactions

      transaction_puts transaction

      puts "---"
    end

    # putt tx, :inputs
    # putt tx, :outputs
    # spents = spents.keys

    # pp spents
  end

  private

  require 'date'

  def transaction_puts(tx)
    return if [tx["inputs"].size, tx["outputs"].size].max > 2


    type = tx["inputs_value"] > tx["outputs_value"] ? :receive : :send
    puts "type: #{type}"

    # puttb(tx, :transacted_value, &:to_mbtc)#{ |v| v.to_mbtc }
    puttb(tx, :transacted_value){ |v| type == :receive ? v.to_mbtc : -v.to_mbtc }
    puttb(tx, :inputs_value){  |v| v.to_mbtc }
    puttb(tx, :outputs_value){ |v| v.to_mbtc }
    puttb(tx, :created_at){    |v| Date.parse(v).strftime "%Y-%m-%d" }
    putt tx, :confirmations



    tx_type = "inputs"
    transactions_sub tx, tx_type
    tx_type = "outputs"
    transactions_sub tx, tx_type
    puts
  end

  def transactions_sub(tx, tx_type) # sub transactions
    transactions = tx[tx_type]
    puts "#{tx_type}:"
    for transaction in transactions
      if tx_type == "outputs"
        puts "  #{transaction["to_address"]} -> #{transaction["value"].to_mbtc} mBTC"
      else
        puts "  #{transaction["from_address"]} -> #{transaction["outpoint_value"].to_mbtc} mBTC"
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

be = BitEasy.new


