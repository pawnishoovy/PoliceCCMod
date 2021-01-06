
dofile("Base.rte/Constants.lua")
require("AI/NativeHumanAI")  --dofile("Base.rte/AI/NativeHumanAI.lua")
package.path = package.path .. ";Heat.rte/?.lua";
require("Actors/Shared/HeatAIBehaviours")

function Create(self)
	self.AI = NativeHumanAI:Create(self)
	--You can turn features on and off here
	self.armSway = true;
	self.automaticEquip = true;
	self.alternativeGib = true;
	self.visibleInventory = true;
	
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
	
	self.emotionTimer = Timer();
	self.emotionDuration = 0;
	
	self.baseHeadFrame = 0;
	
	self.blinkTimer = Timer();
	self.blinkDelay = math.random(5000, 11000);

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
		
		HeatAIBehaviours.handleMovement(self);
		
		HeatAIBehaviours.handleHealth(self);
		
		HeatAIBehaviours.handleHeadFrames(self);

	else
	
		HeatAIBehaviours.handleHeadLoss(self);
	
		HeatAIBehaviours.handleMovement(self);
		
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
