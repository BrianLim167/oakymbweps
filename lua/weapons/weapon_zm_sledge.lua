AddCSLuaFile()

SWEP.HoldType			= "crossbow"

if CLIENT then
   SWEP.PrintName			= "M249"
   SWEP.Slot				= 2
   SWEP.Icon = "vgui/ttt/icon_m249"
   SWEP.ViewModelFlip		= false
end

SWEP.Base	= "weapon_ttt_brekiy_base"

SWEP.Spawnable = true

SWEP.Kind = WEAPON_HEAVY
SWEP.WeaponID = AMMO_M249

SWEP.Primary.Damage = 15
SWEP.Primary.Delay = 0.085
SWEP.Primary.Cone = 0.0095
SWEP.Primary.ClipSize = 100
SWEP.Primary.ClipMax = 10000
SWEP.Primary.DefaultClip	= 100
SWEP.StoredAmmo				= 100
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "AirboatGun"
SWEP.AutoSpawnable      = true
SWEP.Primary.Recoil			= 0.00755
SWEP.Primary.Sound			= Sound("Weapon_m249.shot")
SWEP.CrouchBonus 				 	= 0.85
SWEP.MovePenalty			 	 	= 1.2
SWEP.JumpPenalty			 	 	= 0.3
SWEP.MaxCone 					 	= 0.1

SWEP.AimPatternX 		= function(t)
		return 0.12 * t * math.sin(8 * t)
	end
SWEP.AimPatternY 		= function(t)
		return 40 * t / (t + 15)
	end
SWEP.BloomRecoverRate 	= 0.002
SWEP.AimRecoverRate		= 0.3
SWEP.AimKick			= 0.75
SWEP.Primary.ShoveY         = 0.4
SWEP.Primary.ShoveX         = 0.5

SWEP.UseHands			= true
SWEP.ViewModelFlip		= false
SWEP.ViewModelFOV		= 64
SWEP.ViewModel			= "models/weapons/cstrike/c_mach_m249para.mdl"
SWEP.WorldModel			= "models/weapons/w_mach_m249para.mdl"

SWEP.HeadshotMultiplier = 1.5

SWEP.IronSightsPos = Vector(-5.96, -5.119, 2.349)
SWEP.IronSightsAng = Vector(0, 0, 0)

function SWEP:SetZoom(state)
   if CLIENT then return end
   if not (IsValid(self.Owner) and self.Owner:IsPlayer()) then return end
   if state then
      self.Owner:SetFOV(55, 0.2)
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