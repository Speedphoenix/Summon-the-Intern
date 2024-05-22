pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
function _init()
	debug = true

	cur_mapx = 0
	cur_mapy = 0
	blinkt=0
	t=0
	frames = 0

	mode = "start"
	startstart()

	sqrt_inv_2 = 1 / sqrt(2)
	
	curshake = 0.
	
	leave_dayratio = 0.9
	day_duration = 1800
	day_count = 0
	
	-- time before the ❎ anim pops up
	endmenu_pause = 30
	
	paper_sp = 58
	interact_distance_sq = 11 * 11
	
	prevbtno = false
	prevbtnx = false
	
	burnout = 0
	max_brnt = 100
	
	if debug then
		burnout = max_brnt - 10
	end
	
	paper_load = {59, 60, 61, 62, 63}
	
	neutral_quotes = {
		"could you come over, please",
		"we need help",
		"come here",
		"intern, please",
		"come to my desk",
	}
	negative_quotes = {
		"faster, boy",
		"will it be today?",
		"hurry up!",
		"stop taking breaks",
		"slouching again?",
		"i summoned you hours ago!",
	}
	miss_quotes = {
		"fine, i'll do it myself",
		"boss will hear of this",
		"hmpf, what good are you?",
		--                             < limit
	}
	
	animables = {}
end



function _update()
	frames += 1

	if mode =="game" then update_game()
	elseif mode == "start" then update_start()
	elseif mode == "end" then update_end() end
	prevbtno = btn(🅾️)
	prevbtnx = btn(❎)
end

function pow(a, b)
	local ret = 1
	for i=1, b do
		ret *= a
	end
	return ret
end

function _draw()
	
	if curshake > 0 then
		local v = curshake -- ceil(curshake)
		local x = rnd(v) - v / 2
		local y = rnd(v) - v / 2
		if x > 0 then
			x = ceil(x)
		else
			x = flr(x)
		end
		if y > 0 then
			y = ceil(y)
		else
			y = flr(y)
		end
		
		
		camera(x, y)
		curshake *= 0.5
	else
		camera()
	end
	
	if abs(curshake) < 0.1 then
		curshake = 0
	end

	if mode =="game" then draw_game()
	elseif mode == "start" then draw_start()
	elseif mode == "end" then draw_end() end

	if player != nil then
--		print(player.running, 0, 0, 0)
	end
end

function reset_map()
	reload(0x1000, 0x1000, 0x2000)
end

-->8
-- custom function

function update_player()
	local inx = 0
	local iny = 0
	local dash = false
	
	local lx=player.x
	local ly=player.y

	if btn(⬅️) then inx -= 1 player.flipx = true end
	if btn(➡️) then inx += 1 player.flipx = false end
	if btn(⬆️) then iny -= 1 end
	if btn(⬇️) then iny += 1 end
	
	local ldx = inx
	local ldy = iny

 if player.dash_cd > 0 then
	 player.dash_cd -= 1
	else
	 if btn(❎) and not prevbtnx then
 		dash = true
 		player.dash_cd = player.dash_delay
	 end
	end

	if ldx == 0 then
		player.dx *= player.stop_fric
 end
	if ldy == 0 then
		player.dy *= player.stop_fric
	end
	
	if dash then
		if ldx == 0 and ldy == 0 then
			ldx = player.last_inx
			ldy = player.last_iny
		end
		ldx *= player.dash_acc
		ldy *= player.dash_acc
		curshake = 0.1
		sfx(4)
	end

	ldx *= player.acc
	ldy *= player.acc

	if inx != 0 or iny != 0 then
		player.last_inx = inx
		player.last_iny = iny
	end
	
	if ldx != 0 and ldy != 0 then
		ldx *= sqrt_inv_2
		ldy *= sqrt_inv_2
	end
	
	player.dx += ldx
	player.dy += ldy
	
 local speedsq = player.dx * player.dx + player.dy * player.dy
 if speedsq > player.max_d * player.max_d then
 	local speed = sqrt(speedsq)
 	local news = speed * player.fast_fric
 	if news < player.max_d then
 		news = player.max_d
 	end
 	local ratio = news / speed
 	player.dx *= ratio
 	player.dy *= ratio
 end

 if abs(player.dx) < 0.05 then
 	player.dx = 0
 end
 if abs(player.dy) < 0.05 then
 	player.dy = 0
	end
 
 if not player.working then
	 player.x += player.dx
 	player.y += player.dy
 end
 
 local prevrun = player.running
 local prevwork = player.working
 player.running = player.dx != 0 or player.dy != 0
	player.working = false

 -- check interactions
 if btn(🅾️) and not prevbtno then
 	for i, s in ipairs(summoners) do
 		if in_range(s.x, s.y) then
 			if s.stackx >= 0 then
					do_interact(s)
				end
 		end
 		if s.stackx >= 0 then
 			if in_range(s.stackx * 8, s.stacky * 8) then
 				do_interact(s)
 			end
 		end
 	end
 	for i, a in ipairs(animables) do
 		if in_range(a.x, a.y) then
 			interact_cat(a)
 		end
 	end
 	if in_range(player.homex * 8, player.homey * 8)
 			or in_range(player.startx, player.starty)
 		then
 		drop_papers()
 	end
 elseif btn(🅾️) then
 	if in_range(player.startx, player.starty) then
 		if player.home_stack > 0 then
	 		player.working = true
 			player.running = false
	 		player.flipx = true
	 		player.x = player.startx
	 		player.y = player.starty
	 		player.work_prog += 1
	 			 		
	 		if work_progress() >= 1 then
					player.work_prog = 0
					player.home_stack -= 1
					player.completed_tasks += 1
				end
			end
 	end
 end
 
 if not player.working then
 	player.work_prog = 0
 else
 	player.dx = 0
 	player.dy = 0
 end
 
 if prevrun != player.running
		or prevwork != player.working
		or (not player.running and not player.working)
	then
		player.sfx_acc = 0
	end
 
  --check collision
 if player.dx>0 then

  if collide_map(player,"right", 0) then
   player.dx=0
   player.x=lx
  end
 end
     
 if player.dx<0 then
  if collide_map(player,"left",0) then
   player.dx=0
   player.x=lx  
  end
 end
 
 if player.dy<0 then
  if collide_map(player,"up",0) then
   player.dy=0
   player.y=ly
  end
 end
 
 if player.dy>0 then
  if collide_map(player,"down",0) then
   player.dy=0
   player.y=ly
  end
 end      

end

