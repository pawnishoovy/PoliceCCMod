HumanAIBehaviours = {};

-- function HumanAIBehaviours.createSoundEffect(self, effectName, variations)
	-- if effectName ~= nil then
		-- self.soundEffect = AudioMan:PlaySound(effectName .. math.random(1, variations) .. ".ogg", self.Pos, -1, 0, 130, 1, 400, false);	
	-- end
-- end

-- no longer needed as of pre3!

function HumanAIBehaviours.createEmotion(self, emotion, priority, duration, canOverridePriority)
	if canOverridePriority == nil then
		canOverridePriority = false;
	end
	local usingPriority
	if canOverridePriority == false then
		usingPriority = priority - 1;
	else
		usingPriority = priority;
	end
	if emotion then
		
		self.emotionApplied = false; -- applied later in handleheadframes
		self.Emotion = emotion;
		if duration then
			self.emotionTimer:Reset();
			self.emotionDuration = duration;
		else
			self.emotionDuration = 0; -- will follow voiceSound length
		end
		self.lastEmotionPriority = priority;
		self.deathCloseTimer:Reset();
	end
end

function HumanAIBehaviours.createVoiceSoundEffect(self, soundContainer, priority, emotion, canOverridePriority)
	if canOverridePriority == nil then
		canOverridePriority = false;
	end
	local usingPriority
	if canOverridePriority == false then
		usingPriority = priority - 1;
	else
		usingPriority = priority;
	end
	if self.Head and soundContainer ~= nil then
		if self.voiceSound then
			if self.voiceSound:IsBeingPlayed() then
				if self.lastPriority <= usingPriority then
					if emotion then
						HumanAIBehaviours.createEmotion(self, emotion, priority, 0, canOverridePriority);
					end
					self.voiceSound:Stop();
					self.voiceSound = soundContainer;
					soundContainer:Play(self.Pos)
					self.lastPriority = priority;
					return true;
				end
			else
				if emotion then
					HumanAIBehaviours.createEmotion(self, emotion, priority, 0, canOverridePriority);
				end
				self.voiceSound = soundContainer;
				soundContainer:Play(self.Pos)
				self.lastPriority = priority;
				return true;
			end
		else
			if emotion then
				HumanAIBehaviours.createEmotion(self, emotion, priority, 0, canOverridePriority);
			end
			self.voiceSound = soundContainer;
			soundContainer:Play(self.Pos)
			self.lastPriority = priority;
			return true;
		end
	end
end

