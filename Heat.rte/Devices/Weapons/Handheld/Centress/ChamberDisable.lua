function OnDetach(self)

	self:DisableScript("Heat.rte/Devices/Weapons/Handheld/Centress/Chamber.lua");
	self.BaseReloadTime = 1700;
	self.Frame = 0;
	
end

function OnAttach(self)

	self:EnableScript("Heat.rte/Devices/Weapons/Handheld/Centress/Chamber.lua");
	
end