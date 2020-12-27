function Create(self)
	self.trailM = 0; -- DONT TOUCH
	self.trailMTarget = RangeRand(-1,1);
	self.trailMProgress = 0; -- DONT TOUCH
	
	self.trailGProgress = 0; -- DONT TOUCH
	self.trailGLoss = -0.8; -- Trail lifetime offset (lower number, stays 100% longer)
	
	-- FINE TUNE!
	self.LifetimeMulti = 1; -- How long the particles stay alive
	self.TrailRandomnessMulti = 1; -- Wave modulation target speed
	self.TrailWavenessSpeed = 1; -- Wave modulation controller speed
	
	self.ParticleName = "Tiny Smoke Ball 1"; -- Trail's particle
	
	self.emitTrail = math.random(1,2) < 2;
	
	self.slowdownTimer = Timer();
end

function Update(self)
	-- Epic smoke trail TM by filipex2000, 2020
	
	if self.slowdownTimer:IsPastSimMS(70) then
		self.Sharpness = self.Sharpness * 0.75
		self.Vel = Vector(self.Vel.X, self.Vel.Y):RadRotate(RangeRand(-0.1,0.1)) * 0.5
		self.slowdownTimer:Reset()
	end
	
	if self.emitTrail then
		local smoke
		local offset = self.Vel*(17*TimerMan.DeltaTimeSecs)
		local trailLength = math.floor((offset.Magnitude+0.5) / 6)
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
	end
end

function OnCollideWithTerrain(self, terrainID) -- Go delet
  self.ToDelete = true;
end
