require "swissfork/bracket"

module Swissfork
  class HomogeneousBracket < Bracket
    def leftovers
      pairs && still_unpaired_players
    end

    def number_of_players_in_s1
      maximum_number_of_pairs
    end

    def number_of_required_pairs
      pairable_players.count / 2
    end

    def best_pairs_obtained?
      pairings_completed? && best_possible_pairs?
    end

    def definitive_pairs
      established_pairs
    end

    def pairs
      while(!current_exchange_pairs)
        if exchanger.limit_reached?
          if quality.worst_possible?
            return []
          else
            quality.be_more_permissive
            restart_pairs
            players.sort!
          end
        else
          exchange
          restart_pairs
        end
      end

      current_exchange_pairs
    end
  end
end