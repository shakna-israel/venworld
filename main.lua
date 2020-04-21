local moonshine = require "moonshine"

local config = require "config"

local player = {
	img = love.graphics.newImage("img/Player.png"),
	scale = 0.5,
	rot = 0,
	x = 400,
	y = 300,
	rotspeed = 2.8,
	speed = 180,
}

function make_npc()
	img = love.graphics.newImage("img/NPC.png")
	local screen_width, screen_height = love.graphics.getDimensions()
	local npc = {
		img = img,
		scale = 0.25,
		rot = 0,
		x = screen_width / 2,
		y = screen_height,
		rotspeed = config.npc_rot_speed,
		speed = config.npc_speed,
	}
	return npc
end

local npcs = {}
local dead_npcs = {}

function math.angle(x1,y1, x2,y2) return math.atan2(y2-y1, x2-x1) end

function love.load()
  red = 115/255
  green = 27/255
  blue = 135/255
  love.graphics.setBackgroundColor(red, green, blue, 1)

  effect = moonshine(moonshine.effects.glow)
  effect.glow.strength = 5

  npcs[#npcs + 1] = make_npc()

  last_spawn = love.timer.getTime()
  score = 0

  if config.max_npcs < 20 then
  	config.max_npcs = 20
  end

  love.window.setTitle("venworld")
end

function love.draw()
	love.graphics.setColor(1, 1, 1, 1)

	-- Draw NPCs
	for i=1, #npcs do
		love.graphics.draw(npcs[i].img, npcs[i].x, npcs[i].y, npcs[i].rot, npcs[i].scale, npcs[i].scale, npcs[i].img:getWidth() / 2, npcs[i].img:getHeight() / 2)
	end

	-- Draw corpses
	for i=1, #dead_npcs do
		love.graphics.setColor(1, 1, 1, dead_npcs[i].alpha)
		love.graphics.draw(dead_npcs[i].img, dead_npcs[i].x, dead_npcs[i].y, dead_npcs[i].rot, dead_npcs[i].scale, dead_npcs[i].scale, dead_npcs[i].img:getWidth() / 2, dead_npcs[i].img:getHeight() / 2)
	end
	love.graphics.setColor(1, 1, 1, 1)

	-- Draw Player
	effect(function()
		love.graphics.draw(player.img, player.x, player.y, player.rot, player.scale, player.scale, player.img:getWidth() / 2, player.img:getHeight() / 2)
	end)

	if score > -10 then
		love.graphics.print(string.format("Score: %d", score), 0, 0)
	else
		love.graphics.print("GAME OVER", 0, 0)
	end
end

function collision(a, b)
	aw, ah = a.img:getDimensions()
	bw, bh = b.img:getDimensions()

	aw = (aw * a.scale) / 2
	ah = (ah * a.scale) / 2

	bw = (bw * b.scale) / 2
	bh = (bh * b.scale) / 2

	return a.x < (b.x + bw) and
		b.x < (a.x + aw) and
		a.y < (b.y + bh) and
		b.y < (a.y + ah)
end

function not_in_table(array, value)
	for i=1, #array do
		if i == value then
			return false
		end
	end
	return true
end

function love.update(dt)
	if love.keyboard.isDown(config.quit) then
		love.event.quit(0)
	end

	if score < -10 then
		return
	end

	-- Player controls
	if love.keyboard.isDown(config.left) then
		player.rot = player.rot - (player.rotspeed * dt)
	end
	if love.keyboard.isDown(config.right) then
		player.rot = player.rot + (player.rotspeed * dt)
	end

	if love.keyboard.isDown(config.up) then
		player.x = player.x + math.cos(player.rot - 1.5) * player.speed * dt
    	player.y = player.y + math.sin(player.rot - 1.5) * player.speed * dt
	end

	if love.keyboard.isDown(config.down) then
		player.x = player.x - math.cos(player.rot - 1.5) * (player.speed / 2) * dt
    	player.y = player.y - math.sin(player.rot - 1.5) * (player.speed / 2) * dt
	end

	local screen_width, screen_height = love.graphics.getDimensions()

	-- Player out of bounds
	if player.x < 1 then
		player.x = screen_width
	end
	if player.y < 1 then
		player.y = screen_height
	end
	if player.x > screen_width then
		player.x = 2
	end
	if player.y > screen_height then
		player.y = 2
	end

	-- Player collision
	for i=1, #npcs do
		if collision(npcs[i], player) then
			npcs[i].x = npcs[i].x - (screen_width / 2)
			npcs[i].y = npcs[i].y - (screen_height / 2)
			score = score - 1
		end
	end

	-- NPC collision
	remove_npcs = {}
	for x=1, #npcs do
		for y=1, #npcs do
			if x ~= y then
				if collision(npcs[x], npcs[y]) then
					remove_npcs[#remove_npcs + 1] = x
					score = score + 1
				end
			end
		end
	end

	-- NPC Removal
	new_npcs = {}
	for i=1, #npcs do
		if not_in_table(remove_npcs, i) then
			new_npcs[#new_npcs + 1] = npcs[i]
		else
			dead_npcs[#dead_npcs + 1] = npcs[i]
			dead_npcs[#dead_npcs].alpha = 1
		end
	end
	npcs = new_npcs

	-- NPC movement
	for i=1, #npcs do
		-- Rotate towards
		local r = math.angle(npcs[i].x, npcs[i].y, player.x, player.y)
		if r > npcs[i].rot then
			npcs[i].rot = npcs[i].rot + (npcs[i].rotspeed * dt)
		elseif r < npcs[i].rot then
			npcs[i].rot = npcs[i].rot - (npcs[i].rotspeed * dt)
		end

		-- Move towards
		npcs[i].x = npcs[i].x + math.cos(npcs[i].rot) * npcs[i].speed * dt
    	npcs[i].y = npcs[i].y + math.sin(npcs[i].rot) * npcs[i].speed * dt

    	-- Loop around
    	if npcs[i].x < 1 then
			npcs[i].x = screen_width
		end
		if npcs[i].y < 1 then
			npcs[i].y = screen_height
		end
		if npcs[i].x > screen_width then
			npcs[i].x = 2
		end
		if npcs[i].y > screen_height then
			npcs[i].y = 2
		end
	end

	-- Dead tick
	new_dead_npcs = {}
	for i=1, #dead_npcs do
		dead_npcs[i].alpha = dead_npcs[i].alpha - (0.1 * dt)
		if dead_npcs[i].alpha > 0.1 then
			new_dead_npcs[#new_dead_npcs + 1] = dead_npcs[i]
		end
	end
	dead_npcs = new_dead_npcs

	-- New spawns
	local now = love.timer.getTime()
	if now - last_spawn > 2 then
		if #npcs < config.max_npcs then
			npcs[#npcs + 1] = make_npc()
			last_spawn = now
		end
	end
end