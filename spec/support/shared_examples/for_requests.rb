# frozen_string_literal: true

# Shared example group to test Rack applications
RSpec.shared_examples 'a rack app' do |verb, path, expectation|
  before { public_send verb, path, body, rack_env }

  it do
    expect(last_response)
      .to have_attributes status: status, body: include(message)
  end

  it do
    expect(last_response).send expectation, be_ok
  end
end
