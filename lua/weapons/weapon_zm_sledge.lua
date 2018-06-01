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

SWEP.Primary.Damage = 14
SWEP.Primary.Delay = 0.0775
SWEP.Primary.Cone = 0.08
SWEP.Primary.ClipSize = 100
SWEP.Primary.ClipMax = 100
SWEP.Primary.DefaultClip	= 100
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "AirboatGun"
SWEP.AutoSpawnable      = true
SWEP.Primary.Recoil			= 0.0
SWEP.Primary.Sound			= Sound("Weapon_m249.shot")
SWEP.CrouchBonus 				 	= 0.7
SWEP.MovePenalty			 	 	= 9999
SWEP.JumpPenalty			 	 	= 9999
SWEP.MaxCone 					 	= 0.25

SWEP.AimPatternX 		= function(t)
		return 0.01 * t * math.sin(0.8 * t)
	end
SWEP.AimPatternY 		= function(t)
		return 20 * t / (t + 5)
	end
SWEP.BloomRecoverRate 	= 0.045
SWEP.AimRecoverRate		= 1.85
SWEP.AimKick			= 0.05

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

function SWEP:Reload()
    if (self:Clip1() == self.Primary.ClipSize or
        self.Owner:GetAmmoCount(self.Primary.Ammo) <= 0) then
       return
    end
    self:DefaultReload(ACT_VM_RELOAD)
    self:SetIronsights(false)
    self:SetZoom(false)
end

function SWEP:Holster()
   self:SetIronsights(false)
   self:SetZoom(false)
   return true
end