# frozen_string_literal: true

module Census
  module API
    # This class represents a person in Census
    class Person
      include CensusAPI

      DOCUMENT_TYPES = %w(dni nie passport).freeze
      GENDERS = %w(female male other undisclosed).freeze
      MEMBERSHIP_LEVELS = %w(follower member).freeze
      STATES = %w(pending enabled cancelled trashed).freeze
      VERIFICATIONS = %w(not_verified verification_requested verified mistake fraudulent).freeze

      def self.document_types
        @document_types ||= Hash[DOCUMENT_TYPES.map { |type| [I18n.t("census.api.person.document_type.#{type}"), type] }].freeze
      end

      def self.genders
        @genders ||= Hash[GENDERS.map { |gender| [I18n.t("census.api.person.gender.#{gender}"), gender] }].freeze
      end

      def self.membership_levels
        @membership_levels ||= Hash[MEMBERSHIP_LEVELS.map do |membership_level|
          [I18n.t("census.api.person.membership_level.#{membership_level}"), membership_level]
        end].freeze
      end

      def self.local_document?(document_type)
        document_type != "passport"
      end

      # PUBLIC creates a person with the given params.
      def self.create(params)
        response = send_request do
          post("/api/v1/people", body: params)
        end
        response[:person_id]
      end

      # PUBLIC retrieve the available information for the given person.
      def self.find(qualified_id)
        send_request do
          get("/api/v1/people/#{qualified_id}")
        end
      end

      # PUBLIC update the given person with the given params.
      def self.update(qualified_id, params)
        send_request do
          patch("/api/v1/people/#{qualified_id}", body: params)
        end
      end

      # PUBLIC add a verification process for the given person.
      def self.create_verification(qualified_id, params)
        files = params[:files].map do |file|
          {
            filename: file.original_filename,
            content_type: file.content_type,
            base64_content: Base64.encode64(file.tempfile.read)
          }
        end

        send_request do
          post("/api/v1/people/#{qualified_id}/document_verifications", body: { files: files })
        end
      end

      def self.create_membership_level(qualified_id, params)
        send_request do
          post("/api/v1/people/#{qualified_id}/membership_levels", body: params)
        end
      end
    end
  end
end
