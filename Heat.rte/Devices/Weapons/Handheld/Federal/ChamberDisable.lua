function OnDetach(self)

	self:DisableScript("Heat.rte/Devices/Weapons/Handheld/Federal/Chamber.lua");
	self.ReloadTime = 2500;
	
	if self.Mode == 1 then
		self.returnToBurst = true;
		self.FullAuto = false;
	end
	
end

function OnAttach(self)

	self:EnableScript("Heat.rte/Devices/Weapons/Handheld/Federal/Chamber.lua");
	if self.returnToBurst == true then
		self.FullAuto = true;
		self.returnToBurst = false;
	end
	
end