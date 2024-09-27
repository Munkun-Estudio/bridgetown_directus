# lib/bridgetown_directus/utils.rb

module BridgetownDirectus
  module Utils
    def self.log_directus(message)
      Bridgetown.logger.info("Directus") { message }
    end
  end
end
