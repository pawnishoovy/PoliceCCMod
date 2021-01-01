
dofile("Base.rte/Constants.lua")
require("AI/NativeHumanAI")  --dofile("Base.rte/AI/NativeHumanAI.lua")
package.path = package.path .. ";Heat.rte/?.lua";
require("Actors/Infantry/CyborgHeavy/CyborgAIBehaviours")

function Create(self)
	self.AI = NativeHumanAI:Create(self)
	--You can turn features on and off here
	self.armSway = true;
	self.automaticEquip = true;
	self.alternativeGib = false;
	self.visibleInventory = true;
	
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
	Lead = CreateSoundContainer("VO Lead CyborgHeavy", "Heat.rte")};

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
	
	self.emotionTimer = Timer();
	self.emotionDuration = 0;
	
	self.baseHeadFrame = 0;
	
	self.blinkTimer = Timer();
	self.blinkDelay = math.random(5000, 11000);
	
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

-- Start modded code --

-- End modded code --

function OnCollideWithTerrain(self, terrainID)
	-- let Fall sounds know to play this
	self.terrainCollided = true;
	self.terrainCollidedWith = terrainID;
	--if self.Dying or self.Status == Actor.DEAD or self.Status == Actor.DYING then
	--	CyborgAIBehaviours.handleRagdoll(self)
	--end
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
	
	if (UInputMan:KeyPressed(26)) and self:IsPlayerControlled() then
		self.Health = self.Health -26
	end
	
	if UInputMan:KeyPressed(3) and self:IsPlayerControlled() then
		self.Health = self.Health -51
	end
	
	if (UInputMan:KeyPressed(24)) and self:IsPlayerControlled() then
		self.Health = self.Health -2
	end
	
	if self.voiceSound then
		self.voiceSound.Pos = self.Pos;
	end
	
	if (self:IsDead() ~= true) then
		
		CyborgAIBehaviours.handleMovement(self);
		
		CyborgAIBehaviours.handleHealth(self);
		
		CyborgAIBehaviours.handleSuppression(self);
		
		CyborgAIBehaviours.handleAITargetLogic(self);
		
		CyborgAIBehaviours.handleVoicelines(self);
		
		CyborgAIBehaviours.handleHeadFrames(self);
		
		CyborgAIBehaviours.handleAbilities(self)

	else
	
		CyborgAIBehaviours.handleDying(self)
	
		CyborgAIBehaviours.handleHeadLoss(self);
		
		CyborgAIBehaviours.handleMovement(self);
		
	end
	
	-- clear terrain stuff after we did everything that used em
	
	self.terrainCollided = false;
	self.terrainCollidedWith = nil;
end
-- End modded code --

function UpdateAI(self)
	self.AI:Update(self)

end

function Destroy(self)
	self.AI:Destroy(self)
	
	-- Start modded code --
	
	if ActivityMan:ActivityRunning() then -- for some reason the game crashes if you switch activities (i.e. start a new one) while this actor is active
										  -- presumably it attempts to destroy this, which then tells it to do a buncha stuff and it just goes mad
										  -- this check is to see if the activity is running, since you have to be paused to switch activities. hopefully.
										  -- it is possible Void Wanderers switches activities without pausing. thus this may not work and induce a crash	
	
		if not self.ToSettle then -- we have been gibbed
			
			if (self.voiceSound) then
				if (self.voiceSound:IsBeingPlayed()) then
					self.voiceSound:Stop(-1);
					self.voiceSound = nil;
				end
			end
			--[[
			for actor in MovableMan.Actors do
				if actor.Team == self.Team then
					local d = SceneMan:ShortestDistance(actor.Pos, self.Pos, true).Magnitude;
					if d < 300 then
						local strength = SceneMan:CastStrengthSumRay(self.Pos, actor.Pos, 0, 128);
						if strength < 500 then
							actor:SetNumberValue("Sandstorm Friendly Down", 1)
							break;  -- first come first serve
						else
							if IsAHuman(actor) and actor.Head then -- if it is a human check for head
								local strength = SceneMan:CastStrengthSumRay(self.Pos, ToAHuman(actor).Head.Pos, 0, 128);	
								if strength < 500 then		
									actor:SetNumberValue("Sandstorm Friendly Down", 1)
									break; -- first come first serve
								end
							end
						end
					end
				end
			end]]
		end
		
	end
	
	-- End modded code --
	
end
