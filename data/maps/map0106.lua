local map = ...
-- Dungeon 9 2F

ne_puzzle_step = nil
chests_puzzle_step = nil
nw_switches_next = nil -- index of the next correct switch (nil = error or not started)
nw_switches_nb_activated = 0
nb_torches_lit = 0
door_g_finished = false

function map:on_started(destination_point_name)

  -- north barrier
  if map:get_game():get_boolean(812) then
    map:switch_set_activated("n_barrier_switch", true)
    map:tile_set_enabled("n_barrier", false)
  end

  -- enemies rooms
  map:set_doors_open("door_c", true)
  if destination_point_name ~= "from_3f_e"
      and destination_point_name ~= "from_outside_e" then
    map:set_doors_open("door_b", true)
  end

  -- north-east room
  if destination_point_name == "from_3f_e" then
    map:set_doors_open("door_a", true)
    ne_puzzle_set_step(5)
  else
    ne_puzzle_set_step(1)
  end

  -- compass
  if map:get_game():get_boolean(814) then
    for i = 1, 7 do
      map:chest_set_open("compass_chest_" .. i, true)
    end
  else
    chests_puzzle_step = 1
  end

  -- clockwise switches and next doors
  if destination_point_name ~= "from_1f" then
    map:set_doors_open("door_d", true)
    map:set_doors_open("door_e", true)
    map:switch_set_activated("door_e_switch", true)
    for i = 1, 8 do
      map:switch_set_activated("nw_switch_" .. i, true)
    end
  end

  -- bridges that appear when a torch is lit
  map:tile_set_group_enabled("bridge", false)
end

function map:on_map_opening_transition_finished(destination_point_name)

  -- show the welcome message
  if destination_point_name:find("^from_outside") then
    map:start_dialog("dungeon_9.welcome")
  end
end

function map:on_switch_activated(switch_name)

  -- north barrier
  if switch_name == "n_barrier_switch" then
    sol.audio.play_sound("secret")
    sol.audio.play_sound("door_open")
    map:tile_set_enabled("n_barrier", false)
    map:get_game():set_boolean(812, true)

  -- door A
  elseif switch_name == "door_a_switch" then
    sol.audio.play_sound("secret")
    map:open_doors("door_a")

  -- door E
  elseif switch_name == "door_e_switch" then
    sol.audio.play_sound("secret")
    map:open_doors("door_e")

  -- door G
  elseif switch_name == "door_g_switch"
      and not map:door_is_open("door_g") then
    map:move_camera(1760, 520, 1000, function()
      sol.audio.play_sound("secret")
      map:open_doors("door_g")
      door_g_finished = false
    end)

  -- north-west puzzle: the switches have to be activated clockwise
  elseif switch_name:find("^nw_switch") then

    local index = tonumber(switch_name:match("^nw_switch_([1-8])$"))
    if nw_switches_nb_activated == 0 then
      -- first one
      nw_switches_next = index
    end
  
    if index == nw_switches_next then
      -- okay so far
      nw_switches_next = nw_switches_next % 8 + 1
    else
      -- error
      nw_switches_next = nil
    end
    nw_switches_nb_activated = nw_switches_nb_activated + 1

    if nw_switches_nb_activated == 8 then
      -- the 8 switches are on, was there an error?
      if nw_switches_next == nil then
	-- error
	sol.audio.play_sound("wrong")
	for i = 1, 8 do
	  map:switch_set_activated("nw_switch_" .. i, false)
	end
	nw_switches_nb_activated = 0
	map:switch_set_locked(switch_name, true)
	-- to avoid the switch to be activated again immediately
      else
	-- correct
	sol.audio.play_sound("secret")
	map:open_doors("door_d")
      end
    end
  end
end

function map:on_switch_left(switch_name)

  if switch_name:find("^nw_switch") then
    map:switch_set_locked(switch_name, false)
  end
end

