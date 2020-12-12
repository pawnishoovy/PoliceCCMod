function Create(self)

	self.parentSet = false;
	
	-- Sounds --
	
	self.stopSounds = {["Variations"] = 3,
	["Path"] = "Heat.rte/Devices/Weapons/Handheld/Director/CompliSound/Stop"};
	
	self.startSounds = {["Variations"] = 2,
	["Path"] = "Heat.rte/Devices/Weapons/Handheld/Director/CompliSound/Start"};

	self.reflectionSounds = {["Outdoors"] = nil};
	self.reflectionSounds.Outdoors = {["Variations"] = 3,
	["Path"] = "Heat.rte/Devices/Weapons/Handheld/Director/CompliSound/Reflection"};
	
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
	
	self.triggerPulled = false;
	
	self.Activatable = true;
	self.activatableTimer = Timer();
	self.Overheat = 0;
	self.Cooldownable = true;
	
	self.burstThreshold = 31;
	self.shotCounter = 0;
	self.burstCount = 5;
	self.burstFireDuration = 50;
	self.burstFireDelay = 350;
	
	self.activatableTimer = Timer();
	
	self.boltBackPrepareDelay = 600;
	self.boltBackAfterDelay = 600;
	self.magInPrepareDelay = 500;
	self.magInAfterDelay = 500;
	self.boltForwardPrepareDelay = 600;
	self.boltForwardAfterDelay = 400;
	
	-- phases:
	-- 0 boltback
	-- 1 magin
	-- 2 boltforward
	
	self.reloadPhase = 0;
	
	self.ReloadTime = 9999;
	
	-- Progressive Recoil System 
	self.recoilAcc = 0 -- for sinous
	self.recoilStr = 0 -- for accumulator
	self.recoilStrength = 3 -- multiplier for base recoil added to the self.recoilStr when firing
	self.recoilPowStrength = 0 -- multiplier for self.recoilStr when firing
	self.recoilRandomUpper = 2 -- upper end of random multiplier (1 is lower)
	self.recoilDamping = 1.2
	
	self.recoilMax = 1 -- in deg.
	self.originalSharpLength = self.SharpLength
	-- Progressive Recoil System 
end

