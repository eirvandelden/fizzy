require "test_helper"

class Cards::CreationViewTest < ActionView::TestCase
  test "renders \"Created by\" and the creator name" do
    render "cards/creation", card: cards(:logo)

    assert_select "#creation_card_#{cards(:logo).id}.comment-by-system.comment-by-system--creation" do
      assert_select ".comment__body strong", text: "Created"
      assert_select ".comment__body", text: "Created by David"
    end
  end

  test "renders the creation day as a date time tag" do
    card = cards(:logo)

    render "cards/creation", card: card

    assert_select "time[data-local-time-target=date][datetime=?]", card.created_at.to_i.to_s
  end

  test "escapes the creator name" do
    card = Card.new(creator: User.new(name: "<b>Ana</b>"), created_at: Time.utc(2025, 3, 3))

    render "cards/creation", card: card

    assert_select ".comment__body b", count: 0
    assert_includes rendered, "&lt;b&gt;Ana&lt;/b&gt;"
  end

  test "renders with one query when the creator is not loaded" do
    card = Card.find(cards(:logo).id)

    assert_queries_count(1) { render "cards/creation", card: card }
  end

  test "renders without queries once the creator is loaded" do
    card = Card.find(cards(:logo).id)
    card.creator

    assert_no_queries { render "cards/creation", card: card }
  end
end
