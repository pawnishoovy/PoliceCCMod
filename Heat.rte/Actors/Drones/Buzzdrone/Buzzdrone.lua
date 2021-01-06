
function Create(self)

	self.hoverSpeed = 1.0;
	
	self.hoverPosTarget = Vector(self.Pos.X, self.Pos.Y);
	self.hoverVelocityTarget = 0;
	self.hoverVelocity = 0;
	self.hoverVelocitySpeed = 3;
	self.hoverDirectionTarget = 0;
	self.hoverDirection = 0;
	self.hoverDirectionSpeed = 11.25;
	
	-- Sounds
	self.hoverLoop = CreateSoundContainer("Hover Loop Buzzdrone", "Heat.rte");
	
	self.sawLoop = CreateSoundContainer("Saw Loop Buzzdrone", "Heat.rte");
	self.sawStart = CreateSoundContainer("Saw Start Buzzdrone", "Heat.rte");
	self.sawStop = CreateSoundContainer("Saw Stop Buzzdrone", "Heat.rte");
	
	self.Accelerate = CreateSoundContainer("Accelerate Buzzdrone", "Heat.rte");
	
	self.scanLoop = CreateSoundContainer("Scan Loop Buzzdrone", "Heat.rte");
	self.aggroScanLoop = CreateSoundContainer("Aggro Scan Loop Buzzdrone", "Heat.rte");
	self.scanLockOn = CreateSoundContainer("Scan Lock On Buzzdrone", "Heat.rte");
	self.scanLockOff = CreateSoundContainer("Scan Lock Off Buzzdrone", "Heat.rte");
	
	self.scanTimer = Timer();
	self.scanDelay = 4000;
	
	self.Moving = false;
	
	self.moveTimer = Timer();
	-- Sounds
	
	self.scan = ToGameActivity(ActivityMan:GetActivity()):GetFogOfWarEnabled()
	self.scanTimer = Timer();
	
	self.smokeTimer = Timer()
	self.smokeDelay = math.random(200,30)
	
	self.sawEnabled = false
	self.sawStartSound = true
	
	self.sawHitTimer = Timer()
	self.sawHitDelay = 300
	
	self.accsin = 0;
	self.GlobalAccScalar = 0.1;
	
	self.Frame = 2
end