function collide_map(obj,aim,flag)
 local x1=0
 local y1=0
 local x2=0
 local y2=0

 local x=obj.x
 local y=obj.y
 local w=obj.w
 local h=obj.h

	if aim=="left" then
	 x1=x+1   y1=y+2
	 x2=x+2   y2=y+h-3
	elseif aim=="right" then
	 x1=x+w-2  y1=y+2
	 x2=x+w-1  y2=y+h-3
	elseif aim=="up" then
	 x1=x+5    y1=y-1
	 x2=x+w-5  y2=y
	elseif aim=="down" then
	 x1=x+3    y1=y+h-1
	 x2=x+w-4  y2=y+h+obj.dy/4
 end

 --pixel to tiles
 x1=x1/8  x2/=8  y1/=8  y2/=8

 local a= fget(mget(x1,y1), flag)
 local b= fget(mget(x1,y2), flag)
 local c= fget(mget(x2,y1), flag)
 local d= fget(mget(x2,y2), flag)

 if a or b or c or d then
  is_collide=true
  return true
 else
  is_collide=false
  return false
	end
end

function in_range(x, y)
	local distx = x - player.x
 local disty = y - player.y
 local distsq = distx * distx + disty * disty
 return distsq <= interact_distance_sq
end
function work_progress()
	return player.work_prog / work_duration
end

function update_sfx(obj)
	local delay = nil
	local id
	if obj.working then
		delay = obj.work_sfx_delay
		if mode == "game" then
			id = 6
		else
			id = 12
		end
--	elseif obj.running then
--		delay = obj.run_sfx_delay
--		id = 3
	elseif wasworking == true then
		sfx(-1, 3)
	end
	wasworking = obj.working
	if delay == nil then
		return
	end
	if obj.sfx_acc == 0 then
		sfx(id, 3)
	end
	obj.sfx_acc += 1
	if obj.sfx_acc > delay then
		obj.sfx_acc = 0
	end
end

function anim_player(obj)

	local frames = obj.idle_frames
	local delay = obj.anim_delay
	if obj.stackx >= 0 then
		delay = obj.anim_pat_delay
	end
 if obj.running then
 	frames = obj.run_frames
 	delay = obj.anim_run_delay
 	if obj.carrying > 0 then
	 	frames = obj.run_carry_frames
	 end
 elseif obj.dialog != nil then
 	frames = obj.dial_frames
 	delay = obj.anim_dial_delay
 elseif obj.working then
 	frames = obj.work_frames
 	delay = obj.anim_work_delay
 end
 if obj.dash_cd != nil then
 	if obj.dash_delay - obj.dash_cd < 4 then
 		frames = obj.dash_frames
 		delay = obj.anim_dash_delay
 	end
 end
 if obj.interacting then
 	frames = obj.dial_frames
 	delay = obj.anim_dial_delay
 end
 
	obj.anim_acc -= 1
 if obj.anim_acc <= 0 then --si anim_play atteint 0, reset compteur a rebour a anim_spd   
  obj.anim_acc = delay
  obj.anim_frame += 1
 end
 
 if obj.anim_frame > count(frames) then
	 if obj.interacting then
	 	obj.interacting = false
	 	frames = obj.idle_frames
	 end
  obj.anim_frame = 1
 end
 obj.sp = frames[obj.anim_frame]
end

function find_tile(n)
	for i = 0, 16 do
		for j = 0, 16 do
			if mget(i + cur_mapx, j + cur_mapy) == n then
				return i, j
			end
		end
	end
	return nil
end

function find_flags(f, ox, oy)
	if ox == nil then
		ox = cur_mapx
	end
	if oy == nil then
		oy = cur_mapy
	end
	local ret = {}
	for i = 0, 16 do
		for j = 0, 16 do
			local t = mget(ox + i, oy + j)
			if fget(t, f) then
				add(ret, {
					tx = i,
					ty = j,
					sp = t,
				})
			end
		end
	end
	return ret
end

function shuffle(arr)
	local len = count(arr)
	for i = 0, (len - 2) do
		local r = 1 + flr(rnd(len - i))
		local inter = arr[len - i]
		arr[len - i] = arr[r]
		arr[r] = inter
	end
end
function pick_rnd(arr)
	local i = 1 + flr(rnd(count(arr)))
	return arr[i]
end
-->8
-- update game

function update_game()
 update_player()
 update_summons()
 anim_player(player)
 update_sfx(player)
 for i, s in ipairs(summoners) do
 	anim_player(s)
 end
 for i, a in ipairs(animables) do
 	anim_player(a)
 end

 if debug and btnp(❎) and btnp(🅾️) then
 	mode = "end"
 	startend()
 end

 day_time += 1
 if day_time >= day_duration then
		mode = "end"
		startend()
	elseif day_time >= leave_dayratio * day_duration then
		
 end
 
  
end


function startgame()
	cur_mapx = 0
	cur_mapy = 0
	pal()
	music(1, 500, 7)
	reset_map()
	work_duration = 45
	
	local startx, starty = find_tile(32)
	startx *= 8
	starty *= 8
	local homex, homey = find_tile(96)

	day_time = 0
	day_count += 1
	
	angered_count = 0
	missed_count = 0
	petted_count = 0

	player = {
		sp = 1,
		x = startx,
		y = starty,
		startx = startx,
		starty = starty,
		homex = homex,
		homey = homey,
		h = 8,
		w = 8,
		dx = 0,
		dy = 0,
		last_inx = -1,
		last_iny = 0,
		acc = 0.8,
		dash_acc = 10,
		dash_delay = 30,
		dash_cd = 0,
		stop_fric = .1,
		fast_fric = 0.7,
		max_d = 1.5, -- can still go beyond with acc
		flipx = true,
		running = false,
		working = false,
		
		carrying = 0,
		home_stack = 0,
		work_prog = 0,
		completed_tasks = 0,
		
		anim_acc = 0,
	 anim_delay = 6,
	 anim_run_delay = 3,
	 anim_work_delay = 2,
	 anim_dash_delay = 1,
	 anim_frame = 0,
	 
	 idle_frames = {1, 2, 3},
	 run_frames = {4, 5, 6, 7},
	 run_carry_frames = {25, 26, 27, 28},
	 work_frames = {8, 9, 10},
	 dash_frames = {11},
	 
	 sfx_acc = 0,
--	 run_sfx_delay = 15,
	 work_sfx_delay = 15,
	 
	 -- other obj types values
	 stackx = -1,
	 stacky = -1,
	}
	
	summoners = find_flags(1, cur_mapx, cur_mapy)
	for i, s in ipairs(summoners) do
	 s.anim_delay = 40
	 s.anim_pat_delay = 20
		s.anim_acc = flr(rnd(s.anim_delay))
		s.anim_dial_delay = 2
	 s.anim_frame = ceil(rnd(2))
	 s.idle_frames = { s.sp, s.sp + 1 }
		s.dial_frames = { s.sp + 2, s.sp + 3}
	 s.flipx = false
	 s.stackx = -1
	 s.stacky = -1
	 s.inter_sp = 0
	 s.inter_acc = 0
	 s.x = s.tx * 8
	 s.y = s.ty * 8
	 s.dialog = nil
	 s.patience = 0
	 s.max_pat = 0
	 s.type = 0
		mset(cur_mapx + s.tx, cur_mapy + s.ty, 97)
	end
	
	fill_animables(cur_mapx + 16, cur_mapy)
	for i, a in ipairs(animables) do
		mset(cur_mapx + a.tx + 16, cur_mapy + a.ty, 97)
	end
	
	
	-- balancing
	brnt_per_miss = 10
	brnt_per_shout = 4
	brnt_per_overtime = 4
	day_end_brnt = -1 * brnt_per_overtime
	brnt_per_cat = -3

	local increases = day_count - 1
	diff_ratio = pow(0.8, increases)
	diff_var_ratio = pow(0.85, increases)
	
	summon_delay = 150 * diff_ratio
	summon_variable = 30 * diff_var_ratio
	next_summon = summon_variable * 2
	
	patience_shout = 270 * diff_ratio
	patience_miss = 370 * diff_ratio
	-- rnd added to previous vars
	patience_variable = 60 * diff_var_ratio
	
	if summon_variable < 10 then summon_variable = 10 end
	if patience_variable < 10 then patience_variable = 10 end
	if summon_delay < summon_variable then summon_delay = summon_variable end
	if patience_shout < patience_variable then patience_shout = patience_variable end
	if patience_miss < patience_variable then patience_miss = patience_variable end

