AddCSLuaFile()

SWEP.HoldType = "pistol"


if CLIENT then
   SWEP.PrintName = "Glock-18"
   SWEP.Slot = 1

   SWEP.Icon = "vgui/ttt/icon_glock"
end

SWEP.Kind = WEAPON_PISTOL
SWEP.WeaponID = AMMO_GLOCK

SWEP.Base = "weapon_ttt_brekiy_base"
SWEP.Primary.Recoil	= 0.022
SWEP.Primary.Damage = 12
SWEP.Primary.Delay = 0.0545
SWEP.Primary.Cone = 0.013
SWEP.Primary.ClipSize = 17
SWEP.Primary.Automatic = true
SWEP.Primary.DefaultClip = 17
SWEP.Primary.ClipMax = 54
SWEP.Primary.Ammo = "Pistol"
SWEP.AutoSpawnable = true
SWEP.AmmoEnt = "item_ammo_pistol_ttt"
SWEP.HeadshotMultiplier = 2
SWEP.CrouchBonus 				 	= 0.9
SWEP.MovePenalty			 	 	= 1.01
SWEP.JumpPenalty			 	 	= 2
SWEP.MaxCone 					 	= 0.06

SWEP.AimPatternX 		= function(t)
		return 0.01 * t * math.sin(0.8 * t)
	end
SWEP.AimPatternY 		= function(t)
		return 0.375 * t
	end
SWEP.BloomRecoverRate 	= 0.005
SWEP.AimRecoverRate		= 0.35
SWEP.AimKick				= 0.35
SWEP.Primary.ShoveY         = 0.4
SWEP.Primary.ShoveX         = 0.5

SWEP.UseHands			= true
SWEP.ViewModelFlip		= false
SWEP.ViewModelFOV		= 54
SWEP.ViewModel  = "models/weapons/cstrike/c_pist_glock18.mdl"
SWEP.WorldModel = "models/weapons/w_pist_glock18.mdl"

SWEP.Primary.Sound = Sound( "Weapon_glock.shot" )
SWEP.IronSightsPos = Vector( -5.79, -3.9982, 2.8289 )