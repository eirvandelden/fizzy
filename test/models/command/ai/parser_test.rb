require "test_helper"

class Command::Ai::ParserTest < ActionDispatch::IntegrationTest
  include CommandTestHelper, VcrTestHelper

  setup do
    freeze_timestamps
  end

  test "parse command strings into a composite command containing the individual commands" do
    command = parse_command "assign @kevin and close"

    assert_equal "assign @kevin and close", command.line
    assert_instance_of Command::Composite, command
    commands = command.commands

    assert_instance_of Command::Assign, commands.first
    assert_instance_of Command::Close, commands.last
  end

  test "resolve filter string params as ids" do
    command = parse_command "cards assigned to kevin, tagged with #web, in the collection writebook"

    url = command.commands.first.url
    query_string = URI.parse(url).query
    params = Rack::Utils.parse_nested_query(query_string).with_indifferent_access

    assert_equal [ users(:kevin).id.to_s ], params[:assignee_ids]
    assert_equal [ collections(:writebook).id.to_s ], params[:collection_ids]
    assert_equal [ tags(:web).id.to_s ], params[:tag_ids]
  end

  test "if the AI translator emitted an unknown command, this will result in a regular search (not on AI recursion)" do
    Command::Ai::Translator.any_instance.stubs(:translate).returns(commands: [ "/missing" ])

    command = parse_command "assign @kevin and close"
    assert command.commands.one?

    search_command = command.commands.first
    assert search_command.is_a?(Command::Search)
    assert_equal "/missing", search_command.terms
  end
end
