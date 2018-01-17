# frozen_string_literal: true

module Decidim
  module CensusConnector
    module Verifications
      module Census
        class ActionAuthorizer < Decidim::Verifications::DefaultActionAuthorizer
          attr_reader :allowed_postal_codes

          def authorize
            # Remove the additional setting from the options hash to avoid to be considered missing.
            @membership_level ||= options.delete("membership_level")
            @scope ||= options.delete("scope")

            status_code, data = *super
            [status_code, data]
          end

          # Adds the list of allowed postal codes to the redirect URL, to allow forms to inform about it
          def redirect_params
            { "postal_codes" => allowed_postal_codes&.join("-") }
          end
        end
      end
    end
  end
end