function HumanAIBehaviours.handleMovement(self)
	
	local crouching = self.controller:IsState(Controller.BODY_CROUCH)
	local moving = self.controller:IsState(Controller.MOVE_LEFT) or self.controller:IsState(Controller.MOVE_RIGHT);
	
	--NOTE: you could also put in things like your falling scream here easily with very little overhead
	
	-- Leg Collision Detection system
    --local i = 0
    for i = 1, 2 do
        --local foot = self.feet[i]
		local foot = nil
        --local leg = self.legs[i]
		if i == 1 then
			foot = self.FGFoot 
		else
			foot = self.BGFoot 
		end
        --if foot ~= nil and leg ~= nil and leg.ID ~= rte.NoMOID then
		if foot ~= nil then
            local footPos = foot.Pos				
			local mat = nil
			local pixelPos = footPos + Vector(0, 4)
			self.footPixel = SceneMan:GetTerrMatter(pixelPos.X, pixelPos.Y)
			--PrimitiveMan:DrawLinePrimitive(pixelPos, pixelPos, 13)
			if self.footPixel ~= 0 then
				mat = SceneMan:GetMaterialFromID(self.footPixel)
			--	PrimitiveMan:DrawLinePrimitive(pixelPos, pixelPos, 162);
			--else
			--	PrimitiveMan:DrawLinePrimitive(pixelPos, pixelPos, 13);
			end
			
			local movement = (self.controller:IsState(Controller.MOVE_LEFT) == true or self.controller:IsState(Controller.MOVE_RIGHT) == true or self.Vel.Magnitude > 3)
			if mat ~= nil then
				--PrimitiveMan:DrawTextPrimitive(footPos, mat.PresetName, true, 0);
				if self.feetContact[i] == false then
					self.feetContact[i] = true
					if self.feetTimers[i]:IsPastSimMS(self.footstepTime) and movement then																	
						self.feetTimers[i]:Reset()
					end
				end
			else
				if self.feetContact[i] == true then
					self.feetContact[i] = false
					if self.feetTimers[i]:IsPastSimMS(self.footstepTime) and movement then
						self.feetTimers[i]:Reset()
					end
				end
			end
		end
	end
	
	-- Custom Jump
	if self.controller:IsState(Controller.BODY_JUMPSTART) == true and self.controller:IsState(Controller.BODY_CROUCH) == false and self.jumpTimer:IsPastSimMS(self.jumpDelay) and not self.isJumping then
		if self.feetContact[1] == true or self.feetContact[2] == true then
			local jumpVec = Vector(0,-4.0)
			local jumpWalkX = 3
			if self.controller:IsState(Controller.MOVE_LEFT) == true then
				jumpVec.X = -jumpWalkX
			elseif self.controller:IsState(Controller.MOVE_RIGHT) == true then
				jumpVec.X = jumpWalkX
			end
			self.movementSounds.Jump:Play(self.Pos);
			if math.abs(self.Vel.X) > jumpWalkX * 2.0 then
				self.Vel = Vector(self.Vel.X, self.Vel.Y + jumpVec.Y)
			else
				self.Vel = Vector(self.Vel.X + jumpVec.X, self.Vel.Y + jumpVec.Y)
			end
			self.isJumping = true
			self.jumpTimer:Reset()
			self.jumpStop:Reset()
		end
	elseif self.isJumping or self.wasInAir then
		if (self.feetContact[1] == true or self.feetContact[2] == true) and self.jumpStop:IsPastSimMS(100) then
			self.isJumping = false
			self.wasInAir = false;
			if self.Vel.Y > 0 and self.moveSoundTimer:IsPastSimMS(500) then
				self.movementSounds.Land:Play(self.Pos);
				self.moveSoundTimer:Reset();
			end
		end
	end
	
	--- Extra Movement
	
	-- Booster
	if self.Jetpack then
		
		
		local boosting = false
		if self:IsPlayerControlled() then
			boosting = crouching and self.controller:IsState(Controller.BODY_JUMPSTART)
		elseif self.boosterTimer:IsPastSimMS(self.boosterAIDelay) then
			boosting = self.controller:IsState(Controller.BODY_JUMPSTART) and SceneMan:ShortestDistance(self.Pos,self:GetLastAIWaypoint(),SceneMan.SceneWrapsX).Y < -5
		end
		
		self.jumpJetSound.Pos = self.Jetpack.Pos;
		
		if not self.Hovering and boosting and self.boosterReady then
		
			self.jumpJetSound:Play(self.Pos);
			
			self.Vel = Vector(self.Vel.X, self.Vel.Y):RadRotate(-self.RotAngle)
			self.Vel = Vector(self.Vel.X, self.Vel.Y * 0.5)
			self.Vel = Vector(self.Vel.X, self.Vel.Y):RadRotate(self.RotAngle)
			
			self.Vel = self.Vel + Vector(0, -10):RadRotate(self.RotAngle)
			self.boosterReady = false
			
			self.boosterTimer:Reset()
			
			local offset = Vector(-4, 6)--Vector(self.Jetpack.EmissionOffset.X, self.Jetpack.EmissionOffset.Y)
			
			local emitterA = CreateAEmitter("HumanOfficer Jetpack Smoke Trail Medium")
			emitterA.Lifetime = 1300
			self.Jetpack:AddAttachable(emitterA);
			
			ToAttachable(emitterA).ParentOffset = offset
			
			local emitterB = CreateAEmitter("HumanOfficer Jetpack Smoke Trail Heavy")
			emitterB.Lifetime = 400
			self.Jetpack:AddAttachable(emitterB);
			
			ToAttachable(emitterB).ParentOffset = offset
			
		elseif not self.boosterReady and (self.feetContact[1] == true or self.feetContact[2] == true) and self.boosterTimer:IsPastSimMS(300) then
			self.boosterReady = true
			for attachable in self.Jetpack.Attachables do
				if attachable.ClassName == "AEmitter" and string.find(attachable.PresetName,"Smoke Trail") then
					attachable.ToDelete = true
				end
			end
		end
	end

	if (crouching) then
		if (not self.wasCrouching and self.moveSoundTimer:IsPastSimMS(600)) then
			self.movementSounds.Crouch:Play(self.Pos);
		end
		if (moving) then
			if (self.moveSoundWalkTimer:IsPastSimMS(700)) then
				self.movementSounds.Step:Play(self.Pos);
				self.moveSoundWalkTimer:Reset();
			end
		end
	else
		if (self.wasCrouching and self.moveSoundTimer:IsPastSimMS(600)) then
			self.movementSounds.Stand:Play(self.Pos);
			self.moveSoundTimer:Reset();
		end
	end
	
	if self.Vel.Y > 10 then
		self.wasInAir = true;
	else
		self.wasInAir = false;
	end
	
	self.wasCrouching = crouching;
	self.wasMoving = moving;
end

