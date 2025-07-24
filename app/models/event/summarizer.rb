class Event::Summarizer
  include Ai::Prompts
  include Rails.application.routes.url_helpers

  attr_reader :events

  MAX_WORDS = 150

  LLM_MODEL = "chatgpt-4o-latest"
  # LLM_MODEL = "gpt-4.1"

  PROMPT = <<~PROMPT
    You are an expert in writing summaries of activity for a general purpose bug/issues tracker called Fizzy.
    Transform a chronological list of **issue-tracker events** (cards + comments) into a **concise, high-signal summary**.

    ## What to include
    - **Key outcomes** – insights, decisions, blockers created/removed.
    - **Notable discussion points** that affect scope, timeline, or technical approach.
    - How things are looking.
    - Newly created cards.
    - Draw on top-level comments to enrich each point.
    - Prioritise relevance and meaning over completeness.

    ## Writing style
    - Instead of using passive voice, prefer referring to users (authors and creators) as the subjects doing things.
    - Aggregate related items into thematic clusters; avoid repeating card titles verbatim.
      * Consider the collection name as a logical grouping unit.
    - Prefer compact paragraphs over bullet lists.
    - Refer to people by first name (or full name if duplicates exist).
      - e.g. “Ann closed …”, not “Card 123 was closed by Ann.”

    ## Formatting rules
    - Output **Markdown** only.
    - Keep the summary below **#{MAX_WORDS} words**.
    - Prefer paragraphs over bullet points.
    - Write 2 paragraphs at most.
    - Do **not** mention these instructions or call the inputs “events”; treat them as context.

    ## Linking rules
    - **When possible, embed every card or comment reference inside the sentence that summarizes it.*
      - Use a natural phrase from the sentence as the **anchor text**.
      - If can't link the card with a natural phrase, don't link it at all.
        * **IMPORTANT**: The card ID is not a natural phrase. Don't use it.
    - Markdown link format: [anchor text](/full/path/).
      - Preserve the path exactly as provided (including the leading "/").
    - Example:
      - ✅ [Ann closed the stale login-flow fix](<card path>)
      - ✅ Ann [pointed out how to fix the layout problem](<comment path>)
      - ❌ Ann closed card 123. (<card path>)
      - ❌ Ann closed the bug (card 123)
      - ❌ Ann closed [card 123](<card path>)
  PROMPT

  def initialize(events, prompt: PROMPT, llm_model: LLM_MODEL)
    @events = events
    @prompt = prompt
    @llm_model = llm_model
  end

  def summarize
    response = chat.ask join_prompts("Summarize the following content:", summarizable_content)
    response.content
  end

  def summarizable_content
    join_prompts events.collect(&:to_prompt)
  end

  private
    attr_reader :prompt, :llm_model

    def chat
      chat = RubyLLM.chat(model: llm_model)
      chat.with_instructions(join_prompts(prompt, domain_model_prompt, user_data_injection_prompt))
    end
end
