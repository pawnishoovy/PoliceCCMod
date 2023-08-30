function Update(self)
	
	if not self:IsAttached() then
		self.parent = nil;
		self.parentSet = false;
	elseif self.parentSet ~= true then
		local actor = self:GetRootParent()
		if actor and IsAHuman(actor) then
			self.parent = ToAHuman(actor);
			self.parentSet = true;
		end
	end
	
	if self.parent then
		self.parent:RemoveNumberValue("Mordhau Flinched");
		if self.parent.EquippedItem then
			ToHeldDevice(self.parent.EquippedItem):SetNumberValue("Mordhau Flinched", 1);
		end
		self.ToDelete = true
	else
		self.ToDelete = true
	end
end