# frozen_string_literal: true

require "participa2/seeds/scopes"

namespace :decidim_census_connector do
  desc "Update scopes with data located on seeds/scopes folder"
  task :update_scopes, [:organization_id] => :environment do |_t, args|
    organization = Decidim::Organization.find(args[:organization_id])
    base_path = File.expand_path("../../../db/seeds", __dir__)
    Decidim::CensusConnector::Seeds.seed_scopes(organization, base_path: base_path)
  end
end
