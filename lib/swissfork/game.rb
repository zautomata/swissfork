require "simple_initialize"

module Swissfork
  # Contains the game data associated to a player.
  #
  # The information it contains is similar to Pair, but
  # Pair shows information from an objective point of view,
  # and Game shows information from the player point of view.
  class Game
    initialize_with :player, :pair

    def opponent
      (players - [player]).first
    end

    def colour
      if played?
        if player == white
          :white
        else
          :black
        end
      end
    end

    def float
      if played?
        if player.points_before(self) < opponent.points_before(self)
          :up
        elsif player.points_before(self) > opponent.points_before(self)
          :down
        end
      elsif bye?
        :bye
      end
    end

    def bye?
      !played? && won?
    end

    def winner
      case result
      when :white_won, :white_won_by_forfeit then white
      when :black_won, :black_won_by_forfeit then black
      end
    end

    def points_received
      if won?
        1
      elsif draw?
        0.5
      else
        0
      end
    end

    def played?
      played_results.include?(result)
    end

  private
    def played_results
      [:white_won, :black_won, :draw]
    end

    def white
      players[0]
    end

    def black
      players[1]
    end

    def result
      pair.result
    end

    def players
      pair.players
    end

    def won?
      winner == player
    end

    def draw?
      result == :draw
    end
  end
end