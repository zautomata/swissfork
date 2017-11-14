require "swissfork/generic_colour_possible_pairs"

module Swissfork
  # Calculates how many pairs can be obtained granting
  # the colour preferences of both players.
  class ColourPossiblePairs < GenericColourPossiblePairs

  private
    def opponents_for(player)
      super(player).select do |opponent|
        !player.colour_preference || !opponent.colour_preference ||
          player.colour_preference != opponent.colour_preference
      end
    end
  end
end