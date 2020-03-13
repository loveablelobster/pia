# frozen_string_literal: true

require_relative '../../models/asset'
require_relative '../../models/copy'
require_relative '../../models/file_metadata_set'

RSpec.describe Copy, type: :model do
  it { is_expected.to be_mongoid_document }
  it { is_expected.to have_timestamps }
  it { is_expected.to be_embedded_in(:asset).as_inverse_of :copies }
  it { is_expected.to belong_to :repository }
  it { is_expected.to validate_presence_of :repository }
  it { is_expected.to have_field(:uri).of_type String }
  it { is_expected.to validate_presence_of :uri }
end
