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
			if math.random(0, 100) < 10 then
				self:RemoveAnyRandomWounds(1);
			end
		end
		self.oldHealth = self.Health;
	end
	
	
	--- hovering
	
	if self.hoverCharging == false then
		if (self:IsPlayerControlled() and UInputMan:KeyPressed(15)) then
			if self.Hovering == true then
				self.Hovering = false;
				self.hoverFlameLoop:Stop(-1);
				self.hoverEngineLoop:Stop(-1);
				self.hoverSounds.hoverEnd:Play(self.Pos);
				self.hoverSound = self.hoverSounds.hoverEnd;
				
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
		
			if not self.hoverEngineLoop:IsBeingPlayed() then
				self.hoverEngineLoop:Play(self.Pos);
			end
			if not self.hoverFlameLoop:IsBeingPlayed() then
				self.hoverFlameLoop:Play(self.Pos);
			end
		
			self.hoverEngineLoop.Pitch = (self.Vel.Magnitude / 20) + 1;
			self.hoverEngineLoop.Pitch = math.min(self.hoverEngineLoop.Pitch, 1.5);
			
			if self.Jetpack then
				self.Jetpack:EnableEmission(false);
			end
		end
		
	elseif self.hoverChargeTimer:IsPastSimMS(self.hoverChargeDelay) then
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
		if (self.voiceSound) then
			self.voiceSound:Stop(-1);
		end
	end
end