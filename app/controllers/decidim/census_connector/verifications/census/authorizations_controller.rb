# frozen_string_literal: true

module Decidim
  module CensusConnector
    module Verifications
      module Census
        #
        # Handles registration and verifications again the external census application
        #
        class AuthorizationsController < Decidim::CensusConnector::ApplicationController
          helper Decidim::SanitizeHelper

          before_action :authorize
          helper_method :current_step_path

          STEPS = %w(data verification membership_level).freeze

          def index
            if has_person?
              @handler = current_handler.from_model(person).with_context(form_context)
            else
              @handler = current_handler.new.with_context(form_context)
              @handler.use_default_values
            end
            render current_step
          end

          def create
            @handler = current_handler.from_params(current_handler_params).with_context(form_context)

            current_command.call(census_authorization, @handler) do
              on(:ok) do
                redirect_to next_path
              end

              on(:invalid) do
                flash.now[:alert] = t("errors.create", scope: "decidim.census_connector.verifications.census")
                render current_step
              end
            end
          end

          def update
            create
          end

          private

          def authorize
            authorize! :manage, census_authorization
          end

          def current_step
            @current_step ||= begin
              step = request[:step]
              if step && STEPS.member?(step) && person_id
                step
              else
                STEPS.first
              end
            end
          end

          def current_handler
            @current_handler ||= "decidim/census_connector/verifications/census/#{current_step}_handler".classify.constantize
          end

          def current_handler_params
            current_handler.safe_params(params)
          end

          def current_command
            @current_command ||= "decidim/census_connector/verifications/census/perform_census_#{current_step}_step".classify.constantize
          end

          def next_step
            @next_step ||= STEPS[STEPS.index(current_step) + 1]
          end

          def next_path
            @next_path ||= if next_step
                             decidim_census.root_path(authorization_params.merge(step: next_step))
                           else
                             authorization_params[:redirect_url] || decidim_verifications.authorizations_path(authorization_params.except(:step))
                           end
          end

          def current_step_path
            @current_step_path ||= decidim_census.authorization_path(
              authorization_params.merge(step: current_step)
            )
          end

          def form_context
            {
              user: current_user,
              person_id: person_id,
              local_scope: local_scope,
              person: person
            }
          end

          def authorization_params
            params.permit(:locale, :step, :redirect_url).to_h
          end
        end
      end
    end
  end
end
