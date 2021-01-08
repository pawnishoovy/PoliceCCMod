function Create(self)

	self.parentSet = false;
	
	-- Sounds --
	self.preSound = CreateSoundContainer("Pre Riotbreaker", "Heat.rte");

	self.reflectionSound = CreateSoundContainer("Reflection Riotbreaker", "Heat.rte");
	
	self.boltBackSound = CreateSoundContainer("BoltBack Riotbreaker", "Heat.rte");
	
	self.boltBackReloadSound = CreateSoundContainer("BoltBackReload Riotbreaker", "Heat.rte");
	
	self.boltForwardSound = CreateSoundContainer("BoltForward Riotbreaker", "Heat.rte");
	
	self.shellInsertBreechSound = CreateSoundContainer("ShellInsertBreech Riotbreaker", "Heat.rte");
	
	self.shellInsertPrepareSound = CreateSoundContainer("ShellInsertPrepare Riotbreaker", "Heat.rte");
	
	self.shellInsertSound = CreateSoundContainer("ShellInsert Riotbreaker", "Heat.rte");
	
	self.FireTimer = Timer();
	self:SetNumberValue("DelayedFireTimeMS", 20)
	
	self.originalSharpLength = self.SharpLength
	
	self.originalStanceOffset = Vector(math.abs(self.StanceOffset.X), self.StanceOffset.Y)
	self.originalSharpStanceOffset = Vector(self.SharpStanceOffset.X, self.SharpStanceOffset.Y)
	
	self.originalJointOffset = Vector(self.JointOffset.X, self.JointOffset.Y)
	self.originalSupportOffset = Vector(math.abs(self.SupportOffset.X), self.SupportOffset.Y)
	
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
	
	self.afterReloadDelay = 400;
	self.afterReloadTimer = Timer();
	
	self.boltBackPrepareDelay = 350;
	self.boltBackAfterDelay = 250;
	self.firstShellInPrepareDelay = 750;
	self.firstShellInAfterDelay = 700;
	self.boltForwardFirstShellPrepareDelay = 200;
	self.boltForwardFirstShellAfterDelay = 600;
	self.shellInPrepareDelay = 500;
	self.shellInAfterDelay = 600;
	self.boltForwardPrepareDelay = 100;
	self.boltForwardAfterDelay = 125;
	
	-- phases:
	-- 0 boltback
	-- 1 firstshellin
	-- 2 boltforwardfirstshell
	-- 3 shellin
	-- 4 boltforward
	
	self.reloadPhase = 0;
	
	self.ReloadTime = 19999;
	
	-- Progressive Recoil System 
	self.recoilAcc = 0 -- for sinous
	self.recoilStr = 0 -- for accumulator
	self.recoilStrength = 13 -- multiplier for base recoil added to the self.recoilStr when firing
	self.recoilPowStrength = 0.4 -- multiplier for self.recoilStr when firing
	self.recoilRandomUpper = 1.2 -- upper end of random multiplier (1 is lower)
	self.recoilDamping = 0.9
	
	self.recoilMax = 20 -- in deg.
	self.originalSharpLength = self.SharpLength
	-- Progressive Recoil System 	
end

