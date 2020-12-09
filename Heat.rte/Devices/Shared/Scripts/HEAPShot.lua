function Create(self)
	self.EffectRotAngle = self.Vel.AbsRadAngle;
	--Check backward (second argument) on the first frame as the projectile might be bouncing off something immediately
	HEAPUpdate(self, true);
	
	self.trailPar = CreateMOPixel("Heat HEAP Shot Trail Glow");
	self.trailPar.Pos = self.Pos - (self.Vel * rte.PxTravelledPerFrame);
	self.trailPar.Vel = self.Vel * 0.1;
	self.trailPar.Lifetime = 60;
	MovableMan:AddParticle(self.trailPar);
	
	--[[
	self.trailM = 0; -- DONT TOUCH
	self.trailMTarget = RangeRand(-1,1);
	self.trailMProgress = 0; -- DONT TOUCH
	
	self.trailGProgress = 0; -- DONT TOUCH
	self.trailGLoss = -0.8; -- Trail lifetime offset (lower number, stays 100% longer)
	
	-- FINE TUNE!
	self.LifetimeMulti = 1; -- How long the particles stay alive
	self.TrailRandomnessMulti = 1; -- Wave modulation target speed
	self.TrailWavenessSpeed = 1; -- Wave modulation controller speed
	
	self.ParticleName = "Tiny Smoke Ball 1"; -- Trail's particle]]
	
	self.Accel = Vector(self.Vel.X, self.Vel.Y) * 0.75
	self.Vel = self.Vel * 0.25
end
function Update(self)
	self.ToSettle = false;
	if self.explosion then
		self.ToDelete = true;
	else
		HEAPUpdate(self, false);
		
		if self.trailPar and MovableMan:IsParticle(self.trailPar) then
			self.trailPar.Pos = self.Pos - Vector(self.Vel.X, self.Vel.Y):SetMagnitude(6);
			self.trailPar.Vel = self.Vel * 0.5;
			self.trailPar.Lifetime = self.Age + TimerMan.DeltaTimeMS;
		end
	end
	self.EffectRotAngle = self.Vel.AbsRadAngle;
	
	local accel = Vector(self.Accel.X, self.Accel.Y) * TimerMan.DeltaTimeSecs * 17.5
	self.Vel = self.Vel + accel
	self.Accel = self.Accel - accel
	
	--[[
	-- Epic smoke trail TM by filipex2000, 2020
	local smoke
	local offset = self.Vel*(17*TimerMan.DeltaTimeSecs)
	local trailLength = math.floor((offset.Magnitude+0.5) / 4)
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
				smoke.Lifetime = smoke.Lifetime * RangeRand(0.7, 1.7) * (1.0 + self.trailGProgress) * 0.2 * self.LifetimeMulti;
				smoke.GlobalAccScalar = RangeRand(-1, 1) * 0.15; -- Go up and down
				MovableMan:AddParticle(smoke);
				
				local c = 1;
				self.trailGProgress = math.min(self.trailGProgress + TimerMan.DeltaTimeSecs * c, 1.0)
				self.trailGLoss = math.min(self.trailGLoss + TimerMan.DeltaTimeSecs * 0.65, 1.0);
			end
		end
	end]]
end
function HEAPUpdate(self, inverted)

	local trace = inverted and Vector(-self.Vel.X, -self.Vel.Y):SetMagnitude(GetPPM()) or Vector(self.Vel.X, self.Vel.Y):SetMagnitude(self.Vel.Magnitude * rte.PxTravelledPerFrame + 1);
	local hit, hitPos, skipPx = nil, Vector(), math.sqrt(self.Vel.Magnitude) * 0.5;

	local ray = SceneMan:CastObstacleRay(self.Pos, trace, hitPos, Vector(), self.ID, self.Team, rte.airID, skipPx);
	if ray >= 0 then
		local mo = MovableMan:GetMOFromID(SceneMan:GetMOIDPixel(hitPos.X, hitPos.Y));
		if mo then
			hit = true;
		else
			local penetration = self.Mass * self.Sharpness * self.Vel.Magnitude;
			if SceneMan:GetMaterialFromID(SceneMan:GetTerrMatter(hitPos.X, hitPos.Y)).StructuralIntegrity > penetration then
				hit = true;
			end
		end
	end
	if hit or self.Vel.Magnitude < 5 then
		local offset = Vector(self.Vel.X, self.Vel.Y):SetMagnitude(skipPx);
		self.explosion = CreateAEmitter("Heat.rte/HEAP Hit Effect");
		self.explosion.Pos = hitPos - offset;
		self.explosion.RotAngle = offset.AbsRadAngle;
		self.explosion.Team = self.Team;
		self.explosion.Vel = offset;
		MovableMan:AddParticle(self.explosion);
	end
end
--[[ To-do: Use this system instead
function OnCollideWithMO(self, mo, parentMO)
	self.explosion = CreateAEmitter("Techion.rte/Laser Dissipate Effect");
	self.explosion.Pos = self.Pos;
	self.explosion.RotAngle = self.Vel.AbsRadAngle;
	self.explosion.Team = self.Team;
	self.explosion.Vel = self.Vel;
	MovableMan:AddParticle(self.explosion);
end
function OnCollideWithTerrain(self, terrainID)
	self.explosion = CreateAEmitter("Techion.rte/Laser Dissipate Effect");
	self.explosion.Pos = self.Pos;
	self.explosion.RotAngle = self.Vel.AbsRadAngle;
	self.explosion.Team = self.Team;
	self.explosion.Vel = self.Vel;
	MovableMan:AddParticle(self.explosion);
end]]--