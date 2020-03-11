# frozen_string_literal: true

require_relative '../../support/helpers/mockable'

Mongoid.load! File.expand_path('config/mongoid.yaml'), :test

RSpec.describe Pia::AssetCreator do
  include_context 'with files'
  include_context 'with request'

  before do
    allow(repository_model)
      .to receive(:find_or_create_by).with(name: 'Test Backup')
      .and_return backup_repo

    allow(repository_model)
      .to receive(:find_or_create_by).with(name: 'Test Store')
      .and_return store_repo

    allow(asset_model)
      .to receive(:create!)
      .with(asset_id: 'stored_file',
            copies: [{ repository: backup_repo,
                       uri: 'path/to/backed_up_file.jpg' }],
            file_metadata_sets: Mockable.file_metadata,
            filename: filename,
            identifier: 'path/to/stored_file.jpg',
            md5sum: 'checksum',
            media_type: 'image/jpeg',
            public: false,
            repository: store_repo)
      .and_return asset_object
  end

  let :asset_creator do
    described_class.new asset_model: asset_model,
                        repository_model: repository_model
  end

  let(:asset_model) { class_double 'Asset', 'Asset' }
  
  let :asset_object do
    instance_double 'Asset', 'Old Pic',
                    asset_id: store_id,
                    identifier: store_path,
                    media_type: mime,
                    capture_device: capture_device,
                    create_date: create_date,
                    date_imaged: date_imaged,
                    copyright: copyright,
                    md5sum: checksum
  end

  let(:repository_model) { class_spy 'Repository', 'Repository' }
  let(:backup_repo) { instance_double Repository, 'Test Backup' }
  let(:store_repo) { instance_double Repository, 'Test Store' }
  let(:public_flag) { false }

  let :storage_info do
    { 'Test Store' => ['path/to/stored_file.jpg',
                       Mockable.file_metadata,
                       'checksum'],
      'Test Backup' => ['path/to/backed_up_file.jpg',
                        Mockable.file_metadata,
                        'checksum'] }
  end

  it 'returns json' do
    expect(asset_creator.call(filename, storage_info, public_flag))
      .to eq response_body
  end
end
