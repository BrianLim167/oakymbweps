AddCSLuaFile()

SWEP.HoldType			= "ar2"

if CLIENT then
   SWEP.PrintName			= "M4A1"
   SWEP.Slot				= 2

   SWEP.Icon = "vgui/ttt/icon_m16"
end

SWEP.Base		= "weapon_ttt_brekiy_base"
SWEP.Spawnable = true

SWEP.Kind = WEAPON_HEAVY
SWEP.WeaponID = AMMO_M16

SWEP.Primary.Delay		= 0.1
SWEP.Primary.Recoil		= 0.004
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "SMG1"
SWEP.Primary.Damage = 17
SWEP.Primary.Cone = 0.011
SWEP.Primary.ClipSize = 20
SWEP.Primary.ClipMax = 60
SWEP.Primary.DefaultClip = 20
SWEP.AutoSpawnable      = true
SWEP.AmmoEnt = "item_ammo_smg1_ttt"
SWEP.HeadshotMultiplier = 2.5
SWEP.CrouchBonus 				 	= 0.7
SWEP.MovePenalty			 	 	= 0.25
SWEP.JumpPenalty			 	 	= 0.2
SWEP.MaxCone 					 	= 0.1

SWEP.AimPatternX = function(t)
	return 2*t - 0.4*math.pow(t,4) + 20*math.pow(2,-math.pow(1.9*(t-2.9),2)) --+ 0.15*t*math.sin(14*t)
end
SWEP.AimPatternY = function(t)
	return 2*t - 0.02*math.pow(t,3) + 18 / (1 + math.pow(2, -t + 0.8))
end
SWEP.BloomRecoverRate 	= 0.00058
SWEP.AimRecoverRate		= 0.6
SWEP.AimKick			= 0.01
SWEP.Primary.ShoveY         = 0.3
SWEP.Primary.ShoveX         = 0.4

SWEP.UseHands			= true
SWEP.ViewModelFlip		= false
SWEP.ViewModelFOV		= 64
SWEP.ViewModel			= "models/weapons/cstrike/c_rif_m4a1.mdl"
SWEP.WorldModel			= "models/weapons/w_rif_m4a1.mdl"

SWEP.Primary.Sound = Sound("Weapon_m4.shot")

SWEP.IronSightsPos = Vector(-7.58, -9.2, 0.55)
SWEP.IronSightsAng = Vector(2.599, -1.3, -3.6)


function SWEP:SetZoom(state)
   if CLIENT then return end
   if not (IsValid(self.Owner) and self.Owner:IsPlayer()) then return end
   if state then
      self.Owner:SetFOV(59, 0.2)
   else
      self.Owner:SetFOV(0, 0.2)
   end
end

function SWEP:SecondaryAttack()
   if not self.IronSightsPos then return end
   if self:GetNextSecondaryFire() > CurTime() then return end

   local bIronsights = not self:GetIronsights()

   self:SetIronsights( bIronsights )

   if SERVER then
      self:SetZoom( bIronsights )
   end

   self:SetNextSecondaryFire( CurTime() + 0.3 )
end

function SWEP:PreDrop()
   self:SetZoom(false)
   self:SetIronsights(false)
   return self.BaseClass.PreDrop(self)
end