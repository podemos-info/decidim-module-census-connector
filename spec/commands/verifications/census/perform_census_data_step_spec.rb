# frozen_string_literal: true

require "spec_helper"
require "decidim/core/test/factories"
require "faker/spanish_document"

module Decidim::CensusConnector
  describe Verifications::Census::PerformCensusDataStep do
    subject { described_class.new(authorization, form) }

    let(:organization) { create(:organization) }
    let(:user) { create(:user, organization: organization) }

    let!(:authorization) { create(:authorization, name: "census", user: user, metadata: { "person_id" => 1 }) }
    let!(:scope) { create(:scope, code: "ES", organization: organization, id: 1) }

    let(:first_name) { "Marlin" }
    let(:last_name1) { "D'Amore" }
    let(:document_type) { "dni" }
    let(:document_id) { Faker::SpanishDocument.generate(:dni) }
    let(:born_at) { 18.years.ago }
    let(:gender) { "female" }
    let(:address) { "Rua del Percebe, 1" }
    let(:postal_code) { "08001" }

    let(:form) do
      Verifications::Census::DataForm.new(
        first_name: first_name,
        last_name1: last_name1,
        document_type: document_type,
        document_id: document_id,
        document_scope_id: 1,
        born_at: born_at,
        gender: gender,
        address: address,
        address_scope_id: 1,
        scope_id: nil,
        postal_code: postal_code
      ).with_context(
        person_proxy: PersonProxy.for(user),
        local_scope: scope,
        user: user
      )
    end

    context "when document id not present" do
      let(:document_id) { nil }

      before do
        VCR.use_cassette("missing_document") { subject.call }
      end

      it "adds the API error to the form" do
        expect(form.errors.count).to eq(1)
        expect(form.errors.first).to eq([:document_id, ["no puede estar en blanco"]])
      end
    end

    context "when document id invalid" do
      let(:document_id) { "11111111A" }

      before do
        VCR.use_cassette("invalid_document") { subject.call }
      end

      it "adds the API error to the form" do
        expect(form.errors.count).to eq(1)
        expect(form.errors.first).to eq([:document_id, ["no es válido"]])
      end
    end

    context "when first name not present" do
      let(:first_name) { nil }

      before do
        VCR.use_cassette("missing_first_name") { subject.call }
      end

      it "adds the API error to the form" do
        expect(form.errors.count).to eq(1)
        expect(form.errors.first).to eq([:first_name, ["no puede estar en blanco"]])
      end
    end

    context "when last name not present" do
      let(:last_name1) { nil }

      before do
        VCR.use_cassette("missing_last_name") { subject.call }
      end

      it "adds the API error to the form" do
        expect(form.errors.count).to eq(1)
        expect(form.errors.first).to eq([:last_name1, ["no puede estar en blanco"]])
      end
    end

    context "when birth date not present" do
      let(:born_at) { nil }

      before do
        VCR.use_cassette("missing_birth_date") { subject.call }
      end

      it "adds the API error to the form" do
        expect(form.errors.count).to eq(1)
        expect(form.errors[:born_at]).to eq([["no puede estar en blanco"]])
      end
    end

    context "when document type invalid" do
      let(:document_type) { "dani" }

      before do
        VCR.use_cassette("invalid_document_type") { subject.call }
      end

      it "adds the API errors to the form" do
        expect(form.errors.count).to eq(2)
        expect(form.errors[:document_type]).to eq([["no está incluido en la lista"]])
        expect(form.errors[:document_id]).to eq([["no es válido"]])
      end
    end

    context "when gender not present" do
      let(:gender) { nil }

      before do
        VCR.use_cassette("missing_gender") { subject.call }
      end

      it "adds the API errors to the form" do
        expect(form.errors.count).to eq(1)
        expect(form.errors[:gender]).to eq([["no puede estar en blanco"]])
      end
    end

    context "when gender invalid" do
      let(:gender) { "ardilla" }

      before do
        VCR.use_cassette("invalid_gender") { subject.call }
      end

      it "adds the API errors to the form" do
        expect(form.errors.count).to eq(1)
        expect(form.errors[:gender]).to eq([["no está incluido en la lista"]])
      end
    end

    context "when address not present" do
      let(:address) { nil }

      before do
        VCR.use_cassette("missing_address") { subject.call }
      end

      it "adds the API errors to the form" do
        expect(form.errors.count).to eq(1)
        expect(form.errors[:address]).to eq([["no puede estar en blanco"]])
      end
    end

    context "when postal code not present" do
      let(:postal_code) { nil }

      before do
        VCR.use_cassette("missing_postal_code") { subject.call }
      end

      it "adds the API errors to the form" do
        expect(form.errors.count).to eq(1)
        expect(form.errors[:postal_code]).to eq([["no puede estar en blanco"]])
      end
    end
  end
end
