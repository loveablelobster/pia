# frozen_string_literal: true

module Pia
  # Pluging that provides easy access to a logger.
  module Logger
    # Extends the application with class methods that facilitate access to a
    # logger.
    module ClassMethods
      # Returns a logger object.
      def logger
        opts[:common_logger]
      end
    end

    # Includes methods to facilitate logging into the class.
    module RequestMethods
      # Writes +message+ to the application's logger object.
      def log(message)
        return unless roda_class.logger

        roda_class.logger << message
      end
    end
  end
end
