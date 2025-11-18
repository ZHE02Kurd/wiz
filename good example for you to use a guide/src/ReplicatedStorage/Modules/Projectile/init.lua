local projectiles	= {}

local PROJECTILE	= {}

function PROJECTILE.Create(self, proj, id)
	if not projectiles[proj] then
		projectiles[proj]	= require(script:WaitForChild(proj))
	end
	
	local projectile	= {
		Position	= Vector3.new();
		Velocity	= Vector3.new();
		ID			= id;
		Start		= tick();
		Ignore		= {};
	}
	
	for i, v in pairs(projectiles[proj]) do
		projectile[i]	= v
	end
	
	return projectile
end

return PROJECTILE