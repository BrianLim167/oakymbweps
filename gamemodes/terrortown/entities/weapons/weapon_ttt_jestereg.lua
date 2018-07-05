AddCSLuaFile()

SWEP.HoldType              = "ar2"

if CLIENT then
   SWEP.PrintName          = "Jester Emulator Gun"
   SWEP.Slot               = 6

   SWEP.ViewModelFlip      = false
   SWEP.ViewModelFOV       = 64

   SWEP.Icon               = "vgui/ttt/icon_m16"
   SWEP.IconLetter         = "w"
end

SWEP.Base                  = "weapon_ttt_m16"

SWEP.Kind                  = WEAPON_EQUIP
SWEP.CanBuy                = {ROLE_TRAITOR} -- only traitors can buy
if ROLE_SURVIVALIST then 
	SWEP.CanBuy                = {ROLE_TRAITOR, ROLE_SURVIVALIST}
end
SWEP.LimitedStock           = true -- only buyable once
SWEP.WeaponID              = AMMO_M16

SWEP.Primary.Damage = 0

function SWEP:PreDrop()
   self:SetZoom(false)
   self:SetIronsights(false)
   return self.BaseClass.BaseClass.PreDrop(self)
end