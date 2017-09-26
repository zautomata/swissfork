require "simple_initialize"

module Swissfork
  # Contains all data related to a game.
  #
  # Currently it only contains which players played the game,
  # but color and result information will be added in the future.
  class Pair
    initialize_with :s1_player, :s2_player

    def players
      [s1_player, s2_player]
    end

    def numbers
      players.map(&:number)
    end

    def heterogeneous?
      s1_player.points != s2_player.points
    end

    def include?(player)
      player == s1_player || player == s2_player
    end

    def eql?(pair)
      pair.respond_to?(:s1_player) && pair.s1_player == s1_player && pair.s2_player == s2_player
    end

    def ==(pair)
      eql?(pair)
    end
  end
end
