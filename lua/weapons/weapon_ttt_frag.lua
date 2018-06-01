AddCSLuaFile()

if CLIENT then
   SWEP.PrintName = "Frag Grenade"
   SWEP.Slot = 3
   SWEP.Icon = "vgui/ttt/icon_nades"
   SWEP.IconLetter = "O"
end

-- Always derive from weapon_tttbasegrenade
SWEP.Base = "weapon_tttbasegrenade"

-- Standard GMod values
SWEP.HoldType = "grenade"
SWEP.Weight = 5

-- Model properties
SWEP.UseHands = true
SWEP.ViewModelFlip = false
SWEP.ViewModelFOV = 54
SWEP.ViewModel = Model( "models/weapons/cstrike/c_eq_fraggrenade.mdl" )
SWEP.WorldModel = Model( "models/weapons/w_eq_fraggrenade.mdl" )

SWEP.Kind = WEAPON_NADE
SWEP.AutoSpawnable = false
SWEP.CanBuy = { ROLE_TRAITOR }
SWEP.InLoadoutFor = { nil }
SWEP.LimitedStock = true
SWEP.AllowDrop = true
SWEP.NoSights = true

function SWEP:GetGrenadeName()
   return "ttt_frag_proj"
end

if CLIENT then
   SWEP.EquipMenuData = {
      type = "Grenade",
      desc = "A highly explosive grenade."
   }
end
