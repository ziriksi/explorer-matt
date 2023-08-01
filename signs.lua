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
