function Create(self)

	self.parent = self:GetParent();
	self.origOneHanded = ToHeldDevice(self.parent):IsOneHanded();
	self.origNoSupportFactor = self.parent.NoSupportFactor;
	self.origDualWieldable = ToHeldDevice(self.parent):IsDualWieldable();

end

function Update(self)

	if self:IsAttached() then
		if ToAttachable(self.parent):IsAttached() then
			ToHeldDevice(self.parent):SetOneHanded(true);
			ToHeldDevice(self.parent):SetDualWieldable(true);
			ToHeldDevice(self.parent).NoSupportFactor = 1.0;
			ToHeldDevice(self.parent).DualWieldable = true;
		else
			ToHeldDevice(self.parent):SetOneHanded(self.origOneHanded);
			ToHeldDevice(self.parent):SetDualWieldable(self.origDualWieldable);
			ToHeldDevice(self.parent).NoSupportFactor = self.origNoSupportFactor;
			ToHeldDevice(self.parent):RemoveNumberValue("CyborgOneHand");
			self.ToDelete = true;
		end
	else
		self.ToDelete = true;
	end
end






