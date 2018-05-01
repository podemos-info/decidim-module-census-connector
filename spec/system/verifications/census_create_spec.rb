# frozen_string_literal: true

require "spec_helper"

require "decidim/core/test/factories"

describe "Census verification workflow", type: :system do
  let!(:organization) do
    create(:organization, available_authorizations: ["census"])
  end

  let!(:scope) { create(:scope, code: "ES", id: 1) }

  let!(:user) { create(:user, :confirmed, organization: organization) }

  let(:birth_date) { age.years.ago.strftime("%Y-%b-%d") }

  let(:participatory_space) do
    create(:participatory_process, organization: organization)
  end

  let(:feature) do
    create(
      :feature,
      participatory_space: participatory_space,
      permissions: {
        "foo" => {
          "authorization_handler_name" => "census",
          "options" => {
            "minimum_age" => 18,
            "allowed_document_types" => %w(dni nie)
          }
        }
      }
    )
  end

  let(:dummy_resource) { create(:dummy_resource, feature: feature) }

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
  end

  context "when person not registered with census" do
    before do
      visit resource_locator(dummy_resource).path
      click_link "Foo"
    end

    it "shows popup to require verification" do
      expect(page).to have_content(
        'In order to perform this action, you need to be authorized with "Census"'
      )
    end
  end

  context "when person registered with census" do
    let(:age) { 18 }
    let(:document_type) { "DNI" }

    let(:cassette) { "regular_verification" }

    before do
      VCR.use_cassette(cassette) do
        register_with_census

        visit resource_locator(dummy_resource).path

        click_link "Foo"
      end
    end

    it "grants access to foo" do
      expect(page).to have_current_path(/foo/)
    end

    context "when too young" do
      let(:age) { 17 }

      let(:cassette) { "child_verification" }

      it "shows popup to require verification" do
        expect(page).to have_content(
          "You need to be a least 18 years old and be registered with dni and nie."
        ).and have_content(
          "Age value (#{age}) isn't valid."
        )
      end
    end

    context "when using passport" do
      let(:document_type) { "Passport" }

      let(:cassette) { "verification_with_passport" }

      it "shows popup to require verification" do
        expect(page).to have_content(
          "You need to be a least 18 years old and be registered with dni and nie."
        ).and have_content(
          "Document type value (#{document_type}) isn't valid."
        )
      end
    end

    context "when too young and using passport" do
      let(:age) { 17 }

      let(:document_type) { "Passport" }

      let(:cassette) { "child_verification_with_passport" }

      it "shows popup to require verification" do
        expect(page).to have_content(
          "You need to be a least 18 years old and be registered with dni and nie."
        ).and have_content(
          "Document type value (#{document_type}) isn't valid."
        ).and have_content(
          "Age value (#{age}) isn't valid."
        )
      end
    end
  end

  private

  def register_with_census
    visit decidim_census.root_path

    complete_data_step
    complete_document_step
    complete_membership_step
  end

  def complete_data_step
    fill_in "Name", with: "Peter"
    fill_in "First surname", with: "Lopez"

    select document_type, from: "Document type"

    fill_in "Document", with: document_type == "DNI" ? "71195206V" : "R7232537748"

    choose "Female"

    year, month, day = birth_date.split("-")

    execute_script("$('#date_field_data_handler_born_at').focus()")
    find(".datepicker-dropdown .year", text: year).click
    find(".datepicker-dropdown .month", text: month).click
    find(".datepicker-dropdown .day", text: day).click

    fill_in "Address", with: "Rua del Percebe, 1"
    fill_in "Postal code", with: "08001"

    click_button "Send"
  end

  def complete_document_step
    attach_file "verification_handler_document_file1", Decidim::Dev.asset("id.jpg"), visible: false
    attach_file "verification_handler_document_file2", Decidim::Dev.asset("id.jpg"), visible: false

    click_button "Send"
  end

  def complete_membership_step
    choose "Follower"

    click_button "Send"
  end
end
