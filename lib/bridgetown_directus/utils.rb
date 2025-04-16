# lib/bridgetown_directus/utils.rb

module BridgetownDirectus
  module Utils
    def self.log_directus(message)
      if defined?(Bridgetown) && Bridgetown.respond_to?(:logger)
        Bridgetown.logger.info("Directus") { message }
      elsif ENV["BRIDGETOWN_DIRECTUS_DEBUG"]
        # Fallback for testing or when Bridgetown is not available
        puts "[Directus] #{message}"
      end
    end
  end
end
