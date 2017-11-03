require "simple_initialize"

module Swissfork
  # Checks quality of pairs following the quality criteria
  # described in FIDE Dutch System, sections C.8 to C.19.
  #
  # Criteria C.5 to C.7 are implemented in the main algorithm.
  class QualityChecker
    initialize_with :pairs, :unpaired_players, :quality_calculator

    def ok?
      criteria.none? { |condition| send(condition) }
    end

    def failing_criterion(criteria)
      criteria.select { |condition| send(condition) }.last
    end

    # Preliminary check for downfloat and colour violations.
    # It isn't an exhaustive check; it's just a way to improve
    # performance by detecting not ideal pairs soon and thus
    # reducing the amount of pair combinations we try.
    #
    # If we returned "true" here, the pairing process would
    # still work, but it would be billions of times slower.
    def colours_and_downfloats_are_ok?
      can_downfloat? && !violate_colours?
    end

    def can_downfloat?
      return true if number_of_required_downfloats.zero?

      unpaired_players.combination(number_of_required_downfloats).any? do |players|
        allowed_downfloats.include?(players.to_set) &&
          with_unpaired_players(players) do
          !(downfloats_failing_criterion.tap do |criterion|
            quality_calculator.failing_criteria << criterion if criterion
          end)
        end
      end
    end

    def self.criteria
      [
        :high_difference_violation?,
        :same_colour_three_times?,
        :colour_preference_violation?,
        :strong_colour_preference_violation?,
        :same_downfloats_as_previous_round?,
        :same_upfloats_as_previous_round?,
        :same_downfloats_as_two_rounds_ago?,
        :same_upfloats_as_two_rounds_ago?
      ]
    end

  private
    def criteria
      self.class.criteria
    end

    criteria.each do |criterion|
      define_method criterion do
        send(criterion.to_s.delete("?")).count > allowed_failures[criterion]
      end
    end

    # C.8
    def high_difference_violation
      pairs.select(&:same_absolute_high_difference?)
    end

    # C.9
    def same_colour_three_times
      pairs.select(&:same_colour_three_times?)
    end

    # C.10
    def colour_preference_violation
      pairs.select(&:same_colour_preference?)
    end

    # C.11
    def strong_colour_preference_violation
      pairs.select(&:same_strong_preference?)
    end

    # C.12
    def same_downfloats_as_previous_round
      unpaired_players.select(&:descended_in_the_previous_round?)
    end

    # C.13
    def same_upfloats_as_previous_round
      ascending_players.select(&:ascended_in_the_previous_round?)
    end

    # C.14
    def same_downfloats_as_two_rounds_ago
      unpaired_players.select(&:descended_two_rounds_ago?)
    end

    # C.15
    def same_upfloats_as_two_rounds_ago
      ascending_players.select(&:ascended_two_rounds_ago?)
    end

    def ascending_players
      heterogeneous_pairs.map(&:last)
    end

    def heterogeneous_pairs
      pairs.select(&:heterogeneous?)
    end

    def downfloats_failing_criterion
      failing_criterion(
        [:same_downfloats_as_previous_round?,
         :same_downfloats_as_two_rounds_ago?])
    end

    def violate_colours?
      colours_failing_criterion.tap do |criterion|
        quality_calculator.failing_criteria << criterion if criterion
      end
    end

    def colours_failing_criterion
      failing_criterion([:colour_preference_violation?,
                         :strong_colour_preference_violation?])
    end

    def allowed_downfloats
      quality_calculator.allowed_downfloats
    end

    def number_of_required_downfloats
      quality_calculator.required_downfloats
    end

    def allowed_failures
      quality_calculator.allowed_failures
    end

    def with_unpaired_players(leftovers, &block)
      real_unpaired_players, @unpaired_players = unpaired_players, leftovers
      result = block.call
      @unpaired_players = real_unpaired_players
      result
    end
  end
end
