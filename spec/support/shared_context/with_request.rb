# frozen_string_literal: true

RSpec.shared_context 'with request', shared_context: :metadata do
  # ===== Files
  let(:file) { 'spec/support/test_files/example.jpg' }
  let(:filename) { File.basename file }

  # ===== Request Headers
  let(:rack_env) { { 'CONTENT_TYPE' => 'multipart/form-data' } }

  # ===== Request Body
  let(:username) { 'UserName' }
  
  let :body do
    {
      specify_user: username,
      filename: filename,
      timestamp: timestamp(now),
      file: file
    }
  end

  # ===== Mocks
  let(:success) { 'Success!' }
  
  let(:logger) { instance_spy 'Logger' }
end
