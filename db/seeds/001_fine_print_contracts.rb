# Idempotent operation to create the placeholder contracts
# for the general_terms_of_use and the privacy_policy.

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
  # This is idempotent because the creation fails if the contract already exists
  # Also forces the seeded contract version to be 1
  FinePrint::Contract.create contract_data.merge(version: 1)
end
