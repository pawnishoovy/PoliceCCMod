function Create(self)
	
	self.trailM = 0; -- DONT TOUCH
	self.trailMTarget = RangeRand(-1,1);
	self.trailMProgress = 0; -- DONT TOUCH
	
	self.trailGProgress = 0; -- DONT TOUCH
	self.trailGLoss = -0.8; -- Trail lifetime offset (lower number, stays 100% longer)
	
	-- FINE TUNE!
	self.LifetimeMulti = 0.75; -- How long the particles stay alive
	self.TrailRandomnessMulti = 1; -- Wave modulation target speed
	self.TrailWavenessSpeed = 1; -- Wave modulation controller speed
	
	self.detonateTimer = Timer();
	
	self.airbustAmout = 4;
	self.airbustSpread = 20 / 180 * math.pi;
	
	self.shake = 0.1;
end
function Update(self)
	local endPos = Vector(self.Pos.X, self.Pos.Y); -- This value is going to be overriden by function below, this is the end of the ray
	local vec = Vector(self.Vel.X,self.Vel.Y):SetMagnitude(self.Vel.Magnitude * rte.PxTravelledPerFrame) * 2.0;
	
	self.Vel = Vector(self.Vel.X, self.Vel.Y):DegRotate(RangeRand(-self.shake, self.shake) * math.sqrt(1 + self.Vel.Magnitude));
	
	self.ray = SceneMan:CastObstacleRay(self.Pos, vec, Vector(0, 0), endPos, 0 , self.Team, 0, math.random(3,5)) -- Do the hitscan stuff, raycast
	if self.ray > 0 or self.detonateTimer:IsPastSimMS(300) then
		self:GibThis()
		
		for i = 1, self.airbustAmout do
			local pixel = CreateMOPixel("Particle Disabler Pellet");
			pixel.Vel = (Vector(self.Vel.X,self.Vel.Y):SetMagnitude(70 * RangeRand(0.75,1.5))):RadRotate(self.airbustSpread * -0.5 + self.airbustSpread * (i / self.airbustAmout) + RangeRand(-1.0,1.0) * math.random(0,2));
			pixel.Pos = self.Pos;
			pixel.Team = self.Team;
			pixel.IgnoresTeamHits = true;
			MovableMan:AddParticle(pixel);
			
			if math.random(1,2) < 2 then
				local smoke
				local r = RangeRand(0.8, 1.2)
				for j = 1, 5 do
					smoke = CreateMOSParticle("Tiny Smoke Ball 1");
					smoke.Pos = self.Pos
					smoke.Vel = pixel.Vel * (0.5 + (j / 5)) / 1.5 * 0.5 * RangeRand(0.9, 1.1) * r;
					smoke.GlobalAccScalar = RangeRand(-1, 1) * 0.15
					smoke.AirResistance = smoke.AirResistance * RangeRand(0.75, 1.5) * 0.2;
					MovableMan:AddParticle(smoke);
				end
			end
		end
	else
		-- Epic smoke trail TM by filipex2000, 2020
		
		local smoke
		local offset = self.Vel*(17*TimerMan.DeltaTimeSecs)
		local trailLength = math.floor((offset.Magnitude+0.5) / 3)
		for i = 1, trailLength do
			if RangeRand(0,1) < (1 - self.trailGLoss) then
				smoke = CreateMOPixel("Disabler Micro Smoke Ball "..math.random(1,4));
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