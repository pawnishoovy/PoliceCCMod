function Create(self)

	self.bulletCrackleSound = CreateSoundContainer("Bullet Crackle Raider", "Heat.rte");
	
	local offset = Vector(self.Vel.X, self.Vel.Y):SetMagnitude(30) * -1
	
	for i = 1, math.random(2,6) do
		local poof = CreateMOSParticle(math.random(1,2) < 2 and "Tiny Smoke Ball 1" or "Small Smoke Ball 1");
		poof.Pos = self.Pos + offset
		poof.Vel = Vector(self.Vel.X, self.Vel.Y):RadRotate(math.pi * RangeRand(-1, 1) * 0.05) * RangeRand(0.1, 0.9) * 0.7;
		poof.Lifetime = poof.Lifetime * RangeRand(0.9, 1.6) * 1.4
		poof.AirResistance = poof.AirResistance / math.random(1,3) * 0.66
		poof.HitsMOs = false
		MovableMan:AddParticle(poof);
	end
	for i = 1, math.random(1,2) do
		local poof = CreateMOSParticle("Small Smoke Ball 1");
		poof.Pos = self.Pos + offset
		poof.Vel = (Vector(self.Vel.X, self.Vel.Y):RadRotate(math.pi * (math.random(0,1) * 2.0 - 1.0) * 2.5 + math.pi * RangeRand(-1, 1) * 0.15) * RangeRand(0.1, 0.9) * 0.6 + Vector(self.Vel.X, self.Vel.Y):RadRotate(math.pi * RangeRand(-1, 1) * 0.15) * RangeRand(0.1, 0.9) * 0.2) * 0.5;
		poof.Lifetime = poof.Lifetime * RangeRand(0.9, 1.6) * 0.7
		poof.HitsMOs = false
		MovableMan:AddParticle(poof);
	end
	for i = 1, math.random(1,3) do
		local poof = CreateMOSParticle("Explosion Smoke 2");
		poof.Pos = self.Pos + offset
		poof.Vel = Vector(self.Vel.X, self.Vel.Y):RadRotate(RangeRand(-1, 1) * 0.15) * RangeRand(0.9, 1.6) * 0.22 * i
		poof.Lifetime = poof.Lifetime * RangeRand(0.8, 1.6) * 0.1 * i * math.random(1,2)
		poof.HitsMOs = false
		MovableMan:AddParticle(poof);
	end
	
	self.fire = CreateMOSParticle(math.random(1,2) < 2 and "Fire Puff Small" or "Flame Smoke 2 Glow");
	
	self.endPar = CreateMOSParticle("Small Smoke Ball 1");
end

function Update(self)

	if self.Vel.Magnitude < 8 then
		--self.ToDelete = true;
		self.GlobalAccScalar = 1
		self.AirResistance = 0.01
	end
	
	if math.random(100) > 93 then
		local Effect = CreateMOSParticle("Tiny Smoke Ball 1")
		Effect.Pos = self.Pos
		Effect.Vel = ((self.Vel / 2) + Vector(RangeRand(-20,20), RangeRand(-20,20))) / 30
		MovableMan:AddParticle(Effect)
	end

	if math.random(100) > 98 then
		local Effect = CreateMOPixel("Spark Yellow 2")
		Effect.Pos = self.Pos
		Effect.Vel = ((self.Vel / 2) + Vector(RangeRand(-20,20), RangeRand(-20,20))) / 30
		MovableMan:AddParticle(Effect)
	end
	
	if self.crackleSoundPlaying then
		self.bulletCrackleSound.Pos = self.Pos;
	else
		self.crackleSoundPlaying = true;
		self.bulletCrackleSound:Play(self.Pos);
	end

	if self.ToDelete then
		self.bulletCrackleSound:Stop(-1);

		
		if self.Age < self.Lifetime then
			local hitPos = Vector(self.Pos.X, self.Pos.Y);
			local trace = Vector(self.Vel.X, self.Vel.Y) * rte.PxTravelledPerFrame;
			local skipPx = 2;
			local obstacleRay = SceneMan:CastObstacleRay(Vector(self.Pos.X, self.Pos.Y), trace, Vector(), hitPos, rte.NoMOID, self.Team, rte.airID, skipPx);
			if obstacleRay >= 0 then
				self.fire.Pos = hitPos;
				self.fire.Vel = Vector(self.Vel.X, self.Vel.Y):SetMagnitude(skipPx);
				MovableMan:AddParticle(self.fire);
				
				local damage = CreateMOPixel("Particle Raider Explosion Fragment")
				damage.Pos = self.Pos - Vector(self.Vel.X, self.Vel.Y):SetMagnitude(3)
				damage.Vel = (self.Vel + Vector(RangeRand(-15,15), RangeRand(-15,15)))
				damage.Team = self.Team
				damage.IgnoresTeamHits = true
				MovableMan:AddParticle(damage)
			end
		else
			local smoke = CreateMOSParticle("Flame Smoke 1");
			smoke.Pos = Vector(self.Pos.X, self.Pos.Y);
			smoke.Vel = Vector(self.Vel.X, self.Vel.Y) * 0.5;
			smoke.Lifetime = math.random(250, 500);
			MovableMan:AddParticle(smoke);
			
		end
	end
end

function Destroy(self)
	self.endPar.Pos = Vector(self.Pos.X, self.Pos.Y) + Vector(self.Vel.X, self.Vel.Y) * 0.16;
	self.endPar.Vel = Vector(self.Vel.X + math.random(-5, 5), self.Vel.Y + math.random(-5, 5)) * 0.5;
	self.endPar.HitsMOs = true;
	self.endPar.Mass = self.Mass;
	self.endPar.Lifetime = self.endPar.Lifetime/(1 + self.Age/self.Lifetime);
	MovableMan:AddParticle(self.endPar);
end