require "simple_initialize"

module Swissfork
  class PlayersDifference
    include Comparable

    initialize_with :s1_players, :s2_players

    def <=>(other_difference)
      if difference == other_difference.difference
        if max_s1 == other_difference.max_s1
          max_s2 <=> other_difference.max_s2
        else
          other_difference.max_s1 <=> max_s1
        end
      else
        difference <=> other_difference.difference
      end
    end

    def difference
      (s1_players.map(&:number).sum - s2_players.map(&:number).sum).abs
    end

    def max_s1
      s1_players.map(&:number).max
    end

    def max_s2
      s2_players.map(&:number).max
    end
  end
end
