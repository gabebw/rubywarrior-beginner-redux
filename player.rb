require "pp"
require "./state"

class Player
  MAX_HEALTH = 20

  def initialize
    initial_state = State.new(
      attacking: false,
      resting: false,
      checked_backward: false,
      health: MAX_HEALTH,
    )
    @states = [initial_state]
  end

  def play_turn(warrior)
    @warrior = warrior

    if space.captive?
      add_same_state
      warrior.rescue!
    elsif space_backward.captive?
      add_same_state
      warrior.rescue! :backward
    elsif ! current_state.checked_backward
      if space_backward.wall?
        finish_walking_backward
      else
        add_same_state
        warrior.walk! :backward
      end
    elsif unhealthy?
      if taking_damage?
        add_same_state
        warrior.walk! :backward
      else
        rest!
      end
    elsif space.enemy?
      attack!
    elsif done_resting?
      finish_resting
    else
      add_same_state
      warrior.walk!
    end
  end

  private

  def unhealthy?
    @warrior.health < MAX_HEALTH
  end

  def done_resting?
    current_state.resting && ! unhealthy?
  end

  def rest!
    add_state(resting: true)
    @warrior.rest!
  end

  def attack!
    add_state(attacking: true)
    @warrior.attack!
  end

  def taking_damage?
    current_state.health < previous_state.health
  end

  def being_attacked_by_archer?
    current_state.being_attacked_by_archer
  end

  def finish_walking_backward
    current_state.checked_backward = true
    play_turn(@warrior)
  end

  def finish_resting
    add_state(resting: false)
    play_turn(@warrior)
  end

  def space
    @warrior.feel
  end

  def space_backward
    @warrior.feel :backward
  end

  def current_state
    @states.last
  end

  def previous_state
    @states[-2]
  end

  def add_state(options)
    @states << current_state.merge(options.merge(health: @warrior.health))
  end

  def add_same_state
    add_state(health: @warrior.health)
  end
end
