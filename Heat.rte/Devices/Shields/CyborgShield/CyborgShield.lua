function Create(self)
	
	self.deploySound = CreateSoundContainer("Deploy Sound Sergeant Shield", "Heat.rte");
	self.deployFinishSound = CreateSoundContainer("Deploy Finish Sound Sergeant Shield", "Heat.rte");
	
	self.animTimer = Timer();
	self.initialFrameDelay = 250;
	self.animFrameDelay = 50;
	self.actingDelay = self.initialFrameDelay;
	
	self.Frame = 1;
	
	self.Anim = true;
	
	self.deploySound:Play(self.Pos);
	
end
function Update(self)

	if not self:IsAttached() then self:GibThis() end

	if self.Anim == true then
		if self.animTimer:IsPastSimMS(self.actingDelay) then
			self.actingDelay = self.animFrameDelay;
			self.animTimer:Reset();
			self.Frame = self.Frame + 1;
			if self.Frame == 9 then
				self.deployFinishSound:Play(self.Pos);
				self.Anim = false;
			end
		end
	end
	
	self.deploySound.Pos = self.Pos;
	self.deployFinishSound.Pos = self.Pos;
	
end