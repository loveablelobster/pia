# frozen_string_literal: true

RSpec.shared_context 'with request', shared_context: :metadata do
  def self.respond_and_log(verb, route)
    before do
      rack_env['HTTP_AUTHORIZATION'] = auth_header.join(':') if auth_header
    end

    it_behaves_like 'a rack app', verb, route, :not_to
    it_behaves_like 'a logger', verb, route, :<<
  end

  # ===== Authentication
  let(:key) { 'testkey' }
  let(:secret) { 'testsecret' }
  let(:hmac) { signature file, timestamp(now), username }

  # ===== Request Headers
  let(:rack_env) { { 'CONTENT_TYPE' => 'multipart/form-data' } }
  let(:auth_header) { [key, hmac] }

  # ===== Request Body
  let(:username) { 'UserName' }
  
  let :body do
    {
      specify_user: username,
      filename: filename,
      timestamp: timestamp(now),
      file: rackfile
    }
  end

  # ===== Response
  let(:bad_request_msg) { '{"message":"Bad request. Ignored."}' }
  let(:forbidden_msg) { '{"message":"Forbidden!"}' }

  # ===== Mocks
  let(:success) { 'Success!' }
  
  let(:logger) { instance_spy 'Logger' }
end
