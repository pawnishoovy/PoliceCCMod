function Create(self)

	self.parentSet = false;
	
	-- Sounds --
	self.reflectionSound = CreateSoundContainer("Reflection Liberator", "Heat.rte");
	
	self.rocketInPrepareSound = CreateSoundContainer("RocketInPrepare Liberator", "Heat.rte");
	
	self.rocketInSound = CreateSoundContainer("RocketIn Liberator", "Heat.rte");
	
	self.boltBackPrepareSound = CreateSoundContainer("BoltBackPrepare Liberator", "Heat.rte");
	
	self.boltBackSound = CreateSoundContainer("BoltBack Liberator", "Heat.rte");
	
	self.boltForwardSound = CreateSoundContainer("BoltForward Liberator", "Heat.rte");
	
	self.outSlowSound = CreateSoundContainer("Out Slow Liberator", "Heat.rte");
	
	self.outSlowClunkSound = CreateSoundContainer("Out Slow Clunk Liberator", "Heat.rte");
	
	self.inSlowSound = CreateSoundContainer("In Slow Liberator", "Heat.rte");
	
	self.inSlowClunkSound = CreateSoundContainer("In Slow Clunk Liberator", "Heat.rte");
	
	self.lastAge = self.Age
	
	self.originalSharpLength = self.SharpLength
	
	self.originalStanceOffset = Vector(math.abs(self.StanceOffset.X), self.StanceOffset.Y)
	self.originalSharpStanceOffset = Vector(self.SharpStanceOffset.X, self.SharpStanceOffset.Y)
	
	self.rotation = 0
	self.rotationTarget = 0
	self.rotationSpeed = 9
	
	self.horizontalAnim = 0
	self.verticalAnim = 0
	
	self.angVel = 0
	self.lastRotAngle = self.RotAngle
	
	self.smokeTimer = Timer();
	self.smokeDelayTimer = Timer();
	self.canSmoke = false
	
	
	self.ammoCount = 5;	
	
	self.mechanismState = 0;
	-- 0: inside (launching upwards)
	-- 1: outside (launching forwards)
	
	self.environmentDetectionTimer = Timer();
	self.environmentDetectionDelay = 500;
	
	self.mechanismSwitchTimer = Timer();
	self.mechanismSwitchOutDelay = 400;
	self.mechanismSwitchInDelay = 300;
	self.mechanismSwitchActiveDelay = 0;
	
	self.mechanismSwitching = false;
	
	
	self.reloadTimer = Timer();
	
	self.rocketInPrepareDelay = 890;
	self.rocketInAfterDelay = 50;
	self.boltBackPrepareDelay = 850;
	self.boltBackAfterDelay = 330;
	self.boltForwardPrepareDelay = 330;
	self.boltForwardAfterDelay = 250;
	
	-- phases:
	-- 0 rocketIn
	-- 1 boltback
	-- 2 boltforward
	
	self.reloadPhase = 0;
	
	self.BaseReloadTime = 99999;
	
	-- Progressive Recoil System 
	self.recoilAcc = 0 -- for sinous
	self.recoilStr = 0 -- for accumulator
	self.recoilStrength = 13 -- multiplier for base recoil added to the self.recoilStr when firing
	self.recoilPowStrength = 1.0 -- multiplier for self.recoilStr when firing
	self.recoilRandomUpper = 2 -- upper end of random multiplier (1 is lower)
	self.recoilDamping = 0.3
	
	self.recoilMax = 5 -- in deg.
	self.originalSharpLength = self.SharpLength
	-- Progressive Recoil System 
	
	self.targetingLaser = true
	self.targetingLaserTimer = Timer();
	self.targetingLaserDelay = 70;
	self.targetingPos = Vector(self.Pos.X, self.Pos.Y)
	self.targetingMOUniqueID = -1
end

