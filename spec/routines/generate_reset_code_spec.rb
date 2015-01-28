require 'spec_helper'

describe GenerateResetCode do

  let(:identity) { FactoryGirl.create(:identity) }

  it 'generates a reset code for the given identity' do
    result = GenerateResetCode.call(identity)
    expect(result.errors).to be_empty
    code = result.outputs[:code]
    expect(code).not_to be_nil
    expect(result.outputs[:expires_at]).to be >= DateTime.now
    expect(ResetCode.where(code: code).first.identity).to eq identity

    result = GenerateResetCode.call(identity)
    expect(result.errors).to be_empty
    expect(result.outputs[:code]).not_to be_nil
    expect(result.outputs[:code]).not_to eq code
    expect(result.outputs[:expires_at]).to be >= DateTime.now
    expect(ResetCode.where(code: result.outputs[:code]).first.identity)
      .to eq identity
    expect(ResetCode.where(code: code).first).to be_nil
  end

end
