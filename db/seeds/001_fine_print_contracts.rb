# Idempotent operation to create the placeholder contracts for the general_terms_of_use
# and the privacy_policy.

[
  {
    name:    'general_terms_of_use',
    content: 'Placeholder for general terms of use, required for new installations to function',
    title:   'Terms of Use',
  },
  {
    name:    'privacy_policy',
    content: 'Placeholder for privacy policy, required for new installations to function',
    title:   'Privacy Policy'  
  }
].each do |contract_data|

  next if FinePrint::Contract.where{name.eq contract_data[:name]}.any?

  (FinePrint::Contract.create do |contract|
    contract.name    = contract_data[:name]
    contract.content = contract_data[:content]
    contract.title   = contract_data[:title]
  end).publish  

end