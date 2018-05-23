# frozen_string_literal: true

require "csv"

module Decidim
  module CensusConnector
    module Seeds
      class Scopes
        EXTERIOR_SCOPE = "XX"
        CACHE_PATH = Rails.root.join("tmp", "cache", "#{Rails.env}_scopes.csv").freeze

        def initialize(organization)
          @organization = organization
        end

        def seed(options = {})
          base_path = options[:base_path] || File.expand_path(File.join("..", "..", "..", "..", "db", "seeds"), __dir__)
          @path = File.join(base_path, "scopes")

          save_scope_types(File.join(@path, "scope_types.tsv"))
          save_scopes(File.join(@path, "scopes.tsv"), File.join(@path, "scopes.translations.tsv"))
        end

        private

        def save_scope_types(source)
          puts "Loading scope types..."
          @scope_types = Hash.new { |h, k| h[k] = Hash.new { |h2, k2| h2[k2] = {} } }
          CSV.foreach(source, col_sep: "\t", headers: true) do |row|
            @scope_types[row["Code"]][:id] = row["UID"]
            @scope_types[row["Code"]][:organization] = @organization
            @scope_types[row["Code"]][:name][row["Locale"]] = row["Singular"]
            @scope_types[row["Code"]][:plural][row["Locale"]] = row["Plural"]
          end

          Decidim::ScopeType.transaction do
            @scope_types.values.each do |info|
              Decidim::ScopeType.find_or_initialize_by(id: info[:id]).update!(info)
            end
            max_id = Decidim::ScopeType.maximum(:id)
            Decidim::ScopeType.connection.execute(ActiveRecord::Base.send(:sanitize_sql_array, ["ALTER SEQUENCE decidim_scope_types_id_seq RESTART WITH ?", max_id + 1]))
          end
        end

        def save_scopes(main_source, translations_source)
          puts "Loading scopes..."
          return if use_cached_scopes

          @translations = Hash.new { |h, k| h[k] = {} }
          CSV.foreach(translations_source, col_sep: "\t", headers: true) do |row|
            @translations[row["UID"]][row["Locale"]] = row["Translation"]
          end

          @scope_ids = {}
          CSV.foreach(main_source, col_sep: "\t", headers: true) do |row|
            save_scope row
          end
        end

        def use_cached_scopes
          return unless File.exist?(CACHE_PATH)

          conn = ActiveRecord::Base.connection.raw_connection
          File.open(CACHE_PATH, "r:ASCII-8BIT") do |file|
            conn.copy_data "COPY decidim_scopes FROM STDOUT With CSV HEADER DELIMITER E'\t' NULL '' ENCODING 'UTF8'" do
              conn.put_copy_data(file.readline) until file.eof?
            end
          end
          true
        end

        def cache_scopes
          conn = ActiveRecord::Base.connection.raw_connection
          File.open(CACHE_PATH, "w:ASCII-8BIT") do |file|
            conn.copy_data "COPY (SELECT * FROM decidim_scopes) To STDOUT With CSV HEADER DELIMITER E'\t' NULL '' ENCODING 'UTF8'" do
              while (row = conn.get_copy_data) do file.puts row end
            end
          end
        end

        def root_code(code)
          code.split(/\W/i).first
        end

        def parent_code(code)
          return nil if code == Decidim::CensusConnector.census_local_code
          parent_code = code.rindex(/\W/i)
          parent_code ? code[0..parent_code - 1] : EXTERIOR_SCOPE
        end

        def save_scope(row)
          print "\r#{row["UID"].ljust(30)}"
          code = row["UID"]

          scope = Decidim::Scope.create!(
            code: code,
            organization: @organization,
            scope_type_id: @scope_types[row["Type"]][:id],
            name: @translations[code],
            parent_id: @scope_ids[parent_code(code)]
          )
          @scope_ids[code] = scope.id
        end
      end
    end
  end
end
