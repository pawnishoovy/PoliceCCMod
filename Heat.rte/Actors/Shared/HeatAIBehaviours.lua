HeatAIBehaviours = {};

function HeatAIBehaviours.createSoundEffect(self, effectName, variations)
	if effectName ~= nil then
		self.soundEffect = AudioMan:PlaySound(effectName .. math.random(1, variations) .. ".ogg", self.Pos, -1, 0, 130, 1, 400, false);	
	end
end

function HeatAIBehaviours.createEmotion(self, emotion, priority, duration, canOverridePriority)
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
	end
end

function HeatAIBehaviours.createVoiceSoundEffect(self, effectName, variations, priority, emotion, canOverridePriority)
	if canOverridePriority == nil then
		canOverridePriority = false;
	end
	local usingPriority
	if canOverridePriority == false then
		usingPriority = priority - 1;
	else
		usingPriority = priority;
	end
	if self.Head and effectName ~= nil then
		if self.voiceSound then
			if self.voiceSound:IsBeingPlayed() then
				if self.lastPriority <= usingPriority then
					if emotion then
						HeatAIBehaviours.createEmotion(self, emotion, priority, 0, canOverridePriority);
					end
					self.voiceSound:Stop();
					self.voiceSound = AudioMan:PlaySound(effectName .. math.random(1, variations) .. ".ogg", self.Pos, -1, 0, 130, 1, 450, false);
					self.lastPriority = priority;
					return true;
				end
			else
				if emotion then
					HeatAIBehaviours.createEmotion(self, emotion, priority, 0, canOverridePriority);
				end
				self.voiceSound = AudioMan:PlaySound(effectName .. math.random(1, variations) .. ".ogg", self.Pos, -1, 0, 130, 1, 450, false);
				self.lastPriority = priority;
				return true;
			end
		else
			if emotion then
				HeatAIBehaviours.createEmotion(self, emotion, priority, 0, canOverridePriority);
			end
			self.voiceSound = AudioMan:PlaySound(effectName .. math.random(1, variations) .. ".ogg", self.Pos, -1, 0, 130, 1, 450, false);
			self.lastPriority = priority;
			return true;
		end
	end
end
function HeatAIBehaviours.handleMovement(self)
	
	local crouching = self.controller:IsState(Controller.BODY_CROUCH)
	local moving = self.controller:IsState(Controller.MOVE_LEFT) or self.controller:IsState(Controller.MOVE_RIGHT);
	
	-- Custom Jump
	if self.controller:IsState(Controller.BODY_JUMPSTART) == true and self.controller:IsState(Controller.BODY_CROUCH) == false and self.jumpTimer:IsPastSimMS(self.jumpDelay) and not self.isJumping then
		if self.wasInAir == false then
			local jumpVec = Vector(0,-1.5)
			local jumpWalkX = 3
			if self.controller:IsState(Controller.MOVE_LEFT) == true then
				jumpVec.X = -jumpWalkX
			elseif self.controller:IsState(Controller.MOVE_RIGHT) == true then
				jumpVec.X = jumpWalkX
			end
			HeatAIBehaviours.createSoundEffect(self, self.movementSounds.Jump, self.movementSoundVariations.Jump);
			if math.abs(self.Vel.X) > jumpWalkX * 2.0 then
				self.Vel = Vector(self.Vel.X, self.Vel.Y + jumpVec.Y)
			else
				self.Vel = Vector(self.Vel.X + jumpVec.X, self.Vel.Y + jumpVec.Y)
			end
			self.isJumping = true
			self.jumpTimer:Reset()
			self.jumpStop:Reset()
			self.jumpBoost:Reset()
		end
	elseif self.isJumping then
		if self.wasInAir == false and self.jumpStop:IsPastSimMS(100) then
			self.isJumping = false
			if self.Vel.Y > 0 then
				HeatAIBehaviours.createSoundEffect(self, self.movementSounds.Land, self.movementSoundVariations.Land);
			end
		else
			if self.controller:IsState(Controller.BODY_JUMP) == true and not self.jumpBoost:IsPastSimMS(200) then
				self.Vel = self.Vel - SceneMan.GlobalAcc * TimerMan.DeltaTimeSecs * 1.0 -- Stop the gravity
			end
		end
	end
	
	if (self.wasInAir and self.Vel.Y < 10) then
		self.altitude = SceneMan:FindAltitude(self.Pos, 100, 3);
		if self.altitude < 25 then
			self.wasInAir = false;
			HeatAIBehaviours.createSoundEffect(self, self.movementSounds.Land, self.movementSoundVariations.Land);
		end
	end

	if (crouching) then
		if (not self.wasCrouching and self.moveSoundTimer:IsPastSimMS(800)) then
			HeatAIBehaviours.createSoundEffect(self, self.movementSounds.Crouch, self.movementSoundVariations.Crouch);
		end
		if (moving) then
			if (self.moveSoundWalkTimer:IsPastSimMS(700)) then
				SecurityAIBehaviours.createSoundEffect(self, self.movementSounds.Step, self.movementSoundVariations.Step);
				self.moveSoundWalkTimer:Reset();
			end
		end
	else
		if (self.wasCrouching and self.moveSoundTimer:IsPastSimMS(800)) then
			HeatAIBehaviours.createSoundEffect(self, self.movementSounds.Stand, self.movementSoundVariations.Stand);
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

function HeatAIBehaviours.handleHealth(self)

	local healthTimerReady = self.healthUpdateTimer:IsPastSimMS(750);
	local wasInjured = self.Health < (self.oldHealth - 25);

	if (healthTimerReady or wasInjured) then
		self.oldHealth = self.Health;
		self.healthUpdateTimer:Reset();
		
		if (wasInjured or wasHeavilyInjured) and self.Head then
			
			if self.Health > 0 then
				HeatAIBehaviours.createVoiceSoundEffect(self, self.voiceSounds.Pain, self.voiceSoundVariations.Pain, 5)
			end
		end
	end
	
end

function HeatAIBehaviours.handleHeadFrames(self)
	if not self.Head then return end
	if self.Emotion and self.emotionApplied ~= true and self.Head then
		self.Head.Frame = self.baseHeadFrame + self.Emotion;
		self.emotionApplied = true;
	end
		
		
	if self.emotionDuration > 0 and self.emotionTimer:IsPastSimMS(self.emotionDuration) then
		self.Head.Frame = self.baseHeadFrame;
	elseif (self.emotionDuration == 0) and ((not self.voiceSound or not self.voiceSound:IsBeingPlayed())) then
		self.Head.Frame = self.baseHeadFrame;
	end

end

function HeatAIBehaviours.handleVoicelines(self)

end

