function Create(self)

	self.parentSet = false;

	-- Sounds --
	self.reflectionSound = CreateSoundContainer("Reflection CLIER", "Heat.rte");
	
	self.boltBackPrepareSound = CreateSoundContainer("BoltBackPrepare CLIER", "Heat.rte");
	
	self.boltBackSound = CreateSoundContainer("BoltBack CLIER", "Heat.rte");
	
	self.boltLockSound = CreateSoundContainer("BoltLock CLIER", "Heat.rte");
	
	self.magOutSound = CreateSoundContainer("MagOut CLIER", "Heat.rte");
	
	self.magInPrepareSound = CreateSoundContainer("MagInPrepare CLIER", "Heat.rte");
	
	self.magInSound = CreateSoundContainer("MagIn CLIER", "Heat.rte");
	
	self.boltSlapSound = CreateSoundContainer("BoltSlap CLIER", "Heat.rte");
	
	self.laserOnSound = CreateSoundContainer("Laser On CLIER", "Heat.rte");
	
	self.laserOffSound = CreateSoundContainer("Laser Off CLIER", "Heat.rte");
	
	self.flashPreSound = CreateSoundContainer("Flash Pre CLIER", "Heat.rte");
	
	self.flashSound = CreateSoundContainer("Flash CLIER", "Heat.rte");
	
	self.flashEmptySound = CreateSoundContainer("Flash Empty CLIER", "Heat.rte");
	
	self.flashRechargeSound = CreateSoundContainer("Flash Recharge CLIER", "Heat.rte");
	
	self.originalStanceOffset = Vector(math.abs(self.StanceOffset.X), self.StanceOffset.Y)
	self.originalSharpStanceOffset = Vector(self.SharpStanceOffset.X, self.SharpStanceOffset.Y)
	
	self.rotation = 0
	self.rotationTarget = 0
	self.rotationSpeed = 5
	
	self.horizontalAnim = 0
	self.verticalAnim = 0
	
	self.angVel = 0
	self.lastRotAngle = self.RotAngle
	
	self.smokeTimer = Timer();
	self.smokeDelayTimer = Timer();
	self.canSmoke = false
	
	self.flashActivated = false;
	self.flashFiring = false;
	self.flashLoaded = true;
	
	self.flashChargeTimer = Timer();
	self.flashFireTimer = Timer();
	
	self.flashFireTimeMS = 130;
	self.flashChargeTimeMS = 10000;
	
	self.flashHUDReady = false
	self.flashHUDTimer = Timer()	
	
	self.reloadTimer = Timer();
	
	self.boltBackPrepareDelay = 600;
	self.boltBackAfterDelay = 100;
	self.boltLockPrepareDelay = 150;
	self.boltLockAfterDelay = 100;
	self.magOutPrepareDelay = 500;
	self.magOutAfterDelay = 100;
	self.magInPrepareDelay = 900;
	self.magInAfterDelay = 500;
	self.boltSlapPrepareDelay = 400;
	self.boltSlapAfterDelay = 100;
	
	-- phases:
	-- 0 boltback
	-- 1 boltlock
	-- 2 magout
	-- 3 magin
	-- 4 boltslap (boltforward)
	
	self.reloadPhase = 2;
	
	self.ReloadTime = 9999;

	local actor = MovableMan:GetMOFromID(self.RootID);
	if actor and IsAHuman(actor) then
		self.parent = ToAHuman(actor);
	end
	
	-- Progressive Recoil System 
	self.recoilAcc = 0 -- for sinous
	self.recoilStr = 0 -- for accumulator
	self.recoilStrength = 5 -- multiplier for base recoil added to the self.recoilStr when firing
	self.recoilPowStrength = 0.1 -- multiplier for self.recoilStr when firing
	self.recoilRandomUpper = 1.3 -- upper end of random multiplier (1 is lower)
	self.recoilDamping = 1.0
	
	self.recoilMax = 2 -- in deg.
	self.originalSharpLength = self.SharpLength
	-- Progressive Recoil System 
	
	self.targetingLaser = true
	self.targetingLaserTimer = Timer();
	self.targetingLaserDelay = 70;
	self.targetingPos = Vector(self.Pos.X, self.Pos.Y)
	self.targetingMOUniqueID = -1	
