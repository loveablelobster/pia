# frozen_string_literal: true

RSpec.describe Pia::HmacAuthentication::AuthorizationHeader do
  include_context 'with request'

  let :header do
    described_class.new contents.join(separator), separator: separator
  end

  let(:contents) { [key, signature] }
  let(:separator) { '|' }
  let(:signature) { 'some hashed message' }

  context 'with a valid header' do
    describe '#key' do
      subject { header.key }

      it { is_expected.to eq key }
    end

    describe '#separator' do
      subject { header.separator }

      it { is_expected.to eq separator }
    end

    describe '#signature' do
      subject { header.signature }

      it { is_expected.to eq signature }
    end

    describe '#valid?' do
      subject { header.valid? }

      it { is_expected.to be_truthy }
    end

    describe '#verify' do
      subject { header.verify api_key }

      context 'with a matching key' do
        let(:api_key) { key }

        it { is_expected.to be_truthy }
        it { is_expected.to have_attributes :valid? => true }
      end

      context 'with a non-matching key' do
        let(:api_key) { 'foo' }

        it { is_expected.to be_falsey }
      end
    end
  end

  context 'with an empty header' do
    let(:contents) { [] }

    it 'is invalid' do
      expect(header.valid?).to be_falsey
    end

    it 'does not verify' do
      expect(header.verify(key)).to be_falsey
    end
  end

  context 'with extra elements' do
    let(:contents) { [key, signature, 'foo'] }

    it 'is invalid' do
      expect(header.valid?).to be_falsey
    end

    it 'does not verify' do
      expect(header.verify(key)).to be_falsey
    end
  end

  context 'with a misisng key' do
    let(:contents) { [signature] }

    it 'is invalid' do
      expect(header.valid?).to be_falsey
    end

    it 'does not verify' do
      expect(header.verify(key)).to be_falsey
    end
  end

  context 'with a missing signature' do
    let(:contents) { [key] }

    it 'is invalid' do
      expect(header.valid?).to be_falsey
    end

    it 'does not verify' do
      expect(header.verify(key)).to be_falsey
    end
  end
end