function HumanAIBehaviours.handleHealth(self)

	local healthTimerReady = self.healthUpdateTimer:IsPastSimMS(750);
	local wasLightlyInjured = self.Health < (self.oldHealth - 5);
	local wasInjured = self.Health < (self.oldHealth - 25);
	local wasHeavilyInjured = self.Health < (self.oldHealth - 50);

	if (healthTimerReady or wasLightlyInjured or wasInjured or wasHeavilyInjured) then
	
		self.oldHealth = self.Health;
		self.healthUpdateTimer:Reset();
		
		if not (self.FGArm) and (self.FGArmLost ~= true) then
			self.Suppression = self.Suppression + 100;
			self.FGArmLost = true;
			HumanAIBehaviours.createVoiceSoundEffect(self, self.voiceSounds.suppressedHigh, 5, 4);
		end
		if not (self.BGArm) and (self.BGArmLost ~= true) then
			self.Suppression = self.Suppression + 100;
			self.BGArmLost = true;
			HumanAIBehaviours.createVoiceSoundEffect(self, self.voiceSounds.suppressedHigh, 5, 4);
		end
		if not (self.FGLeg) and (self.FGLegLost ~= true) then
			self.Suppression = self.Suppression + 100;
			self.FGLegLost = true;
			HumanAIBehaviours.createVoiceSoundEffect(self, self.voiceSounds.suppressedHigh, 5, 4);
		end
		if not (self.BGLeg) and (self.BGLegLost ~= true) then
			self.Suppression = self.Suppression + 100;
			self.BGLegLost = true;
			HumanAIBehaviours.createVoiceSoundEffect(self, self.voiceSounds.suppressedHigh, 5, 4);
		end	
		
		if wasHeavilyInjured then
			self.Suppression = self.Suppression + 100;
			if self.Healing == true then
				self.Healing = false;
				if self:IsPlayerControlled() then
					self.healSounds.healStereoInterrupt:Play(self.Pos);
					self.healSound = healSounds.healStereoInterrupt;
				else
					self.healSounds.healMonoInterrupt:Play(self.Pos);
					self.healSound = self.healSounds.healMonoInterrupt;
				end
			end
			self.healWarned = false;
			self.toHeal = false;
			self.healTimer:Reset();
			self.healDelayTimer:Reset();
		elseif wasInjured then
			self.Suppression = self.Suppression + 50;
			if self.Healing == true then
				self.Healing = false;
				if self:IsPlayerControlled() then
					self.healSounds.healStereoInterrupt:Play(self.Pos);
					self.healSound = healSounds.healStereoInterrupt;
				else
					self.healSounds.healMonoInterrupt:Play(self.Pos);
					self.healSound = self.healSounds.healMonoInterrupt;
				end
			end
			self.healWarned = false;
			self.toHeal = false;
			self.healTimer:Reset();
			self.healDelayTimer:Reset();
		elseif wasLightlyInjured then
			HumanAIBehaviours.createEmotion(self, 2, 1, 500);
			self.Suppression = self.Suppression + math.random(15,25);
			if self.Healing == true then
				self.Healing = false;
				if self:IsPlayerControlled() then
					self.healSounds.healStereoInterrupt:Play(self.Pos);
					self.healSound = self.healSounds.healStereoInterrupt;
				else
					self.healSounds.healMonoInterrupt:Play(self.Pos);
					self.healSound = self.healSounds.healMonoInterrupt;
				end
			end
			self.healWarned = false;
			self.toHeal = false;
			self.healTimer:Reset();
			self.healDelayTimer:Reset();
		end
		
		if (wasInjured) or (wasHeavilyInjured) and self.Head then
			if self.Health > 0 then
				HumanAIBehaviours.createVoiceSoundEffect(self, self.voiceSounds.Pain, 2, 2)
			else
				HumanAIBehaviours.createVoiceSoundEffect(self, self.voiceSounds.Death, 10, 4)
			end
		end		
	end
	
end

function HumanAIBehaviours.handleDying(self)
	if self.Head then
		if self.deathSoundPlayed ~= true then
			self.deathSoundPlayed = true;
			HumanAIBehaviours.createVoiceSoundEffect(self, self.voiceSounds.Death, 10, 4);
			self.deathCloseTimer:Reset();
		end
		if self.deathCloseTimer:IsPastSimMS(self.deathCloseDelay) then
			self.Head.Frame = self.baseHeadFrame + 1; -- (+1: eyes closed. rest in peace grunt)
		end
	end
end

function HumanAIBehaviours.handleSuppression(self)

	local blinkTimerReady = self.blinkTimer:IsPastSimMS(self.blinkDelay);
	local suppressionTimerReady = self.suppressionUpdateTimer:IsPastSimMS(1500);
	
	if (blinkTimerReady) and (not self.Suppressed) and self.Head then
		if self.Head.Frame == self.baseHeadFrame then
			HumanAIBehaviours.createEmotion(self, 1, 0, 100);
			self.blinkTimer:Reset();
			self.blinkDelay = math.random(5000, 11000);
		end
	end	
	
	if (suppressionTimerReady) then
		if self.Suppression > 25 then
			if self.suppressedVoicelineTimer:IsPastSimMS(self.suppressedVoicelineDelay) then
				if self.Suppression > 99 then
					-- keep playing voicelines if we keep being suppressed
					HumanAIBehaviours.createVoiceSoundEffect(self, self.voiceSounds.suppressedHigh, 5, 4);
					self.suppressedVoicelineTimer:Reset();
					self.suppressionUpdates = 0;
				elseif self.Suppression > 80 then
					HumanAIBehaviours.createVoiceSoundEffect(self, self.voiceSounds.suppressedMedium, 4, 4);
					self.suppressedVoicelineTimer:Reset();
					self.suppressionUpdates = 0;
				end
				if self.Suppressed == false then -- initial voiceline
					if self.Suppression > 55 then
						HumanAIBehaviours.createVoiceSoundEffect(self, self.voiceSounds.suppressedMedium, 4, 4);
					else
						HumanAIBehaviours.createVoiceSoundEffect(self, self.voiceSounds.suppressedLow, 3, 2);
					end
					self.suppressedVoicelineTimer:Reset();
				end
			end
			self.Suppressed = true;
		else
			self.Suppressed = false;
		end
		self.Suppression = math.min(self.Suppression, 100)
		if self.Suppression > 0 then
			self.Suppression = self.Suppression - 7;
		end
		self.Suppression = math.max(self.Suppression, 0);
		self.suppressionUpdateTimer:Reset();
	end
