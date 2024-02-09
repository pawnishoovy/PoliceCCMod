function Create(self)

	self.startSound = CreateSoundContainer("Time Nade Start", "Heat.rte");
	
	self.bounceSound = CreateSoundContainer("Grenade Bounce Heat", "Heat.rte");
	self.rollSound = CreateSoundContainer("Grenade Roll Heat", "Heat.rte");

	self.activateTimer = Timer();
	self.activateDelay = 2000
	
	self.deactivateTimer = Timer();
	self.deactivateDelay = 10000
	
	self.range = 160
	
	self.timeFactor = (1 - 0.02)
	
	self.glowSpawnTimer = Timer();
	
	self.lastVel = Vector(self.Vel.X, self.Vel.Y)
	
	self.impulse = Vector()
	self.bounceSoundTimer = Timer()	
	
	self.active = false
end

function Update(self)

	self.impulse = (self.Vel - self.lastVel) / TimerMan.DeltaTimeSecs * self.Vel.Magnitude * 0.1
	self.lastVel = Vector(self.Vel.X, self.Vel.Y)

	if self.active then
		--PrimitiveMan:DrawCirclePrimitive(self.Pos, self.range, 5)
		
		-- for mo in MovableMan.Particles do
			-- if mo and mo.PinStrength < 1 and (mo.HitsMOs == true or math.random(1,3) <= 2) then
				-- local distance = SceneMan:ShortestDistance(self.Pos, mo.Pos + mo.Vel * GetPPM() * TimerMan.DeltaTimeSecs, SceneMan.SceneWrapsX).Magnitude
				
				-- if distance < self.range then
					-- local distanceFactor = math.sqrt(math.max(self.range - (distance * 0.3), 0) / self.range)
					-- local timeFactor = self.timeFactor * distanceFactor
					
					-- --PrimitiveMan:DrawCirclePrimitive(mo.Pos, 1, 5)
					-- if mo.Lifetime and mo.Lifetime > 0 and mo.ClassName ~= "AEmitter" and mo.ClassName ~= "MOSRotating" and mo.ClassName ~= "Actor" then
						-- mo.Lifetime = mo.Lifetime + TimerMan.DeltaTimeSecs * 700 * timeFactor
					-- end
					-- --mo.Pos = mo.Pos - mo.Vel * GetPPM() * TimerMan.DeltaTimeSecs * timeFactor
					-- mo.Vel = mo.Vel - SceneMan.GlobalAcc * TimerMan.DeltaTimeSecs * 0.5 * mo.GlobalAccScalar * distanceFactor
				-- end
			-- end
		-- end
		
		for mo in MovableMan:GetMOsInRadius(self.Pos, self.range, Activity.NOTEAM, false) do
			if mo and mo.PinStrength == 0 and mo.ClassName ~= "ADoor" and mo.ClassName ~= "ACraft" and mo.UniqueID ~= self.UniqueID then
				local distance = SceneMan:ShortestDistance(self.Pos, mo.Pos + mo.Vel * GetPPM() * TimerMan.DeltaTimeSecs, SceneMan.SceneWrapsX).Magnitude
				
				if distance < (self.range + mo.Radius) then
					local distanceFactor = math.sqrt(math.max(self.range - (distance * 0.3), 0) / self.range)
					local timeFactor = self.timeFactor * distanceFactor
					
					if mo.Lifetime and mo.Lifetime > 0 and mo.ClassName ~= "AEmitter" and mo.ClassName ~= "MOSRotating" and mo.ClassName ~= "Actor" then
						mo.Lifetime = mo.Lifetime + TimerMan.DeltaTimeSecs
					end
					
					--PrimitiveMan:DrawCirclePrimitive(mo.Pos, 3, 5)
					mo.Pos = mo.Pos - mo.Vel * GetPPM() * TimerMan.DeltaTimeSecs * timeFactor
					mo.Vel = mo.Vel - (SceneMan.GlobalAcc*2) * TimerMan.DeltaTimeSecs * 0.5 * mo.GlobalAccScalar * distanceFactor
					
					if self.glowSpawnTimer:IsPastSimMS(65) and math.random(1,4) < 2 and IsActor(mo) then
						ToActor(mo).Health = ToActor(mo).Health - TimerMan.DeltaTimeSecs
					end
				end
			end
			if mo.PresetName == self.PresetName and mo.UniqueID ~= self.UniqueID and ToMOSRotating(mo):NumberValueExists("Active") then
				local distance = SceneMan:ShortestDistance(self.Pos, mo.Pos + mo.Vel * GetPPM() * TimerMan.DeltaTimeSecs, SceneMan.SceneWrapsX).Magnitude
				if distance < self.range * 2 then
					self:GibThis();
				end
			end
		end
		
		if self.glowSpawnTimer:IsPastSimMS(65) then
			for i = 0, math.random(4,12) do
				local glow = CreateMOPixel("Time Nade Glow "..math.random(1,2));
				glow.Pos = self.Pos + Vector(math.random(0,self.range), 0):RadRotate(math.pi * 2 * RangeRand(1,0));
				MovableMan:AddParticle(glow);
			end
			
			self.glowSpawnTimer:Reset()
		end
		--[[
		for actor in MovableMan.Actors do
			if actor.PinStrength < 1 and actor.ClassName ~= "ADoor" and actor.ClassName ~= "ACraft" then
				local distance = SceneMan:ShortestDistance(self.Pos, actor.Pos + actor.Vel * GetPPM() * TimerMan.DeltaTimeSecs, SceneMan.SceneWrapsX).Magnitude
				if distance < (self.range + actor.Radius) then
					--PrimitiveMan:DrawCirclePrimitive(mo.Pos, 3, 5)
					--mo.Lifetime = mo.Lifetime + TimerMan.DeltaTimeSecs * 1000 * self.timeFactor
					actor.Pos = actor.Pos - actor.Vel * GetPPM() * TimerMan.DeltaTimeSecs * self.timeFactor
					actor.Vel = actor.Vel - SceneMan.GlobalAcc * TimerMan.DeltaTimeSecs * 0.5
				end
			end
		end]]
		
		if self.deactivateTimer:IsPastSimMS(self.deactivateDelay) then
			self:GibThis()
		end
	else
		self.deactivateTimer:Reset()
		if self:IsActivated() then
			if self.activateTimer:IsPastSimMS(self.activateDelay) then
				self.Frame = 1
				self.active = true
				
				self:SetNumberValue("Active", 1)
				
				local emitter = CreateAEmitter("Time Nade Emitter")
				emitter.Lifetime = self.deactivateDelay
				self:AddAttachable(emitter);
				
				self.startSound:Play(self.Pos);
			end
		else
			self.activateTimer:Reset()
		end
	end
end

function OnCollideWithTerrain(self, terrainID)
	if self.bounceSoundTimer:IsPastSimMS(50) then
		if self.impulse.Magnitude > 25 then -- Hit
			self.bounceSound:Play(self.Pos);
			self.bounceSoundTimer:Reset()
		elseif self.impulse.Magnitude > 11 then -- Roll
			self.rollSound:Play(self.Pos);
			self.bounceSoundTimer:Reset()
		end
	end
end