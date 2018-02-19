# frozen_string_literal: true

module Decidim
  module CensusConnector
    module Verifications
      module Census
        class VerificationHandler < CensusHandler
          attribute :document_file1
          attribute :document_file2
          attribute :tos_agreement, Boolean

          validates :document_file1, presence: true
          validates :document_file2, presence: true, if: :require_document_file2?
          validates :tos_agreement, allow_nil: true, acceptance: true

          def self.safe_params(params)
            params.require(:verification_handler).permit(:document_file1, :document_file2, :tos_agreement)
          end

          def require_document_file2?
            document_type == "passport"
          end

          def document_type
            @document_type ||= context.person.document_type
          end

          def information_page
            @information_page ||= Decidim::StaticPage.find_by(slug: "verification-information")
          end

          def terms_and_conditions_page
            @terms_and_conditions_page ||= Decidim::StaticPage.find_by(slug: "verification-terms-and-conditions")
          end
        end
      end
    end
  end
end
