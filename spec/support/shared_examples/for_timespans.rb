# frozen_string_literal: true

RSpec.shared_examples 'a timespan' do
  it 'returns the correct number of hours' do
    expect(timespan.hours).to be hours
  end

  it 'returns the correct number of hours' do
    expect(timespan.minutes).to be minutes
  end

  it 'returns the correct number of hours' do
    expect(timespan.seconds).to be seconds
  end

  it 'calculates the total number of seconds' do
    expect(timespan.to_seconds).to be total_seconds
  end
end