function Update(self)
	if (self.Health < 1 or self.Status == Actor.DEAD or self.Status == Actor.DYING) then -- Death
		if not self.dead then
			if math.random(1,3) < 2 then
				self.dead = true
				self:GibThis();
				return
			else
				local emitter = CreateAEmitter("Smoke Trail Medium")
				emitter.Lifetime = 3000
				self:AddAttachable(emitter);
				
				if math.random(1,2) < 2 then
					self.Vel = self.Vel + Vector(RangeRand(-1,1), RangeRand(-1,0)) * 5
					self.GibImpulseLimit = 1
				end
			
				self.dead = true
				self.GlobalAccScalar = 1.0;
			end
		end
		--self.ToSettle = true;
		return
	end
	
	-- Damage
	self.hoverSpeed = 0.2 + math.min((self.Health / self.MaxHealth + 0.5) / 1.5, 1)
	
	if self.smokeTimer:IsPastSimMS(self.smokeDelay) then
		if RangeRand(1, 0) > (0.5 + (self.Health / self.MaxHealth)) then
			local particle = CreateMOSParticle("Small Smoke Ball 1");
			particle.Pos = self.Pos + Vector(RangeRand(-self.Radius,self.Radius),RangeRand(-self.Radius,self.Radius)) * 0.25;
			particle.Vel = Vector(RangeRand(-1,1),RangeRand(-1,1));
			particle.Lifetime = particle.Lifetime * RangeRand(0.6, 1.6) * 2.0; -- Randomize lifetime
			MovableMan:AddParticle(particle);
		end
		
		self.smokeTimer:Reset()
		self.smokeDelay = math.random(200,30)
	end
	
	-- Scan
	if self.scan and self.scanTimer:IsPastSimMS(60) then
		SceneMan:CastSeeRay(self.Team, self.Pos, Vector(300 * self.FlipFactor, 0):RadRotate(self.RotAngle + math.rad(RangeRand(-1, 1) * 45)), Vector(), 110, 4);
		self.scanTimer:Reset()
	end
	
	if self.aggroScan == true then
		if self.scanLockOnSound == true then
			self.scanLockOn:Play(self.Pos);
			self.scanLockOnSound = false;
			
			self.scanLoop:Stop(-1);
			
			self.scanLockOff:Stop(-1);
			
			self.Scan = true;
			
		end
		if not self.aggroScanLoop:IsBeingPlayed() then
			self.aggroScanLoop:Play(self.Pos);
		else
			self.aggroScanLoop.Pos = self.Pos;
		end
	else
		if self.aggroScanLoop:IsBeingPlayed() then
			self.aggroScanLoop:Stop(-1);
			
			self.scanTimer:Reset();
			
			self.scanLockOff:Play(self.Pos);
		end
		
		if self.Scan == true and not self.Scanning == true then
			self.Scan = false;
			self.Scanning = true;
			self.scanLoop:Stop(-1);
			self.scanTimer:Reset();
		end
		if self.Scanning == true then
			self.Scan = false;
			if not self.scanLoop:IsBeingPlayed() then
				self.scanLoop:Play(self.Pos);
				self.scanTimer:Reset();
			elseif self.scanLoop:IsBeingPlayed() then
			
				PrimitiveMan:DrawLinePrimitive(self.Pos + Vector(4*self.FlipFactor, -4):RadRotate(self.RotAngle), self.Pos + Vector(20*self.FlipFactor, 0):RadRotate(self.RotAngle):DegRotate(math.random(-45, 45)), 122);
				PrimitiveMan:DrawLinePrimitive(self.Pos + Vector(4*self.FlipFactor, -4):RadRotate(self.RotAngle), self.Pos + Vector(20*self.FlipFactor, 0):RadRotate(self.RotAngle):DegRotate(math.random(-45, 45)), 122);
				PrimitiveMan:DrawLinePrimitive(self.Pos + Vector(4*self.FlipFactor, -4):RadRotate(self.RotAngle), self.Pos + Vector(20*self.FlipFactor, 0):RadRotate(self.RotAngle):DegRotate(math.random(-45, 45)), 122);
				
				self.scanLoop.Pos = self.Pos;
				if self.scanTimer:IsPastSimMS(self.scanDelay) then
					AudioMan:FadeOutSound(self.scanLoop, 250);
					self.Scanning = false;
				end
			end
		end
		
		self.scanLockOnSound = true;
		
	end
	
	if math.random() < 0.002 then
		self.Scan = true;
		self.scanDelay = math.random(2000, 6500);
	end	
	
	-- Controller
	
	if self:IsPlayerControlled() then -- PLAYER
		local movementVector = Vector()
		local ctrl = self:GetController()
		
		local moving = false
		
		if ctrl:IsState(Controller.HOLD_UP) or ctrl:IsState(Controller.BODY_JUMP) then
			movementVector.Y = movementVector.Y - 1
			moving = true
		end
		
		if ctrl:IsState(Controller.HOLD_DOWN) or ctrl:IsState(Controller.BODY_CROUCH) then
			movementVector.Y = movementVector.Y + 1
			moving = true
		end
		if ctrl:IsState(Controller.HOLD_LEFT) then
			movementVector.X = movementVector.X - 1
			moving = true
		end
		if ctrl:IsState(Controller.HOLD_RIGHT) then
			movementVector.X = movementVector.X + 1
			moving = true
		end
		
		if ctrl:IsState(Controller.WEAPON_FIRE) then
			self.sawEnabled = true
		else
			self.sawEnabled = false
		end
		
		if moving then
			movementVector:SetMagnitude(self.Vel.Magnitude * 2.0 + 25)
			self.hoverPosTarget = Vector(self.Pos.X, self.Pos.Y) + movementVector;
		end
		
		self.Scan = false;
		self.aggroScan = false;
		
		
	else -- AI
		-- Placeholder AI
		local target = MovableMan:GetClosestEnemyActor(self.Team, self.Pos, 300, Vector());
		if target and target.Status < Actor.INACTIVE then
			--Check that the target isn't obscured by terrain
			local aimTrace = SceneMan:ShortestDistance(self.Pos, target.Pos, SceneMan.SceneWrapsX);
			local terrCheck = SceneMan:CastStrengthRay(self.Pos, aimTrace, 30, Vector(), 5, 0, SceneMan.SceneWrapsX);
			if terrCheck == false then
				self.hoverPosTarget = Vector(target.Pos.X, target.Pos.Y)
				
				self.sawEnabled = true
				self.aggroScan = true;
			end
		else
			-- Patrol
			
			self.sawEnabled = false
		end
	end
	
	-- Buzzsaw
	if self.sawEnabled then
		if self.sawStartSound then
			self.sawStart:Play(self.Pos)
			self.sawStartSound = false
		end
		if not self.sawLoop:IsBeingPlayed() then
			self.sawLoop:Play(self.Pos)
		else
			self.sawLoop.Pos = self.Pos
		end
		
		self.Frame = (self.Age / 2) % 2
	else
		if self.sawLoop:IsBeingPlayed() then
			self.sawLoop:Stop(-1);
			
			self.sawStop:Play(self.Pos)
		end
		
		self.Frame = 2
		
		self.sawStartSound = true
	end

	
	-- Movement
	self.accsin = (self.accsin + TimerMan.DeltaTimeSecs * 2) % 2;
	self.GlobalAccScalar = math.sin(self.accsin * math.pi) * 0.2;
	
	--PrimitiveMan:DrawCirclePrimitive(self.hoverPosTarget, 6, 13);
	--PrimitiveMan:DrawLinePrimitive(self.Pos, self.Pos + Vector(self.hoverVelocityTarget, 0):RadRotate(self.hoverDirectionTarget), 122);
	--PrimitiveMan:DrawLinePrimitive(self.Pos, self.Pos + Vector(self.hoverVelocity, 0):RadRotate(self.hoverDirection), 5);
	
	-- Define howery
	local vec = SceneMan:ShortestDistance(Vector(self.Pos.X, self.Pos.Y),self.hoverPosTarget,SceneMan.SceneWrapsX)
	self.hoverDirectionTarget = vec.AbsRadAngle;
	self.hoverVelocityTarget = math.min(vec.Magnitude, 60) / 2;
	
	--PrimitiveMan:DrawLinePrimitive(self.Pos, self.Pos + vec, 116);
	--PrimitiveMan:DrawLinePrimitive(self.Pos, self.Pos + Vector(10,0):RadRotate(vec.AbsRadAngle), 149);
	
	self.hoverVelocity = (self.hoverVelocity + self.hoverVelocityTarget * TimerMan.DeltaTimeSecs * self.hoverVelocitySpeed * self.hoverSpeed) / (1 + TimerMan.DeltaTimeSecs * self.hoverVelocitySpeed * self.hoverSpeed)
	
	-- Frotate self.hoverDirection
	local min_value = -math.pi;
	local max_value = math.pi;
	local value = self.hoverDirectionTarget - self.hoverDirection;
	local result;
	
	local range = max_value - min_value;
	if range <= 0 then
		result = min_value;
	else
		local ret = (value - min_value) % range;
		if ret < 0 then ret = ret + range end
		result = ret + min_value;
	end
	
	self.hoverDirection = (self.hoverDirection + result * TimerMan.DeltaTimeSecs * self.hoverDirectionSpeed * self.hoverSpeed)
	--self.hoverDirection = self.hoverDirectionTarget
	
	result = 0
	
	-- Frotate self.RotAngle
	value = self.RotAngle;
	
	range = max_value - min_value;
	if range <= 0 then
		result = min_value;
	else
		ret = (value - min_value) % range;
		if ret < 0 then ret = ret + range end
		result = ret + min_value;
	end
	
	self.RotAngle = (self.RotAngle - result * TimerMan.DeltaTimeSecs * 15 * self.hoverSpeed)
	
	self.Vel = (self.Vel + Vector(self.hoverVelocity * 0.5, 0):RadRotate(self.hoverDirection) * TimerMan.DeltaTimeSecs * 7) / (1 + TimerMan.DeltaTimeSecs * 7);
	--self.Vel = Vector(self.hoverVelocity * 0.5, 0):RadRotate(self.hoverDirection)
	self.AngularVel = (self.AngularVel) / (1 + TimerMan.DeltaTimeSecs * 10 * self.hoverSpeed) - self.Vel.X * TimerMan.DeltaTimeSecs * 6 / self.hoverSpeed
	
	if math.abs(self.Vel.X) > 5 then
		self.HFlipped = (self.Vel.X) < 0
	end
	
	-- Sounds
	if self.Vel.Magnitude < 5 then
		if self.Moving == true then
			if self.moveTimer:IsPastSimMS(600) then

				self.Accelerate:Stop(-1);

				--self.Deccelerate:Play(self.Pos);
				self.moveTimer:Reset();
			end
			self.moveTimer:Reset();
			self.Moving = false;
		end
	else
		if self.Moving == false then
			if self.moveTimer:IsPastSimMS(600) then
				--if self.Deccelerate:IsBeingPlayed() then
				--	self.Deccelerate:Stop(-1);
				--end
				self.Accelerate:Play(self.Pos);
			end
			self.moveTimer:Reset();
			self.Moving = true;
		end	
		
	end
	
	--[[
	if self.Vel.Magnitude > 2 and not self.hoverLoop:IsBeingPlayed() then
		self.hoverLoop:Play(self.Pos);
	elseif self.Vel.Magnitude <= 2 then
		if self.hoverLoop:IsBeingPlayed() then
			self.hoverLoop:Stop(-1);
		end
	end]]
	if not self.hoverLoop:IsBeingPlayed() then
		self.hoverLoop:Play(self.Pos);
	end
	
	self.hoverLoop.Pos = self.Pos;
	self.Accelerate.Pos = self.Pos;
	
	if self.hoverLoop:IsBeingPlayed() then
		self.hoverLoop.Volume = (self.Vel.Magnitude / 20) + 0.5;
		self.hoverLoop.Pitch = (self.Vel.Magnitude / 20) + 1;
	end
	-- Sounds
