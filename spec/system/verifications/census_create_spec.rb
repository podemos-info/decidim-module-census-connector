# frozen_string_literal: true

require "spec_helper"

require "decidim/core/test/factories"

describe "Census person creation", type: :system do
  let!(:organization) do
    create(:organization, available_authorizations: ["census"])
  end

  let!(:scope) { create(:scope, code: "ES") }

  let!(:user) { create(:user, :confirmed, organization: organization) }

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
    visit decidim_census.root_path
  end

  it "redirects to personal data page after login" do
    expect(page).to have_content("Personal data")
  end
end
