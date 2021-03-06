require "create_players_helper"
require "swissfork/round"

module Swissfork
  describe Round do
    let(:round) { Round.new(players) }

    describe "#bye" do
      context "even number of players" do
        let(:players) { create_players(1..10) }

        it "returns nil" do
          round.bye.should be nil
        end
      end

      context "odd number of players" do
        let(:players) { create_players(1..11) }

        it "returns the unpaired player" do
          round.bye.number.should eq 11
        end
      end
    end

    describe "#pairs with byes" do
      let(:players) { create_players(1..11) }

      context "a player has already had a bye" do
        before(:each) { players[10].stub(had_bye?: true) }

        it "another player gets the bye" do
          round.bye.number.should eq 10
          round.pair_numbers.should eq [[1, 6], [2, 7], [3, 8], [4, 9], [5, 11]]
        end
      end

      context "a player downfloated in the previous round" do
        before(:each) do
          players[10].stub(floats: [:down])
        end

        it "another player gets the bye" do
          round.bye.number.should eq 10
          round.pair_numbers.should eq [[1, 6], [2, 7], [3, 8], [4, 9], [5, 11]]
        end
      end

      context "penultimate bracket has an even number of players" do
        before(:each) do
          players[0..5].each_stub(points: 1)
          players[6..10].each_stub(points: 0)
        end

        context "all players in the last bracket had byes" do
          before(:each) do
            players[6..10].each_stub(had_bye?: true)
          end

          it "gives the bye to a player from the previous bracket" do
            round.bye.number.should eq 6
            round.pair_numbers.should eq [[1, 3], [2, 4], [5, 7], [8, 10], [9, 11]]
          end

          context "last player in the PPB played against last bracket players" do
            before(:each) do
              players[5].stub_opponents(players[6..10])
              players[6..10].each_stub_opponents([players[5]])
            end

            it "gives the bye to that player anyway" do
              round.bye.number.should eq 6
              round.pair_numbers.should eq [[1, 3], [2, 4], [5, 7], [8, 10], [9, 11]]
            end
          end

          context "the last players in the PPB had a bye" do
            before(:each) do
              players[2..5].each_stub(had_bye?: true)
            end

            it "gives the bye to a different player" do
              round.bye.number.should eq 2
              round.pair_numbers.should eq [[1, 4], [3, 5], [6, 7], [8, 10], [9, 11]]
            end
          end
        end

        context "all players in the last two brackets had byes" do
          before(:each) do
            players[0..3].each_stub(points: 2)
            players[4..7].each_stub(points: 1)
            players[8..10].each_stub(points: 0)

            players[4..10].each_stub(had_bye?: true)
          end

          it "a player from a previous bracket gets the bye" do
            round.bye.number.should eq 4
            round.pair_numbers.should eq [[1, 2], [3, 5], [6, 7], [8, 9], [10, 11]]
          end
        end

        context "all players in the last bracket have downfloated" do
          before(:each) do
            players[6..10].each_stub(floats: [:down])
          end

          it "gives the bye to the last player in the last bracket" do
            round.bye.number.should eq 11
            round.pair_numbers.should eq [[1, 4], [2, 5], [3, 6], [7, 9], [8, 10]]
          end

          context "the first player in the bracket didn't downfloat" do
            before(:each) do
              players[6].stub(floats: [])
            end

            it "gives the bye to that player" do
              round.bye.number.should eq 7
              round.pair_numbers.should eq [[1, 4], [2, 5], [3, 6], [8, 10], [9, 11]]
            end
          end
        end
      end

      context "penultimate bracket has an odd number of players" do
        before(:each) do
          players[0..6].each_stub(points: 1)
          players[7..10].each_stub(points: 0)
        end

        context "all players in the last bracket had byes" do
          before(:each) do
            players[7..10].each_stub(had_bye?: true)
          end

          it "gives the bye to a player from the previous bracket" do
            round.bye.number.should eq 7
            round.pair_numbers.should eq [[1, 4], [2, 5], [3, 6], [8, 10], [9, 11]]
          end

          context "the last players in the PPB had also a bye" do
            before(:each) do
              players[2..6].each_stub(had_bye?: true)
            end

            it "gives the bye to a different player" do
              round.bye.number.should eq 2
              round.pair_numbers.should eq [[1, 5], [3, 6], [4, 7], [8, 10], [9, 11]]
            end
          end
        end

        context "all players in the last bracket have downfloated" do
          before(:each) do
            players[7..10].each_stub(floats: [:down])
          end

          it "gives the bye to the last player in the last bracket" do
            round.bye.number.should eq 11
            round.pair_numbers.should eq [[1, 4], [2, 5], [3, 6], [7, 8], [9, 10]]
          end

          context "the first player in the bracket didn't downfloat" do
            before(:each) do
              players[7].stub(floats: [])
            end

            it "gives the bye to that player" do
              round.bye.number.should eq 8
              round.pair_numbers.should eq [[1, 4], [2, 5], [3, 6], [7, 9], [10, 11]]
            end
          end
        end
      end
    end
  end
end
