AddCSLuaFile()

SWEP.HoldType              = "pistol"

if CLIENT then
   SWEP.PrintName          = "sipistol_name"
   SWEP.Slot               = 6

   SWEP.ViewModelFlip      = false
   SWEP.ViewModelFOV       = 54

   SWEP.EquipMenuData = {
      type = "item_weapon",
      desc = "sipistol_desc"
   };

   SWEP.Icon               = "vgui/ttt/icon_silenced"
   SWEP.IconLetter         = "a"
end

SWEP.Base                  = "weapon_ttt_brekiy_base"

SWEP.ShortLightBrightness = -10
SWEP.LongLightBrightness = -50

SWEP.Primary.Recoil		   = 0.0115
SWEP.Primary.Damage        = 17
SWEP.Primary.Delay         = 0.15
SWEP.Primary.Cone          = 0.006
SWEP.Primary.ClipSize      = 20
SWEP.Primary.Automatic     = true
SWEP.Primary.DefaultClip   = 20
SWEP.Primary.ClipMax       = 60
SWEP.Primary.Ammo          = "Pistol"
SWEP.Primary.Sound         = Sound( "Weapon_usp.shot" )
SWEP.Primary.SoundLevel    = 50
SWEP.HeadshotMultiplier    = 2
SWEP.CrouchBonus 				 	= 0.55
SWEP.MovePenalty			 	 	= 0.175
SWEP.JumpPenalty			 	 	= 0.02
SWEP.MaxCone 					 	= 0.06
SWEP.Tracer							= "None"

SWEP.AimPatternX 		= function(t)
		return 0.2 * math.sin( 2 * t )
	end
SWEP.AimPatternY 		= function(t)
		return 20 * t / (t + 15)
	end
SWEP.BloomRecoverRate 	= 0.0017
SWEP.AimRecoverRate		= 0.075
SWEP.AimKick			= 1.15
SWEP.Primary.ShoveY         = 0.1
SWEP.Primary.ShoveX         = 0.1

SWEP.Kind                  = WEAPON_EQUIP
SWEP.CanBuy                = {ROLE_TRAITOR} -- only traitors can buy

if ROLE_SURVIVALIST then 
	SWEP.CanBuy                = {ROLE_TRAITOR, ROLE_SURVIVALIST}
end

SWEP.WeaponID              = AMMO_SIPISTOL

SWEP.AmmoEnt               = "item_ammo_pistol_ttt"
SWEP.IsSilent              = true

SWEP.UseHands              = true
SWEP.ViewModel             = "models/weapons/cstrike/c_pist_usp.mdl"
SWEP.WorldModel            = "models/weapons/w_pist_usp_silencer.mdl"

SWEP.IronSightsPos         = Vector( -5.91, -4, 2.84 )
SWEP.IronSightsAng         = Vector(-0.5, 0, 0)

SWEP.PrimaryAnim           = ACT_VM_PRIMARYATTACK_SILENCED
SWEP.ReloadAnim            = ACT_VM_RELOAD_SILENCED

function SWEP:Deploy()
   self:SendWeaponAnim(ACT_VM_DRAW_SILENCED)
   return self.BaseClass.Deploy(self)
end