end

function OnCollideWithMO(self, collidedMO, collidedRootMO)
	if self.sawEnabled and self.sawHitTimer:IsPastSimMS(self.sawHitDelay) then
		local dif = SceneMan:ShortestDistance(self.Pos,collidedMO.Pos, SceneMan.SceneWrapsX)
		local pos = self.Pos + dif * 0.5
		
		local effect = CreateMOSRotating("Buzzdrone Saw Hit Effect");
		if effect then
			effect.Pos = pos;
			MovableMan:AddParticle(effect);
			effect:GibThis();
		end
		
		self.Health = self.Health - math.random(0,2)
		
		-- Damage things by spewing particles
		for j = 0, math.random(2,4) do
			for i = 0, 1 do
				local Particle = CreateMOPixel("Buzzdrone Particle", "Heat.rte")
				Particle.Pos = self.Pos;
				Particle.Vel = self.Vel + Vector(85 * self.FlipFactor * (i - 0.5) * 2.0, 0):RadRotate(self.RotAngle + math.rad(RangeRand(-1,1) * 80))
				Particle.Team = self.Team
				Particle.IgnoresTeamHits = true
				MovableMan:AddParticle(Particle);
			end
		end
		
		self.Vel = self.Vel - dif:SetMagnitude(math.random(12,25)) * math.random(1,3)
		
		self.sawHitTimer:Reset()
	end
