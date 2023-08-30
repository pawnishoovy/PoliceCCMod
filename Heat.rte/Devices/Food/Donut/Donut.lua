function Create(self)

	self.eatOrganicSound = CreateSoundContainer("Eat Organic Donut Heat", "HEAT.rte");
	self.eatMechanicalSound = CreateSoundContainer("Eat Mechanical Donut Heat", "HEAT.rte");

	self.originalStanceOffset = Vector(6, 8);
	
	self.eatTimer = Timer();

end
function Update(self)

	self.parent = self:GetRootParent();
	if IsAHuman(self.parent) and ToAHuman(self.parent).Head then
		
		self.parent = ToAHuman(self.parent);
		local controller = self.parent:GetController();
		controller:SetState(Controller.AIM_SHARP,false);

		local dist = SceneMan:ShortestDistance(self.parent.Pos+self.originalStanceOffset, self.parent.Head.Pos + Vector(2, 5), SceneMan.SceneWrapsX)
		
		if self:IsActivated() then
		
			self.StanceOffset = self.originalStanceOffset + dist
			
			if not self.eating then
				self.eatTimer:Reset();
				self.eating = true;
				self.parent:SetNumberValue("Eating Delicious Heat Donut", 1);
			end
			
			if self.eatTimer:IsPastSimMS(100) then
				self.parent.Health = math.min(self.parent.MaxHealth, self.parent.Health + 1);
				self:GibThis();
				
				if self.parent:IsOrganic() then
					self.eatOrganicSound:Play(self.Pos);
					for i = 1, 5 do
						local effect = CreateMOPixel("Bone Particle", "Base.rte");
						effect.Pos = self.Pos
						effect.Vel = self.Vel + Vector(math.random(3, 5), 0):RadRotate(math.pi*math.random(0, 100)/100);
						MovableMan:AddParticle(effect);
					end
					self.parent:SetNumberValue("Ate Delicious Heat Donut", 1);
				else
					self.eatMechanicalSound:Play(self.Pos);
					
					for i = 1, 10 do
						local effect = CreateMOPixel("Bone Particle", "Base.rte");
						effect.Pos = self.Pos
						effect.Vel = self.Vel + Vector(math.random(3, 5), 0):RadRotate(math.pi*math.random(0, 100)/100);
						MovableMan:AddParticle(effect);
					end
					for i = 1, 10 do
						local effect = CreateMOPixel("Drop Brain Fluid Dark", "Base.rte");
						effect.Pos = self.Pos
						effect.Vel = self.Vel + Vector(math.random(3, 5), 0):RadRotate(math.pi*math.random(0, 100)/100);
						MovableMan:AddParticle(effect);
					end
				end
				
			end
			
		else
			self.eating = false;
			self.StanceOffset = self.originalStanceOffset
		end
		
	else
		self.parent = nil;
	end
		

end
