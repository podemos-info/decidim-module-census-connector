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

        def qualified_id
          @qualified_id ||= "#{current_user.id}@#{Decidim::CensusConnector.system_identifier}"
        end

        def person_id
          @person_id ||= census_authorization.metadata["person_id"]
        end

        def has_person?
          person_id.present?
        end

        def person
          return nil unless has_person?

          @person ||= PersonProxy.new(qualified_id).person
        end
      end
    end
  end
end
