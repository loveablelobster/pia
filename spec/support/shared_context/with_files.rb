# frozen_string_literal: true

RSpec.shared_context 'with files', shared_context: :metadata do
  let(:file) { 'spec/support/test_files/example.jpg' }
  let(:filename) { File.basename file }
  let(:rackfile) { Rack::Test::UploadedFile.new file, 'image/jpeg' }
end
