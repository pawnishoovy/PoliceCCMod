function Create(self)
	self.detonationDelay = 3000;
	
	self.impactDetonation = true
	
	self.lastVel = Vector(self.Vel.X, self.Vel.Y)
	
	self.impulse = Vector()
	self.bounceSoundTimer = Timer()
	
	self.trailM = 0; -- DONT TOUCH
	self.trailMTarget = RangeRand(-1,1);
	self.trailMProgress = 0; -- DONT TOUCH
	
	self.trailGProgress = 0; -- DONT TOUCH
	self.trailGLoss = 0.0; -- Trail lifetime offset (lower number, stays 100% longer)
	
	-- FINE TUNE!
	self.LifetimeMulti = 0.3; -- How long the particles stay alive
	self.TrailRandomnessMulti = 1; -- Wave modulation target speed
	self.TrailWavenessSpeed = 1; -- Wave modulation controller speed
	
	self.ParticleName = "Trail Nade Riotbreaker"; -- Trail's particle
end
function Update(self)
	
	self.impulse = (self.Vel - self.lastVel) / TimerMan.DeltaTimeSecs * self.Vel.Magnitude * 0.1
	self.lastVel = Vector(self.Vel.X, self.Vel.Y)
	
	-- Epic smoke trail TM by filipex2000, 2020
	local smoke
	local offset = self.Vel*(17*TimerMan.DeltaTimeSecs)
	local trailLength = math.floor((offset.Magnitude+0.5) / 3)
	for i = 1, trailLength do
		if RangeRand(0,1) < (1 - self.trailGLoss) then
			smoke = CreateMOSParticle(self.ParticleName);
			if smoke then
				
				local a = 10 * self.TrailWavenessSpeed;
				local b = 5 * self.TrailRandomnessMulti;
				self.trailM = (self.trailM + self.trailMTarget * TimerMan.DeltaTimeSecs * a) / (1 + TimerMan.DeltaTimeSecs * a)
				self.trailMProgress = self.trailMProgress + TimerMan.DeltaTimeSecs * b;
				if self.trailMProgress > 1 then
					self.trailMTarget = RangeRand(-1,1);
					self.trailMProgress = self.trailMProgress - 1;
				end
				
				smoke.Pos = self.Pos - offset * (1 - (i/trailLength)) * RangeRand(0.9, 1.1);
				smoke.Vel = self.Vel * self.trailGProgress * 0.5 + Vector(0, self.trailM * 17  * RangeRand(0.9, 1.1) * self.trailGProgress):RadRotate(Vector(self.Vel.X, self.Vel.Y).AbsRadAngle);-- * RangeRand(0.5, 1.2) * 0.5;
				smoke.Lifetime = smoke.Lifetime * RangeRand(0.7, 1.7) * (1.0 + self.trailGProgress) * 0.6 * self.LifetimeMulti;
				smoke.GlobalAccScalar = RangeRand(-1, 1) * 0.15; -- Go up and down
				MovableMan:AddParticle(smoke);
				
				local c = 1;
				self.trailGProgress = math.min(self.trailGProgress + TimerMan.DeltaTimeSecs * c, 1.0)
				self.trailGLoss = math.min(self.trailGLoss + TimerMan.DeltaTimeSecs * 0.65, 1.0);
			end
		end
	end
	
	if self.Age > self.detonationDelay and self.impactDetonation then
		self:GibThis()
	else
		--self.ToDelete = false;
		self.ToSettle = false;
	end
end

function OnCollideWithTerrain(self, terrainID)
	if self.bounceSoundTimer:IsPastSimMS(50) then
		if self.impulse.Magnitude > 25 then -- Hit
			AudioMan:PlaySound("Heat.rte/Devices/Weapons/Handheld/Riotbreaker/CompliSound/Bounce"..math.random(1,6)..".ogg", self.Pos, -1, 0, 130, 1, 250, false);
			self.bounceSoundTimer:Reset()
		elseif self.impulse.Magnitude > 11 then -- Roll
			AudioMan:PlaySound("Heat.rte/Devices/Weapons/Handheld/Riotbreaker/CompliSound/Roll"..math.random(1,6)..".ogg", self.Pos, -1, 0, 130, 1, 250, false);
			self.bounceSoundTimer:Reset()
		end
	end
end

function OnCollideWithMO(self, collidedMO, collidedRootMO)
	if self.impactDetonation then
		self:GibThis();
		self.impactDetonation = false
		self.ToDelete = true
	end
end

function Destroy(self)

	ActivityMan:GetActivity():ReportDeath(self.Team, -1);
end