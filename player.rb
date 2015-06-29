class Player
  MAX_HEALTH = 20

  def initialize
    @attacking = false
  end

  def play_turn(warrior)
    @warrior = warrior

    if unhealthy? && just_killed_something?
      rest!
    elsif space.enemy?
      attack!
    elsif done_resting?
      @resting = false
      play_turn(warrior)
    else
      warrior.walk!
    end
  end

  private

  def unhealthy?
    @warrior.health < MAX_HEALTH
  end

  def just_killed_something?
    @attacking && ! space.enemy?
  end

  def done_resting?
    @resting && ! unhealthy?
  end

  def rest!
    @resting = true
    @warrior.rest!
  end

  def attack!
    @attacking = true
    @warrior.attack!
  end

  def space
    @warrior.feel
  end
end
