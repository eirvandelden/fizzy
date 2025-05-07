require "test_helper"

class Command::AssignTest < ActionDispatch::IntegrationTest
  include CommandTestHelper

  setup do
    Current.session = sessions(:david)
    @card = cards(:text)
  end

  test "assign card on perma" do
    assert_difference -> { @card.assignees.count }, +2 do
      execute_command "/assign @kevin @david", context_url: collection_card_url(@card.collection, @card)
    end

    assert_includes @card.assignees.reload, users(:david)
    assert_includes @card.assignees, users(:kevin)
  end

  test "assign cards on cards' index page" do
    execute_command "/assign @kevin @david", context_url: collection_cards_url(@card.collection)

    cards(:logo, :text, :layout).each do |card|
      assert_includes card.assignees.reload, users(:david)
      assert_includes card.assignees, users(:kevin)
    end
  end

  test "undo assignment" do
    Assignment.destroy_all
    command = parse_command "/assign @kevin @david", context_url: collection_cards_url(@card.collection)

    command.execute

    cards(:logo, :text, :layout).each do |card|
      assert_includes card.assignees.reload, users(:david)
      assert_includes card.assignees, users(:kevin)
    end

    command.reload.undo

    cards(:logo, :text, :layout).each do |card|
      assert_empty card.reload.assignees.reload
    end
  end
end
