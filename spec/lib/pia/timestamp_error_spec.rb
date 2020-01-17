# frozen_string_literal: true

RSpec.describe Pia::TimestampError do
  include_context 'with middleware'

  let :timestamp_error do
    described_class.new message,
                        middleware: middleware,
                        timestamp: timestamp
  end

  describe '#message' do
    subject(:error_message) { timestamp_error.message }

    let :expected_message do
      'Attempted file upload with an invalid timestamp:'\
        " #{now.strftime('%Y-%m-%d %H:%M:%S.%6L')}."
    end
    
    let(:stop_info) { " Stopped in #{inspect_msg}." }

    context 'with message' do
      let(:message) { greeting }

      it { is_expected.to eq greeting }
    end

    context 'with middleware' do
      let(:middleware) { file_auth }

      it do
        expect(error_message)
          .to eq 'Attempted file upload without a timestamp.' + stop_info
      end
    end

    context 'with timestamp' do
      let(:timestamp) { now }

      it { is_expected.to eq expected_message }
    end

    context 'with middleware and timestamp' do
      let(:middleware) { file_auth }
      let(:timestamp) { now }

      it do
        expect(error_message)
          .to eq expected_message + stop_info
      end
    end
  end

  describe '#timestamp' do
    subject { timestamp_error.timestamp }

    context 'without timestamp' do
      it { is_expected.to be_nil }
    end

    context 'with timestamp' do
      let(:timestamp) { now }

      it { is_expected.to be now }
    end
  end
end
