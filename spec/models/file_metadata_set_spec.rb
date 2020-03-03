# frozen_string_literal: true

require_relative '../../models/asset'
require_relative '../../models/file_metadata_set'
require_relative '../../models/repository'
require_relative '../support/helpers/mockable'

Mongoid.load! File.expand_path('config/mongoid.yaml'), :test

RSpec.describe FileMetadataSet, type: :model do
  it { is_expected.to be_mongoid_document }
  it { is_expected.to have_timestamps }
  it { is_expected.to be_dynamic_document }
  it { is_expected.to be_embedded_in(:asset).as_inverse_of :file_metadata_sets }
  it { is_expected.to have_field(:setname).of_type String }
  it { is_expected.to validate_presence_of :setname }

  it do
    expect(described_class)
      .to validate_inclusion_of(:setname).to_allow %w[stored dropped withheld]
  end
end
