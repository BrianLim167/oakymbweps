AddCSLuaFile()

SWEP.HoldType = "pistol"

if CLIENT then

   SWEP.PrintName = "MAC10"
   SWEP.Slot = 2

   SWEP.Icon = "vgui/ttt/icon_mac"
end


SWEP.Base = "weapon_ttt_brekiy_base"

SWEP.Kind = WEAPON_HEAVY
SWEP.WeaponID = AMMO_MAC10

if ROLE_SURVIVALIST then 
	SWEP.CanBuy                = {ROLE_SURVIVALIST}
end

SWEP.Primary.Damage      = 14
SWEP.Primary.Delay       = 0.0615
SWEP.Primary.Cone        = 0.019
SWEP.Primary.ClipSize    = 30
SWEP.Primary.ClipMax     = 60
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Automatic   = true
SWEP.Primary.Ammo        = "smg1"
SWEP.Primary.Recoil      = 0.0225
SWEP.Primary.Sound       = Sound( "Weapon_mac10.shot" )
SWEP.HeadshotMultiplier = 2
SWEP.CrouchBonus 				 	= 0.9
SWEP.MovePenalty			 	 	= 0.025
SWEP.JumpPenalty			 	 	= 1.2
SWEP.MaxCone 					 	= 0.07

SWEP.AimPatternX 		= function(t)
		return 0.0
	end
SWEP.AimPatternY 		= function(t)
		return 1.4 * t
	end
SWEP.BloomRecoverRate 	= 0.00425
SWEP.AimRecoverRate		= 0.225
SWEP.AimKick			= 0.225
SWEP.Primary.ShoveY         = 0.2
SWEP.Primary.ShoveX         = 0.325

SWEP.AutoSpawnable = true

SWEP.AmmoEnt = "item_ammo_smg1_ttt"

SWEP.UseHands			= true
SWEP.ViewModelFlip		= false
SWEP.ViewModelFOV		= 54
SWEP.ViewModel  = "models/weapons/cstrike/c_smg_mac10.mdl"
SWEP.WorldModel = "models/weapons/w_smg_mac10.mdl"

SWEP.IronSightsPos = Vector(-8.921, -9.528, 2.9)
SWEP.IronSightsAng = Vector(0.699, -5.301, -7)

SWEP.DeploySpeed = 3

function SWEP:SetZoom(state)
   if CLIENT then return end
   if not (IsValid(self.Owner) and self.Owner:IsPlayer()) then return end
   if state then
      self.Owner:SetFOV(50, 0.2)
   else
      self.Owner:SetFOV(0, 0.2)
   end
end

-- Add some zoom to ironsights for this gun
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