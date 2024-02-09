package.path = package.path .. ";Heat.rte/?.lua";
require("Actors/Infantry/HumanOfficer/HumanAIBehaviours")

function Create(self)
	
	self.RTE = "Heat.rte";
	self.baseRTE = "Heat.rte";
	
	self.movementSounds = {
	Land = CreateSoundContainer("Land HumanOfficer", "Heat.rte"),
	Jump = CreateSoundContainer("Jump HumanOfficer", "Heat.rte"),
	Crouch = CreateSoundContainer("Crouch HumanOfficer", "Heat.rte"),
	Stand = CreateSoundContainer("Stand HumanOfficer", "Heat.rte"),
	Step = CreateSoundContainer("Step HumanOfficer", "Heat.rte")};
	
	self.jumpJetSound = CreateSoundContainer("Jumpjet Start HumanOfficer", "Heat.rte");
	
	if (self:NumberValueExists("Gender") and self:GetNumberValue("Gender") == 0) or (self:NumberValueExists("Identity") and self:GetNumberValue("Identity") > 2) or math.random(0,100) < 40 then -- female
		
		if not self:NumberValueExists("Identity") then
			self:SetNumberValue("Identity", math.random(2,4))
		end
		self.baseHeadFrame = self:GetNumberValue("Identity") * 5;
		self.Gender = 0
		
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
		
	else -- male
		
		if not self:NumberValueExists("Identity") then
			self:SetNumberValue("Identity", math.random(0,1))
		end
		self.baseHeadFrame = self:GetNumberValue("Identity") * 5;
		self.Gender = 1
		
		if self.Head then
			self.Head:SetEntryWound("Wound Flesh Helmet Entry HumanOfficer", "Heat.rte");
			self.Head:SetExitWound("Wound Flesh Helmet Exit HumanOfficer", "Heat.rte");
		end
		
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
	
	self.emotionTimer = Timer();
	self.emotionDuration = 0;
	
	self.blinkTimer = Timer();
	self.blinkDelay = math.random(5000, 11000);
	
	self.deathCloseTimer = Timer();
	self.deathCloseDelay = 750;
	
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
	
	-- heal ability
	
	self.healSounds = {
	healWarning = CreateSoundContainer("Heal Warning HumanOfficer", "Heat.rte"),
	healStereo = CreateSoundContainer("Heal Stereo HumanOfficer", "Heat.rte"),
	healStereoInterrupt = CreateSoundContainer("Heal Stereo Interrupt HumanOfficer", "Heat.rte"),
	healStereoHigh = CreateSoundContainer("Heal Stereo High HumanOfficer", "Heat.rte"),
	healMono = CreateSoundContainer("Heal Mono HumanOfficer", "Heat.rte"),
	healMonoInterrupt = CreateSoundContainer("Heal Mono Interrupt HumanOfficer", "Heat.rte"),
	Heal = CreateSoundContainer("Heal HumanOfficer", "Heat.rte")};
	
	self.healSound = CreateSoundContainer("VO Normal Female Pain HumanOfficer", "Heat.rte");
	-- MEANINGLESS! also
	
	self.healDelayTimer = Timer();
	self.healTimer = Timer();
	
	self.healInitialDelay = 10000;
	self.healDelay = 2000;
	
	self.healJuice = 250;    -- not actually hp idk why, this translates to 100-150 hp heal
	self.healThreshold = 80; -- hp below which to try to heal
							 -- ideally i'd heal anytime below 100 but the sounds and the timers get iffy since we want to heal even when bleeding lightly
							 
	self.hoverSounds = {
	hoverCharge = CreateSoundContainer("Hover Charge HumanOfficer", "Heat.rte"),
	hoverStart = CreateSoundContainer("Hover Start HumanOfficer", "Heat.rte"),
	hoverEnd = CreateSoundContainer("Hover End HumanOfficer", "Heat.rte")};
	
	self.hoverCharging = false;
	self.hoverChargeTimer = Timer();
	self.hoverChargeDelay = 800;
	
	self.hoverAltitudeTarget = 100
	self.hoverAltitude = 0
	self.hoverTilt = 0
	self.hoverGFXTimer = Timer()
	self.hoverUpdate = Timer()
	
	self.Hovering = false;
	
	self.hoverFuel = 100;
	self.hoverFuelMax = 100;
	
	self.hoverFuelOffset = Vector(0, -26);
	self.hoverFuelLength = 10;
	
	self.hoverAIEndTimer = Timer();
	self.hoverAIEndDelay = 5000;
	
	self.hoverAnimTimer = Timer();
	self.hoverAnimDelay = 300;
	
	self.hoverSound = CreateSoundContainer("VO Normal Female Pain HumanOfficer", "Heat.rte");
	-- MEANINGLESS! also
	
	self.hoverFlameLoop = CreateSoundContainer("Hover Flame Loop HumanOfficer", "Heat.rte");
	self.hoverEngineLoop = CreateSoundContainer("Hover Engine Loop HumanOfficer", "Heat.rte");
	

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
	
	
	self.MeleeAISkill = 0.6;
end

function ThreadedUpdate(self)

	self.controller = self:GetController();

	self.voiceSound.Pos = self.Pos;
	self.healSound.Pos = self.Pos;
	self.hoverSound.Pos = self.Pos;
	self.hoverFlameLoop.Pos = self.Pos;
	self.hoverEngineLoop.Pos = self.Pos;
	
	if (self:IsDead() ~= true) then
		
		HumanAIBehaviours.handleMovement(self);
		
		HumanAIBehaviours.handleHealth(self);
		
		HumanAIBehaviours.handleSuppression(self);
		
		HumanAIBehaviours.handleAITargetLogic(self);
		
		HumanAIBehaviours.handleVoicelines(self);
		
		HumanAIBehaviours.handleAbilities(self);
		
		HumanAIBehaviours.handleHeadFrames(self);

	else
	
		HumanAIBehaviours.handleDying(self)
	
		HumanAIBehaviours.handleHeadLoss(self);
		
		HumanAIBehaviours.handleMovement(self);
		
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
	
		HumanAIBehaviours.createVoiceSoundEffect(self, self.voiceSounds.Battlecry, 3, 3, false);
		
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
			HumanAIBehaviours.createVoiceSoundEffect(self, self.voiceSounds.Battlecry, 3, 3, false);
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
	
	self.hoverEngineLoop:Stop(-1);
	self.hoverFlameLoop:Stop(-1);
	
end
