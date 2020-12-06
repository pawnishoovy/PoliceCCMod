function Create(self)
	self.Frame = 0;
	self.parent = nil;
end

function Update(self)

	if self.parent == nil then   -- if self.parent isn't defined
		mo = MovableMan:GetMOFromID(self.RootID);
			if mo then
				if IsHDFirearm(mo) then   -- if root ID is the gun
					self.parent = ToHDFirearm(mo);
			elseif IsAHuman(mo) then   -- if root ID is the actor holding the gun
				if ToAHuman(mo).EquippedItem and IsHDFirearm(ToAHuman(mo).EquippedItem) then
					self.parent = ToHDFirearm(ToAHuman(mo).EquippedItem);
					self.parentIdentified = true
				end
			end
		end

	elseif IsHDFirearm(self.parent) then
	
		self:ClearForces();
		self:ClearImpulseForces();
		
		self:RemoveWounds(self.WoundCount);
		
		self.GetsHitByMOs = false;
			
		if self.parent:NumberValueExists("MagRemoved") then
			self.Frame = 0;
		else
			self.Frame = 1;
		end
		if self.parent:NumberValueExists("MagRotation") then
			self.RotAngle = self.RotAngle + self.parent:GetNumberValue("MagRotation");
		end
		if self.parent:NumberValueExists("MagOffsetX") and self.parent:NumberValueExists("MagOffsetY") then
			self.Pos = self.Pos + Vector(self.parent:GetNumberValue("MagOffsetX"), self.parent:GetNumberValue("MagOffsetY"));
		end
		--self.RotAngle = self.parent.RotAngle;
	end
	
	if self.parentIdentified == true and IsHDFirearm(self.parent) == false then
		self.ToDelete = true;
	end
end



