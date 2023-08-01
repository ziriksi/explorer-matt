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
