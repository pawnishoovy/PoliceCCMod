function Update(self)
	
	if math.random(100) > 93 then
		local Effect = CreateMOPixel("Spark Yellow 1")
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
	
	if self.crackleSound then
		if self.crackleSound:IsBeingPlayed() then
			self.crackleSound:SetPosition(self.Pos);
		end
	else
		self.crackleSound = AudioMan:PlaySound("Heat.rte/Devices/Weapons/Handheld/Raider/CompliSound/BulletCrackle" .. math.random(1, 4) .. ".ogg", self.Pos, -1, 0, 130, 1, 450, false);
	end

	if self.ToDelete then
		if self.crackleSound then
			if self.crackleSound:IsBeingPlayed() then
				self.crackleSound:Stop(-1);
			end
		end
	end
end