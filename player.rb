require "pry"

require "./state"
require "./null_enemy"

class Player
  MAX_HEALTH = 20
  ARCHER = "Archer"
  UNHEALTHY_CUTOFF = MAX_HEALTH - 5

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
    elsif clear_shot_at_enemy?(:forward) || clear_shot_at_enemy?(:backward)
      smartly_shoot_at_enemy!
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
    elsif ! current_state.checked_backward
      if space_backward.wall?
        finish_walking_backward
      else
        walk! :backward
      end
    elsif done_resting?
      finish_resting
    else
      walk!
    end
  end

  private

  def clear_shot_at_enemy?(direction)
    captive_index = look(direction).map(&:captive?).index(true) || -1
    empty_index = look(direction).map(&:empty?).index(true) || 0
    enemy_index = look(direction).map(&:enemy?).index(true)

    if enemy_index
      enemy_index < captive_index || enemy_index > 0 && captive_index < 0
    end
  end

  def smartly_shoot_at_enemy!
    # Shoot at archers first, then shoot at the thing with more health
    if closest_enemy(:forward).name == ARCHER
      shoot! :forward
    elsif closest_enemy(:backward).name == ARCHER
      shoot! :backward
    elsif closest_enemy(:forward).health > closest_enemy(:backward).health
      shoot! :forward
    elsif clear_shot_at_enemy?(:forward)
      shoot! :forward
    elsif clear_shot_at_enemy?(:backward)
      shoot! :backward
    end
  end

  def shoot!(direction = :forward)
    @warrior.shoot! direction
    add_state_with_new_health
  end

  def unhealthy?
    @warrior.health <= UNHEALTHY_CUTOFF
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

  def closest_enemy(direction)
    enemy_space = look(direction).detect(&:enemy?)
    if enemy_space
      enemy_space.unit || NullEnemy.new
    else
      NullEnemy.new
    end
  end

  def previous_state
    @states[-2] || current_state
  end

  def add_state(options)
    @states << current_state.merge(options.merge(health: @warrior.health))
  end

  def look(direction = :forward)
    @warrior.look(direction)
  end

  def add_state_with_new_health
    add_state(health: @warrior.health)
  end
end
