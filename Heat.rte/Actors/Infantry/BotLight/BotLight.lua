package.path = package.path .. ";Heat.rte/?.lua";
require("Actors/Shared/HeatAIBehaviours")

function Create(self)
	
	self.RTE = "Heat.rte";
	self.baseRTE = "Heat.rte";
	
	self.movementSounds = {
	Land = CreateSoundContainer("Land BotLight", "Heat.rte"),
	Jump = CreateSoundContainer("Jump BotLight", "Heat.rte"),
	Crouch = CreateSoundContainer("Crouch BotLight", "Heat.rte"),
	Stand = CreateSoundContainer("Stand BotLight", "Heat.rte"),
	Step = CreateSoundContainer("Step BotLight", "Heat.rte")};
	
	self.jumpJetSound = CreateSoundContainer("Jumpjet Start Heat", "Heat.rte");
	
	self.voiceSounds = {
	Pain = CreateSoundContainer("VO Pain Heat", "Heat.rte")};
	
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
	
end

function ThreadedUpdate(self)

	self.controller = self:GetController();
	
	self.voiceSound.Pos = self.Pos;
	
	if (self:IsDead() ~= true) then
		
		HeatAIBehaviours.handleMovement(self);
		
		HeatAIBehaviours.handleHealth(self);

	else
	
		HeatAIBehaviours.handleHeadLoss(self);
	
		HeatAIBehaviours.handleMovement(self);
		
	end

end

function Destroy(self)

	if not self.ToSettle then -- we have been gibbed
		self.voiceSound:Stop(-1);		
	end
	
end
