class Player
  def play_turn(warrior)
    space = warrior.feel
    if space.enemy?
      warrior.attack!
    else
      warrior.walk!
    end
  end
end
