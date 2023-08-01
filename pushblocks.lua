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
