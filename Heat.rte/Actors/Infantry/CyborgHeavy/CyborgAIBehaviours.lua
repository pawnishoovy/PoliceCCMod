CyborgAIBehaviours = {};

-- function CyborgAIBehaviours.createSoundEffect(self, effectName, variations)
	-- if effectName ~= nil then
		-- self.soundEffect = AudioMan:PlaySound(effectName .. math.random(1, variations) .. ".ogg", self.Pos, -1, 0, 130, 1, 400, false);	
	-- end
-- end

-- no longer needed as of pre3!

function CyborgAIBehaviours.createVoiceSoundEffect(self, soundContainer, priority, canOverridePriority)
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
					self.voiceSound:Stop();
					self.voiceSound = soundContainer;
					soundContainer:Play(self.Pos)
					self.lastPriority = priority;
					return true;
				end
			else
				self.voiceSound = soundContainer;
				soundContainer:Play(self.Pos)
				self.lastPriority = priority;
				return true;
			end
		else
			self.voiceSound = soundContainer;
			soundContainer:Play(self.Pos)
			self.lastPriority = priority;
			return true;
		end
	end
end

function CyborgAIBehaviours.handleMovement(self)
	
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
			local jumpVec = Vector(0,-1.5)
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
		
		if boosting and self.boosterReady then
		
			self.jumpJetSound:Play(self.Pos);
			
			self.Vel = Vector(self.Vel.X, self.Vel.Y):RadRotate(-self.RotAngle)
			self.Vel = Vector(self.Vel.X, self.Vel.Y * 0.5)
			self.Vel = Vector(self.Vel.X, self.Vel.Y):RadRotate(self.RotAngle)
			
			self.Vel = self.Vel + Vector(0, -10):RadRotate(self.RotAngle)
			self.boosterReady = false
			
			self.boosterTimer:Reset()
			
			local offset = Vector(-4, 6)--Vector(self.Jetpack.EmissionOffset.X, self.Jetpack.EmissionOffset.Y)
			
			local emitterA = CreateAEmitter("Cyborg Jetpack Smoke Trail Medium")
			emitterA.Lifetime = 1300
			self.Jetpack:AddAttachable(emitterA);
			
			ToAttachable(emitterA).ParentOffset = offset
			
			local emitterB = CreateAEmitter("Cyborg Jetpack Smoke Trail Heavy")
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

function CyborgAIBehaviours.handleHealth(self)

	local healthTimerReady = self.healthUpdateTimer:IsPastSimMS(750);
	local wasLightlyInjured = self.Health < (self.oldHealth - 1);
	local wasInjured = self.Health < (self.oldHealth - 6);

	if (healthTimerReady or wasInjured or wasLightlyInjured) then
	
		if self.toSelfDestruct and not self.selfDestructing then
			if (self.Health < self.selfDestructThreshold) or (self.WoundCount > 40) then
				self.selfDestructing = true;
				CyborgAIBehaviours.createVoiceSoundEffect(self, self.voiceSounds.Respect, 9)
			end
		end
	
		self.oldHealth = self.Health;
		self.healthUpdateTimer:Reset();
		
		if (wasLightlyInjured) then		
			self.Suppression = self.Suppression + 5;	
		end
		
		if (wasInjured) and self.Head then
			self.Suppression = self.Suppression + 10;
			if self.Health > 0 then
				CyborgAIBehaviours.createVoiceSoundEffect(self, self.voiceSounds.Pain, 4)
			else
				CyborgAIBehaviours.createVoiceSoundEffect(self, self.voiceSounds.Death, 10)
			end
		end
	end
end

function CyborgAIBehaviours.handleSelfDestruct(self)
	
	self.Health = self.selfDestructThreshold;
	if self.Status == 3 then
		self.Status = 1;
	end
	self.controller:SetState(Controller.WEAPON_DROP,true);

	if not self.voiceSound:IsBeingPlayed() then
		self:GibThis();
	end
end

function CyborgAIBehaviours.handleDying(self)
	if self.Head then
		if self.deathSoundPlayed ~= true then
			self.deathSoundPlayed = true;
			CyborgAIBehaviours.createVoiceSoundEffect(self, self.voiceSounds.Death, 10);
		end		
	end
end

