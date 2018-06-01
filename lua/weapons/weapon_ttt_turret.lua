--- Essayer de virer les "faux dégâts" avec le feu après destruction. Remplacer le groupe de collisions du feu, ça devrait être bon.
-- TTT Turret by Mohamed RACHID

SWEP.HoldType = "duel"

local gamemode_name = engine.ActiveGamemode()
if gamemode_name == "terrortown" then
	SWEP.Base = "weapon_tttbase"
	if SERVER then
		resource.AddWorkshop("233976994")
	end
end

local WorldModel = Model("models/combine_turrets/floor_turret.mdl")
SWEP.ViewModel			 = "models/weapons/v_crowbar.mdl"
SWEP.WorldModel			= WorldModel


SWEP.DrawCrosshair		= false
SWEP.Primary.ClipSize		 = -1
SWEP.Primary.DefaultClip	 = -1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo		 = "none"
SWEP.Primary.Delay = 0.001

SWEP.Secondary.ClipSize	  = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Automatic	 = false
SWEP.Secondary.Ammo	  = "none"
SWEP.Secondary.Delay = 0.001

-- This is special equipment

SWEP.Kind = WEAPON_EQUIP2
SWEP.CanBuy = {ROLE_TRAITOR}
SWEP.Spawnable = true
SWEP.LimitedStock = false

SWEP.Icon = "VGUI/ttt/weapon_ttt_turret_mr_v1"

SWEP.AllowDrop = true
SWEP.NoSights = true
SWEP.HealthPoints = 500

if CLIENT then
	local language = GetConVarString("gmod_language")
	if language == "fr" then
		SWEP.PrintName = "Tourelle"
	else
		SWEP.PrintName = "Turret"
	end
else
	SWEP.PrintName = "Turret"
end
SWEP.Category = "TTT"


if CLIENT then
	local language = GetConVarString("gmod_language")
	
	if gamemode_name == "terrortown" then
		SWEP.Slot = 7
	else
		SWEP.Slot = 4
	end
	
	SWEP.ViewModelFOV = 10
	
	local lang_desc
	local lang_mapwarn
	if language == "fr" then
		lang_desc = "Tire automatiquement et blesse sévèrement\nles innocents imprudents."
	else
		lang_desc = "Automatically shoot and severely harm\nimprudent innocents."
	end
	SWEP.EquipMenuData = {
		type = "item_weapon",
		desc = lang_desc
	};
	
	SWEP.Purpose = lang_desc
end

if SERVER then
	-- Application des dégâts
	hook.Add("ScaleNPCDamage", "turret_ScaleNPCDamage", function (npc, hitgroup, dmginfo)
		if npc.weapon_ttt_turret then
			local damage = dmginfo:GetDamage()
			dmginfo:SetDamage(0)
			npc:SetHealth(npc:Health() - damage)
			if npc:Health() <= 0 then
				local position = npc:GetPos()
				local support = npc:GetParent()
				local CreationID = npc:GetCreationID()
				npc:Remove()
				support.turret = ents.Create("prop_dynamic")
				if IsValid(support.turret) then
					support.turret:SetModel(WorldModel)
					support.turret:SetParent(support)
					support.turret:SetLocalPos(Vector(0, 0, 0))
					support.turret:SetAngles(support:GetAngles() + Angle(0, 0, 0))
					support.turret.weapon_ttt_turret = true
					local explosion = EffectData()
					explosion:SetStart(position+Vector(0,0,40))
					explosion:SetOrigin(position+Vector(0,0,40))
					explosion:SetScale(1)
					explosion:SetEntity(support.turret)
					util.Effect("Explosion", explosion, true, true)
					support.turret:Ignite(60)
					support.turret:SetMaterial("models/props_pipes/GutterMetal01a")
				end
			end
		end
	end)
	-- Suppression et modification des dégâts
	hook.Add("EntityTakeDamage", "turret_EntityTakeDamage", function (target, dmg)
		local turret
		if dmg:GetInflictor().weapon_ttt_turret then
			turret = dmg:GetInflictor()
		elseif IsValid(dmg:GetInflictor():GetParent()) then
			turret = dmg:GetInflictor():GetParent()
		end
		if IsValid(turret) and turret.weapon_ttt_turret then
			local DamageType = dmg:GetDamageType()
			-- Dégâts liés à la destruction de la tourelle
			if DamageType == DMG_BURN or DamageType == DMG_BLAST then
				dmg:ScaleDamage(0)
				dmg:SetDamageType(DMG_GENERIC) -- pas de son de brûlure
				return dmg
			-- Dégâts liés aux attaques de la tourelle
			elseif gamemode_name == "terrortown" then
				local attacker = turret:GetCreator()
				if IsValid(attacker) then
					dmg:SetAttacker(attacker)
					dmg:SetInflictor(turret)
				end
				if target:IsPlayer() then
					if target:IsActiveTraitor() then
						dmg:ScaleDamage(2)
						local amount = dmg:GetDamage()
						dmg:ScaleDamage(0)
						turret:FakeDamage(target, amount)
						return dmg
					else
						dmg:ScaleDamage(3)
						return dmg
					end
				else
					dmg:ScaleDamage(0)
					return dmg
				end
			end
		end
	end)
