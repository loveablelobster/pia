# frozen_string_literal: true

require_relative '../../support/shared_examples/for_timespans'

module Pia
  RSpec.describe Timespan do
    describe '.in_seconds' do
      subject(:span) { described_class.in_seconds timestring }

      let(:timestring) { '1h 20m 45s' }

      it 'calculates the total number of seconds for the string' do
        expect(span).to be 4845
      end

      context 'when string contains arbitrary whitespace' do
        let(:timestring) { '1h   20m45s' }

        it 'calculates the total number of seconds for the string' do
          expect(span).to be 4845
        end
      end

      context 'when string contains mixed case' do
        let(:timestring) { '1H 20m 45S' }

        it 'calculates the total number of seconds for the string' do
          expect(span).to be 4845
        end
      end
    end

    describe '#to_h' do
      subject { described_class.new('1h 20m 45s').to_h }

      it { is_expected.to include h: 1, m: 20, s: 45 }
    end

    describe '#to_s' do
      subject { described_class.new('1h 20m 45s').to_s }

      it { is_expected.to eq '1h 20m 45s' }
    end

    context 'when only hours are given' do
      it_behaves_like 'a timespan' do
        let(:timespan) { described_class.new '3h' }
        let(:hours) { 3 }
        let(:minutes) { 0 }
        let(:seconds) { 0 }
        let(:total_seconds) { 10_800 }
      end
    end

    context 'when only minutes are given' do
      it_behaves_like 'a timespan' do
        let(:timespan) { described_class.new '30m' }
        let(:hours) { 0 }
        let(:minutes) { 30 }
        let(:seconds) { 0 }
        let(:total_seconds) { 1_800 }
      end
    end

    context 'when only seconds are given' do
      it_behaves_like 'a timespan' do
        let(:timespan) { described_class.new '15s' }
        let(:hours) { 0 }
        let(:minutes) { 0 }
        let(:seconds) { 15 }
        let(:total_seconds) { 15 }
      end
    end

    context 'when hours and minutes are given' do
      it_behaves_like 'a timespan' do
        let(:timespan) { described_class.new '1h 15m' }
        let(:hours) { 1 }
        let(:minutes) { 15 }
        let(:seconds) { 0 }
        let(:total_seconds) { 4_500 }
      end
    end

    context 'when minutes and seconds are given' do
      it_behaves_like 'a timespan' do
        let(:timespan) { described_class.new '1m 30s' }
        let(:hours) { 0 }
        let(:minutes) { 1 }
        let(:seconds) { 30 }
        let(:total_seconds) { 90 }
      end
    end

    context 'when hours and seconds are given' do
      it_behaves_like 'a timespan' do
        let(:timespan) { described_class.new '1h 5s' }
        let(:hours) { 1 }
        let(:minutes) { 0 }
        let(:seconds) { 5 }
        let(:total_seconds) { 3_605 }
      end
    end

    context 'when hours, minutes, and seconds are given' do
      it_behaves_like 'a timespan' do
        let(:timespan) { described_class.new '1h 20m 45s' }
        let(:hours) { 1 }
        let(:minutes) { 20 }
        let(:seconds) { 45 }
        let(:total_seconds) { 4_845 }
      end
    end
  end
end
