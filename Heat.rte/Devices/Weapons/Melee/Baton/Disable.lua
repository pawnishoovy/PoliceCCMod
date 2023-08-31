function OnDetach(self)

	self:RemoveNumberValue("AI Parry")
	self:RemoveNumberValue("AI Parry Eligible")

	self:DisableScript("Heat.rte/Devices/Weapons/Melee/Baton/Baton.lua");
	
	self:RemoveStringValue("Parrying Type");
	self.Parrying = false;
	
	self.Blocking = false;
	self:RemoveNumberValue("Blocking");
	
	self.currentAttackAnimation = 0;
	self.currentAttackSequence = 0;
	self.currentAttackStart = false
	self.attackAnimationIsPlaying = false
	
	self.rotationInterpolationSpeed = 25;
	
	self.Frame = 0;
	
	self.canBlock = false;
	
end

function OnAttach(self)

	self:RemoveNumberValue("AI Parry")
	self:RemoveNumberValue("AI Parry Eligible")

	self:RemoveStringValue("Parrying Type");
	self.Parrying = false;
	
	self.Blocking = false;
	self:RemoveNumberValue("Blocking");
	
	self.currentAttackAnimation = 0;
	self.currentAttackSequence = 0;
	self.currentAttackStart = false
	self.attackAnimationIsPlaying = false
	
	self.rotationInterpolationSpeed = 25;
	
	self:EnableScript("Heat.rte/Devices/Weapons/Melee/Baton/Baton.lua");
	
	self.Frame = 0;
	
	self.canBlock = false;
	
	if self.offTheGround ~= true then --equipped from inv
	
		self.equipAnim = true;
		
		-- local rotationTarget = rotationTarget + 170 / 180 * math.pi
		-- local stanceTarget = stanceTarget + Vector(-10, -10);
	
		-- self.stance = self.stance + stanceTarget
		
		-- rotationTarget = rotationTarget * self.FlipFactor
		-- self.rotation = self.rotation + rotationTarget
		
		-- self.StanceOffset = self.originalStanceOffset + self.stance
		-- self.RotAngle = self.RotAngle + self.rotation
		
	end
	
end

function Update(self)

	if not self:IsAttached() then
		self.offTheGround = true;
	else
		self.offTheGround = false;
	end
	
end