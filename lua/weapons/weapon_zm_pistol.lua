AddCSLuaFile()
 
SWEP.HoldType = "pistol"
   

if CLIENT then
   SWEP.PrintName = "Five-Seven"
   SWEP.Slot = 1

   SWEP.Icon = "vgui/ttt/icon_pistol"
end

SWEP.Kind = WEAPON_PISTOL
SWEP.WeaponID = AMMO_PISTOL

SWEP.Base = "weapon_ttt_brekiy_base"
SWEP.Primary.Recoil	= 0.025
SWEP.Primary.Damage = 13
SWEP.Primary.Delay = 0.125
SWEP.Primary.Cone = 0.0115
SWEP.Primary.ClipSize = 20
SWEP.Primary.Automatic = false
SWEP.Primary.DefaultClip = 20
SWEP.Primary.ClipMax = 60
SWEP.Primary.Ammo = "Pistol"
SWEP.AutoSpawnable = true
SWEP.AmmoEnt = "item_ammo_pistol_ttt"
SWEP.HeadshotMultiplier = 2
SWEP.CrouchBonus 				 	= 0.7
SWEP.MovePenalty			 	 	= 0.005
SWEP.JumpPenalty			 	 	= 0.02
SWEP.MaxCone 					 	= 0.06

SWEP.AimPatternX 		= function(t)
		return 0
	end
SWEP.AimPatternY 		= function(t)
		return 20 * t / (t + 15)
	end
SWEP.BloomRecoverRate 	= 0.0012
SWEP.AimRecoverRate		= 0.075
SWEP.AimKick			= 0.15
SWEP.Primary.ShoveY         = 0.5
SWEP.Primary.ShoveX         = 1.0

SWEP.UseHands			= true
SWEP.ViewModelFlip		= false
SWEP.ViewModelFOV		= 54
SWEP.ViewModel  = "models/weapons/cstrike/c_pist_fiveseven.mdl"
SWEP.WorldModel = "models/weapons/w_pist_fiveseven.mdl"

SWEP.Primary.Sound = Sound( "Weapon_fiveseven.shot" )
SWEP.IronSightsPos = Vector(-5.95, -4, 2.799)
SWEP.IronSightsAng = Vector(0, 0, 0)