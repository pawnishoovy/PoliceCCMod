function Create(self)
	self.boosterTimer = Timer()
	self.booster = false
	
	for i = 1, math.random(2,6) do
		local poof = CreateMOSParticle(math.random(1,2) < 2 and "Tiny Smoke Ball 1" or "Small Smoke Ball 1");
		poof.Pos = self.Pos
		poof.Vel = Vector(self.Vel.X, self.Vel.Y):RadRotate(math.pi * RangeRand(-1, 1) * 0.05) * RangeRand(0.1, 0.9) * 0.6;
		poof.Lifetime = poof.Lifetime * RangeRand(0.9, 1.6) * 0.6
		MovableMan:AddParticle(poof);
	end
	for i = 1, math.random(2,4) do
		local poof = CreateMOSParticle("Small Smoke Ball 1");
		poof.Pos = self.Pos
		poof.Vel = (Vector(self.Vel.X, self.Vel.Y):RadRotate(math.pi * (math.random(0,1) * 2.0 - 1.0) * 2.5 + math.pi * RangeRand(-1, 1) * 0.15) * RangeRand(0.1, 0.9) * 0.6 + Vector(self.Vel.X, self.Vel.Y):RadRotate(math.pi * RangeRand(-1, 1) * 0.15) * RangeRand(0.1, 0.9) * 0.2) * 0.5;
		poof.Lifetime = poof.Lifetime * RangeRand(0.9, 1.6) * 0.6
		MovableMan:AddParticle(poof);
	end
	for i = 1, 3 do
		local poof = CreateMOSParticle("Explosion Smoke 2");
		poof.Pos = self.Pos
		poof.Vel = Vector(self.Vel.X, self.Vel.Y):RadRotate(RangeRand(-1, 1) * 0.15) * RangeRand(0.9, 1.6) * 0.66 * i;
		poof.Lifetime = poof.Lifetime * RangeRand(0.8, 1.6) * 0.1 * i
		MovableMan:AddParticle(poof);
	end
end
function Update(self)
	if self.boosterTimer:IsPastSimMS(500) then
		self:EnableEmission(true)
		if not self.booster then
			for i = 1, 6 do
				local poof = CreateMOSParticle("Explosion Smoke Small");
				poof.Pos = self.Pos + Vector(0, 3)-- * self.FlipFactor):RadRotate(self.RotAngle)
				poof.Vel = Vector(self.Vel.X, self.Vel.Y):RadRotate(RangeRand(-1, 1) * 0.03) * RangeRand(0.9, 1.6) * 0.99 * (i-3);
				poof.Lifetime = poof.Lifetime * RangeRand(0.8, 1.6) * 0.1 * i
				poof.GlobalAccScalar = 0
				poof.AirResistance = poof.AirResistance * 1
				MovableMan:AddParticle(poof);
			end
			self.booster = true
		end
	else
		self:EnableEmission(false)
	end
end