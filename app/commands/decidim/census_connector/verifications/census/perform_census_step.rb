# frozen_string_literal: true

module Decidim
  module CensusConnector
    module Verifications
      module Census
        # A command to create a partial authorization for a user.
        class PerformCensusStep < Rectify::Command
          # Public: Initializes the command.
          #
          # authorization - An Authorization object.
          # handler - An AuthorizationHandler object.
          def initialize(authorization, handler)
            @authorization = authorization
            @handler = handler
          end

          # Executes the command. Broadcasts these events:
          #
          # - :ok when everything is valid.
          # - :invalid if the handler wasn't valid and we couldn't proceed.
          #
          # Returns nothing.
          def call
            return broadcast(:invalid) if handler.invalid?

            perform
          end

          protected

          def attributes
            handler.attributes.except(:person_id, :user, :handler_name)
          end

          private

          attr_reader :authorization, :handler
        end
      end
    end
  end
end