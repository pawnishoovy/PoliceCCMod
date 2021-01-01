function Create(self)

	self.idleLoop = CreateSoundContainer("Idle Loop PoliceCraft", "Heat.rte");
	self.engineLoop = CreateSoundContainer("Engine Loop PoliceCraft", "Heat.rte");

end

function Update(self)

	if not self.idleLoop:IsBeingPlayed() then
		self.idleLoop:Play(self.Pos);
	end

	if self.Vel.Magnitude > 2 and not self.engineLoop:IsBeingPlayed() then
		self.engineLoop:Play(self.Pos);
	elseif self.Vel.Magnitude <= 2 then
		self.engineLoop:Stop(-1);
	end
	
	self.idleLoop.Pos = self.Pos;
	self.engineLoop.Pos = self.Pos;
	
	if self.engineLoop:IsBeingPlayed() then
		self.engineLoop.Volume = self.Vel.Magnitude / 28;
		self.engineLoop.Pitch = (self.Vel.Magnitude / 28) + 1;
	end

	if self.Vel.Magnitude > 30 then
		local vec = self.Vel + Vector(0, 0);
		self.Vel = vec:SetMagnitude(30);
	end

end

function Destroy(self)

	if self.idleLoop:IsBeingPlayed() then
		self.idleLoop:Stop(-1);
	end

	if self.engineLoop:IsBeingPlayed() then
		self.engineLoop:Stop(-1);
	end
	
end

