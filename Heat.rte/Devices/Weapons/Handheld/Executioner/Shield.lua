function Create(self)
	self.Frame = 0;
	self.parent = nil;
	self.soundLowPlayed = false;
	self.soundLow = CreateSoundContainer("Charge Low Executioner", "Heat.rte");
	self.soundMedPlayed = false;
	self.soundMed = CreateSoundContainer("Charge Medium Executioner", "Heat.rte");
	self.soundHiPlayed = false;
	self.soundHi = CreateSoundContainer("Charge High Executioner", "Heat.rte");
	
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

		if self.parent:GetNumberValue("ShieldActive") == 1 and (self.Frame < 2) then
			self.Frame = math.random(0,1)
			if self.WoundCount > 9 then
				self.parent:SetNumberValue("Charge", 3);
				self.Frame = 2;
				self:RemoveWounds(self.WoundCount);
				if self.soundHiPlayed == false then
					self.soundHi:Play(self.Pos);
					self.soundHiPlayed = true;
				end
			elseif self.WoundCount > 6 then
				self.parent:SetNumberValue("Charge", 2);
				if self.soundMedPlayed == false then
					self.soundMed:Play(self.Pos);
					self.soundMedPlayed = true;
				end
			elseif self.WoundCount > 3 then
				self.parent:SetNumberValue("Charge", 1);
				if self.soundLowPlayed == false then
					self.soundLow:Play(self.Pos);
					self.soundLowPlayed = true;
				end
			end

			if self.parent:NumberValueExists("MagRotation") then
				self.RotAngle = self.RotAngle + self.parent:GetNumberValue("MagRotation");
			end
			if self.parent:NumberValueExists("MagOffsetX") and self.parent:NumberValueExists("MagOffsetY") then
				self.Pos = self.Pos + Vector(self.parent:GetNumberValue("MagOffsetX"), self.parent:GetNumberValue("MagOffsetY"));
			end
		else
			if self.WoundCount > 0 then
				self:RemoveWounds(self.WoundCount);
			end
			self.Frame = 2;
			if self.parent:GetNumberValue("ActivateShield") == 1 then
				self.parent:SetNumberValue("ActivateShield", 0);
				self.Frame = math.random(0,1)
				self.soundLowPlayed = false;
				self.soundMedPlayed = false;
				self.soundHiPlayed = false;
			end
		end
		
		if self.Frame < 2 then
			local glow = CreateMOPixel("Shield Executioner Glow "..math.random(1,4));
			glow.Pos = self.Pos + Vector(RangeRand(-1,1), RangeRand(-1,0))
			glow.EffectRotAngle = self.HFlipped and (self.RotAngle + math.pi) or (self.RotAngle);
			MovableMan:AddParticle(glow);
		end
		--self.Frame = 1
		--self.RotAngle = self.parent.RotAngle;
	end
	
	if self.parentIdentified == true and IsHDFirearm(self.parent) == false then
		self.ToDelete = true;
	end
end



