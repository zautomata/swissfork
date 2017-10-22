require "simple_initialize"

module Swissfork
  # Contains all data related to a game.
  #
  # Currently it only contains which players played the game,
  # but result information will be added in the future.
  class Pair
    initialize_with :s1_player, :s2_player
    include Comparable

    def players
      if players_ordered_by_preference.first.colour_preference == :black
        players_ordered_by_preference.reverse
      else
        players_ordered_by_preference
      end
    end

    def higher_player
      [s1_player, s2_player].sort.first
    end

    def lower_player
      [s1_player, s2_player].sort.last
    end

    def hash
      numbers.hash
    end

    def last
      s2_player
    end

    def numbers
      players.map(&:number)
    end

    def same_absolute_high_difference?
      same_absolute_preference? && both_have_high_difference?
    end

    def same_colour_three_times?
      same_absolute_preference? && !both_have_high_difference?
    end

    def same_colour_preference?
      s1_player.colour_preference && s2_player.colour_preference &&
        s1_player.colour_preference == s2_player.colour_preference
    end

    def same_strong_preference?
      same_colour_preference? && s1_player.preference_degree.strong? &&
        s2_player.preference_degree.strong?
    end

    def heterogeneous?
      s1_player.points != s2_player.points
    end

    def eql?(pair)
      # TODO: Using array "-" for performance reasons. Check if it still
      # holds true when the program is more mature.
      ([pair.s1_player, pair.s2_player] - [s1_player, s2_player]).empty?
    end

    def ==(pair)
      eql?(pair)
    end

    def <=>(pair)
      [s1_player, s2_player].min <=> [pair.s1_player, pair.s2_player].min
    end

  private
    def same_absolute_preference?
      same_colour_preference? && s1_player.preference_degree.absolute? &&
        s2_player.preference_degree.absolute?
    end

    def both_have_high_difference?
      s1_player.colour_difference > 1 && s2_player.colour_difference > 1
    end

    def players_ordered_by_preference
      @players_ordered_by_preference ||=
        if s1_player.colour_preference == s2_player.colour_preference
          players_with_same_colour_ordered_by_preference
        else
          players_with_different_colour_ordered_by_preference
        end
    end

    def players_with_same_colour_ordered_by_preference
      if s2_player.stronger_preference_than?(s1_player)
        [s2_player, s1_player]
      else
        players_ordered_inverting_last_different_colours
      end
    end

    def players_with_different_colour_ordered_by_preference
      if s1_player.colour_preference == :none
        [s2_player, s1_player]
      else
        [s1_player, s2_player]
      end
    end

    def players_ordered_inverting_last_different_colours
      if s1_player.colours == s2_player.colours
        players_ordered_by_rank
      elsif last_different_colours[0] == s1_player.colour_preference
        [s2_player, s1_player]
      else
        [s1_player, s2_player]
      end
    end

    def players_ordered_by_rank
      [higher_player, lower_player]
    end

    def last_different_colours
      s1_player.colours.zip(s2_player.colours).select do |colours|
        colours.uniq.count > 1
      end.last
    end
  end
end
