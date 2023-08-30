function OnDetach(self)

	-- really shouldn't be used outside of being held

	self:DisableScript("Heat.rte/Devices/Weapons/Handheld/Riotbreaker/Chamber.lua");
	self.BaseReloadTime = 6000;
	
	self.ammoCountRaised = false;
	if self.Reloading then
		self.resumeReload = true;
	end
	if self.phaseOnStop then
		self.reloadPhase = self.phaseOnStop;
		self.phaseOnStop = nil;
	end
	self.reloadTimer:Reset();
	self.prepareSoundPlayed = false;
	self.afterSoundPlayed = false;
	
end

function OnAttach(self)

	self:EnableScript("Heat.rte/Devices/Weapons/Handheld/Riotbreaker/Chamber.lua");
	self.reloadTimer:Reset();
	
end