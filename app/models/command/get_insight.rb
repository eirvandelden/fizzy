class Command::GetInsight < Command
  include ::Ai::Prompts, Command::Cards

  store_accessor :data, :query, :params

  def title
    "Insight query '#{query}'"
  end

  def execute
    response = chat.ask query
    Command::Result::InsightResponse.new(response.content)
  end

  def undoable?
    false
  end

  def needs_confirmation?
    false
  end

  private
    MAX_COMPLETED_CARDS = 40

    def chat
      chat = RubyLLM.chat(model: "chatgpt-4o-latest")
      chat.with_instructions(join_prompts(prompt, domain_model_prompt, current_view_prompt, user_data_injection_prompt, cards_context))
    end

    def prompt
      <<~PROMPT
        You are a helpful assistant that is able to provide answers and insights about the data
        in a general purpose bug/issues tracker called Fizzy.

        ## General rules

        - Try to provide direct answers and insights.
        - If necessary, elaborate on the reasons for your answer.
        - When asking for summaries, try to highlight key outcomes.
        - If you need further details or clarifications, indicate it.
        - When referencing cards or comments, always link them (see rules below).
        - **NEVER** answer with cards that don't exist.
        - Notice that the current card (this card) is provided when inside a card, in the section BEGIN OF CURRENT CARD

        ## Critical rules

        - Always assume that the user is querying about information in the system, not asking you to generate similar data.
        - Never include cards that don't exist in your answers.
        - When asking for similar cards, tickets, bugs, etc., never imagine those. Only reference cards from the list of cards provided.
        - If you are missing cards or information, indicate it instead of making up a response.

        ## Linking rules

        - When presenting a given insight, if it clearly derives from a specific card or comment,
          include a link to the card or comment path.
          * Don't add these as standalone links, but referencing words from the insight
        - Markdown link format: [anchor text](/full/path/).
          - Preserve the path exactly as provided (including the leading "/").
        - Prefer anchor text links that read naturally over numbers.
        - When showing the card title as the link anchor text, also include #<card id> at the end between parentheses.
      PROMPT
    end

    def cards_context
      promptable_cards.collect(&:to_prompt).join("\n")
    end

    def promptable_cards
      if filter.indexed_by.latest? && context.viewing_list_of_cards?
        cards_including_closed_ones
      else
        cards
      end
    end

    def cards_including_closed_ones
      closed_cards = user.accessible_cards.closed.recently_closed_first.limit(MAX_COMPLETED_CARDS)
      open_cards = cards

      open_sql = open_cards.to_sql
      closed_sql = "SELECT * FROM (#{closed_cards.to_sql})" # isolate limit
      sql = " SELECT * FROM ( #{open_sql} UNION ALL #{closed_sql} ) AS cards "

      Card.from("(#{sql}) AS cards")
    end

    def filter
      user.filters.from_params(params.reverse_merge(**FilterScoped::DEFAULT_PARAMS))
    end
end
