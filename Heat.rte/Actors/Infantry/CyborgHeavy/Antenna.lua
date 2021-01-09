function Create(self)

	self.RotAngle = 0;
	self.RotAngleVel = 0;
	
	self.parent = nil;
end

function Update(self)
	
	
	if self.parent == nil then
		mo = self:GetRootParent()
		if mo and IsActor(mo) then
			self.parent = ToActor(mo);
		end

	elseif IsActor(self.parent) then
		
		local targetAngle = self.parent.RotAngle
		--local targetAngle = (Vector(5, 0):RadRotate(self.parent.RotAngle) + self.Vel * 0.5).AbsRadAngle
		
		local min_value = -math.pi
		local max_value = math.pi
		local value = targetAngle - self.RotAngle
		local result
		
		local range = max_value - min_value
		if range <= 0 then 
			result = min_value
		else
			local ret = (value - min_value) % range
			if ret < 0 then ret = ret + range end
			result = ret + min_value
		end
		local a = 12
		local b = 15
		
		self.RotAngleVel = (self.RotAngleVel + result * TimerMan.DeltaTimeSecs * a) / (1 + TimerMan.DeltaTimeSecs * a)
		self.RotAngle = self.RotAngle + self.RotAngleVel * TimerMan.DeltaTimeSecs * b -- Interpolate 
		
	end
end