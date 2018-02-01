# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module CensusConnector
    # This concern add methods and helpers to simplify access to census context.
    module CensusContext
      extend ActiveSupport::Concern

      included do
        helper_method :local_scope, :local_scope_ranges, :has_person?, :person, :person_participatory_spaces

        def local_scope
          @local_scope ||= Decidim::Scope.find_by(code: Decidim::CensusConnector.census_local_code)
        end

        # PUBLIC: returns a list of ranges of local scopes ids
        def local_scope_ranges
          @local_scope_ranges ||= begin
            ranges = []
            current_range = []
            local_scope.descendants.reorder(id: :asc).pluck(:id).each do |scope_id|
              if current_range.last && current_range.last + 1 != scope_id
                ranges << [current_range.first, current_range.last]
                current_range = []
              end
              current_range << scope_id
            end
            ranges << [current_range.first, current_range.last]
          end
        end

        def person_scopes
          @person_scopes ||= begin
            scopes = Set[nil]
            if has_person?
              scopes.merge(person.scope.part_of)
              scopes.merge(person.address_scope.part_of)
            end
            scopes.to_a
          end
        end

        def person_participatory_spaces
          @person_participatory_spaces ||= Decidim.participatory_space_registry.manifests.flat_map do |participatory_space_manifest|
            participatory_space_model = participatory_space_manifest.model_class_name.constantize
            next unless participatory_space_model.columns_hash["decidim_scope_id"]
            participatory_space_model.published.where(decidim_scope_id: person_scopes)
          end.compact
        end

        def census_authorization
          @census_authorization ||= Decidim::Authorization.find_or_initialize_by(
            user: current_user,
            name: "census"
          ) do |authorization|
            authorization.metadata = {}
          end
        end

        def person_id
          @person_id ||= census_authorization.metadata["person_id"]&.to_i
        end

        def has_person?
          person_id.present?
        end

        def person
          return nil unless has_person?
          @person ||= begin
            person_data = ::Census::API::Person.find(person_id)
            Person.new(person_data)
          end
        end
      end

      class Person
        delegate :first_name, :last_name1, :last_name2, to: :person_data
        delegate :document_type, :document_id, to: :person_data
        delegate :address, :postal_code, to: :person_data
        delegate :membership_level, :gender, to: :person_data
        delegate :id, to: :scope, prefix: true
        delegate :id, to: :address_scope, prefix: true
        delegate :id, to: :document_scope, prefix: true

        def initialize(person_data)
          @person_data = OpenStruct.new(person_data)
        end

        def scope
          @scope ||= Decidim::Scope.find_by(code: person_data.scope_code)
        end

        def address_scope
          @address_scope ||= Decidim::Scope.find_by(code: person_data.address_scope_code)
        end

        def document_scope
          @document_scope ||= Decidim::Scope.find_by(code: person_data.document_scope_code)
        end

        def born_at
          @born_at ||= Date.parse(person_data.born_at)
        end

        private

        attr_reader :person_data
      end
    end
  end
end
