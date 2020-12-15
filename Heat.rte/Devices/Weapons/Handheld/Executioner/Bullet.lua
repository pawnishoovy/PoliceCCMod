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

	if self.ToDelete then
		if self.Age < self.Lifetime then
			local hitPos = Vector(self.Pos.X, self.Pos.Y);
			local trace = Vector(self.Vel.X, self.Vel.Y) * rte.PxTravelledPerFrame;
			local skipPx = 2;
			local obstacleRay = SceneMan:CastObstacleRay(Vector(self.Pos.X, self.Pos.Y), trace, Vector(), hitPos, rte.NoMOID, self.Team, rte.airID, skipPx);
			if obstacleRay >= 0 then
				
				if math.random(100) > 55 then
					local Effect = CreateMOSParticle("Tiny Smoke Ball 1", "Base.rte")
					Effect.Pos = hitPos
					Effect.Vel = ((self.Vel*-1) + Vector(RangeRand(-100,100), RangeRand(-10,10))) / 10
					MovableMan:AddParticle(Effect)
				end
				
				local Effect = CreateMOSParticle("Side Thruster Blast Ball 1", "Base.rte")
				Effect.Pos = hitPos
				Effect.Vel = ((self.Vel*-1) + Vector(RangeRand(-100,100), RangeRand(-20,20))) / 10
				MovableMan:AddParticle(Effect)
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