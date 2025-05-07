require "test_helper"

class Command::CloseTest < ActionDispatch::IntegrationTest
  include CommandTestHelper

  setup do
    Current.session = sessions(:david)
    @card = cards(:text)
  end

  test "close card on perma" do
    assert_changes -> { @card.reload.closed? }, from: false, to: true do
      execute_command "/close", context_url: collection_card_url(@card.collection, @card)
    end

    assert_equal Closure::Reason.default, @card.closure.reason
    assert_equal users(:david), @card.closed_by
  end

  test "close card on perma with reason" do
    assert_changes -> { @card.reload.closed? }, from: false, to: true do
      execute_command "/close Not now", context_url: collection_card_url(@card.collection, @card)
    end

    assert_equal users(:david), @card.closed_by
    assert_equal "Not now", @card.closure.reason
  end

  test "close cards on cards' index page" do
    cards = cards(:logo, :text, :layout)
    cards.each(&:reopen)

    execute_command "/close", context_url: collection_cards_url(@card.collection)

    cards.each { it.reload.closed? }
  end

  test "undo close" do
    cards = cards(:logo, :text, :layout)
    cards.each(&:reopen)

    command = parse_command "/close", context_url: collection_cards_url(@card.collection)
    command.execute

    cards.each { it.reload.closed? }

    command.undo

    cards.each { it.reload.open? }
  end
end
