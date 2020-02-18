# frozen_string_literal: true

RSpec.shared_context 'with files', shared_context: :metadata do
  # ===== Directories
  let(:testdir) { TESTDIR }
  let(:workdir) { WORKDIR }
  let(:storedir) { IMGSTORE }
  let(:docdir) { DOCSTORE }
  let(:libdir) { LIBDIR }

  # ===== Files
  let(:repoconfig) { 'spec/support/test_files/repositories.yaml' }
  let(:file) { 'spec/support/test_files/example.jpg' }
  let(:filename) { File.basename file }
  let(:rackfile) { Rack::Test::UploadedFile.new file, 'image/jpeg' }

  let(:doc_file) { 'spec/support/test_files/lorem_ipsum.pdf' }
  let(:doc_filename) { File.basename doc_file }
  let :doc_rackfile do
    Rack::Test::UploadedFile.new doc_file, 'application/pdf'
  end

  let(:bad_file) { 'spec/support/test_files/example.jp2' }
  let(:bad_filename) { File.basename bad_file }
  let(:bad_rackfile) { Rack::Test::UploadedFile.new bad_file, 'image/jp2' }
end
