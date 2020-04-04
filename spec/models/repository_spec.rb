# frozen_string_literal: true

require_relative '../../models/asset'
require_relative '../../models/copy'
require_relative '../../models/file_metadata_set'
require_relative '../../models/repository'

RSpec.describe Repository, type: :model do
  before :context do
    described_class.create! name: 'Test Repository',
                            iiif_image_api: true,
                            service_url: 'http://example.com/path/to/service/'
  end

  let :repository do
    Repository.find_by name: 'Test Repository'
  end

  it { is_expected.to be_mongoid_document }
  it { is_expected.to have_timestamps }

  it do
    expect(described_class)
      .to have_field(:iiif_image_api).of_type(Mongoid::Boolean)
      .with_default_value_of false
  end

  it { is_expected.to have_field(:name).of_type String }
  it { is_expected.to validate_presence_of :name }

  it do
    expect(described_class).to have_index_for(name: 1)
      .with_options unique: true
  end

  it { is_expected.to have_field(:service_url).of_type String }
  it { is_expected.to have_field(:service_url).with_alias :fullsize }
  it { is_expected.to have_field(:default_output_format).of_type String }
  it { is_expected.to have_many(:assets).as_inverse_of :repository }
end
