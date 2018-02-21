# frozen_string_literal: true

module Decidim
  module CensusConnector
    module Verifications
      module Census
        class ActionAuthorizer < Decidim::Verifications::DefaultActionAuthorizer
          def authorize
            @allowed_document_types = options.delete("allowed_document_types")
            @minimum_age = options.delete("minimum_age")

            status_code, data = *super

            return [status_code, data] if status_code == :missing

            if minimum_age.present? && age < minimum_age
              status_code = :unauthorized
              add_unmatched_field(data, "age" => age)
            end

            if allowed_document_types.present? && document_type == "passport"
              status_code = :unauthorized
              add_unmatched_field(data, "document_type" => document_type_label)
            end

            if minimum_age.present? || allowed_document_types.present?
              data[:extra_explanation] = {
                key: "extra_explanation",
                params: {
                  scope: "decidim.census_connector.verifications.census",
                  minimum_age: minimum_age,
                  allowed_documents: allowed_document_types.to_sentence(words_connector: " #{I18n.t("or")} ")
                }
              }
            end

            [status_code, data]
          end

          # Adds the list of allowed postal codes to the redirect URL, to allow forms to inform about it
          def redirect_params
            {
              "document_types" => allowed_document_types&.join("-"),
              "mimimum_age" => minimum_age
            }
          end

          private

          def add_unmatched_field(data, field)
            data[:fields] ||= {}

            data[:fields].merge!(field)
          end

          def age
            person.age
          end

          def document_type
            person.document_type
          end

          def document_type_label
            I18n.t(document_type, scope: "census.api.person.document_type")
          end

          def allowed_document_types
            @allowed_document_types.split(",").map(&:chomp)
          end

          def minimum_age
            @minimum_age&.to_i
          end

          def person
            PersonProxy.new(authorization.metadata["person_id"]).person
          end
        end
      end
    end
  end
end
