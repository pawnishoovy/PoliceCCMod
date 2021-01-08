function OnDetach(self)

	self:DisableScript("Heat.rte/Devices/Weapons/Handheld/Disabler/Chamber.lua");
	self.ReloadTime = 3800;
	
end

function OnAttach(self)

	self:EnableScript("Heat.rte/Devices/Weapons/Handheld/Disabler/Chamber.lua");
	
end