pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
function _init()
 blinkt=0
 t=0
	mode = "start"
	sqrt_inv_2 = 1 / sqrt(2)
	
	startx, starty = find_tile(32)
	startx *= 8
	starty *= 8
	homex, homey = find_tile(96)
	
	paper_sp = 58
	interact_distance_sq = 9 * 9
	
	patience_duration = 150
	
	work_duration = 90
	prevbtno = false
	prevbtnx = false
	
	paper_load = {59, 60, 61, 62, 63}

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
		acc = 0.8,
		stop_fric = .1,
		fast_fric = 0.7,
		max_d = 1.5, -- can still go beyond with acc
		flipx = true,
		running = false,
		working = false,
		
		carrying = 0,
		home_stack = 2,
		work_prog = 0,
		score = 0,
		
		anim_acc = 0,
	 anim_delay = 6,
	 anim_run_delay = 3,
	 anim_work_delay = 2,
	 anim_frame = 0,
	 
	 idle_frames = {1, 2, 3},
	 run_frames = {4, 5, 6, 7},
	 work_frames = {8, 9, 10},
	 
	 -- other obj types values
	 stackx = -1,
	 stacky = -1,
	}
	
	neutral_quotes = {
		"...",
		"come here",
		"intern, please",
	}
	negative_quotes = {
		"faster, boy",
		"will it be today?",
		"hurry up!",
		"stop taking breaks",
		"slouching again?",
	}

	summoners = find_flags(1)
	for i, s in ipairs(summoners) do
	 s.anim_delay = 40
	 s.anim_pat_delay = 20
		s.anim_acc = flr(rnd(s.anim_delay))
		s.anim_dial_delay = 2
	 s.anim_frame = flr(rnd(2))
	 s.idle_frames = { s.sp, s.sp + 1 }
		s.dial_frames = { s.sp + 2, s.sp + 3}
	 s.flipx = false
	 s.stackx = -1
	 s.stacky = -1
	 s.x = s.tx * 8
	 s.y = s.ty * 8
	 s.dialog = nil
	 s.patience = 0
	 s.csfx = flr(rnd(3))
		mset(s.tx, s.ty, 97)
	end
end



function _update()

	if mode =="game" then update_game()
	elseif mode == "start" then update_start()
	elseif mode == "end" then update_end() end
	prevbtno = btn(🅾️)
	prevbtnx = btn(❎)
end



function _draw()

	if mode =="game" then draw_game()
	elseif mode == "start" then draw_start()
	elseif mode == "end" then draw_end() end

	print(player.running, 0, 0, 0)
	print(player.working)
	
	local speedsq = player.dx * player.dx + player.dy * player.dy
	local speed = sqrt(speedsq)
	print("" .. flr(player.x) .. " " .. flr(player.y) .. " " .. speed)
	print(player.home_stack)

	
--	for index, s in ipairs(summoners) do
--	
--		print("".. index .. " " .. s.stackx .. " " .. s.stacky)
--	end
--	if lastsummonable != nil then
--		print(lastsummonable.stackx)
--	else
--		print(nil)
--	end
--	print(last_t)
end


-->8
--  custom function

function update_player()
	ldx = 0
	ldy = 0
	
	local lx=player.x
	local ly=player.y

	if btn(⬅️) then ldx -= 1 player.flipx = true end
	if btn(➡️) then ldx += 1 player.flipx = false end
	if btn(⬆️) then ldy -= 1 end
	if btn(⬇️) then ldy += 1 end 		

	if ldx == 0 then
		player.dx *= player.stop_fric
 end
	if ldy == 0 then
		player.dy *= player.stop_fric
	end
	
	if ldx != 0 and ldy != 0 then
		ldx *= sqrt_inv_2
		ldy *= sqrt_inv_2
	end
	
	
	player.dx += ldx * player.acc
	player.dy += ldy * player.acc
		 
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

-- if abs(player.dx) > player.max_d then
-- 	if player.dx > 0 then
--  	player.dx = player.max_d
--  else
--   player.dx = player.max_d * -1
-- 	end
-- end
-- 
-- if abs(player.dy) > player.max_d then
-- 	if player.dy > 0 then
--  	player.dy = player.max_d
--  else
--   player.dy = player.max_d*-1
-- 	end
-- end

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
 	if in_range(player.homex * 8, player.homey * 8) then
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
					player.score += 1
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


