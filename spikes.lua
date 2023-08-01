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