function Update(self)
	self.rotationTarget = 0 -- ZERO IT FIRST AAAA!!!!!
	self.delayedFireEnabled = true -- IMPORTANT
	
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
	
	self.SharpLength = self.originalSharpLength * (0.9 + math.pow(math.min(self.FireTimer.ElapsedSimTimeMS / 125, 1), 2.0) * 0.1)
	
	if self.FiredFrame then
		self.horizontalAnim = self.horizontalAnim + 2
		
		self.angVel = self.angVel + RangeRand(0.7,1.1) * 30
		
		if self.parent then
			local controller = self.parent:GetController();		
		
			if controller:IsState(Controller.BODY_CROUCH) then
				self.recoilStrength = 11
				self.recoilPowStrength = 2.5
				self.recoilRandomUpper = 1
				self.recoilDamping = 0.4
				
				self.recoilMax = 20
			else
				self.recoilStrength = 13
				self.recoilPowStrength = 3.4
				self.recoilRandomUpper = 1.2
				self.recoilDamping = 0.25
				
				self.recoilMax = 20
			end
			if (not controller:IsState(Controller.AIM_SHARP))
			or (controller:IsState(Controller.MOVE_LEFT)
			or controller:IsState(Controller.MOVE_RIGHT)) then
				self.recoilDamping = self.recoilDamping * 0.9;
			end
		end
		
		self.canSmoke = true
		self.smokeTimer:Reset()
		
		self.reloadTimer:Reset();
		self.reChamber = true;
		
		if self.Magazine then
			self.ammoCount = 0 + self.Magazine.RoundCount; -- +0 to avoid reference bullshit and save it as a number properly
			if self.ammoCount == 0 then
				self.breechShellReload = true;
				self:Reload();
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
	
	-- PAWNIS RELOAD ANIMATION HERE
	if self.reChamber then
		if self:IsReloading() then
			self.Reloading = true;
			self.reloadCycle = true;
			if self.ammoCount == 0 then
				self.reloadPhase = 0;
			else
				self.reloadPhase = 3;
			end
		end
		self.reChamber = false;
		self.Chamber = true;
		self.Casing = true;
	end
	
	if self:IsReloading() and (not self.Chamber) then -- if we start reloading from "scratch"
		self.Chamber = true;
		self.ReloadTime = 19999;
		self.Reloading = true;
		self.reloadCycle = true;
		if self.breechShellReload then
			self.reloadPhase = 0;
		else
			self.reloadPhase = 3;
		end
	end
	
	if self.parent then
	
		local ctrl = self.parent:GetController();
		local screen = ActivityMan:GetActivity():ScreenOfPlayer(ctrl.Player);
	
		if self:IsReloading() then
			self.parent:GetController():SetState(Controller.AIM_SHARP,false);
			self.afterReloadTimer:Reset();
		elseif not self.afterReloadTimer:IsPastSimMS(self.afterReloadDelay) then
			self:Deactivate();
			self.delayedFireEnabled = false -- IMPORTANT
		end
			
		
		if self.resumeReload then
			self:Reload();
			self.resumeReload = false;
			if self.reloadPhase == 3 and self.ammoCount == 4 then
				self.reloadPhase = 4;
			end
		end
		if self.Chamber then
			self:Deactivate();
			if self:IsReloading() then
				
				-- Fancy Reload Progress GUI
				if not (not self.reloadCycle and self.parent:GetController():IsState(Controller.WEAPON_FIRE)) and self.parent:IsPlayerControlled() then
					for i = 1, self.ammoCount do
						local color = 120
						local spacing = 4
						local offset = Vector(0 - spacing * 0.5 + spacing * (i) - spacing * self.ammoCount / 2, (self.ammoCountRaised and i == self.ammoCount) and 35 or 36)
						local position = self.parent.AboveHUDPos + offset
						PrimitiveMan:DrawCirclePrimitive(position + Vector(0,-2), 1, color);
						PrimitiveMan:DrawLinePrimitive(position + Vector(1,-3), position + Vector(1,3), color);
						PrimitiveMan:DrawLinePrimitive(position + Vector(-1,-3), position + Vector(-1,3), color);
						PrimitiveMan:DrawLinePrimitive(position + Vector(1,3), position + Vector(-1,3), color);
					end
				end
				
				if self.Reloading == false then
					self.reloadCycle = true;
					self.ReloadTime = 19999;
					self.Reloading = true;
					-- self.reloadTimer:Reset();
					-- self.prepareSoundPlayed = false;
					-- self.afterSoundPlayed = false;
				end
				
			else
				self.Reloading = false;
			end
			
			if self.reloadPhase == 0 then
				self.reloadDelay = self.boltBackPrepareDelay;
				self.afterDelay = self.boltBackAfterDelay;
				
				self.prepareSound = nil;
				if self:IsReloading() then
					self.afterSound = self.boltBackReloadSound;
					self.rotationTarget = 5;
				else
					self.afterSound = self.boltBackSound;
					self.rotationTarget = 2;
				end
				
			elseif self.reloadPhase == 1 then
				self.reloadDelay = self.firstShellInPrepareDelay
				self.afterDelay = self.firstShellInAfterDelay
				self.prepareSound = nil;
				self.afterSound = self.shellInsertBreechSound;
				
			elseif self.reloadPhase == 2 then
				self.reloadDelay = self.boltForwardFirstShellPrepareDelay;
				self.afterDelay = self.boltForwardFirstShellAfterDelay;
				self.prepareSound = nil;
				self.afterSound = self.boltForwardSound;
				
				self.rotationTarget = -10
			elseif self.reloadPhase == 3 then
				self.reloadDelay = self.shellInPrepareDelay;
				self.afterDelay = self.shellInAfterDelay;
				self.prepareSound = self.shellInsertPrepareSound;
				self.afterSound = self.shellInsertSound;
				
				self.rotationTarget = 10 * self.reloadTimer.ElapsedSimTimeMS / (self.reloadDelay + self.afterDelay)
			elseif self.reloadPhase == 4 then
				self.reloadDelay = self.boltForwardPrepareDelay;
				self.afterDelay = self.boltForwardAfterDelay;
				self.prepareSound = nil;
				self.afterSound = self.boltForwardSound;
				
				self.rotationTarget = -5
			end
			
			if self.prepareSoundPlayed ~= true then
				self.prepareSoundPlayed = true;
				if self.prepareSound then
					self.prepareSound:Play(self.Pos);
				end
			end
			
			if self.reloadTimer:IsPastSimMS(self.reloadDelay) then
				--[[
				if self.reloadPhase == 0 and self.Casing then
					local shell
					shell = CreateMOSParticle("Shell Shotgun");
					shell.Pos = self.Pos+Vector(0,-3):RadRotate(self.RotAngle);
					shell.Vel = self.Vel+Vector(-math.random(2,4)*self.FlipFactor,-math.random(3,4)):RadRotate(self.RotAngle);
					MovableMan:AddParticle(shell);
					
					self.Casing = false
				end]]
				-- if self.reloadPhase == 0 then
					-- self.horizontalAnim = self.horizontalAnim + TimerMan.DeltaTimeSecs * self.afterDelay
				-- end
			
				self.phasePrepareFinished = true;
			
				if self.afterSoundPlayed ~= true then
					if self.reloadPhase == 1 or self.reloadPhase == 3 then
						self.horizontalAnim = self.horizontalAnim + 1
						self.verticalAnim = self.verticalAnim - 1
					end
				
					self.afterSoundPlayed = true;
					if self.afterSound then
						self.afterSound:Play(self.Pos);
					end
				end
			
				if self.reloadPhase == 0 then
					
					if self.reloadTimer:IsPastSimMS(self.reloadDelay + ((self.afterDelay/5)*2)) then
						self.Frame = 4;
					elseif self.reloadTimer:IsPastSimMS(self.reloadDelay + ((self.afterDelay/5)*1.5)) then
						self.Frame = 3;
					elseif self.reloadTimer:IsPastSimMS(self.reloadDelay + ((self.afterDelay/5)*1)) then
						self.Frame = 2;
					elseif self.reloadTimer:IsPastSimMS(self.reloadDelay + ((self.afterDelay/5)*0.5)) then
						self.Frame = 1;
					end
					
				elseif self.reloadPhase == 1 then
				
					if self.parent:GetController():IsState(Controller.WEAPON_FIRE) then
						self.reloadCycle = false;
						PrimitiveMan:DrawTextPrimitive(screen, self.parent.AboveHUDPos + Vector(0, 30), "Interrupting...", true, 1);
					end
					
					self.Frame = 5;
				
					if self.ammoCountRaised ~= true then
						self.ammoCountRaised = true;
						if self.ammoCount < 4 then
							self.ammoCount = self.ammoCount + 1;
							if self.ammoCount == 4 then
								self.reloadCycle = false;
							end
						else
							self.reloadCycle = false;
						end
					end
					
					self.phaseOnStop = 2;
					
				elseif self.reloadPhase == 2 then
					
					if self.reloadTimer:IsPastSimMS(self.reloadDelay + ((self.afterDelay/5)*2.0)) then
						self.Frame = 0;
					elseif self.reloadTimer:IsPastSimMS(self.reloadDelay + ((self.afterDelay/5)*1.5)) then
						self.Frame = 9;
					elseif self.reloadTimer:IsPastSimMS(self.reloadDelay + ((self.afterDelay/5)*1.0)) then
						self.Frame = 8;
					elseif self.reloadTimer:IsPastSimMS(self.reloadDelay + ((self.afterDelay/5)*0.5)) then
						self.Frame = 7;
					else
						self.Frame = 6;
					end
					
				elseif self.reloadPhase == 3 then
					
					self.phaseOnStop = 3;
				
					if self.parent:GetController():IsState(Controller.WEAPON_FIRE) then
						self.reloadCycle = false;
						PrimitiveMan:DrawTextPrimitive(screen, self.parent.AboveHUDPos + Vector(0, 30), "Interrupting...", true, 1);
					end

					if self.ammoCountRaised ~= true then
						self.ammoCountRaised = true;
						if self.ammoCount < 4 then
							self.ammoCount = self.ammoCount + 1;
							if self.ammoCount == 4 then
								self.reloadCycle = false;
							end
						else
							self.reloadCycle = false;
						end
					end

				elseif self.reloadPhase == 4 then
					
					if self.reloadTimer:IsPastSimMS(self.reloadDelay + ((self.afterDelay/5)*2)) then
						self.Frame = 0;
					elseif self.reloadTimer:IsPastSimMS(self.reloadDelay + ((self.afterDelay/5)*1.5)) then
						self.Frame = 1;
					elseif self.reloadTimer:IsPastSimMS(self.reloadDelay + ((self.afterDelay/5)*1)) then
						self.Frame = 2;
					elseif self.reloadTimer:IsPastSimMS(self.reloadDelay + ((self.afterDelay/5)*0.5)) then
						self.Frame = 3;
					end

				end
				
				if self.reloadTimer:IsPastSimMS(self.reloadDelay + self.afterDelay) then
					self.reloadTimer:Reset();
					self.prepareSoundPlayed = false;
					self.afterSoundPlayed = false;
					if self.reloadPhase == 0 then

						if not self:IsReloading() then
							self.reloadPhase = 4;
						elseif self.breechShellReload == true then
							self.reloadPhase = self.reloadPhase + 1;
						else
							self.reloadPhase = 4;
						end
						if self.Casing then
							local shell
							shell = CreateAEmitter("Casing Riotbreaker");
							shell.Pos = self.Pos+Vector(1 * self.FlipFactor,-1):RadRotate(self.RotAngle);
							shell.Vel = self.Vel+Vector(-math.random(2,4)*self.FlipFactor,-math.random(3,4)):RadRotate(self.RotAngle);
							shell.RotAngle = self.RotAngle
							shell.HFlipped = self.HFlipped
							MovableMan:AddParticle(shell);
							
							self.Casing = false
						end
					
					elseif self.reloadPhase == 1 then
					
						self.ammoCountRaised = false;
					
						self.reloadPhase = self.reloadPhase + 1;
						
					elseif self.reloadPhase == 2 then
					
						if self.reloadCycle then
							self.reloadPhase = 3; -- same phase baby the ride never ends (except at 4 rounds)
						else
							self.ReloadTime = 0;
							self.reloadPhase = 0;
							self.Chamber = false;
							self.Reloading = false;
							self.phaseOnStop = nil;
						end
						
					elseif self.reloadPhase == 3 then
					
						self.ammoCountRaised = false;
					
						if self.reloadCycle then
							self.reloadPhase = 3; -- same phase baby the ride never ends (except at 4 rounds)
						else
							self.ReloadTime = 0;
							self.reloadPhase = 0;
							self.Chamber = false;
							self.Reloading = false;
							self.phaseOnStop = nil;
						end
					
					elseif self.reloadPhase == 4 then
					
						if self:IsReloading() then
							if self.ammoCount < 4 then
								self.reloadPhase = 3;
							else
								self.ReloadTime = 0;
								self.reloadPhase = 0;
								self.Chamber = false;
								self.Reloading = false;
								self.phaseOnStop = nil;
							end
						else
							self.ReloadTime = 0;
							self.reloadPhase = 0;
							self.Chamber = false;
							self.Reloading = false;
							self.phaseOnStop = nil;
						end
						
					else
						self.reloadPhase = self.reloadPhase + 1;
					end
				end				
			else
				self.phasePrepareFinished = false;
			end
			
		else
			local f = math.max(1 - math.min((self.FireTimer.ElapsedSimTimeMS - 25) / 200, 1), 0)
			self.JointOffset = self.originalJointOffset + Vector(1, 0) * f
			
			self.reloadTimer:Reset();
			self.prepareSoundPlayed = false;
			self.afterSoundPlayed = false;
			self.ReloadTime = 19999;
		end
	else
		self.reloadTimer:Reset();
	end
	
	if self:DoneReloading() then
		self.breechShellReload = false;
		self.Magazine.RoundCount = self.ammoCount;
	end	
	
	-- Animation
	if self.parent then
		self.horizontalAnim = math.floor(self.horizontalAnim / (1 + TimerMan.DeltaTimeSecs * 24.0) * 1000) / 1000
		self.verticalAnim = math.floor(self.verticalAnim / (1 + TimerMan.DeltaTimeSecs * 15.0) * 1000) / 1000
		
		local stance = Vector()
		stance = stance + Vector(-1,0) * self.horizontalAnim -- Horizontal animation
		stance = stance + Vector(0,5) * self.verticalAnim -- Vertical animation
		
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
		
		--self.rotationTarget = self.rotationTarget + recoilFinal -- apply the recoil
		if self.delayedFire then -- Rotation fix
			self.rotation = recoilFinal + (self.angVel * 3)
		else
			self.rotationTarget = self.rotationTarget + recoilFinal -- apply the recoil
		end
		-- Progressive Recoil Update			
	
		self.rotation = (self.rotation + self.rotationTarget * TimerMan.DeltaTimeSecs * self.rotationSpeed) / (1 + TimerMan.DeltaTimeSecs * self.rotationSpeed)
		local total = math.rad(self.rotation) * self.FlipFactor
		
		self.RotAngle = self.RotAngle + total;
		
		--self:SetNumberValue("MagRotation", total);
		
		local supportOffset = Vector(0,0)
		if self.Frame == 1 or self.Frame == 9 then
			supportOffset = Vector(-1,0)
		elseif self.Frame == 2 or self.Frame == 8 then
			supportOffset = Vector(-2,0)
		elseif self.Frame == 3 or self.Frame == 7 then
			supportOffset = Vector(-3,0)
		elseif self.Frame == 4 or self.Frame == 6 then
			supportOffset = Vector(-4,0)
		end
		if self.parent:GetController():IsState(Controller.AIM_SHARP) == true and self.parent:GetController():IsState(Controller.MOVE_LEFT) == false and self.parent:GetController():IsState(Controller.MOVE_RIGHT) == false then
			supportOffset = supportOffset + Vector(-1,0)
		end
		
		self.SupportOffset = self.originalSupportOffset + supportOffset
		
		local jointOffset = Vector(self.JointOffset.X * self.FlipFactor, self.JointOffset.Y):RadRotate(self.RotAngle);
		local offsetTotal = Vector(jointOffset.X, jointOffset.Y):RadRotate(-total) - jointOffset
		self.Pos = self.Pos + offsetTotal;
		--self:SetNumberValue("MagOffsetX", offsetTotal.X);
		--self:SetNumberValue("MagOffsetY", offsetTotal.Y);
		
		self.StanceOffset = Vector(self.originalStanceOffset.X, self.originalStanceOffset.Y) + stance
		self.SharpStanceOffset = Vector(self.originalSharpStanceOffset.X, self.originalSharpStanceOffset.Y) + stance
	end
	
	if self.canSmoke and not self.smokeTimer:IsPastSimMS(1500) then
		if self.smokeDelayTimer:IsPastSimMS(60) then
			
			local poof = CreateMOSParticle("Tiny Smoke Ball 1", "Base.rte")
			poof.Pos = self.Pos + Vector(self.MuzzleOffset.X * self.FlipFactor, self.MuzzleOffset.Y):RadRotate(self.RotAngle);
			poof.Lifetime = poof.Lifetime * RangeRand(0.3, 1.3) * 0.9;
			poof.Vel = self.Vel * 0.1
			poof.GlobalAccScalar = RangeRand(0.9, 1.0) * -0.4; -- Go up and down
			MovableMan:AddParticle(poof);
			self.smokeDelayTimer:Reset()
			
		end
	end
end