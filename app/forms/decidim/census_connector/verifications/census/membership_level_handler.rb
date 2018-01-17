# frozen_string_literal: true

module Decidim
  module CensusConnector
    module Verifications
      module Census
        class MembershipLevelHandler < CensusHandler
          attribute :membership_level, Symbol

          def self.membership_levels
            ::Census::API::Person.membership_levels
          end

          def self.safe_params(params)
            params.require(:membership_level_handler).permit(:membership_level)
          end
        end
      end
    end
  end
end
