# A composite of commands
class Command::Composite < Command
  store_accessor :data, :title

  has_many :commands, inverse_of: :parent, dependent: :destroy

  def execute
    commands.collect { it.execute }
  end

  def undo
    undoable_commands.collect { it.undo }
  end

  def undoable?
    undoable_commands.any?
  end

  def confirmation_prompt
    confirmations = commands_excluding_redirections.collect(&:confirmation_prompt).collect { "- #{it}." }.join("\n")

    <<~MD
      You are about to:

      #{confirmations}
    MD
  end

  def needs_confirmation?
    commands.any?(&:needs_confirmation?)
  end

  def error_messages
    commands.flat_map(&:error_messages).uniq
  end

  private
    def commands_excluding_redirections
      commands.reject { it.is_a?(Command::VisitUrl) }
    end

    def undoable_commands
      @undoable_commands ||= commands.filter(&:undoable?).reverse
    end
end
