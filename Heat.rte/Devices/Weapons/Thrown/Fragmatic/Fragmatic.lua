function Create(self)

	self.beepSound = CreateSoundContainer("Beep Fragmatic", "Heat.rte");
	self.imminentSound = CreateSoundContainer("Imminent Beep Fragmatic", "Heat.rte");
	self.pullPinSound = CreateSoundContainer("Pull Pin Fragmatic", "Heat.rte");
	
	self.bounceSound = CreateSoundContainer("Grenade Bounce Heat", "Heat.rte");
	self.rollSound = CreateSoundContainer("Grenade Roll Heat", "Heat.rte");
	
	self.Frame = 2;
	
	self.Beeps = 0;
	self.beepDelay = 330;
	self.beepSound.Pitch = 1;
	self.imminentPlayed = false;
	self.fuzeDelay = 5000;
	self.payload = CreateMOSRotating("Fragmatic Grenade Payload", "Heat.rte");
	
	self.lastVel = Vector(self.Vel.X, self.Vel.Y)
	
	self.impulse = Vector()
	self.bounceSoundTimer = Timer()	
	
	self.smallAngle = math.pi/6;
	self.angleList = {};

	self.clusterCount = 4;
end
function Update(self)

	self.impulse = (self.Vel - self.lastVel) / TimerMan.DeltaTimeSecs * self.Vel.Magnitude * 0.1
	self.lastVel = Vector(self.Vel.X, self.Vel.Y)

	self.beepSound.Pos = self.Pos;
	self.imminentSound.Pos = self.Pos;
	
	if self.fuze then
		if self.beepTimer:IsPastSimMS(self.beepDelay) then
			self.beepTimer:Reset();
			
			self.Frame = 1;
			
			self.beepDelay = self.beepDelay - 8;
			self.beepSound.Pitch = self.beepSound.Pitch * 1.03;
			self.Beeps = self.Beeps + 1;
			
			if self.Beeps < 16 then
				self.beepSound:Play(self.Pos);
			else
				self.beepDelay = 9999;
				self.imminentSound:Play(self.Pos);
			end
		elseif self.Beeps < 16 then
			self.Frame = 0;
		end
			
		if self.fuze:IsPastSimMS(self.fuzeDelay) then
			self:GibThis();
			self.angleList = {};
			for i = 1, 12 do
				local angleCheck = self.smallAngle * i;
				for i = 1, 5 do
					local checkPos = self.Pos + Vector(i, 0):RadRotate(angleCheck);
					if SceneMan.SceneWrapsX == true then
						if checkPos.X > SceneMan.SceneWidth then
							checkPos = Vector(checkPos.X - SceneMan.SceneWidth, checkPos.Y);
						elseif checkPos.X < 0 then
							checkPos = Vector(SceneMan.SceneWidth + checkPos.X, checkPos.Y);
						end
					end
					local terrCheck = SceneMan:GetTerrMatter(checkPos.X, checkPos.Y);
					if terrCheck ~= rte.airID then
						break;
					end
					if i == 5 then
						self.angleList[#self.angleList + 1] = angleCheck;
					end
				end
			end
			for i = 1, self.clusterCount do
				local minibomb = CreateAEmitter("Fragmatic Grenade Fragment");
				minibomb.Pos = self.Pos;
				minibomb.Sharpness = math.random(26,100) * math.max(math.random(0,3), 1)
				if #self.angleList > 0 then
					minibomb.Vel = Vector(3000 / minibomb.Sharpness, 0):RadRotate(self.angleList[math.random(#self.angleList)] + RangeRand(-0.1, 0.1));
				else
					minibomb.Vel = Vector(3000 / minibomb.Sharpness, 0):DegRotate(45 * i + ((math.random() * 15) - 7.5));
				end
				MovableMan:AddParticle(minibomb);
			end
		end
		
	elseif self:IsActivated() and not self.fuze then
		self.pullPinSound:Play(self.Pos);
		self.beepTimer = Timer();
		self.fuze = Timer();
	end
end

function OnCollideWithTerrain(self, terrainID)
	if self.bounceSoundTimer:IsPastSimMS(50) then
		if self.impulse.Magnitude > 25 then -- Hit
			self.bounceSound:Play(self.Pos);
			self.bounceSoundTimer:Reset()
		elseif self.impulse.Magnitude > 11 then -- Roll
			self.rollSound:Play(self.Pos);
			self.bounceSoundTimer:Reset()
		end
	end
end

function Destroy(self)
	if self.fuze and self.payload then
		self.payload.Pos = Vector(self.Pos.X, self.Pos.Y);
		MovableMan:AddParticle(self.payload);
		self.payload:GibThis();
	end
end