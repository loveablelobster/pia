# frozen_string_literal: true

require_relative '../../models/asset'
require_relative '../../models/copy'
require_relative '../../models/file_metadata_set'
require_relative '../../models/repository'
require_relative '../support/helpers/mockable'

Mongoid.load! File.expand_path('config/mongoid.yaml'), :test

RSpec.describe Asset, type: :model do
  let :asset do
    described_class.create! asset_id: asset_id,
                            identifier: identifier,
                            public: false,
                            filename: filename,
                            media_type: media_type,
                            md5sum: checksum,
                            repository: primary_store,
                            file_metadata_sets: Mockable.file_metadata
  end

  let :primary_store do
    Repository.new name: repository
  end

  let(:asset_id) { 'where_there_be_a_UUID' }
  let(:identifier) { "path/to/#{asset_id}" }
  let(:filename) { 'i_was_once_named.txt' }
  let(:media_type) { 'application/text' }
  let(:checksum) { 'a_md5_checksum' }
  let(:repository) { 'Example Repository' }
  let(:stored_metadata) { Mockable.file_metadata :stored }
  let(:dropped_metadata) { Mockable.file_metadata :dropped }
  let(:withheld_metadata) { Mockable.file_metadata :withheld }

  before { Asset.destroy_all }

  it { is_expected.to be_mongoid_document }
  it { is_expected.to have_timestamps }
  it { is_expected.to have_field(:asset_id).of_type String }
  it { is_expected.to validate_presence_of :asset_id }

  it do
    expect(described_class).to have_index_for(asset_id: 1)
      .with_options unique: true
  end

  it { is_expected.to have_field(:identifier).of_type String }
  it { is_expected.to validate_presence_of :identifier }
  
  it do
    expect(described_class).to have_field(:public).of_type(Mongoid::Boolean)
      .with_default_value_of(true)
  end

  it { is_expected.to have_field(:filename).of_type String }
  it { is_expected.to have_field(:media_type).of_type String }
  it { is_expected.to have_field(:md5sum).of_type String }
  it { is_expected.to belong_to(:repository).as_inverse_of :assets }
  it { is_expected.to validate_presence_of :repository }
  it { is_expected.to embed_many :file_metadata_sets }
  it { is_expected.to embed_many(:copies).as_inverse_of :asset }

  describe '#fetch_metadata' do
    subject { asset.fetch_metadata field }

    context 'when accessing stored metadata' do
      let(:field) { 'Copyright' }

      it { is_expected.to eq stored_metadata['Copyright'] }
    end

    context 'when accessing dropped metadata' do
      let(:field) { 'Make' }

      it { is_expected.to eq dropped_metadata['Make'] }
    end

    context 'when accessing withheld metadata' do
      let(:field) { 'GPSAltitude' }

      it { is_expected.not_to eq withheld_metadata['GPSAltitude'] }
      it { is_expected.to be_nil }
    end

    context 'when querying for multiple values' do
      subject(:fetched_tag) { asset.fetch_metadata 'NothingHere', 'Copyright' }

      it 'returns the first match' do
        expect(fetched_tag).to eq stored_metadata['Copyright']
      end
    end
  end

  describe '#capture_device' do
    subject { asset.capture_device }

    let :capture_device do
      %w[Make Model LensModel].map { |tag| dropped_metadata[tag] }
                              .join ', '
    end

    it { is_expected.to eq capture_device }
  end

  describe '#copyright' do
    subject { asset.copyright }

    it { is_expected.to eq stored_metadata['Copyright'] }
  end

  describe '#create_date' do
    subject { asset.create_date time_format }

    context 'with a target format' do
      let(:time_format) { '%Y-%m-%d' }

      let(:time) { stored_metadata['CreateDate'].strftime time_format }

      it { is_expected.to eq time }
    end

    context 'without a target format' do
      let(:time_format) { nil }

      it { is_expected.to be_a Time }
      it { is_expected.to eq stored_metadata['CreateDate'].to_s }
    end
  end

  describe '#date_imaged' do
    subject { asset.date_imaged time_format }

    context 'with a target format' do
      let(:time_format) { '%Y-%m-%d' }

      let(:time) { stored_metadata['DateTimeOriginal'].strftime time_format }

      it { is_expected.to eq time }
    end

    context 'without a target format' do
      let(:time_format) { nil }

      it { is_expected.to be_a Time }
      it { is_expected.to eq stored_metadata['DateTimeOriginal'].to_s }
    end
  end
end
