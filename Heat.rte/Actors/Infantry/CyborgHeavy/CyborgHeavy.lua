package.path = package.path .. ";Heat.rte/?.lua";
require("Actors/Infantry/CyborgHeavy/CyborgAIBehaviours")

function Create(self)
	
	self.RTE = "Heat.rte";
	self.baseRTE = "Heat.rte";
	
	self.movementSounds = {
	Land = CreateSoundContainer("Land CyborgHeavy", "Heat.rte"),
	Jump = CreateSoundContainer("Jump CyborgHeavy", "Heat.rte"),
	Crouch = CreateSoundContainer("Crouch CyborgHeavy", "Heat.rte"),
	Stand = CreateSoundContainer("Stand CyborgHeavy", "Heat.rte"),
	Step = CreateSoundContainer("Step CyborgHeavy", "Heat.rte")};
	
	self.jumpJetSound = CreateSoundContainer("Jumpjet Start Cyborg", "Heat.rte");
	
	self.voiceSounds = {
	Pain = CreateSoundContainer("VO Pain CyborgHeavy", "Heat.rte"),
	Death = CreateSoundContainer("VO Death CyborgHeavy", "Heat.rte"),
	Hold = CreateSoundContainer("VO Hold CyborgHeavy", "Heat.rte"),
	Suppressed = CreateSoundContainer("VO Suppressed CyborgHeavy", "Heat.rte"),
	Battlecry = CreateSoundContainer("VO Battlecry CyborgHeavy", "Heat.rte"),
	Intimidate = CreateSoundContainer("VO Intimidate CyborgHeavy", "Heat.rte"),
	Lead = CreateSoundContainer("VO Lead CyborgHeavy", "Heat.rte"),
	meleeYell = CreateSoundContainer("VO Melee Yell CyborgHeavy", "Heat.rte"),
	Respect = CreateSoundContainer("VO Respect CyborgHeavy", "Heat.rte")};
	
	self.voiceSound = CreateSoundContainer("VO Pain CyborgHeavy", "Heat.rte");
	-- MEANINGLESS! this is just so we can do voiceSound.Pos without an if check first! it will be overwritten first actual VO play

	self.altitude = 0;
	self.wasInAir = false;
	
	self.moveSoundTimer = Timer();
	self.moveSoundWalkTimer = Timer();
	self.wasCrouching = false;
	self.wasMoving = false;
	
	self.Suppression = 0;
	self.Suppressed = false;
	
	self.suppressionUpdateTimer = Timer();
	
	self.suppressedVoicelineTimer = Timer();
	self.suppressedVoicelineDelay = 5000;
	
	self.healthUpdateTimer = Timer();
	self.oldHealth = self.Health;
	
	if math.random(0, 100) < 5 then
		self.toSelfDestruct = true;
		self.selfDestructThreshold = 5;
		self.GibWoundLimit = 5000;
	end
	
	self.holdVoiceLineTimer = Timer();
	self.holdVoiceLineDelay = 15000;
	
	self.spotVoiceLineTimer = Timer();
	self.spotVoiceLineDelay = 15000;
	
	self.gunShotCounter = 0;
	self.suppressingVoiceLineTimer = Timer();
	self.suppressingVoiceLineDelay = 15000;
	
	self.leadVoiceLineTimer = Timer();
	self.leadVoiceLineDelay = 15000;
	
	 -- in MS
	self.spotDelayMin = 4000;
	self.spotDelayMax = 8000;
	
	 -- in percent
	self.spotIgnoreDelayChance = 10;
	self.spotNoVoicelineChance = 15;

	-- fil jump
	
	-- Leg Collision Detection system
    self.feetContact = {false, false}
    self.feetTimers = {Timer(), Timer()}
	self.footstepTime = 100 -- 2 Timers to avoid noise
	
	-- Custom Jumping
	self.isJumping = false
	self.jumpTimer = Timer();
	self.jumpDelay = 500;
	self.jumpStop = Timer();
	
	-- Extra Movement
	self.boosterReady = true
	self.boosterTimer = Timer()
	self.boosterAIDelay = 6000
	
	-- Abilities
	
	self.Shield = CreateHeldDevice("Sergeant's Shield", "Heat.rte");
	self.shieldUsed = false;
	self.shieldAITrigger = false
	
	
	self.MeleeAISkill = 1;
	
