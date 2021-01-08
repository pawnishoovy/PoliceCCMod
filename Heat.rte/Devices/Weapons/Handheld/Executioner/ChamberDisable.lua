function OnDetach(self)

	self:DisableScript("Heat.rte/Devices/Weapons/Handheld/Executioner/Chamber.lua");
	self.ReloadTime = 4200;
	
	if self.Charging == true then
		self.Charging = false;
		if self.chargeUpSound then
			self.chargeUpSound:Stop(-1);
			self.chargeInterruptSound:Play(self.Pos);
			self.returnToCharge = true;
		end
	end	
	
end

function OnAttach(self)

	self:EnableScript("Heat.rte/Devices/Weapons/Handheld/Executioner/Chamber.lua");
	if self.returnToCharge == true then
		self.returnToCharge = false;
		self.Charging = true;
		self.shieldActivationTimer:Reset();
		self.chargeUpSound:Play(self.Pos);
	end
	
end