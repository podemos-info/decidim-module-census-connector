# frozen_string_literal: true

require "spec_helper"

require "decidim/core/test/factories"

describe "Census person creation", type: :system do
  let!(:organization) do
    create(:organization, available_authorizations: ["census"])
  end

  let!(:scope) { create(:scope, code: "ES", id: 1) }

  let!(:user) { create(:user, :confirmed, organization: organization) }

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
    visit decidim_census.root_path
  end

  it "goes through the first form" do
    expect(page).to have_content("Personal data")

    complete_data_step
    expect(page).to have_content("Identity verification")

    complete_document_step
    expect(page).to have_content("Membership level")

    complete_membership_step
    expect(page).to have_content("Granted at")
  end

  private

  def complete_data_step
    fill_in "Name", with: "Peter"
    fill_in "First surname", with: "Lopez"
    fill_in "Document", with: "71195206V"
    choose "Female"

    page.execute_script("$('#date_field_data_handler_born_at').focus()")
    page.find(".datepicker-dropdown .year", text: "2000").click
    page.find(".datepicker-dropdown .month", text: "Jun").click
    page.find(".datepicker-dropdown .day", text: "10").click

    fill_in "Address", with: "Rua del Percebe, 1"
    fill_in "Postal code", with: "08001"

    submit_verification_form
  end

  def complete_document_step
    attach_file "verification_handler_document_file1", Decidim::Dev.asset("id.jpg"), visible: false
    attach_file "verification_handler_document_file2", Decidim::Dev.asset("id.jpg"), visible: false

    submit_verification_form
  end

  def complete_membership_step
    choose "Follower"

    submit_verification_form
  end

  def submit_verification_form
    VCR.use_cassette("verification") do
      click_button "Send"
    end
  end
end
