function Create(self)

	self.parentSet = false;
	
	-- Sounds --
	self.preSound = CreateSoundContainer("Pre Judge", "Heat.rte");
	
	self.fireManualSound = CreateSoundContainer("Fire Manual Judge", "Heat.rte");
	
	self.fireAutoSound = CreateSoundContainer("Fire Auto Judge", "Heat.rte");
	
	self.manualReflectionSound = CreateSoundContainer("Reflection Manual Judge", "Heat.rte");
	
	self.autoReflectionSound = CreateSoundContainer("Reflection Auto Judge", "Heat.rte");
	
	self.magInPrepareSound = CreateSoundContainer("MagInPrepare Judge", "Heat.rte");
	
	self.magInSound = CreateSoundContainer("MagIn Judge", "Heat.rte");
	
	self.chamberSpinSound = CreateSoundContainer("ChamberSpin Judge", "Heat.rte");
	
	self.autoOnSound = CreateSoundContainer("Auto On Judge", "Heat.rte");
	
	self.autoOffSound = CreateSoundContainer("Auto Off Judge", "Heat.rte");
	
	self.targetSound = CreateSoundContainer("Target Judge", "Heat.rte");
	
	self.FireTimer = Timer();
	self:SetNumberValue("DelayedFireTimeMS", 25)	
	
	self.lastAge = self.Age
	
	self.originalSharpLength = self.SharpLength
	
	self.originalStanceOffset = Vector(math.abs(self.StanceOffset.X), self.StanceOffset.Y)
	self.originalSharpStanceOffset = Vector(self.SharpStanceOffset.X, self.SharpStanceOffset.Y)
	
	self.rotation = 0
	self.rotationTarget = 0
	self.rotationSpeed = 15
	
	self.horizontalAnim = 0
	self.verticalAnim = 0
	
	self.angVel = 0
	self.lastRotAngle = self.RotAngle
	
	self.smokeTimer = Timer();
	self.smokeDelayTimer = Timer();
	self.canSmoke = false
	
	
	self.Mode = 0;
	self.searchRange = FrameMan.PlayerScreenWidth * 0.3;
	self.searchTimer = Timer();
	self.searchTimer:SetSimTimeLimitMS(100);
	self.Target = nil;
	
	
	self.reloadTimer = Timer();
	
	self.magInPrepareDelay = 1000;
	self.magInAfterDelay = 250;
	self.chamberSpinPrepareDelay = 250;
	self.chamberSpinAfterDelay = 700;
	
	-- phases:
	-- 0 magin
	-- 1 speeeen
	
	self.reloadPhase = 0;
	
	self.ReloadTime = 9999;
	
	-- Progressive Recoil System 
	self.recoilAcc = 0 -- for sinous
	self.recoilStr = 0 -- for accumulator
	self.recoilStrength = 15 -- multiplier for base recoil added to the self.recoilStr when firing
	self.recoilPowStrength = 0.2 -- multiplier for self.recoilStr when firing
	self.recoilRandomUpper = 2 -- upper end of random multiplier (1 is lower)
	self.recoilDamping = 1.0
	
	self.recoilMax = 5 -- in deg.
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

		if self.reloadPhase == 0 then
			self.reloadDelay = self.magInPrepareDelay;
			self.afterDelay = self.magInAfterDelay;
			self.prepareSound = self.magInPrepareSound;
			self.afterSound = self.magInSound;
			
			self.rotationTarget = -5;
			
		elseif self.reloadPhase == 1 then
			self.reloadDelay = self.chamberSpinPrepareDelay;
			self.afterDelay = self.chamberSpinAfterDelay;
			self.prepareSound = nil;
			self.afterSound = self.chamberSpinSound;
			
		end
		
		if self.prepareSoundPlayed ~= true then
			self.prepareSoundPlayed = true;
			if self.prepareSound then
				self.prepareSound:Play(self.Pos);
			end
		end
	
		if self.reloadTimer:IsPastSimMS(self.reloadDelay) then
		
			if self.reloadPhase == 0 then
			elseif self.reloadPhase == 1 then
			
				if self.reloadTimer:IsPastSimMS(self.reloadDelay + ((self.afterDelay/5)*3.7)) then
					self.Frame = 0;
				elseif self.reloadTimer:IsPastSimMS(self.reloadDelay + ((self.afterDelay/5)*0.5)) then
					self.Frame = (self.Frame + 1) % 2;
				end

			end
			
			if self.afterSoundPlayed ~= true then
			
				if self.reloadPhase == 0 then
					self.Frame = 0;
					self.phaseOnStop = 1;
					local fake
					fake = CreateMOSRotating("Fake Magazine MOSRotating Judge");
					fake.Pos = self.Pos + Vector(-3 * self.FlipFactor, -2):RadRotate(self.RotAngle);
					fake.Vel = self.Vel + Vector(0.5*self.FlipFactor, 3):RadRotate(self.RotAngle);
					fake.RotAngle = self.RotAngle;
					fake.AngularVel = self.AngularVel + (-1*self.FlipFactor);
					fake.HFlipped = self.HFlipped;
					MovableMan:AddParticle(fake);
					
					self.angVel = self.angVel + 7;
					self.verticalAnim = self.verticalAnim + 1
					
				elseif self.reloadPhase == 1 then
					self.angVel = self.angVel - 2;
					self.verticalAnim = self.verticalAnim - 1	
					self.phaseOnStop = nil;
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
				if self.reloadPhase == 1 then
					self.ReloadTime = 0;
					self.reloadPhase = 0;
				else
					self.reloadPhase = self.reloadPhase + 1;
				end
			end
		end		
	else
		
		self.reloadTimer:Reset();
		self.prepareSoundPlayed = false;
		self.afterSoundPlayed = false;
		if self.phaseOnStop then
			self.reloadPhase = self.phaseOnStop;
			self.phaseOnStop = nil;
		end
		self.ReloadTime = 9999;
	end	

	if self.FiredFrame then
		self.Frame = (self.Frame + 1) % 2;
		
		self.canSmoke = true
		self.smokeTimer:Reset()
		
		if self.Mode == 0 then
			self.angVel = self.angVel - RangeRand(0.7,1.1) * 5
			for i = 1, 3 do
				local Bullet = CreateMOPixel("Particle Judge", "Heat.rte")
				Bullet.Pos = self.MuzzlePos;
				Bullet.Vel = self.Vel + Vector(130*self.FlipFactor,0):RadRotate(self.RotAngle)
				Bullet.Team = self.Team
				Bullet.IgnoresTeamHits = true
				MovableMan:AddParticle(Bullet);
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
		
		if self.Mode == 0 then
			self.fireManualSound:Play(self.Pos);
		else
			self.fireAutoSound:Play(self.Pos);
		end
		
		if outdoorRays >= self.rayThreshold then
			if self.Mode == 0 then
				self.manualReflectionSound:Stop(-1);
				self.autoReflectionSound:Stop(-1);
				self.manualReflectionSound:Play(self.Pos);
			else
				self.manualReflectionSound:Stop(-1);
				self.autoReflectionSound:Stop(-1);
				self.autoReflectionSound:Play(self.Pos);
			end
		end
	end
	
	-- Animation
	if self.parent then
	
		if self.Target then
		
			-- bias towards head if we have one
			-- we can't just target it cuz we will often miss upwards then
			if self.TargetHead then
				local betweenPosition = self.Target.Pos + (SceneMan:ShortestDistance(self.Target.Pos, self.TargetHead.Pos, SceneMan.SceneWrapsX) / 1.3);
				self.targetDist = SceneMan:ShortestDistance(self.Pos, betweenPosition, SceneMan.SceneWrapsX);
			else
				self.targetDist = SceneMan:ShortestDistance(self.Pos, self.Target.Pos, SceneMan.SceneWrapsX);
			end
			
			if self.HFlipped then
				self.targetAngle = (self.targetDist.AbsDegAngle-180)*-1;
			else
				self.targetAngle = self.targetDist.AbsDegAngle;
			end
			local selfAngle = (self.RotAngle*self.FlipFactor) * (180/math.pi);
			if (self.targetAngle) - selfAngle > -45 and (self.targetAngle) - selfAngle < 45 then
				self.rotationTarget = (self.targetAngle) - selfAngle;
			else
				self.Target = nil;
			end
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
		
		-- this shit was broken by pre4, muzzle flash is just gonna be in the wrong place sorry
		-- ask your precious furfag gay nigger-lover overlords why
		
		self.RotAngle = self.RotAngle + total;
		-- self.RotAngle = self.RotAngle + total;
		-- self:SetNumberValue("MagRotation", total);
		
		-- local jointOffset = Vector(self.JointOffset.X * self.FlipFactor, self.JointOffset.Y):RadRotate(self.RotAngle);
		-- local offsetTotal = Vector(jointOffset.X, jointOffset.Y):RadRotate(-total) - jointOffset
		-- self.Pos = self.Pos + offsetTotal;
		-- self:SetNumberValue("MagOffsetX", offsetTotal.X);
		-- self:SetNumberValue("MagOffsetY", offsetTotal.Y);
		
		self.StanceOffset = Vector(self.originalStanceOffset.X, self.originalStanceOffset.Y) + stance
		self.SharpStanceOffset = Vector(self.originalSharpStanceOffset.X, self.originalSharpStanceOffset.Y) + stance
		
		-- Auto/Manual mode piggybacking off self.parent here
		
		if self.parent:IsPlayerControlled() then
			if UInputMan:KeyPressed(HeatHotkeyMap.WeaponAbilityPrimary) then
				if self.Mode == 0 then
					self.autoOnSound:Play(self.Pos);
					self.Mode = 1;
					self.RateOfFire = 650;
					self.FullAuto = true;
					self.delayedFireDisabled = true;
					self.recoilStrength = 4;
					self.SharpLength = 50;
					self.originalSharpLength = self.SharpLength;
				else
					self.autoOffSound:Play(self.Pos);
					self.Mode = 0;
					self.RateOfFire = 200;
					self.FullAuto = false;			
					self.delayedFireDisabled = false;
					self.recoilStrength = 15;
					self.SharpLength = 200;
					self.originalSharpLength = self.SharpLength;
				end									
			end
		end
		
		-- Smart Pistol Ripoff Moment
		
		if self.Mode == 1 and self.Magazine then
			if self.FiredFrame then -- needs to be here to get the rotation right...
				for i = 1, 1 do
					local Bullet = CreateMOPixel("Particle Judge", "Heat.rte")
					Bullet.Pos = self.MuzzlePos;
					Bullet.Vel = Vector(180*self.FlipFactor,0):RadRotate(self.RotAngle)
					Bullet.Team = self.Team
					Bullet.IgnoresTeamHits = true
					MovableMan:AddParticle(Bullet);
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
			end
			if self.Magazine.RoundCount > 0 then
				
				if self.searchTimer:IsPastSimTimeLimit() then
					self.searchTimer:Reset();
					
					if self.Target == nil
					or self.Target:IsDead()
					or self.targetDist.Magnitude > 450
					or SceneMan:CastObstacleRay(self.MuzzlePos, SceneMan:ShortestDistance(self.MuzzlePos, self.Target.Pos, SceneMan.SceneWrapsX), Vector(), Vector(), self.Target.ID, self.Target.Team, rte.airID, 10) >= 0 then
		
						local searchPos = self.Pos + Vector(self.searchRange * 0.8 * self.FlipFactor, 0):RadRotate(self.RotAngle);
						self.TargetHead = nil;
						self.Target = nil;

						for actor in MovableMan.Actors do
							if actor.Team ~= self.Team then

								local Dist = SceneMan:ShortestDistance(self.Pos, actor.Pos, SceneMan.SceneWrapsX)
								local Angle = Dist.AbsDegAngle;
								if self.HFlipped then
									Angle = (Angle-180)*-1;
								end
								local selfAngle = (self.RotAngle*self.FlipFactor) * (180/math.pi);
								if (Angle) - selfAngle > -45 and (Angle) - selfAngle < 45
								and (SceneMan:ShortestDistance(searchPos, actor.Pos, SceneMan.SceneWrapsX).Magnitude - actor.Radius) < self.searchRange
								and SceneMan:CastObstacleRay(self.MuzzlePos, SceneMan:ShortestDistance(self.MuzzlePos, actor.Pos, SceneMan.SceneWrapsX), Vector(), Vector(), actor.ID, actor.Team, rte.airID, 10) < 0 then

									local topLeft = Vector(-actor.Radius, -actor.Radius);
									local bottomRight = Vector(actor.Radius, actor.Radius);
									for att in actor.Attachables do
										if IsAttachable(att) then
											local dist = SceneMan:ShortestDistance(actor.Pos, att.Pos, SceneMan.SceneWrapsX);
											local reach = dist:SetMagnitude(dist.Magnitude + math.sqrt(att.Diameter));
											if reach.X < topLeft.X then
												topLeft.X = reach.X;
											elseif reach.X > bottomRight.X then
												bottomRight.X = reach.X;
											end
											if reach.Y < topLeft.Y then
												topLeft.Y = reach.Y;
											elseif reach.Y > bottomRight.Y then
												bottomRight.Y = reach.Y;
											end
										end
									end
									local screen = ActivityMan:GetActivity():ScreenOfPlayer(ToActor(self.parent):GetController().Player);
									PrimitiveMan:DrawBoxPrimitive(screen, actor.Pos + topLeft, actor.Pos + bottomRight, 149);
									
									if IsAHuman(actor) and ToAHuman(actor).Head then
										self.TargetHead = ToAHuman(actor).Head;
									end
									
									self.Target = actor;
									self.targetSound:Play(self.Pos);
									break;
								end
							end
						end
					end
				end
			else
				self.searchTimer:Reset();
			end
		else
			self.Target = nil;
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