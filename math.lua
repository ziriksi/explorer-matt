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
