require "create_players_helper"
require "swissfork/bracket"

module Swissfork
  describe Bracket do
    let(:bracket) { Bracket.for(players) }

    describe ".for" do
      let(:players) { create_players(1..6) }

      before(:each) do
        players.each_stub(points: 1)
      end

      context "players with the same points" do
        it "is homogeneous" do
          bracket.class.name.should eq "Swissfork::HomogeneousBracket"
        end
      end

      context "players with different number of points" do
        before(:each) do
          players.first.stub(points: 1.5)
        end

        it "is heterogeneous" do
          bracket.class.name.should eq "Swissfork::HeterogeneousBracket"
        end
      end

      context "at least half of the players have different number of points" do
        before(:each) do
          players[0..2].each_stub(points: 1.5)
        end

        it "is heterogeneous" do
          bracket.class.name.should eq "Swissfork::HeterogeneousBracket"
        end
      end
    end

    describe "#points" do
      let(:players) { create_players(1..6) }

      before(:each) do
        players.each_stub(points: 1)
      end

      context "homogeneous bracket" do
        it "returns the number of points from all players" do
          bracket.points.should eq 1
        end
      end

      context "heterogeneous bracket" do
        before(:each) { players.last.stub(points: 0.5) }

        it "returns the points from the player with the lowest amount of points" do
          bracket.points.should eq 0.5
        end
      end
    end

    describe "#s1_numbers" do
      let(:bracket) do
        Bracket.for([]).tap do |bracket|
          bracket.stub(s1: create_players(1..4))
        end
      end

      it "returns the numbers for the players in s1" do
        bracket.s1_numbers.should eq [1, 2, 3, 4]
      end
    end

    describe "#s2_numbers" do
      let(:bracket) do
        Bracket.for([]).tap do |bracket|
          bracket.stub(s2: create_players(5..8))
        end
      end

      it "returns the numbers for the players in s1" do
        bracket.s2_numbers.should eq [5, 6, 7, 8]
      end
    end

    describe "#s1" do
      context "even number of players" do
        let(:players) { create_players(1..6) }
        before(:each) do
          players.each_stub(points: 1)
        end

        context "homogeneous bracket" do
          it "returns the first half of the players" do
            bracket.s1_numbers.should eq [1, 2, 3]
          end
        end

        context "heterogeneous bracket" do
          before(:each) do
            players[0..1].each_stub(points: 1.5)
          end

          it "returns the descended players" do
            bracket.s1_numbers.should eq [1, 2]
          end
        end

        context "unordered players" do
          let(:players) { create_players(1..6).shuffle }

          it "orders the players" do
            bracket.s1_numbers.should eq [1, 2, 3]
          end
        end
      end

      context "odd number of players" do
        let(:players) { create_players(1..7) }

        it "returns the first half of the players, rounded downwards" do
          bracket.s1_numbers.should eq [1, 2, 3]
        end
      end
    end

    describe "#s2" do
      context "even number of players" do
        let(:players) { create_players(1..6) }

        before(:each) do
          players.each_stub(points: 1)
        end

        context "homogeneous bracket" do
          it "returns the second half of the players" do
            bracket.s2_numbers.should eq [4, 5, 6]
          end
        end

        context "heterogeneous bracket" do
          before(:each) do
            players[0..1].each_stub(points: 1.5)
          end

          it "returns all players but the descended ones" do
            bracket.s2_numbers.should eq [3, 4, 5, 6]
          end
        end
      end

      context "odd number of players" do
        let(:players) { create_players(1..7) }

        it "returns the second half of the players, rounded upwards" do
          bracket.s2_numbers.should eq [4, 5, 6, 7]
        end
      end
    end

    describe "#exchange" do
      let(:s1_players) { create_players(1..5) }
      let(:s2_players) { create_players(6..11) }
      let(:bracket) { Bracket.for(s1_players + s2_players) }

      context "two exchanges" do
        before(:each) { 2.times { bracket.exchange }}

        it "exchanges the players and reorders S1" do
          bracket.s1_numbers.should eq [1, 2, 3, 4, 7]
        end
      end

      context "heterogeneous bracket" do
        before(:each) do
          s1_players[0..2].each_stub(points: 2)
          bracket.stub(number_of_moved_down_possible_pairs: 2)
        end

        context "two exchanges" do
          before(:each) { 2.times { bracket.exchange }}

          it "exchanges players and reorders S1 and Limbo" do
            bracket.s1_numbers.should eq [2, 3]
            bracket.limbo_numbers.should eq [1]
            bracket.s2_numbers.should eq [4, 5, 6, 7, 8, 9, 10, 11]
          end
        end
      end
    end

    describe "#pair_numbers" do
      context "even number of players" do
        let(:players) { create_players(1..10) }
        before(:each) do
          players.each_stub_opponents([])
        end

        context "no previous opponents" do
          it "pairs the players from s1 with the players from s2" do
            bracket.pair_numbers.should eq [[1, 6], [2, 7], [3, 8], [4, 9], [5, 10]]
          end
        end

        context "need to transpose once" do
          before(:each) do
            players[4].stub_opponents([players[9]])
            players[9].stub_opponents([players[4]])
          end

          it "pairs the players after transposing" do
            bracket.pair_numbers.should eq [[1, 6], [2, 7], [3, 8], [4, 10], [5, 9]]
          end
        end

        context "need to transpose twice" do
          before(:each) do
            players[3].stub_opponents([players[9], players[8]])
            players[9].stub_opponents([players[3]])
            players[8].stub_opponents([players[3]])
          end

          it "pairs using the next transposition" do
            bracket.pair_numbers.should eq [[1, 6], [2, 7], [3, 9], [4, 8], [5, 10]]
          end
        end

        context "need to transpose three times" do
          before(:each) do
            players[3].stub_opponents([players[8]])
            players[4].stub_opponents(players[8..9])
            players[9].stub_opponents([players[4]])
            players[8].stub_opponents(players[3..4])
          end

          it "pairs using the next transposition" do
            bracket.pair_numbers.should eq [[1, 6], [2, 7], [3, 9], [4, 10], [5, 8]]
          end
        end

        context "only the last transposition makes pairing possible" do
          before(:each) do
            players[4].stub_opponents(players[6..9])
            players[3].stub_opponents(players[7..9])
            players[2].stub_opponents(players[8..9])
            players[1].stub_opponents([players[9]])

            players[9].stub_opponents(players[1..4])
            players[8].stub_opponents(players[2..4])
            players[7].stub_opponents(players[3..4])
            players[6].stub_opponents([players[4]])
          end

          it "pairs after transposing every player" do
            bracket.pair_numbers.should eq [[1, 10], [2, 9], [3, 8], [4, 7], [5, 6]]
          end
        end

        context "one previous opponent" do
          before(:each) do
            players[0].stub_opponents([players[5]])
            players[5].stub_opponents([players[0]])
            players[3].stub_opponents([players[8]])
            players[8].stub_opponents([players[3]])
          end

          it "pairs the players avoiding previous opponents" do
            bracket.pair_numbers.should eq [[1, 7], [2, 6], [3, 8], [4, 10], [5, 9]]
          end
        end

        context "several previous opponents" do
          before(:each) do
            players[2].stub_opponents([players[9]])
            players[3].stub_opponents(players[8..9])
            players[4].stub_opponents(players[7..9])

            players[9].stub_opponents(players[2..4])
            players[8].stub_opponents(players[3..4])
            players[7].stub_opponents([players[4]])
          end

          it "pairs the players avoiding previous opponents" do
            bracket.pair_numbers.should eq [[1, 6], [2, 10], [3, 9], [4, 8], [5, 7]]
          end
        end

        context "one player from S1 has played against everyone in S2" do
          before(:each) do
            players[0].stub_opponents(players[5..9])
            players[5..9].each_stub_opponents([players[0]])
          end

          it "pairs the players with another player from S1" do
            bracket.pair_numbers.should eq [[1, 5], [2, 7], [3, 8], [4, 9], [6, 10]]
          end
        end

        context "two players from S1 have played against everyone in S2" do
          before(:each) do
            players[0].stub_opponents([players[1]] + players[3..9])
            players[1].stub_opponents(players[0..2] + players[4..9])
            players[2].stub_opponents([players[1]])
            players[3].stub_opponents([players[0]])
            players[4..9].each_stub_opponents([players[0], players[1]])
          end

          it "pairs those two players with players from S1" do
            bracket.pair_numbers.should eq [[1, 3], [2, 4], [5, 8], [6, 9], [7, 10]]
          end
        end

        context "one of the players can't be paired" do
          before(:each) do
            players[0].stub_opponents(players[1..9])
            players[1..9].each_stub_opponents([players[0]])
          end

          it "doesn't pair that player" do
            bracket.pair_numbers.should eq [[2, 6], [3, 7], [4, 8], [5, 9]]
          end

          it "moves that player and the last player down" do
            bracket.leftover_numbers.should eq [1, 10]
          end
        end

        context "two players can only play against one opponent" do
          before(:each) do
            players[0..1].each_stub_opponents(players[0..8])
            players[2..8].each_stub_opponents([players[0], players[1]])
          end

          it "pairs the higher of those two players" do
            bracket.pair_numbers.should eq [[1, 10], [3, 6], [4, 7], [5, 8]]
          end

          it "moves the lower player and the last player down" do
            bracket.leftover_numbers.should eq [2, 9]
          end

          context "the lower player has already downfloated" do
            before(:each) do
              players[1].stub(floats: [:down])
            end

            it "pairs the lower player, and moves the higher one down" do
              bracket.pair_numbers.should eq [[2, 10], [3, 6], [4, 7], [5, 8]]
              bracket.leftover_numbers.should eq [1, 9]
            end
          end
        end

        context "four players can only play against one opponent" do
          before(:each) do
            players[0..3].each_stub_opponents(players[0..5] + players[7..9])
            players[4..5].each_stub_opponents(players[0..3])
            players[7..9].each_stub_opponents(players[0..3])
          end

          it "downfloats four players" do
            bracket.pair_numbers.should eq [[1, 7], [5, 8], [6, 9]]
            bracket.leftover_numbers.should eq [2, 3, 4, 10]
          end

          context "two of those players and the last one have already downfloated" do
            before(:each) do
              players[0..1].each_stub(floats: [:down])
              players[9].stub(floats: [:down])
            end

            it "minimizes same downfloats as the previous round (minimum: 2)" do
              bracket.pair_numbers.should eq [[1, 7], [5, 8], [6, 10]]
              bracket.leftover_numbers.should eq [2, 3, 4, 9]
            end

            context "the penultimate downfloated two rounds ago" do
              before(:each) do
                players[8].stub(floats: [:down, nil])
              end

              it "minimizes same downfloats as two rounds before (minimum: 0)" do
                bracket.pair_numbers.should eq [[1, 7], [5, 9], [6, 10]]
                bracket.leftover_numbers.should eq [2, 3, 4, 8]
              end

              context "one of the required downfloats also descended 2 rounds ago" do
                before(:each) do
                  players[3].stub(floats: [:down, nil])
                end

                it "minimizes same downfloats as two rounds before (minimum: 1)" do
                  bracket.pair_numbers.should eq [[1, 7], [5, 9], [6, 10]]
                  bracket.leftover_numbers.should eq [2, 3, 4, 8]
                end
              end
            end
          end
        end
      end

      context "odd number of players" do
        let(:players) { create_players(1..11) }
        before(:each) do
          players.each_stub_opponents([])
        end

        context "no previous opponents" do
          it "pairs all players except the last one" do
            bracket.pair_numbers.should eq [[1, 6], [2, 7], [3, 8], [4, 9], [5, 10]]
          end
        end

        context "previous opponents affecting the second to last player" do
          before(:each) do
            players[4].stub_opponents([players[9]])
            players[9].stub_opponents([players[4]])
          end

          it "pairs all players except the second to last one" do
            bracket.pair_numbers.should eq [[1, 6], [2, 7], [3, 8], [4, 9], [5, 11]]
          end
        end

        context "all players downfloated; the first one did so 2 rounds ago" do
          before(:each) do
            players[0].stub(floats: [:down, nil])
            players[1..10].each_stub(floats: [nil, :down])
          end

          it "downfloats that player and pairs the rest in order" do
            bracket.pair_numbers.should eq [[2, 7], [3, 8], [4, 9], [5, 10], [6, 11]]
          end
        end
      end
    end

    describe "#leftovers" do
      context "even number of players" do
        let(:players) { create_players(1..10) }

        it "returns an empty array" do
          bracket.leftovers.should eq []
        end
      end

      context "odd number of players" do
        let(:players) { create_players(1..11) }

        context "no previous opponents" do
          it "returns the last player" do
            bracket.leftover_numbers.should eq [11]
          end
        end

        context "previous opponents affecting the second to last player" do
          before(:each) do
            players[4].stub_opponents([players[9]])
            players[9].stub_opponents([players[4]])
          end

          it "returns the second to last player" do
            bracket.leftover_numbers.should eq [10]
          end
        end
      end
    end

    describe "methods differing between homogeneous and heterogeneous brackets" do
      let(:bracket) { Bracket.new(players) }
      let(:players) { create_players(1..10) }

      it "raises an exception when called directly from Bracket" do
        -> { bracket.s2 }.should raise_error("Implement in subclass")
        -> { bracket.number_of_required_pairs }.should raise_error("Implement in subclass")
        -> { bracket.exchange }.should raise_error("Implement in subclass")
      end
    end

    describe "<=>" do
      def bracket_with_points(points)
        Bracket.for([]).tap do |bracket|
          bracket.stub(points: points)
        end
      end

      let(:higher_bracket) { bracket_with_points(3) }
      let(:medium_bracket) { bracket_with_points(2) }
      let(:lower_bracket) { bracket_with_points(1) }

      it "sorts brackets based on points in descending order" do
        [medium_bracket, lower_bracket, higher_bracket].sort.should eq(
          [higher_bracket, medium_bracket, lower_bracket])
      end
    end
  end
end
