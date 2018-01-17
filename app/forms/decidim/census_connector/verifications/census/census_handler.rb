# frozen_string_literal: true

module Decidim
  module CensusConnector
    module Verifications
      module Census
        class CensusHandler < Decidim::AuthorizationHandler
          delegate :local_scope, :user, :person_id, to: :context

          def use_default_values; end

          def handler_name
            "census"
          end

          def id
            person_id || @id
          end

          def metadata
            {
              "person_id" => id
            }
          end
        end
      end
    end
  end
end
