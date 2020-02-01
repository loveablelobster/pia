# frozen_string_literal: true

module Pia
  module Logger
    module ClassMethods
      def logger
        opts[:common_logger]
      end
    end

    module RequestMethods
      def log(message)
        return unless roda_class.logger
        roda_class.logger << message
      end
    end
  end
end
