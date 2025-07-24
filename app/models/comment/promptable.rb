module Comment::Promptable
  extend ActiveSupport::Concern

  included do
    include Rails.application.routes.url_helpers
  end

  def to_prompt
    <<~PROMPT
        BEGIN OF COMMENT #{id}

        **Content:**

        #{body.to_plain_text.first(5000)}

        #### Metadata

        * Id: #{id}
        * Card id: #{card.id}
        * Card title: #{card.title}
        * Created by: #{creator.name}}
        * Created at: #{created_at}}
        * Path: #{collection_card_path(card.collection, card, anchor: ActionView::RecordIdentifier.dom_id(self), script_name: Account.script_name)}
        END OF COMMENT #{id}
      PROMPT
  end
end
