require "pp"
require "./state"

class Player
  MAX_HEALTH = 20
  ARCHER = "a"

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
      rescue!
    elsif space_backward.captive?
      rescue! :backward
    elsif space.stairs?
      # If we're at the stairs, we don't care about health.
      walk!
    elsif facing_wall?
      warrior.pivot!
      add_state_with_new_health
    elsif ! current_state.checked_backward
      if space_backward.wall?
        finish_walking_backward
      else
        walk! :backward
      end
    elsif being_attacked_by_archer? && recently_rested?
      walk!
    elsif next_to_archer?
      # Handle the case where we're next to an archer separately,
      # because backing away from them makes the warrior take a lot of damage.
      attack!
    elsif unhealthy? && ! being_attacked_by_archer?
      if taking_damage? || space.enemy?
        walk! :backward
      else
        rest!
      end
    elsif space.enemy?
      attack!
    elsif done_resting?
      finish_resting
    else
      walk!
    end
  end

  private

  def unhealthy?
    @warrior.health < MAX_HEALTH
  end

  def recently_rested?
    @states.last(3).map(&:health).include?(MAX_HEALTH)
  end

  def done_resting?
    current_state.resting && ! unhealthy?
  end

  def rest!
    @warrior.rest!
    add_state(resting: true)
  end

  def rescue!(direction = :forward)
    @warrior.rescue! direction
    add_state_with_new_health
  end

  def attack!
    @warrior.attack!
    add_state(attacking: true)
  end

  def walk!(direction = :forward)
    @warrior.walk! direction
    add_state_with_new_health
  end

  def taking_damage?
    current_state.health < previous_state.health
  end

  def being_attacked_by_archer?
    taking_damage? && space.empty?
  end

  def next_to_archer?
    space.enemy? && space.unit.character == ARCHER
  end

  def finish_walking_backward
    current_state.checked_backward = true
    play_turn(@warrior)
  end

  def finish_resting
    current_state.resting = false
    play_turn(@warrior)
  end

  def facing_wall?
    space.wall?
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

  def add_state_with_new_health
    add_state(health: @warrior.health)
  end
end
