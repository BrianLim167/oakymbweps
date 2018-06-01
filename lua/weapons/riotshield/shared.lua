-----------------------------------------------------------------------------------------|
-----------------------------By BuzzOfwar------------------------------------------------|
-----------------------------------------------------------------------------------------|
SWEP.WorldModel = "models/arleitiss/riotshield/shield.mdl"
SWEP.ViewModel = ""
SWEP.Category = "Police Pack"    
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.HoldType = "slam"  
SWEP.Author = "Buzzofwar"
SWEP.Contact = "Buzzofwar"
SWEP.Purpose = "Hold"
SWEP.Instructions = "Look Forward Dont move And Deploy it"
-----------------------------------------------------------------------------------------|
SWEP.Primary.Ammo = "none"
SWEP.Primary.ClipSize  = -1
SWEP.Primary.DefaultClip = 1
SWEP.Primary.Automatic  = true

SWEP.Secondary.ClipSize 	= -1                    
SWEP.Secondary.Delay 		= 0.7              
SWEP.Secondary.Ammo 		= "none"

SWEP.Base = "weapon_tttbase"
SWEP.Kind = WEAPON_EQUIP2
 
 -- TTT Conversion Code --
 
 SWEP.EquipMenuData = {
      name = "Riot Shield",
      type = "item_weapon",
      desc = "Look Forward!"
   };
SWEP.Icon = "materials/vgui/ttt/icon_riotshield.png"

SWEP.CanBuy = {ROLE_DETECTIVE}
SWEP.LimitedStock = false

SWEP.AutoSpawnable = false
SWEP.AdminSpawnable = true
SWEP.InLoadoutFor = nil
SWEP.AllowDrop = true
SWEP.IsSilent = false
SWEP.NoSights = true

-- /TTT Conversion Code --

-----------------------------------------------------------------------------------------|
function SWEP:Initialize()
	self:SetWeaponHoldType(self.HoldType)
	if ( SERVER ) then
    self:SetWeaponHoldType(self.HoldType)
	end
end
-----------------------------------------------------------------------------------------|
function SWEP:Deploy()
	if SERVER then
		if IsValid(self.ent) then self.ent:Remove() end
		self:SetModelScale(0,0)
		self.ent = ents.Create("prop_physics")
			self.ent:SetModel("models/arleitiss/riotshield/shield.mdl")
			self.ent:SetPos(self.Owner:GetPos() + Vector(0,0,10) + (self.Owner:GetForward()*20))
			self.ent:SetAngles(Angle(0,self.Owner:EyeAngles().y,self.Owner:EyeAngles().r))
			self.ent:SetParent(self.Owner)
			self.ent:Fire("SetParentAttachmentMaintainOffset", "eyes", 0.01) 
			self.ent:SetCollisionGroup( COLLISION_GROUP_DEBRIS ) 
			self.ent:Spawn()
			self.ent:Activate()
	end
	return true
end
-----------------------------------------------------------------------------------------|
function SWEP:Holster()
	if SERVER then
		self.ent:Remove()
		return true
	end
end
-----------------------------------------------------------------------------------------|
function SWEP:OnDrop()
	if SERVER then
			self.ent:Remove()
			self:SetModelScale(1,0)
	end
end
-----------------------------------------------------------------------------------------|
if SERVER then
	AddCSLuaFile("shared.lua")
	resource.AddFile("materials/arleitiss/riotshield/shield_edges.vmt")
	resource.AddFile("materials/arleitiss/riotshield/shield_glass.vmt")
	resource.AddFile("materials/arleitiss/riotshield/shield_grip.vmt")
	resource.AddFile("materials/arleitiss/riotshield/shield_gripbump.vtf")
	resource.AddFile("models/arleitiss/riotshield/shield.mdl")
	resource.AddFile("materials/arleitiss/riotshield/riot_metal.vmt")
	resource.AddFile("materials/arleitiss/riotshield/riot_metal_bump.vtf")
	resource.AddFile("materials/arleitiss/riotshield/shield_cloth.vmt")

end
-----------------------------------------------------------------------------------------|
if CLIENT then
	SWEP.PrintName = "RiotShield"
	SWEP.Slot = 7
	SWEP.SlotPos = 7
	SWEP.DrawAmmo = false
	SWEP.DrawCrosshair = false
end
-----------------------------------------------------------------------------------------|
function getChestPosAng(Chest)
    local attachmentID=Chest:LookupAttachment("eyes");
    return Chest:GetAttachment(attachmentID)
end
-----------------------------------------------------------------------------------------|
function SWEP:OnDrop()
		if SERVER then
		if not IsValid(self.ent) then return end
			self.ent:Remove()
			self:SetModelScale(1,0)
end
end
-----------------------------------------------------------------------------------------|
function SWEP:OnRemove()
		if SERVER then
		if not IsValid(self.ent) then return end
		self.ent:Remove()
end
end