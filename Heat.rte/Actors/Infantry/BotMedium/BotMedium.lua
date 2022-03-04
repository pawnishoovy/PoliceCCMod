
dofile("Base.rte/Constants.lua")
require("AI/NativeHumanAI")  --dofile("Base.rte/AI/NativeHumanAI.lua")
package.path = package.path .. ";Heat.rte/?.lua";
require("Actors/Infantry/BotMedium/BotMediumAIBehaviours")

function Create(self)
	self.AI = NativeHumanAI:Create(self)
	--You can turn features on and off here
	self.armSway = true;
	self.automaticEquip = false;
	self.alternativeGib = true;
	self.visibleInventory = false;
	
	-- Start modded code --
	
	self.RTE = "Heat.rte";
	self.baseRTE = "Heat.rte";
	
	self.movementSounds = {
	Land = CreateSoundContainer("Land BotMedium", "Heat.rte"),
	Jump = CreateSoundContainer("Jump BotMedium", "Heat.rte"),
	Crouch = CreateSoundContainer("Crouch BotMedium", "Heat.rte"),
	Stand = CreateSoundContainer("Stand BotMedium", "Heat.rte"),
	Step = CreateSoundContainer("Step BotMedium", "Heat.rte")};
	
	self.jumpJetSound = CreateSoundContainer("Jumpjet Start Heat", "Heat.rte");
	
	if math.random(0, 1) == 0 then
		self.voiceSounds = {
		Spot = CreateSoundContainer("VO Spot VariantOne", "Heat.rte"),
		Death = CreateSoundContainer("VO Death VariantOne", "Heat.rte"),
		Suppressed = CreateSoundContainer("VO Suppressed VariantOne", "Heat.rte"),
		deployDrone = CreateSoundContainer("VO Drone Deploy VariantOne", "Heat.rte")};
	else
		self.voiceSounds = {
		Spot = CreateSoundContainer("VO Spot VariantTwo", "Heat.rte"),
		Death = CreateSoundContainer("VO Death VariantTwo", "Heat.rte"),
		Suppressed = CreateSoundContainer("VO Suppressed VariantTwo", "Heat.rte"),
		deployDrone = CreateSoundContainer("VO Drone Deploy VariantTwo", "Heat.rte")};
	end
	
	self.voiceSound = CreateSoundContainer("VO Pain Heat", "Heat.rte");
	-- MEANINGLESS! this is just so we can do voiceSound.Pos without an if check first! it will be overwritten first actual VO play

	self.altitude = 0;
	self.wasInAir = false;
	
	self.moveSoundTimer = Timer();
	self.moveSoundWalkTimer = Timer();
	self.wasCrouching = false;
	self.wasMoving = false;
	
	self.healthUpdateTimer = Timer();
	self.oldHealth = self.Health;
	
	self.Suppression = 0;
	self.Suppressed = false;
	
	self.suppressionUpdateTimer = Timer();
	
	self.suppressedVoicelineTimer = Timer();
	self.suppressedVoicelineDelay = 5000;
	
	self.spotVoiceLineTimer = Timer();
	self.spotVoiceLineDelay = 15000;
	
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
	
	-- Start modded code--
	
	self.voiceSound.Pos = self.Pos;
	
	if (self:IsDead() ~= true) then
		
		BotMediumAIBehaviours.handleMovement(self);
		
		BotMediumAIBehaviours.handleHealth(self);
		
		BotMediumAIBehaviours.handleAITargetLogic(self);
		
		BotMediumAIBehaviours.handleVoicelines(self);
		
		BotMediumAIBehaviours.handleSuppression(self);
		

	else
	
		BotMediumAIBehaviours.handleHeadLoss(self);
		
		BotMediumAIBehaviours.handleDying(self);
	
		BotMediumAIBehaviours.handleMovement(self);
		
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
