module Swissfork
  # Given a list of players to pair and possible opponents,
  # it calculates if some players remain unpaired.
  #
  # For example, if we've got players 1, 2, 3, 4, and 2 has
  # played against 3 and 4, in theory all players have possible
  # opponents and can be paired. However, if we pair number 2,
  # numbers 3 and 4 will remain unpaired, because their only
  # possible opponent (number 1) can't play against more than one
  # player.
  class Completion
    def initialize(players, opponents = nil)
      @players = players
      @opponents = opponents || players
    end
    attr_reader :players, :opponents

    def ok?
      all_players_can_be_paired? && bye_can_be_selected?
    end

    def all_players_can_be_paired?
      incompatibilities < 2
    end

    def bye_can_be_selected?
      return true if players.count.even?

      players.select { |player| !player.had_bye? }.any? do |player|
        Completion.new(players - [player]).all_players_can_be_paired?
      end
    end

    def compatibilities
      (players.count - incompatibilities) / 2
    end

    def number_of_required_mdps
      (0..players.count + 1).each do |number|
        additional_players = Array.new(number) do |index|
          Player.new(index + 10000) # Assuming there are less than 10000 players.
        end

        return number if Completion.new(players + additional_players).ok?
      end
    end

    # Returns the number of players who will remain unpaired
    # after the best possible pairing
    def incompatibilities
      return 0 if enough_players_to_guarantee_pairing?

      incompatibilities = 0

      until(players_in_a_combination > list.keys.count)
        list.keys.combination(players_in_a_combination).each do |players|
          opponents = list.values_at(*players).reduce(&:+).uniq

          if opponents.count < players_in_a_combination
            remove_from_list(players + opponents)

            incompatibilities += players_in_a_combination - opponents.count
            reset_players_in_a_combination
            break
          elsif players_in_a_combination.odd? && (opponents - players).empty?
            remove_from_list(players + opponents)

            incompatibilities += 1
            reset_players_in_a_combination
            break
          end
        end

        increase_players_in_a_combination
      end

      incompatibilities + list.values.select { |rivals| rivals.empty? }.count
    end

  private
    def list
      @list ||= players.reduce({}) do |list, player|
        list[player] = player.compatible_players_in(opponents)
        list
      end
    end

    def enough_players_to_guarantee_pairing?
      (players & opponents).count > players.map(&:opponents).map(&:count).max * 2
    end

    def remove_from_list(removals)
      removals.each { |player| list.delete(player) }
      list.each { |person, rivals| list[person] = rivals - removals }
    end

    def players_in_a_combination
      @players_in_a_combination ||= 1
    end

    def increase_players_in_a_combination
      @players_in_a_combination = players_in_a_combination + 1
    end

    def reset_players_in_a_combination
      @players_in_a_combination = nil
    end
  end
end
