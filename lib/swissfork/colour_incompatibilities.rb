require "simple_initialize"

module Swissfork
  # Given a list of players, it calculates how many pairs
  # fulfilling colour preferences can be generated.
  class ColourIncompatibilities
    initialize_with :players, :number_of_possible_pairs

    def violations
      [number_of_possible_pairs - players_with_minoritary_preference.count - players_with_no_preference.count, 0].max
    end

    def strong_violations
      [violations - players_with_main_mild_preference.count, 0].max
    end

    def main_preference
      @main_preference ||= if players_with_black_preference.count > players_with_white_preference.count
        :black
      else
        :white
      end
    end

    def minoritary_preference
      if main_preference == :black
        :white
      else
        :black
      end
    end

  private
    def players_with_main_preference
      send("players_with_#{main_preference}_preference")
    end

    def players_with_main_mild_preference
      players_with_main_preference.select do |player|
        player.preference_degree == :mild
      end
    end

    def players_with_minoritary_preference
      send("players_with_#{minoritary_preference}_preference")
    end

    def players_with_no_preference
      players.reject(&:colour_preference)
    end

    [:white, :black].each do |colour|
      define_method "players_with_#{colour}_preference" do
        players.select { |player| player.colour_preference == colour }
      end
    end
  end
end