end

function ThreadedUpdate(self)

	self.controller = self:GetController();

	self.voiceSound.Pos = self.Pos;
	
	if (self:IsDead() ~= true) then
		
		CyborgAIBehaviours.handleMovement(self);
		
		CyborgAIBehaviours.handleHealth(self);
		
		CyborgAIBehaviours.handleSuppression(self);
		
		CyborgAIBehaviours.handleAITargetLogic(self);
		
		CyborgAIBehaviours.handleVoicelines(self);
		
		CyborgAIBehaviours.handleAbilities(self)
		
		if self.selfDestructing then
			CyborgAIBehaviours.handleSelfDestruct(self)
		end

	else
	
		if self.selfDestructing then
			self:GibThis();
		end
	
		CyborgAIBehaviours.handleDying(self)
	
		CyborgAIBehaviours.handleHeadLoss(self);
		
		CyborgAIBehaviours.handleMovement(self);
		
	end

end

function SyncedUpdate(self)

	-- Thread-unsafe number value crap
	
	if self.AI.Target then
		if self.threadingJustSpotted then
			self.AI.Target:SetNumberValue("Heat Enemy Spotted Age", self.AI.Target.Age)
			self.AI.Target:SetNumberValue("Heat Enemy Spotted Delay", math.random(self.spotDelayMin, self.spotDelayMax))
		else
			self.AI.Target:SetNumberValue("Heat Enemy Spotted Age", self.AI.Target.Age)
		end
	end
	
	if self.threadingWarcried then
		
		if math.random(0, 100) < 50 then
			CyborgAIBehaviours.createVoiceSoundEffect(self, self.voiceSounds.Battlecry, 3, false);
		else
			CyborgAIBehaviours.createVoiceSoundEffect(self, self.voiceSounds.Intimidate, 3, false);
		end
		
		if self.EquippedItem and (self.EquippedItem:IsInGroup("Weapons - Mordhau Melee") or self.EquippedItem:NumberValueExists("Weapons - Mordhau Melee")) then
			self.EquippedItem:SetNumberValue("Warcried", 1);
		end
		
		for actor in MovableMan:GetMOsInRadius(self.Pos, 200, Activity.NOTEAM, true) do
			if IsAHuman(actor) and actor.Team == self.Team then
				actor = ToAHuman(actor);
				local d = SceneMan:ShortestDistance(actor.Pos, self.Pos, true).Magnitude;
				local strength = SceneMan:CastStrengthSumRay(self.Pos, actor.Pos, 0, 128);
				if strength < 400 and math.random(1, 100) < 85 then
					actor:SetNumberValue("Warcry Together", 1)
				else
					if IsAHuman(actor) and actor.Head then -- if it is a human check for head
						local strength = SceneMan:CastStrengthSumRay(self.Pos, ToAHuman(actor).Head.Pos, 0, 128);	
						if strength < 400 and math.random(1, 100) < 85 then		
							actor:SetNumberValue("Warcry Together", 1)
						end
					end
				end
			end
		end
		
		self:SetNumberValue("Warcried", 1);
	elseif self:NumberValueExists("Warcry Together") then
	
		if not self.AI.Target then
			if math.random(0, 100) < 50 then
				CyborgAIBehaviours.createVoiceSoundEffect(self, self.voiceSounds.Battlecry, 3, false);
			else
				CyborgAIBehaviours.createVoiceSoundEffect(self, self.voiceSounds.Intimidate, 3, false);
			end
			if self.EquippedItem and (self.EquippedItem:IsInGroup("Weapons - Mordhau Melee") or self.EquippedItem:NumberValueExists("Weapons - Mordhau Melee")) then
				self.EquippedItem:SetNumberValue("Warcried", 1);
			end
		end
		
		self:RemoveNumberValue("Warcry Together");
	end

	self.threadingJustSpotted = false;
	self.threadingWarcried = false;
	
end

function Destroy(self)
	
	if not self.ToSettle then -- we have been gibbed		
		self.voiceSound:Stop(-1);
	end
	
end
