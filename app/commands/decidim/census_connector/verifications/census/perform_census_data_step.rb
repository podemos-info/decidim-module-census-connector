# frozen_string_literal: true

module Decidim
  module CensusConnector
    module Verifications
      module Census
        # A command to create a partial authorization for a user.
        class PerformCensusDataStep < PerformCensusStep
          def perform
            res = :invalid
            if authorization.new_record?
              handler.id = ::Census::API::Person.create(person_params)
              ::Decidim::Verifications::AuthorizeUser.call(handler) do
                on(:ok) { res = :ok }
              end
            else
              ::Census::API::Person.update(handler.id, person_params)
              res = :ok
            end
            broadcast(res)
          end

          private

          def person_params
            attributes.except(:scope_id, :address_scope_id).merge(
              extra: { participa_id: handler.user.id },
              email: handler.user.email,
              document_scope_code: handler.document_scope&.code,
              scope_code: handler.scope&.code,
              address_scope_code: handler.address_scope&.code
            )
          end
        end
      end
    end
  end
end
