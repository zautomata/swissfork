require "simple_initialize"
require "swissfork/scoregroup"
require "swissfork/bye_game"

module Swissfork
  # Generates the pairs of a whole round.
  #
  # Its only useful public method is #pairs. All the other
  # public methods are public so they can be easily tested.
  class Round
    initialize_with :players
    attr_accessor :number
    attr_reader :finished
    alias_method :finished?, :finished

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

    def results
      pairs.map(&:result)
    end

    def results=(results)
      if pairs.size != results.size
        raise IndexError, "expected #{pairs.size} results, got #{results.size}"
      end

      pairs.zip(results).each do |pair, result|
        pair.result = result
      end

      bye.add_game(ByeGame.new(bye)) if bye
      @finished = true
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
