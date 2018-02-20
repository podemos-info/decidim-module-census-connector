# frozen_string_literal: true

module Decidim
  module CensusConnector
    class PersonProxy
      def initialize(id)
        @id = id
      end

      def person
        @person ||= begin
          person_data = ::Census::API::Person.find(@id)
          Person.new(person_data)
        end
      end
    end
  end
end
