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
