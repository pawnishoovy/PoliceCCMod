function Create(self)

	self.maneuverBurstSound = CreateSoundContainer("Maneuver Burst Liberator", "Heat.rte");

	self.boosterTimer = Timer()
	self.boosterDelay = (self:GetNumberValue("TargetMode") == 1 and 700 or 100) + math.random(-30,30)
	self.booster = false
	
	self.maneuverTimer = Timer()
	self.maneuverDelay = math.random(175,225)
	self.maneuverMax = math.random(1,2)
	self.maneuver = self.maneuverMax
	
	self.dead = false
	
	self.AngularVel = RangeRand(-1,1) * 4
	
	self.targetPos = Vector(self:GetNumberValue("TargetX"), self:GetNumberValue("TargetY"))
	self.targetID = self:NumberValueExists("TargetID") and self:GetNumberValue("TargetID") or nil
	--self.targetSet = false
	
	
	for i = 1, math.random(2,6) do
		local poof = CreateMOSParticle(math.random(1,2) < 2 and "Tiny Smoke Ball 1" or "Small Smoke Ball 1");
		poof.Pos = self.Pos
		poof.Vel = Vector(self.Vel.X, self.Vel.Y):RadRotate(math.pi * RangeRand(-1, 1) * 0.05) * RangeRand(0.1, 0.9) * 0.6;
		poof.Lifetime = poof.Lifetime * RangeRand(0.9, 1.6) * 0.6
		poof.HitsMOs = false
		MovableMan:AddParticle(poof);
	end
	for i = 1, math.random(2,4) do
		local poof = CreateMOSParticle("Small Smoke Ball 1");
		poof.Pos = self.Pos
		poof.Vel = (Vector(self.Vel.X, self.Vel.Y):RadRotate(math.pi * (math.random(0,1) * 2.0 - 1.0) * 2.5 + math.pi * RangeRand(-1, 1) * 0.15) * RangeRand(0.1, 0.9) * 0.6 + Vector(self.Vel.X, self.Vel.Y):RadRotate(math.pi * RangeRand(-1, 1) * 0.15) * RangeRand(0.1, 0.9) * 0.2) * 0.5;
		poof.Lifetime = poof.Lifetime * RangeRand(0.9, 1.6) * 0.6
		poof.HitsMOs = false
		MovableMan:AddParticle(poof);
	end
	for i = 1, 3 do
		local poof = CreateMOSParticle("Explosion Smoke 2");
		poof.Pos = self.Pos
		poof.Vel = Vector(self.Vel.X, self.Vel.Y):RadRotate(RangeRand(-1, 1) * 0.15) * RangeRand(0.9, 1.6) * 0.66 * i;
		poof.Lifetime = poof.Lifetime * RangeRand(0.8, 1.6) * 0.1 * i
		poof.HitsMOs = false
		MovableMan:AddParticle(poof);
	end
