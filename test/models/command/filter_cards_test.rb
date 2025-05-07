require "test_helper"

class Command::FilterCardsTest < ActionDispatch::IntegrationTest
  include CommandTestHelper

  setup do
    @card_ids = cards(:logo, :layout).collect(&:id)
  end

  test "redirect to the cards index filtering by cards" do
    result = execute_command "#{@card_ids.join(" ")}"

    assert_equal cards_path(indexed_by: "newest", card_ids: @card_ids), result.url
  end

  test "respect existing filters" do
    result = execute_command "#{@card_ids.join(",")}", context_url: "http://37signals.fizzy.localhost:3006/cards?collection_ids%5B%5D=#{collections(:writebook).id}"

    assert_equal cards_path(indexed_by: "newest", collection_ids: [ collections(:writebook).id ], card_ids: @card_ids), result.url
  end
end
