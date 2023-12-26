--[[
	Aseprite playable platformer mockup. Just for FUN!
	MIT License
	DarkDes, 2023
]]--

-- Search in the top level of layers in the current sprite
local function find_layer(name)
	for i,layer in ipairs(app.sprite.layers) do
		if layer.name == name then
			return layer
		end
	end
	return nil
end

-- Don't mess up the original sprite we run from, add a cloned sprite!
app.sprite = Sprite(app.sprite)

-- Canvas & Viewport
VIEW_W = 192
VIEW_H = 144

imageBuffer = Image(VIEW_W, VIEW_H)

-- Level
local TMC = find_layer("TMCollision")

-- Interface
local INT = find_layer("Interface")
local interface = {}
interface.cels = {}
interface.cels_positions = {}
interface.score_point = Point(0,0)
interface.health_point = Point(0,0)
interface.health_layer = nil

-- Player
local P = find_layer("Player")
local player = {}
player.cels = {}
player.health = 4
player.score = 0
player.do_not_hurt_me = false
player.finished = false
player.input_block = false
-- Input move
player.side = 1
player.move_x = 0
player.move_y = 0
-- Velocity
player.vel_y = 0
player.on_ground = 0
player.position = Point(0,0)
player.bounds = nil
-- Camera
camera_x = 0
camera_y = 0

-- Player cels
if P.isGroup then
	for j,layer in ipairs(P.layers) do
		for i,cel in ipairs(layer.cels) do
			if player.bounds == nil then
				player.bounds = Rectangle(cel.bounds)
			end
			table.insert(player.cels, cel)
			player.bounds = player.bounds:union(cel.bounds)
		end
	end
elseif P.isImage then
	for i,cel in ipairs(P.cels) do
		if player.bounds == nil then
			player.bounds = Rectangle(cel.bounds)
		end
		table.insert(player.cels, cel)
		player.bounds = player.bounds:union(cel.bounds)
	end
end

-- Scanning Layers:
-- Interface 
if INT.isGroup then
	for j,layer in ipairs(INT.layers) do
		if layer.isGroup then
			for j,layer2 in ipairs(layer.layers) do
				for i,cel in ipairs(layer2.cels) do
					table.insert(interface.cels, cel)
					table.insert(interface.cels_positions, Point(cel.position))
				end
			end
		else 
			for i,cel in ipairs(layer.cels) do
				table.insert(interface.cels, cel)
				table.insert(interface.cels_positions, Point(cel.position))
			end
		end
		if layer.name == "ScorePoint" then
			interface.score_point = layer.cels[1].position
		end
		if layer.name == "Health" then
			interface.health_layer = layer
			player.health = #layer.layers
		end
	end
end

-- FINISH
local finish_layers = find_layer("Finish")
local FINISH_cels = {}
for j,layer in ipairs(finish_layers.layers) do
	for i,cel in ipairs(layer.cels) do
		table.insert(FINISH_cels, cel)
	end
end

-- Dangers
local LGD = find_layer("Dangers") -- Layer group of layers and cals
local LGD_cels = {}
if LGD.isGroup then
	for j,layer in ipairs(LGD.layers) do
		for i,cel in ipairs(layer.cels) do
			table.insert(LGD_cels, cel)
		end
	end
end

-- Bonuses
local LGB = find_layer("Bonuses") -- Layer Group of layers and cels
local LGB_cels = {}
if LGB.isGroup then
	for j,layer in ipairs(LGB.layers) do
		for i,cel in ipairs(layer.cels) do
			table.insert(LGB_cels, cel)
		end
	end
end


-- Functions for canvas:
function dcanv_onkeyup(ev)
	if ev.code == "ArrowLeft" or ev.code == "ArrowRight" then 
		player.move_x = 0
	end
	if ev.code == "ArrowUp" or ev.code == "ArrowDown" then 
		player.move_y = 0
	end
end

function dcanv_onkeydown(ev)
	if ev.code == "ArrowLeft" then 
		player.move_x = -1
	elseif ev.code == "ArrowRight" then
		player.move_x = 1
	end
	
	-- Jumping
	if ev.code == "ArrowUp" then 
		player.move_y = -1
		if player.on_ground and player.input_block == false then
			player.vel_y = -10
			player.on_ground = false
		end
	elseif ev.code == "ArrowDown" then
		player.move_y = 1
	end
	
	if player.move_x ~= 0 or player.move_y ~= 0 then
		ev:stopPropagation()
	end
end

function dcanv_onpaint(ev)
	local gc = ev.context
	imageBuffer:drawSprite( app.sprite, app.frame, Point(-camera_x, -camera_y) )
	gc:drawImage( imageBuffer, 0, 0 )
	
	gc.color = Color{r=255,g=0,b=0}
	if player.health <= 0 then
		local text_size = gc:measureText("FINISHED!")
		gc:fillText( "GAME OVER!", (VIEW_W - text_size.w)/2, (VIEW_H - text_size.h)/2 )
	end
	
	gc.color = Color{r=200,g=200,b=100}
	if player.finished then
		local text_size = gc:measureText("FINISHED!")
		gc:fillText( "FINISHED!", (VIEW_W - text_size.w)/2, (VIEW_H - text_size.h)/2 )
	end
	
	-- Score
	gc.color = Color{r=200,g=200,b=100}
	gc:fillText( player.score, interface.score_point.x, interface.score_point.y )
end

