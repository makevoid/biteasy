# conf

require_relative "../blockchain"

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :should
  end
end


# specs

describe "blockchain" do

    before :all do
      tx_count_limit = 50
      @bc = Blockchain.new tx_count_limit
    end

    # 1st transaction
    # type send
    # total value

    it "lists transactions" do
      @bc.transactions.should be_an(Array)
    end

end