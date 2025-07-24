class Command::Ai::Parser
  include Rails.application.routes.url_helpers

  attr_reader :context

  delegate :user, to: :context

  def initialize(context)
    @context = context
    self.default_url_options[:script_name] = context.script_name
  end

  def parse(query)
    normalized_query = resolve_named_params_to_ids command_translator.translate(query)
    build_command_for normalized_query, query
  end

  private
    def command_translator
      Command::Ai::Translator.new(context)
    end

    def build_command_for(normalized_query, query)
      query_context = context_from_query(normalized_query)
      resolved_context = query_context || context

      commands = Array.wrap(commands_from_query(normalized_query, resolved_context))

      if query_context && !commands.last.is_a?(Command::GetInsight)
        commands.unshift Command::VisitUrl.new(user: user, url: query_context.url, context: resolved_context)
      end

      Command::Composite.new(title: query, commands: commands, user: user, line: query, context: resolved_context)
    end

    def commands_from_query(normalized_query, context)
      # The query should only contain supported /commands. If that's not the case,
      # we don't want to fall back to AI again (potential stack overflow).
      parser = Command::Parser.new(context, fall_back_to_ai: false)
      if command_lines = normalized_query[:commands].presence
        command_lines.collect { parser.parse(it) }
      end
    end

    def resolve_named_params_to_ids(normalized_query)
      normalized_query.tap do |query_json|
        if query_context = query_json[:context].presence
          query_context[:assignee_ids] = query_context[:assignee_ids]&.filter_map { |name| context.find_user(name)&.id }
          query_context[:creator_ids] = query_context[:creator_ids]&.filter_map { |name| context.find_user(name)&.id }
          query_context[:closer_ids] = query_context[:closer_ids]&.filter_map { |name| context.find_user(name)&.id }
          query_context[:collection_ids] = query_context[:collection_ids]&.filter_map { |name| context.find_collection(name)&.id }
          query_context[:stage_ids] = query_context[:stage_ids]&.filter_map { |name| context.find_workflow_stage(name)&.id }
          query_context[:tag_ids] = query_context[:tag_ids]&.filter_map { |name| context.find_tag(name)&.id }
          query_context.compact!
        end
      end
    end

    def assignee_from(string)
      string_without_at = string.delete_prefix("@")
      User.all.find { |user| user.mentionable_handles.include?(string_without_at.downcase) }
    end

    def context_from_query(query_json)
      if context_properties = query_json[:context].presence
        url = cards_path(**context_properties)
        Command::Parser::Context.new(user, url: url, script_name: context.script_name, source_context: context)
      end
    end
end
