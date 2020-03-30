class Limerick
  include Enumerable

  def initialize
    @lines = []
  end

  def each
    return @lines unless block_given?

    @lines.each do |line|
      yield(line)
    end
  end

  def size
    @lines.size
  end

  def complete?
    @lines.size == 5
  end

  def <<(line)
    @lines << line
  end

  def to_s
    @lines.join("<br>")
  end
end