end

function fill_animables(mapx, mapy)
	animables = find_flags(3, mapx, mapy)
	for i, a in ipairs(animables) do
		a.anim_delay = 40
		a.anim_acc = flr(rnd(a.anim_delay))
		a.anim_dial_delay = 6
		a.anim_frame = ceil(rnd(4))
		a.idle_frames = {
			a.sp,
			a.sp + 1,
			a.sp + 2,
			a.sp + 3,
		}
		a.dial_frames = {29, 30, 31}
		a.flipx = false
		a.stackx = -1
		a.stacky = -1
		a.x = a.tx * 8
		a.y = a.ty * 8
		a.dialog = nil
		a.interracting = false
		mset(mapx + a.tx, mapy + a.ty, 97)
	end
end

function get_summonable()
	for index, s in ipairs(summoners) do
		if s.stackx < 0 then
			for i = -1, 1 do
				for j = -1, 1 do
					if i == 0 and j == 0 then
					else
						local t = mget(s.tx + i, s.ty + j)
						local deco = mget(s.tx + i + 16, s.ty + j)
						if fget(t, 2) and deco <= 0 then
							local px = s.tx + i
							local py = s.ty + j
							return s, px, py
						end
					end
				end
			end
		end
	end
	return nil
end

function update_summons()
	for i, s in ipairs(summoners) do
		if s.stackx >= 0 then
			if s.patience > 0 then
				s.patience -= 1
			end
			if s.patience <= 0 then
				bump_summon(s)
			end
		end
	end

	next_summon -= 1
	if next_summon <= 0 then
		local var_sum = flr(rnd(summon_variable))
		next_summon = summon_delay + var_sum
		shuffle(summoners)
		local s, px, py = get_summonable()
		lastsummonable = s
		if s != nil then
			bump_summon(s, px, py)
			mset(cur_mapx + s.stackx + 16, cur_mapy + s.stacky, paper_sp)
			s.type = 1
		end
	end
end

function bump_summon(s, stackx, stacky)
	if stackx != nil then
		s.stackx = stackx
		s.stacky = stacky
	end
	s.anim_acc = 12

	local txtcol = 0
	local bgcol = 7
	local quotes = neutral_quotes
	
	if s.type == 0 then
	elseif s.type == 1 then
		txtcol = 1
		bgcol = 8
		burnout += brnt_per_shout
		quotes = negative_quotes
		curshake = 0.1
		angered_count += 1
	else
		txtcol = 8
		bgcol = 0
		burnout += brnt_per_miss
		quotes = miss_quotes
		curshake = 0.1
		missed_count += 1
	end
	
	s.dialog = {
		x = s.x,
		y = s.y - 14,
		txtcol = txtcol,
		bgcol = bgcol,
		txt = pick_rnd(quotes),
		dur = 45,
		curlen = 1,
		lapse = 0,
		csfx = s.type,
	}
	
	s.type = (s.type + 1) % 3
	
	local var_pat = flr(rnd(patience_variable))
	if s.type == 0 then
		s.patience = 0
		mset(cur_mapx + s.stackx + 16, cur_mapy + s.stacky, 0)
		s.stackx = -1
		s.stacky = -1
	elseif s.type == 1 then
		s.patience = patience_shout + var_pat
	else
		s.patience = patience_miss + var_pat
	end
	s.max_pat = s.patience
end

function do_interact(s)
	player.carrying += 1
	mset(cur_mapx + s.stackx + 16, cur_mapy + s.stacky, 0)
	s.stackx = -1
	s.stacky = -1
	s.dialog = nil
	s.patience = 0
	s.type = 0
	sfx(10)
--	s.anim_acc = 0
end

function interact_cat(a, ignore_sfx)
	a.interacting = true
	a.anim_acc = 0
	a.anim_frame = 1
	if ignore_sfx != true then
		sfx(5)
	end
	
	if mode == "game" then
		if petted_count < 1 then
			burnout += brnt_per_cat
		end
		petted_count += 1
	end
end

function drop_papers()
	if player.carrying <= 0 then
		return
	end
	player.home_stack += player.carrying
	player.carrying = 0
	sfx(11)
end

-->8
-- main menu

function update_start()

 t += 1
 blinkt = blinkt + 1

 if btnp(❎) or btnp(🅾️) then 
  startgame()  
  mode = "game"
 end
 
end

function startstart()
	reset_map()
--	if not debug then
		music(0)
--	end
end

function draw_start()

	pal(0, 133, 1)
	cls(0)
	rectfill(0,110,128,128,5)
	map(32,0)
	

	print("❎/x dash    🅾️/c interact",13,96,4)
	print("❎/x dash    🅾️/c interact",13,95,9)
	
	print("press ❎ or 🅾️",35,38,blink())
	print("ludum dare 55 by",32,112,13)
	print("speedphoenix & kiuun",25,120,13)
	print("ludum dare 55 by",32,111,6)
	print("speedphoenix & kiuun",25,119,6)
	




end

function blink()

 local blink_anim={5,5,6,6,7,7,6,6}
 
 if blinkt>#blink_anim then
  blinkt=1
 end

 return blink_anim[blinkt]
end

-->8
-- draw game

function draw_game()

	cls(13)
	map(cur_mapx, cur_mapy)
	map(cur_mapx + 16, cur_mapy)
	
	local t = day_time / day_duration
	draw_clock(0, 0, t, 4.5, 1, 2)
	draw_calendar(20, 0, day_count)
	draw_brnt(60, 4)

	for i, s in ipairs(summoners) do
		draw_entity(s)
	end
	
 for i, a in ipairs(animables) do
 	draw_entity(a)
 end

	draw_entity(player)
	
	for i, s in ipairs(summoners) do
		if s.dialog != nil then
			draw_dialog(s.dialog)
			local dur = s.dialog.dur
			if s.dialog.lapse > dur then
				s.dialog = nil
			end
		end
	end
