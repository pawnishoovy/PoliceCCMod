function OnDetach(self)

	self:DisableScript("Heat.rte/Devices/Weapons/Handheld/Assailant/Chamber.lua");
	self.BaseReloadTime = 2700;
	self.Frame = 0;
	
end

function OnAttach(self)

	self:EnableScript("Heat.rte/Devices/Weapons/Handheld/Assailant/Chamber.lua");
	
end