# frozen_string_literal: true

require_relative '../../models/asset'
require_relative '../../models/copy'
require_relative '../../models/file_metadata_set'
require_relative '../../models/repository'

Mongoid.load! File.expand_path('config/mongoid.yaml'), :test

RSpec.describe Repository, type: :model do
  it { is_expected.to be_mongoid_document }
  it { is_expected.to have_timestamps }
  it { is_expected.to have_field(:name).of_type String }
  it { is_expected.to validate_presence_of :name }
  it { is_expected.to have_many(:assets).as_inverse_of :repository }
end
