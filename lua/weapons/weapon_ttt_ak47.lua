AddCSLuaFile()

if CLIENT then
   SWEP.PrintName = "AK-47"
   SWEP.Slot = 2
   SWEP.Icon = "vgui/ttt/icon_ak47"
   SWEP.IconLetter = "b"
end

SWEP.Base = "weapon_ttt_brekiy_base"
SWEP.HoldType = "ar2"

SWEP.AutoSpawnable = true
SWEP.AmmoEnt = "item_ammo_smg1_ttt"
SWEP.AllowDrop = true
SWEP.IsSilent = false
SWEP.NoSights = false
SWEP.Primary.Ammo 				= "SMG1"
SWEP.Primary.Delay 				= 0.125
SWEP.Primary.Recoil 			= 0.005
SWEP.Primary.Cone 				= 0.01
SWEP.Primary.Damage 			= 19
SWEP.Primary.Automatic 			= true
SWEP.Primary.ClipSize 			= 30
SWEP.Primary.ClipMax 			= 60
SWEP.Primary.DefaultClip 		= 30
SWEP.Primary.Sound 				= Sound( "Weapon_ak47.shot" )
SWEP.Primary.SoundEmpty			= Sound( "Weapon_AR2.Empty" )
SWEP.HeadshotMultiplier 		= 2.5
SWEP.CrouchBonus 				= 0.7
SWEP.MovePenalty			 	= 1.75
SWEP.JumpPenalty			 	= 0.3
SWEP.MaxCone 					= 0.095
SWEP.TracerFrequency				= 3

SWEP.AimPatternX		= function(t)
	return 3*t - 2.2*math.pow(t,1.5) + 4.5*math.pow(2,-math.pow(5*(t-2.525),2)) - 3.7*math.pow(2,-math.pow(24*(t-2.575),2)) + 1.6*math.pow(2,-math.pow(100*(t-2.63),2))-- + 0.1*t*math.sin(16*t)
end
SWEP.AimPatternY		= function(t)
	return 4.75*t + 0.05*math.pow(t,2) + 1.5 / (1 + math.pow(2, -t*10 + 10))
end
SWEP.BloomRecoverRate 	= 0.00056
SWEP.AimRecoverRate		= 0.55
SWEP.AimKick 			= 0.045
SWEP.Primary.ShoveY         = 0.25
SWEP.Primary.ShoveX         = 0.5

SWEP.UseHands = true
SWEP.ViewModelFlip = false
SWEP.ViewModelFOV = 50
SWEP.ViewModel = Model( "models/weapons/cstrike/c_rif_ak47.mdl" )
SWEP.WorldModel = Model( "models/weapons/w_rif_ak47.mdl" )

SWEP.IronSightsPos = Vector( -6.45, 10, 1.4 )
SWEP.IronSightsAng = Vector( 2.737, 0.158, 0 )

SWEP.Kind = WEAPON_HEAVY

function SWEP:SetZoom(state)
   if CLIENT then return end
   if not (IsValid(self.Owner) and self.Owner:IsPlayer()) then return end
   if state then
      self.Owner:SetFOV(50, 0.2)
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