# frozen_string_literal: true

RSpec.shared_context 'with time', shared_context: :metadata do
  let(:now) { Time.now.utc }
  let(:five_seconds_ago) { (DateTime.now - (5 / 86400.0)).to_time.utc }
  let(:two_hours_ago) { (DateTime.now - (2 / 24.0)).to_time.utc }
  let(:two_hours_ahead) { (DateTime.now + (2 / 24.0)).to_time.utc }
  let(:seconds_over_time) { (now - two_hours_ago - validity_in_sec).to_i }
  let(:seconds_ahead_of_time) { (two_hours_ahead - now).to_i }
  let(:validity_in_sec) { 30 }

  let(:time_print_fmt) { '%Y-%m-%d %H:%M:%S.%6L %Z' }
  let(:missing_timestamp) { 'Missing timestamp.' }

  let :expired_timestamp do
    "Expired timestamp: #{two_hours_ago.strftime time_print_fmt};"
  end

  let :future_timestamp do
    "Invalid timestamp: #{two_hours_ahead.strftime time_print_fmt};"
  end
end
