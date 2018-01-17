# frozen_string_literal: true

require "rails"
require "active_support/all"

require "decidim/core"

module Decidim
  module CensusConnector
    # Decidim's CensusConnector Rails Engine.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::CensusConnector

      initializer "decidim_census_conector.inject_abilities_to_user" do |_app|
        Decidim.configure do |config|
          config.abilities += ["Decidim::CensusConnector::Verifications::Abilities::CurrentUserAbility"]
        end
      end

      initializer "decidim_census_connector.assets" do |app|
        app.config.assets.precompile += %w(decidim_census_connector_manifest.js decidim_census_connector_manifest.css)
      end
    end
  end
end
