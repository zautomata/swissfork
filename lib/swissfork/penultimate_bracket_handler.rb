require "simple_initialize"

module Swissfork
  # Handles the logic to move players in the penultimate bracket.
  #
  # This is a special case described in FIDE Ducth System,
  # sections A.9 and C.4. The basic idea is: when the pairing
  # of the remaining players isn't possible, we need to use
  # players from the last paired bracket.
  class PenultimateBracketHandler
    initialize_with :penultimate_bracket_players, :last_bracket

    def move_players_to_allow_last_bracket_pairs
      while(true)
        players_to_move = permutations.next.last(last_bracket.leftovers.count)

        duplicate_bracket = last_bracket.dup
        duplicate_bracket.add_players(players_to_move)

        break if duplicate_bracket.leftovers.count <= 1
      end

      last_bracket.add_players(players_to_move)
      penultimate_bracket_players.reject! { |player| players_to_move.include?(player) }
    end

  private
    def permutations
      @permutations ||= compatible_players.permutation
    end

    def compatible_players
      penultimate_bracket_players.select do |player|
        last_bracket.leftovers.any? { |leftover| player.compatible_with?(leftover) }
      end
    end
  end
end
