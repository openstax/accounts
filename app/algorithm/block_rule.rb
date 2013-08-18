class BlockRule < Rule

  def initialize(&block)
    @block = block
  end

  def check
    @block.call
  end

end