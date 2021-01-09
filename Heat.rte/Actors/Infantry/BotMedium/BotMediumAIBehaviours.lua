BotMediumAIBehaviours = {};

-- function BotMediumAIBehaviours.createSoundEffect(self, effectName, variations)
	-- if effectName ~= nil then
		-- self.soundEffect = AudioMan:PlaySound(effectName .. math.random(1, variations) .. ".ogg", self.Pos, -1, 0, 130, 1, 400, false);	
	-- end
-- end

-- no longer needed as of pre3!

function BotMediumAIBehaviours.createVoiceSoundEffect(self, soundContainer, priority, emotion, canOverridePriority)
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
						BotMediumAIBehaviours.createEmotion(self, emotion, priority, 0, canOverridePriority);
					end
					self.voiceSound:Stop();
					self.voiceSound = soundContainer;
					soundContainer:Play(self.Pos)
					self.lastPriority = priority;
					return true;
				end
			else
				if emotion then
					BotMediumAIBehaviours.createEmotion(self, emotion, priority, 0, canOverridePriority);
				end
				self.voiceSound = soundContainer;
				soundContainer:Play(self.Pos)
				self.lastPriority = priority;
				return true;
			end
		else
			if emotion then
				BotMediumAIBehaviours.createEmotion(self, emotion, priority, 0, canOverridePriority);
			end
			self.voiceSound = soundContainer;
			soundContainer:Play(self.Pos)
			self.lastPriority = priority;
			return true;
		end
	end
end

function BotMediumAIBehaviours.handleMovement(self)
	
	local crouching = self.controller:IsState(Controller.BODY_CROUCH)
	local moving = self.controller:IsState(Controller.MOVE_LEFT) or self.controller:IsState(Controller.MOVE_RIGHT);
	
	-- Leg Collision Detection system
    --local i = 0
	if self:IsPlayerControlled() then -- AI doesn't update its own foot checking when playercontrolled so we have to do it
		if self.Vel.Y > 10 then
			self.wasInAir = true;
		else
			self.wasInAir = false;
		end
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
	else
		if self.AI.flying == true and self.wasInAir == false then
			self.wasInAir = true;
		elseif self.AI.flying == false and self.wasInAir == true then
			self.wasInAir = false;
			self.isJumping = false
			if self.moveSoundTimer:IsPastSimMS(500) then
				self.movementSounds.Land:Play(self.Pos);
				self.moveSoundTimer:Reset();
			end
		end
	end
	
	
	
	-- Custom Jump
	if self.controller:IsState(Controller.BODY_JUMPSTART) == true and self.controller:IsState(Controller.BODY_CROUCH) == false and self.jumpTimer:IsPastSimMS(self.jumpDelay) and not self.isJumping then
		if (self:IsPlayerControlled() and self.feetContact[1] == true or self.feetContact[2] == true) or self.wasInAir == false then
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
		if (self:IsPlayerControlled() and self.feetContact[1] == true or self.feetContact[2] == true) and self.jumpStop:IsPastSimMS(100) then
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
		
			self.isJumping = true;
			self.jumpJetSound:Play(self.Pos);
			
			self.Vel = Vector(self.Vel.X, self.Vel.Y):RadRotate(-self.RotAngle)
			self.Vel = Vector(self.Vel.X, self.Vel.Y * 0.5)
			self.Vel = Vector(self.Vel.X, self.Vel.Y):RadRotate(self.RotAngle)
			
			self.Vel = self.Vel + Vector(0, -10):RadRotate(self.RotAngle)
			self.boosterReady = false
			
			self.boosterTimer:Reset()
			
			local offset = Vector(-4, 6)--Vector(self.Jetpack.EmissionOffset.X, self.Jetpack.EmissionOffset.Y)
			
			local emitterA = CreateAEmitter("Heat Jetpack Smoke Trail Medium")
			emitterA.Lifetime = 1300
			self.Jetpack:AddAttachable(emitterA);
			
			ToAttachable(emitterA).ParentOffset = offset
			
			local emitterB = CreateAEmitter("Heat Jetpack Smoke Trail Heavy")
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

	self.wasCrouching = crouching;
	self.wasMoving = moving;
end

function BotMediumAIBehaviours.handleHealth(self)

	local healthTimerReady = self.healthUpdateTimer:IsPastSimMS(750);
	local wasLightlyInjured = self.Health < (self.oldHealth - 1);
	local wasInjured = self.Health < (self.oldHealth - 6);

	if (healthTimerReady or wasInjured or wasLightlyInjured) then
	
		self.oldHealth = self.Health;
		self.healthUpdateTimer:Reset();
		
		if (wasLightlyInjured) then		
			self.Suppression = self.Suppression + 10;	
		end
		
		if (wasInjured) and self.Head then
			self.Suppression = self.Suppression + 15;
			if self.Health > 0 then
			else
				BotMediumAIBehaviours.createVoiceSoundEffect(self, self.voiceSounds.Death, 10)
			end
		end
	end
	
end

function BotMediumAIBehaviours.handleAITargetLogic(self)
	-- SPOT ENEMY REACTION
	-- works off of the native AI's target
	
	if not self.LastTargetID then
		self.LastTargetID = -1
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
					
					BotMediumAIBehaviours.createVoiceSoundEffect(self, self.voiceSounds.Spot, 3);
					
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

function BotMediumAIBehaviours.handleSuppression(self)

	local suppressionTimerReady = self.suppressionUpdateTimer:IsPastSimMS(1500);
	
	if (suppressionTimerReady) then
		if self.Suppression > 50 then
			if self.Suppression > 99 and self.suppressedVoicelineTimer:IsPastSimMS(self.suppressedVoicelineDelay) then
				-- keep playing voicelines if we keep being suppressed to the max
				BotMediumAIBehaviours.createVoiceSoundEffect(self, self.voiceSounds.Suppressed, 5);
				self.suppressedVoicelineTimer:Reset();
			end
			if self.Suppressed == false and self.suppressedVoicelineTimer:IsPastSimMS(self.suppressedVoicelineDelay) then -- initial voiceline
				BotMediumAIBehaviours.createVoiceSoundEffect(self, self.voiceSounds.Suppressed, 5);
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

function BotMediumAIBehaviours.handleDying(self)
	if self.Head then
		if self.deathSoundPlayed ~= true then
			self.deathSoundPlayed = true;
			BotMediumAIBehaviours.createVoiceSoundEffect(self, self.voiceSounds.Death, 10);
		end		
	end
end

function BotMediumAIBehaviours.handleVoicelines(self)
	
	if self:NumberValueExists("DeployedHeatDrone") then
	
		self:RemoveNumberValue("DeployedHeatDrone");
		BotMediumAIBehaviours.createVoiceSoundEffect(self, self.voiceSounds.deployDrone, 3);
	end
	
end

function BotMediumAIBehaviours.handleHeadLoss(self)
	if not (self.Head) then
		self.voiceSounds = {};
		if (self.voiceSound) then
			self.voiceSound:Stop(-1);
		end
	end
end