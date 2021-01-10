
dofile("Base.rte/Constants.lua")
require("AI/NativeHumanAI")  --dofile("Base.rte/AI/NativeHumanAI.lua")
package.path = package.path .. ";Heat.rte/?.lua";
require("Actors/Infantry/HumanOfficer/HumanAIBehaviours")

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
	Land = CreateSoundContainer("Land HumanOfficer", "Heat.rte"),
	Jump = CreateSoundContainer("Jump HumanOfficer", "Heat.rte"),
	Crouch = CreateSoundContainer("Crouch HumanOfficer", "Heat.rte"),
	Stand = CreateSoundContainer("Stand HumanOfficer", "Heat.rte"),
	Step = CreateSoundContainer("Step HumanOfficer", "Heat.rte")};
	
	self.jumpJetSound = CreateSoundContainer("Jumpjet Start Heat", "Heat.rte");
	
	self.Gender = math.random(0, 1);
	
	if self.Gender == 0 then -- female
	
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
	
	self.voiceSound = CreateSoundContainer("VO Normal Female Pain HumanOfficer", "Heat.rte");
	-- MEANINGLESS! this is just so we can do voiceSound.Pos without an if check first! it will be overwritten first actual VO play

	self.altitude = 0;
	self.wasInAir = false;
	
	self.moveSoundTimer = Timer();
	self.moveSoundWalkTimer = Timer();
	self.wasCrouching = false;
	self.wasMoving = false;
	
	self.baseHeadFrame = 0;
	
	self.emotionTimer = Timer();
	self.emotionDuration = 0;
	
	self.blinkTimer = Timer();
	self.blinkDelay = math.random(5000, 11000);
	
	self.Suppression = 0;
	self.Suppressed = false;
	
	self.reloadVoicelineTimer = Timer();
	self.reloadVoicelineDelay = 5000;
	
	self.suppressionUpdateTimer = Timer();
	
	self.suppressedVoicelineTimer = Timer();
	self.suppressedVoicelineDelay = 5000;
	
	self.healthUpdateTimer = Timer();
	self.oldHealth = self.Health;

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
	
	-- End modded code
end

function Update(self)

	self.controller = self:GetController();
	
	if self.alternativeGib then
		HumanFunctions.DoAlternativeGib(self);
	end
	if self.automaticEquip then
		HumanFunctions.DoAutomaticEquip(self);
	end
	if self.armSway then
		HumanFunctions.DoArmSway(self, (self.Health/self.MaxHealth));	--Argument: shove strength
	end
	if self.visibleInventory then
		HumanFunctions.DoVisibleInventory(self, false);	--Argument: whether to show all items
	end
	
	-- Start modded code--

	self.voiceSound.Pos = self.Pos;
	
	if (self:IsDead() ~= true) then
		
		HumanAIBehaviours.handleMovement(self);
		
		HumanAIBehaviours.handleHealth(self);
		
		HumanAIBehaviours.handleSuppression(self);
		
		HumanAIBehaviours.handleAITargetLogic(self);
		
		HumanAIBehaviours.handleVoicelines(self);
		
		HumanAIBehaviours.handleHeadFrames(self);

	else
	
		HumanAIBehaviours.handleDying(self)
	
		HumanAIBehaviours.handleHeadLoss(self);
		
		HumanAIBehaviours.handleMovement(self);
		
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
