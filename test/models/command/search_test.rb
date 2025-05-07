require "test_helper"

class Command::SearchTest < ActionDispatch::IntegrationTest
  include CommandTestHelper

  test "redirect to the cards index filtering by search terms" do
    result = execute_command "some text"

    assert_equal cards_path(indexed_by: "newest", terms: [ "some text" ]), result.url
  end

  test "respect existing filters" do
    result = execute_command "some text", context_url: "http://37signals.fizzy.localhost:3006/cards?collection_ids%5B%5D=#{collections(:writebook).id}"

    assert_equal cards_path(indexed_by: "newest", collection_ids: [ collections(:writebook).id ], terms: [ "some text" ]), result.url
  end
end
