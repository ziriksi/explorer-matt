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
