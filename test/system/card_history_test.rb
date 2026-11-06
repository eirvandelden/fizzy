require "application_system_test_case"

class CardHistoryTest < ApplicationSystemTestCase
  setup do
    sign_in_as(users(:david))
  end

  test "full history shows the creation row first" do
    visit card_url(cards(:logo))

    assert_no_text "Created by David"

    click_on "Full history"

    assert_text "Created by David"
    assert_equal "creation_card_#{cards(:logo).id}", first(".comment-by-system", minimum: 1, visible: true)[:id]
  end

  test "collapsing the full history hides the creation row" do
    visit card_url(cards(:logo))

    click_on "Full history"
    assert_text "Created by David"

    click_on "Full history"
    assert_no_text "Created by David"
  end

  test "a card with one system comment shows no full history button and no creation row" do
    visit card_url(cards(:layout))

    assert_no_button "Full history"
    assert_no_text "Created by David"
  end

  test "a card with no system comments shows no creation row" do
    visit card_url(cards(:buy_domain))

    assert_no_button "Full history"
    assert_no_text "Created by David"
  end
end
