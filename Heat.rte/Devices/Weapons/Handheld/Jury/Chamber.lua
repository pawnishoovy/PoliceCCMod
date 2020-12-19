function Create(self)

	self.parentSet = false;
	
	-- Sounds --
	self.addSounds = {["Loop"] = nil};
	self.addSounds.Loop = {["Variations"] = 3,
	["Path"] = "Heat.rte/Devices/Weapons/Handheld/Jury/CompliSound/Add"};
	
	self.mechSounds = {["Loop"] = nil};
	self.mechSounds.Loop = {["Variations"] = 3,
	["Path"] = "Heat.rte/Devices/Weapons/Handheld/Jury/CompliSound/Mech"};

	self.reflectionSounds = {["Outdoors"] = nil};
	self.reflectionSounds.Outdoors = {["Variations"] = 3,
	["Path"] = "Heat.rte/Devices/Weapons/Handheld/Jury/CompliSound/Reflection"};
	
	self.shrapnelAddSounds = {["Loop"] = nil};
	self.shrapnelAddSounds.Loop = {["Variations"] = 3,
	["Path"] = "Heat.rte/Devices/Weapons/Handheld/Jury/CompliSound/ShrapnelAdd"};
	
	self.shrapnelMechSounds = {["Loop"] = nil};
	self.shrapnelMechSounds.Loop = {["Variations"] = 3,
	["Path"] = "Heat.rte/Devices/Weapons/Handheld/Jury/CompliSound/ShrapnelMech"};

	self.shrapnelReflectionSounds = {["Outdoors"] = nil};
	self.shrapnelReflectionSounds.Outdoors = {["Variations"] = 3,
	["Path"] = "Heat.rte/Devices/Weapons/Handheld/Jury/CompliSound/ShrapnelReflection"};
	
	self.shrapnelPreSounds = {["Variations"] = 3,
	["Path"] = "Heat.rte/Devices/Weapons/Handheld/Jury/CompliSound/ShrapnelPre"};
	
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
	
	self.reloadTimer = Timer();
	
	
	self.canShrapnel = false;
	self.shrapnelThreshold = 40;
	self.shrapnelFireTimer = Timer();
	self.shrapnelFireTimeMS = 100;
	self.shrapnelActivated = false;
	self.shrapnelFiring = false;
	
	self.shrapnelAnimTimer = Timer();
	self.shrapnelUnreadyPlayed = true;
	
	self.shrapnelHUDReady = false
	self.shrapnelHUDTimer = Timer()
	
	self.magOutPrepareDelay = 1000;
	self.magOutAfterDelay = 1000;
	self.magInPrepareDelay = 900;
	self.magInAfterDelay = 200;
	self.magHitPrepareDelay = 480;
	self.magHitAfterDelay = 800;
	self.boltBackPrepareDelay = 500;
	self.boltBackAfterDelay = 300;
	self.boltForwardPrepareDelay = 300;
	self.boltForwardAfterDelay = 400;
	
	-- phases:
	-- 0 magout
	-- 1 magin
	-- 2 maghit
	-- 3 boltback
	-- 4 boltforward
	
	self.reloadPhase = 0;
	
	self.ReloadTime = 9999;
	
	-- Progressive Recoil System 
	self.recoilAcc = 0 -- for sinous
	self.recoilStr = 0 -- for accumulator
	self.recoilStrength = 14 -- multiplier for base recoil added to the self.recoilStr when firing
	self.recoilPowStrength = 0.1 -- multiplier for self.recoilStr when firing
	self.recoilRandomUpper = 2 -- upper end of random multiplier (1 is lower)
	self.recoilDamping = 1.2
	
	self.recoilMax = 1 -- in deg.
	self.originalSharpLength = self.SharpLength
	-- Progressive Recoil System 
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
		
		self.Reloading = true;
		self.canShrapnel = false;

		if self.reloadPhase == 0 then
			self.reloadDelay = self.magOutPrepareDelay;
			self.afterDelay = self.magOutAfterDelay;			
			self.prepareSoundPath = 
			"Heat.rte/Devices/Weapons/Handheld/Jury/Sounds/MagOutPrepare";
			self.afterSoundPath = 
			"Heat.rte/Devices/Weapons/Handheld/Jury/Sounds/MagOut";
			
			self.rotationTarget = 5;
			
		elseif self.reloadPhase == 1 then
			self.reloadDelay = self.magInPrepareDelay;
			self.afterDelay = self.magInAfterDelay;
			self.prepareSoundPath = 
			"Heat.rte/Devices/Weapons/Handheld/Jury/Sounds/MagInPrepare";
			self.afterSoundPath = 
			"Heat.rte/Devices/Weapons/Handheld/Jury/Sounds/MagIn";
			
			self.rotationTarget = -3;
			
		elseif self.reloadPhase == 2 then
			self.reloadDelay = self.magHitPrepareDelay;
			self.afterDelay = self.magHitAfterDelay;
			self.prepareSoundPath = 
			"Heat.rte/Devices/Weapons/Handheld/Jury/Sounds/MagHitPrepare";
			self.afterSoundPath = 
			"Heat.rte/Devices/Weapons/Handheld/Jury/Sounds/MagHit";
			
			self.rotationTarget = -2;
			
		elseif self.reloadPhase == 3 then
			self.reloadDelay = self.boltBackPrepareDelay;
			self.afterDelay = self.boltBackAfterDelay;
			self.prepareSoundPath = 
			"Heat.rte/Devices/Weapons/Handheld/Jury/Sounds/BoltBackPrepare";	
			self.afterSoundPath = 
			"Heat.rte/Devices/Weapons/Handheld/Jury/Sounds/BoltBack";	

			self.rotationTarget = -4;
		
		elseif self.reloadPhase == 4 then
			self.reloadDelay = self.boltForwardPrepareDelay;
			self.afterDelay = self.boltForwardAfterDelay;
			self.prepareSoundPath = nil;
			self.afterSoundPath = 
			"Heat.rte/Devices/Weapons/Handheld/Jury/Sounds/BoltForward";
			
			self.rotationTarget = -3;
			
		end
		
		if self.prepareSoundPlayed ~= true then
			self.prepareSoundPlayed = true;
			if self.prepareSoundPath then
				self.prepareSound = AudioMan:PlaySound(self.prepareSoundPath .. ".ogg", self.Pos, -1, 0, 130, 1, 250, false);
			end
		end
	
		if self.reloadTimer:IsPastSimMS(self.reloadDelay) then
		
			if self.reloadPhase == 0 then
				self:SetNumberValue("MagRemoved", 1);
			elseif self.reloadPhase == 1 then
				self:RemoveNumberValue("MagRemoved");
			elseif self.reloadPhase == 3 then
			
				if self.shrapnelReload == true then
					if self.reloadTimer:IsPastSimMS(self.reloadDelay + ((self.afterDelay/5)*1.2)) then
						self.Frame = 9;
					elseif self.reloadTimer:IsPastSimMS(self.reloadDelay + ((self.afterDelay/5)*0.9)) then
						self.Frame = 8;
					elseif self.reloadTimer:IsPastSimMS(self.reloadDelay + ((self.afterDelay/5)*0.6)) then
						self.Frame = 7;
					end
				else
					if self.reloadTimer:IsPastSimMS(self.reloadDelay + ((self.afterDelay/5)*1.2)) then
						self.Frame = 3;
					elseif self.reloadTimer:IsPastSimMS(self.reloadDelay + ((self.afterDelay/5)*0.9)) then
						self.Frame = 2;
					elseif self.reloadTimer:IsPastSimMS(self.reloadDelay + ((self.afterDelay/5)*0.6)) then
						self.Frame = 1;
					end
				end

			elseif self.reloadPhase == 4 then
			
				if self.shrapnelReload == true then
					if self.reloadTimer:IsPastSimMS(self.reloadDelay + ((self.afterDelay/5)*1.2)) then
						self.Frame = 5;
					elseif self.reloadTimer:IsPastSimMS(self.reloadDelay + ((self.afterDelay/5)*0.9)) then
						self.Frame = 6;
					elseif self.reloadTimer:IsPastSimMS(self.reloadDelay + ((self.afterDelay/5)*0.6)) then
						self.Frame = 7;
					elseif self.reloadTimer:IsPastSimMS(self.reloadDelay + ((self.afterDelay/5)*0.3)) then
						self.Frame = 8;
					end
				else
					if self.reloadTimer:IsPastSimMS(self.reloadDelay + ((self.afterDelay/5)*1.2)) then
						self.Frame = 0;
					elseif self.reloadTimer:IsPastSimMS(self.reloadDelay + ((self.afterDelay/5)*0.9)) then
						self.Frame = 1;
					elseif self.reloadTimer:IsPastSimMS(self.reloadDelay + ((self.afterDelay/5)*0.6)) then
						self.Frame = 2;
					elseif self.reloadTimer:IsPastSimMS(self.reloadDelay + ((self.afterDelay/5)*0.3)) then
						self.Frame = 3;
					end
				end
				
			end
			
			if self.afterSoundPlayed ~= true then
			
				if self.reloadPhase == 0 then
					self.phaseOnStop = 1;
					local fake
					fake = CreateMOSRotating("Fake Magazine MOSRotating Jury");
					fake.Pos = self.Pos + Vector(1 * self.FlipFactor, 0):RadRotate(self.RotAngle);
					fake.Vel = self.Vel + Vector(0.5*self.FlipFactor, 3):RadRotate(self.RotAngle);
					fake.RotAngle = self.RotAngle;
					fake.AngularVel = self.AngularVel + (-1*self.FlipFactor);
					fake.HFlipped = self.HFlipped;
					MovableMan:AddParticle(fake);
					
					self.angVel = self.angVel + 2;
					self.verticalAnim = self.verticalAnim + 1
					
				elseif self.reloadPhase == 1 then
					self.phaseOnStop = 2;
					self.angVel = self.angVel - 2;
					self.verticalAnim = self.verticalAnim - 1	
					self:RemoveNumberValue("MagRemoved");
					
				elseif self.reloadPhase == 2 then
					if self.chamberOnReload then
						self.phaseOnStop = 3;
					else
						self.phaseOnStop = nil;
					end
					self.angVel = self.angVel - 5;
					self.verticalAnim = self.verticalAnim - 2	
					
				elseif self.reloadPhase == 3 then
					self.horizontalAnim = self.horizontalAnim - 1;
					self.angVel = self.angVel - 2;
				elseif self.reloadPhase == 4 then
					self.horizontalAnim = self.horizontalAnim + 1;
					self.angVel = self.angVel + 4;
					self.phaseOnStop = nil;
				else
					self.phaseOnStop = nil;
				end
			
				self.afterSoundPlayed = true;
				if self.afterSoundPath then
					self.afterSound = AudioMan:PlaySound(self.afterSoundPath .. ".ogg", self.Pos, -1, 0, 130, 1, 250, false);
				end
			end
			if self.reloadTimer:IsPastSimMS(self.reloadDelay + self.afterDelay) then
				self.reloadTimer:Reset();
				self.afterSoundPlayed = false;
				self.prepareSoundPlayed = false;
				-- reset recoils for firing normally just in case we shrapnelled
				self.recoilStrength = 14;
				self.recoilDamping = 1.2;
				if self.chamberOnReload and self.reloadPhase == 2 then
					self.reloadPhase = self.reloadPhase + 1;
				elseif self.reloadPhase == 2 or self.reloadPhase == 4 then
					self.ReloadTime = 0;
					self.reloadPhase = 0;
					self.Reloading = false;
					self.canShrapnel = false;
					if self.shrapnelReload == true then
						self.shrapnelReload = false;
						self.shrapnelUnreadyPlayed = false;
					else
						self.shrapnelUnreadyPlayed = true;
					end
				else
					self.reloadPhase = self.reloadPhase + 1;
				end
			end
		end		
	else
		
		if self.Reloading == true then
			if self.shrapnelReload == true then
				self.Frame = 5;
			else
				self.Frame = 0;
			end
		end
				
		self.reloadTimer:Reset();
		self.afterSoundPlayed = false;
		self.prepareSoundPlayed = false;
		if self.phaseOnStop then
			self.reloadPhase = self.phaseOnStop;
			self.phaseOnStop = nil;
		end
		self.ReloadTime = 9999;
	end
	
	if self:DoneReloading() == true and self.chamberOnReload then
		self.Magazine.RoundCount = 80
		self.chamberOnReload = false;
	elseif self:DoneReloading() then
		self.Magazine.RoundCount = 81
		self.chamberOnReload = false;
	end	
	
	if self.FiredFrame then
		self.angVel = self.angVel - RangeRand(0.7,1.1) * 5
		
		self.canSmoke = true
		self.smokeTimer:Reset()
		
		if self.Magazine then
			if self.Magazine.RoundCount > 0 then
				if self.canShrapnel == false and self.Magazine.RoundCount <= self.shrapnelThreshold then
					self.canShrapnel = true;
					self.shrapnelReadySound = AudioMan:PlaySound("Heat.rte/Devices/Weapons/Handheld/Jury/Sounds/ShrapnelReady" .. math.random(1, 3) .. ".ogg", self.Pos, -1, 0, 130, 1, 250, false);
					
					self.shrapnelAnimTimer:Reset();
					self.shrapnelReload = true;
					
					self.shrapnelHUDReady = true
					self.shrapnelHUDTimer:Reset()
				end
			else
				self.chamberOnReload = true;
			end
		end
		
		if self.reflectionSound then
			if self.reflectionSound:IsBeingPlayed() then
				self.reflectionSound:Stop(-1)
			end
		end
		
		if self.mechSound then
			if self.mechSound:IsBeingPlayed() then
				self.mechSound:Stop(-1)
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

		if self.parent:IsPlayerControlled() then
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
				
		self.mechSound = AudioMan:PlaySound(self.mechSounds.Loop.Path .. math.random(1, self.mechSounds.Loop.Variations) .. ".ogg", self.Pos, -1, 0, 130, 1, 250, false);	
		self.addSound = AudioMan:PlaySound(self.addSounds.Loop.Path .. math.random(1, self.addSounds.Loop.Variations) .. ".ogg", self.Pos, -1, 0, 130, 1, 450, false);
		
		if outdoorRays >= self.rayThreshold then
			self.reflectionSound = AudioMan:PlaySound(self.reflectionSounds.Outdoors.Path .. math.random(1, self.reflectionSounds.Outdoors.Variations) .. ".ogg", self.Pos, -1, 0, 130, 1, 450, false);
		end
	end
	
	if self.canShrapnel then	
		if self.shrapnelAnimTimer:IsPastSimMS(100) then
			self.Frame = 5;
		else
			self.Frame = 4;
		end
	elseif (not self.shrapnelReload) and (not self.Reloading) then
	
		if self.shrapnelUnreadyPlayed == false then
			self.shrapnelUnreadySound = AudioMan:PlaySound("Heat.rte/Devices/Weapons/Handheld/Jury/Sounds/ShrapnelUnready" .. math.random(1, 3) .. ".ogg", self.Pos, -1, 0, 130, 1, 250, false);
			self.shrapnelUnreadyPlayed = true;
		end
		
		if self.shrapnelAnimTimer:IsPastSimMS(100) then
			self.Frame = 0;
		else
			self.Frame = 4;
		end
	end
	
	if self.shrapnelActivated and self.canShrapnel and (not self.shrapnelFiring) and (not self:IsReloading()) then
	
		self.shrapnelActivated = false;
		self.shrapnelFiring = true;
		
		AudioMan:PlaySound(self.shrapnelPreSounds.Path .. math.random(1, self.shrapnelPreSounds.Variations) .. ".ogg", self.Pos, -1, 0, 130, 1, 450, false);
		
		self.shrapnelFireTimer:Reset();
		
	end
	
	if self.shrapnelFiring and self.shrapnelFireTimer:IsPastSimMS(self.shrapnelFireTimeMS) then
	
		if self.Magazine then
			if self.canShrapnel == true and self.Magazine.RoundCount > 0 then
			
				-- bang!
				
				self.shrapnelFired = true;
				self.canShrapnel = false;
				
				self.recoilStrength = 40;
				self.recoilDamping = 0.6;
				
				self.Frame = 5;
				self.angVel = self.angVel - RangeRand(0.7,1.1) * 15;
				
				self.canSmoke = true;
				self.smokeTimer:Reset();
				
				self.chamberOnReload = true;
				self.shrapnelReload = false;
				
				for i = 1, self.Magazine.RoundCount do
					local Bullet = CreateMOPixel("Particle Jury", "Heat.rte")
					Bullet.Pos = self.MuzzlePos;
					Bullet.Vel = self.Vel + (Vector(180*self.FlipFactor,0) + Vector(RangeRand(-20,20), RangeRand(-20,20))):RadRotate(self.RotAngle)
					Bullet.Team = self.parent.Team
					Bullet.IgnoresTeamHits = true
					MovableMan:AddParticle(Bullet);
				end
				
				self.Magazine.RoundCount = 0;
				
				if self.reflectionSound then
					if self.reflectionSound:IsBeingPlayed() then
						self.reflectionSound:Stop(-1)
					end
				end
				
				if self.mechSound then
					if self.mechSound:IsBeingPlayed() then
						self.mechSound:Stop(-1)
					end
				end
				
				for i = 1, 7 do
					local Effect = CreateMOSParticle("Tiny Smoke Ball 1", "Base.rte")
					if Effect then
						Effect.Pos = self.MuzzlePos;
						Effect.Vel = (self.Vel + Vector(RangeRand(-20,20), RangeRand(-20,20)) + Vector(150*self.FlipFactor,0):RadRotate(self.RotAngle)) / 20
						Effect.Lifetime = Effect.Lifetime * 3
						MovableMan:AddParticle(Effect)
					end
				end
				
				for i = 1, 3 do
					local Effect = CreateMOSParticle("Side Thruster Blast Ball 1", "Base.rte")
					if Effect then
						Effect.Pos = self.MuzzlePos;
						Effect.Vel = (self.Vel + Vector(RangeRand(-20,20), RangeRand(-20,20)) + Vector(150*self.FlipFactor,0):RadRotate(self.RotAngle)) / 10
						Effect.Lifetime = Effect.Lifetime * 3
						MovableMan:AddParticle(Effect)
					end
				end

				local outdoorRays = 0;
				
				local indoorRays = 0;
				
				local bigIndoorRays = 0;

				if self.parent:IsPlayerControlled() then
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
						
				self.mechSound = AudioMan:PlaySound(self.shrapnelMechSounds.Loop.Path .. math.random(1, self.shrapnelMechSounds.Loop.Variations) .. ".ogg", self.Pos, -1, 0, 130, 1, 250, false);	
				self.addSound = AudioMan:PlaySound(self.shrapnelAddSounds.Loop.Path .. math.random(1, self.shrapnelAddSounds.Loop.Variations) .. ".ogg", self.Pos, -1, 0, 130, 1, 450, false);
				
				if outdoorRays >= self.rayThreshold then
					self.reflectionSound = AudioMan:PlaySound(self.shrapnelReflectionSounds.Outdoors.Path .. math.random(1, self.shrapnelReflectionSounds.Outdoors.Variations) .. ".ogg", self.Pos, -1, 0, 130, 1, 450, false);
				end
			end
		end
		
		self.shrapnelFiring = false;
		
	end
	
	-- Animation + HUD
	if self.parent then	
		
		local ctrl = self.parent:GetController();
		local screen = ActivityMan:GetActivity():ScreenOfPlayer(ctrl.Player);
		if self.parent:IsPlayerControlled() and (ctrl:IsState(Controller.PIE_MENU_ACTIVE) or (self.shrapnelHUDReady and not self.shrapnelHUDTimer:IsPastSimMS(1000))) then
			local pos = self.parent.AboveHUDPos + Vector(0, 24)
			
			if self.shrapnelHUDReady and not ctrl:IsState(Controller.PIE_MENU_ACTIVE) and not self.shrapnelHUDTimer:IsPastSimMS(2000) then
				PrimitiveMan:DrawTextPrimitive(screen, pos + Vector(0, 10), "Shrapnel-shot Ready!", true, 1);
			elseif self.canShrapnel then
				PrimitiveMan:DrawTextPrimitive(screen, pos, "Shrapnel-shot: Ready", true, 1);
				PrimitiveMan:DrawTextPrimitive(screen, pos + Vector(0, 10), "Press O to fire", true, 1);
			else
				PrimitiveMan:DrawTextPrimitive(screen, pos, "Shrapnel-shot: Loading...", true, 1);
			end
		end
		
		self.horizontalAnim = math.floor(self.horizontalAnim / (1 + TimerMan.DeltaTimeSecs * 24.0) * 1000) / 1000
		self.verticalAnim = math.floor(self.verticalAnim / (1 + TimerMan.DeltaTimeSecs * 15.0) * 1000) / 1000
		
		local stance = Vector()
		stance = stance + Vector(-1,0) * self.horizontalAnim -- Horizontal animation
		stance = stance + Vector(0,5) * self.verticalAnim -- Vertical animation
		
		self.rotationTarget = self.rotationTarget - (self.angVel * 4)
		
		-- Progressive Recoil Update
		if self.FiredFrame or self.shrapnelFired == true then
			self.shrapnelFired = false;
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
		
		local fire = false
		if self.parent:IsPlayerControlled() then
			if UInputMan:KeyPressed(15) then
				fire = true
			end
		elseif self.Magazine then -- AI
			if self.canShrapnel == true and not self:IsReloading() and self.Magazine.UniqueID % 3 == 0 and self.Magazine.Age > 500 and self.Magazine.RoundCount > 70 and self.parent:GetController():IsState(Controller.WEAPON_FIRE) == true then -- Hacks
				fire = true
			end
		end
		
		if fire then
			if self.canShrapnel == true and not self:IsReloading() then
			  self.shrapnelActivated = true;
			else
				--sound
			end
		end

	end
	
	if self.canSmoke and not self.smokeTimer:IsPastSimMS(1500) then

		if self.smokeDelayTimer:IsPastSimMS(120) then
			
			local poof = math.random(1,2) < 2 and CreateMOSParticle("Tiny Smoke Ball 1") or CreateMOPixel("Real Bullet Micro Smoke Ball "..math.random(1,4), "Sandstorm.rte");
			poof.Pos = self.Pos + Vector(self.MuzzleOffset.X * self.FlipFactor, self.MuzzleOffset.Y):RadRotate(self.RotAngle);
			poof.Lifetime = poof.Lifetime * RangeRand(0.3, 1.3) * 0.9;
			poof.Vel = self.Vel * 0.1
			poof.GlobalAccScalar = RangeRand(0.9, 1.0) * -0.4; -- Go up and down
			MovableMan:AddParticle(poof);
			self.smokeDelayTimer:Reset()
		end
	end
end