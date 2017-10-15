require "simple_initialize"
require "swissfork/bracket"

module Swissfork
  # Generates the pairs of a whole round.
  #
  # Its only useful public method is #pairs. All the other
  # public methods are public so they can be easily tested.
  class Round
    require "swissfork/scoregroup"

    initialize_with :players

    def scoregroups
      @scoregroups ||= player_groups.map { |players| Scoregroup.new(players, self) }.sort
    end

    def pairs
      @pairs ||= establish_pairs
    end

    # Helper method which makes tests more readable.
    def pair_numbers
      pairs.map(&:numbers)
    end

    def bye
      (players - pairs.flat_map(&:players)).first
    end

  private
    def establish_pairs
      scoregroups.each do |scoregroup|
        established_pairs.push(*scoregroup.pairs)
        scoregroup.move_leftovers_to_next_scoregroup unless scoregroup.last?
      end

      established_pairs.sort
    end

    def established_pairs
      @established_pairs ||= []
    end

    def player_groups
      players.group_by(&:points).values
    end
  end
end
