# frozen_string_literal: true

RSpec.describe Pia::RepositoryStack do
  include_context 'with files'
  include_context 'with request'
  include_context 'with time'

  def repodouble(name, media_types, path)
    repo = instance_double 'Pia::RepositoryStack::Repository', name
    allow(repo).to receive(:name).and_return name
    allow(repo).to receive(:media_types).and_return(media_types)
    allow(repo).to receive(:supports?).and_return(false)
    allow(repo).to receive(:store).and_return([path, {}, 'checksum'])
    media_types.each do |mime|
      allow(repo).to receive(:supports?).with(mime)
        .and_return(true)
    end
    repo
  end

  let :app do
    repos = [imagerepo, docrepo]
    scale = { scale: { width: 64, height: 48 } }
    storage_opts = { nesting_levels: nil,
                     folder_limit: nil,
                     link_location: nil }
    storage_dir = nil
    _app do
      plugin Pia::RepositoryStack,
             repositories: repos
      route do |r|
        r.on do
          store(r).to_json
        end
      end
    end
  end

  let :imagerepo do
    repodouble 'Image Store', %w[image/jpeg image/tiff], 'path/to/image'
  end

  let :docrepo do
    repodouble 'Document Store', %w[application/pdf], 'path/to/document'
  end

  before { app.opts[:common_logger] = logger }

  context 'with a supported image type' do
    it_behaves_like 'a rack app', :post, '/', :to do
      let(:message) { '{"Image Store":["path/to/image",{},"checksum"]}' }
      let(:status) { 200 }
    end
  end

  context 'with a supported document type' do
    let :body do
      {
        specify_user: username,
        filename: doc_filename,
        timestamp: timestamp(now),
        file: doc_rackfile
      }
    end
    
    it_behaves_like 'a rack app', :post, '/', :to do
      let(:message) { '{"Document Store":["path/to/document",{},"checksum"]}' }
      let(:status) { 200 }
    end
  end

  context 'with an unsupported file type' do
    let :body do
      {
        specify_user: username,
        filename: bad_filename,
        timestamp: timestamp(now),
        file: bad_rackfile
      }
    end
    
    it_behaves_like 'a rack app', :post, '/', :not_to do
      let :message do
        'Image format image/jp2 is not supported. Supported formats are:'\
        ' ["image/jpeg", "image/tiff", "application/pdf"].'
      end

      let(:status) { 333 }
    end
  end
end
