local frame=0
local player
local particles={}
local colliders={}
local pushblocks={{},{},{},{},{}}
local emitters={}
local receivers={}
local redirectors={}
local beams={}
local spikes={}
local signs={}
local reading=0
local boss=nil
local bullets={}
local restart_timer=0
local gameover=false
local finish_time=""
local promises={frame={},condition={}}
local dirs={
	{0,1},
	{1,0},
	{0,-1},
	{-1,0}
}
local level={
	x=0,
	y=0
}

function _init()
	load_level(0,0)
	new_promise(function()
		return btnp(❎)
	end,function()
		-- controls screen
		rectfill(0,0,128,128,0)
		print("use arrows\n  to move",5,3,7)
		print("hold ❎ and press\narrows to interact",55,3,7)
		print("[x] on keyboard",60,46)
		print("  hold 🅾️ to\nreset the level",3,69)
		print("[z] on keyboard",3,118)
		print(" press ❎\nto continue",80,93)
		
		palt(4,true)
		spr(1+frame%3,20+sin(frame/50)*8,24+cos(frame/50)*8,1,1,cos(frame/50)>0)
		spr(1,87,25)
		spr(frame/15%2>1 and 113 or 112,95,25)
		for i=1,4 do
			if (frame/15%2>1 and i==2) mpal({7,6,13},{15,8,2})
			spr(7+frame/3%4,87+dirs[i][1]*8,25+dirs[i][2]*8)
			pal()
		end
		palt(4,true)
		spr(1,27,108)
		circ(30,96,10,7)
		circfill(30,96,frame/3%10+1,7)
		line(0,48,128,73,7)
		line(50,0,36,55,7)
		line(62,60,78,128,7)
		pal()
	end,function()
		camera(-256,0)
		screen_fade(function()
			camera(0,0)
			load_level(2,0)
		end)
	end)
end

function load_level(mx,my)
	level.x=mx
	level.y=my
	
	colliders={}
	player=new_player()
 particles={}
 pushblocks={{},{},{},{},{}}
 emitters={}
 receivers={}
 redirectors={}
 beams={}
 spikes={}
 signs={}
 boss=nil
 bullets={}
 
	-- generate level
	for x=0,15 do
		for y=0,15 do
		 tile=mget(mx*16+x,my*16+y)
		 
		 -- static
 		if fget(tile,0) and not fget(tile,7) then
 			new_collider(x*8,y*8)
 		end
 		-- pushblocks
 		if fget(tile,1) then
 			new_pushblock(x*8,y*8,tile-16)
 		end
 		-- lasers
 		if fget(tile,2) then
 			if tile>71 then
 				new_receiver(x*8,y*8)
 			elseif tile>63 then
 				new_emitter(x*8,y*8,(tile-64)%4+1,tile>67)
 			else
 				new_redirector(x*8,y*8,tile)
 			end
 		end
 		-- spikes
 		if fget(tile,3) then
 			new_spike(x*8,y*8,tile)
 		end
 		-- signs
 		if fget(tile,4) then
 			new_sign(x*8,y*8)
 		end
 		-- waypoints
 		if tile==48 then
 			player.x=x*8
 			player.y=y*8
 		end
 		-- boss
 		if tile==104 then
 			new_boss(x*8,y*8)
 		end
 	end
	end
	-- invisible wall at level (1,0)
	if level.x==1 and level.y==0 then
		new_collider(0,24)
	end
end

function is_outside()
	return pget(1,2)==12
end

-- separated for checking for no dupe screen fades
local when_dark=nil
function fade_interval(frames)
		palt(15,true)
		palt(0,false)
		local f=16-frames/2
		if (f>8) f=16-f
		for x=0,15 do
			for y=0,15 do
				if (f<9) spr(80+f,x*8,y*8)
			end
		end
		if (f==8) then
			when_dark()
			when_dark=nil
		end
	end

function screen_fade(wd)
	for i=1,#promises.frame do
		if(promises.frame[i].interval==fade_interval) return
	end
	when_dark=wd
	new_promise(32,fade_interval,function()return "fade"end)
	sfx(8)
end