end

function draw_brnt(x, y)
	spr(112, x, y)
	for i=1, 6 do
		spr(113, x + i * 8, y)
	end
	spr(114, x + 7 * 8, y)
	
	local ratio = burnout / max_brnt
	if ratio > 1 then
		ratio = 1
	end
	if ratio > 0 then
		local width = 8 * 8 - 6
		local rend = x + 2 + ratio * width
		rectfill(x + 2, y + 3, rend, y + 4, 8)
	end
end

function draw_clock(x, y, t, r, col, col2)
	if col2 != nil then
		for i=0, flr(t * 40) do
			draw_clock(x, y, i / 40, r, col2)
		end
	end
	x += 9.5
	y += 7.5
	local t = 0.25 - t
	local x2 = x + cos(t) * r
	local y2 = y + sin(t) * r
	line(x, y, x2, y2, col)
end

function draw_calendar(x, y, d, h)
	if h == nil then
		h = 16
		spr(101, x, y, 2, 2)
	else
		local sp = 101
		local ty = flr(sp / 16)
		local tx = sp % 16
		sspr(tx * 8, ty * 8 + 1, 16, 15,
				x, y, 16, h)
	end
	
	if h > 5 then
		local twidth = print(d, 0, -100)
		local tx = x + 9 - twidth / 2
		local ty = y + h / 2 - 2
		print(d, tx, ty)
	end
end

function draw_entity(obj)
	if obj.carrying != nil and obj.carrying > 0 then
		local offx = 6
		if obj.flipx then
			offx = -2
		end
		draw_paper(obj.x + offx, obj.y + 4, obj.carrying)
	end
	spr(obj.sp, obj.x, obj.y, 1, 1, obj.flipx)
	if obj.stackx >= 0 then
		local x = obj.stackx * 8
		local y = obj.stacky * 8
		spr(14 + obj.inter_sp, x, y)
	 obj.inter_acc += 1
	 if obj.inter_acc > 20 then
	 	obj.inter_sp = (obj.inter_sp + 1) % 2
	 	obj.inter_acc = 0
	 end
	
		local ratio = obj.patience / obj.max_pat
		local pix = ratio * 12
		spr(12, obj.x, obj.y - 4, 2, 1)
		col = 12
		if ratio < 0.3 then
			col = 8
		elseif ratio < 0.7 then
			col = 9
		end
		rectfill(obj.x + 2, obj.y - 3, obj.x + 2 + pix, obj.y - 3, col)
	end
	if obj.home_stack != nil then
		local stack = obj.home_stack
		if obj.working then
			stack -= 1
			local prog = work_progress()
			local idx = 1 + flr(prog * count(paper_load))
			local sp = paper_load[idx]
			spr(sp, obj.startx - 8, obj.starty)
		end
	 if stack > 0 then
			draw_paper(obj.homex * 8 + 2, obj.homey * 8 + 4, stack)
		end
	end
end

function draw_paper(x, y, h)
	rectfill(x,
			y - h + 1,
			x + 3,
			y,
			6
	)
	rectfill(x,
			y - h - 2,
			x + 3,
			y - h,
			7
	)
end

function draw_dialog(d)
	local len = #d.txt
	local twidth = print(d.txt, 0, -100)
	local theight = 5
	if d.bgcol != 7 then
		pal(6, d.bgcol)
	end
	pal(7, d.bgcol)

	local x = d.x
	if x + twidth + 12 > 128 then
		x = 128 - (twidth + 8)
	end
	
	rectfill(x + 3,
			d.y - 5,
			x + twidth,
			d.y + theight + 3,
			7
		)
	spr(48, x - 2, d.y - 5)
	spr(49, x + twidth, d.y - 5)
	spr(50, x - 2, d.y + theight - 4)
	spr(51, x + twidth, d.y + theight - 4)

	if d.curlen <	len then
		d.curlen += 1
		sfx(d.csfx)
	else
		d.lapse += 1
	end

	for i = 1, d.curlen do
		print(d.txt[i], x + i * 4, d.y, d.txtcol)
	end
 --	print(d.txt, x, d.y, d.txtcol)
	-- print(d.txt, 0, 0)
	pal(0)
end
-->8
-- end menu


function update_end()
	endf += 1
	
	local final_brnt = burnout
	final_brnt += player.home_stack * brnt_per_overtime
	
	if final_brnt >= max_brnt then
		game_over = true
	end
	
	-- add the animated ❎ btn
	if not added_btn
			and (
					(
							player.home_stack <= 0
							and ended_work_f > endmenu_pause
					)
				or
					(
						endf == 240
						and not game_over
					)
			) then
		added_btn = true
		add(animables, {
			sp = 71,
			x = 100,
			y = 100,
			anim_delay = 10,
			anim_acc = 0,
			anim_dial_delay = 2,
			anim_frame = ceil(rnd(4)),
			idle_frames = { 71, 72 },
			flipx = false,
			stackx = -1,
			stacky = -1,
			dialog = nil,
		})
	end
	
	if endf > 1 and btn(🅾️) and not prevbtno then
		interact_cat(end_cat)
	end

 if btn(❎) and not prevbtnx then
		if not game_over and endf > endmenu_pause then
			startgame()
 		mode = "game"
 	elseif player.home_stack <= 0
 			and ended_work_f > endmenu_pause
 		then
	 	_init()
 		mode = "start"
		end
 end
 
	if player.home_stack > 0 then
		player.work_prog += 1
		night_time += 1
		
		if work_progress() >= 1 then
			player.work_prog = 0
			player.home_stack -= 1
			burnout += brnt_per_overtime
			if player.home_stack <= 0 and game_over then
				sfx(13)
			end
		end
	else
		if endf > 1 and ended_work_f == 0 then
			interact_cat(end_cat, game_over)
		end
		ended_work_f += 1
	end
		
	anim_player(player)
	player.working = player.home_stack > 0
	update_sfx(player)

 for i, a in ipairs(animables) do
 	anim_player(a)
 end

end

function startend()
	reset_map()
	music(-1, 1000)
	
	game_over = false
	added_btn = false
	work_duration = 30
	ended_work_f = 0
	
	night_time = 0
	ovrt_per_clock = 3 * work_duration
	
	cur_mapx = 48
	cur_mapy = 0
	fill_animables(cur_mapx, cur_mapy)
	for i, a in ipairs(animables) do
 	end_cat = a
		mset(cur_mapx + a.tx, cur_mapy + a.ty, 97)
	end

	endf = 0
	
	local spread_cnt = 0
	for i, s in ipairs(summoners) do
		if s.stackx >= 0 then
			spread_cnt += 1
		end
	end

	local homex, homey = find_tile(96)
	local startx = (homex + 1) * 8
	local starty = (homey + 1) * 8
	
	player.sp = 41
	player.x = startx - 1
	player.y = starty
	player.startx = startx
	player.starty = starty
	player.homex = homex
	player.homey = homey
	player.flipx = false
	player.running = false
	player.working = true
	player.dash_cd = nil
	
	player.home_stack = player.home_stack + player.carrying + spread_cnt
	player.carrying = 0
	player.work_prog = 0

	player.anim_acc = 0
	player.anim_delay = 12
	player.anim_work_delay = 3
	player.anim_frame = 0

	player.idle_frames = {41, 42, 43}
	player.work_frames = {41, 42, 43}
	
	overtimed = player.home_stack
	
	burnout += day_end_brnt
