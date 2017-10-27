require "simple_initialize"
require "swissfork/preference_priority"

module Swissfork
  # Contains information about the games a player has
  # played, its opponents, and results. That information is
  # used to calculate the player's colour preference and
  # compatible opponents.
  #
  # The player's personal information is handled by the
  # Inscription class.
  class Player
    include Comparable
    initialize_with :number
    attr_accessor :inscription

    def games
      @games ||= []
    end

    def add_game(game)
      games << game
    end

    def opponents
      games.select(&:played?).map(&:opponent)
    end

    def floats
      games.map(&:float)
    end

    def colours
      games.map(&:colour)
    end

    def points
      points_after(games)
    end

    def points_before(game)
      points_after(games.first(games.index(game)))
    end

    def had_bye?
      games.any?(&:bye?)
    end

    def descended_in_the_previous_round?
      [:down, :bye].include?(floats.last)
    end

    def ascended_in_the_previous_round?
      floats.last == :up
    end

    def descended_two_rounds_ago?
      [:down, :bye].include?(floats[-2])
    end

    def ascended_two_rounds_ago?
      floats[-2] == :up
    end

    def colour_preference
      if colours.any?
        if last_two_colours_were_the_same?
          opposite_of_last_colour
        elsif colour_difference > 0
          :black
        elsif colour_difference < 0
          :white
        else
          opposite_of_last_colour
        end
      end
    end

    def preference_priority
      PreferencePriority.new(self)
    end

    def preference_degree
      if colours.any?
        if last_two_colours_were_the_same?
          :absolute
        else
          case colour_difference.abs
          when 0 then :mild
          when 1 then :strong
          else :absolute
          end
        end
      else
        :none
      end
    end

    def colour_difference
      colours.select { |colour| colour == :white }.count -
      colours.select { |colour| colour == :black }.count
    end

    def inspect
      number.to_s
    end

    def <=>(other_player)
      # Comparing the arrays results in better performance.
      [other_player.points, number] <=> [points, other_player.number]
    end

    def compatible_players_in(players)
      (players - (opponents + [self])).select do |player|
        preference_degree != :absolute || player.preference_degree != :absolute ||
        player.colour_preference != colour_preference ||
        topscorer? || player.topscorer?
      end
    end

    def topscorer?
      false # TODO
    end

    def rating
      inscription.rating
    end

  private
    def last_two_colours_were_the_same?
      colours.compact[-1] == colours.compact[-2]
    end

    def opposite_of_last_colour
      if colours.compact.last == :white
        :black
      else
        :white
      end
    end

    def points_after(games)
      games.map(&:points_received).reduce(0.0, :+)
    end
  end
end
