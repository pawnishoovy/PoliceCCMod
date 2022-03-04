
dofile("Base.rte/Constants.lua")
require("AI/NativeHumanAI")  --dofile("Base.rte/AI/NativeHumanAI.lua")
package.path = package.path .. ";Heat.rte/?.lua";
require("Actors/Infantry/CyborgHeavy/CyborgAIBehaviours")

function Create(self)
	self.AI = NativeHumanAI:Create(self)
	--You can turn features on and off here
	self.armSway = true;
	self.automaticEquip = false;
	self.alternativeGib = false;
	self.visibleInventory = false;
	
	-- Start modded code --
	
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
	
	-- End modded code
end

function Update(self)

	self.controller = self:GetController();
	
	-- Start modded code--

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
-- End modded code --

function UpdateAI(self)
	self.AI:Update(self)

end

function Destroy(self)
	self.AI:Destroy(self)
	
	-- Start modded code --
	
	if not self.ToSettle then -- we have been gibbed		
		self.voiceSound:Stop(-1);
	end
	
	-- End modded code --
	
end
