# frozen_string_literal: true

RSpec.shared_context 'with request', shared_context: :metadata do
  # ===== Files
  let(:file) { 'spec/support/test_files/example.jpg' }
  let(:filename) { File.basename file }

  # ===== Timestamps
  let(:now) { Time.now }
  let(:two_hours_ago) { (DateTime.now - (2 / 24.0)).to_time }
  let(:two_hours_ahead) { (DateTime.now + (2 / 24.0)).to_time }
 
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
  let(:rack_app) { double call: [200, {}, success] }
  
  let(:logger) { instance_double('Logger').as_null_object }
end