-- Dialog & Canvas
local D = Dialog{ title = "Game", onclose = function() async_rendering_timer:stop() app.command.PlayAnimation() end }
D:canvas{
	id 			= "canvas",
	width 		= VIEW_W,
	height 		= VIEW_H,
	hexpand 	= true,
	vexpand 	= true,
	onkeyup		= dcanv_onkeyup,
	onkeydown	= dcanv_onkeydown,
	onpaint 	= dcanv_onpaint
}

-- Timer for disabling invincibility
hurt_timer = Timer{ interval = 1.0, ontick = function() 
	player.do_not_hurt_me = false
	hurt_timer:stop()
	end }

-- Main "Game" Loop
async_rendering_timer =
Timer{
	interval = 1.0/30.0, -- 30 fps
	ontick = function()
	-- as one event in history (per frame, ew)
	app.transaction(
	function()
	
		-- Gravitation
		if player.on_ground == false then
			if player.vel_y < 2 then 
				player.vel_y = player.vel_y + 1
			end
		else
			player.vel_y = 0
		end
		
		local p_vel_x = player.move_x
		local p_vel_y = player.vel_y
		local collided
		
		-- Player state (if dead, then no input)
		if player.input_block then
			p_vel_x = 0
		end
		
		-- Collisions: use read pixels and check alpha.
		-- If any point on the line have has an non-transparent pixel, true is returned.
		
		-- Collision Left and Right
		function collision_line_vertical(px, py, ph)
			local color = Color()
			for i=py, ph+py, 1 do 
				color = Color( TMC.cels[1].image:getPixel( px, i ) )
				if color.alpha > 128 then 
					return true
				end
			end
			return false
		end
		-- Collision Top and Bottom
		function collision_line_horisontal(px, py, pw)
			local color = Color()
			for i=px, pw+px, 1 do 
				color = Color( TMC.cels[1].image:getPixel( i, py ) )
				if color.alpha > 128 then 
					return true
				end
			end
			return false
		end
		
		-- Horizontal collisions
		collided = collision_line_vertical(player.position.x + p_vel_x, player.position.y, player.bounds.height-2)
		if collided then p_vel_x = 0 end
		
		collided = collision_line_vertical(player.position.x + player.bounds.width + p_vel_x, player.position.y, player.bounds.height-2)
		if collided then p_vel_x = 0 end
		
		-- Vertical collisions
		collided = collision_line_horisontal( player.position.x, player.position.y + p_vel_y, player.bounds.width )
		if collided then p_vel_y = 0 end
		
		collided = collision_line_horisontal( player.position.x+2, player.position.y + p_vel_y + player.bounds.height, player.bounds.width-4 )
		if collided then 
			p_vel_y = 0
			player.on_ground = true
		else
			player.on_ground = false
			if p_vel_y < 1 then
				p_vel_y = p_vel_y + 1
			end
		end
		-- Move player
		for i,cel in ipairs(player.cels) do
			cel.position = Point(cel.position.x + p_vel_x, cel.position.y + p_vel_y)
		end
		player.position = player.cels[1].position
		-- end move

		local _bounds = Rectangle( player.position.x, player.position.y, player.bounds.width, player.bounds.height)
		-- I don't know why or how it works with tilemap, 
		-- so just use the hazards\dangers and bonuses as separate layers of the target with appropriate boundaries.
		
		-- Bonus Collision
		for i,cel in ipairs(LGB_cels) do
			if cel.layer.isVisible == true and _bounds:intersects(cel.bounds) then
				-- Pick up!
				cel.layer.isVisible = false
				player.score = player.score + 100
			end
		end
		
		-- Danger Collision
		for i,cel in ipairs(LGD_cels) do
			if player.do_not_hurt_me == false and _bounds:intersects(cel.bounds) then
				-- HURT
				if player.health > 0 then 
					player.health = player.health - 1
					player.do_not_hurt_me = true
					hurt_timer:start()
					
					-- Game Over
					if player.health <= 0 then
						player.input_block = true
					end
					
					-- Change health bar indicator count
					local hp = interface.health_layer
					for h=1, #hp.layers do
						if player.health < h then
							hp.layers[h].isVisible = false
						else
							hp.layers[h].isVisible = true
						end
					end
				end
			end
		end
		
		-- Finish Collision
		for i,cel in ipairs(FINISH_cels) do
			if _bounds:intersects(cel.bounds) then
				-- Finish!
				cel.layer.isVisible = false -- Hide "finish object"
				player.finished = true
				player.input_block = true
			end
		end
		
		-- Camera follow
		camera_x = player.position.x - VIEW_W/2 + player.bounds.width/2
		camera_y = player.position.y - VIEW_H/2 + player.bounds.height/2
		
		-- Clamp camera position to sprite(location) borders
		if camera_x < 0 then camera_x = 0 elseif camera_x > app.sprite.width-VIEW_W then camera_x = app.sprite.width - VIEW_W end
		if camera_y < 0 then camera_y = 0 elseif camera_y > app.sprite.height-VIEW_H then camera_y = app.sprite.height - VIEW_H end
		
		-- Update position of Interface
		for i,cel in ipairs(interface.cels) do
			cel.position = Point(interface.cels_positions[i].x + camera_x, interface.cels_positions[i].y + camera_y)
		end

		-- Update screen
		D:repaint()
	end) -- history
	end
}

-- Starting up!
async_rendering_timer:start()
D:show{ wait=false }
app.command.PlayAnimation()

-- End of file