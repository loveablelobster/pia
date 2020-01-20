# frozen_string_literal: true

RSpec.describe Pia::Middleware::RequestInterval do
  include_context 'with request'

  let(:app) { described_class.new rack_app, timeout: '30s', logger: logger }

  let(:message) { '{"message":"Bad request. Ignored."}' }
  let(:status) { 111 }
  let(:warn) { 'WARN -- : Attempted file upload' }
  let(:warn_invalid) { "#{warn} with an invalid timestamp:" }

  context 'when called with a valid timestamp' do
    it_behaves_like 'a rack app', :post, '/', :to do
      let(:message) { success }
      let(:status) { 200 }
    end
  end

  context 'when called with an expired timestamp' do
    before { body[:timestamp] = timestamp two_hours_ago }

    it_behaves_like 'a rack app', :post, '/', :not_to

    it_behaves_like 'a logger' do
      let :log_msg do
        end_with "#{warn_invalid} #{timestamp(two_hours_ago)}.\n"
      end
    end
  end

  context 'when called with a future timestamp' do
    before { body[:timestamp] = timestamp two_hours_ahead }

    it_behaves_like 'a rack app', :post, '/', :not_to

    it_behaves_like 'a logger' do
      let :log_msg do
        end_with "#{warn_invalid} #{timestamp(two_hours_ahead)}.\n"
      end
    end
  end

  context 'when called without a timestamp' do
    let(:log_msg) { end_with "#{warn} without a timestamp.\n" }

    context 'when timestamp key is missing' do
      before { body.delete(:timestamp) }

      it_behaves_like 'a rack app', :post, '/', :not_to
      it_behaves_like 'a logger'
    end

    context 'when timestamp value is missing' do
      before { body[:timestamp] = nil }

      it_behaves_like 'a rack app', :post, '/', :not_to
      it_behaves_like 'a logger'
    end
  end
end
