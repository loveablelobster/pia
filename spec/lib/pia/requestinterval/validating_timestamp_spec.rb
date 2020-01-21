# frozen_string_literal: true

RSpec.describe Pia::Requestinterval::ValidatingTimestamp do
  include_context 'with time'

  let :timestamp do
    described_class.new time,
                        validity: 30,
                        reference_time: now,
                        formatter: time_print_fmt
  end

  let(:time) { now }

  describe '#expired?' do
    subject { timestamp.expired? }

    context 'with an expired_timestamp' do
      let(:time) { two_hours_ago }

      it { is_expected.to be_truthy }
    end

    context 'with a valid timestamp' do
      let(:time) { five_seconds_ago }

      it { is_expected.to be_falsey }
    end

    context 'with the current time' do
      it { is_expected.to be_falsey }
    end

    context 'without a timestamp' do
      let(:time) { nil }

      it { is_expected.to be_nil }
    end
  end

  describe '#future?' do
    subject { timestamp.future? }

    context 'with a past timestamp' do
      let(:time) { two_hours_ago }

      it { is_expected.to be_falsey }
    end

    context 'with a present timestamp' do
      it { is_expected.to be_falsey }
    end

    context 'with a future timestamp' do
      let(:time) { two_hours_ahead }

      it { is_expected.to be_truthy }
    end
  
    context 'without a timestamp' do
      let(:time) { nil }

      it { is_expected.to be_nil }
    end
  end

  describe '#missing?' do
    subject { timestamp.missing? }

    context 'with a timestamp' do
      it { is_expected.to be_falsey }
    end

    context 'without a timestamp' do
      let(:time) { nil }

      it { is_expected.to be_truthy }
    end
  end

  describe '#reference_time' do
    subject { timestamp.reference_time }

    it { is_expected.to be now }
  end

  describe '#reference_timestamp' do
    subject { timestamp.reference_timestamp }

    it { is_expected.to eq now.strftime time_print_fmt }
  end

  describe '#time' do
    subject { timestamp.time }

    it { is_expected.to be time }
  end

  describe '#timestamp' do
    subject { timestamp.timestamp }

    it { is_expected.to eq now.strftime time_print_fmt }
  end

  describe '#to_s' do
    subject { timestamp.to_s }

    context 'with a valid timestamp' do
      it { is_expected.to eq now.strftime time_print_fmt }
    end

    context 'with an expired timestamp' do
      let(:time) { two_hours_ago }
      let(:msg) { expired_timestamp }

      it { is_expected.to start_with msg }
    end

    context 'with a future timestamp' do
      let(:time) { two_hours_ahead }
      let(:msg) { future_timestamp }

      it { is_expected.to start_with msg }
    end

    context 'without a timestamp' do
      let(:time) { nil }
      let(:msg) { missing_timestamp }

      it { is_expected.to eq msg }
    end
  end

  describe '#valid?' do
    subject { timestamp.valid? }

    context 'with an expired timestamp' do
      let(:time) { two_hours_ago }

      it { is_expected.to be_falsey }
    end

    context 'with a valid timestamp' do
      let(:time) { five_seconds_ago }

      it { is_expected.to be_truthy }
    end

    context 'with the current time' do
      it { is_expected.to be_truthy }
    end

    context 'with a future timestmap' do
      let(:time) { two_hours_ahead }

      it { is_expected.to be_falsey }
    end

    context 'without a timestamp' do
      let(:time) { nil }

      it { is_expected.to be_falsey }
    end
  end
  
  describe '#validity' do
    subject { timestamp.validity }

    it { is_expected.to be 30 }
  end
end
