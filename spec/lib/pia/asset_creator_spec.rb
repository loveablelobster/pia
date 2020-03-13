# frozen_string_literal: true

Mongoid.load! File.expand_path('config/mongoid.yaml'), :test

RSpec.describe Pia::AssetCreator do
  include_context 'with files'
  include_context 'with mocks'
  include_context 'with request'

  before do
    allow(repository_model)
      .to receive(:find_by).with(name: 'Test Backup')
      .and_return backup_repo

    allow(repository_model)
      .to receive(:find_by).with(name: 'Test Store')
      .and_return store_repo

    allow(asset_model).to receive(:create!).with(asset_attributes)
                      .and_return asset_object
  end

  let :asset_creator do
    described_class.new asset_model: asset_model,
                        repository_model: repository_model
  end

  let(:asset_model) { class_double 'Asset', 'Asset' }
  
  let(:repository_model) { class_spy 'Repository', 'Repository' }
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
