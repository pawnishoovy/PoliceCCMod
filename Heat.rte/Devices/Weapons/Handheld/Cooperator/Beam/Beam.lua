
function Create(self)

	self.beamHitSound = CreateSoundContainer("Beam Hit Cooperator", "Heat.rte");

	local glow = CreateMOPixel("Glow Cooperator Beam Extra");
	glow.Pos = self.Pos;
	MovableMan:AddParticle(glow);
	
	self.lastPos = Vector(self.Pos.X, self.Pos.Y);
	self.hits = 0;
	
	self.cast = true;
	self.castLength = 700;
	
	self.lSpw = 0;
	self.lSpwMax = 3;
end

function Update(self)
	self.Vel = Vector();
	
	if self.cast then
		local step = self.castLength
		local endPos = Vector(self.Pos.X, self.Pos.Y); -- This value is going to be overriden by function below, this is the end of the ray
		self.ray = SceneMan:CastObstacleRay(self.Pos, Vector(1, 0):RadRotate(self.RotAngle) * step, Vector(0, 0), endPos, 0 , self.Team, 0, 1) -- Do the hitscan stuff, raycast
		
		local travel = SceneMan:ShortestDistance(self.Pos,endPos,SceneMan.SceneWrapsX);
		--PrimitiveMan:DrawLinePrimitive(self.Pos, self.Pos + travel, 13);
		self.Pos = endPos
		self.cast = false
		
		local travel = SceneMan:ShortestDistance(self.Pos,self.lastPos,SceneMan.SceneWrapsX);
		local travelMagnitude = travel.Magnitude
		
		if travelMagnitude > 5 then
			local maxi = travelMagnitude / GetPPM() * 5
			for i = 0, maxi do
				--PrimitiveMan:DrawCirclePrimitive(self.Pos + travel / maxi * i, 2 + i / maxi * 3, math.floor(154 + 3 / maxi * i));
				
				local glow = CreateMOPixel("Glow Cooperator Beam "..math.random(1,5));
				glow.Pos = self.Pos + travel * math.max(math.min(1 / maxi * i, 1), 0);
				--glow.Vel = travel:SetMagnitude(30)
				glow.EffectRotAngle = self.RotAngle;
				MovableMan:AddParticle(glow);
				
				--local glowExtra = CreateMOPixel("Glow Cooperator Beam Extra");
				--glowExtra.Pos = self.Pos + travel * math.max(math.min(1 / maxi * i, 1), 0);
				--MovableMan:AddParticle(glowExtra);
			end
			
		end
	elseif not (self.hits > 0 and self.hits < 2) then
		self.ToDelete = true
		return
	end
	
	
	if (self.ray > -1 or self.hits > 0) and self.hits < 2 then
		
		local glow = CreateMOPixel("Glow Cooperator Beam Extra");
		glow.Pos = self.Pos;
		MovableMan:AddParticle(glow);
		if (self.hits >= 1 and math.random(1,2) < 2) or self.hits < 1 then
			local pixel = CreateMOPixel("Cooperator Beam Damage 1");
			pixel.Vel = Vector(1, 0):RadRotate(self.RotAngle) * 70;
			pixel.Pos = self.Pos - Vector(2, 0):RadRotate(self.RotAngle);
			pixel.Team = self.Team -- It doesn't work, somehow
			pixel.IgnoresTeamHits = true;
			MovableMan:AddParticle(pixel);
		end
		
		local smoke = CreateMOSParticle("Tiny Smoke Ball 1");
		smoke.Pos = self.Pos - Vector(2, 0):RadRotate(self.RotAngle);
		smoke.Vel = Vector(-1, 0):RadRotate(self.RotAngle + RangeRand(-0.3,0.3)) * RangeRand(0.4, 16);
		smoke.Lifetime = smoke.Lifetime * RangeRand(0.6, 1.6) * 0.9; -- Randomize lifetime
		smoke.GlobalAccScalar = RangeRand(-0.1, 0.1)
		MovableMan:AddParticle(smoke);
		
		local smoke = CreateMOPixel("Drop Oil");
		smoke.Pos = self.Pos - Vector(2, 0):RadRotate(self.RotAngle);
		smoke.Vel = Vector(-1, 0):RadRotate(self.RotAngle + RangeRand(-0.3,0.3)) * RangeRand(0.2, 26);
		smoke.Lifetime = 1000 * RangeRand(0.1, 1.0); -- Randomize lifetime
		MovableMan:AddParticle(smoke);
		
		local smoke = CreateMOPixel("Spark Yellow "..math.random(1,2));
		smoke.Pos = self.Pos - Vector(2, 0):RadRotate(self.RotAngle);
		smoke.Vel = Vector(-1, 0):RadRotate(self.RotAngle + RangeRand(-0.8,0.8)) * RangeRand(7, 45);
		smoke.Lifetime = 700 * RangeRand(0.1, 1.0); -- Randomize lifetime
		MovableMan:AddParticle(smoke);
		
		self.hits = self.hits + 1;
		if self.hits == 1 then
			--AudioMan:PlaySound("FGround.rte/Effects/Special/Lasers/Sounds/LaserDissipate"..math.random(1,3)..".wav", self.Pos);
			if math.random(1,3) < 2 then
				self.beamHitSound:Play(self.Pos);
			end
			
			local smoke = CreateMOSParticle("Small Smoke Ball 1");
			smoke.Pos = self.Pos - Vector(2, 0):RadRotate(self.RotAngle);
			smoke.Vel = Vector(-1, 0):RadRotate(self.RotAngle + RangeRand(-0.3,0.3)) * RangeRand(0.4, 8);
			smoke.Lifetime = smoke.Lifetime * RangeRand(0.6, 1.6) * 0.5; -- Randomize lifetime
			smoke.GlobalAccScalar = RangeRand(-0.1, 0.1)
			MovableMan:AddParticle(smoke);
			
		end
		
	end
	
end