function CyborgAIBehaviours.handleSuppression(self)

	local suppressionTimerReady = self.suppressionUpdateTimer:IsPastSimMS(1500);
	
	if (suppressionTimerReady) then
		if self.Suppression > 50 then
			if self.Suppression > 99 and self.suppressedVoicelineTimer:IsPastSimMS(self.suppressedVoicelineDelay) then
				-- keep playing voicelines if we keep being suppressed to the max
				CyborgAIBehaviours.createVoiceSoundEffect(self, self.voiceSounds.Suppressed, 5);
				self.suppressedVoicelineTimer:Reset();
			end
			if self.Suppressed == false and self.suppressedVoicelineTimer:IsPastSimMS(self.suppressedVoicelineDelay) then -- initial voiceline
				CyborgAIBehaviours.createVoiceSoundEffect(self, self.voiceSounds.Suppressed, 5);
				self.suppressedVoicelineTimer:Reset();
			end
			self.Suppressed = true;
		else
			self.Suppressed = false;
		end
		self.Suppression = math.min(self.Suppression, 100)
		if self.Suppression > 0 then
			self.Suppression = self.Suppression - 5;
		end
		self.Suppression = math.max(self.Suppression, 0);
		self.suppressionUpdateTimer:Reset();
	end
end

function CyborgAIBehaviours.handleAITargetLogic(self)
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
		
		if self.shieldUsed == false and (distance < 300 or self.Health < 70) then -- AI shield trigger
			self.shieldAITrigger = true
		end
		
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
					
					CyborgAIBehaviours.createVoiceSoundEffect(self, self.voiceSounds.Intimidate, 3);
					
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

function CyborgAIBehaviours.handleVoicelines(self)

	-- squad stuff
	-- this is imperfect: itll only play when we go straight from being in a squad to being player controlled (i.e. we are now the leader)
	-- there is no way to see if we're leading a squad, so that close approximation is the best we can get.
	-- also means no VO when FORMING a squad :(

	if self.AIMode == 11 then
		self.inSquad = true;
	elseif self.inSquad == true and self:IsPlayerControlled() and self.leadVoiceLineTimer:IsPastSimMS(self.leadVoiceLineDelay) then
		self.inSquad = false;
		CyborgAIBehaviours.createVoiceSoundEffect(self, self.voiceSounds.Lead, 3);
		self.leadVoiceLineTimer:Reset();
	else
		self.inSquad = false;
	end
	
	if self:NumberValueExists("Melee Attacked") then
		self:RemoveNumberValue("Melee Attacked");
		CyborgAIBehaviours.createVoiceSoundEffect(self, self.voiceSounds.meleeYell, 3);
	end
		
		
	-- holding
	
	if self.AIMode == 1 then
		if self.Holding == false then
			self.Holding = true;
			
			if self.holdVoiceLineTimer:IsPastSimMS(self.holdVoiceLineDelay) then
				CyborgAIBehaviours.createVoiceSoundEffect(self, self.voiceSounds.Hold, 3);
				self.holdVoiceLineTimer:Reset();
			end
		end
	else
		self.Holding = false;
	end
	
	-- DEVICE RELATED VOICELINES
	
	if self.EquippedItem then	
		-- SUPPRESSING
		if (IsHDFirearm(self.EquippedItem)) then	
			if self.EquippedItem:IsInGroup("Weapons - Primary") then
				local gun = ToHDFirearm(self.EquippedItem);
				local gunMag = gun.Magazine
				
				if gun.FullAuto == true and gunMag and gunMag.Capacity > 10  and gun:IsActivated() then
					if gun.FiredFrame then
						self.gunShotCounter = self.gunShotCounter + 1;
					end
					if self.gunShotCounter > (gunMag.Capacity*0.7) and self.suppressingVoiceLineTimer:IsPastSimMS(self.suppressingVoiceLineDelay) then
						CyborgAIBehaviours.createVoiceSoundEffect(self, self.voiceSounds.Battlecry, 3);
						self.suppressingVoiceLineTimer:Reset();
					end
				else
					self.gunShotCounter = 0;
				end
			end
		end
	end
end

function CyborgAIBehaviours.handleAbilities(self)
	if (self:IsPlayerControlled() and UInputMan:KeyPressed(15)) or self.shieldAITrigger == true then
		if self.shieldUsed == false then
			self:AddInventoryItem(self.Shield);
			self.shieldUsed = true;
		end
	end
	
	if self.EquippedItem and IsHDFirearm(self.EquippedItem)then
		local gun = ToHDFirearm(self.EquippedItem)
		if not gun:NumberValueExists("CyborgOneHand") then
			local attachment = CreateAttachable("One Hand Attachment CyborgHeavy", "Heat.rte");
			gun:AddAttachable(attachment);
			gun:SetNumberValue("CyborgOneHand", 1);
		end
	end
	
end

function CyborgAIBehaviours.handleHeadLoss(self)
	if not (self.Head) then
		self.voiceSounds = {};
		self.voiceSound:Stop(-1);
	end
end