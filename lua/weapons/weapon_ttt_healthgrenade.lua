AddCSLuaFile()

SWEP.HoldType           = "grenade"

if CLIENT then
   SWEP.PrintName       = "Health Grenade"
   SWEP.Slot            = 3

   SWEP.ViewModelFlip   = false
   SWEP.ViewModelFOV    = 54

   SWEP.Icon            = "vgui/ttt/icon_nades"
   SWEP.IconLetter      = "Q"
end

SWEP.Base               = "weapon_tttbasegrenade"


SWEP.Kind               = WEAPON_NADE

SWEP.UseHands           = true
SWEP.ViewModel          = "models/weapons/cstrike/c_eq_smokegrenade.mdl"
SWEP.WorldModel         = "models/weapons/w_eq_smokegrenade.mdl"

SWEP.Weight             = 5
SWEP.AutoSpawnable      = false
SWEP.Spawnable          = true
-- really the only difference between grenade weapons: the model and the thrown
-- ent.

SWEP.EquipMenuData = {
  type = "Weapon",
  desc = [[ Heals players in an area. Lasts for 30 seconds.]]

};

SWEP.Icon = "VGUI/ttt/icon_nades"

SWEP.CanBuy = { ROLE_DETECTIVE, ROLE_TRAITOR }
SWEP.LimitedStock = true

function SWEP:GetGrenadeName()
   return "ttt_healthgrenade_proj"
end
