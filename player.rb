class Player
  MAX_HEALTH = 20

  def initialize
    @attacking = false
    @health_this_turn = MAX_HEALTH
    @health_last_turn = MAX_HEALTH
  end

  def play_turn(warrior)
    @warrior = warrior
    @health_this_turn = warrior.health

    if space.captive?
      warrior.rescue!
    elsif unhealthy? && just_killed_something? && ! taking_damage?
      rest!
    elsif space.enemy?
      attack!
    elsif done_resting?
      @resting = false
      play_turn(warrior)
    else
      warrior.walk!
    end

    @health_last_turn = warrior.health
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

  def taking_damage?
    @health_this_turn < @health_last_turn
  end

  def space
    @warrior.feel
  end
end
