
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
	Land = self.baseRTE.."/Actors/Infantry/BotLight/Sounds/Movement/Land/Land",
	Jump = self.baseRTE.."/Actors/Infantry/BotLight/Sounds/Movement/Jump/Jump",
	Crouch = self.baseRTE.."/Actors/Infantry/BotLight/Sounds/Movement/Crouch/Crouch",
	Stand = self.baseRTE.."/Actors/Infantry/BotLight/Sounds/Movement/Stand/Stand",
	Step = self.baseRTE.."/Actors/Infantry/BotLight/Sounds/Movement/Step/Step"};
	
	self.movementSoundVariations = {Land = 5,
	Jump = 5,
	Crouch = 3,
	Stand = 3,
	Step = 5};
	
	self.voiceSounds = {Pain = 
	self.RTE.."/Actors/Shared/Sounds/VO/Pain/Pain"};
	
	self.voiceSoundVariations = {Pain =	5};

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
	
	-- Custom Jumping
	self.isJumping = false
	self.jumpTimer = Timer();
	self.jumpDelay = 500;
	self.jumpStop = Timer();
	self.jumpBoost = Timer();
	
	-- End modded code
end

-- Start modded code --

-- End modded code --

function OnCollideWithTerrain(self, terrainID)
	-- let Fall sounds know to play this
	self.terrainCollided = true;
	self.terrainCollidedWith = terrainID;
	--if self.Dying or self.Status == Actor.DEAD or self.Status == Actor.DYING then
	--	HeatAIBehaviours.handleRagdoll(self)
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
		self.Health = self.Health -6
	end
	
	if self.voiceSound then
		if self.voiceSound:IsBeingPlayed() then
			self.voiceSound:SetPosition(self.Pos);
		end
	end
	
	if (self:IsDead() ~= true) then
		
		HeatAIBehaviours.handleMovement(self);
		
		HeatAIBehaviours.handleHealth(self);
		
		HeatAIBehaviours.handleVoicelines(self);
		
		HeatAIBehaviours.handleHeadFrames(self);

	else
	
		HeatAIBehaviours.handleMovement(self);
		
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
