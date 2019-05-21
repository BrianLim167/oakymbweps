AddCSLuaFile()

if CLIENT then
   SWEP.PrintName = "P228"
   SWEP.Slot = 1
   SWEP.Icon = "vgui/ttt/icon_glock"
   SWEP.IconLetter = "y"
end

SWEP.Base = "weapon_ttt_brekiy_base"
SWEP.HoldType = "pistol"

SWEP.Primary.Ammo = "Pistol"
SWEP.Primary.Delay = 0.125
SWEP.Primary.Recoil = 0.00625
SWEP.Primary.Cone = 0.013
SWEP.Primary.Damage = 17
SWEP.Primary.Automatic = false
SWEP.Primary.ClipSize = 12
SWEP.Primary.ClipMax = 60
SWEP.Primary.DefaultClip = 12
SWEP.Primary.Sound = Sound( "Weapon_p228.shot" )
SWEP.HeadshotMultiplier = 2
SWEP.CrouchBonus 				 	= 0.7
SWEP.MovePenalty			 	 	= 0.02
SWEP.JumpPenalty			 	 	= 0.2
SWEP.MaxCone 					 	= 0.06

SWEP.AimPatternX 		= function(t)
		return 0
	end
SWEP.AimPatternY 		= function(t)
		return 1.75 * t
	end
SWEP.BloomRecoverRate 	= 0.00075
SWEP.AimRecoverRate		= 0.175
SWEP.AimKick			= 1.1
SWEP.Primary.ShoveY         = 0.2
SWEP.Primary.ShoveX         = 0.35

-- Model properties
SWEP.UseHands = true
SWEP.ViewModelFlip = false
SWEP.ViewModelFOV = 54
SWEP.ViewModel = Model( "models/weapons/cstrike/c_pist_p228.mdl" )
SWEP.WorldModel = Model( "models/weapons/w_pist_p228.mdl" )

SWEP.IronSightsPos = Vector( -5.961, -9.214, 2.839 )

SWEP.Kind = WEAPON_PISTOL
SWEP.AutoSpawnable = true
SWEP.AmmoEnt = "item_ammo_pistol_ttt"
SWEP.AllowDrop = true
SWEP.IsSilent = false
SWEP.NoSights = false
