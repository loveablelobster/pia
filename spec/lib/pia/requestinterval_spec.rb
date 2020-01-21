# frozen_string_literal: true

RSpec.describe Pia::Requestinterval do
  include_context 'with request'
  include_context 'with time'

  let :app do
    _app do
      plugin Pia::Requestinterval
      route do |r|
        r.on do
          r.validate_timestamp
          r.timestamp
        end
      end
    end
  end

  before { app.opts[:common_logger] = logger }

  context 'with a valid timestamp' do
    it_behaves_like 'a rack app', :post, '/', :to do
      let(:message) { timestamp now }
      let(:status) { 200 }
    end
  end

  context 'with an invalid timestamp' do
    let(:message) { '{"message":"Bad request. Ignored."}' }
    let(:status) { 111 }

    context 'when the timestamp is expired' do
      before { body[:timestamp] = timestamp two_hours_ago }

      let(:log_msg) { start_with "Request aborted. #{expired_timestamp}" }

      it_behaves_like 'a rack app', :post, '/', :not_to
      it_behaves_like 'a logger', :post, '/', :warn
    end

    context 'when the timestamp is in the future' do
      before { body[:timestamp] = timestamp two_hours_ahead }

      let(:log_msg) { start_with "Request aborted. #{future_timestamp}" }

      it_behaves_like 'a rack app', :post, '/', :not_to
      it_behaves_like 'a logger', :post, '/', :warn
    end

    context 'without a timestamp' do
      before { body[:timestamp] = nil }

      let(:log_msg) { 'Request aborted. Missing timestamp.' }

      it_behaves_like 'a rack app', :post, '/', :not_to
      it_behaves_like 'a logger', :post, '/', :warn
    end
  end
end
