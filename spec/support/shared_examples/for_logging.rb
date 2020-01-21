# frozen_string_literal: true

RSpec.shared_examples 'a logger' do |verb, path, log_method|
  before { public_send verb, path, body, rack_env }

  it do
    expect(logger).to have_received(log_method).with log_msg
  end
end
