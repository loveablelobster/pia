# frozen_string_literal: true

RSpec.describe Pia::AssetRedirect do
  include_context 'with mocks'
  include_context 'with request'

  let(:redirect) { described_class.new asset_object }

  it { p redirect.fullsize }
end
