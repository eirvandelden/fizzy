require "test_helper"

class Cards::PublishesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as :kevin
  end

  test "create" do
    card = cards(:logo)
    card.drafted!

    assert_changes -> { card.reload.published? }, from: false, to: true do
      post card_publish_path(card)
    end

    assert_redirected_to card.board
  end

  test "create and add another" do
    card = cards(:logo)
    card.drafted!

    assert_changes -> { card.reload.published? }, from: false, to: true do
      assert_difference -> { Card.count }, +1 do
        post card_publish_path(card, creation_type: "add_another")
      end
    end

    new_card = Card.last
    assert new_card.drafted?
    assert_redirected_to card_draft_path(new_card)
  end

  test "concurrent create and add another should not cause duplicate card numbers" do
    card = cards(:logo)
    board = card.board
    user = users(:kevin)
    account = board.account
    initial_count = Card.count

    # Simulate concurrent "add another" requests
    threads = 5.times.map do |i|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          # Set Current.user for this thread context
          Current.user = user
          Current.account = account

          # Create a draft card, publish it, then add another (simulating the controller flow)
          draft = board.cards.create!(status: "drafted")
          draft.publish

          # Simulate the "add another" request - this may hit RecordNotUnique
          attempts = 0
          begin
            attempts += 1
            board.cards.create!(status: "drafted")
          rescue ActiveRecord::RecordNotUnique
            retry if attempts < 3
            raise
          end
        ensure
          Current.user = nil
          Current.account = nil
        end
      end
    end

    threads.each(&:join)

    # We should have created 10 new cards total (5 published + 5 drafts)
    assert_equal initial_count + 10, Card.count

    # All cards should have unique numbers within the account
    numbers = account.cards.pluck(:number)
    assert_equal numbers.uniq.size, numbers.size, "Card numbers should be unique"
  end
end
