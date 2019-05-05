AddCSLuaFile()

SWEP.HoldType = "smg"

if CLIENT then
   SWEP.PrintName = "UMP Prototype"
   SWEP.Slot      = 2

   SWEP.Icon = "vgui/ttt/icon_ump"

   SWEP.ViewModelFOV = 72

   SWEP.EquipMenuData = {
      type = "item_weapon",
      desc = "A special gun that fires shocking bullets. The target's aim will be thrown off."
   };
end

SWEP.Base = "weapon_ttt_brekiy_base"

SWEP.Kind = WEAPON_HEAVY
SWEP.WeaponID = AMMO_STUN
SWEP.CanBuy = {ROLE_DETECTIVE}
SWEP.LimitedStock = false

SWEP.Primary.Damage = 12
SWEP.Primary.Delay = 0.1
SWEP.Primary.Cone = 0.013
SWEP.Primary.ClipSize = 25
SWEP.Primary.ClipMax = 60
SWEP.Primary.DefaultClip	= 25
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "smg1"
SWEP.AutoSpawnable      = false
SWEP.AmmoEnt = "item_ammo_smg1_ttt"
SWEP.Primary.Recoil		= 0.01
SWEP.Primary.Sound		= Sound( "Weapon_ump45.shot" )
SWEP.CrouchBonus 				 	= 0.7
SWEP.MovePenalty			 	 	= 0.25
SWEP.JumpPenalty			 	 	= 0.3
SWEP.MaxCone 					 	= 0.06

SWEP.AimPatternX 		= function(t)
		return 0
	end
SWEP.AimPatternY 		= function(t)
		return 1.25 * t
	end
SWEP.BloomRecoverRate 	= 0.00151
SWEP.AimRecoverRate		= 0.15
SWEP.AimKick			= 0.8

SWEP.UseHands			= true
SWEP.ViewModelFlip		= false
SWEP.ViewModelFOV		= 54
SWEP.ViewModel			= "models/weapons/cstrike/c_smg_ump45.mdl"
SWEP.WorldModel			= "models/weapons/w_smg_ump45.mdl"

SWEP.HeadshotMultiplier = 2

SWEP.IronSightsPos = Vector(-8.735, -10, 4.039)
SWEP.IronSightsAng = Vector(-1.201, -0.201, -2)

function SWEP:Callback( att, tr, dmginfo )
	if SERVER or (CLIENT and IsFirstTimePredicted()) then
	   local ent = tr.Entity
	   if ent == self.Owner then return end
	   if (not tr.HitWorld) and IsValid(ent) then
		  local edata = EffectData()

		  edata:SetEntity(ent)
		  edata:SetMagnitude(3)
		  edata:SetScale(2)

		  util.Effect("TeslaHitBoxes", edata)

		  if SERVER and ent:IsPlayer() then
			 local eyeang = ent:EyeAngles()
			 local j = 10
			 eyeang.pitch = math.Clamp(eyeang.pitch + math.Rand(-j, j), -90, 90)
			 eyeang.yaw = math.Clamp(eyeang.yaw + math.Rand(-j, j), -90, 90)
			 ent:SetEyeAngles(eyeang)
		  end
	   end
	end
end