end


-- Modification des dégâts affichés (anti-testeur)
if gamemode_name == "terrortown" then
	if SERVER then
		util.AddNetworkString("weapon_ttt_turret_fakedmg")
		local FakeHealth = {}
		function SWEP:FakeDamage (ply, amount)
			local UserID = ply:UserID()
			if FakeHealth[UserID] == nil then
				FakeHealth[UserID] = 0
			end
			FakeHealth[UserID] = FakeHealth[UserID] + amount
			net.Start("weapon_ttt_turret_fakedmg")
				net.WriteEntity(ply)
				net.WriteUInt(FakeHealth[UserID], 32)
			net.Broadcast()
		end
		hook.Add("TTTEndRound", "turret_TTTEndRound", function (result)
			FakeHealth = {}
		end)
		hook.Add("TTTBeginRound", "turret_TTTBeginRound", function ()
			FakeHealth = {} -- une fois encore par sécurité
		end)
	else
		local Entity = FindMetaTable("Entity")
		if Entity then
			if !isfunction(Entity.HealthTurretNoFake) then
				Entity.HealthTurretNoFake = Entity.Health
			end
			function Entity:Health (...)
				if self.HealthTurretFakeAmount == nil or self.HealthTurretFakeAmount == 0 then
					return self:HealthTurretNoFake(...)
				else
					local fakehealth = self:HealthTurretNoFake(...) - self.HealthTurretFakeAmount
					if fakehealth < 1 then
						fakehealth = 1
					end
					return fakehealth
				end
			end
		end
		net.Receive("weapon_ttt_turret_fakedmg", function (len, pl)
			local ply = net.ReadEntity()
			local amount = net.ReadUInt(32)
			if IsValid(ply) and ply != LocalPlayer() and isnumber(amount) then
				ply.HealthTurretFakeAmount = amount
			end
		end)
		hook.Add("TTTEndRound", "turret_TTTEndRound", function (result)
			for _, ply in pairs(player.GetAll()) do
				ply.HealthTurretFakeAmount = nil
			end
		end)
		hook.Add("TTTBeginRound", "turret_TTTBeginRound", function ()
			for _, ply in pairs(player.GetAll()) do
				ply.HealthTurretFakeAmount = nil -- une fois encore par sécurité
			end
		end)
	end
end

function SWEP:RemoveClientPreview()
	if CLIENT then
		if IsValid(self.viewturret) then
			self.viewturret:SetNoDraw(true)
			self.viewturret:Remove()
		end
	end
end

-- On ajoute le comportement de la prévisualisation lorsque l'arme est jetée ou ramassée.
if CLIENT then
	function SWEP:OwnerChanged() -- OnDrop does not work because it is the normal drop.
		if LocalPlayer() != self.Owner then
			self:RemoveClientPreview()
		else
			self:Deploy()
		end
	end
end

function SWEP:PrimaryAttack()
	self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	self:HealthDrop()
end
function SWEP:SecondaryAttack()
	self.Weapon:SetNextSecondaryFire( CurTime() + self.Secondary.Delay )
	self:HealthDrop()
end

