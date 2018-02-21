# frozen_string_literal: true

module Decidim
  module CensusConnector
    module Verifications
      module Census
        class ActionAuthorizer < Decidim::Verifications::DefaultActionAuthorizer
          def authorize
            @allowed_document_types = options.delete("allowed_document_types")
            @minimum_age = options.delete("minimum_age")

            @status_code, @data = *super

            return [@status_code, @data] if @status_code == :missing

            authorize_age

            authorize_document_types

            return [@status_code, @data] if @status_code == :ok

            add_extra_explanation

            [@status_code, @data]
          end

          def redirect_params
            params = {}
            params[:minimum_age] = minimum_age if authorizing_by_age?
            params[:allowed_documents] = humanized_allowed_documents if authorizing_by_document_types?
            params
          end

          private

          def authorizing_by_age?
            minimum_age.present?
          end

          def authorizing_by_document_types?
            allowed_document_types.present?
          end

          def authorizing_by_age_and_document_types?
            authorizing_by_age? && authorizing_by_document_types?
          end

          def authorize_age
            if authorizing_by_age? && age < minimum_age
              @status_code = :unauthorized

              add_unmatched_field("age" => age)
            end
          end

          def authorize_document_types
            if authorizing_by_document_types? && document_type == "passport"
              @status_code = :unauthorized

              add_unmatched_field("document_type" => document_type_label)
            end
          end

          def add_extra_explanation
            return unless authorizing_by_age? || authorizing_by_document_types?

            key = if authorizing_by_age_and_document_types?
                    "extra_explanation_age_and_document_type"
                  elsif authorizing_by_age?
                    "extra_explanation_age"
                  else
                    "extra_explanation_document_type"
                  end

            @data[:extra_explanation] = {
              key: key,
              params: redirect_params.merge(scope: "decidim.census_connector.verifications.census")
            }
          end

          def humanized_allowed_documents
            allowed_document_types.to_sentence(
              words_connector: " #{I18n.t("or", scope: "decidim.census_connector.verifications.census")} "
            )
          end

          def add_unmatched_field(field)
            @data[:fields] ||= {}

            @data[:fields].merge!(field)
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
