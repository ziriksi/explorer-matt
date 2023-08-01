pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- main

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

-->8
-- player

function new_player()
 	return {
  	x=60,
  	y=60,
  	vx=0,
  	vy=0,
  	dx=0,
  	dy=0,
  	frame=0,
  	left=false,
  	action_timeout=false,
  	alive=true,
  	jumping=false,
  	collider=new_collider(40,40),
  	update=function(this)
  		local px=this.x
  		local py=this.y
  		
   	if this.vx>=0.2 then
   		this.vx-=0.15
   	end
   	if this.vx<=-0.2 then
   		this.vx+=0.15
   	end
   	if abs(this.vx)<0.2 then
   		this.vx=0
  		end
   	if this.vy>=0.2 then
   		this.vy-=0.15
  		end
   	if this.vy<=-0.2 then
   		this.vy+=0.15
   	end
   	if abs(this.vy)<0.2 then
    	this.vy=0
   	end
   	
   	for i=1,#promises.frame do
   		if promises.frame[i].interval==fade_interval then
   			goto ignore_move
   		end
   	end
   	
   	if gameover then
   		goto ignore_physics
   	end
   	
   	if btn(🅾️) and level.x+level.y>0 then
   		restart_timer+=1
   		if restart_timer>32 then
   			restart_timer=0
   			screen_fade(function()load_level(level.x,level.y)end)
   		end
   	elseif restart_timer>0 then
   		restart_timer-=1
   	end
   	
   	if (not player.alive) goto ignore_physics
   	
   	if btn(❎) then
   		local dirs={
   			{⬅️,-1,0},
   			{➡️,1,0},
   			{⬆️,0,-1},
   			{⬇️,0,1}
   		}
   		for i=1,4 do
   			if not this.action_timeout and btn(dirs[i][1]) then
   				check_action_collider(new_collider((round(player.x/8)+dirs[i][2])*8,(round(player.y/8)+dirs[i][3])*8),dirs[i][2],dirs[i][3])
   				
   				colliders[#colliders]=nil
   				this.action_timeout=true
   				new_promise(10,function()end,function()this.action_timeout=false end)
   			end
   		end
   	 goto ignore_move
   	end
   	
   	
   	
   	if btn(⬅️) then
   		this.left=true
   		this.vx=max(this.vx-0.5,-2)
  		end
   	if btn(➡️) then
   		this.left=false
   		this.vx=min(this.vx+0.5,2)
   	end
   	if btn(⬆️) then
   		this.vy=max(this.vy-0.5,-2)
  		end
   	if btn(⬇️) then
   		this.vy=min(this.vy+0.5,2)
   	end
   	
   	::ignore_move::
   	
   	this.x+=this.vx
   	this.y+=this.vy
   	
   	this.collider.x=this.x
   	this.collider.y=this.y
   	
   	
   	for i=1,#colliders do
   		local c=colliders[i] -- collider
   		local pc=player.collider -- player collider
   		if c!=pc then -- dont collide with self
    		for i=1,10 do
    			if is_colliding(c,pc) then
       	if (boss and c==boss.collider and boss.hp>=1) player.damage()
       	if abs(c.x-pc.x)>=abs(c.y-pc.y) then
       		this.x-=this.vx/5
       		this.vx/=1.1
       	end
       	if abs(c.x-pc.x)<=abs(c.y-pc.y) then
        	this.y-=this.vy/5
        	this.vy/=1.1
       	end
       	
       	this.collider.x=this.x
       	this.collider.y=this.y
    			end
   			end
   			-- clip fix, only triggers
   			-- if colliding at
   			-- specific angle
   			local angle=atan2(c.y-pc.y,c.x-pc.x)
   			while is_colliding(c,pc) do
   				print(sin(angle),1,10)
   				print(cos(angle),1,20)
  
   				this.x-=sin(angle)
   				this.y-=cos(angle)
    	 	this.collider.x=this.x
      	this.collider.y=this.y
   			end
   		end
   	end
   	
   	::ignore_physics::
   	
   	this.dx=this.x-px
   	this.dy=this.y-py
   	
   	if (abs(player.dx)>0.1 or abs(player.dy)>0.1) then
   	 this.frame+=1
   	 this.frame%=3
   	else
   		this.frame=0
   	end
   	
   	if this.x!=mid(-7,this.x,127) or this.y!=mid(-8,this.y,128) then
   		this.x+=this.vx
   		this.y+=this.vy
   		local tx=flr(this.x/128)
   		local ty=flr(this.y/128)
   		screen_fade(function()
   			load_level(level.x+tx,level.y+ty)
   		end)
   	end
   	
   	if gameover then
   		if frame%30==0 then
   			player.jumping=true
   		 local py=player.y
   		 new_promise(12,function(f)
   		 	player.y=py+sin(f/24)*8
   		 end,function()
   		 	player.jumping=false
   		 end)
   		end
   	end
  	end,
  	damage=function()
  		if (not player.alive) return
  		player.alive=false
  		sfx(3)
  		for i=1,#promises.frame do
  			if boss and promises.frame[i].callback==boss.land then
  				promises.frame=remove_item(promises.frame,i)
  				boss.jumping=false
  				break
  			end
  		end
  		new_promise(10,function()
  			new_dust(player.x+rnd(8),player.y+rnd(8),5,6+rnd(2))
  		end,function()end)
  		
				-- heads up! a frame delay
				-- fucks up the screen for
				-- no reason
				-- maybe i'll fix it later
				new_promise(29,function()end,function()
					screen_fade(function()load_level(level.x,level.y)end)
				end)
  	end
 	}
end


-->8
-- math

function round(n)
	if n%1<0.5 then
		return flr(n)
	else
	 return ceil(n)
	end
end

function remove_item(list,index)
	local ret={}
	for i=1,#list do
		if i!=index then
			ret[#ret+1]=list[i]
		end
	end
	return ret
end

function mpal(old,new)
	for i=1,#old do
		pal(old[i],new[i])
	end
end

function display_time()
 local t=time()
 local h=flr(t/3600)
 local m=flr(t/60)%60
 local s=flr(t)%60
 
 local ret=tostr(h)..":"
 ret..=(m<10 and "0"..m or m)..":"
 ret..=(s<10 and "0"..s or s)
	return ret
end

function outline_print(text,x,y,col)
	for dx=-1,1 do
		for dy=-1,1 do
			print(text,x+dx,y+dy,0)
		end
	end
	print(text,x,y,col)
end

function lerp(min,max,n)
	return min+(max-min)*n
end
-->8
-- particles

function new_dust(x,y,size,col)
	particles[#particles+1]={
	 x=x,
	 y=y,
	 size=size,
	 count=0,
	 life=10,
	 col=col or 6,
	 update=function()
	 	
	 end,
	 draw=function(this)
	 	circfill(this.x,this.y,sin(-this.count/20)*size,this.col)
	 	--circ(this.x,this.y,sin(-this.count/20)*size,6)
	 end
	}
end

function new_ember(x,y)
	particles[#particles+1]={
	 x=x,
	 y=y,
	 vx=0.5-rnd(),
	 vy=-1.5,
	 count=0,
	 life=40,
	 update=function(this)
	 	this.vy+=0.15
	 	if this.count>22 then
	 		this.vx=0
	 		this.vy=0
	 	end
	 	this.x+=this.vx
	 	this.y+=this.vy
	 end,
	 draw=function(this)
	 	pset(this.x,this.y,8+rnd(3))
	 end
	}
end

function new_sparkle(x,y)
	particles[#particles+1]={
		x=x,
		y=y,
		count=0,
		life=8,
		update=function()end,
		draw=function(this)
			if this.count<4 then
				spr(114+this.count,this.x,this.y)
			else
			 spr(121-this.count,this.x,this.y)
			end
		end
	}
end

function new_treasure(x,y)
	particles[#particles+1]={
		x=x,
		y=y,
		vx=rnd(2)-1,
		vy=-4+rnd(3),
		count=0,
		life=200,
		ground=y+rnd(32)-16,
		hit_ground=false,
		spr=98+rnd(5),
		update=function(this)
			this.x+=this.vx
			this.y+=this.vy
			this.vy+=0.2
			
			if this.vy>0 and this.y>this.ground and not this.hit_ground then
				this.hit_ground=true
				this.vy=-4
			end
			
			if rnd()<0.2 then --%20
				new_sparkle(this.x,this.y)
			end
		end,
		draw=function(this)
			palt(5,true)
			palt(0,false)
			spr(this.spr,this.x,this.y)
			pal()
		end
	}
end

function update_particles()
	for i=1,#particles do
		if i>#particles then
			break
		end
		particles[i].count+=1
		particles[i].update(particles[i])
		if particles[i].count>=particles[i].life then
			particles=remove_item(particles,i)
		end
	end
end

function draw_particles()
	for i=1,#particles do
		particles[i].draw(particles[i])
	end
end
-->8
-- colliders

function new_collider(x,y,size,ghost)
	size=size or 7.5
	local c={
		x=x+(8-size)/2,
		y=y+(8-size)/2,
		size=size
	}
	if not ghost then
		colliders[#colliders+1]=c
	end
	return c
end

function is_colliding(c1,c2)
	return abs(c1.x-c2.x)<(c1.size+c2.size)/2 and abs(c1.y-c2.y)<(c1.size+c2.size)/2
end

function check_action_collider(ac,vx,vy)
	-- check pushblocks
	for c=1,5 do
		for i=1,#pushblocks[c] do
			local grp=pushblocks[c]
			if is_colliding(ac,grp[i].collider) then
				-- check if can move
				local can_move=true
				for j=1,#pushblocks[c] do
					grp[j].collider.x+=vx*8
					grp[j].collider.y+=vy*8
				end
				for j=1,#grp do
					for k=1,#colliders do
						if grp[j].collider!=colliders[k] and is_colliding(grp[j].collider,colliders[k]) then
							can_move=false
						end
					end
				end
				for j=1,#grp do
					grp[j].collider.x-=vx*8
					grp[j].collider.y-=vy*8
				end
				if can_move then
					sfx(0)
 				new_promise(8,function()
 					for j=1,#grp do
 						grp[j].x+=vx
 						grp[j].y+=vy
 					end
 				end,function()end)
				else
					sfx(1)
				end
				return
			end
		end
	end
	
	for i=1,#redirectors do
		local r=redirectors[i]
		if is_colliding(ac,r.collider) then
			local can_move=true
			r.collider.x+=vx*8
			r.collider.y+=vy*8
			for j=1,#colliders do
			 local c=colliders[j]
				if r.collider!=c and is_colliding(r.collider,c) then
				 can_move=false
				end
			end
			r.collider.x-=vx*8
			r.collider.y-=vy*8
			if can_move then
				sfx(0)
				new_promise(8,function()
					r.x+=vx
					r.y+=vy
				end,function()end)
			else
				sfx(1)
			end
		end
	end
	
	reading=0
	for i=1,#signs do
		if is_colliding(ac,signs[i]) and #promises.condition<40 then
			reading=i
			local rx=player.x
			local ry=player.y
			new_promise(function()
				return (player.x!=rx or player.y!=ry)
				 and not btn(❎)
			end,function()end,function()
				reading=0
			end)
		end
	end
	
	for i=1,#bullets do
		local b=bullets[i]
		if is_colliding(ac,b.reflect_collider) then
			b.angle=b.angle+0.5
			b.shift=-b.shift
			b.reflected=true
			sfx(5)
		end
	end
	
	-- open switch
	if level.x==1 and level.y==0
	and flr(ac.x)/8==3 and flr(ac.y)/8==13
	and mget(19,13)==122 then
		sfx(4)
	 mset(19,13,123)
	 mset(47,7,16)
	 mset(47,8,16)
	 mset(47,9,16)
	end
	
	-- end chest
	if level.x==3 and level.y==2
	and flr(ac.x)/8==5 and flr(ac.y)/8==8
	and mget(53,40)==96 then
		sfx(4)
	 mset(53,40,97)
	 
	 gameover=true
	 restart_timer=0
	 player.vx=0
	 player.vy=0
	end
end


-->8
-- pushblocks

function new_pushblock(x,y,col)
	pushblocks[col][#pushblocks[col]+1]={
		x=x,
		y=y,
		collider=new_collider(x,y)
	}
end

function draw_pushblocks()
	local pals={
		{15,8,2},
		{7,10,9},
		{10,11,3},
		{7,12,13},
		{15,14,2}
	}
	local darkpals={
		{8,2,1},
		{10,9,4},
		{11,3,1},
		{6,13,1},
		{14,2,1}
	}
	for g=1,5 do
	 for i=1,#pushblocks[g] do
	 	local pb=pushblocks[g][i]
	 	pb.collider.x=pb.x
	 	pb.collider.y=pb.y
	 	local dist=sqrt((pb.x-player.x)^2+(pb.y-player.y)^2)
	 	if dist>17 then
 	 	mpal(pals[g],darkpals[g])
 	 end
	 	if dist>26 then
 	 	mpal(pals[g],{13,1,0})
 	 end
	 	spr(16+g,pb.x,pb.y)
	 	pal()
	 end
	end
end
-->8
-- promises

function new_promise(f,interval,callback)
	if type(f)=="function" then
		promises.condition[#promises.condition+1]={
			condition=f,
			interval=interval,
			callback=callback
		}
	else
		promises.frame[#promises.frame+1]={
			frames=f,
			interval=interval,
			callback=callback
		}
	end
end
-->8
-- lasers

--[[
directions of each kind
of redirector
vector of **input** directions
output lasers should be negative
--]]
local redir_dict={
	["22"]={{0,-8},{-8,0}},
	["23"]={{0,-8},{8,0}},
	["24"]={{0,-8},{8,0},{-8,0}},
	["25"]={{0,8},{0,-8},{8,0}},
	["38"]={{0,8},{-8,0}},
	["39"]={{0,8},{8,0}},
	["40"]={{0,8},{8,0},{-8,0}},
	["41"]={{0,8},{0,-8},{-8,0}},
	["56"]={{8,0},{-8,0}},
	["57"]={{0,8},{0,-8}},
}

function new_redirector(x,y,id)
	redirectors[#redirectors+1]={
		x=x,
		y=y,
		id=id,
		collider=new_collider(x,y)
	}
end

function draw_redirectors()
	for i=1,#redirectors do
		local r=redirectors[i]
		local dist=sqrt((r.x-player.x)^2+(r.y-player.y)^2)
	 
	 if dist>26 then
	 	mpal({15,8,2},{13,1,0})
	 	spr(17,r.x,r.y)
	 else
	 	if dist>17 then mpal({7,6,13,8},{6,13,1,2}) end
	 	spr(r.id,r.x,r.y)
	 end
	 pal()
		
		r.collider.x=r.x
		r.collider.y=r.y
	end
end

function new_emitter(x,y,d,k)
	emitters[#emitters+1]={
		x=x,
		y=y,
		dir=dirs[d],
		deadly=k
	}
end

function draw_emitters()
	for i=1,#emitters do
		local e=emitters[i]
		if #beams<27 then -- limiter
			new_beam(e.x,e.y,e.dir,e.deadly)
		end
	end
end

function new_receiver(x,y)
	receivers[#receivers+1]={
		x=x,
		y=y,
		activity=0,
		collider=new_collider(x,y)
	}
end

function draw_receivers(x,y)
	for i=1,#receivers do
		local r=receivers[i]
		if r.activity>0 then r.activity-=1 end
	end
end

function new_beam(x,y,d,k)
	beams[#beams+1]={
		x=x,
		y=y,
		vx=d[1]*8,
		vy=d[2]*8,
		deadly=k,
		collider=new_collider(x,y,2,true)
	}
end

local i=-1
function draw_beams()
	while stat(1)<0.965 do
		i+=1
		if i>#beams then
			i=1
			break
		end
		
		local b=beams[i]
		if not b then goto skip end
		b.x+=b.vx
		b.y+=b.vy
		b.collider.x=b.x
		b.collider.y=b.y

		for j=1,#redirectors do
			local r=redirectors[j]
			if is_colliding(r.collider,b.collider) then
			 local inputs=redir_dict[tostr(r.id)]
			 local lineup=false
			 for k=1,#inputs do
			 	local v=inputs[k]
			 	if (b.vx==v[1] and b.vy==v[2]) then
			 		lineup=true
			 	end
			 end
			 if not lineup then break end
			 for k=1,#inputs do
			 	local v=inputs[k]
			 	if not (b.vx==v[1] and b.vy==v[2]) then
			 	 new_beam(r.x,r.y,{-v[1]/8,-v[2]/8},b.deadly)
			 	end
			 end
			 break
			end
		end
		for j=1,#receivers do
			local r=receivers[j]
			if is_colliding(b.collider,r.collider) then
				r.activity=10
			end
		end
		for j=1,#colliders do
			if is_colliding(colliders[j],b.collider)
			or b.x!=mid(-8,b.x,128) or b.y!=mid(-8,b.y,128) then
				beams=remove_item(beams,i)
				i-=1
				if b.deadly and colliders[j]==player.collider then
					if player.alive then
						new_dust(player.x+4,player.y+4,10,11)
						new_dust(player.x+4,player.y+4,5,7)
					end
					player.damage()
				end
				goto skip
			end
		end
		
		local col=b.deadly and 11 or 8
		if b.vx==0 then
			rectfill(b.x+2,b.y,b.x+5,b.y+7,col)
			rectfill(b.x+3,b.y,b.x+4,b.y+7,7)
		else
			rectfill(b.x,b.y+2,b.x+7,b.y+5,col)
			rectfill(b.x,b.y+3,b.x+7,b.y+4,7)
		end
		::skip::
	end
end
-->8
-- spikes

function new_spike(x,y,id)
	spikes[#spikes+1]={
		x=x,
		y=y,
		inverted=id>48,
		tier=id%16, -- 1-3
		collider=new_collider(x,y,2)
	}
end

function draw_spikes()
	local num_active=0
	for i=1,#receivers do
		if receivers[i].activity>0 then
			num_active+=1
		end
	end
	local num_inactive=#receivers-num_active
	palt(0,false)
	palt(15,true)
	for i=1,#spikes do
		local s=spikes[i]
		local spike_up=(s.inverted and num_inactive or num_active)>=s.tier

		if spike_up then
			spr(36,s.x,s.y)
			s.collider.x=-8
			s.collider.y=-8
		else
			spr((s.inverted and 48 or 32)+s.tier,s.x,s.y)
			s.collider.x=s.x
			s.collider.y=s.y
		end
		if is_colliding(player.collider,s.collider) then
			player.damage()
		end
	end
	palt()
end

-->8
-- signs

sign_text={
	["4,0"]={"pay attention to the movement\nof same-colored blocks","it's dark, so you may need to\nget close to see colors","remember you can hold 🅾️ to\nreset objects"},
	["3,1"]={"sometimes spikes need power off\nto go down","you can tell this if the spike\npoints up and right"},
	["2,1"]={"if a spike pops up while you're\nunder it, you'll get hurt","be careful!"},
	["0,2"]={"redirectors can be pushed\naround","they change a laser's direction\nor split it into two"},
	["6,3"]={"timing is key"},
	["7,3"]={"lasers sometimes flicker because\nof lag reasons"}
}
function new_sign(x,y)
	signs[#signs+1]=new_collider(x,y)
end
-->8
-- boss

function new_boss(x,y)
	boss={
		x=x,
		y=y,
		py=0,
		hp=100,
		collider=new_collider(x+8,y+8,16),
		
		-- left as a functtion with a
		-- reference so the promise
		-- can be identified and
		-- cleared on player damage
		
		-- otherwise the promise will
		-- persist after a restart
		-- and the boss will appear to
		-- keep its position 
		land=function()end,
		jump=function()
			if (not player.alive) return
			local start={x=boss.x,y=boss.y}
			local target={x=player.x,y=player.y}
			new_promise(30,function(f)
				if (not boss) return -- crash fix
				boss.x=lerp(start.x,target.x,1-f/30)
				boss.y=lerp(start.y,target.y,1-f/30)-sin(1-f/60)*24
			end,boss.land)
		end
	}
end

function new_bullet()
	local angle=atan2(player.x-boss.x-4,player.y-boss.y-4)
	local curve=rnd(0.3)-0.15
	angle+=curve
	local frames_to_reach=sqrt(
		(player.x-boss.x)^2+(player.y-boss.y)^2
	)/4
	local shift=-curve/frames_to_reach
	bullets[#bullets+1]={
		x=boss.x+8,
		y=boss.y+8,
		--vx=(player.x-boss.x)/25,
		--vy=(player.y-boss.y)/25,
		vx=cos(angle)*2,
		vy=sin(angle)*2,
		angle=angle,
		shift=shift,
		life=300,
		collider=new_collider(0,0,2,true),
		reflect_collider=new_collider(0,0,8,true),
		reflected=false
	}
end

function draw_boss()
	if (boss==nil) return
	boss.collider.x=boss.x+4
	boss.collider.y=boss.y+4
	if boss.hp>=1 then
		if (frame%15==0 and frame%120>30) new_bullet()
		if (frame%120==0) boss.jump()
	elseif player.alive then
		bullets={}
		-- timer
		boss.hp+=0.01
		new_dust(boss.x+rnd(16),boss.y+rnd(16),10,5+rnd(3))
		sfx(2)
		if boss.hp>0.5 then
			boss.collider.y=-128
			new_dust(boss.x+8,boss.y+8,30,8)
			new_dust(boss.x+8,boss.y+8,20,9)
			new_dust(boss.x+8,boss.y+8,10,10)
			for i=1,30 do
				new_ember(boss.x-12+rnd(40),boss.y-12+rnd(40))
			end
			sfx(7)
			boss=nil
			mset(64,39,0)
			mset(64,40,0)
			mset(64,41,0)
			mset(66,39,0)
			local remover=new_collider(0,70,16,true)
			for i=#colliders,1,-1 do
				if is_colliding(colliders[i],remover) then
					colliders=remove_item(colliders,i)
				end
			end
			return
		end
	end
	
	palt(15,true)
	palt(0,false)
	spr(104,boss.x,boss.y,2,2)
	spr(118,boss.x-1,boss.y+(boss.y==boss.py and 9 or 12))
	spr(119,boss.x+9,boss.y+(boss.y==boss.py and 9 or 12))
	pal()
	outline_print("boss hp",3,3,7)
	rectfill(32,2,123,7,0)
	rectfill(33,3,33+boss.hp*89/100,6,8)
	line(33,3,33+boss.hp*89/100,3,15)
	line(33,6,33+boss.hp*89/100,6,2)

	boss.py=boss.y
end

function draw_bullets()
	for i=1,#bullets do
		local b=bullets[i]
		if (b==nil) break
		b.angle+=b.shift
		b.vx=cos(b.angle)*2
		b.vy=sin(b.angle)*2
		b.x+=b.vx
		b.y+=b.vy
		
		b.collider.x=b.x-3
		b.collider.y=b.y-3
		b.reflect_collider.x=b.x
		b.reflect_collider.y=b.y
		b.life-=1
		for j=1,#colliders do
			local c=colliders[j]
			if (c!=b.collider and b.life<=290
			and is_colliding(b.collider,c))
			or b.life<0 then
				new_dust(b.x,b.y,5,11)
				new_dust(b.x,b.y,3,7)
				bullets=remove_item(bullets,i)
				if (c==player.collider and not b.reflected) player.damage()
				if c==boss.collider and b.reflected then
					boss.hp=max(boss.hp-7,0)
					sfx(6)
				end
				break
			end
		end
	end
	
	for i=1,#bullets do
		spr(89,bullets[i].x,bullets[i].y)
	end
end

__gfx__
000000000000000000707000007070000000000000000000000000000dddddd00dddddd00dd776600666ddd00000000000000000000000000000000000000000
00000000007070000777770007777700000707000007070000000000dd0000dddd0000dddd000066660000dd0111101111110110011110111101111111011110
00700700077777000717710007177100007777700077777000000000d000000dd000000dd00000066000000d0100000000000010011111011101111110111110
00077000071771000777770007777700007171700071717000070700d000000dd0000007d00000067000000d0001111101111010011000000000000000000110
000770000777770000777004007770040077777000777770007777706000000dd0000007d000000d7000000d0101000000001010011001111111110111100110
007007000077700400777740077770400007770000077700071171106000000dd0000006d000000dd000000d0101011111101000001010000000000000010100
00000000077777400777700000777700007777700007770007777770660000dddd000066dd0000dddd0000dd0101011111101010010010111101111111010010
0000000000707000000070000070000000070700007000707777777706677dd00ddd66600dddddd00dddddd00100011001101010011010100000000001010110
111111010ffffff0077777700aaaaaa0077777700ffffff007777770077777700777777007700770000000000101011001100010011010100000000001010110
00000000f888888f7aaaaaa7abbbbbba7cccccc7feeeeeef766666677666666776666667766ee667010111100101011111101010011000100000000001010110
1101111188888888aaaaaaaabbbbbbbbcccccccceeeeeeee66666666666666666666666666688666010000100001011111101010011010100000000000010000
1101111188888888aaaaaaaabbbbbbbbcccccccceeeeeeee666dddddddddd666ddddddddddd88666010110000101000000001010011010100000000001010110
1101111188888888aaaaaaaabbbbbbbbcccccccceeeeeeee66688888888886668888888888888666010110100101111011111000011010100000000001010110
0000000088888888aaaaaaaabbbbbbbbcccccccceeeeeeee66688666666886666668866666688666000110100100000000000010000010000000000001010110
11111101288888829aaaaaa93bbbbbb3dccccccd2eeeeee2d668866dd668866dd668866dd668866d010000100110111111011110011010100000000001000110
111111010222222009999990033333300dddddd0022222200dd22dd00dd22dd00dd22dd00dd22dd0010110100000000000000000011010100000000001010110
1111110f1100011f1100011f1100011f1111110f0000000007700770077007700770077007700770010110100000000000000000011010100000000001010110
00000000000d000000070000000700000000000000000000766ee667766ee667766ee667766ee667010110100111111001111110010010111111101111010010
ff0ffffff006d00ff007600ff00a700ff00ff00f0000000066688666666886666668866666688666000110000100000001d1dd10001010000000000000010100
110fff11101d6101101671011019a101101fff010000000066688dddddd88666ddd88ddd66688ddd010110100101101001111110011001111011111111100110
110f1111101dd101101d610110149101101f11010000000066688888888886668888888866688888010110100101101001dd1d10011000000000000000000110
00000000000110000001100000011000000110000000000066666666666666666666666666688666010110100000001001111110011111011111101110111110
ffffff0fff00000fff00000fff00000fff00000f00000000d666666dd666666dd666666dd668866d010000100111111001111110011110111111101111011110
fff1110ffff1110ffff1110ffff1110ffff1110f000000000dddddd00dddddd00dddddd00dd22dd0010110100000000000000000000000000000000000000000
008800881100011f1100011f1100011f111000f11100000f1100010f1100000f0777777007700770010110000000000000000000000000000000000000000000
008800880000d00000007000000070000000100000011000000100000001100076666667766ee667010110100111011111111011110111100000000000000000
88008800f00d600ff006700ff007a00f00001100ff0110ff00110000001111006666666666688666010110100100000000000000000000000000000000000000
880088001016d10110176101101a910101111110000110000111111001111110dddddddd66688666000110100101111110111111101110100000000000000000
00880088101dd1011016d10110194101011111100111111001111110000110008888888866688666010110100101111110111111101110100000000000000000
00880088000110000001100000011000000011000011110000110000000110006666666666688666010000100000000000000000000000100000000000000000
88008800ff00000fff00000fff00000ffff0100ff001100ff0010f0fff01100fd666666dd668866d011110100111111011111011111101100000000000000000
88008800fff1110ffff1110ffff1110ffff0000fff00000fff00010fff00000f0dddddd00dd22dd0000000000000000000000000000000000000000000000000
000000000110101000088000010101100000000001101010000bb000010101100000000001101010000000000101011000000000e88ebbbbbbbaabbbcccccccc
11011111011000101187781101010110110111110110001011b77b1101010110110111110110001011d66d11010101100000000082eebbbbbba44abbcccccccc
1101111101101d8000d66d0008d100001101111101101db000d66d000bd1000011011111011010d0000dd0000d010000000000008228bbbbbba249bbcccccccc
00000000011016781011111187610110000000000110167b10111111b76101100000000001101d601011111106d1011000000000b88bbbbbbbb99bbbcccccccc
11111101011016780000000087610110111111010110167b00000000b76101101111110101101d600000000006d1011000000000bb3bbbbbbbbb3bbbcccccccc
00d66d0000001d801111101108d1011000d66d0000001db0111110110bd10110000dd000000010d0111110110d01011000000000bbb3bbbbbbbb3bbbcccccccc
1187781101101010111110110100011011b77b1101101010111110110100011011d66d1101101010111110110100011000000000bbb3bbbbbbb3bbbbcccccccc
00088000011010100000000001010110000bb0000110101000000000010101100000000001101010000000000101011000000000bb3bbbbbbbb3bbbbcccccccc
ffffffffff0fff0f0f0f0f0f0f0f0f0f0f0f0f0f000f000f00000000000000000000000000000000ffffffff0000000000000000cccccccccccccccccccccccc
fffffffffffffffffffffffff0f0f0f0000000000000000000000000000000000000000000000000ffffffff0000000000000000cccccccccccccccccccccccc
ffffffff0fff0fff0f0f0f0f0f0f0f0f0f0f0f0f0f000f000f000f000f00000000000000000bb000ffffffff0000000000000000ccccccccccccccccccc7777c
fffffffffffffffffffffffff0f0f0f0000000000000000000000000000000000000000000b77b00fff76fff0000000000000000cccccccccccc777777799997
ffffffffff0fff0f0f0f0f0f0f0f0f0f0f0f0f0f000f000f00000000000000000000000000b77b00f056d50f0000000000000000ccc7777c7777999999999999
fffffffffffffffffffffffff0f0f0f00000000000000000000000000000000000000000000bb000ff0550ff0000000000000000777ffff7999ffff9999ffff9
ffffffff0fff0fff0f0f0f0f0f0f0f0f0f0f0f0f0f000f000f000f0000000f000000000000000000fff00fff0000000000000000ffffffffffffffffffffffff
fffffffffffffffffffffffff0f0f0f0000000000000000000000000000000000000000000000000ffffffff0000000000000000ffffffffffffffffffffffff
122222211226d221552225555555555555522555555555555555111500000000ffffffffffffffffffffffffffffffffbbbbbbbbbbbbbbbbbbb31101ffffffff
24994442240550425299905555111155552f9055551001555551a70500000000ffff00000000ffffffffffffffffffffbbbbbbbbbbbbbbbbbbb30000ffffffff
044442200200002029aa420551c7c30552f7f8055177ff1555017b0500000000fff0777777770fffffffffffffffffffbbbbbbbbbbbbbbbbbbb30111ffffffff
0006d0000000000029a924051d777dd0529728055076fe0551a1ab0500000000ff077777777770ffff1111ffffffffffbb1111bbbbbbbbbbbbbb3111ffffffff
099554400994444029a924050ccdcc305287210550effd0550b0b10500000000f07777777777770ff1bbbb1fffffffffb1bbbb1bbbbbbbbbbbbb3111ffffffff
094444200944442009422405507cdd055082210551eed6155010b10500000000f07077777777070f1baaaab1ffffffff1baaaab1bbbbbbbbbbbb3000ffffffff
044222200442222050244055550c305555081055551001555500110500000000f07080777708070fbaabbaab1faaaaaabaabbaab1bbbbbbbbbb31101ffaaaaaa
1000000110000001550005555550055555500555555555555550005500000000f07000777700070fbbbbbbbb1abbbbbbbbbbbbbb1bbbbbbbbbb31101aabbbbbb
000000000000000000000000000000000000000000000000ffffffffffffffffff077777777770ffbbbbbbbbbbbbbbbbabbaabba1bbbbbbbbbbbbbbbbbbbbbbb
000000000000000000000000000000000000000000090000fffffffffffffffffff0770770770fffbbbbbbbbbbbbbbbbbaaaaaab1bbbbbbbbbbbbbbbbbbbbbbb
000f80000000000000000000000000000009000000090000fffffffffffffffffff0007007000fffbbbbbbbbbbbbbbbb3bb33bb30bbbbbbbb33bbb3bbbbbbbbb
00888800000f80000000000000090000000a0000009a9000ffffffffffffffffff007070070700ffbbb76bbbbbbbbbbb133113310bbbbbbbbb33b33bbbbbbbbb
0d6886d00d6886d0000a000000a7a00009a7a90099a7a990fff0000ff0000fffff077777777770ffbb36d3bbbb3763bb01133110bbbbbbbb3bb3b3bbbbbbbbbb
00d66d0000d66d000000000000090000000a0000009a9000ff07770ff07770fffff0777777770fffbbb33bbbbbb33bbbb000000bbbbbbbbb33b3bbb3bbbbbbbb
000000000000000000000000000000000009000000090000f077770ff077770fffff00000000ffffbbbbbbbbbbbbbbbbbb2940bbbbbbbbbbb3bbbb33bbbbbbbb
000000000000000000000000000000000000000000090000f000000ff000000fffffffffffffffffbbbbbbbbbbbbbbbbbb0420bbbbbbbbbbbbbbbb3bbbbbbbbb
0101010101d100000000f10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
d0e0e0e0e0e0e0e0e0e0e0e0e0e0e0f0010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01d0e0e004c100000000b1e0e0f0010101d0e0e0e084e0e0e0e0e0e0e0e0f0010101010101d0e0e0e0e0e0e0e0e0f00101010101010101010101010101010101
d10000000000000000000000000000f1010101010101010101010101010101010101010101010101010101010101010101d0e0e0e0e0f0010101d0e0e0e0f001
01d10000000000000000000000f1010101d1000000000000000000000000f1010101010101d10000001200000000f10101010101010101010101010101010101
d10000000000000000000000000000f10101010101010101010101010101010101d0e0e0e0e0e0e0e0e0e0e0e0e0f00101d100000000f1010101d1004100f101
01d10000000000000300000000f1010101d1000000000000000000000000f1010101010101d10000001200000000f10101010101010101010101010101010101
d10000b2b2000000000000b2b20000f10101010101010101010101010101010101d1000000000000000000310000f10101d100111111f1010101d1131313f101
01d10000000000000000000000f1010101d1000000000000000000000000f1010101010101d10000001200000000f1010101d0e0e0e0e0e0e0e0e0e0e0f00101
d10000b20000000000000000b20000f101b201b201b201b201b201b201b201b20154510000000000000000000000b40101d113131313b184e084c1323232f101
01d10000000000000000000000f1010101d1000000000000000061000000f1010101010101d15100001200000000f1010101d100000000000000000000f10101
d10000000000000000000000000000f10101010101010101010101010101010101d1000000000000000000313100f10101d1000000000000000000000000f101
01d10000000000000000000000b4010101d1000000000000000000000000f1010101010101d10000001200000000f1010101d100000000000000000000b1e0e0
c10000000000000000000000000000b1e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e001d13232b0c00000000000000000f10101d1000000000000000000000000f101
01d10000000062000000000000f1010101d1000000000000000000000000f1010101010101d2e2e2e2e2c0000000f1010101d100000000000000000000000000
b20086000000000000000000000000b200000000000000000000000000000000e0c10000f1d11212120000000000f10101d100000000b024c09333333333f101
01d10000000000000000000000f1010101d1000000000000000000000000f10101010101010101010101d1000000f1010101d100000600000000000003000000
b20000000000000000000000000300b20063000000000000000000000003000000330000f1940071120000000000f10101d100000000b1e0c19300000000f101
01d10000000000000000000000f1010101d1000000000000000000000000f10101010101010101010101d1000000f1010101d100000000000000000000000000
b20000000000000000000000000000b20000000000000000000000000000000063330011b1c11212120000000000f10101d10000000000330000000000b0f201
01d10000000000000000000000f1010101d1000000000000000000000000b1e0e0e0e0e0e0e084e0e0e0c1000000f1010101d100000000000000000000b0e2e2
c00000000000000000000000000000b0e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e20033001141410000000000000000f10101d1b200b0c000330092008100740101
01d2e2e2e2e2c0121212b0e2e2f2010101d100000000000000000000000023000000000000000000000000000000f1010101d100000000000000000000f10101
d10000b20000000000000000b20000f101010101010101010101010101010101e2c00000131311b2000000000000f10101d10041f1d100333300000000b1f001
010101010101d1000000f1010101010101d100000000000000000000000023430003000000000000000000000000f1010101d2e2e2e2e2e2e2e2e2e2e2f20101
d10000b2b2000000000000b2b20000f101b201b201b201b201b201b201b201b201d10062b0c0b200000091000000b1e0e0c1b200f1d10000006200007100f101
010101010101d1000000f10101010101011400000091b20000000000000023000000000041000000000000000000f10101010101010101010101010101010101
d10000000000000000000000000000f10101010101010101010101010101010101d10000f1940000000000000300000000630033f1d10003000000000000f101
010101010101d1005300f1010101010101d2e2e2e2a4e2e2e2e2c0000300b0e2e2e2e2e2e2e264e2e2e2c0515151f10101010101010101010101010101010101
d10000000000000000000000000000f10101010101010101010101010101010101d2e2e2f2d2e2e2e2e264e2e2e2e2e2e2e2e2e2f2d1000000b0e2a4a4e2f201
010101010101d1000000f1010101010101010101010101010101d1000000f10101010101010101010101d1005300f10101010101010101010101010101010101
d2e2e2e2e2e2e2e2e2e2e2e2e2e2e2f201010101010101010101010101010101010101010101010101010101010101010101010101d1000000f1010101010101
010101010101d1000000f1010101010101010101010101010101d1000000f10101010101010101010101d1000000f10101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101d1000000f1010101010101
01d0e0e0e0e0c1000000b1e084e0f00101010101010101010101d1007300f10101d0e0e0e0e0e084e0e0c1000000f10101d0e0e0e0e0e004e0e0e004e0e0f001
0101010101010101010101010101010101010101010101010101010101010101010101d0e0e0e0e0e0e0e0f00101010101d0e004e0c1007300f1010101010101
01d1000000000000030000000000f10101010101010101010101d1000000f10101d100410000b200000000000300f10101d1310000b22100000000000000f101
0101010101010101010101010101010101010101d0e0e0e0e0e0e0e0f00101010101019400008300000071f10101010101d1000000a2000000f1010101010101
0114000000000000000000000000f10101d0e0e0e0e0e0e0e0e0c1323232f10101d1000000000000000000000000f10101d141000000b200000041000000f101
0101010101010101010101010101010101d0e0e0c100330000000000f1010101010101d10000b0c0000000f10101010101d1006100a2000000f1010101010101
01d1000000000000000000000000f10101d1000000000000000000000000f10101d10000000000000000000000b0f20101d131000000b0a4c00041620000b401
0101010101010101010101010101010101d100002100330000000000b1e0e0e0e0e0c2c1b0a4f2d1000000f10101010101d1007100a2000000f1010101010101
01d1000000000000000000000000f10101d1000000000000000000000000f10101d10000000000000000000031f1010101d1b2000000b1e0c10041414100f101
0101010101010101010101010101010101d2e2e2c0003300000000002100000000000000b1e0f0d1000000f10101010101d1007200a2232323f1010101010101
01d1000000000000000000000000b40101d1006100000000000081000000f10101d10000000000000000000000f1010101d1000000000000000000000000f101
0101010101010101010101010101010101010101d2e2c0000000000021b24300000000030000f1d1000000f10101010101d1008300a2000000b1e0e0e0e0f001
01d1000000000000000000000000b1e0e0c1000000000000810000000000b40101d100000000000000000000b2b1e0e0e0c1000000000000000000000000f101
01d0e0e0e0e0f0d084e0e0e0e004f00101d0e0e0e044c1000000000021000000000000000000f1d1000000f10101010101d1620000a2005100a200000000f101
01d112121200000091000000000022000000000000000000000000000000b40101d100000000000000000000120000000000000000000000000000000000f101
01d100000000b4d1000000000000f10101d100000000000000000000b0e2e2e2e2e2c0110000b1c1000000f10101010101d1000000a2000000a30000b231f101
01d100621200000000000000000022430000030000000000000000009200f10101d1000000000000000000001243000000000300000000b0c00000310000f101
011400000000b1c1000000000000f10101d111111100000000000000f10101010101540000008383000072f10101010101d1000000a20000003200000000f101
01d100001200000000000000000022000000000000000000000000000000f10101d1004141414100000000001200000000000000000000f19400000000003401
01d1000000000000000000000000b1e0e0c10000110000000000b064f20101010101d11212120000000011b1e0e0e0e0e0c100b0a4e2e2e2c0b223b0c0b2f101
01d2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2a4e2e224e2e2e2e2e2f20101d1313131004100000000b0e2c000b0c0232323b0c033f1d1b2b2b0e2e2f201
01d1000000000000006172000000320000000000000000000000b18484f001010101d100000000000000002200003200000000b1c2f0d0e0c10000b1c100f101
010101010101010101010101010101010101010101010101010101010101010101d1310031004100000000f1d0c100f1d1000000f1d100b1c13100b1e0e0e0e0
e0c1000000000000617200000000324300000300000000000000000000f101010101d1000000008181000022000032430003000000f194000000008100317401
010101010101010101010101010101010101010101010101010101010101010101d1001100004141000000f1d11100f1d1002100f1d100000000000000220000
0000000300000061720000000000320000000000000000b20031310000f101010101d2e2a4c0000000000022110032000000000000b1c1000000120000b2f101
010101010101010101010101010101010101010101010101010101010101010101d2e2e2e2e2e224e2e2e2f2d2e264f2d1000000f1d100000000210000220000
0000000000b0e224e2e2e2a4e2e2e2e2e2e2e2e2e2a4e2e2e2e2e22424f201010101010101d10000000000220000b0e2e2c0000000000000b25100620000b401
010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101d2e2e2e2f2d2e2e2e2e2e2e2e2e2e2e2
e2e2e2e2e2f201010101010101010101010101010101010101010101010101010101010101d2e2e2e2e2e2e2e2e2f20101d2e2e2e2e2e2e2e2e2a4e2e2e2f201
__gff__
0000000000000000000000010181018181020202020204040404010101010001000808088100040404040101118101810008080881818181040401010101000005050505050505050505050500818101000000000000000000008100008181810101000000000000000001810181818100000000000000000000818101818181
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0b2b0c000000000000000000000000004f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f101010101010101010101010101010101010101010101010101010100d0e0f10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
2b302b000000000000000000000000004f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f101010101010101010101010101010101010101010101010101010101d001f10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
1b2b1c000000000000000000000000004f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f101010101010101010101010101010101010101010101010101010101d001f10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
000000000000000000000000000000005d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d0b2e101010101010101010101010101010101010101010101010101010101d001f10100d0e0e0e0e0e0e0e0f1010101010101010101010101010101010101010101010100d0e0e0e0e0e0e0e0e0e0e0e0f10
000000000000000000000000000000006a6b6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f1f1010100d0e0e0e0e0e0e0e0e0f101010101010101010101010101010101d001f10101d000000000000001f0d0e0f101010100d0e0e0e0e0e0e0e0e0e0e0e0e0f1010101d00000000000000000000001f10
000000000000000000000000000000007c7d7f7f7f7f7f7f7f7f7f7f7f7f7f7f6c6d7f7f7f7f7f7f7f7f7f7f7f7f1f1010101d00000000000000001f10101010100d0e0e0e0e0e0e0e0e0e0e1c001b0e0e1c000000000000001f1d001f101010101d0000000000000000000000001f1010101d00000000000000001113001f10
000000000000000000000000000000006c6d4d7f7f7f7e7f7f7f7f4e7f7f7f7f7c7d7f7f7f7f7f7f7f7f7f7f7f7f1b0e0e0e1c00000000000000001f10101010101d00000000000000000000001400000000000000000000001f1d001b0e0e0e0e1c0000000000000000000000001f1010101d00000000000000000000001f10
000000000000000000000000000000007c7d7f7f7f7f7f7f7f7f7f7f7f7f7f7f6c6d7f7e7f7f4d7f7f7f7f7f4e7f6e2b00000000000000000000001b0e0e0e0e0e1c00000000000000000000001400000000000000000000001b1c111300000000000000000000000000000000121f1010101d00000000000000000000001f10
000000000000000000000000000000006c6d7f7f7f7f7f7f7f7f7f7f7f7e7f7f7c7d7f7f7f7f7f7f7f7f7f7f7f7f6e2b00000030000000000000110000340000000000300000000000000000001400000000003000001300000000111300340000000030000000000000000000001f1010101d00000000000000000000001f10
000000000000000000000000000000007c7d7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7e7f7f7f6e2b00000000000000000000000b2e2e2e2e2e0c00000000000000000000001434000000000000001300000b0c111300000000000000000000000000000000001b0e0e0e1c00000000000000000000001f10
000000000000000000000000000000006c6d7f7f7f4d7f7f7f7f7f7f7f7f7f7f6c6d7f7f7f7f7f7f7f7f7f7f7f7f0b2e2e2e0c00000000000000001f10101010101d0000000000000000000000140b2e2e0c000000001300001f2d2e0c000b2e2e2e0c0000000000000000000012340000000000300000000000000000001f10
000000000000000000000000000000007c7d7f7f7f7f7f7f7f7e7f7f7f7f7f7f7c7d7f7f7f7f7f7f7f7f7f7f7f7f1f1010101d00000000000000001f10101010101d0000000000000000000000141f10101d000000001100001f10102d2e2f1010101d00000000001100000000120b2e2e2e0c00002b00000000000000001f10
000000000000000000000000000000006c6d7f7f7e7f4e7f7f7f7f7e7f7f7f7f6c6d7e7f7f7f7f7f4e7f7f7f7e7f1f1010102d2e2e2e2e2e2e2e2e2f10101010101d00000000000000000b2e0c141f10101d000000001100001f10101010101010101d0011001100110b2e2e2e2e2f1010101d00001111111313000000001f10
000000000000000000000000000000007c7d7f7a7f7f7f7f7f7f7f7f7f7f7f7f7c7d7f7f4d7f7f7f7f7f7f7f7f7f1f1010101010101010101010101010101010101d14000011000011001f101d141f10101d000000001100001f10101010101010101d0012001200001f10101010101010101d000011141414132b0000001f10
000000000000000000000000000000006c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c6c1f1010101010101010101010101010101010101d00000000000000001f102d2e2f10101d000000000000001f10101010101010102d2e2e2e2e2e2e2f10101010101010102d2e2e2e0c350b2e2e2e2e2e2f10
000000000000000000000000000000007c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c1f1010101010101010101010101010101010102d2e2e2e2e2e2e2e2e2f1010101010102d2e2e2e2e2e2e2e2f101010101010101010101010101010101010101010101010101010101d001f10101010101010
101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101d001f10101010101010
1010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010100d0e0e0e0e0f101010101010101010101d001f10101010101010
101010101010101010101010101010101010101010101010101010101010101010101010100d0e0e0e0e2c2c0e0e0f1010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010100d1c000013001f101010101010101010101d001f10101010101010
100d0e0e0e0e0e0e0e0e0e0e0e0e0f101010101010101010101010101010101010101010101d00000000000000001f1010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101d0011003b3c1b0e0e0f101010101010101d001f10101010101010
101d000000000000000013002a001f1010100d0e0e0e0e0e0e0e0e0e0e0e0f1010101010104100000000000000004b1010100d0e0e0e0e0e0e2c2c0e48480f101010100d0e0e0e0e4848480e0e0e0f10100d0e0e0e0e0e0e0e400e0e0e0e0f10100d0e0e0e1c2b002b00000000001f10100d0e0e0e0e1c001b0e0e0e0e0e0f10
101d000000002b11111113003a001f1010101d00000000140000000000001b0e0e0e0e0e0e1c00000000000000001f1010101d00110000000000002a00001f101010101d000000000000000000001f10101d0000000000000000000000001f10101d0000000000000000000000001f10101d0000000000300000000000001f10
101d000000003b3c3c3d000000001b0e0e0e1c0000000013000000000000000000003100002100000000130000001b0e0e0e1c14000000000014002a00001b0e0e0e0e1c000000000000000000001f10101d0000000000000000000000001f10101d0000000000000000000000001b0e0e1c1100000000000000000000121f10
101d000000000000000000000000000000002200000000110000000000000000000031000021000000000000000000000032310000000000003b3c3a0000000000232221000000000000000000001b0e0e1c2100000000000000000000001f10101d001111110000000000000000000000001100000000000000000000121f10
101d00000000000000000000000000000036220000000000000000000030000000003100002100000000000030000000363231000000000000000000000000003623222100000000000000000000000000002100000000000000000000001f10101d00111212000000000000003000002b361200000000000000000000111f10
101d00120000000000000000300000000000220000000000000000000000000000003100002100001300000000000000003231000000000000000030000000000023222100000000300000000000000036002100000000001111110000001b0e0e1c001111120000000000000000000000001100000000000000000000121f10
0d1c3c1a000000000000000000000b2e2e2e0c00000b2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e0c00000000000000000000000b2e2e2e2e0c000000000000000000000b2e2e0c21000000000000000000300000003612121212121300003b3c3d000b2e2e2e0c1100000000000000000000121f10
1d00002a000000000000000000001f1010101d00001f0d4848480e48480e0f101010101010101010101010101010101010101d13131100000000000000001f101010101d000000001313131300001f10101d0000000000000000000000000b2e2e0c00000000002b002a003a001f1010101d0000000000000000000000001f10
2d0c113a0000000000001a0000001f1010101d00001f1d001400141414001f101010101010101010101010101010101010101d00131100000000000000001f101010102d2e2e2e2e4242422e2e2e2f10101d0000000000000000000000001f10102d2e2e2e2e0c00003a0012001f1010102d2e2e2e2e2e2e2e2e2e2e2e2e2f10
101d001200002b1111112a1300001f1010101d00001f1d131300000000001f101010101010101010101010101010101010101d00001100000000000000001f1010101010101010101010101010101010102d2e2e2e2e2e2e2e4a2e2e2e2e2f101010101010101d0000000000001f101010101010101010101010101010101010
102d2e2e2e0c131313000b2e2e2e2f1010102d2e2e2f1d110011001100001f101010101010101010101010101010101010102d2e2e2e2e2e2e2e2e2e42422f1010101010101010101010101010101010101010101010101010101010101010101010101010102d2e2e2e2e2e2e2f101010101010101010101010101010101010
10101010101d000035001f10101010101010101010102d424242424242422f10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
__sfx__
000500000a6400b6400c640086400c6400f640106400e6300e620096100c6000e6000e6000e600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400000645006450221000645006450054000540005400054000540005400054000540003300033000330003300221000000000000000000000000000000000000000000000000000000000000000000000000
000400002b6202b6100000000000000000000000000007002e7002f70031700317003270033700007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040000092700b270102701127009270052700427004250042300121006200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400001267012640116503f67028650236401f62000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400002e250221503f4703f4403f4202b0002c20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040000251502e15038150386502f6502b65023630166200861000600326002e6002960028600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040000231502d150371503f1503f3703d6703c6603c6603c6603b6603a6503965038650366503565032640306402e6402c63029630256202261000000000000000000000000000000000000000000000000000
00050000225701c57019570175701757016570175701a5701f5702657000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00070000345752f56529555225551c555185551655514555135551255512535185050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
