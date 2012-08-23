local map = ...
-- Dungeon 9 5F

function map:on_started(destination_point_name)

  map:set_doors_open("door_b", true)
  map:set_doors_open("door_c", true)
  map:set_doors_open("door_d", true)
  map:npc_set_group_enabled("child", false)
end

function map:on_block_moved(block_name)

  -- door A
  if block_name == "door_a_block" then
    if not map:door_is_open("door_a") then
      sol.audio.play_sound("secret")
      map:open_doors("door_a")
    end

  -- doors B and C
  elseif block_name == "door_bc_block" then
    sol.audio.play_sound("secret")
    map:open_doors("door_b")
    map:open_doors("door_c")
  end

end

function map:on_hero_on_sensor(sensor_name)

  -- door B
  if sensor_name:find("^close_door_b_sensor") then
    if map:door_is_open("door_b")
        and map:has_entities("door_b_enemy") then
      map:close_doors("door_b")
    end

  -- door C
  elseif sensor_name:find("^close_door_c_sensor") then
    if map:door_is_open("door_c")
        and map:has_entities("door_c_enemy") then
      map:close_doors("door_c")
    end

  -- door B + C
  elseif sensor_name:find("^close_door_bc_sensor") then
    map:close_doors("door_b")
    map:close_doors("door_c")
    map:sensor_set_group_enabled("close_door_bc_sensor", false)

  -- door D
  elseif sensor_name:find("^close_door_d_sensor") then
    if map:door_is_open("door_d")
        and not map:enemy_is_dead("door_d_enemy") then
      map:close_doors("door_d")
      map:enemy_set_enabled("door_d_enemy", true)
    end

  -- childs
  elseif sensor_name == "childs_hint_sensor" then
    map:get_hero():freeze()
    map:get_hero():set_direction(1)
    map:npc_set_group_enabled("child", true)
    for i = 1, 8 do
      local sprite = map:npc_get_sprite("child_" .. i)
      sprite:set_ignore_suspend(true)
    end
    sol.timer.start(3000, function()
      map:get_hero():unfreeze()
      map:sensor_set_enabled(sensor_name, false)
      map:start_dialog("dungeon_9.5f_childs_hint")
    end)
  end
end

function map:on_enemy_dead(enemy_name)

  -- door D
  if enemy_name == "door_d_enemy" then
    if not map:door_is_open("door_d") then
      sol.audio.play_sound("secret")
      map:open_doors("door_d")
    end

  -- door B
  elseif enemy_name:find("^door_b_enemy") then
    if not map:has_entities("door_b_enemy")
        and not map:door_is_open("door_b") then
      sol.audio.play_sound("secret")
      map:open_doors("door_b")
    end
 
  -- door C
  elseif enemy_name:find("^door_c_enemy") then
    if not map:has_entities("door_c_enemy")
        and not map:door_is_open("door_c") then
      sol.audio.play_sound("secret")
      map:open_doors("door_c")
    end
  end
end

