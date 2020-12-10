function Update(self)


	-- all this to play a sound...

	if self.ToDelete then
		if self.Age < self.Lifetime then
			local hitPos = Vector(self.Pos.X, self.Pos.Y);
			local trace = Vector(self.Vel.X, self.Vel.Y) * rte.PxTravelledPerFrame;
			local skipPx = 2;
			local obstacleRay = SceneMan:CastObstacleRay(Vector(self.Pos.X, self.Pos.Y), trace, Vector(), hitPos, rte.NoMOID, self.Team, rte.airID, skipPx);
			if obstacleRay >= 0 then
				
				self.hitSound = AudioMan:PlaySound("Heat.rte/Devices/Weapons/Handheld/Assailant/CompliSound/BulletImpact" .. math.random(1, 5) .. ".ogg", hitPos, -1, 0, 130, 1, 150, false);
				--[[
				if math.random(100) > 85 then
					local Effect = CreateMOSParticle("Explosion Smoke 2 Glow")
					Effect.Pos = hitPos
					Effect.Vel = ((self.Vel*-1) + Vector(RangeRand(-20,20), RangeRand(-20,20))) / 10
					MovableMan:AddParticle(Effect)
				end
				if math.random(100) > 70 then
					local Effect = CreateMOSParticle("Explosion Smoke 1")
					Effect.Pos = hitPos
					Effect.Vel = ((self.Vel*-1) + Vector(RangeRand(-20,20), RangeRand(-20,20))) / 10
					MovableMan:AddParticle(Effect)
				end]]
			end
		end
	end
end