function anim_player(obj)

	local frames = obj.idle_frames
	local delay = obj.anim_delay
	if obj.stackx >= 0 then
		delay = obj.anim_pat_delay
	end
 if obj.running then
 	frames = obj.run_frames
 	delay = obj.anim_run_delay
 elseif obj.dialog != nil then
 	frames = obj.dial_frames
 	delay = obj.anim_dial_delay
 elseif obj.working then
 	frames = obj.work_frames
 	delay = obj.anim_work_delay
 end
 
	obj.anim_acc -= 1
 if obj.anim_acc <= 0 then --si anim_play atteint 0, reset compteur a rebour a anim_spd   
  obj.anim_acc = delay
  obj.anim_frame += 1
 end
 
 if obj.anim_frame > count(frames) then
  obj.anim_frame = 1
 end
 obj.sp = frames[obj.anim_frame]
end

function find_tile(n)
	for i = 0, 16 do
		for j = 0, 16 do
			if mget(i, j) == n then
				return i, j
			end
		end
	end
	return nil
end

function find_flags(f)
	local ret = {}
	for i = 0, 16 do
		for j = 0, 16 do
			local t = mget(i, j)
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
-- update main menu

function update_start()

 
 t+=1
 blinkt=blinkt+1

 if btnp(❎) or btnp(🅾️) then 
  startgame()  
  mode="game"
 end
 
end
-->8
-- update game

function update_game()
 if btnp(❎) and btnp(🅾️)
 then mode="end" end
 
 update_player()
 update_summons()
 anim_player(player)
 for i, s in ipairs(summoners) do
 	anim_player(s)
 end
 
end


function startgame()
	pal(1)

	player.x = startx
	player.y = starty
	player.score = 0
	
	summon_delay = 150
	next_summon = summon_delay
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
			s.summon_time += 1
			if s.patience > 0 then
				s.patience -= 1
			end
		end
	end

	next_summon -= 1
	if next_summon <= 0 then
		next_summon = summon_delay
		shuffle(summoners)
		local s, px, py = get_summonable()
		lastsummonable = s
		if s != nil then
			do_summon(s, px, py)
			mset(s.stackx + 16, s.stacky, paper_sp)
		end
	end
end

function do_summon(s, stackx, stacky)
	s.stackx = stackx
	s.stacky = stacky
	s.summon_time = 0
	s.dialog = {
		x = s.x,
		y = s.y - 16,
		txtcol = 0,
		bgcol = 7,
		txt = pick_rnd(neutral_quotes),
		dur = 45,
		curlen = 1,
		lapse = 0,
		csfx = s.csfx,
	}
	s.patience = patience_duration
end

function do_interact(s)
	player.carrying += 1
	mset(s.stackx + 16, s.stacky, 0)
	s.stackx = -1
	s.stacky = -1
	s.dialog = nil
	s.patience = 0
	s.anim_acc = 0
end

function drop_papers()
	player.home_stack += player.carrying
	player.carrying = 0
end

-->8
-- update end menu

function update_end()

 if btnp(❎) or btnp(🅾️)
 then mode="start" end
 
end
-->8
-- draw main menu

function draw_start()

	pal(0, 133, 1)
	cls(0)
	map(32,0)
	print("press ❎ or 🅾️",60,64,blink())
	print("credits",48,112,13)
	print("speedphoenix & kiuun",25,120,13)
		print("credits",48,111,6)
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
	map(0,0)
	map(16,0)
	
	for i, s in ipairs(summoners) do
		draw_entity(s)
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

function draw_entity(obj)
	if obj.sp == 0 then
		print("why", 0, 10)
	end
	spr(obj.sp, obj.x, obj.y, 1, 1, obj.flipx)
	if obj.carrying != nil and obj.carrying > 0 then
		local offx = 6
		if obj.flipx then
			offx = -2
		end
		draw_paper(obj.x + offx, obj.y + 4, obj.carrying)
	end
	if obj.stackx >= 0 then
		local ratio = obj.patience / patience_duration
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
	pal(7, d.bgcol)
	
	
	rectfill(d.x + 3,
			d.y - 5,
			d.x + twidth,
			d.y + theight + 3,
			7
		)
	spr(48, d.x - 2, d.y - 5)
	spr(49, d.x + twidth, d.y - 5)
	spr(50, d.x - 2, d.y + theight - 4)
	spr(51, d.x + twidth, d.y + theight - 4)

	if d.curlen <	len then
		d.curlen += 1
		sfx(d.csfx)
	else
		d.lapse += 1
	end

	for i = 1, d.curlen do
		print(d.txt[i], d.x + i * 4, d.y, d.txtcol)
	end
 --	print(d.txt, d.x, d.y, d.txtcol)
	-- print(d.txt, 0, 0)
	pal(0)
