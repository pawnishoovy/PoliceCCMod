function OnDetach(self)

	self:DisableScript("Heat.rte/Devices/Weapons/Handheld/Disabler/Chamber.lua");
	self.BaseReloadTime = 3800;
	
end

function OnAttach(self)

	self:EnableScript("Heat.rte/Devices/Weapons/Handheld/Disabler/Chamber.lua");
	
end