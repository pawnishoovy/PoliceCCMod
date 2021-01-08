function OnDetach(self)

	self:DisableScript("Heat.rte/Devices/Weapons/Handheld/CLIER/Chamber.lua");
	self.ReloadTime = 3000;
	if self.boltLockedBack == true then
		self.Frame = 3;
	else
		self.Frame = 0;
	end
	
end

function OnAttach(self)

	self:EnableScript("Heat.rte/Devices/Weapons/Handheld/CLIER/Chamber.lua");
	
end