function OnDetach(self)

	self:DisableScript("Heat.rte/Devices/Weapons/Handheld/Tazer/Chamber.lua");
	self.BaseReloadTime = 3300;
	
	if self.magInside == true then
		self.Frame = 5;
	elseif self.coverBack == true then
		self.Frame = 4;
	else
		self.Frame = 0;
	end
	self.reloadTimer:Reset();
	self.afterSoundPlayed = false;
	self.prepareSoundPlayed = false;
	if self.phaseOnStop then
		self.reloadPhase = self.phaseOnStop;
		self.phaseOnStop = nil;
	end

	
end

function OnAttach(self)

	self:EnableScript("Heat.rte/Devices/Weapons/Handheld/Tazer/Chamber.lua");
	self.reloadTimer:Reset();
	self.BaseReloadTime = 9999;
	
end