function Update(self)
	self.rotationTarget = 0 -- ZERO IT FIRST AAAA!!!!!
	
	if self.ID == self.RootID then
		self.parent = nil;
		self.parentSet = false;
	elseif self.parentSet == false then
		local actor = MovableMan:GetMOFromID(self.RootID);
		if actor and IsAHuman(actor) then
			self.parent = ToAHuman(actor);
			self.parentSet = true;
		end
	end
	
	-- mechanism stuff
	
	if self.mechanismSwitching == true then
		
		if self.mechanismState == 1 then
			if self.mechanismSwitchTimer:IsPastSimMS(self.mechanismSwitchActiveDelay) then
				self.Frame = 0;
			elseif self.mechanismSwitchTimer:IsPastSimMS(self.mechanismSwitchActiveDelay / 5 * 4) then
				self.Frame = 1;
			elseif self.mechanismSwitchTimer:IsPastSimMS(self.mechanismSwitchActiveDelay / 5 * 3) then
				self.Frame = 2;
			elseif self.mechanismSwitchTimer:IsPastSimMS(self.mechanismSwitchActiveDelay / 5 * 2) then
				self.Frame = 3;
			elseif self.mechanismSwitchTimer:IsPastSimMS(self.mechanismSwitchActiveDelay / 5 * 1) then
				self.Frame = 4;
			end
		else
			if self.mechanismSwitchTimer:IsPastSimMS(self.mechanismSwitchActiveDelay) then
				self.Frame = 4;
			elseif self.mechanismSwitchTimer:IsPastSimMS(self.mechanismSwitchActiveDelay / 5 * 4) then
				self.Frame = 3;
			elseif self.mechanismSwitchTimer:IsPastSimMS(self.mechanismSwitchActiveDelay / 5 * 3) then
				self.Frame = 2;
			elseif self.mechanismSwitchTimer:IsPastSimMS(self.mechanismSwitchActiveDelay / 5 * 2) then
				self.Frame = 1;
			elseif self.mechanismSwitchTimer:IsPastSimMS(self.mechanismSwitchActiveDelay / 5 * 1) then
				self.Frame = 0;
			end
		end
		
		if self.mechanismSwitchTimer:IsPastSimMS(self.mechanismSwitchActiveDelay) then
			if self.mechanismState == 1 then
				self.mechanismState = 0;
				self.inSlowClunkSound:Play(self.Pos);
			else
				self.mechanismState = 1;
				self.outSlowClunkSound:Play(self.Pos);
			end
			self.mechanismSwitching = false;
		end
	else
		if self.mechanismState == 1 then
			self.Frame = 4;
		else
			self.Frame = 0
		end
	end
	
	if self.parent then		
		if self.environmentDetectionTimer:IsPastSimMS(self.environmentDetectionDelay) then
		
			self.environmentDetectionTimer:Reset();
		
			local outdoorRays = 0;
			
			local indoorRays = 0;

			local Vector2 = Vector(0,-700); -- straight up		
			local Vector2SlightLeft = Vector(0,-700):RadRotate(22.5*(math.pi/180));
			local Vector2SlightRight = Vector(0,-700):RadRotate(-22.5*(math.pi/180));		
			local Vector3 = Vector(0,0); -- dont need this but is needed as an arg
			local Vector4 = Vector(0,0); -- dont need this but is needed as an arg

			self.ray = SceneMan:CastObstacleRay(self.Pos, Vector2, Vector3, Vector4, self.RootID, self.Team, 128, 7);
			self.raySlightRight = SceneMan:CastObstacleRay(self.Pos, Vector2SlightRight, Vector3, Vector4, self.RootID, self.Team, 128, 7);
			self.raySlightLeft = SceneMan:CastObstacleRay(self.Pos, Vector2SlightLeft, Vector3, Vector4, self.RootID, self.Team, 128, 7);
			
			self.rayTable = {self.ray, self.raySlightRight, self.raySlightLeft};
			
			for _, rayLength in ipairs(self.rayTable) do
				if rayLength < 0 then
					outdoorRays = outdoorRays + 1;
				else
					indoorRays = indoorRays + 1;
				end
			end
			
			-- trajectory check!
			local trajectoryObscured = true
			
			if not self:IsReloading() then
				local VectorT1 = Vector(0,-110):RadRotate(self.RotAngle);
				local VectorT2 = SceneMan:ShortestDistance(self.Pos + VectorT1, self.targetingPos, SceneMan.SceneWrapsX);
				
				VectorT2:SetMagnitude(math.max(VectorT2.Magnitude - 15, 0))
				
				--PrimitiveMan:DrawLinePrimitive(self.Pos, self.Pos + VectorT1, 5);
				
				local rayT1 = SceneMan:CastStrengthRay(self.Pos, VectorT1, 30, Vector(), 5, 0, SceneMan.SceneWrapsX);
				if rayT1 == false then
					--PrimitiveMan:DrawLinePrimitive(self.Pos + VectorT1, self.Pos + VectorT1 + VectorT2, 5);
					
					local rayT2 = SceneMan:CastStrengthRay(self.Pos + VectorT1, VectorT2, 30, Vector(), 5, 0, SceneMan.SceneWrapsX);
					if rayT2 == false then
						trajectoryObscured = false
					end
				end
			else
				trajectoryObscured = false
			end
			
			if outdoorRays == 3 and not trajectoryObscured then
				if self.mechanismState == 1 then
					self.mechanismSwitchTimer:Reset();
					self.mechanismSwitching = true;
					self.mechanismSwitchActiveDelay = self.mechanismSwitchInDelay;
					self.inSlowSound:Play(self.Pos);
				end
			else
				if self.mechanismState == 0 then
					self.mechanismSwitchTimer:Reset();
					self.mechanismSwitching = true;
					self.mechanismSwitchActiveDelay = self.mechanismSwitchOutDelay;
					self.outSlowSound:Play(self.Pos);
				end
			end
		end
	end
				
	
    -- Smoothing
    local min_value = -math.pi;
    local max_value = math.pi;
    local value = self.RotAngle - self.lastRotAngle
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
    
    self.lastRotAngle = self.RotAngle
    self.angVel = (result / TimerMan.DeltaTimeSecs) * self.FlipFactor
    
    if self.lastHFlipped ~= nil then
        if self.lastHFlipped ~= self.HFlipped then
            self.lastHFlipped = self.HFlipped
            self.angVel = 0
        end
    else
        self.lastHFlipped = self.HFlipped
    end
	
	-- PAWNIS RELOAD ANIMATION HERE
	if self:IsReloading() then
	
		local ctrl = self.parent:GetController();
		local screen = ActivityMan:GetActivity():ScreenOfPlayer(ctrl.Player);
	
		if self.Reloading ~= true then
			self.Reloading = true;
			self.reloadCycle = true;
			self.BaseReloadTime = 99999;
		end

		if self.reloadPhase == 0 then
			self.reloadDelay = self.rocketInPrepareDelay;
			self.afterDelay = self.rocketInAfterDelay;			
			self.prepareSound = self.rocketInPrepareSound;
			self.afterSound = self.rocketInSound;
			
			self.rotationTarget = 5;
			
			
		elseif self.reloadPhase == 1 then
			self.reloadDelay = self.boltBackPrepareDelay;
			self.afterDelay = self.boltBackAfterDelay;
			self.prepareSound = self.boltBackPrepareSound;
			self.afterSound = self.boltBackSound;

			self.rotationTarget = 5;
		
		elseif self.reloadPhase == 2 then
			self.reloadDelay = self.boltForwardPrepareDelay;
			self.afterDelay = self.boltForwardAfterDelay;
			self.prepareSound = nil;
			self.afterSound = self.boltForwardSound;
			
			self.rotationTarget = 2;
			
			self.Frame = self.Frame + 10
		end
		self.rotationTarget = self.rotationTarget + -30
		
		if self.prepareSoundPlayed ~= true then
			self.prepareSoundPlayed = true;
			if self.prepareSound then
				self.prepareSound:Play(self.Pos);
			end
		end
	
		if self.reloadTimer:IsPastSimMS(self.reloadDelay) then
		
			if self.reloadPhase == 0 then
			
				if self.parent:GetController():IsState(Controller.WEAPON_FIRE) then
					self.reloadCycle = false;
					PrimitiveMan:DrawTextPrimitive(screen, self.parent.AboveHUDPos + Vector(0, 30), "Interrupting...", true, 1);
				end
			
			elseif self.reloadPhase == 1 then
			
				if self.parent:GetController():IsState(Controller.WEAPON_FIRE) then
					self.reloadCycle = false;
					PrimitiveMan:DrawTextPrimitive(screen, self.parent.AboveHUDPos + Vector(0, 30), "Interrupting...", true, 1);
				end
			
				if self.reloadTimer:IsPastSimMS(self.reloadDelay + self.afterDelay / 5 * 2) then
					self.Frame = self.Frame + 10;
				elseif self.reloadTimer:IsPastSimMS(self.reloadDelay + self.afterDelay / 5 * 1) then
					self.Frame = self.Frame + 5;
				end

			elseif self.reloadPhase == 2 then
			
				if self.parent:GetController():IsState(Controller.WEAPON_FIRE) then
					self.reloadCycle = false;
					PrimitiveMan:DrawTextPrimitive(screen, self.parent.AboveHUDPos + Vector(0, 30), "Interrupting...", true, 1);
				end
			
				if self.reloadTimer:IsPastSimMS(self.reloadDelay + self.afterDelay / 5 * 0.6) then
					self.Frame = self.Frame - 10;
				elseif self.reloadTimer:IsPastSimMS(self.reloadDelay + self.afterDelay / 5 * 0.3) then
					self.Frame = self.Frame - 5;
				end
			end
			
			if self.afterSoundPlayed ~= true then
			
				if self.reloadPhase == 0 then
					self.phaseOnStop = 1;
					
					self.angVel = self.angVel + 2;
					self.verticalAnim = self.verticalAnim + 1
					
				elseif self.reloadPhase == 1 then
				
					self.phaseOnStop = 2;

					self.angVel = self.angVel - 2;
					self.verticalAnim = self.verticalAnim - 1	
					
				elseif self.reloadPhase == 2 then
					self.horizontalAnim = self.horizontalAnim - 1;
					self.angVel = self.angVel - 2;
				
					if self.ammoCount < 5 then
						self.ammoCount = self.ammoCount + 1;
						if self.ammoCount == 5 then
							self.reloadCycle = false;
						end
					else
						self.reloadCycle = false;
					end
					
					self.phaseOnStop = nil;
				else
					self.phaseOnStop = nil;
				end
			
				self.afterSoundPlayed = true;
				if self.afterSound then
					self.afterSound:Play(self.Pos);
				end
			end
			if self.reloadTimer:IsPastSimMS(self.reloadDelay + self.afterDelay) then
				self.reloadTimer:Reset();
				self.afterSoundPlayed = false;
				self.prepareSoundPlayed = false;
				if self.reloadPhase == 2 then
					if self.reloadCycle == true then
						self.reloadPhase = 0; -- keep reloading
					else
						self.BaseReloadTime = 0;
						self.reloadPhase = 0;
						self.Reloading = false;
					end
				else
					self.reloadPhase = self.reloadPhase + 1;
				end
			end
		end		
	else
		self.reloadTimer:Reset();
		self.afterSoundPlayed = false;
		self.prepareSoundPlayed = false;
		if self.phaseOnStop then
			self.reloadPhase = self.phaseOnStop;
			self.phaseOnStop = nil;
		end
		self.BaseReloadTime = 99999;
	end
	
	if self:DoneReloading() == true then
		self.Magazine.RoundCount = self.ammoCount;
	end
	
	-- PAWNIS RELOAD ANIMATION HERE
	
	-- Laser
	-- Tactical Laser!!
	if self.parent and not self:IsReloading() then
		local offset = Vector(3 * self.FlipFactor, 3):RadRotate(self.RotAngle)
		local point = self.Pos + offset
		
		--PrimitiveMan:DrawCirclePrimitive(point, 1, 13);
		PrimitiveMan:DrawLinePrimitive(point, point, 13);
		
		if self.targetingLaserTimer:IsPastSimMS(self.targetingLaserDelay) then
			local glow = CreateMOPixel("Mine Laser Particle");
			glow.Pos = point;
			MovableMan:AddParticle(glow);
			
			local rayVec = Vector(700 * self.FlipFactor, 0):RadRotate(self.RotAngle)
			
			local endPos = point + rayVec; -- This value is going to be overriden by function below, this is the end of the ray
			self.ray = SceneMan:CastObstacleRay(point, rayVec, Vector(0, 0), endPos, self.parent.ID, self.Team, 0, 2) -- Do the hitscan stuff, raycast
			local vec = SceneMan:ShortestDistance(point,endPos,SceneMan.SceneWrapsX);
			
			local moCheckPos = endPos + Vector(rayVec.X, rayVec.Y):SetMagnitude(math.random(1,2))
			local moCheck = SceneMan:GetMOIDPixel(moCheckPos.X, moCheckPos.Y);
			if moCheck ~= 255 then
				self.targetingMOID = MovableMan:GetMOFromID(moCheck).UniqueID
			else
				self.targetingMOID = nil
			end
			
			self.targetingPos = Vector(endPos.X, endPos.Y)
			
			--PrimitiveMan:DrawLinePrimitive(point, point + vec, 13);
			if self.parent:IsPlayerControlled() then
				if self.ray > 0 then
					local glow = CreateMOPixel("Mine Laser Particle");
					glow.Pos = endPos;
					MovableMan:AddParticle(glow);
					
					glow = CreateMOPixel("Mine Laser Particle");
					glow.Pos = endPos;
					MovableMan:AddParticle(glow);
					PrimitiveMan:DrawLinePrimitive(endPos, endPos, 13);
				end
				
				local maxi = vec.Magnitude / GetPPM() * 1.5
				for i = 1, maxi do
					if math.random(1,3) >= 2 then
						local glow = CreateMOPixel("Mine Laser Beam "..math.random(1,3));
						glow.Pos = point + vec * math.max(math.min((1 / maxi * i) + RangeRand(-1.0,1.0) * 0.03, 1), 0);
						glow.EffectRotAngle = self.RotAngle;
						MovableMan:AddParticle(glow);
					end
				end
			end
			
			self.targetingLaserTimer:Reset()
		end
	end
	
	if self.FiredFrame then
		--self.angVel = self.angVel - RangeRand(0.7,1.1) * 15
		
		if self.mechanismState == 0 then
			self.Missile = CreateAEmitter("Projectile Liberator", "Heat.rte")
			self.Missile.Pos = self.Pos + Vector(-7 * self.FlipFactor, -8):RadRotate(self.RotAngle);
			self.Missile.Vel = self.Vel + Vector(0,-20):RadRotate(self.RotAngle)
			self.Missile.RotAngle = self.Missile.Vel.AbsRadAngle
			self.Missile.Team = self.parent.Team
			self.Missile.IgnoresTeamHits = true
			self.Missile:SetNumberValue("TargetMode", 1)
			self.Missile:SetNumberValue("TargetX", self.targetingPos.X)
			self.Missile:SetNumberValue("TargetY", self.targetingPos.Y)
			if self.targetingMOID then
				self.Missile:SetNumberValue("TargetID", self.targetingMOID)
			end
			
			MovableMan:AddParticle(self.Missile)
		else
			self.Missile = CreateAEmitter("Projectile Liberator", "Heat.rte")
			self.Missile.Pos = self.MuzzlePos;
			self.Missile.Vel = self.Vel + Vector(15*self.FlipFactor,-2):RadRotate(self.RotAngle)
			self.Missile.RotAngle = self.Missile.Vel.AbsRadAngle
			self.Missile.Team = self.parent.Team
			self.Missile.IgnoresTeamHits = true
			self.Missile:SetNumberValue("TargetMode", 0)
			self.Missile:SetNumberValue("TargetX", self.targetingPos.X)
			self.Missile:SetNumberValue("TargetY", self.targetingPos.Y)
			if self.targetingMOID then
				self.Missile:SetNumberValue("TargetID", self.targetingMOID)
			end
			
			MovableMan:AddParticle(self.Missile)
			
			self.canSmoke = true
			self.smokeTimer:Reset()
		end
		
		if self.Magazine then
			self.ammoCount = 0 + self.Magazine.RoundCount; -- +0 to avoid reference bullshit and save it as a number properly
			if self.ammoCount == 0 then
				self:Reload();
			end
		end
		
		for i = 1, 2 do
			local Effect = CreateMOSParticle("Tiny Smoke Ball 1", "Base.rte")
			if Effect then
				Effect.Pos = self.MuzzlePos;
				Effect.Vel = (self.Vel + Vector(RangeRand(-20,20), RangeRand(-20,20)) + Vector(150*self.FlipFactor,0):RadRotate(self.RotAngle)) / 30
				MovableMan:AddParticle(Effect)
			end
		end
		
		local Effect = CreateMOSParticle("Side Thruster Blast Ball 1", "Base.rte")
		if Effect then
			Effect.Pos = self.MuzzlePos;
			Effect.Vel = (self.Vel + Vector(150*self.FlipFactor,0):RadRotate(self.RotAngle)) / 10
			MovableMan:AddParticle(Effect)
		end

		local outdoorRays = 0;
		
		local indoorRays = 0;
		
		local bigIndoorRays = 0;

		if self.parent and self.parent:IsPlayerControlled() then
			self.rayThreshold = 2; -- this is the first ray check to decide whether we play outdoors
			local Vector2 = Vector(0,-700); -- straight up
			local Vector2Left = Vector(0,-700):RadRotate(45*(math.pi/180));
			local Vector2Right = Vector(0,-700):RadRotate(-45*(math.pi/180));			
			local Vector2SlightLeft = Vector(0,-700):RadRotate(22.5*(math.pi/180));
			local Vector2SlightRight = Vector(0,-700):RadRotate(-22.5*(math.pi/180));		
			local Vector3 = Vector(0,0); -- dont need this but is needed as an arg
			local Vector4 = Vector(0,0); -- dont need this but is needed as an arg

			self.ray = SceneMan:CastObstacleRay(self.Pos, Vector2, Vector3, Vector4, self.RootID, self.Team, 128, 7);
			self.rayRight = SceneMan:CastObstacleRay(self.Pos, Vector2Right, Vector3, Vector4, self.RootID, self.Team, 128, 7);
			self.rayLeft = SceneMan:CastObstacleRay(self.Pos, Vector2Left, Vector3, Vector4, self.RootID, self.Team, 128, 7);			
			self.raySlightRight = SceneMan:CastObstacleRay(self.Pos, Vector2SlightRight, Vector3, Vector4, self.RootID, self.Team, 128, 7);
			self.raySlightLeft = SceneMan:CastObstacleRay(self.Pos, Vector2SlightLeft, Vector3, Vector4, self.RootID, self.Team, 128, 7);
			
			self.rayTable = {self.ray, self.rayRight, self.rayLeft, self.raySlightRight, self.raySlightLeft};
		else
			self.rayThreshold = 1; -- has to be different for AI
			local Vector2 = Vector(0,-700); -- straight up
			local Vector3 = Vector(0,0); -- dont need this but is needed as an arg
			local Vector4 = Vector(0,0); -- dont need this but is needed as an arg		
			self.ray = SceneMan:CastObstacleRay(self.Pos, Vector2, Vector3, Vector4, self.RootID, self.Team, 128, 7);
			
			self.rayTable = {self.ray};
		end
		
		for _, rayLength in ipairs(self.rayTable) do
			if rayLength < 0 then
				outdoorRays = outdoorRays + 1;
			elseif rayLength > 170 then
				bigIndoorRays = bigIndoorRays + 1;
			else
				indoorRays = indoorRays + 1;
			end
		end
		
		if outdoorRays >= self.rayThreshold then
			self.reflectionSound:Play(self.Pos);
		end
	end
	
	-- Animation
	if self.parent then
		self.horizontalAnim = math.floor(self.horizontalAnim / (1 + TimerMan.DeltaTimeSecs * 24.0) * 1000) / 1000
		self.verticalAnim = math.floor(self.verticalAnim / (1 + TimerMan.DeltaTimeSecs * 15.0) * 1000) / 1000
		
		local stance = Vector()
		stance = stance + Vector(-1,0) * self.horizontalAnim -- Horizontal animation
		stance = stance + Vector(0,5) * self.verticalAnim -- Vertical animation
		
		self.rotationTarget = self.rotationTarget - (self.angVel * 4)
		
		-- Progressive Recoil Update
		if self.FiredFrame then
			self.recoilStr = self.recoilStr + ((math.random(10, self.recoilRandomUpper * 10) / 10) * 0.5 * self.recoilStrength) + (self.recoilStr * 0.6 * self.recoilPowStrength)
			self:SetNumberValue("recoilStrengthBase", self.recoilStrength * (1 + self.recoilPowStrength) / self.recoilDamping)
		end
		self:SetNumberValue("recoilStrengthCurrent", self.recoilStr)
		
		self.recoilStr = math.floor(self.recoilStr / (1 + TimerMan.DeltaTimeSecs * 8.0 * self.recoilDamping) * 1000) / 1000
		self.recoilAcc = (self.recoilAcc + self.recoilStr * TimerMan.DeltaTimeSecs) % (math.pi * 4)
		
		local recoilA = (math.sin(self.recoilAcc) * self.recoilStr) * 0.05 * self.recoilStr
		local recoilB = (math.sin(self.recoilAcc * 0.5) * self.recoilStr) * 0.01 * self.recoilStr
		local recoilC = (math.sin(self.recoilAcc * 0.25) * self.recoilStr) * 0.05 * self.recoilStr
		
		local recoilFinal = math.max(math.min(recoilA + recoilB + recoilC, self.recoilMax), -self.recoilMax)
		
		self.SharpLength = math.max(self.originalSharpLength - (self.recoilStr * 3 + math.abs(recoilFinal)), 0)
		
		self.rotationTarget = self.rotationTarget + recoilFinal -- apply the recoil
		-- Progressive Recoil Update		
		
		self.rotation = (self.rotation + self.rotationTarget * TimerMan.DeltaTimeSecs * self.rotationSpeed) / (1 + TimerMan.DeltaTimeSecs * self.rotationSpeed)
		local total = math.rad(self.rotation) * self.FlipFactor
		
		self.InheritedRotAngleOffset = total * self.FlipFactor;
		-- self.RotAngle = self.RotAngle + total;
		-- self:SetNumberValue("MagRotation", total);
		
		-- local jointOffset = Vector(self.JointOffset.X * self.FlipFactor, self.JointOffset.Y):RadRotate(self.RotAngle);
		-- local offsetTotal = Vector(jointOffset.X, jointOffset.Y):RadRotate(-total) - jointOffset
		-- self.Pos = self.Pos + offsetTotal;
		-- self:SetNumberValue("MagOffsetX", offsetTotal.X);
		-- self:SetNumberValue("MagOffsetY", offsetTotal.Y);
		
		self.StanceOffset = Vector(self.originalStanceOffset.X, self.originalStanceOffset.Y) + stance
		self.SharpStanceOffset = Vector(self.originalSharpStanceOffset.X, self.originalSharpStanceOffset.Y) + stance
	end
	
	if self.canSmoke and not self.smokeTimer:IsPastSimMS(1500) then

		if self.smokeDelayTimer:IsPastSimMS(120) then
			
			local poof = CreateMOSParticle("Tiny Smoke Ball 1");
			poof.Pos = self.Pos + Vector(self.MuzzleOffset.X * self.FlipFactor, self.MuzzleOffset.Y):RadRotate(self.RotAngle);
			poof.Lifetime = poof.Lifetime * RangeRand(0.3, 1.3) * 0.9;
			poof.Vel = self.Vel * 0.1
			poof.GlobalAccScalar = RangeRand(0.9, 1.0) * -0.4; -- Go up and down
			MovableMan:AddParticle(poof);
			self.smokeDelayTimer:Reset()
		end
	end
end