function _update()
 frame+=1
 frame%=30000
 
	player.update(player)
	if frame%3==0 and (abs(player.dx)>0.1 or abs(player.dy)>0.1) and not gameover then
		new_dust(player.x+1+rnd(5),player.y+7+rnd(3),3)
		sfx(2)
	end
	if frame%15==0 and not is_outside() and not gameover then
		new_ember(player.x+(player.left and 0 or 7),player.y+4,3)
	end
	update_particles()
	
	if is_outside() then
		for i=16,45 do
		--print(mget(i,3),1,1)
		--stop()
		mset(i,3,94.5+cos(frame/100))
		end
	end
	
	if gameover then
		if (frame%5==0) new_treasure(40,58)
		if (frame%20==0) sfx(9)
	end
end

function _draw()
	pal()
	-- no c15 transparency if
	-- on outside room
	-- (light blue tile in corner)
	if not is_outside() then
		palt(15,true)
	end
	cls()
	
	-- background
	palt(0,false)
	for i=0,16 do
 	for j=0,16 do
 		spr(16,i*8,j*8)
 	end
	end
	-- torch light
	circfill(player.x+4,player.y+4,13.33+sin(frame/100)*1.9,2)
	circfill(player.x+4,player.y+4,9.66+sin(frame/100)*1.9,8)
	circfill(player.x+4,player.y+4,8+sin(frame/100)*1.9,9)

	for i=0,15 do
 	for j=0,15 do
 		spr(32,i*8,j*8)
 	end
	end
	map(level.x*16,level.y*16,
		0,0,16,16,0b00000001)
	pal()
	
	draw_spikes()
	draw_pushblocks()
	draw_emitters()
	draw_redirectors()
	draw_receivers()
	draw_beams()
	draw_particles()
	draw_boss()
	draw_bullets()
	pal()
	
	if (is_outside()) palt(4,true)
	if player.alive then
		if gameover then
			spr(player.jumping and 5 or 4,player.x,player.y)
		else
	 	spr(1+player.frame,player.x,player.y,1,1,player.left)
		end
		-- torch flame
		if not is_outside() and not gameover then
			if player.left then
				pset(flr(player.x)+0.5+sin(frame/20),player.y+4,10)
				pset(flr(player.x)+0.5+sin(frame/20+0.15),player.y+3,8)
			else
				pset(flr(player.x)+7.5+sin(frame/20),player.y+4,10)
				pset(flr(player.x)+7.5+sin(frame/20+0.15),player.y+3,8)	
			end
		end
	else
	 spr(6,player.x,player.y,1,1,player.left)
	end
	pal()
	
	if btn(❎) and not gameover then
		local offsets={{0,-1},{1,0},{0,1},{-1,0}}
		for i=1,4 do
			if btn(({⬆️,➡️,⬇️,⬅️})[i]) then mpal({7,6,13},{15,8,2}) end
			spr(7+(frame/3)%4,(round(player.x/8)+offsets[i][1])*8,(round(player.y/8)+offsets[i][2])*8)
			pal()
		end
	end
	
	if restart_timer>0 then
		print("restart?",player.x-10,player.y+9,7)
		circ(player.x+3,player.y-12,10,7)
		circfill(player.x+3,player.y-12,restart_timer/3,7)
	end
	
	-- sign text
	if reading>0 then
		rectfill(0,114,128,128,13)
		print((sign_text[
			level.x..","..level.y
		] or {})[reading] or "this message should not appear",1,116,7)
	end
	
	-- promises
	local remove={frame={},condition={}}
	
	for i=1,#promises.frame do
	 local p=promises.frame[i]
		p.frames-=1
		p.interval(p.frames)
		if p.frames<=0 then
			p.callback()
			remove.frame[#remove.frame+1]=i
		end
	end
	
	for i=1,#promises.condition do
	 local p=promises.condition[i]
		p.interval()
		if p.condition() then
			p.callback()
			remove.condition[#remove.condition+1]=i
		end
	end
	
	-- remove finished promises
	for i=#remove.frame,1,-1 do
		promises.frame=remove_item(promises.frame,i)
	end
	for i=#remove.condition,1,-1 do
		promises.condition=remove_item(promises.condition,i)
	end
	
	if gameover then
		if (finish_time=="") finish_time=display_time()
		
		outline_print("thanks for playing!",28,24,7)
		outline_print("you finished in "..finish_time,18,110,7)
	end
	
	-- debug
	for i=1,#colliders do
		local c=colliders[i]
		--rect(c.x+(8-c.size)/2,c.y+(8-c.size)/2,c.x+(8-c.size)/2+c.size,c.y+(8-c.size)/2+c.size,3)
	end
	--print(#beams,5,1,7)
	--print(display_time(),5,1,7)
end