end

function HumanAIBehaviours.handleAITargetLogic(self)
	-- SPOT ENEMY REACTION
	-- works off of the native AI's target
	
	if not self.LastTargetID then
		self.LastTargetID = -1
	end
	
	-- AGRESSIVENESS
	if not self.Suppressed and self.Health > 55 and self.UniqueID % 2 == 0 then
		self.aggressive = true
	else
		self.aggressive = false
	end
	
	--spotEnemy
	
	if (not self:IsPlayerControlled()) and self.AI.Target and IsAHuman(self.AI.Target) then
	
		self.spotVoiceLineTimer:Reset();
		
		local posDifference = SceneMan:ShortestDistance(self.Pos,self.AI.Target.Pos,SceneMan.SceneWrapsX)
		local distance = posDifference.Magnitude
		
		if self.spotAllowed ~= false then
			
			if self.LastTargetID == -1 then
				self.LastTargetID = self.AI.Target.UniqueID
				-- Target spotted
				--local posDifference = SceneMan:ShortestDistance(self.Pos,self.AI.Target.Pos,SceneMan.SceneWrapsX)
				
				if not self.AI.Target:NumberValueExists("Heat Enemy Spotted Age") or -- If no timer exists
				self.AI.Target:GetNumberValue("Heat Enemy Spotted Age") < (self.AI.Target.Age - self.AI.Target:GetNumberValue("Heat Enemy Spotted Delay")) or -- If the timer runs out of time limit
				math.random(0, 100) < self.spotIgnoreDelayChance -- Small chance to ignore timers, to spice things up
				then
					-- Setup the delay timer
					self.AI.Target:SetNumberValue("Heat Enemy Spotted Age", self.AI.Target.Age)
					self.AI.Target:SetNumberValue("Heat Enemy Spotted Delay", math.random(self.spotDelayMin, self.spotDelayMax))
					
					self.spotAllowed = false;
					
					HumanAIBehaviours.createVoiceSoundEffect(self, self.voiceSounds.Spot, 3, 3);
					
				end
			else
				-- Refresh the delay timer
				if self.AI.Target:NumberValueExists("Heat Enemy Spotted Age") then
					self.AI.Target:SetNumberValue("Heat Enemy Spotted Age", self.AI.Target.Age)
				end
			end
		end
	else
		if self.spotVoiceLineTimer:IsPastSimMS(self.spotVoiceLineDelay) then
			self.spotAllowed = true;
		end
		if self.LastTargetID ~= -1 then
			self.LastTargetID = -1
			-- Target lost
			--print("TARGET LOST!")
		end
	end
end

