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