end

-->8
-- draw end menu

function draw_end()
	pal(14, 133, 1)
	cls(0)
	rectfill(16,10,111,111,14)
	map(cur_mapx, cur_mapy)
	
	print("burnout",50,103,5)
	print("burnout",50,102,6)
	
	draw_brnt(32, 92)
	
	for i, a in ipairs(animables) do
 	draw_entity(a)
 end
	
	local t = night_time / ovrt_per_clock
	spr(106,20,13,2,2) --horloge	
	draw_clock(20, 13, t, 4.5, 1, 2)
	
	if game_over then
		draw_calendar(90, 12, day_count, 16)
	else
		draw_calendar(90, 12, day_count + 1, 16)
		local calh = 15 - ended_work_f
		if calh > 0 then
			draw_calendar(90, 13, day_count, calh)
		end
	end
	draw_entity(player)

	local overtimed = overtimed
	if overtimed > 0 then
		overtimed = "\f8"..overtimed
	end
	local angered_count = angered_count
	if angered_count > 0 then
		angered_count = "\f8"..angered_count
	end
	local missed_count = missed_count
	if missed_count > 0 then
		missed_count = "\f8"..missed_count
	end

	print("tasks done:  "..player.completed_tasks,22,31,6)
	print("overtime:    "..overtimed, 6)
	print("n+1 angered: "..angered_count, 6)
	print("n+1 enraged: "..missed_count, 6)
	print("cat petted:  "..petted_count, 6)

	if player.home_stack <= 0 and game_over then
		draw_gameover()
	end
end

function draw_gameover()
	rectfill(38, 60, 88, 80, 1)
	print("game over", 45, 65, 8)
end

