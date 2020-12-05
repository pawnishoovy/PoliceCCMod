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

end

-- ?????

-- function Destroy(self)
	
	-- local endVector = Vector();
	-- local rayResult = SceneMan:CastObstacleRay(self.Pos, self.Vel, endVector, endVector, self.ID, -1, rte.grassID, 1)
	-- local vel = Vector(self.Vel.X, self.Vel.Y)
	
	-- rayResult = rayResult - 1;
	-- print(rayResult)
	-- if rayResult < 0 then
		-- rayResult = 0;
	-- end
	
	-- print(rayResult)
	-- print(vel)
	-- PrimitiveMan:DrawCirclePrimitive(self.Pos, 8, 5)
	
	-- vel:SetMagnitude(rayResult)
	
	-- if self.Vel.Magnitude < 3 then
		-- endVector = self.Pos;
	-- else
		-- endVector = self.Pos + vel;
	-- end

	-- for i = 1, 1 do
		-- local Effect = CreateMOSParticle("Tiny Smoke Ball 1", "Base.rte")
		-- Effect.Pos = endVector
		-- Effect.Vel = ((self.Vel*-1) + Vector(RangeRand(-100,100), RangeRand(-10,10))) / 10
		-- MovableMan:AddParticle(Effect)
	-- end
	
	-- for i = 1, 3 do
		-- local Effect = CreateMOSParticle("Side Thruster Blast Ball 1", "Base.rte")
		-- Effect.Pos = endVector
		-- Effect.Vel = ((self.Vel*-1) + Vector(RangeRand(-100,100), RangeRand(-20,20))) / 10
		-- MovableMan:AddParticle(Effect)
	-- end

	-- if math.random(100) > 85 then
		-- local Effect = CreateMOSParticle("Explosion Smoke 2 Glow")
		-- Effect.Pos = endVector
		-- Effect.Vel = ((self.Vel*-1) + Vector(RangeRand(-20,20), RangeRand(-20,20))) / 10
		-- MovableMan:AddParticle(Effect)
	-- end
	-- if math.random(100) > 70 then
		-- local Effect = CreateMOSParticle("Explosion Smoke 1")
		-- Effect.Pos = endVector
		-- Effect.Vel = ((self.Vel*-1) + Vector(RangeRand(-20,20), RangeRand(-20,20))) / 10
		-- MovableMan:AddParticle(Effect)
	-- end

-- end