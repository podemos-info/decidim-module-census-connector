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

              person_id = ::Census::API::Person.create(person_params)

              authorization.update!(metadata: { "person_id" => person_id })
            else
              ::Census::API::Person.update(handler.id, person_params)
            end

            broadcast :ok
          end

          private

          def person_params
            attributes.except(:document_scope_id, :scope_id, :address_scope_id).merge(
              external_id_field => handler.user.id,
              email: handler.user.email,
              document_scope_code: handler.document_scope&.code,
              scope_code: handler.scope&.code,
              address_scope_code: handler.address_scope&.code
            )
          end

          def external_id_field
            :"id_at_#{Decidim::CensusConnector.system_identifier}"
          end
        end
      end
    end
  end
end
