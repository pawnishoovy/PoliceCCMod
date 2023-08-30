function OnDetach(self)

	self:DisableScript("Heat.rte/Devices/Weapons/Handheld/Jury/Chamber.lua");
	self.BaseReloadTime = 5000;
	
	if self.canShrapnel then	
		self.Frame = 5;
	elseif ((not self.shrapnelReload) and (not self.Reloading)) or self.toClose == true then
		self.Frame = 0;
	end
	
end

function OnAttach(self)

	self:EnableScript("Heat.rte/Devices/Weapons/Handheld/Jury/Chamber.lua");
	
end