end

function OnCollideWithTerrain(self, terrainID)
	if self.Status == Actor.DEAD or self.Status == Actor.DYING then return end
	
	-- Custom move out of terrain script, EXPERIMENTAL
	--PrimitiveMan:DrawCirclePrimitive(self.Pos, self.Radius, 13);
	local pos = self.Pos -- Hit Pos
	
	local maxi = 8
	for i = 1, maxi do
		local offset = Vector(self.Radius, 0):RadRotate(((math.pi * 2) / maxi) * i)
		local endPos = self.Pos + offset; -- This value is going to be overriden by function below, this is the end of the ray
		self.ray = SceneMan:CastObstacleRay(self.Pos + offset, offset * -1.0, Vector(0, 0), endPos, 0 , self.Team, 0, 1)
		if self.ray == 0 then
			--self.Pos = self.Pos - offset * 0.1;
			self.Pos = self.Pos - offset * 0.05;
			self.Vel = self.Vel * 0.5;
			
			if self.sawEnabled then
				self.Vel = self.Vel - offset * math.min(self.Vel.Magnitude + 5, 35) * 0.1
			end
		end
		
		pos = self.Pos + SceneMan:ShortestDistance(self.Pos,endPos, SceneMan.SceneWrapsX) * 0.5
		--PrimitiveMan:DrawLinePrimitive(self.Pos + offset, self.Pos - offset, 46);
		--PrimitiveMan:DrawLinePrimitive(self.Pos + offset, endPos, 116);
	end
	
	if self.sawEnabled and self.sawHitTimer:IsPastSimMS(self.sawHitDelay) then
		
		local effect = CreateMOSRotating("Buzzdrone Saw Hit Effect");
		if effect then
			effect.Pos = pos;
			MovableMan:AddParticle(effect);
			effect:GibThis();
		end
		
		self.Health = self.Health - math.random(0,1)
		
		self.sawHitTimer:Reset()
	end
end

function Destroy(self)

	if self.sawLoop:IsBeingPlayed() then
		self.sawLoop:Stop(-1);
		
		self.sawStop:Play(self.Pos)
	end

	self.hoverLoop:Stop(-1);
	
	self.Accelerate:Stop(-1);

	self.scanLoop:Stop(-1);

	self.aggroScanLoop:Stop(-1);

end