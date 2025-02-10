require "test_helper"

class Bubble::StatusesTest < ActiveSupport::TestCase
  test "bubbles start out in a `creating` state" do
    bubble = buckets(:writebook).bubbles.create! creator: users(:kevin), title: "Newly created bubble"

    assert bubble.creating?
    assert_not_includes Bubble.published_or_drafted_by(users(:kevin)), bubble
    assert_not_includes Bubble.published_or_drafted_by(users(:jz)), bubble
  end

  test "bubbles are only visible to the creator when drafted" do
    bubble = buckets(:writebook).bubbles.create! creator: users(:kevin), title: "Drafted Bubble"
    bubble.drafted!

    assert_includes Bubble.published_or_drafted_by(users(:kevin)), bubble
    assert_not_includes Bubble.published_or_drafted_by(users(:jz)), bubble
  end

  test "bubbles are visible to everyone when published" do
    bubble = buckets(:writebook).bubbles.create! creator: users(:kevin), title: "Published Bubble"
    bubble.published!

    assert_includes Bubble.published_or_drafted_by(users(:kevin)), bubble
    assert_includes Bubble.published_or_drafted_by(users(:jz)), bubble
  end
end
