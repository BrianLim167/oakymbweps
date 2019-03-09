
AddCSLuaFile()

SWEP.HoldType			= "pistol"

if CLIENT then
   SWEP.PrintName			= "Desert Eagle"			
   SWEP.Author				= "TTT"

   SWEP.Slot				= 1
   SWEP.SlotPos			= 1

   SWEP.Icon = "vgui/ttt/icon_deagle"
end

SWEP.Base		= "weapon_ttt_brekiy_base"

SWEP.Spawnable = true
SWEP.Kind = WEAPON_PISTOL
SWEP.WeaponID = AMMO_DEAGLE

if ROLE_SURVIVALIST then 
	SWEP.CanBuy                = {ROLE_SURVIVALIST}
end


SWEP.Primary.Ammo       = "AlyxGun"
SWEP.Primary.Recoil		= 0.085
SWEP.Primary.Damage = 49
SWEP.Primary.Delay = 0.275
SWEP.Primary.Cone = 0.018
SWEP.Primary.ClipSize = 7
SWEP.Primary.ClipMax = 35
SWEP.Primary.DefaultClip = 7
SWEP.Primary.Automatic = false
SWEP.HeadshotMultiplier = 2.7
SWEP.CrouchBonus 				 	= 0.55
SWEP.MovePenalty			 	 	= 1.5
SWEP.JumpPenalty			 	 	= 0.5
SWEP.MaxCone 					 	= 0.12
SWEP.TracerFrequency				= 1

SWEP.AimPatternX 		= function(t)
		return 0
	end
SWEP.AimPatternY 		= function(t)
		return 10 * t
	end
SWEP.BloomRecoverRate 	= 0.005
SWEP.AimRecoverRate		= 0.85
SWEP.AimKick			= 5
SWEP.Primary.ShoveY         = 0.4
SWEP.Primary.ShoveX         = 1.0

SWEP.AutoSpawnable      = true
SWEP.AmmoEnt = "item_ammo_revolver_ttt"
SWEP.Primary.Sound			= Sound( "Weapon_deagle.shot" )
SWEP.Primary.SoundEmpty			= Sound( "Weapon_Shotgun.Empty" )

SWEP.UseHands			= true
SWEP.ViewModelFlip		= false
SWEP.ViewModelFOV		= 54
SWEP.ViewModel			= "models/weapons/cstrike/c_pist_deagle.mdl"
SWEP.WorldModel			= "models/weapons/w_pist_deagle.mdl"

SWEP.IronSightsPos = Vector(-6.361, -3.701, 2.15)
SWEP.IronSightsAng = Vector(0, 0, 0)