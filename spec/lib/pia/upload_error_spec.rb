# frozen_string_literal: true

RSpec.describe Pia::UploadError do
  include_context 'with middleware'

  let :upload_error do
    described_class.new message,
                        middleware: middleware
  end

  describe '#body' do
    subject { upload_error.body }

    it { is_expected.to eq Pia::BAD_REQUEST }
  end

  describe '#header' do
    subject { upload_error.header }

    it { is_expected.to be_a(Hash) & be_empty }
  end

  describe '#message' do
    subject { upload_error.message }

    it { is_expected.to eq 'Upload failed.' }

    context 'with message' do
      let(:message) { greeting }

      it { is_expected.to eq greeting }
    end

    context 'with middleware' do
      let(:middleware) { file_auth }

      it { is_expected.to eq 'Upload failed. Stopped in FileAuth Middleware.' }
    end
  end
 
  describe '#middleware' do
    subject { upload_error.middleware }

    context 'without middleware' do
      it { is_expected.to be_nil }
    end

    context 'with middleware' do
      let(:middleware) { file_auth }

      it { is_expected.to be file_auth }
    end
  end

  describe '#response' do
    subject { upload_error.response }

    it { is_expected.to contain_exactly 111, {}, Pia::BAD_REQUEST }
  end

  describe '#status' do
    subject { upload_error.status }

    it { is_expected.to be 111 }
  end
end
