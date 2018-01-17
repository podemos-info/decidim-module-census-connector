# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module CensusConnector
    # This concern add methods and helpers to simplify access to census context.
    module CensusContext
      extend ActiveSupport::Concern

      included do
        helper_method :local_scope, :local_scope_ranges

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

        def person_data
          return {} unless has_person?
          @person_data ||= ::Census::API::Person.find(person_id)
        end

        def person_scope
          return nil unless has_person?
          @person_scope ||= Decidim::Scope.find_by(code: person_data[:scope_code])
        end

        def person_address_scope
          return nil unless has_person?
          @person_scope ||= Decidim::Scope.find_by(code: person_data[:address_scope_code])
        end
      end
    end
  end
end
