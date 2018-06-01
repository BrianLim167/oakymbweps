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
SWEP.Primary.Recoil	= 0.0025
SWEP.Primary.Damage = 12
SWEP.Primary.Delay = 0.0545
SWEP.Primary.Cone = 0.017
SWEP.Primary.ClipSize = 17
SWEP.Primary.Automatic = true
SWEP.Primary.DefaultClip = 17
SWEP.Primary.ClipMax = 54
SWEP.Primary.Ammo = "Pistol"
SWEP.AutoSpawnable = true
SWEP.AmmoEnt = "item_ammo_pistol_ttt"
SWEP.HeadshotMultiplier = 2
SWEP.CrouchBonus 				 	= 0.7
SWEP.MovePenalty			 	 	= 1.01
SWEP.JumpPenalty			 	 	= 2
SWEP.MaxCone 					 	= 0.06

SWEP.UseHands			= true
SWEP.ViewModelFlip		= false
SWEP.ViewModelFOV		= 54
SWEP.ViewModel  = "models/weapons/cstrike/c_pist_glock18.mdl"
SWEP.WorldModel = "models/weapons/w_pist_glock18.mdl"

SWEP.Primary.Sound = Sound( "Weapon_glock.shot" )
SWEP.IronSightsPos = Vector( -5.79, -3.9982, 2.8289 )