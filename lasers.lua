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