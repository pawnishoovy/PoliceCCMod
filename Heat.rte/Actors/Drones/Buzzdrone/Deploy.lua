function Create(self)
	self.active = false
	self.canSpawn = false
	
	self.Deploy = CreateSoundContainer("Deploy Buzzdrone", "Heat.rte");
	
	self.actorPresetName = "Buzzdrone"
	
	self.Team = -1;
end

function Update(self)
	if self.ID ~= self.RootID then
		local actor = MovableMan:GetMOFromID(self.RootID);
		if MovableMan:IsActor(actor) then
			self.Team = ToActor(actor).Team;
			self.parent = ToActor(actor);
		end
	end
	
	if self:IsActivated() and self.ID == self.RootID then
		self.active = true
	end
	
	if self.canSpawn and not self.ToDelete then
		local actor = CreateActor(self.actorPresetName);
		actor.Pos = self.Pos;
		actor.RotAngle = self.RotAngle;
		actor.AngularVel = self.AngularVel;
		actor.Vel = self.Vel;
		actor.HFlipped = self.HFlipped;
		actor.Team = self.Team;
		actor.IgnoresTeamHits = true;
		MovableMan:AddActor(actor);
		
		self.Deploy:Play(self.Pos)
		
		self.ToDelete = true
		self.canSpawn = false
	end
	
	if self:IsActivated() and self.parent and self.numberValueSet ~= true then
		self.parent:SetNumberValue("DeployedHeatDrone", 1);
		self.numberValueSet = true;
	end
	
end

function OnCollideWithMO(self, collidedMO, collidedRootMO)
	if self.active then
		self.canSpawn = true
	end
end

function OnCollideWithTerrain(self, terrainID)
	if self.active then
		self.canSpawn = true
	end
end