function Update(self)
	self.Frame = 0;
	self.rotationTarget = 0 -- ZERO IT FIRST AAAA!!!!!
	
	local tryingToFire = self:IsActivated();
	
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
	
	if self.lastHFlipped ~= nil then
		if self.lastHFlipped ~= self.HFlipped then
			self.lastHFlipped = self.HFlipped
			value = value + math.pi
		end
	else
		self.lastHFlipped = self.HFlipped
	end
	
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
	
	if tryingToFire and self.Activatable == true then
		-- self.doNothingLol
	else
		self:Deactivate();
	end
	
	if (self.Overheat > 0) and (((not tryingToFire) and self.Cooldownable == true) or (self:IsReloading())) then
		if self.Overheat > 150 then
			self.Overheat = 150;
		end
		self.Overheat = self.Overheat - 0.5;
	end
	
	if self.Overheat > self.burstThreshold then
		if self.Burst == false then
			self.actingTimerDelay = self.burstFireDuration;
			self.Burst = true;
		end
	else
		self.Activatable = true;
		self.Burst = false;
		if self.shotCounter ~= 0 then
			self.switchOffSound = AudioMan:PlaySound("Heat.rte/Devices/Weapons/Handheld/Director/Sounds/SwitchOffLast.ogg", self.Pos, -1, 0, 130, 1, 150, false);
		end
		self.shotCounter = 0;
		
	end
	
	if self.Burst == true then
		if self.Overheat > 110 then
			self.burstCount = 1;
		elseif self.Overheat > 70 then
			self.burstCount = 2;
		else
			self.burstCount = 4;
		end
		if self.activatableTimer:IsPastSimMS(self.actingTimerDelay) then
			if self.Activatable == true then
				if tryingToFire then
					self.Cooldownable = false;
				else
					self.Cooldownable = true;
				end
				self.Activatable = false;
				self.shotCounter = self.shotCounter + 1
				if self.shotCounter >= self.burstCount then
					self.actingTimerDelay = self.burstFireDelay;
					self.shotCounter = 0;
					self.switchOffSound = AudioMan:PlaySound("Heat.rte/Devices/Weapons/Handheld/Director/Sounds/SwitchOffLast.ogg", self.Pos, -1, 0, 130, 1, 150, false);
				else
					self.switchOffSound = AudioMan:PlaySound("Heat.rte/Devices/Weapons/Handheld/Director/Sounds/SwitchOff.ogg", self.Pos, -1, 0, 130, 1, 150, false);
				end
			else
				self.Activatable = true;
				self.actingTimerDelay = self.burstFireDuration;
				if self.actingTimerDelay == self.burstFireDelay then
					self.switchOnSound = AudioMan:PlaySound("Heat.rte/Devices/Weapons/Handheld/Director/Sounds/SwitchOnFirst.ogg", self.Pos, -1, 0, 130, 1, 150, false);
				else
					self.switchOnSound = AudioMan:PlaySound("Heat.rte/Devices/Weapons/Handheld/Director/Sounds/SwitchOn.ogg", self.Pos, -1, 0, 130, 1, 150, false);
				end
			end
			self.activatableTimer:Reset();
		end
	end	
	
	-- PAWNIS RELOAD ANIMATION HERE
	if self:IsReloading() then

		if self.reloadPhase == 0 then
			self.reloadDelay = self.boltBackPrepareDelay;
			self.afterDelay = self.boltBackAfterDelay;			
			self.prepareSoundPath = 
			"Heat.rte/Devices/Weapons/Handheld/Director/Sounds/BoltBackPrepare";
			self.afterSoundPath = 
			"Heat.rte/Devices/Weapons/Handheld/Director/Sounds/BoltBack";
			
			self.rotationTarget = 5;
			
		elseif self.reloadPhase == 1 then
			self.reloadDelay = self.magInPrepareDelay;
			self.afterDelay = self.magInAfterDelay;
			self.prepareSoundPath = 
			"Heat.rte/Devices/Weapons/Handheld/Director/Sounds/MagInPrepare";
			self.afterSoundPath = 
			"Heat.rte/Devices/Weapons/Handheld/Director/Sounds/MagIn";

			self.rotationTarget = 5;
		
		elseif self.reloadPhase == 2 then
			self.reloadDelay = self.boltForwardPrepareDelay;
			self.afterDelay = self.boltForwardAfterDelay;
			self.prepareSoundPath =
			"Heat.rte/Devices/Weapons/Handheld/Director/Sounds/BoltForwardPrepare";
			self.afterSoundPath = 
			"Heat.rte/Devices/Weapons/Handheld/Director/Sounds/BoltForward";
			
			self.rotationTarget = 2;
			
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
			end
			
			if self.afterSoundPlayed ~= true then
			
				if self.reloadPhase == 0 then
					
					self.phaseOnStop = 2;
					local fake
					fake = CreateMOSRotating("Fake Magazine MOSRotating Director");
					fake.Pos = self.Pos + Vector(-8 * self.FlipFactor, 0):RadRotate(self.RotAngle);
					fake.Vel = self.Vel + Vector(0.5*self.FlipFactor, 3):RadRotate(self.RotAngle);
					fake.RotAngle = self.RotAngle;
					fake.AngularVel = self.AngularVel + (-1*self.FlipFactor);
					fake.HFlipped = self.HFlipped;
					MovableMan:AddParticle(fake);
					
					self.horizontalAnim = self.horizontalAnim - 1;
					self.angVel = self.angVel - 2;
					
				elseif self.reloadPhase == 1 then
					
					self.phaseOnStop = 3;
					self.angVel = self.angVel - 2;
					self.verticalAnim = self.verticalAnim - 1	
					self:RemoveNumberValue("MagRemoved");					
					
				elseif self.reloadPhase == 2 then
				
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
				if self.reloadPhase == 2 then
					self.ReloadTime = 0;
					self.reloadPhase = 0;
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
		self.ReloadTime = 9999;
	end

	-- PAWNIS RELOAD ANIMATION HERE
	
	if self.prepareSound then
		if self.prepareSound:IsBeingPlayed() then
			self.prepareSound:SetPosition(self.Pos);
		end
	end
	
	if self.afterSound then
		if self.afterSound:IsBeingPlayed() then
			self.afterSound:SetPosition(self.Pos);
		end
	end
	
	if self:IsActivated() and self.RoundInMagCount > 0 then
	
		if self.reflectionSound then
			if self.reflectionSound:IsBeingPlayed() then
				self.reflectionSound:Stop(-1)
			end
		end
		if self.smokeSound then
			if self.smokeSound:IsBeingPlayed() then
				self.smokeSound:Stop(-1)
			end
		end
		if self.stopSound then
			if self.stopSound:IsBeingPlayed() then
				self.stopSound:Stop(-1)
			end
		end
		if self.triggerPulled ~= true then
			self.triggerPulled = true;
			self.startSound = AudioMan:PlaySound(self.startSounds.Path .. math.random(1, self.startSounds.Variations) .. ".ogg", self.Pos, -1, 0, 130, 1, 250, false);
		end
		
	else
	
		if self.triggerPulled == true then
		
			self.triggerPulled = false;
			
			self.stopSound = AudioMan:PlaySound(self.stopSounds.Path .. math.random(1, self.stopSounds.Variations) .. ".ogg", self.Pos, -1, 0, 130, 1, 250, false);
			
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
			
			if outdoorRays >= self.rayThreshold then
				self.reflectionSound = AudioMan:PlaySound(self.reflectionSounds.Outdoors.Path .. math.random(1, self.reflectionSounds.Outdoors.Variations) .. ".ogg", self.Pos, -1, 0, 130, 1, 450, false);
			end
			
		end
	end
			
	
	if self.FiredFrame then
		self.Frame = 1;
		self.Overheat = self.Overheat + 1;

		self.canSmoke = true
		self.smokeTimer:Reset()

	end
	
	-- Animation
	if self.parent then
	
			local ctrl = self.parent:GetController();
			local screen = ActivityMan:GetActivity():ScreenOfPlayer(ctrl.Player);
			if self.parent:IsPlayerControlled() then
				local pos = self.parent.AboveHUDPos + Vector(0, 24)
				PrimitiveMan:DrawTextPrimitive(screen, pos + Vector(0, 10), tostring(self.Overheat), true, 1);
			end
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
		
		self.RotAngle = self.RotAngle + total;
		self:SetNumberValue("MagRotation", total);
		
		local jointOffset = Vector(self.JointOffset.X * self.FlipFactor, self.JointOffset.Y):RadRotate(self.RotAngle);
		local offsetTotal = Vector(jointOffset.X, jointOffset.Y):RadRotate(-total) - jointOffset
		self.Pos = self.Pos + offsetTotal;
		self:SetNumberValue("MagOffsetX", offsetTotal.X);
		self:SetNumberValue("MagOffsetY", offsetTotal.Y);
		
		self.StanceOffset = Vector(self.originalStanceOffset.X, self.originalStanceOffset.Y) + stance
		self.SharpStanceOffset = Vector(self.originalSharpStanceOffset.X, self.originalSharpStanceOffset.Y) + stance
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