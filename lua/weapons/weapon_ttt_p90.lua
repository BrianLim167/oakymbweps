AddCSLuaFile()

if CLIENT then
   SWEP.PrintName = "P90"
   SWEP.Slot = 2
   SWEP.Icon = "vgui/ttt/icon_p90"
   SWEP.IconLetter = "m"
end

SWEP.Base = "weapon_ttt_brekiy_base"
SWEP.HoldType = "smg"

SWEP.Primary.Ammo = "Pistol"
SWEP.Primary.Delay = 0.075
SWEP.Primary.Recoil = 0.015
SWEP.Primary.Cone = 0.035
SWEP.Primary.Damage = 8
SWEP.Primary.HollowRating = 7
SWEP.Primary.Automatic = true
SWEP.Primary.ClipSize = 60
SWEP.Primary.ClipMax = 100
SWEP.Primary.DefaultClip = 60
SWEP.Primary.Sound = Sound( "Weapon_p90.shot" )
SWEP.Secondary.Sound = Sound( "Default.Zoom" )
SWEP.HeadshotMultiplier = 2
SWEP.CrouchBonus 				 	= 0.7
SWEP.MovePenalty			 	 	= 0.03
SWEP.JumpPenalty			 	 	= 2
SWEP.MaxCone 					 	= 0.06

SWEP.AimPatternX 		= function(t)
		return 0
	end
SWEP.AimPatternY 		= function(t)
		return 50 * t / (t + 25)
	end
SWEP.BloomRecoverRate 	= 0.0045
SWEP.AimRecoverRate		= 0.25
SWEP.AimKick			= 0.05
SWEP.Primary.ShoveY         = 0.2
SWEP.Primary.ShoveX         = 0.3

SWEP.UseHands = true
SWEP.ViewModelFlip = false
SWEP.ViewModelFOV = 55
SWEP.ViewModel = Model( "models/weapons/cstrike/c_smg_p90.mdl" )
SWEP.WorldModel = Model( "models/weapons/w_smg_p90.mdl" )

SWEP.IronSightsPos = Vector( -5, 1, 0.5 )
SWEP.IronSightsAng = Vector( 2.6, 1.37, 0 )

SWEP.Kind = WEAPON_HEAVY
SWEP.AutoSpawnable = true
SWEP.AmmoEnt = "item_ammo_pistol_ttt"
SWEP.InLoadoutFor = { nil }
SWEP.AllowDrop = true
SWEP.IsSilent = false
SWEP.NoSights = false

function SWEP:SetZoom( state )
   if CLIENT then
      return
   elseif IsValid( self.Owner ) and self.Owner:IsPlayer() then
      if state then
         self.Owner:SetFOV( 55, 0.2 )
      else
         self.Owner:SetFOV( 0, 0.2 )
      end
   end
end

function SWEP:PrimaryAttack( worldsnd )
   self.BaseClass.PrimaryAttack( self, worldsnd )
   self:SetNextSecondaryFire( CurTime() + 0.1 )
end

-- Add some zoom to ironsights for this gun
function SWEP:SecondaryAttack()
   if not self.IronSightsPos then return end
   if self:GetNextSecondaryFire() > CurTime() then return end

   local bIronsights = not self:GetIronsights()

   self:SetIronsights( bIronsights )

   if SERVER then
      self:SetZoom( bIronsights )
   else
      self:EmitSound( self.Secondary.Sound )
   end

   self:SetNextSecondaryFire( CurTime() + 0.3 )
end

function SWEP:PreDrop()
   self:SetZoom( false )
   self:SetIronsights( false )
   return self.BaseClass.PreDrop( self )
end