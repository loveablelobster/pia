# frozen_string_literal: true

RSpec.shared_context 'with middleware' do
  let(:message) { nil }
  let(:greeting) { 'Hi! This is Your Upload Error' }
  
  let(:timestamp) { nil }
  let(:now) { Time.now }
 
  let(:middleware) { nil }
  let(:inspect_msg) { 'FileAuth Middleware' }

  let :file_auth do
    instance_double 'PiaMiddleware::FileAuth', inspect: inspect_msg
  end
end
