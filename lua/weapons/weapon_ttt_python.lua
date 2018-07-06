AddCSLuaFile()

if CLIENT then
   SWEP.PrintName = "Colt Python"
   SWEP.Slot = 6
   SWEP.Icon = "vgui/ttt/icon_revolver"
   SWEP.IconLetter = "f"
end

SWEP.Base = "weapon_ttt_brekiy_base"
SWEP.HoldType = "revolver"

SWEP.Primary.Ammo = "AlyxGun"
SWEP.Primary.Delay = 0.3
SWEP.Primary.Recoil = 0.055
SWEP.Primary.Cone = 0.012
SWEP.Primary.Damage = 55
SWEP.Primary.Automatic = false
SWEP.Primary.ClipSize = 6
SWEP.Primary.ClipMax = 12
SWEP.Primary.DefaultClip = 6
SWEP.Primary.Sound = Sound("Weapon_DetRev.Single")
SWEP.HeadshotMultiplier = 2
SWEP.CrouchBonus 				 	= 0.55
SWEP.MovePenalty			 	 	= 1
SWEP.JumpPenalty			 	 	= 0.2
SWEP.MaxCone 					 	= 0.09

SWEP.AimPatternX 		= function(t)
		return 0
	end
SWEP.AimPatternY 		= function(t)
		return 7.5 * t
	end
SWEP.BloomRecoverRate 	= 0.0035
SWEP.AimRecoverRate		= 0.95
SWEP.AimKick			= 2.5
SWEP.Primary.ShoveY         = 0.1
SWEP.Primary.ShoveX         = 0.5

-- Model properties
SWEP.UseHands = true
SWEP.ViewModelFlip = false
SWEP.ViewModelFOV = 54
SWEP.ViewModel = Model("models/weapons/c_357.mdl")
SWEP.WorldModel = Model("models/weapons/w_357.mdl")

SWEP.IronSightsPos = Vector ( -4.64, -3.96, 0.68 )
SWEP.IronSightsAng = Vector ( 0.214, -0.1767, 0 )
SWEP.Kind = WEAPON_EQUIP1

SWEP.AutoSpawnable = false
SWEP.AmmoEnt = "item_ammo_revolver_ttt"
SWEP.CanBuy = { ROLE_DETECTIVE }
SWEP.InLoadoutFor = { nil }
SWEP.LimitedStock = false
SWEP.AllowDrop = true
SWEP.IsSilent = false
SWEP.NoSights = false

function SWEP:Precache()
   util.PrecacheSound( "weapons/det_revolver/revolver-fire.wav" )
end

-- Give the primary sound an alias
sound.Add ( {
   name = "Weapon_DetRev.Single",
   channel = CHAN_USER_BASE + 10,
   volume = 0.7,
   sound = "weapons/det_revolver/revolver-fire.wav"
} )

-- Equipment menu information is only needed on the client
if CLIENT then
   SWEP.EquipMenuData = {
      type = "Weapon",
      desc = "We sheriff now."
   }
end