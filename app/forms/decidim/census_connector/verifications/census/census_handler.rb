# frozen_string_literal: true

module Decidim
  module CensusConnector
    module Verifications
      module Census
        class CensusHandler < Decidim::AuthorizationHandler
          delegate :local_scope, :user, :qualified_id, to: :context

          def use_default_values; end

          def handler_name
            "census"
          end

          def id
            qualified_id || @id
          end

          def metadata
            {
              "qualified_id" => id
            }
          end
        end
      end
    end
  end
end
