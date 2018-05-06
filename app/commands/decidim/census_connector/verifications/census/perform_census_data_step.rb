# frozen_string_literal: true

module Decidim
  module CensusConnector
    module Verifications
      module Census
        # A command to create a partial authorization for a user.
        class PerformCensusDataStep < PerformCensusStep
          def perform
            if authorization.new_record?
              broadcast :invalid unless handler.valid?

              handler.id = ::Census::API::Person.create(person_params)

              authorization.metadata = { "person_id" => handler.id }
            else
              ::Census::API::Person.update(handler.id, person_params)
            end

            update_authorization

            broadcast :ok
          end

          private

          def update_authorization
            if person.enabled?
              authorization.grant!
            else
              authorization.save!
            end
          end

          def person_params
            attributes.except(:document_scope_id, :scope_id, :address_scope_id).merge(
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
