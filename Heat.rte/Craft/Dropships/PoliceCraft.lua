function Create(self)

	self.idleLoop = CreateSoundContainer("Idle Loop PoliceCraft", "Heat.rte");
	self.engineLoop = CreateSoundContainer("Engine Loop PoliceCraft", "Heat.rte");
	
	self.Accelerate = CreateSoundContainer("Accelerate PoliceCraft", "Heat.rte");
	self.Deccelerate = CreateSoundContainer("Deccelerate PoliceCraft", "Heat.rte");
	
	self.upBoost = CreateSoundContainer("Up Boost PoliceCraft", "Heat.rte");
	
	self.Moving = false;
	
	self.moveTimer = Timer();
	
	self.sirenWhoop = CreateSoundContainer("Siren Whoop PoliceCraft", "Heat.rte");	
	self.sirenWhoop:Play(self.Pos);
	
	self.sirenBlast = CreateSoundContainer("Siren Blast PoliceCraft", "Heat.rte");
	
	self.healthUpdateTimer = Timer();
	self.oldHealth = self.Health;
	
	--ToGameActivity(ActivityMan:GetActivity()):GetBanner(GUIBanner.YELLOW, 0):ShowText("oh lawd they coming", GUIBanner.FLYBYLEFTWARD, 1000, Vector(FrameMan.PlayerScreenWidth, FrameMan.PlayerScreenHeight), 0.4, 4000, 0);
end

function Update(self)

	local cont = self:GetController();
	
	if self.healthUpdateTimer:IsPastSimMS(1000) then
		self.healthUpdateTimer:Reset();
		if self.Health < self.oldHealth - 50 then
			self.sirenBlast:Play(self.Pos);
		end
		self.oldHealth = self.Health
	end
	
	if self.Health > 0 and self.RotAngle ~= 0 and self.RotAngle < math.pi/2 and self.RotAngle > -math.pi/2 then

		self.AngularVel = self.AngularVel*(1-self.Health/1000)-math.sin(self.RotAngle*2)*(self.Health/1000);

		--print(self.AngularVel);
	end
	
	if self.Vel.Magnitude < 5 then
		if self.Moving == true then
			if self.moveTimer:IsPastSimMS(600) then
				self.Accelerate:Stop(-1);
				self.Deccelerate:Play(self.Pos);
				self.moveTimer:Reset();
			end
			self.moveTimer:Reset();
			self.Moving = false;
		end
		if self.Vel.Magnitude < 1 then
			if cont:IsState(Controller.MOVE_UP) then
				self.upBoost:Play(self.Pos);
				self.Vel = self.Vel + Vector(0, -4);
			end
		end
	else
		if self.Moving == false then
			if self.moveTimer:IsPastSimMS(600) then
				self.Deccelerate:Stop(-1);
				self.Accelerate:Play(self.Pos);
			end
			self.moveTimer:Reset();
			self.Moving = true;
		end	
		
	end	

	if self.Vel.Magnitude > 2 and not self.engineLoop:IsBeingPlayed() then
		self.engineLoop:Play(self.Pos);
	elseif self.Vel.Magnitude <= 2 then
		self.engineLoop:Stop(-1);
	end
	
	self.idleLoop.Pos = self.Pos;
	self.engineLoop.Pos = self.Pos;
	self.Accelerate.Pos = self.Pos;
	self.Deccelerate.Pos = self.Pos;
	self.upBoost.Pos = self.Pos;
	self.sirenBlast.Pos = self.Pos;
	
	if self.engineLoop:IsBeingPlayed() then
		self.engineLoop.Volume = self.Vel.Magnitude / 28;
		self.engineLoop.Pitch = (self.Vel.Magnitude / 28) + 1;
	end
	
	if self.idleLoop:IsBeingPlayed() then
		self.idleLoop.Volume = 1 - (self.Vel.Magnitude / 60);
	else
		self.idleLoop:Play(self.Pos);
	end
	if self.Vel.Magnitude > 30 then
		local vec = self.Vel + Vector(0, 0);
		self.Vel = vec:SetMagnitude(30);
	end

end

function Destroy(self)

	self.idleLoop:Stop(-1);

	self.engineLoop:Stop(-1);
	
	self.Accelerate:Stop(-1);
	
	self.Deccelerate:Stop(-1);
	
	self.sirenBlast:Stop(-1);
	
end

