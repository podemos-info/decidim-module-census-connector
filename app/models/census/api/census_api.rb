# frozen_string_literal: true

require "httparty"

module Census
  module API
    # Base class for all Census API classes
    class CensusAPI
      include ::HTTParty

      base_uri ::Decidim::CensusConnector.census_api_base_uri

      http_proxy Decidim::CensusConnector.census_api_proxy_address, Decidim::CensusConnector.census_api_proxy_port if Decidim::CensusConnector.census_api_proxy_address.present?

      debug_output if Decidim::CensusConnector.census_api_debug

      def self.send_request
        response = yield

        http_response_code = response.code.to_i
        return { http_response_code: http_response_code } if http_response_code == 500

        json_response = JSON.parse(response.body, symbolize_names: true)
        json_response[:http_response_code] = http_response_code
        json_response
      end
    end
  end
end
