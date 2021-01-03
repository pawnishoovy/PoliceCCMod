function Create(self)
	self.activateTimer = Timer();
	self.activateDelay = 1000
	
	self.deactivateTimer = Timer();
	self.deactivateDelay = 5000
	
	self.active = false
end

function Update(self)
	if self:IsActivated() then
		if self.activateTimer:IsPastSimMS(self.activateDelay) then
			self.Frame = 1
			self.active = true
			
			local emitter = CreateAEmitter("Time Nade Emitter")
			emitter.Lifetime = self.deactivateDelay
			self:AddAttachable(emitter);
		end
	else
		self.activateTimer:Reset()
	end
	
	if self.active then
		if self.deactivateTimer:IsPastSimMS(self.deactivateDelay) then
			self:GibThis()
		end
	else
		self.deactivateTimer:Reset()
	end
end