function map:on_hero_on_sensor(sensor_name)

  -- north-east puzzle
  if sensor_name == "ne_puzzle_sensor_1" then

    map:hero_set_position(2408, 653)
    if ne_puzzle_step == 2 then
      -- correct
      ne_puzzle_set_step(ne_puzzle_step + 1)
    else
      -- wrong
      ne_puzzle_set_step(1)
    end

  elseif sensor_name == "ne_puzzle_sensor_2" then

    map:hero_set_position(2408, 397)
    if ne_puzzle_step == 1
      	or ne_puzzle_step == 3
	or ne_puzzle_step == 4 then
      -- correct
      ne_puzzle_set_step(ne_puzzle_step + 1)
      if ne_puzzle_step == 5 then
	sol.audio.play_sound("secret")
      end
    else
      -- wrong
      ne_puzzle_set_step(1)
    end

  -- door G
  elseif sensor_name == "door_g_success_sensor"
      and not door_g_finished then
    sol.audio.play_sound("secret")
    door_g_finished = true

  elseif sensor_name:find("^close_door_g_sensor")
      and not door_g_finished
      and map:door_is_open("door_g") then
    sol.audio.play_sound("wrong")
    map:move_camera(1760, 520, 1000, function()
      map:close_doors("door_g")
      map:switch_set_activated("door_g_switch", false)
    end) 

  -- door E
  elseif sensor_name:find("^close_door_e_sensor")
      and map:door_is_open("door_e") then
    map:close_doors("door_e")
    map:switch_set_activated("door_e_switch", false)

  -- west enemies room
  elseif sensor_name:find("^close_door_b_sensor")
      and map:has_entities("door_b_enemy")
      and map:door_is_open("door_b") then
    map:close_doors("door_b")
    map:sensor_set_group_enabled("close_door_b_sensor", false)

  -- north enemies room
  elseif sensor_name:find("^close_door_c_sensor")
      and map:has_entities("door_c_enemy")
      and map:door_is_open("door_c") then
    map:close_doors("door_c")
    map:sensor_set_group_enabled("close_door_c_sensor", false)

  -- save solid ground location
  elseif sensor_name:find("^save_solid_ground_sensor") then
    map:hero_save_solid_ground()

  -- reset solid ground location
  elseif sensor_name:find("^reset_solid_ground_sensor") then
    map:hero_reset_solid_ground()
  end
end

function map:on_enemy_dead(enemy_name)

  -- west enemies room
  if enemy_name:find("^door_b_enemy") then
    if not map:has_entities("door_b_enemy")
        and not map:door_is_open("door_b") then
      sol.audio.play_sound("secret")
      map:open_doors("door_b")
    end

  -- north enemies room
  elseif enemy_name:find("^door_c_enemy") then
    if not map:has_entities("door_c_enemy")
        and not map:door_is_open("door_c") then
      sol.audio.play_sound("secret")
      map:open_doors("door_c")
    end

  end
end

function ne_puzzle_set_step(step)

  ne_puzzle_step = step
  map:tile_set_group_enabled("ne_puzzle_step", false)
  map:tile_set_group_enabled("ne_puzzle_step_" .. step, true)
  if step < 5 then
    map:tile_set_group_enabled("secret_way_open", false)
    map:tile_set_group_enabled("secret_way_closed", true)
  else
    map:tile_set_group_enabled("secret_way_open", true)
    map:tile_set_group_enabled("secret_way_closed", false)
  end
end

function map:on_chest_empty(chest_name)

  local index = tonumber(chest_name:match("^compass_chest_([1-7])"))
  if index ~= nil then
    if index == chests_puzzle_step then
      if index == 7 then
	map:hero_start_treasure("compass", 1, 814)
      else
        map:hero_unfreeze()
	chests_puzzle_step = chests_puzzle_step + 1
      end
    else
      sol.audio.play_sound("wrong")
      map:hero_unfreeze()
      chests_puzzle_step = 1
      for i = 1, 7 do
	map:chest_set_open("compass_chest_" .. i, false)
      end
    end
  end
end

-- Torches on this map interact with the map script
-- because we don't want usual behavior from items/lamp.lua:
-- we want a shorter delay and we want torches to enable the bridge
function map:on_npc_interaction(npc_name)

  if string.find(npc_name, "^torch") then
    map:start_dialog("torch.need_lamp")
  end
end

-- Called when fire touches an NPC linked to this map
function map:on_npc_collision_fire(npc_name)

  if string.find(npc_name, "^torch") then
    
    local torch_sprite = map:npc_get_sprite(npc_name)
    if torch_sprite:get_animation() == "unlit" then
      -- temporarily light the torch up
      torch_sprite:set_animation("lit")
      if nb_torches_lit == 0 then
        map:tile_set_group_enabled("bridge", true)
      end
      nb_torches_lit = nb_torches_lit + 1
      sol.timer.start(8000, function()
        torch_sprite:set_animation("unlit")
        nb_torches_lit = nb_torches_lit - 1
        if nb_torches_lit == 0 then
	  map:tile_set_group_enabled("bridge", false)
	end
      end)
    end
  end
end

function map:on_block_moved(block_name)

  if block_name == "door_f_block"
      and not map:door_is_open("door_f") then
    sol.audio.play_sound("secret")
    map:open_doors("door_f")
  end
end