end

function Update(self)

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
	--PrimitiveMan:DrawTextPrimitive(self.Pos + Vector(-20, 20), "Angular Velocity = "..self.angVel, true, 0);
	--PrimitiveMan:DrawLinePrimitive(self.Pos, self.Pos + Vector(15 * self.FlipFactor,0):RadRotate(self.RotAngle),  13);
	--PrimitiveMan:DrawLinePrimitive(self.Pos, self.Pos + Vector(15 * self.FlipFactor,0):RadRotate(self.RotAngle + (self.angVel * 0.05)),  5);
	
	if self:IsReloading() then
		if self.parent then
			self.parent:GetController():SetState(Controller.AIM_SHARP,false);
		end
		--[[
		if not self:NumberValueExists("MagRemoved") and self.parent:IsPlayerControlled() then
			local color = (self.reloadPhase == 2 and 105 or 120)
			local offset = Vector(0, 36)
			local position = self.parent.AboveHUDPos + offset
			
			local mini = 0
			local maxi = 4
			
			local lastVecA = Vector(0, 0)
			local lastVecB = Vector(0, 0)
			
			local bend = math.rad(9)
			local step = 2.5
			local width = 2
			
			position = position + Vector(0, step * maxi * -0.5)
			for i = mini, maxi do
				
				local vecA = Vector(width, 0):RadRotate(bend * i) + Vector(0, step * i):RadRotate(bend * i)
				local vecB = Vector(-width, 0):RadRotate(bend * i) + Vector(0, step * i):RadRotate(bend * i)
				
				-- Jitter fix
				vecA = Vector(math.floor(vecA.X), math.floor(vecA.Y))
				vecB = Vector(math.floor(vecB.X), math.floor(vecB.Y))
				position = Vector(math.floor(position.X), math.floor(position.Y))
				
				if i ~= mini then
					PrimitiveMan:DrawLinePrimitive(position + vecA, position + lastVecA, color);
					PrimitiveMan:DrawLinePrimitive(position + vecB, position + lastVecB, color);
				end
				if i == mini or i == maxi then
					PrimitiveMan:DrawLinePrimitive(position + vecA, position + vecB, color);
				end
				
				lastVecA = Vector(vecA.X, vecA.Y)
				lastVecB = Vector(vecB.X, vecB.Y)
			end
		end]]
	
		
		if self.reloadPhase == 0 then
			self.reloadDelay = self.boltBackPrepareDelay;
			self.afterDelay = self.boltBackAfterDelay;
			
			self.prepareSound = self.boltBackPrepareSound;
			self.afterSound = self.boltBackSound;
			
			self.rotationTarget = -5 * self.reloadTimer.ElapsedSimTimeMS / (self.reloadDelay + self.afterDelay)

		elseif self.reloadPhase == 1 then
			self.reloadDelay = self.boltLockPrepareDelay;
			self.afterDelay = self.boltLockAfterDelay;
			
			self.prepareSound = nil;
			self.afterSound = self.boltLockSound;
			
			self.rotationTarget = -5 * self.reloadTimer.ElapsedSimTimeMS / (self.reloadDelay + self.afterDelay)				
		
		elseif self.reloadPhase == 2 then
			self.reloadDelay = self.magOutPrepareDelay;
			self.afterDelay = self.magOutAfterDelay;
			
			self.prepareSound = nil;
			self.afterSound = self.magOutSound;
			
			self.rotationTarget = -5 * self.reloadTimer.ElapsedSimTimeMS / (self.reloadDelay + self.afterDelay)
			
		elseif self.reloadPhase == 3 then
			self.reloadDelay = self.magInPrepareDelay;
			self.afterDelay = self.magInAfterDelay;
			
			self.prepareSound = self.magInPrepareSound;
			self.afterSound = self.magInSound;
			
			self.rotationTarget = 15-- * self.reloadTimer.ElapsedSimTimeMS / (self.reloadDelay + self.afterDelay)
			
		elseif self.reloadPhase == 4 then
			self.reloadDelay = self.boltSlapPrepareDelay;
			self.afterDelay = self.boltSlapAfterDelay;
			
			self.prepareSound = nil;
			self.afterSound = self.boltSlapSound;
			
			self.rotationTarget = 15-- * self.reloadTimer.ElapsedSimTimeMS / (self.reloadDelay + self.afterDelay)
			
		end
		
		if self.prepareSoundPlayed ~= true then
			self.prepareSoundPlayed = true;
			if self.prepareSound then
				self.prepareSound:Play(self.Pos);
			end
		end
	
		if self.reloadTimer:IsPastSimMS(self.reloadDelay) then
		
			if self.reloadPhase == 0 then
				if self.reloadTimer:IsPastSimMS(self.reloadDelay + ((self.afterDelay/5)*1.2)) then
					self.Frame = 2;
				elseif self.reloadTimer:IsPastSimMS(self.reloadDelay + ((self.afterDelay/5)*0.6)) then
					self.Frame = 1;
				elseif self.reloadTimer:IsPastSimMS(self.reloadDelay + ((self.afterDelay/5)*0.3)) then
					self.Frame = 0;
				end
				self.phaseOnStop = 0;
			elseif self.reloadPhase == 1 then
				self.Frame = 3;
				self.phaseOnStop = 2;
				self.boltLockedBack = true;
			elseif self.reloadPhase == 2 then
				self.phaseOnStop = nil;
				self:SetNumberValue("MagRemoved", 1);
			elseif self.reloadPhase == 3 then
				self:RemoveNumberValue("MagRemoved");
			elseif self.reloadPhase == 4 then
				if self.reloadTimer:IsPastSimMS(self.reloadDelay + ((self.afterDelay/5)*0.5)) then
					self.Frame = 0;
					self.rotationTarget = -10
				elseif self.reloadTimer:IsPastSimMS(self.reloadDelay + ((self.afterDelay/5)*0.4)) then
					self.Frame = 1;
				elseif self.reloadTimer:IsPastSimMS(self.reloadDelay + ((self.afterDelay/5)*0.3)) then
					self.Frame = 2;
				else
					self.Frame = 3;
					self.rotationTarget = -15
				end
			end
			
			if self.afterSoundPlayed ~= true then
			
				if self.reloadPhase == 2 then
					local fake
					fake = CreateMOSRotating("Fake Magazine MOSRotating CLIER");
					fake.Pos = self.Pos + Vector(0, 2):RadRotate(self.RotAngle);
					fake.Vel = self.Vel + Vector(0.5*self.FlipFactor, 3):RadRotate(self.RotAngle);
					fake.RotAngle = self.RotAngle;
					fake.AngularVel = self.AngularVel + (-1*self.FlipFactor);
					fake.HFlipped = self.HFlipped;
					MovableMan:AddParticle(fake);
					
					self.verticalAnim = self.verticalAnim + 1
				elseif self.reloadPhase == 3 then
					if self.chamberOnReload then
						
					else
						self.ReloadTime = 0; -- done! no after delay if non-chambering reload.
						self.reloadPhase = 2;
					end
					self:RemoveNumberValue("MagRemoved");
					
					self.verticalAnim = self.verticalAnim - 1
				end
				
				if self.reloadPhase == 0 then
					self.horizontalAnim = self.horizontalAnim + 1
				elseif self.reloadPhase == 4 then
					self.horizontalAnim = self.horizontalAnim - 1
				end
			
				self.afterSoundPlayed = true;
				if self.afterSound then
					self.afterSound:Play(self.Pos);
				end
			end
			if self.reloadTimer:IsPastSimMS(self.reloadDelay + self.afterDelay) then
				self.reloadTimer:Reset();
				self.prepareSoundPlayed = false;
				self.afterSoundPlayed = false;
				if self.chamberOnReload and self.reloadPhase == 4 then
					self.ReloadTime = 0;
					self.reloadPhase = 2;
					self.boltLockedBack = false;
				elseif (not self.chamberOnReload) and self.reloadPhase == 3 then
					self.ReloadTime = 0;
					self.reloadPhase = 2;
					self.boltLockedBack = false;
				else
					self.reloadPhase = self.reloadPhase + 1;
				end
			end
		end
	else
		self.rotationTarget = 0
		if self.boltLockedBack == true then
			self.Frame = 3;
		else
			self.Frame = 0;
		end
		if self.phaseOnStop then
			self.reloadPhase = self.phaseOnStop;
			self.phaseOnStop = nil;
		end		
		self.reloadTimer:Reset();
		self.prepareSoundPlayed = false;
		self.afterSoundPlayed = false;
		self.ReloadTime = 9999;
	end
	
	if self:DoneReloading() == true and self.chamberOnReload then
		self.Magazine.RoundCount = 30;
		self.chamberOnReload = false;
	elseif self:DoneReloading() then
		self.Magazine.RoundCount = 31;
		self.chamberOnReload = false;
	end
	
	if self.flashActivated and self.flashLoaded and (not self.flashFiring) and (not self:IsReloading()) then
	
		self.flashActivated = false;
		self.flashLoaded = false;
		self.flashFiring = true;
		
		self.flashPreSound:Play(self.Pos);
		
		self.flashFireTimer:Reset();
		self.flashChargeTimer:Reset();
		
	end
	
	if self.flashFiring and self.flashFireTimer:IsPastSimMS(self.flashFireTimeMS) then
		
		-- Flash
		local rayVec = Vector(75 * self.FlipFactor, 0):RadRotate(self.RotAngle)
		
		local endPos = self.MuzzlePos + rayVec; -- This value is going to be overriden by function below, this is the end of the ray
		local ray = SceneMan:CastObstacleRay(self.MuzzlePos, rayVec, Vector(0, 0), endPos, self.parent.ID, self.Team, 0, 2) -- Do the hitscan stuff, raycast
		--local vec = SceneMan:ShortestDistance(point,endPos,SceneMan.SceneWrapsX);
		
		local Effect = CreateMOPixel("Flash Glow CLIER", "Heat.rte")
		if Effect then
			Effect.Pos = self.MuzzlePos;
			--Effect.Vel = (self.Vel + Vector(RangeRand(-20,20), RangeRand(-20,20)) + Vector(150*self.FlipFactor,0):RadRotate(self.RotAngle)) / 30
			MovableMan:AddParticle(Effect)
		end
		
		for i = 0, math.random(3,6) do
			local Effect = CreateMOPixel("Flash Glow CLIER", "Heat.rte")
			if Effect then
				Effect.Pos = self.MuzzlePos + Vector(math.random(15,50) * self.FlipFactor, 0):RadRotate(self.RotAngle + math.rad(RangeRand(-45,45)));
				MovableMan:AddParticle(Effect)
			end
		end
		
		local Flash = CreateMOPixel("Flash CLIER", "Heat.rte")
		if Flash then
			Flash.Pos = endPos;
			Flash.Vel = Vector(45,0)
			Flash.Team = self.Team
			MovableMan:AddParticle(Flash)
		end
		
		self.flashSound:Play(self.Pos);
		
		self.flashFiring = false;
		self.flashLoaded = false;
		
	end
	
	
	if self.flashLoaded == false then
	
		if self.flashChargeTimer:IsPastSimMS(self.flashChargeTimeMS) then
			self.flashLoaded = true;
			self.flashRechargeSound:Play(self.Pos);
			
			self.flashHUDReady = true
			self.flashHUDTimer:Reset()
		end
		
	end
	
	if self.FiredFrame then	
		self.canSmoke = true
		self.smokeTimer:Reset()
		
		self.horizontalAnim = self.horizontalAnim + 0.2
		self.angVel = self.angVel + RangeRand(0,1) * 3

		if self.Magazine then
			if self.Magazine.RoundCount > 0 then	
				self.reloadPhase = 2;
			else
				self.chamberOnReload = true;
				self.reloadPhase = 0;
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
	
	
		local ctrl = self.parent:GetController();
		local screen = ActivityMan:GetActivity():ScreenOfPlayer(ctrl.Player);
		if self.parent:IsPlayerControlled() and (ctrl:IsState(Controller.PIE_MENU_ACTIVE) or (self.flashHUDReady and not self.flashHUDTimer:IsPastSimMS(1000))) then
			local pos = self.parent.AboveHUDPos + Vector(0, 24)
			
			if self.flashHUDReady and not ctrl:IsState(Controller.PIE_MENU_ACTIVE) and not self.flashHUDTimer:IsPastSimMS(2000) then
				PrimitiveMan:DrawTextPrimitive(screen, pos + Vector(0, 10), "Flash Ready!", true, 1);
			elseif self.flashLoaded then
				PrimitiveMan:DrawTextPrimitive(screen, pos, "Flash: Ready", true, 1);
				PrimitiveMan:DrawTextPrimitive(screen, pos + Vector(0, 10), "Press V to fire", true, 1);
			else
				PrimitiveMan:DrawTextPrimitive(screen, pos, "Flash: Loading...", true, 1);
			end
		end
		
		self.horizontalAnim = math.floor(self.horizontalAnim / (1 + TimerMan.DeltaTimeSecs * 12.0) * 1000) / 1000
		self.verticalAnim = math.floor(self.verticalAnim / (1 + TimerMan.DeltaTimeSecs * 8.0) * 1000) / 1000
		
		local stance = Vector()
		stance = stance + Vector(-5,0) * self.horizontalAnim -- Horizontal animation
		stance = stance + Vector(0,6) * self.verticalAnim -- Vertical animation
		
		self.rotationTarget = self.rotationTarget + (self.angVel * 3)
		
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
		
		self.RotAngle = self.RotAngle + total;
		self:SetNumberValue("MagRotation", total);
		
		local jointOffset = Vector(self.JointOffset.X * self.FlipFactor, self.JointOffset.Y):RadRotate(self.RotAngle);
		local offsetTotal = Vector(jointOffset.X, jointOffset.Y):RadRotate(-total) - jointOffset
		self.Pos = self.Pos + offsetTotal;
		self:SetNumberValue("MagOffsetX", offsetTotal.X);
		self:SetNumberValue("MagOffsetY", offsetTotal.Y);
		
		self.StanceOffset = Vector(self.originalStanceOffset.X, self.originalStanceOffset.Y) + stance
		self.SharpStanceOffset = Vector(self.originalSharpStanceOffset.X, self.originalSharpStanceOffset.Y) + stance
		
		if self.parent:IsPlayerControlled() then
			if UInputMan:KeyPressed(8) then
				if self.laserOn == true then
					self.laserOn = false;
					self.laserOffSound:Play(self.Pos);
				else
					self.laserOn = true;
					self.laserOnSound:Play(self.Pos);
				end												
			end
		end
		
		local fire = false
		if self.parent:IsPlayerControlled() then
			if UInputMan:KeyPressed(22) then
				fire = true
			end
		elseif self.Magazine then -- AI
			if self.flashLoaded == true and not self:IsReloading() and self.Magazine.UniqueID % 3 == 0 and self.Magazine.Age > 500 and ctrl:IsState(Controller.WEAPON_FIRE) == true then -- Hacks
				fire = true
			end
		end
		
		if fire then
			if self.flashLoaded == true and not self:IsReloading() then
			  self.flashActivated = true;
			else
				self.flashEmptySound:Play(self.Pos);
			end
		end
		
		-- Laser
		-- Tactical Laser!!
		if self.laserOn == true then
			local offset = Vector(3 * self.FlipFactor, 0):RadRotate(self.RotAngle)
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