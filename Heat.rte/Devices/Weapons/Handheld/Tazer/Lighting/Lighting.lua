function DrawCircleDir(pos, radius, dir)
    PrimitiveMan:DrawCirclePrimitive(pos, radius, 5);
	PrimitiveMan:DrawLinePrimitive(pos, pos + Vector(radius, 0):RadRotate(dir),  13);
end

function Create(self)
	-- yup
	if self.FlipFactor == -1 then	
		self.RotAngle = self.RotAngle - math.rad(180);
	end
	local glow = CreateMOPixel("Tazer Lighting Glow 2");
	glow.Pos = self.Pos;
	MovableMan:AddParticle(glow);
	
	--self.lightingHitSound = CreateSoundContainer("Lighting Hit Taser", "Heat.rte");
	
	self.pointCount = math.floor(500 * RangeRand(0.9,1.1) + 0.5);	-- Number of points
	self.spiralScale = 10 * RangeRand(0.85,1.15);	-- Size of the spiral
	self.skipPoints = 5;
	self.skipDegreeRange = 35 * RangeRand(0.9,1.1)
	
	self.detectedPoints = {}
	
	for i = self.skipPoints, self.pointCount - 1 do
		local radius = self.spiralScale * math.sqrt(i);
		local angle = i * 137.508;
		local checkVec = Vector(radius, 0):DegRotate(angle)
		local checkPos = self.Pos + checkVec + Vector(5, 0):RadRotate(self.RotAngle);
		
		local min_value = -math.pi;
		local max_value = math.pi;
		local value = self.RotAngle - checkVec.AbsRadAngle
		local result;
		local ret = 0
		
		local range = max_value - min_value;
		if range <= 0 then
			result = min_value;
		else
			ret = (value - min_value) % range;
			if ret < 0 then ret = ret + range end
			result = ret + min_value;
		end
		
		if math.abs(result * (1 + (radius / 100)) * 0.5) < math.rad(self.skipDegreeRange) then
			
			if SceneMan.SceneWrapsX == true then
				if checkPos.X > SceneMan.SceneWidth then
					checkPos = Vector(checkPos.X - SceneMan.SceneWidth, checkPos.Y);
				elseif checkPos.X < 0 then
					checkPos = Vector(SceneMan.SceneWidth + checkPos.X, checkPos.Y);
				end
			end
			local color = 254;
			local terrCheck = SceneMan:GetTerrMatter(checkPos.X, checkPos.Y);
			local moCheck = SceneMan:GetMOIDPixel(checkPos.X, checkPos.Y);
			
			local mo = moCheck ~= 255 and MovableMan:GetMOFromID(moCheck)
			if moCheck ~= 255 and (mo.Team ~= self.Team) then
				color = 122;
				if terrCheck ~= 0 then
					color = 149;
				end
				
				local score = 5 / SceneMan:ShortestDistance(self.Pos, checkPos, SceneMan.SceneWrapsX).Magnitude
				table.insert(self.detectedPoints, {Vector(checkPos.X, checkPos.Y), score, moCheck})
			elseif terrCheck ~= 0 then
				color = 5;
				
				local score = 1 / SceneMan:ShortestDistance(self.Pos, checkPos, SceneMan.SceneWrapsX).Magnitude
				table.insert(self.detectedPoints, {Vector(checkPos.X, checkPos.Y), score, nil})
			end
			--PrimitiveMan:DrawLinePrimitive(checkPos, checkPos, color);
			
		end
	end
	
	-- Pick best point
	self.targetPos = self.Pos + Vector(self.spiralScale * 13 * RangeRand(0.8,1.2), 0):RadRotate(self.RotAngle + RangeRand(-1,1) * 0.35)
	local hit = false
	local hitPos = Vector(self.Pos.X, self.Pos.Y)
	local hitMO = nil
	
	if #self.detectedPoints > 0 then
		local lastScore = 0
		for i, point in ipairs(self.detectedPoints) do
			local score = point[2]
			if lastScore < score then
				self.targetPos = point[1]
				lastScore = score
				
				hitPos = Vector(self.targetPos.X, self.targetPos.Y)
				
				if point[3] ~= nil then
					hitMO = point[3]
				end
				hit = true
			end
		end
		
	end
	
	-- GFX
	local dif = SceneMan:ShortestDistance(self.Pos, self.targetPos, SceneMan.SceneWrapsX)
	local maxi = math.floor((dif.Magnitude * 0.25))
	
	local lastPos = self.Pos
	
	local midpoint = Vector(self.spiralScale * 3 * RangeRand(0.8,1.2), 0):RadRotate(self.RotAngle) + Vector(RangeRand(-1,1), RangeRand(-1,1)) * 20
	for i = 1, maxi do
		local fac = i / maxi
		local facRev = 1 - fac
		
		local p1 = Vector(0, 0)
		local p2 = midpoint
		local p3 = dif
		
		
		local pos = self.Pos + (p1 * math.pow(1 - fac, 2) + p2 * 2 * (1 - fac) * fac + p3 * math.pow(fac, 2)) + Vector(RangeRand(-1,1), RangeRand(-1,1)) * 3
		local glow = CreateMOPixel("Tazer Lighting Glow "..math.random(1,3));
		glow.Pos = pos;
		MovableMan:AddParticle(glow);
		
		local glow = CreateMOPixel("Tazer Lighting Glow "..math.random(1,3));
		glow.Pos = lastPos + SceneMan:ShortestDistance(lastPos, pos, SceneMan.SceneWrapsX) * 0.5
		MovableMan:AddParticle(glow);
		
		PrimitiveMan:DrawLinePrimitive(lastPos, pos, 187);
		
		if fac > 0.5 or fac < 0.2 then
			if SceneMan:GetTerrMatter(pos.X, pos.Y) ~= 0 then
				hitPos = Vector(lastPos.X, lastPos.Y)
				hitMO = nil
				break
			end
		end
		lastPos = pos
	end
	
	-- Damage
	if hitMO ~= nil then
		hitMO = MovableMan:GetMOFromID(hitMO)
		if IsMOSRotating(hitMO) then hitMO = ToMOSRotating(hitMO) end
		if IsAttachable(hitMO) then hitMO = ToAttachable(hitMO) end
		
		local parent = hitMO:GetRootParent()
		local actor = ((parent ~= nil and IsActor(parent)) and parent) or (IsActor(hitMO) and hitMO)
		if actor and actor.ClassName ~= "ADoor" then
			actor = ToActor(actor)
			if math.random(1,4) < 2 and actor.PinStrength < 1 then
				actor:FlashWhite(36)
				actor.Pos = actor.Pos + Vector(RangeRand(-1,1), RangeRand(-1,1)) * 2
				actor.Vel = actor.Vel + Vector(RangeRand(-1,1), RangeRand(-1,1))
				
			end
			
			local wound = CreateAEmitter(actor:GetEntryWoundPresetName(), PresetMan:GetDataModule(actor.ModuleID).FileName);
			local mult = 0.33 + math.max(0, 0.20 * (3 - wound.BurstDamage)) -- lessen the impact of low burstdamage
			local damage = wound.BurstDamage * mult * math.random(1,3) / actor.Radius * 14
			if actor:IsMechanical() then
				damage = damage * 1.5;
			end
			--print(damage)
			actor.Health = actor.Health - damage;
		end
	end
	
	-- Hit GFX
	if hit then
		if math.random(1,7) < 2 then
		self.explosion = CreateAEmitter("Heat.rte/Lighting Hit Effect");
		self.explosion.Pos = hitPos;
		self.explosion.RotAngle = self.RotAngle;
		self.explosion.Team = self.Team;
		MovableMan:AddParticle(self.explosion);
		end
		
		local spark = CreateMOPixel("Spark Tazer 1");
		spark.Pos = hitPos + Vector(RangeRand(-1, 1), RangeRand(-1, 1))
		spark.Vel = Vector(RangeRand(-1, 1), RangeRand(-1, 1)) * 15
		spark.Lifetime = spark.Lifetime * RangeRand(0.8, 1.2) * math.random(1,3)
		MovableMan:AddParticle(spark);
	end
end

function Update(self)
	self.ToDelete = true
end