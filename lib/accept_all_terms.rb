class AcceptAllTerms
  BATCH_SIZE = 1000

  def run
    contracts = FinePrint::Contract.all
    User.find_each(batch_size: BATCH_SIZE) do |user|
      contracts.each do |contract|
        FinePrint.sign_contract(user, contract)
      end
    end
  end
end
