function Create(self)

	self.fakeMag = nil;
	for attachable in self.Attachables do
		
		if string.find(attachable.PresetName, "Fake Magazine") then
			self.fakeMag = attachable
			self.fakeMag:AddScript("Heat.rte/Devices/Shared/FakeMag.lua") -- SAFE MEASURE
		end
	end
end

function Update(self)
	
	if self.fakeMag and not self:NumberValueExists("LostFakeMag") then
		self.fakeMag:ClearForces();
		self.fakeMag:ClearImpulseForces();
		
		self.fakeMag:RemoveWounds(self.fakeMag.WoundCount);
		
		self.fakeMag.GetsHitByMOs = false;
			
		if self:NumberValueExists("MagRemoved") then
			self.fakeMag.Frame = 0;
		else
			self.fakeMag.Frame = 1;
		end
		if self.parent:NumberValueExists("MagRotation") then
			self.fakeMag.RotAngle = self.fakeMag.RotAngle + self:GetNumberValue("MagRotation");
		end
		if self.parent:NumberValueExists("MagOffsetX") and self.parent:NumberValueExists("MagOffsetY") then
			self.fakeMag.Pos = self.fakeMag.Pos + Vector(self:GetNumberValue("MagOffsetX"), self:GetNumberValue("MagOffsetY"));
		end
	end
	
end



