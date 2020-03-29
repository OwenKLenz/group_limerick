class Limerick
  def initialize
    @lines = []
  end

  def complete?
    @lines.size == 5
  end

  def <<(line)
    @lines << line
  end

  def to_s
    @lines.join("\n")
  end
end