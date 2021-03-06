require "pry"

require "./state"
require "./null_enemy"

class Player
  MAX_HEALTH = 20
  ARCHER = "Archer"
  UNHEALTHY_CUTOFF = MAX_HEALTH - 5

  def initialize
    initial_state = State.new(
      resting: false,
      checked_backward: false,
      health: MAX_HEALTH,
    )
    @states = [initial_state]
  end

  def play_turn(warrior)
    @warrior = warrior

    rescue_captive ||
      walk_toward_stairs ||
      pivot_away_from_wall ||
      shoot_at_enemy ||
      walk_toward_archer_if_rested ||
      attack_nearby_archer ||
      safely_rest ||
      attack_enemy ||
      explore_backward ||
      finish_resting ||
      walk!
  end

  private

  def rescue_captive
    if space.captive?
      rescue!
    elsif space_backward.captive?
      rescue! :backward
    end
  end

  def walk_toward_stairs
    if space.stairs?
      # If we're at the stairs, we don't care about health.
      walk!
    end
  end

  def pivot_away_from_wall
    if facing_wall?
      pivot!
    end
  end

  def shoot_at_enemy
    if clear_shot_at_enemy?(:forward) || clear_shot_at_enemy?(:backward)
      smartly_shoot_at_enemy!
    end
  end

  def walk_toward_archer_if_rested
    if being_attacked_by_archer? && recently_rested?
      walk!
    end
  end

  def attack_nearby_archer
    if next_to_archer?
      # Handle the case where we're next to an archer separately,
      # because backing away from them makes the warrior take a lot of damage.
      attack!
    end
  end

  def safely_rest
    if unhealthy? && ! being_attacked_by_archer?
      if taking_damage? || space.enemy?
        walk! :backward
      else
        rest!
      end
    end
  end

  def attack_enemy
    if space.enemy?
      attack!
    end
  end

  def explore_backward
    if ! current_state.checked_backward
      if space_backward.wall?
        finish_walking_backward
      else
        walk! :backward
      end
    end
  end

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
    add_state_with_new_health
  end

  def walk!(direction = :forward)
    @warrior.walk! direction
    add_state_with_new_health
  end

  def pivot!
    @warrior.pivot!
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
    if done_resting?
      current_state.resting = false
      play_turn(@warrior)
    end
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
      enemy_space.unit
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