function HumanAIBehaviours.handleVoicelines(self)

	-- squad stuff
	-- this is imperfect: itll only play when we go straight from being in a squad to being player controlled (i.e. we are now the leader)
	-- there is no way to see if we're leading a squad, so that close approximation is the best we can get.
	-- also means no VO when FORMING a squad :(

	if self.AIMode == 11 then
		self.inSquad = true;
	elseif self.inSquad == true and self:IsPlayerControlled() and self.leadVoiceLineTimer:IsPastSimMS(self.leadVoiceLineDelay) then
		self.inSquad = false;
		HumanAIBehaviours.createVoiceSoundEffect(self, self.voiceSounds.Lead, 3);
		self.leadVoiceLineTimer:Reset();
	else
		self.inSquad = false;
	end

	-- DEVICE RELATED VOICELINES
	
	if self.EquippedItem then	
		-- SUPPRESSING, RELOADING
		if (IsHDFirearm(self.EquippedItem)) then	
			if self.EquippedItem:IsInGroup("Weapons - Primary") then
				local gun = ToHDFirearm(self.EquippedItem);
				local reloading = gun:IsReloading();
				local gunMag = gun.Magazine
				
				if gun.FullAuto == true and gunMag and gunMag.Capacity > 10  and gun:IsActivated() then
					if gun.FiredFrame then
						self.gunShotCounter = self.gunShotCounter + 1;
					end
					if self.gunShotCounter > (gunMag.Capacity*0.7) and self.suppressingVoiceLineTimer:IsPastSimMS(self.suppressingVoiceLineDelay) then
						HumanAIBehaviours.createVoiceSoundEffect(self, self.voiceSounds.Battlecry, 3, 3);
						self.suppressingVoiceLineTimer:Reset();
					end
				else
					self.gunShotCounter = 0;
				end
				if (reloading) then
					if (self.reloadVoicelinePlayed ~= true) then
						if (math.random(1, 100) < 30) then
							HumanAIBehaviours.createVoiceSoundEffect(self, self.voiceSounds.Reload, 3, 2);
						end
						self.reloadVoicelinePlayed = true;
					end
				else
					self.reloadVoicelinePlayed = false;
				end
			end
		end
	end
end

function HumanAIBehaviours.handleAbilities(self)

	if self.Health < 80 and self.healJuice > 0 then
		self.toHeal = true;
	end
	
	if self.toHeal == true then
		if self.healDelayTimer:IsPastSimMS(self.healInitialDelay) then
			if self.healWarned ~= true then
				self.healWarned = true;
				self.healSounds.healWarning:Play(self.Pos);
				self.healSound = self.healSounds.healWarning;
				self.healSoundPlayed = false;
				self.healTimer:Reset();
			else
				if self.healTimer:IsPastSimMS(self.healDelay) and self.Health < 100 and self.healJuice > 0 then
					if self.healSoundPlayed ~= true then
						self.healSoundPlayed = true;
						if math.random(0, 100) < 2 then
							self.healSounds.Heal:Play(self.Pos);
							self.healSound = self.healSounds.Heal;
						elseif not self:IsPlayerControlled() then
							self.healSounds.healMono:Play(self.Pos);
							self.healSound = self.healSounds.healMono;
						elseif self.Health < 26 then
							self.healSounds.healStereoHigh:Play(self.Pos);
							self.healSound = self.healSounds.healStereoHigh;
						else
							self.healSounds.healStereo:Play(self.Pos);
							self.healSound = self.healSounds.healStereo;
						end
					end
					self.Healing = true;
				elseif self.Health >= 100 or self.healJuice < 0 then
					self.healWarned = false;
					self.Healing = false;
					self.toHeal = false;
					self.healTimer:Reset();
					self.healDelayTimer:Reset();
				end
			end
		end
	end
	
	if self.Healing == true then
		local value = (1 * TimerMan.DeltaTimeSecs * 100);
		self.Health = self.Health + value
		self.healJuice = self.healJuice - value
		for i = 1, 2 do
			if math.random(0, 100) < 15 then
				self:RemoveAnyRandomWounds(1);
			end
		end
		self.oldHealth = self.Health;
	end
	
	
	--- hovering
	
	if self.hoverCharging == false then
		if (self:IsPlayerControlled() and UInputMan:KeyPressed(15)) or self.hoverFuel <= 0 then
			if self.Hovering == true then
				self.hoverFuel = 0;
				self.Hovering = false;
				self.hoverFlameLoop:Stop(-1);
				self.hoverEngineLoop:Stop(-1);
				self.hoverSounds.hoverEnd:Play(self.Pos);
				self.hoverSound = self.hoverSounds.hoverEnd;
				
				self.hoverAnimTimer:Reset();
				
				--self.Vel = Vector(self.Vel.X, self.Vel.Y * 0.5);
				if self.Jetpack then
					self.Jetpack.Frame = 1
				end
				
				if self.Gender == 0 then
				
					self.voiceSounds = {
					Pain = CreateSoundContainer("VO Normal Female Pain HumanOfficer", "Heat.rte"),
					Death = CreateSoundContainer("VO Normal Female Death HumanOfficer", "Heat.rte"),
					Lead = CreateSoundContainer("VO Normal Female Lead HumanOfficer", "Heat.rte"),
					suppressedLow = CreateSoundContainer("VO Normal Female Suppressed Low HumanOfficer", "Heat.rte"),
					suppressedMedium = CreateSoundContainer("VO Normal Female Suppressed Medium HumanOfficer", "Heat.rte"),
					suppressedHigh = CreateSoundContainer("VO Normal Female Suppressed High HumanOfficer", "Heat.rte"),
					Battlecry = CreateSoundContainer("VO Normal Female Battlecry HumanOfficer", "Heat.rte"),
					Spot = CreateSoundContainer("VO Normal Female Spot HumanOfficer", "Heat.rte"),
					Reload = CreateSoundContainer("VO Normal Female Reload HumanOfficer", "Heat.rte")};
					
				else
				
					self.voiceSounds = {
					Pain = CreateSoundContainer("VO Normal Male Pain HumanOfficer", "Heat.rte"),
					Death = CreateSoundContainer("VO Normal Male Death HumanOfficer", "Heat.rte"),
					Lead = CreateSoundContainer("VO Normal Male Lead HumanOfficer", "Heat.rte"),
					suppressedLow = CreateSoundContainer("VO Normal Male Suppressed Low HumanOfficer", "Heat.rte"),
					suppressedMedium = CreateSoundContainer("VO Normal Male Suppressed Medium HumanOfficer", "Heat.rte"),
					suppressedHigh = CreateSoundContainer("VO Normal Male Suppressed High HumanOfficer", "Heat.rte"),
					Battlecry = CreateSoundContainer("VO Normal Male Battlecry HumanOfficer", "Heat.rte"),
					Spot = CreateSoundContainer("VO Normal Male Spot HumanOfficer", "Heat.rte"),
					Reload = CreateSoundContainer("VO Normal Male Reload HumanOfficer", "Heat.rte")};
					
				end
				
			else
				self.hoverCharging = true;
				self.hoverSounds.hoverCharge:Play(self.Pos);
				self.hoverSound = self.hoverSounds.hoverCharge;
				self.hoverChargeTimer:Reset();
			end
		end
		
		if self.Hovering then
		
			if self:IsPlayerControlled() then
				--[[
				-- Fuel Gauge
				-- Bar Background
				PrimitiveMan:DrawLinePrimitive(self.Pos + self.hoverFuelOffset + Vector(-self.hoverFuelLength, 0), self.Pos + self.hoverFuelOffset + Vector(self.hoverFuelLength, 0), 26);
				-- Bar Foreground
				local fac = math.max(math.min(self.hoverFuel / self.hoverFuelMax, 1), 0)
				PrimitiveMan:DrawLinePrimitive(self.Pos + self.hoverFuelOffset + Vector(-self.hoverFuelLength, 0), self.Pos + self.hoverFuelOffset + Vector(-self.hoverFuelLength + (self.hoverFuelLength * 2 * fac), 0), 116);
				]]
				self.hoverAIEndTimer:Reset();
			elseif self.hoverAIEndTimer:IsPastSimMS(self.hoverAIEndDelay) then
				self.hoverFuel = 0;
			end
		
			if not self.hoverEngineLoop:IsBeingPlayed() then
				self.hoverEngineLoop:Play(self.Pos);
			end
			if not self.hoverFlameLoop:IsBeingPlayed() then
				self.hoverFlameLoop:Play(self.Pos);
			end
			
			---
			local hoverVel = Vector(self.Vel.X, self.Vel.Y)
			
			local targetAltitude = self.hoverAltitudeTarget
			if self.Indoors == true and not self.controller:IsState(Controller.HOLD_UP) then
				self.controller:SetState(Controller.HOLD_DOWN, true);
				self.controller:SetState(Controller.BODY_CROUCH, true);
			end
				
			if self.controller:IsState(Controller.HOLD_DOWN) then
				targetAltitude = targetAltitude * 0.66
			elseif self.controller:IsState(Controller.HOLD_UP) then
				targetAltitude = targetAltitude * 1.4
			end
			
			if self.hoverUpdate:IsPastSimMS(60) then
				--self.hoverAltitude = SceneMan:FindAltitude(self.Pos, 200, 3);
				
				local inVec = Vector(0,-35);
				local inRay = SceneMan:CastObstacleRay(self.Pos, inVec, Vector(), Vector(), 0, self.Team, 0, 4);
				
				--PrimitiveMan:DrawLinePrimitive(self.Pos, self.Pos + inVec, 122);
				
				if inRay > 0 then
					self.Indoors = true;
				else
					self.Indoors = false;
				end
				
				-- Reset
				self.hoverTilt = 0
				self.hoverAltitude = targetAltitude
				
				-- Calculate
				local scanRays = 6
				local scanLength = targetAltitude + 30
				local scanArc = 45
				local scanPos = self.Pos
				for i = 0, (scanRays - 1) do
					local fac = ((i / (scanRays - 1)) - 0.5) * 2.0
					local ang = math.rad(scanArc * fac)
					local vec = Vector(0, scanLength):RadRotate(ang)
					
					local endPos = Vector(self.Pos.X, self.Pos.Y)
					local ray = SceneMan:CastObstacleRay(scanPos, vec, Vector(0, 0), endPos, 0 , self.Team, 0, 4) -- Do the hitscan stuff, raycast
					if ray ~= -1 then
						if self.hoverAltitude > ray then
							self.hoverAltitude = ray
						end
						local a = 1 - (ray / scanLength)
						self.hoverTilt = (self.hoverTilt + (ang * a))
					end
					
					--PrimitiveMan:DrawLinePrimitive(scanPos, scanPos + Vector(vec.X, vec.Y):SetMagnitude(ray), 122);
				end
				self.hoverTilt = self.hoverTilt / scanRays
				
				self.hoverUpdate:Reset()
			end
			--PrimitiveMan:DrawLinePrimitive(self.Pos, self.Pos + Vector(0, 15):RadRotate(self.hoverTilt), 5);
			
			--PrimitiveMan:DrawCirclePrimitive(self.Pos, self.hoverAltitude, 13)
			local factor = math.max((targetAltitude - self.hoverAltitude) / 100, 0)
			
			if self.Vel.Y > -8.0 then
				self.Vel = self.Vel - (SceneMan.GlobalAcc * TimerMan.DeltaTimeSecs * factor * 2.0):RadRotate(self.hoverTilt) - Vector(0, math.max(self.Vel.Y, 0)) * TimerMan.DeltaTimeSecs * 12.0 * factor
			end
			
			-- Input
			local input = 0
			input = input + (self.controller:IsState(Controller.HOLD_RIGHT) and 1 or 0)
			input = input - (self.controller:IsState(Controller.HOLD_LEFT) and 1 or 0)
			
			-- Damp X velocity
			local damp = 0.5
			if input == 1 then
				
				if self.Vel.X < 0 then
					self.Vel = Vector(self.Vel.X  / (1 + TimerMan.DeltaTimeSecs * damp * 2.5), self.Vel.Y)
				end
			elseif input == -1 then
				
				if self.Vel.X > 0 then
					self.Vel = Vector(self.Vel.X  / (1 + TimerMan.DeltaTimeSecs * damp * 2.5), self.Vel.Y)
				end
			else
				self.Vel = Vector(self.Vel.X / (1 + TimerMan.DeltaTimeSecs * damp), self.Vel.Y)
			end
			-- Movement
			local movementSpeed = 22
			local movementTargetVel = 15
			self.Vel = Vector(self.Vel.X + (movementSpeed * input * math.max((movementTargetVel - math.abs(self.Vel.X)) / movementTargetVel)) * TimerMan.DeltaTimeSecs, self.Vel.Y)
			
			-- Stop Animations
			self.controller:SetState(Controller.MOVE_RIGHT, false)
			self.controller:SetState(Controller.MOVE_LEFT, false)
			
			-- STABILITY
			if self.Status == 1 then
				self.Status = 0
			elseif self.Status == 0 then
				self.AngularVel = self.AngularVel - (self.Vel.X * 0.06 * RangeRand(0.4, 0.5));
			end
			---
			
			local change = self.Vel - hoverVel
			
			local value = (TimerMan.DeltaTimeSecs * 4) + (change.Magnitude * TimerMan.DeltaTimeSecs * 10);
			self.hoverFuel = math.max(self.hoverFuel - value, 0);
			
			self.hoverEngineLoop.Pitch = (change.Magnitude / 3 + self.Vel.Magnitude / 30) + 1;
			self.hoverEngineLoop.Pitch = math.min(self.hoverEngineLoop.Pitch, 1.7);
			
			if self.Jetpack then
				-- GFX
				if self.hoverGFXTimer:IsPastSimMS(26) then
					local effect = CreateMOSRotating("Ground Smoke Particle 1", "Heat.rte")
					effect.Pos = self.Jetpack.Pos + Vector(RangeRand(-1,1), RangeRand(-1,1)) * 6
					effect.Vel = self.Vel + Vector(math.random(110,200),0):RadRotate(math.pi * 1.5 + math.rad(45) * RangeRand(-1,1))
					effect.Lifetime = effect.Lifetime * RangeRand(0.8,2.0)
					effect.AirResistance = effect.AirResistance * RangeRand(0.5,0.8)
					MovableMan:AddParticle(effect)
					
					local effect = CreateMOSParticle(math.random(1,3) < 2 and "Small Smoke Ball 1 Glow Blue" or "Tiny Smoke Ball 1 Glow Blue", "Heat.rte")
					effect.Pos = self.Jetpack.Pos + Vector(-4 * self.Jetpack.FlipFactor, 6):RadRotate(self.Jetpack.RotAngle)
					effect.Vel = self.Vel + Vector(math.random(15,25),0):RadRotate(math.pi * 1.5 + math.rad(45) * RangeRand(-1,1))
					effect.Lifetime = effect.Lifetime * RangeRand(0.8,2.0) * 0.75
					effect.AirResistance = effect.AirResistance * RangeRand(1.0,1.2)
					MovableMan:AddParticle(effect)
					self.hoverGFXTimer:Reset()
				end
				--
				
				self.Jetpack.Frame = 2
				
				self.controller:SetState(Controller.BODY_JUMP, false)
				self.controller:SetState(Controller.BODY_JUMPSTART, false)
				self.Jetpack:EnableEmission(false);
			end
		else
			local value = (TimerMan.DeltaTimeSecs * 10);
			self.hoverFuel = math.min(self.hoverFuel + value, self.hoverFuelMax);
		
			if self.Jetpack and self.hoverAnimTimer:IsPastSimMS(self.hoverAnimDelay) then
				self.Jetpack.Frame = 0
			elseif self.Jetpack then
				self.Jetpack.Frame = 1;
			end
		end
		
	elseif self.hoverChargeTimer:IsPastSimMS(self.hoverChargeDelay) then
		self.hoverAIEndTimer:Reset();
		self.hoverCharging = false;
		self.Hovering = true;
		self.hoverFlameLoop:Play(self.Pos);
		self.hoverEngineLoop:Play(self.Pos);
		self.hoverSounds.hoverStart:Play(self.Pos);
		self.hoverSound = self.hoverSounds.hoverStart;
		
		local jumpVec = Vector(0,-10.0)
		
		self.Vel = Vector(self.Vel.X, self.Vel.Y + jumpVec.Y);
		
		if self.Gender == 0 then
		
			self.voiceSounds = {
			Pain = CreateSoundContainer("VO Normal Female Pain HumanOfficer", "Heat.rte"),
			Death = CreateSoundContainer("VO Normal Female Death HumanOfficer", "Heat.rte"),
			Lead = CreateSoundContainer("VO Megaphone Female Lead HumanOfficer", "Heat.rte"),
			suppressedLow = CreateSoundContainer("VO Megaphone Female Suppressed Low HumanOfficer", "Heat.rte"),
			suppressedMedium = CreateSoundContainer("VO Megaphone Female Suppressed Medium HumanOfficer", "Heat.rte"),
			suppressedHigh = CreateSoundContainer("VO Megaphone Female Suppressed High HumanOfficer", "Heat.rte"),
			Battlecry = CreateSoundContainer("VO Megaphone Female Battlecry HumanOfficer", "Heat.rte"),
			Spot = CreateSoundContainer("VO Megaphone Female Spot HumanOfficer", "Heat.rte"),
			Reload = CreateSoundContainer("VO Megaphone Female Reload HumanOfficer", "Heat.rte")};
			
		else
		
			self.voiceSounds = {
			Pain = CreateSoundContainer("VO Normal Male Pain HumanOfficer", "Heat.rte"),
			Death = CreateSoundContainer("VO Normal Male Death HumanOfficer", "Heat.rte"),
			Lead = CreateSoundContainer("VO Megaphone Male Lead HumanOfficer", "Heat.rte"),
			suppressedLow = CreateSoundContainer("VO Megaphone Male Suppressed Low HumanOfficer", "Heat.rte"),
			suppressedMedium = CreateSoundContainer("VO Megaphone Male Suppressed Medium HumanOfficer", "Heat.rte"),
			suppressedHigh = CreateSoundContainer("VO Megaphone Male Suppressed High HumanOfficer", "Heat.rte"),
			Battlecry = CreateSoundContainer("VO Megaphone Male Battlecry HumanOfficer", "Heat.rte"),
			Spot = CreateSoundContainer("VO Megaphone Male Spot HumanOfficer", "Heat.rte"),
			Reload = CreateSoundContainer("VO Megaphone Male Reload HumanOfficer", "Heat.rte")};
			
		end
		
	elseif self.hoverChargeTimer:IsPastSimMS(self.hoverChargeDelay - 100) then
		self.Jetpack.Frame = 1
	end
	
	if self.HUDVisible and self:IsPlayerControlled() and (self.Hovering or self.hoverFuel < self.hoverFuelMax) then
		-- Fuel Gauge
		local colors = {244, 46, 47, 48, 86, 87, 118, 135, 149, 162, 147}
		local fac = math.max(math.min(self.hoverFuel / self.hoverFuelMax, 1), 0)
		local color = colors[math.floor(fac * (#colors - 1) + 1.5)]
		for i = -1, 1 do
			-- Bar Background
			PrimitiveMan:DrawLinePrimitive(self.Pos + self.hoverFuelOffset + Vector(-self.hoverFuelLength, i), self.Pos + self.hoverFuelOffset + Vector(self.hoverFuelLength, i), 26);
			-- Bar Foreground
			PrimitiveMan:DrawLinePrimitive(self.Pos + self.hoverFuelOffset + Vector(-self.hoverFuelLength, i), self.Pos + self.hoverFuelOffset + Vector(-self.hoverFuelLength + (self.hoverFuelLength * 2 * fac), i), color);
		end
	end
	
end

function HumanAIBehaviours.handleHeadFrames(self)
	if not self.Head then return end
	if self.Emotion and self.emotionApplied ~= true and self.Head then
		self.Head.Frame = self.baseHeadFrame + self.Emotion;
		self.emotionApplied = true;
	end
		
		
	if self.emotionDuration > 0 and self.emotionTimer:IsPastSimMS(self.emotionDuration) then
		if (self.Suppressed or self.Suppressing) then
			self.Head.Frame = self.baseHeadFrame + 2;
		else
			self.Head.Frame = self.baseHeadFrame;
		end
	elseif (self.emotionDuration == 0) and ((not self.voiceSound or not self.voiceSound:IsBeingPlayed())) then
		-- if suppressed OR suppressing base emotion is angry
		if (self.Suppressed or self.Suppressing) then
			self.Head.Frame = self.baseHeadFrame + 2;
		else
			self.Head.Frame = self.baseHeadFrame;
		end
	end

end

function HumanAIBehaviours.handleHeadLoss(self)
	if not (self.Head) then
		self.voiceSounds = {};
		self.voiceSound:Stop(-1);
	end
end