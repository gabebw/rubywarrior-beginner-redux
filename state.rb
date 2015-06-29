class State

  def initialize(options)
    @attacking = options[:attacking]
    @checked_backward = options[:checked_backward]
    @health = options[:health]
    @resting = options[:resting]
  end

  attr_accessor :health, :checked_backward, :resting

  def merge(options)
    self.class.new(to_h.merge(options))
  end

  def inspect
    to_h
  end

  private

  def to_h
    {
      attacking: @attacking,
      checked_backward: @checked_backward,
      health: @health,
      resting: @resting,
    }
  end
end
