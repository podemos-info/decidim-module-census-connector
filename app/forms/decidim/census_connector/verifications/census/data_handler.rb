# frozen_string_literal: true

module Decidim
  module CensusConnector
    module Verifications
      module Census
        class DataHandler < CensusHandler
          def self.document_scopes
            @document_scopes ||= Decidim::Scope.top_level.order(name: :asc)
          end

          def self.document_types
            ::Census::API::Person.document_types
          end

          def self.genders
            ::Census::API::Person.genders
          end

          attribute :first_name, String
          attribute :last_name1, String
          attribute :last_name2, String

          attribute :document_type, String
          attribute :document_id, String
          attribute :document_scope_id, Integer

          attribute :born_at, Date
          attribute :gender, String

          attribute :address, String
          attribute :address_scope_id, Integer
          attribute :scope_id, Integer
          attribute :postal_code, String

          validates :first_name, :last_name1, :born_at, :address, presence: true
          validates :document_type, inclusion: { in: document_types.values }
          validates :document_id, format: { with: /\A[A-z0-9]*\z/, message: I18n.t("errors.messages.uppercase_only_letters_numbers") }, presence: true
          validates :document_scope, presence: true, unless: :local_document?
          validates :gender, inclusion: { in: genders.values }, presence: true
          validates :postal_code, presence: true, format: { with: /\A[0-9]*\z/, message: I18n.t("errors.messages.uppercase_only_letters_numbers") }
          validates :scope_id, :address_scope_id, presence: true

          validate :over_min_age

          def use_default_values
            @document_scope_id = @address_scope_id = @scope_id = local_scope.id
            @document_scope = @address_scope = @scope = local_scope
            @document_type = self.class.document_types.values.first
          end

          def document_scope
            @document_scope ||= begin
              if local_document?
                local_scope
              else
                Decidim::Scope.find_by(id: document_scope_id)
              end
            end
          end

          def address_scope
            @address_scope ||= Decidim::Scope.find_by(id: address_scope_id)
          end

          def scope
            @scope ||= begin
              if local_scope.ancestor_of?(address_scope)
                address_scope
              else
                Decidim::Scope.find_by(id: scope_id)
              end
            end
          end

          def local_document?
            ::Census::API::Person.local_document? document_type
          end

          def self.safe_params(params)
            params.require(:data_handler).permit(:first_name, :last_name1, :last_name2, :document_type, :document_id, :document_scope_id, :born_at, :gender,
                                                 :address, :address_scope_id, :scope_id, :postal_code)
          end

          private

          def over_min_age
            minimum_age = Decidim::CensusConnector.person_minimum_age
            if born_at.present? && born_at >= minimum_age.years.ago
              errors.add(:born_at, I18n.t("errors.age_under_minimum_age", scope: "decidim.census_connector.verifications.census", min_age: minimum_age))
            end
          end
        end
      end
    end
  end
end
