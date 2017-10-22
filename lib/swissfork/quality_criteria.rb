require "simple_initialize"

module Swissfork
  # Checks quality of pairs following the quality criteria
  # described in FIDE Dutch System, sections C.8 to C.19.
  #
  # Criteria C.5 to C.7 are implemented in the main algorithm.
  class QualityCriteria
    initialize_with :bracket

    def ok?
      criteria.none? { |condition| send(condition) }
    end

    def failing_criterion
      criteria.select { |condition| send(condition) }.last
    end

    def be_more_permissive
      relevant_criterion = current_failing_criterion

      if relevant_criterion != old_failing_criterion
        if old_failing_criterion_is_less_important?
          allowed_failures[old_failing_criterion] = 0
        end

        self.old_failing_criterion = relevant_criterion
      end

      bracket.reset_failing_criteria
      allowed_failures[relevant_criterion] += 1
    end

    def can_downfloat?(leftovers)
      return true if number_of_required_downfloats.zero?

      leftovers.combination(number_of_required_downfloats).any? do |players|
        allowed_downfloats.include?(players.to_set) &&
          !exceed_same_downfloats_as_previous_round?(players) &&
          !exceed_same_downfloats_as_two_rounds_ago?(players)
      end
    end

    def current_failing_criterion
      if ok?
        bracket.failing_criteria.sort_by do |criterion|
          criteria.index(criterion)
        end.last
      else
        criteria.select { |condition| send(condition) }.last
      end
    end

  private
    attr_writer :old_failing_criterion

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

    def criteria
      self.class.criteria
    end

    criteria.each do |criterion|
      define_method criterion do
        send(criterion.to_s.delete("?")).count > allowed_failures[criterion]
      end
    end

    def allowed_failures
      @allowed_failures ||= Hash.new(0).tap do |allowed_failures|
        allowed_failures[:colour_preference_violation?] =
          bracket.minimum_colour_violations
        allowed_failures[:strong_colour_preference_violation?] =
          bracket.minimum_strong_colour_violations
        # TODO: check.
        allowed_failures[:same_downfloats_as_previous_round?] =
          [number_of_required_downfloats - bracket.resident_players.reject(&:descended_in_the_previous_round?).count, 0].max
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
      pairable_leftovers.select(&:descended_in_the_previous_round?)
    end

    # C.13
    def same_upfloats_as_previous_round
      ascending_players.select(&:ascended_in_the_previous_round?)
    end

    # C.14
    def same_downfloats_as_two_rounds_ago
      pairable_leftovers.select(&:descended_two_rounds_ago?)
    end

    # C.15
    def same_upfloats_as_two_rounds_ago
      ascending_players.select(&:ascended_two_rounds_ago?)
    end

    def old_failing_criterion
      @old_failing_criterion ||= criteria.last
    end

    def old_failing_criterion_is_less_important?
      criteria.index(old_failing_criterion) > criteria.index(current_failing_criterion)
    end

    def exceed_same_downfloats_as_previous_round?(players)
      if players.reject(&:descended_in_the_previous_round?).count < number_of_downfloats_not_from_the_previous_round
        bracket.failing_criteria << :same_downfloats_as_previous_round?
        true
      end
    end

    def exceed_same_downfloats_as_two_rounds_ago?(players)
      if players.reject(&:descended_two_rounds_ago?).count < number_of_downfloats_not_from_two_rounds_ago
        bracket.failing_criteria << :same_downfloats_as_two_rounds_ago?
        true
      end
    end

    def number_of_downfloats_not_from_two_rounds_ago
      number_of_required_downfloats -
        allowed_failures[:same_downfloats_as_two_rounds_ago?]
    end

    def number_of_downfloats_not_from_the_previous_round
      number_of_required_downfloats -
        allowed_failures[:same_downfloats_as_previous_round?]
    end

    def ascending_players
      heterogeneous_pairs.map(&:last)
    end

    def heterogeneous_pairs
      pairs.select(&:heterogeneous?)
    end

    def pairable_leftovers
      bracket.pairable_provisional_leftovers
    end

    def pairs
      bracket.provisional_pairs
    end

    def number_of_required_downfloats
      bracket.number_of_required_downfloats
    end

    def allowed_downfloats
      bracket.allowed_downfloats
    end
  end
end