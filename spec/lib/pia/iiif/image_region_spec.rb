# frozen_string_literal: true

RSpec.describe Pia::IIIF::ImageRegion do
  context 'with :full' do
    subject { described_class.new(:full).to_s }

    it { is_expected.to eq 'full' }
  end

  context 'with :square' do
    subject { described_class.new(:square).to_s }

    it { is_expected.to eq 'square' }
  end

  context 'with rectangle' do
    subject { described_class.new(125, 15, 120, 140).to_s }

    it { is_expected.to eq '125,15,120,140' }
  end

  context 'with percentage' do
    subject { described_class.new(:pct, 41.6, 7.5, 40, 70).to_s }

    it { is_expected.to eq 'pct:41.6,7.5,40,70' }
  end
end