function SWEP:HealthDrop()
	local language = GetConVarString("gmod_language")
	if SERVER then
		local ply = self.Owner
		if not IsValid(ply) then return end

		if self.Planted then return end

		local vsrc = ply:GetShootPos()
		local vang = ply:GetAimVector()
		local vvel = ply:GetVelocity()
		local eyetrace = ply:GetEyeTrace()
		local distply = eyetrace.HitPos:Distance(ply:GetPos())
		
		-- Too far from the owner
		if distply > 100 or !eyetrace.HitWorld then
			if language == "fr" then
				ply:ChatPrint("Veuillez choisir un autre emplacement en visant ailleurs.")
			else
				ply:ChatPrint("Please choose another location by aiming somewhere else.")
			end
			return false
		end
		
		-- local vthrow = vvel + vang * 200

		local playerangle = ply:GetAngles()
		local supportangle
		local support = ents.Create("prop_dynamic")
		if IsValid(support) then
			if undo != nil then
				undo.Create("NPC")
					undo.SetPlayer(ply)
					undo.AddEntity(support)
					undo.SetCustomUndoText("Undone "..self.PrintName)
				undo.Finish("Weapon ("..tostring(self.PrintName)..")")
			end
			if ply.AddCleanup != nil then
				ply:AddCleanup("npcs", support)
			end
			support:SetModel("models/hunter/blocks/cube025x025x025.mdl")
			-- support:SetPos(vsrc + vang * 10)
			supportangle = support:GetAngles()
			support:SetPos(eyetrace.HitPos + Vector(0, 0, 0))
			support:Spawn()
			
			-- Invisible (propre)
			support:SetRenderMode(10)
			support:DrawShadow(false)
			
			support.turret = ents.Create("npc_turret_floor")
			if IsValid(support.turret) then
				self.Planted = true
				support.turret:SetParent(support)
				support.turret:SetLocalPos(Vector(0, 0, 0))
				
				support:SetAngles(Angle(supportangle.p, playerangle.y, supportangle.r))
				support.turret:SetAngles(support:GetAngles() + Angle(0, 0, 0))
				
				support.turret:Spawn()
				support.turret:Activate()
				support.turret:SetMaxHealth(self.HealthPoints)
				support.turret:SetHealth(self.HealthPoints)
				support.turret:SetBloodColor(BLOOD_COLOR_MECH)
				support.turret.FakeDamage = self.FakeDamage
				support.turret.weapon_ttt_turret = true
				support.turret.Icon = self.Icon
				
				support.turret:SetPhysicsAttacker(ply) -- inutile
				support.turret:SetCreator(ply) -- responsable des dégâts
				support.turret.fingerprints = {ply} -- ADN
				
				-- On empêche la tourelle de bloquer son propriétaire tant qu'il est à proximité.
				support.turret:SetOwner(ply)
				local turret_pos = support.turret:GetPos()
				local distance_timer = "turret" .. tostring(support.turret:GetCreationID())
				timer.Create(distance_timer, 0.2, 0, function ()
					if (not IsValid(support.turret)) or (not IsValid(ply)) then
						timer.Destroy(distance_timer)
						return
					end
					
					local ply_pos = ply:GetPos()
					if math.abs(turret_pos.x - ply_pos.x) > 50 or math.abs(turret_pos.y - ply_pos.y) > 50 then
						support.turret:SetOwner(nil)
						timer.Destroy(distance_timer)
					end
				end)
				
				self:Remove()
			end
		end
	end
end


function SWEP:Reload()
	return false
end

function SWEP:OnRemove()
	if CLIENT and IsValid(self.Owner) and self.Owner == LocalPlayer() and self.Owner:Alive() then
		self:RemoveClientPreview()
		RunConsoleCommand("lastinv")
	end
end

if CLIENT then
	if gamemode_name == "terrortown" then
		function SWEP:Initialize()
			self:Deploy()
			self.viewturret:SetNoDraw(true)
			self.viewturret.hidden = true
			
			return self.BaseClass.Initialize(self)
		end
	else
		function SWEP:Initialize()
			self:Deploy()
			
			local return_val = self.BaseClass.Initialize(self)
			
			self:SetWeaponHoldType(self.HoldType)
			
			return return_val
		end
	end
end

function SWEP:Deploy()
	if SERVER and IsValid(self.Owner) then
		self.Owner:DrawViewModel(false)
	end
	if CLIENT then
		if !IsValid(self.viewturret) then
			self.viewturret = ents.CreateClientProp(WorldModel)
		end
		if IsValid(self.viewturret) then
			self.viewturret:SetParent(self)
			self.viewturret:Spawn()
			self.viewturret.WellPlaced = true
			self:Think()
		end
	end
	return true
end

function SWEP:Holster()
	self:RemoveClientPreview() -- for some reason, it does not always work
	return true
end

if CLIENT then
	function SWEP:Think()
		if IsValid(self.viewturret) then
			local ply = LocalPlayer()
			if ply:GetActiveWeapon() == self then
				if self.viewturret.hidden then -- on doit le cacher de cette façon car lors du déploiement initial le hook Deploy ne fonctionne pas
					self.viewturret:SetNoDraw(false)
					self.viewturret.hidden = false
				end
				local eyetrace = ply:GetEyeTrace()
				local newpos = eyetrace.HitPos
				local distply = newpos:Distance(ply:GetPos())
				self.viewturret:SetPos(newpos)
				self.viewturret:SetAngles(Angle(0, ply:GetAngles().y, 0) + Angle(0, 0, 0))
				if distply > 100 or !eyetrace.HitWorld then
					if self.viewturret.WellPlaced then
						self.viewturret:SetColor(Color(128,0,0))
						self.viewturret:SetMaterial("models/shiny")
						self.viewturret.WellPlaced = false
					end
				else
					if !self.viewturret.WellPlaced then
						self.viewturret:SetColor(Color(255,255,255))
						self.viewturret:SetMaterial("")
						self.viewturret.WellPlaced = true
					end
				end
			else
				if !self.viewturret.hidden then
					self.viewturret:SetNoDraw(true)
					self.viewturret.hidden = true
				end
			end
		end
	end
end