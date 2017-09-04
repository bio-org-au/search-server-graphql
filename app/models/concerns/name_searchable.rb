# frozen_string_literal: true

# Concern for name Searching
# Extracted from name.rb
module NameSearchable
  extend ActiveSupport::Concern

  # String methods
  module SearchableNameStrings
    refine String do
      def regexified
        gsub("*", ".*").gsub("%", ".*").sub(/$/, "$").sub(/^/, "^")
      end

      def hybridized
        strip.gsub(/  */, " (x )?").sub(/^ */, "(x )?").tr("×", "x")
      end
    end
  end

  # Class methods
  module ClassMethods
    using SearchableNameStrings
    SIMPLE_NAME_REGEX = "lower(f_unaccent(simple_name)) ~ lower(f_unaccent(?)) "
    FULL_NAME_REGEX = "lower(f_unaccent(full_name)) ~ lower(f_unaccent(?))"

    def search_for(string)
      where("#{SIMPLE_NAME_REGEX} or #{FULL_NAME_REGEX}",
            string.hybridized.regexified,
            string.hybridized.regexified)
    end

    def simple_name_allow_for_hybrids_like(string)
      search_for(string)
    end

    def full_name_allow_for_hybrids_like(string)
      where(FULL_NAME_REGEX, string.regexified.hybridized)
    end

    def scientific_search
      Name.not_a_duplicate
          .has_an_instance
          .includes(:status)
          .includes(:rank)
    end

    def cultivar_search
      Name.not_a_duplicate
          .has_an_instance
          .includes(:status)
          .joins(:rank)
    end

    def common_search
      Name.not_a_duplicate
          .has_an_instance
          .includes(:status)
          .order("sort_name")
    end
  end
end