__gfx__
0000000000099900000999000000000000099900000000000009990000000000000099900000000000000000000aaaa00d555555555555d00000000088000088
000000000009fc000009fc00000999000009fc00000999000009fc000009990000059f80000599900005999088899a7fd51111111111115d0800008080000008
00700700000fff00000fff000009fc00000fff000009fc00000fff000009fc000005fff000059f8000059f80000ffff00d555555555555d00800008000000000
000770000008480000084800000fff0000088400000fff0000448800000fff00000584800005fff00005ff4f004448f000000000000000000000000000000000
0007700000084f000008480000084800000884f00008480000f88800000848000001884f0001844f00018480f448880000000000000000000800008000000000
007007000008880000084f0000084f000008880000084f000008880000084f000001116600011166000111660008885000000000000000000880088080000008
00000000000605000008880000088800006605000006600000550600000560000000010600000106000001060660005000000000000000000000000088000088
00000000000605000006050000060500000005000000500000000600000060000000101000001010000010106000050000000000000000000000000000000000
00000000000099990000000000000000000099990555000000000000000000000555000000099900000000000009990000000000000000000000000001010000
0000000000009f30000099990000999900009f30014550000555000005550000014550000009fc00000999000009fc000009990000000000010100000b1b0000
000000000010fff000109f3000109f300010ffe00444010001455100014551000e440100000fff000009fc00000fff000009fc00010100000b1b000008110000
00000000001131300011fff00011fff0001131300313110004441100044411000313110000088400000fff0000088400000fff0001111d000811d00008110000
000000000001331f0001311f0001311f0001331f41331000411310004113100041331000000884f000088400000884f00008840001111d0001111d000111d000
00000000000111550001115500011155000111555511100055111000551110005511100000088800000884f000088800000884f00d1d11d00d1d11d00d1d1d00
00000000000001050000010500000105000001055010000050100000501000005010000000660500000660000055060000056000000000d0000000d0000000d0
00000000000010100000101000001010000010100101000001010000010100000101000000000500000050000000060000006000000000d0000000d0000000d0
00000000000000000000000000000000000000000044400000000000000000000044400000000000007000000000000000000000000000000000000000000000
0000500000000000000000000000000000088800004440000044400000444000004f10f009990050000070500000005001010000010100000101000001010000
000050000008880000000000000888000044480000fff00000444000004f100000ffe0300cff005099900050999000500b1b00000b1b0000011100000b1b0000
05551000004448000008880000444800000cfc00031113000011100000111000031113000ff88050cff88050cff880500111d0000111d0000111d0000111d000
05551000000cfc0000444800000cfc00000fef0f0011100003111300031113000011100000588810ff888810ff88881001111d0001111d0001111d0001111d00
01110000000fff00000cfc00000fff000003113000555000005550000055500000555000f55d1110f55d1110f55d11100d1d11d00d1d1d000d1d11d00d1d11d0
0010000000031300000fff0000031100000311000001000000010000000100000001000000d0100000d0100000d01000000000d000000d00000000d0000000d0
01010000000f1f00000f1f00000f11f0000f110000101000001010000010100000101000000101000001010000010100000000d00000d000000000d00000000d
00000666666000006777777777777776000111000000d00000000000000d00000000000000000000000000000000000000000000000000000000000000000000
00066777777660006777777777777776011155500000d0000dddddd0000d00000dddddd000000000007777000000000000000000000000000000000000000000
0067777777777600677777777777777605556650000dd0000d1111d0000dd0000dddddd000000000007777000777777007777770077777700777777007777770
06777777777777600677777777777760055555500005d0000d1111d0000d50000dd55dd000000000007777000777777007577770075677700756577007565570
06777777777777600677777777777760555555500055d0000dddddd0000d55000dd51dd000000000006666000777777007677770076577700765577007655670
67777777777777760067777777777600555555500055000000555500000055000055150000000000000000000777777007567770075677700756657007566570
67777777777777760006677777766000006006000000000000000000000000000000100000000000000000000777777007777770077777700777777007777770
67777777777777760000066666600000006006000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000
444444444444444401000000000000100000000000000000000000000011100000000000999999aa99999999aaaaaaaa66666666766666666666666666666667
4444444446644664010000000000001000000000d777000000d7777001666100001110009944444444444444444444aa77777777767777777777777777777767
4444444446444464000000000000000000000000dd666100001d66661656561001666100a4400000000000000000044a77000077766777777777777777777667
44444444444444440000000000000000000000005566601001dd6666166566101656561094000000000000000000004a77000077766677777777777777776667
4444444446444464000000000000000000000000dd66601010dd6666165656101665661094000000000000000000004977000077766667777777777777766667
4444444446644664000000000000000000000000d866601010dd66661d666d101656561094000000000000000000004977dddd77766666777777777777666667
44444444444444440000000000000000000000000d666011100d666601ddd1000166610094000000000000000000004977777777766666677777777776666667
44444444444444440000000000000000000000000000000000000000001110000011100094000000000000000000004955555555766666655555555556666667
444444444444444401000010000000000000000003b33b30000003b3001110000000000094000000000000000000004966666666766666657666666556666667
44444444466446640100001000000000000000003b33b3b300003333016661000011100094000000000000000000004977777777766666657766666556666667
44444444464444640000000000000000000b00003303b33303b33000165556100166610094000000000000000000004977777777766666657776666556666667
44444444444444440000000000000000000300000003b03303330000165656101655561094000000000000000000004977777777766666657777666556666667
44444444464444640000000000000000000500000093390000030000165556101656561094000000000000000000004977777777766666657777766556666667
444444444664466400000000000000000000000000999900009390001d666d101655561094400000000000000000004977777777766666657777776556666667
4444444444444444000000000000000000000000004444000099900001ddd1000166610099444444444444444444449944444444766666657777777556666667
55555555555555550000000000000000000000000044440000444000001110000011100099999999999999999999999944444444766666655555555556666667
444444440000000044444d6400000000000000000000000000000000940000000000004900000049000000000000000076000000766556655666666756655667
4aa44aa400000000444ddd6400000000000000000000a0000000a000940000000000004900000049000000066166000076660000766445655666666756544667
4a4444a40000000044fddd6400000006ddddf0ff0555955555559555940000000000004900000049000006777177760076666600766441555666666755144667
44444444000000004fffddd600000066dddd00000555555555555555940000000000004900000049000067777777776076666665766444455666666754444667
4a4444a4000000004aaaff5600000060ddd000000777777777777777999999aaaa999999000000490000777777777770766666dd766444445666666744444667
4aa44aa4000800004aaaa45500000060dd0f0000077777777777777799444444444444990000004900067777777777767666dddd766644445666666744446667
44444444000000004444444400000060f000f0000777777777777777a44000000000044a00000049000677777777777676dddddd766664445666666744466667
44444444000000005555555500000060f00000000777777777777777940000000000004900000049000117777177771176666666766666647777777746666667
09999999999999999999999000000060000000f00777777777777777000000000000000094000000000677777777777611111111766666650000000056666667
a4111111111111111111114a00000060f00000000777777777777777000000000000000094000000000677777777777611111111766666655555555556666667
9171177777777777777771d900000060000000000777777777777777000000000000000094000000000077777777777011111111766666dddddddddddd666667
9111111111111111111111190000006000000000077777777777777700000000000000009400000000006777777777601111111176666dddddddddddddd66667
911111111111111111111119000000600000000006666666666666669999999900000000940000000000067771777600111111117666dddddddddddddddd6667
91111111111111111111111900000d6d000000000000000000000000444444440000000094000000000000066166000011111111766dddddddddddddddddd667
94111111111111111111114901111ddd00000000000000000000000000000000000000009400000000000000000000001111111176dddddddddddddddddddd67
09999999999999999999999001000000000000000000000000000000000000000000000094000000000000000000000011111111766666666666666666666667
000000000000000000000000000000000076000044444444000000099aaa00000000000000000000000000000000000000000000000000000000000000000076
00000000000000000000000000000000007600004444444400000049444a00000000000000000000000000000000000000000000000000000000000000007776
0000000000000000000000000000000007d660004444444400000499004900000000000000000000000000000000000000000000000000000000000000777666
00000000000000000000000000000000076660005555555500000490004900000000000000000000000000000000000000007000000000000000000777766666
00000000000007000000700000000000776660005555555500000490004000000000a0000000a0000000000000000000000077000000aa000000007666666660
000000000000070000077000000000077666600050505050000004999aa00a000a00a0000004a00000000000000a000000000000000099a999007766ddddddd0
00000000000000000070000000000077d7766000050505050000044444a049009a49aaaaaa04aaaaaaa00aaa004aaaa0007700000aaa999a99007dddddddd770
000000000000000000000000000007777d776000005000500000000004949004944944a44a04944a44a09444a49444a000000009999999999006ddddddd77777
0000000000000000000000070000007777770000000000000000490004949004944944944a49904904949004949004a00000009999fffff00006666666777677
00000000000000000000007700000007777000000000000000004900499490049499499499490499499490049490090000000099ffff4ff4f006666666666777
0000000888800000000000000000000077000000000000000000490499049099949049049049049049049004949049000000099fff44ffff4006666666677777
0000008888888888800000000000000007000000000000000000494994049994049049049049049049049049049049000000999fff77cff7c000666666677777
0000088888882222220000000000000000000000000000000000499940044400049040049049040049044990049049000090999fff77cff7c000666666677777
00008888822222222200000000000000000000000000000000004440000000000400000400400000400044000400400000999f9fffffffffff00666666677777
0000888882fffff22000000000000000000000000000000000000000000000000000000000000000000000000000000000099f9fffffffffff00666666666777
00088888ffffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000099f9ffffff77eff00666666667777
0008884ffffffffff000000ffff00000dd777700400000000000000000000aaa0a0000000000a000009000000000000000099ffffffff88fff00666666677777
0002244f555ff555f00000fffff000777777dd704400000000000000000044904a00000000040000049a00000000000000000fffffffffffff00666666676777
0000f44f717ff717f00000fffff0066677dd77774400000000000000000004904aaa0aaa000090aaa4900aaa0aaa0aaa000000fffffffffff000666666667777
0000f44ffffffffff000000ffff06666777777770000000000000000000004904949494a00049494a490499a4940494a000000ffffffffff0000666666667777
0000fffffff77ffff00001ffff006666777777770000000000000000000004904949490000049494949049404900494900000000444440000000666666667777
000000fffffeefff00001ffff0006666660000000000000000000000000004904949499900049494949949994900494900000008888888888800666666667777
0000000ffffeeff0d111fffff00000000000000000000000000000000000040040404440000404040440444040004040000000088888888888fffff666667777
000001111fffff11d11fffff00000000000000000000000000000000000000000000000000000000000000000000000000000008888222888ffffff666667ff7
00001dd11111111dd11ffff10000077d777000000000000000007700000000005555555500000000000000000000000000000000882288888ffffff66666fff0
001111ddd1ddddd1d111ff00000077d77d7770000000000000077777770000005555555500000000000000000000000000000000882888888ffffff66666fff0
00ddd11111111111ddd1100000077d77d777d7700000000077777d777d7777775555555500000000000000000000000000000000088888888ffff8444fffff00
0111dd111111111d1110000000667777777d777700000000777d7777d777d7705555555500000000000000000000000000ff0000008888822888884444000000
0111d1fffdddddd1000000000666000777d77770000000007777777d7777d7705555555500000000000000000000000000000000002222228888884400000000
011d1ffffff1111100000000000000007777700000000000007777d7777d77705555555500000000000000000000000000000000000222288888888000000000
001d1ffffff11111000000000000000007770000000000000000777777d777005555555500000000000000000000000000f00000000222080808080000000000
44411fffff4444444444444444444444007000000000000000000077777770005555555500000000000000000000000000000000000080808080808000000000
00000007000000070000000000000000555555555550000009990000000000000000000009990000000000000000000000000000000000000000000000000000
55555575555550700000000000000000566667666650000003f90000099900000999000003f90000000000000000000000000000000000000000000000000000
4444444444455000000000000000000050007000065000000ff9910003f9010003f9010008f99100000000000000000000000000000000000000000000000000
4444444444455000000000000000000050070000065000000e2e11000ff991000ff991000e2e1100000000000000000000000000000000000000000000000000
444444444445500700000999907000005070000006500000f2ee1000f22e1000f22e1000f2ee1000000000000000000000000000000000000000000000000000
44444444444550000000999999c00000500000000750000055111000551110005511100055111000000000000000000000000000000000000000000000000000
444444444445500000009999ff900000500000007650000050100000501000005010000050100000000000000000000000000000000000000000000000000000
44444444444550000009f9ffff000000500700070650000001010000010100000101000001010000000000000000000000000000000000000000000000000000
44444444444550000000fffcfc000000507000700650000000000000000000000000000000000000000000000000000000000000000000000000000000000000
444444444445500000000fffff0000005700000006500000000000000000000000000000000005d0000000000000000000000000000000000000000000000000
444444444445500000000dfff00030005000000006500000000005d000000000000005d000055550000000000000000000000000000000000000000000000000
444444444445500770000ddd00003300500000000650000000055550000005d000055550050cfc00000000000000000000000000000000000000000000000000
444444444445500000008888800333305000000006500000050cfc0005055550005cfc00005fef0f000000000000000000000000000000000000000000000000
444444444545500000088888880333005000000006500000005fff00005cfc00050fff0000028820000000000000000000000000000000000000000000000000
4444444ddd4550000008855544444400500000000650000000028200000fff000002880000028800000000000000000000000000000000000000000000000000
444444444545500000888555444444f05555555555500000000f8f00000f8f00000f88f0000f8800000000000000000000000000000000000000000000000000
444444444545500000888555444444f0000000000000000000005550000000000000000000005550000000000000000000000000000000000000000000000000
44444444444550000088ff5544ff4400000000000000000000055410000055500000555000055410000000000000000000000000000000000000000000000000
44444444444550000002ff5544ff4400000000000000000000054440000554100005541000054480000000000000000000000000000000000000000000000000
44444444444550000000255544ff440000000000000000000055c1c000554440005544400051c1c0000000000000000000000000000000000000000000000000
4444444444455000000028888000000000000000000000000001cc140001c1140001c1140001cc14000000000000000000000000000000000000000000000000
44444444444550000000555550000000000000000000000000011155000111550001115500011155000000000000000000000000000000000000000000000000
44444444444550000000550550000000000000000000000000000105000001050000010500000105000000000000000000000000000000000000000000000000
44444444444550000000550550000000000000000000000000001010000010100000101000001010000000000000000000000000000000000000000000000000
44444444444550000000550550000000000000000000000000999900000000000000000009999000000000000000000000000000000000000000000000000000
444444444445500000005505500000000000000000000000004440000099990009999000004f30f0000000000000000000000000000000000000000000000000
44444444444550000000550550000000000000000000000000fff00000444000004f300000ff80e0000000000000000000000000000000000000000000000000
4444444444455000000055055000000000000000000000000e111e0000111000001110000e111e00000000000000000000000000000000000000000000000000
5555555555555ddddd0055055000000d0d000ddd00000000001110000e111e000e111e0000111000000000000000000000000000000000000000000000000000
00000000000000000000550550000000000000000000000000555000005550000055500000555000000000000000000000000000000000000000000000000000
00000000000000000000dd0dd0000000000000000000000000010000000100000001000000010000000000000000000000000000000000000000000000000000
00000000000000000000440444000000000000000000000000101000001010000010100000101000000000000000000000000000000000000000000000000000
__gff__
0000000000000000030303000000151500030303030303030300000000080808000303030303030303030303080000000000000000000000000000000000000001050000000101000001010111111111010500000001010000010101111111110101010000000001010100000101010100000000000000010001000001010101
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003030303000000000000000000000000030303030000000000000000000000000303030300000000000000000000000003030303000000000000
__map__
494a4a4a4a4a4a4a4a4a4a4a4a4a4a4b6a6b0000000000000000000000000010494a4a4a4a4a4a4a4a4a4a4a4a4a4a4b000000000000000000000000000000000000000000000000000000000000000000b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b800000000000000000000000000000000000000000000000000000000000000
595a5a5a5a5a5a5a5a5a5a5a5a5a5a5b7a7b000000000000000000000000001079000000868788898a8b0000000000690000494a4a4a4a4a4a4a4a4a4a4b00000000494a4a4a4a4a4a4a4a4a4a4b000000b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b800000000000000000000000000000000000000000000000000000000000000
4d4e5c5c4e4e4c4e4e4e4e4c4e5c4e4f1010101000001000101010100000101079000000969798999a9b000000000069000079000000000000000000006900000000790000000000000000000069000000b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b800000000000000000000000000000000000000000000000000000000000000
5d00505100405050410056000041005f10003600000000360000000000000010790000000000a7a8a9aaab0000000069000079000000000000000000006900000000790000000000000000000069000000b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b800000000000000000000000000000000000000000000000000000000000000
5d002500005000e6500000001150005f1000424300350000000000000037001079000000000000000000000000000069000079000000000000000000006900000000790000c0c1c2c300c4c50069000000b8b8b84d4e4c4e4e4e4e4c4e4fb8b8b800000000000000000000000000000000000000000000000000000000000000
6d00000000520000520000000052006f1000000000000000000000000000001079000000000000000000000083840069000079000000000000000000006900000000790000d0d1d2d300d4d50069000000b8b8b85d00000000000000006fb8b8b800000000000000000000000000000000000000000000000000000000000000
5d00004150504100000050500000005f1000000000360000000000360000001079808182838400000000000093940069000079000000000000000000006900000000790000e0e1e2e30000000069000000b8b8b86d00504000006000005fb8b8b80000000000362c000000000000000000000000000000000000000000000000
5d00114042f65000000042250060005f10000037000000000000004300000010799091929394838400b6b78c8d8e8f690000790000000000000000000069000000007900f4f0f1f2f3f400000069000000b8b8b85d00255000005020005fb8b8b800000000000054000000000000000000000000000000000000000000000000
5d00004000005200000000000040205f1000000000000000000000000000001079a0a1a2a3a493940000009c9d9e9f69000079000000636460000000006900000000790000000000000000000069000000b8b8b85d00005200005200005fb8b8b800000000000000000000000000000000000000000000000000000000000000
6d000040150000004d4e4e4e4e4e4e4f1000000035000000000000000000001079b0b1b2b3b40000000000acadaeaf69000079000000737450000000006900000000790000000000000000000069000000b8b8b85d00000000410000005fb8b8b800000000000000000000000000000000000000000000000000000000000000
5d000051000041005d40c6000000215f100000000000000000350000000000107985858585a50000b6b700bcbdbebf69000079000000000052002c00006900000000790000000000000000000069000000b8b8b85d00000011500000005fb8b8b800000000000000003700000000000000000000000000000000000000000000
5d000052001150005d5150500051505f10000000000000000000002c0000381079000000000000000000000000000069000079000000000000000000006900000000790000000000000000000069000000b8b8b85d56000000520000005fb8b8b800000000000000004500000000000000000000000000000000000000000000
5d00e640000000005d4243430042435f1000003700000000000000000000001079000000000000000000000000000069000079000000000000000000006900000000790000000000000000000069000000b8b8b87d7e7e7e7e7e7e7e7e7fb8b8b800000000000000000000000000000000000000000000000000000000000000
5d000051505000005e0000000000d65f10000000003800000000000000000010677777777777777777777777777777680000595a5a5a5a5a5a5a5a5a5a5b00000000595a5a5a5a5a5a5a5a5a5a5b000000b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b800000000000000000000000000000000000000000000000000000000000000
5d55004242430000000000560051505f1000000000000000000000000000381079000000000000000000000000000069000000000000000000000000000000000000000000000000000000000000000000b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b800000000000000000000000000000000000000000000000000000000000000
7d7e7e7e7e7e7e7e7e7e7e7e7e7e7e7f10101010101010101010101010424310595a5a5a5a5a5a5a5a5a5a5a5a5a5a5b000000000000000000000000000000000000000000000000000000000000000000b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b800000000000000000000000000000000000000000000000000000000000000
__sfx__
960100001402011020110200000000000000000000000000000000000000000000000000000000000001f70000000000000000000000000000000000000000000000000000000000000000000000000000000000
480100000fa300fa3014a301aa4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
560100001f940229402a9402094020940070000300000000000000000000000000000000002000060000c00017000000000000000000000000000000000000000000000000000000000000000000000000000000
91020000117100d71000700006000c0001300011000100000c0001300011000046000160001600110000c710117101070011000100000c0000d700107001370008600076000c0000c0000c000130001100010000
4c0200000c620176402967037640296301e620146200e6100b6100861007610076100160000600006000060002600026000260002600046000560004600026000060000600026000260002600026000260003600
940600002e1002f1002e1001d110281312e1312c1112b1112a1122b1122a1122b1122b1122a1002b1002b1000c100000000000000000000000000000000000000000000000000000000000000000000000000000
a60400200c6700d6700e6700f6700f6700f6700f6700d6700c6700c6700c6700c6700c6700d6700e6700f67010670106701167011670106700f6700d6700c6700d6700e670106701067010670116701267012670
9203001f3c620000000000000000000002a6000000000000000000000000000000000000000000000000000036620000001460000000000000000000000000000000000000000000000000000000000000000000
960300143c62000000000003a6003a6003a62000000000003c600000003c6203a6003a60000000000003a6203c600000003a6003a6003a600000003a600000003c600000003a6003a6003a600000000000000000
3505000024262242613026230200242002a5002426224261302622250026500195002426224261302621850018500005000050000500015002e5002e50030500325003650028500295002b5002e5003050035500
900200000361105611096210e6211d6212b6100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
911000003061518615000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
910c002011f251d6000000011f2013f20000003260013f2535600000002b6000000014f2511f2010f05000000ef052860014f2500000000000000013f25000000000012f2515f2000000000000000015f5539600
c101000022650216501f6501d6501965015650126500f6500c6500065000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
051200001f020180001f0201d0201f0202102018000220222202222025220202102022020210201f0201d0201f020180001f0251f0251d02521025210001f0201f0221f0221f0221f0221f021180001800018000
051200000707507075070750707507075070750000005075000000507505075050750507505075000000000007075000000707507075050750507500000070750707507075070750707507071000000000000000
491200000c0530c05310655000000c0530c05310655040000c0530c05310655000000c0530c05310655000000c0530c05310655000000c0530c05310655000000000010625106351064510655000000000000000
001200002211000100221102111022110241100010026112261122611526110241102611024110221102111022110181002211522115211152411521100221102211222112221122211222111181001810018100
91090008106250c000106000c000106150c0001061500000106000c000000000c0000c0000c0000c000000000c0000c0000000000000000000000000000000000c0000c000000000000000000000000000000000
01120000070750000000000070750707500000070750000000000000000000005075050750000000000000000707500000000000707507075000000707500000000000a0750a0000507505075000000000000000
01120000070750000000000070750707500000070750000000000000000000005075050750000000000000000f07500000000000f0750f075000000f0750000000000110750a0001107511075000000000000000
7f1200001f0151f000260151f0002b0151f0001f0151f000260151f0002b0151f0001a0151d0001d0151f0001f0151f000260151f0002b0151f0001f0151f000260151f0002b0151f0002d0151d0002e01526000
1112000013010130001300013010110100c0001301013012130121301213012000000000000000000000000013010130001300013010160100c00011010110121101011010110100000000000000000000000000
91120000106250c0001061510615106250c0001061510615106250c0001061510615106250c0001061510615106550c0530c05310655000000c053106550c05310600106550c0530c053106550c053106550c053
1512000013010130001300013010110100c000130101301213012130121301200000000000000000000000001b010180101b0101d0100c0001b0101d0101f010110001d0101f0102201027010260102401022010
491200000c0230c02310635000000c0230c02310635000000c0230c023106350c0230c0000c02310635000000c0230c02310635000000c0230c02310635000000c0230c023106350c023106250c0231063500000
a512000007135071350713507135071350713507135071350713507135071350713507135111351110013135071000713507135071350713507135131301513016132161311513513135111350e1351513513135
a51200001310007130071350713507135071350713507135071350713507135071350713511135111000f1300f13511135131351113211135131351513516132161350e135111320e13016130151301313011130
911200001f2111f2121f2121f2121f2121f21213211132001320013200132001f2111f2121d2101d2151f2101f2121f2121f2121f2151320013200222102421026211262122421022210212101d2102421022210
911200002221222212222122221222215222002220013200132001320013200222002220021215212001f2101f215212152221521212212152221526215292122921521215222122121026210242102221021210
01120000132501f2111f2121f21200000000001f21021210222122121000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
04 14171516
01 18194344
00 181a4344
00 18191c44
00 1d1a1e44
00 1f202244
00 1f212344
00 1f151b44
02 16151b44
00 1f155b44
00 1f155b44
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
01 181c4344
00 181c4344
00 181b1c44
02 181b1c44

