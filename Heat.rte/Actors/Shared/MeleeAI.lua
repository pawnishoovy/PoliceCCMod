--require("AI/NativeHumanAI")   -- or NativeCrabAI or NativeTurretAI

function Sign(x)
	if x<0 then
		return -1
	elseif x>0 then
		return 1
	else
		return 0
	end
end

function Create(self)
	
	self.MeleeAI = {}
	self.MeleeAI.debug = false
	
	
--	MovableMan:ChangeActorTeam(self, 3)
	
	-- States:
	self.MeleeAI.skill = self.MeleeAISkill -- Diagnosis: skill issue
	self.MeleeAI.active = false
	
	local activity = ActivityMan:GetActivity()
	if activity then
		self.MeleeAI.skill = (self.MeleeAI.skill / 2) + ((self.MeleeAI.skill / 2) * (activity:GetTeamAISkill(self.Team)/100))
	end
	
	
	self.MeleeAI.movementInputPrevious = 0
	self.MeleeAI.movementDirectionChangeTimer = Timer()
	self.MeleeAI.movementDirectionChangeDuration = 100
	
	self.MeleeAI.weapon = nil
	self.MeleeAI.weaponData = {}
	
	self.MeleeAI.distanceOffsetMin = -15
	self.MeleeAI.distanceOffsetMax = 30
	self.MeleeAI.distanceOffset = RangeRand(self.MeleeAI.distanceOffsetMin, self.MeleeAI.distanceOffsetMax)
	self.MeleeAI.distanceOffsetDelayTimer = Timer()
	self.MeleeAI.distanceOffsetDelayMin = 700
	self.MeleeAI.distanceOffsetDelayMax = 2200
	self.MeleeAI.distanceOffsetDelay = RangeRand(self.MeleeAI.distanceOffsetDelayMin, self.MeleeAI.distanceOffsetDelayMax)
	
	self.MeleeAI.randomGimmickTimer = Timer()
	self.MeleeAI.randomGimmickDelayMin = 800
	self.MeleeAI.randomGimmickDelayMax = 2500
	self.MeleeAI.randomGimmickDelay = RangeRand(self.MeleeAI.randomGimmickDelayMin, self.MeleeAI.randomGimmickDelayMax)
	
	self.MeleeAI.lookOffset = 0
	self.MeleeAI.lookOffsetCurrent = 0
	
	self.MeleeAI.kickChance = 0; -- 3 + 25 * self.MeleeAI.skill -- we do not have kicking in this mod...
	
	self.MeleeAI.blocking = false
	self.MeleeAI.blockingDelayMax = 1000 * (0.15 + 0.85 * (1 - self.MeleeAI.skill))
	self.MeleeAI.blockingDelay = self.MeleeAI.blockingDelayMax * 0.05
	self.MeleeAI.blockingDelayTimer = Timer()
	self.MeleeAI.blockingFatigueLevel = 1
	self.MeleeAI.blockingFatigueLevelRegeneration = (0.15 + 0.5 * self.MeleeAI.skill)
	self.MeleeAI.blockingFatigueMode = 0 -- 0 - ready, 1 - blocking, 2 - regenerating
	
	self.MeleeAI.tactics = {
		["Offensive"] = function ()
			-- Invert distance offset
			self.MeleeAI.distanceOffset = math.max(-math.abs(self.MeleeAI.distanceOffset), -10)
		end,
		["Defensive"] = function ()
			-- Basic behaviour
		end
	}
	self.MeleeAI.tactic = "Offensive"
	
	self.MeleeAI.parryReady = false
	self.MeleeAI.parrySuccess = false
	self.MeleeAI.parryChance = 80--%
	
	self.MeleeAI.attacking = false
	
	self.MeleeAI.attackMissThereshold = 0
	self.MeleeAI.attackMissTheresholdGain = 15 * (1 - self.MeleeAI.skill)
	self.MeleeAI.attackMissDelay = 1000
	self.MeleeAI.attackMissTimer = Timer()
	
	self.MeleeAI.weaponAttackData = {
	{name = "Swing", index = 1},
	{name = "Stab", index = 3},
	{name = "Overhead", index = 4}
	}
	self.MeleeAI.weaponNextAttackIndex = math.floor(RangeRand(1, #self.MeleeAI.weaponAttackData + 1))
	
end

function UpdateAI(self)

	--print("meleeai")

	if self.Status >= Actor.DYING or not self.Head then
		return
	end
	self.MeleeAI.attacking = false
	
	local ctrl = (self.controller and self.controller or self:GetController())
	
	-- Misc
	local movementInput = 0
	
	-- Keep track of weapon and get the ranges
	local weapon = self.EquippedItem
	if weapon and (IsHeldDevice(weapon) or IsHDFirearm(weapon)) then
		weapon = ToHeldDevice(weapon)
		if self.MeleeAI.weapon == nil or self.MeleeAI.weapon ~= weapon.UniqueID then
			weapon = ToHeldDevice(weapon)
			if weapon:NumberValueExists("Weapons- Mordhau Melee") or weapon:IsInGroup("Weapons - Mordhau Melee") then
				self.MeleeAI.weapon = weapon.UniqueID
				--self.MeleeAI.weaponData
				for i = 0, 4 do
					--print(weapon:GetNumberValue("Attack "..tostring(i+1).." Range"))
					table.insert(self.MeleeAI.weaponData, {name = weapon:GetStringValue("Attack "..tostring(i+1).." Name"), range = weapon:GetNumberValue("Attack "..tostring(i+1).." Range")})
				end
			else
				self.MeleeAI.weapon = nil
				self.MeleeAI.weaponData = {}
				
				weapon = nil
			end
		end
	elseif self.MeleeAI.weapon ~= nil then
		self.MeleeAI.weapon = nil
		self.MeleeAI.weaponData = {}
		
		weapon = nil
	end
	
	if self:NumberValueExists("Mordhau Flinched") then
		self:RemoveNumberValue("Mordhau Flinched")
		self.MeleeAI.blockingFatigueLevel = 1.0
	end
	
	-- Fatigue "state" machine
	if self.MeleeAI.blockingFatigueMode == 0 then -- Read
		self.MeleeAI.blockingFatigueLevel = math.min(self.MeleeAI.blockingFatigueLevel + TimerMan.DeltaTimeSecs * self.MeleeAI.blockingFatigueLevelRegeneration * 0.25, 1)
		if self.MeleeAI.blocking and not self.MeleeAI.attacking then
			self.MeleeAI.blockingFatigueMode = 1
		end
	elseif self.MeleeAI.blockingFatigueMode == 1 then -- Blocking
		self.MeleeAI.blockingFatigueLevel = math.max(self.MeleeAI.blockingFatigueLevel - TimerMan.DeltaTimeSecs * 1.0, 0)
		if not self.MeleeAI.blocking or self.MeleeAI.attacking then
			self.MeleeAI.blockingFatigueMode = 0
		elseif self.MeleeAI.blockingFatigueLevel < 0.05 then
			self.MeleeAI.blockingFatigueMode = 2
		end
	elseif self.MeleeAI.blockingFatigueMode == 2 then -- Regeneration (cooldown)
		self.MeleeAI.blockingFatigueLevel = math.min(self.MeleeAI.blockingFatigueLevel + TimerMan.DeltaTimeSecs * self.MeleeAI.blockingFatigueLevelRegeneration, 1)
		if self.MeleeAI.blockingFatigueLevel > 0.95 then
			self.MeleeAI.blockingFatigueMode = 0
		end
	end
	
	-- Extra graphical debug
	if self.MeleeAI.debug then
		--self.MeleeAI.blockingFatigueLevel = 0
		--self.MeleeAI.blockingFatigueLevelRegeneration = 1
		--self.MeleeAI.blockingFatigueMode = 0 -- 0 - ready, 1 - blocking, 2 - regenerating
		
		local hudOrigin = self.Pos
		local hudUpperPos = hudOrigin + Vector(0, -30)
		
		local hudBarWidthOutline = 30
		local hudBarWidth = 30
		local hudBarHeight = 3
		local hudBarColor = 87
		local hudBarColorBG = 83
		local hudBarColorOutline = 2
		
		local hudBarOffset = Vector(1, 1)
		
		local pos = hudUpperPos
		
		-- Fatigue
		hudBarWidth = 30 * self.MeleeAI.blockingFatigueLevel
		hudBarColor = ((self.MeleeAI.blockingFatigueMode == 0 and 87) or (self.MeleeAI.blockingFatigueMode == 1 and 99 or 47))
		hudBarColorBG = 83

		PrimitiveMan:DrawBoxFillPrimitive(pos + Vector(hudBarWidthOutline * -0.5, hudBarHeight * -0.5) + hudBarOffset, pos + Vector(hudBarWidthOutline * 0.5, hudBarHeight * 0.5) + hudBarOffset, hudBarColorBG)
		PrimitiveMan:DrawBoxFillPrimitive(pos + Vector(hudBarWidthOutline * -0.5, hudBarHeight * -0.5), pos + Vector(hudBarWidthOutline * -0.5 + hudBarWidth, hudBarHeight * 0.5), hudBarColor)
		PrimitiveMan:DrawBoxPrimitive(pos + Vector(hudBarWidthOutline * -0.5, hudBarHeight * -0.5), pos + Vector(hudBarWidthOutline * 0.5, hudBarHeight * 0.5), hudBarColorOutline)
		
		
		pos = pos + Vector(0, 5)
		
		hudBarWidth = 30 * math.max(self.MeleeAI.attackMissThereshold / 100, 1 - math.min(self.MeleeAI.attackMissTimer.ElapsedSimTimeMS / self.MeleeAI.attackMissDelay, 1))
		hudBarColor = 213
		hudBarColorBG = 216
		
		PrimitiveMan:DrawBoxFillPrimitive(pos + Vector(hudBarWidthOutline * -0.5, hudBarHeight * -0.5) + hudBarOffset, pos + Vector(hudBarWidthOutline * 0.5, hudBarHeight * 0.5) + hudBarOffset, hudBarColorBG)
		PrimitiveMan:DrawBoxFillPrimitive(pos + Vector(hudBarWidthOutline * -0.5, hudBarHeight * -0.5), pos + Vector(hudBarWidthOutline * -0.5 + hudBarWidth, hudBarHeight * 0.5), hudBarColor)
		PrimitiveMan:DrawBoxPrimitive(pos + Vector(hudBarWidthOutline * -0.5, hudBarHeight * -0.5), pos + Vector(hudBarWidthOutline * 0.5, hudBarHeight * 0.5), hudBarColorOutline)
	end
	
	local pugilism = self:NumberValueExists("Pugilism")
	
	local target = self.AI.Target
	--print(target)
	if target and (pugilism or self.MeleeAI.weapon) then
	
		--print("target");
		local dif = SceneMan:ShortestDistance(self.Pos, target.Pos, SceneMan.SceneWrapsX)
		local difMagnitude = dif.Magnitude
		
		ctrl:SetState(Controller.BODY_CROUCH, false)
		
		--if difMagnitude < 120 then
		--	ctrl:SetState(Controller.BODY_JUMP, false)
		--	ctrl:SetState(Controller.BODY_JUMPSTART, false)
		--end
		
		if (self.AI.TargetLostTimer.ElapsedSimTimeMS < 800 and difMagnitude < 200) or difMagnitude < 100 then
			
			self.MeleeAI.active = true
			
			if self.MeleeAI.debug then
				PrimitiveMan:DrawCirclePrimitive(self.Pos, 5, 13)
				PrimitiveMan:DrawCircleFillPrimitive(target.Pos, 2, 13)
				
				PrimitiveMan:DrawLinePrimitive(self.Pos, self.Pos + dif, 13);
			end
			
			local meleeRange = 20
			
			-- Randomize distance form target
			if self.MeleeAI.distanceOffsetDelayTimer:IsPastSimMS(self.MeleeAI.distanceOffsetDelay) then
				self.MeleeAI.distanceOffset = RangeRand(self.MeleeAI.distanceOffsetMin, self.MeleeAI.distanceOffsetMax)
				self.MeleeAI.distanceOffsetDelay = RangeRand(self.MeleeAI.distanceOffsetDelayMin, self.MeleeAI.distanceOffsetDelayMax)
				self.MeleeAI.distanceOffsetDelayTimer:Reset()
				
				local tacticList = {}
				for key, tactic in pairs(self.MeleeAI.tactics) do
					table.insert(tacticList, key)
				end
				self.MeleeAI.tactic = tacticList[math.random(1, #tacticList)]
			end
			
			self.MeleeAI.tactics[self.MeleeAI.tactic]()
			
			--- Actual target behaviour
			if IsAHuman(target) then
				target = ToAHuman(target)
				
				--print("behaving")
				ctrl:SetState(Controller.WEAPON_FIRE, false)
				self.AI.fire = false
				
				if pugilism then -- Unarmed AI
					
					local enemyUnarmed = target:NumberValueExists("Pugilism")
					local enemyAttacking = target:NumberValueExists("Puglism Attacking")
					
					if enemyAttacking then
						self:SetNumberValue("AI Block", 1)
					elseif not self:NumberValueExists("Puglism Attacking") then
						if RangeRand(0, 100) < self.MeleeAI.kickChance * 0.5 and difMagnitude < 40 then -- Tends to kick a lil too often
							self:SetNumberValue("AI Kick", 1)
						elseif difMagnitude < (meleeRange + math.random(-5,5) + 10) then
							ctrl:SetState(Controller.WEAPON_FIRE, true)
						end
					end
					
				else -- Actual melee AI
					
					local newRange = self.MeleeAI.weaponData[self.MeleeAI.weaponAttackData[self.MeleeAI.weaponNextAttackIndex].index].range + 20
					meleeRange = (newRange and newRange or 60)
					
					local targetWeapon = target.EquippedItem
					local targetWeaponMelee = false
					
					-- Get perecious data
					if targetWeapon and (IsHeldDevice(targetWeapon) or IsHDFirearm(targetWeapon)) then
						targetWeapon = ToHeldDevice(targetWeapon)
						
						if targetWeapon:IsInGroup("Weapons - Mordhau Melee") then
							 targetWeaponMelee = true
						end
					else
						targetWeaponMelee = false
					end
					
					
					if targetWeaponMelee then
					
						local attacking = (targetWeapon:NumberValueExists("Current Attack Type") and targetWeapon:GetNumberValue("Current Attack Type") > 0)
						
						
						local attackNames = {"Swing", "Horse Swing", "Stab", "Overhead"}
						local attackName = "None"
						local attackType
						local attackRange
						
						if attacking then
							attackType = targetWeapon:GetNumberValue("Current Attack Type")
							attackRange = targetWeapon:GetNumberValue("Current Attack Range")
							attackName = attackNames[attackType]
							--print(attackName)
							
							if not attackName then
								attackName = "Error!"
							end
						end
						
						-- Display it
						--PrimitiveMan:DrawTextPrimitive(target.Pos + Vector(0, -36), attackName, false, 1);
						--PrimitiveMan:DrawTextPrimitive(self.Pos + Vector(0, -36), tostring(math.floor(meleeRange)), false, 1);
						
						local block = false
						local attack = false
						
						--if self.MeleeAI.weapon then -- Melee response:
							-- Get close but not too close
						--end
						
						self.MeleeAI.parrySuccess = false
						
						-- Defend
						if self.MeleeAI.blockingFatigueMode < 2 and not self.MeleeAI.parrySuccess and ((attacking and attackType and attackRange) and self.FlipFactor ~= target.FlipFactor and difMagnitude < (attackRange + 30)) then
							-- Block
							block = true
							if self.MeleeAI.blockingDelayTimer:IsPastSimMS(self.MeleeAI.blockingDelay) then
								weapon:SetNumberValue("AI Block", 1)
									
								if not self.MeleeAI.blocking then
									self.MeleeAI.lookOffset = math.rad(70) * RangeRand(-1, 1) * (1 - self.MeleeAI.skill)
									if attackType == 4 then
										self.MeleeAI.lookOffset = self.MeleeAI.lookOffset + math.rad(math.random(25,40))
									end
									
									self.MeleeAI.blocking = true
								end
							end
							
							
						--	if math.random() < 0.05 then
						--		self.MeleeAI.randomGimmickDelay = RangeRand(self.MeleeAI.randomGimmickDelayMin, self.MeleeAI.randomGimmickDelayMax)
						--		self.MeleeAI.randomGimmickTimer:Reset()
						--	end
							
							if weapon:NumberValueExists("Blocked Mordhau") and weapon:GetNumberValue("Blocked Mordhau") then
								self.MeleeAI.parrySuccess = true
								self.MeleeAI.parryReady = true
								
								self.MeleeAI.lookOffset = math.rad(math.random(-30, 30)) * (1 - self.MeleeAI.skill)
							end
						else -- End of block
							self.MeleeAI.blockingDelayTimer:Reset()
							
							if weapon:NumberValueExists("Blocked Mordhau") and weapon:GetNumberValue("Blocked Mordhau") then
								weapon:RemoveNumberValue("Blocked Mordhau")
								self.MeleeAI.distanceOffset = self.MeleeAI.distanceOffset + 20
							end
							self.MeleeAI.parryReady = true
							--self.MeleeAI.parrySuccess = false
							
							if self.MeleeAI.blocking then
								self.MeleeAI.blocking = false
								self.MeleeAI.attackMissThereshold = self.MeleeAI.attackMissThereshold + self.MeleeAI.attackMissTheresholdGain * 0.5
								
								self.MeleeAI.blockingDelay = self.MeleeAI.blockingDelayMax * RangeRand(0.1, 1.0) * RangeRand(0.5, 1.0)
								
								--print("fatigued?")
								
								weapon:RemoveNumberValue("AI Flourish")
							end
						end
						
						if self:NumberValueExists("Kicking") or (weapon:NumberValueExists("Current Attack Type") and weapon:GetNumberValue("Current Attack Type") > 0) then
							self.MeleeAI.parrySuccess = false
							weapon:RemoveNumberValue("AI Parry")
							self.MeleeAI.attacking = true
						else
							self.MeleeAI.attacking = false
							
							if self.MeleeAI.parryReady then
								if math.random(0, 100) < (self.MeleeAI.parryChance * (self.MeleeAI.skill * self.MeleeAI.skill)) then
									weapon:SetNumberValue("AI Parry", 1)
								end
								self.MeleeAI.parryReady = false
							end
						end
						
						-- Attack
						--print(weapon)
						
						--PrimitiveMan:DrawTextPrimitive(self.Pos + Vector(0, -50 - 14), (weapon and weapon.PresetName or "None"), false, 1);
						--PrimitiveMan:DrawTextPrimitive(self.Pos + Vector(0, -50 - 28), (block and "True" or "False"), false, 1);
						--PrimitiveMan:DrawTextPrimitive(self.Pos + Vector(0, -50 - 42), (not (weapon:NumberValueExists("Current Attack Type") and weapon:GetNumberValue("Current Attack Type") > 0) and "True" or "False"), false, 1);
						
						if weapon and (not block) and self.MeleeAI.attackMissTimer:IsPastSimMS(self.MeleeAI.attackMissDelay) and not (weapon:NumberValueExists("Current Attack Type") and weapon:GetNumberValue("Current Attack Type") > 0) then
							
							--print("attemptattack")
							
							if RangeRand(0, 100) < self.MeleeAI.attackMissThereshold then -- Attack miss thereshold handling
								self.MeleeAI.attackMissThereshold = -self.MeleeAI.attackMissTheresholdGain
								self.MeleeAI.attackMissTimer:Reset()
							elseif RangeRand(0, 100) < self.MeleeAI.kickChance and difMagnitude < 40 then
								self:SetNumberValue("AI Kick", 1)
								self.MeleeAI.parryReady = false
								
								ctrl:SetState(Controller.BODY_JUMP, true)
								ctrl:SetState(Controller.BODY_JUMPSTART, true)
							elseif difMagnitude < (meleeRange + math.random(-5,5) + 10) then
								ctrl:SetState(Controller.WEAPON_FIRE, true)
								
								-- Initiate different attacks
								local attackName = self.MeleeAI.weaponData[self.MeleeAI.weaponAttackData[self.MeleeAI.weaponNextAttackIndex].index].name
								if attackName and attackName ~= "Swing" then
									weapon:SetNumberValue("AI "..attackName, 1)
								end
								-- Randomize next attack
								self.MeleeAI.weaponNextAttackIndex = math.floor(RangeRand(1, #self.MeleeAI.weaponAttackData + 1))
								-- Disable parrying variables
								self.MeleeAI.parrySuccess = false
								
								-- Increase miss thereshold
								self.MeleeAI.attackMissThereshold = self.MeleeAI.attackMissThereshold + self.MeleeAI.attackMissTheresholdGain

								-- Random chance to reset gimmick timer
							--	if math.random() < 0.05 then
							--		self.MeleeAI.randomGimmickDelay = RangeRand(self.MeleeAI.randomGimmickDelayMin, self.MeleeAI.randomGimmickDelayMax)
							--		self.MeleeAI.randomGimmickTimer:Reset()
							--	end
								
								weapon:RemoveNumberValue("AI Flourish")
							end
							
						end
						
						-- Misc
						-- if not attack and not block then
							-- -- Gimmick
							-- if difMagnitude > 60 and self.MeleeAI.randomGimmickTimer:IsPastSimMS(self.MeleeAI.randomGimmickDelay) then
								-- self.MeleeAI.randomGimmickDelay = RangeRand(self.MeleeAI.randomGimmickDelayMin, self.MeleeAI.randomGimmickDelayMax)
								-- self.MeleeAI.randomGimmickTimer:Reset()
								
								-- if math.random() < 0.2 then
									-- weapon:SetNumberValue("AI Flourish", 1)
								-- end
							-- end
						-- end
						
					else -- Versus ranged
						
						self.MeleeAI.distanceOffset = -20
						
						-- Defend if far
						if difMagnitude >= (meleeRange + math.random(-5,5) + 20) then
							local enemyCtrl = target:GetController()
							if enemyCtrl then
								local frequency = 800
								if (target.Age % frequency) < frequency * 0.7 and enemyCtrl:IsState(Controller.WEAPON_FIRE) then
									weapon:SetNumberValue("AI Block", 1)
								end
							end
						end
						
						-- Attack if close
						if weapon and not (weapon:NumberValueExists("Current Attack Type") and weapon:GetNumberValue("Current Attack Type") > 0) then
							
							if RangeRand(0, 100) < self.MeleeAI.kickChance and difMagnitude < 40 then
								self:SetNumberValue("AI Kick", 1)
								self.MeleeAI.parryReady = false
								
								ctrl:SetState(Controller.BODY_JUMP, true)
								ctrl:SetState(Controller.BODY_JUMPSTART, true)
							elseif difMagnitude < (meleeRange + math.random(-5,5) + 20) then
								ctrl:SetState(Controller.WEAPON_FIRE, true)
								
								
								
								-- Initiate different attacks
								local attackName = self.MeleeAI.weaponData[self.MeleeAI.weaponAttackData[self.MeleeAI.weaponNextAttackIndex].index].name
								if attackName and attackName ~= "Swing" then
									weapon:SetNumberValue("AI "..attackName, 1)
								end
								-- Randomize next attack
								self.MeleeAI.weaponNextAttackIndex = math.floor(RangeRand(1, #self.MeleeAI.weaponAttackData + 1))
								
								weapon:RemoveNumberValue("AI Flourish")
							end
							
						end
					end
					
				end
	
				
			elseif not pugilism then -- Basic attack, lame stuff
				self.MeleeAI.distanceOffset = 0
				
				local enemyCtrl = target:GetController()
				if enemyCtrl then
					if enemyCtrl:IsState(Controller.WEAPON_FIRE) then
						weapon:SetNumberValue("AI Block", 1)
					end
				end
				
				-- Attack if close
				if weapon and (weapon:NumberValueExists("Current Attack Type") and weapon:GetNumberValue("Current Attack Type") > 0) then
					
					if RangeRand(0, 100) < self.MeleeAI.kickChance and difMagnitude < 40 then
						self:SetNumberValue("AI Kick", 1)
						self.MeleeAI.parryReady = false
						
						ctrl:SetState(Controller.BODY_JUMP, true)
						ctrl:SetState(Controller.BODY_JUMPSTART, true)
					elseif difMagnitude < (meleeRange + math.random(-5,5) + 20) then
						ctrl:SetState(Controller.WEAPON_FIRE, true)
						
						-- Initiate different attacks
						local attackName = self.MeleeAI.weaponData[self.MeleeAI.weaponAttackData[self.MeleeAI.weaponNextAttackIndex].index].name
						if attackName and attackName ~= "Swing" then
							weapon:SetNumberValue("AI "..attackName, 1)
						end
						-- Randomize next attack
						self.MeleeAI.weaponNextAttackIndex = math.floor(RangeRand(1, #self.MeleeAI.weaponAttackData + 1))
						
						weapon:RemoveNumberValue("AI Flourish")
					end
					
				end
			end
			
			-- Move
			local distanceToKeep = meleeRange + self.MeleeAI.distanceOffset
			if math.abs(dif.X) > (distanceToKeep - 7) then
				movementInput = Sign(dif.X)
			elseif math.abs(dif.X) < (distanceToKeep - 5) then
				movementInput = -Sign(dif.X)
			end
			
			-- Movement
			ctrl:SetState(Controller.BODY_CROUCH, false)
			
			if difMagnitude < 120 then
				ctrl:SetState(Controller.BODY_JUMP, false)
				ctrl:SetState(Controller.BODY_JUMPSTART, false)
				self.AI.proneState = AHuman.NOTPRONE
			end
			if movementInput ~= 0 then
				if self.MeleeAI.movementInputPrevious ~= movementInput then
					self.MeleeAI.movementInputPrevious = movementInput
					self.MeleeAI.movementDirectionChangeTimer:Reset()
				end
				
				if self.MeleeAI.movementDirectionChangeTimer:IsPastSimMS(self.MeleeAI.movementDirectionChangeDuration) then
					if movementInput == 1 then
						ctrl:SetState(Controller.MOVE_RIGHT, true)
						ctrl:SetState(Controller.MOVE_LEFT, false)
						
						self.AI.lateralMoveState = Actor.LAT_RIGHT
					elseif movementInput == -1 then
						ctrl:SetState(Controller.MOVE_LEFT, true)
						ctrl:SetState(Controller.MOVE_RIGHT, false)
						
						self.AI.lateralMoveState = Actor.LAT_LEFT
					end
				else
					ctrl:SetState(Controller.MOVE_RIGHT, false)
					ctrl:SetState(Controller.MOVE_LEFT, false)
				end
				
			end
			
			-- Look around
			local sway = math.sin(self.Age * 0.01 + self.UniqueID) * 0.05 + math.sin(self.Age * 0.002 + 2) * 0.1 + math.sin(self.Age * 0.015 - 3 - self.UniqueID) * 0.05 + math.sin(self.Age * 0.005 + 6) * 0.075 * 0.05 + math.sin(self.Age * 0.001 + 15 + self.UniqueID) * 0.3
			local factor = sway * (1 - (self.MeleeAI.skill * self.MeleeAI.skill)) + self.MeleeAI.lookOffsetCurrent * self.FlipFactor
			--self:SetAimAngle(math.pi * 0.5 * factor)
			
			if IsAHuman(target) and target.Head then
				ctrl.AnalogAim = (SceneMan:ShortestDistance(self.Pos, ToAHuman(target).Head.Pos + Vector(0, 5), SceneMan.SceneWrapsX).Normalized):RadRotate(factor)
			else
				ctrl.AnalogAim = (dif.Normalized):RadRotate(factor)
			end
			
			local speed = 35 * (0.3 + self.MeleeAI.skill)
			self.MeleeAI.lookOffsetCurrent = (self.MeleeAI.lookOffsetCurrent + self.MeleeAI.lookOffset * TimerMan.DeltaTimeSecs * speed) / (1 + TimerMan.DeltaTimeSecs * speed)
			
			if not self.MeleeAI.blocking then
				self.MeleeAI.lookOffset = self.MeleeAI.lookOffset / (1 + TimerMan.DeltaTimeSecs * 35 * (0.3 + self.MeleeAI.skill))
			else
				self.MeleeAI.lookOffset = self.MeleeAI.lookOffset / (1 + TimerMan.DeltaTimeSecs * 15 * (0.3 + (1 - self.MeleeAI.skill)))
			end
			
		elseif self.MeleeAI.active then
			self.MeleeAI.active = false
			self.AI.Target = nil
			self.MeleeAI.blocking = false
			self.MeleeAI.attacking = false
		elseif weapon then
			weapon:SetNumberValue("AI Block", 1)
		end
	elseif self.MeleeAI.active then
		self.MeleeAI.active = false
		self.AI.Target = nil
		self.MeleeAI.blocking = false
		self.MeleeAI.attacking = false
	end
	
end