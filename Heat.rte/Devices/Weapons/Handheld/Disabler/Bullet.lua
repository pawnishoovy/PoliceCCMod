function Update(self)
	
	if math.random(100) > 93 then
		local Effect = CreateMOPixel("Spark Yellow 1")
		if Effect then
			Effect.Pos = self.Pos
			Effect.Vel = ((self.Vel / 2) + Vector(RangeRand(-20,20), RangeRand(-20,20))) / 30
			MovableMan:AddParticle(Effect)
		end
	end

	if math.random(100) > 98 then
		local Effect = CreateMOPixel("Spark Yellow 2")
		if Effect then
			Effect.Pos = self.Pos
			Effect.Vel = ((self.Vel / 2) + Vector(RangeRand(-20,20), RangeRand(-20,20))) / 30
			MovableMan:AddParticle(Effect)
		end
	end

end


function Destroy(self)
	local Offset = self.Vel*(8*TimerMan.DeltaTimeSecs)


	
	for i = 1, 1 do
		local Effect = CreateMOSParticle("Tiny Smoke Ball 1", "Base.rte")
		if Effect then
			Effect.Pos = self.Pos + Offset
			Effect.Vel = ((self.Vel*-1) + Vector(RangeRand(-100,100), RangeRand(-10,10))) / 10
			MovableMan:AddParticle(Effect)
		end
	end
	
	for i = 1, 1 do
		local Effect = CreateMOSParticle("Side Thruster Blast Ball 1", "Base.rte")
		if Effect then
			Effect.Pos = self.Pos + Offset
			Effect.Vel = ((self.Vel*-1) + Vector(RangeRand(-100,100), RangeRand(-20,20))) / 10
			MovableMan:AddParticle(Effect)
		end
	end

	if math.random(100) > 99 then
		local Effect = CreateMOSParticle("Explosion Smoke 2 Glow")
		if Effect then
			Effect.Pos = self.Pos + Offset
			Effect.Vel = ((self.Vel*-1) + Vector(RangeRand(-20,20), RangeRand(-20,20))) / 10
			MovableMan:AddParticle(Effect)
		end
	end
	if math.random(100) > 99 then
		local Effect = CreateMOSParticle("Explosion Smoke 1")
		if Effect then
			Effect.Pos = self.Pos + Offset
			Effect.Vel = ((self.Vel*-1) + Vector(RangeRand(-20,20), RangeRand(-20,20))) / 10
			MovableMan:AddParticle(Effect)
		end
	end
end