end
function Update(self)
	
	--if not self.targetSet then
	--	self.targetPos = Vector(self:GetNumberValue("TargetX"), self:GetNumberValue("TargetY"))
	--	self.targetSet = true
	--end
	if self.targetID then
		local MO = MovableMan:FindObjectByUniqueID(self.targetID)
		if MO then
			local pos = MO.Pos
			local timeDif = SceneMan:ShortestDistance(self.Pos,pos,SceneMan.SceneWrapsX).Magnitude / (self.Vel.Magnitude / TimerMan.DeltaTimeSecs)
			self.targetPos = MO.Pos + Vector(MO.Vel.X, MO.Vel.Y) * timeDif * 1.5
		else
			self.targetID = nil
		end
	end
	
	-- launch
	if self.boosterTimer:IsPastSimMS(self.boosterDelay) and not self.dead then
		self:EnableEmission(true)
		self.GlobalAccScalar = 0.1
		if not self.booster then
		
			local vel = Vector(15,0):RadRotate(self.RotAngle) * -1.0
			for i = 1, 6 do
				local poof = CreateMOSParticle("Explosion Smoke Small");
				poof.Pos = self.Pos + Vector(0, 3)-- * self.FlipFactor):RadRotate(self.RotAngle)
				poof.Vel = Vector(vel.X, vel.Y):RadRotate(RangeRand(-1, 1) * 0.03) * RangeRand(0.9, 1.6) * 0.99 * (i-3);
				poof.Lifetime = poof.Lifetime * RangeRand(0.8, 1.6) * 0.1 * i
				poof.GlobalAccScalar = 0
				poof.AirResistance = poof.AirResistance * 1
				MovableMan:AddParticle(poof);
			end
			self.AngularVel = 0
			self.booster = true
		end
	else
		if not self.dead then
			if self.maneuver > 0 and self.maneuverTimer:IsPastSimMS(self.maneuverDelay) then
				self.maneuver = self.maneuver - 1
				
				--self.AngularVel = self.AngularVel * 0.7
				local vel = Vector(25,0):RadRotate(self.RotAngle) * -1.0
				for i = 1, math.random(2,6) do
					local poof = CreateMOSParticle(math.random(1,2) < 2 and "Tiny Smoke Ball 1" or "Small Smoke Ball 1");
					poof.Pos = self.Pos
					poof.Vel = Vector(vel.X, vel.Y):RadRotate(math.pi * RangeRand(-1, 1) * 0.05) * RangeRand(0.1, 0.9) * 0.6;
					poof.Lifetime = poof.Lifetime * RangeRand(0.9, 1.6) * 0.6
					poof.HitsMOs = false
					MovableMan:AddParticle(poof);
				end
				for i = 1, math.random(2,4) do
					local poof = CreateMOSParticle("Small Smoke Ball 1");
					poof.Pos = self.Pos
					poof.Vel = (Vector(vel.X, vel.Y):RadRotate(math.pi * (math.random(0,1) * 2.0 - 1.0) * 2.5 + math.pi * RangeRand(-1, 1) * 0.15) * RangeRand(0.1, 0.9) * 0.6 + Vector(self.Vel.X, self.Vel.Y):RadRotate(math.pi * RangeRand(-1, 1) * 0.15) * RangeRand(0.1, 0.9) * 0.2) * 0.5;
					poof.Lifetime = poof.Lifetime * RangeRand(0.9, 1.6) * 0.6
					poof.HitsMOs = false
					MovableMan:AddParticle(poof);
				end
				for i = 1, 3 do
					local poof = CreateMOSParticle("Explosion Smoke 2");
					poof.Pos = self.Pos
					poof.Vel = Vector(vel.X, vel.Y):RadRotate(RangeRand(-1, 1) * 0.15) * RangeRand(0.9, 1.6) * 0.66 * i;
					poof.Lifetime = poof.Lifetime * RangeRand(0.8, 1.6) * 0.1 * i
					poof.HitsMOs = false
					MovableMan:AddParticle(poof);
				end
				
				-- Frotate self.hoverDirection
				local min_value = -math.pi;
				local max_value = math.pi;
				local value = (SceneMan:ShortestDistance(self.Pos,self.targetPos,SceneMan.SceneWrapsX).AbsRadAngle) - self.RotAngle
				local result;
				
				local range = max_value - min_value;
				if range <= 0 then
					result = min_value;
				else
					local ret = (value - min_value) % range;
					if ret < 0 then ret = ret + range end
					result = ret + min_value;
				end
				
				self.AngularVel = self.AngularVel * 0.1 + value / ((self.boosterDelay - self.maneuverDelay * self.maneuverMax) * 0.001)
				
				self.Vel = self.Vel * 0.7
				
				self.maneuverBurstSound:Play(self.Pos);
				self.maneuverTimer:Reset()
			end
			
		end
		
		self:EnableEmission(false)
	end
	
	if self:GetNumberValue("TargetMode") == 1 then -- cool targeting
		
	elseif self:GetNumberValue("TargetMode") == 0 then -- less cool targeting
		
	end
	--AudioMan:PlaySound("Heat.rte/Devices/Weapons/Handheld/Liberator/Sounds/OutSlow" .. math.random(1, 3) .. ".ogg", self.Pos, -1, 0, 130, 1, 250, false);
	if self.booster and not self.dead then -- targeting
		local dif = SceneMan:ShortestDistance(self.Pos,self.targetPos,SceneMan.SceneWrapsX);
		
		local angToTarget = dif.AbsRadAngle
		
		local velCurrent = self.Vel-- + SceneMan.GlobalAcc
		local velTarget = Vector(100, 0):RadRotate(angToTarget)
		local velDif = velTarget - velCurrent
		
		
		
		-- Frotate self.hoverDirection
		local min_value = -math.pi;
		local max_value = math.pi;
		local value = velDif.AbsRadAngle - self.RotAngle
		local result;
		
		local range = max_value - min_value;
		if range <= 0 then
			result = min_value;
		else
			local ret = (value - min_value) % range;
			if ret < 0 then ret = ret + range end
			result = ret + min_value;
		end
		
		self.RotAngle = self.RotAngle + result * TimerMan.DeltaTimeSecs * 25
		
		-- acceleration
		self.Vel = self.Vel + Vector(math.pow(math.min(velDif.Magnitude, 25), 1.5), 0):RadRotate(self.RotAngle) * TimerMan.DeltaTimeSecs
		
		-- close to target, no need to target anymore
		if dif.Magnitude < 50 then
			self.dead = true
			self.GlobalAccScalar = 1.0
			self.Vel = self.Vel * 0.7
			
			self.AngularVel = RangeRand(-1,1) * 6
			
			
		end
	end
end