end
-->8
-- draw end menu

function draw_end()
	cls(8)

end
__gfx__
0000000000099900000999000000000000099900000000000009990000000000000099900000000000000000000aaaa00d555555555555d00000000000000000
000000000009fc000009fc00000999000009fc00000999000009fc000009990000009fc000009990000099900000cc7fd51111111111115d0000000000000000
00700700000fff00000fff000009fc00000fff000009fc00000fff000009fc000010fff000109fc000009fc0000ffff00d555555555555d00000000000000000
000770000004880000048800000fff0000088400000fff0000448800000fff00001184800011fff00011ff4f004448f000000000000000000000000000000000
000770000004f8000004880000048800000884f00008480000f88800000848000001884f0001844f00018480f448880000000000000000000000000000000000
00700700000888000004f8000004f8000008880000084f000008880000084f000001116600011166000111660008885000000000000000000000000000000000
00000000000605000008880000088800006605000006600000550600000560000000010600000106000001060660005000000000000000000000000000000000
00000000000605000006050000060500000005000000500000000600000060000000101000001010000010106000050000000000000000000000000000000000
00000000000099900000000000000000000099900555000000000000000000000555000000000000000000000000000009090000090900000909000009090000
000000000000ff3000009990000099900000ff300145500005550000055500000145500000000000000000000000000009990000099900000999000009990000
000000000010fff00010ff300010ff300010ffe00444010001455100014551000e44010000000000000000000000000005990000059900000599000005990000
00000000001131300011fff00011fff0001131300313110004441100044411000313110000000000000000000000000009995000099950000999500009995000
000000000001331f0001311f0001311f0001331f4133100041131000411310004133100000000000000000000000000009999500099995000999950009999500
0000000000011155000111550001115500011155551110005511100055111000551110000000000000000000000000000f9f99500f9f95000f9f99500f9f9950
00000000000001050000010500000105000001055010000050100000501000005010000000000000000000000000000000000050000005000000005000000050
00000000000010100000101000001010000010100101000001010000010100000101000000000000000000000000000000000050000050000000005000000005
00005000000000000000000000000000000000000044400000000000000000000044400000000000000000000000000000000000880000880000000000000000
0000500000000000000000000000000000088800004440000044400000444000004f10f000000000000000000000000008800880800000080000000000000000
000050000008880000000000000888000044480000fff00000444000004f100000ffe03000000000000000000000000008000080000000000000000000000000
05551000004448000008880000444800000cfc000311130000111000001110000311130000000000000000000000000000000000000000000000000000000000
05551000000cfc0000444800000cfc00000fef0f0011100003111300031113000011100000000000000000000000000008000080000000000000000000000000
01110000000fff00000cfc00000fff00000311300055500000555000005550000055500000000000000000000000000008800880800000080000000000000000
0010000000031300000fff0000031100000311000001000000010000000100000001000000000000000000000000000000000000880000880000000000000000
01010000000f1f00000f1f00000f11f0000f11000010100000101000001010000010100000000000000000000000000000000000000000000000000000000000
00000666666000006777777777777776000111000000d00000000000000d00000000000000000000000000000000000000000000000000000000000000000000
00066777777660006777777777777776011155500000d0000dddddd0000d00000dddddd000000000007777000000000000000000000000000000000000000000
0067777777777600677777777777777605556650000dd0000d1111d0000dd0000dddddd000000000007777000777777007677770076577700765677007656570
06777777777777600677777777777760055555500005d0000d1111d0000d50000dd55dd000000000007777000777777007577770075677700756577007565570
06777777777777600677777777777760555555500055d0000dddddd0000d55000dd51dd000000000006666000777777007677770076577700765577007655670
67777777777777760067777777777600555555500055000000555500000055000055150000000000000000000777777007567770075677700756657007566570
67777777777777760006677777766000006006000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000
67777777777777760000066666600000006006000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000
444444444444444401000000000000100000000000000000000000000000000000000000999999aa99999999aaaaaaaa66666666766666666666666666666667
4444444446644664010000000000001000000000667770000066777700000000000000009944444444444444444444aa77777777767777777777777777777767
444444444644446400000000000000000000000055777100001677770000000000000000a4400000000000000000044a77cccc77766777777777777777777667
44444444444444440000000000000000000000006677701001667777000000000000000094000000000000000000004a77cccc77766677777777777777776667
44444444464444640000000000000000000000006677701010667777000000000000000094000000000000000000004977cccc77766667777777777777766667
44444444466446640000000000000000000000006877701010667777000000000000000094000000000000000000004977dddd77766666777777777777666667
44444444444444440000000000000000000000006677701110667777000000000000000094000000000000000000004977777777766666677777777776666667
44444444444444440000000000000000000000000000000000000000000000000000000094000000000000000000004955555555766666655555555556666667
444444444444444401000010000000000000000003b33b30000003b3000000000000000094000000000000000000004966666666766666657666666556666667
44444444466446640100001000000000000000003b33b3b300003333000000000000000094000000000000000000004977777777766666657766666556666667
44444444464444640000000000000000000000003303b33303b33000000b00000000000094000000000000000000004977777777766666657776666556666667
44444444444444440000000000000000000000000003b03303330000000300000000000094000000000000000000004977777777766666657777666556666667
44444444464444640000000000000000000000000093390000030000000500000000000094000000000000000000004977777777766666657777766556666667
44444444466446640000000000000000000000000099990000939000000000000000000094400000000000000000004977777777766666657777776556666667
44444444444444440000000000000000000000000044440000999000000000000000000099444444444444444444449944444444766666657777777556666667
55555555555555550000000000000000000000000044440000444000000000000000000099999999999999999999999944444444766666655555555556666667
44444444000000000000000000000000000000000000000000000000000000000000000000000049000000000000000076000000766556655666666756655667
4aa44aa4000000000000000000000000000000000000000000000000000000000000000000000049000000066166000076660000766445655666666756544667
4a4444a4000000000000000000000000000000000000000000000000000000000000000000000049000006777177760076666600766441555666666755144667
44444444000000000000000000000000000000000000000000000000000000000000000000000049000067777777776076666665766444455666666754444667
4a4444a40000000000000000000000000000000000000000000000000000000000000000000000490000777777777770766666dd766444445666666744444667
4aa44aa400080000000000000000000000000000000000000000000000000000000000000000004900067777777777767666dddd766644445666666744446667
44444444000000000000000000000000000000000000000000000000000000000000000000000049000677777777777676dddddd766664445666666744466667
44444444000000000000000000000000000000000000000000000000000000000000000000000049000117777177771176666666766666647777777746666667
00000000000000000000000000000000000000000000000000000000000000000000000094000000000677777777777611111111766666650000000056666667
00000000000000000000000000000000000000000000000000000000000000000000000094000000000677777777777611111111766666655555555556666667
00000000000000000000000000000000000000000000000000000000000000000000000094000000000077777777777011111111766666dddddddddddd666667
0000000000000000000000000000000000000000000000000000000000000000000000009400000000006777777777601111111176666dddddddddddddd66667
000000000000000000000000000000000000000000000000000000000000000000000000940000000000067771777600111111117666dddddddddddddddd6667
00000000000000000000000000000000000000000000000000000000000000000000000094000000000000066166000011111111766dddddddddddddddddd667
0000000000000000000000000000000000000000000000000000000000000000000000009400000000000000000000001111111176dddddddddddddddddddd67
00000000000000000000000000000000000000000000000000000000000000000000000094000000000000000000000011111111766666666666666666666667
00000000000000000000000000000000007600004444444400000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000007600004444444400000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000007d6600044444444000000099aaa00000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000076660005555555500000049444a00000000000000000000000000000000000000000000000000000000000000000000
00000000000007000000700000000000776660005555555500000499004900000000000000000000000000000000000000000000000000000000000000000000
00000000000007000007700000000007766660005050505000000490004900000000000000000000000000000000000000000000000000000000000000000000
00000000000000000070000000000077d77660000505050500000490004000000000a0000000a000000000000000000000000000000000000000000000000000
000000000000000000000000000007777d77600000500050000004999aa00a000a00a0000004a00000000000000a000000000000000000000000000000000000
0000000000000000000000070000007777770000000000000000044444a049009a49aaaaaa04aaaaaaa00aaa004aaaa000000000000000000000000000000000
0000000000000000000000770000000777700000000000000000000004949004944944a44a04944a44a09444a49444a000000000000000000000000000000000
0000000888800000000000000000000077000000000000000000490004949004944944944a49904904949004949004a000000000000000000000000000000000
00000088888888888000000000000000070000000000000000004900499490049499499499490499499490049490090000000000000000000000000000000000
00000888888822222200000000000000000000000000000000004904990490999490490490490490490490049490490000000000000000000000000000000000
00008888822222222200000000000000000000000000000000004949940499940490490490490490490490490490490000000000000000000000000000000000
0000888882fffff22000000000000000000000000000000000004999400444000490400490490400490449900490490000000000000000000000000000000000
00088888ffffffff0000000000000000000000000000000000004440000000000400000400400000400044000400400000000000000000000000000000000000
0008884ffffffffff000000ffff00000dd77770040000000000aaa0a0000000000a0000090000000000000000000000000000000000000000000000000000000
0002244f555ff555f00000fffff000777777dd70440000000044904a00000000040000049a000000000000000000000000000000000000000000000000000000
0000f44f717ff717f00000fffff0066677dd7777440000000004904aaa0aaa000090aaa4900aaa0aaa0aaa000000000000000000000000000000000000000000
0000f44ffffffffff000000ffff0666677777777000000000004904949494a00049494a490499a4940494a000000000000000000000000000000000000000000
0000fffffff77ffff00001ffff006666777777770000000000049049494900000494949490494049004949000000000000000000000000000000000000000000
000000fffffeefff00001ffff0006666660000000000000000049049494999000494949499499949004949000000000000000000000000000000000000000000
0000000ffffeeff0d111fffff0000000000000000000000000040040404440000404040440444040004040000000000000000000000000000000000000000000
000001111fffff11d11fffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001dd11111111dd11ffff10000077d777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001111ddd1ddddd1d111ff00000077d77d7770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ddd11111111111ddd1100000077d77d777d7700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0111dd111111111d1110000000667777777d77770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0111d1fffdddddd1000000000666000777d777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011d1ffffff111110000000000000000777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001d1ffffff111110000000000000000077700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44411fffff4444444444444444444444007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000030303000000000000030303030303030300000000000000000303030303030303000000151510100000000000000000000000000000000001050000000101000001010111111111010500000001010000010101111111110101000000000000000100000101010100000000000000000001000001010101
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
494a4a4a4a4a4a4a4a4a4a4a4a4a4a4b6a6b0000000000000000000000000010494a4a4a4a4a4a4a4a4a4a4a4a4a4a4b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
595a5a5a5a5a5a5a5a5a5a5a5a5a5a5b7a7b0000000000000000000000000010790000000000000000000000000000690000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4d4e5c5c4e4e4c4e4e4e4e4c4e5c4e4f10101010000010001010101000001010790000000000000000000000000000690000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5d00505100405050410056000041005f10003600000000360000000000000010790000008687888900000000000000690000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5d00250000500011500000001150005f1000424300350000000000000037001079000000969798999a9b0000000000690000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6d00000000520000520000000052006f10000000000000000000000000000010790000000000a6a7a8a9aa00000000690000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5d00004150504100000050500000005f10000000003600000000003600000010790000000000000000000000000000690000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5d00114042255000000042250060005f10000037000000000000004300000010790000000000000000000000000000690000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5d00004000005200000000000040205f10000000000000000000000000000010790000000000000000000000000000690000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6d000040150000004d4e4e4e4e4e4e4f10000000350000000000000000000010798081828384000000000000000000690000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5d000051000041005d4015000000215f10000000000000000035000000000010799091929394838400000000000000690000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5d000052001150005d5150500051505f10000000000000000000001c0000381079a0a1a2a3a4939400000000000000690000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5d001140000000005d4243430042435f1000003700000000000000000000001079b0b1b2b3b4000000000000000000690000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5d000051505000005e0000000000215f100000000038000000000000000000107985858585a5000000000000000000690000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5d55004242430000000000560051505f1000000000000000000000000000381079b600000000000000000000000000690000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7d7e7e7e7e7e7e7e7e7e7e7e7e7e7e7f10101010101010101010101010424310595a5a5a5a5a5a5a5a5a5a5a5a5a5a5b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000b55009530065200000000000000000000000000000000000000000000000000000000000001f70000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000050200d030150500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000204001020000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000117100d71000700006000c0001300011000100000c0001300011000046000160001600110000c710117101070011000100000c0000d700107001370008600076000c0000c0000c000130001100010000
