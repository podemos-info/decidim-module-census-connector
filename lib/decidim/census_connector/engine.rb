# frozen_string_literal: true

require "rails"
require "active_support/all"

require "decidim/core"

module Decidim
  module CensusConnector
    # Decidim's CensusConnector Rails Engine.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::CensusConnector

      initializer "decidim_census_conector.inject_abilities_to_user" do
        Decidim.configure do |config|
          config.abilities += ["Decidim::CensusConnector::Verifications::Abilities::CurrentUserAbility"]
        end
      end

      initializer "decidim_census_connector.assets" do |app|
        app.config.assets.precompile += %w(decidim_census_connector_manifest.js decidim_census_connector_manifest.css)
      end

      initializer "decidim_census_connector.mount_routes" do
        Decidim.register_global_engine "decidim_census_account", Decidim::CensusConnector::Account::Engine, at: "census_account"
      end

      def load_seed
        Decidim::Organization.find_each do |organization|
          break if Decidim::Scope.find_by(code: "ES", organization: organization)

          country = Decidim::ScopeType.create_with(
            plural: Decidim::Faker::Localized.literal("countries")
          ).find_or_initialize_by(
            name: Decidim::Faker::Localized.literal("country"),
            organization: organization
          )

          Decidim::Scope.create!(
            code: "ES",
            organization: organization,
            name: Decidim::Faker::Localized.literal(::Faker::Address.unique.state),
            scope_type: country
          )
        end
      end
    end
  end
end
