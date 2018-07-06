AddCSLuaFile()

if CLIENT then
   SWEP.PrintName = "TMP"
   SWEP.Slot = 6
   SWEP.Icon = "vgui/ttt/icon_tmp"
   SWEP.IconLetter = "d"
end

SWEP.Base = "weapon_ttt_brekiy_base"
SWEP.HoldType = "smg"

SWEP.Primary.Ammo = "smg1"
SWEP.Primary.Delay = 0.07
SWEP.Primary.Recoil = 0.0025
SWEP.Primary.Cone = 0.019
SWEP.Primary.Damage = 12
SWEP.Primary.Automatic = true
SWEP.Primary.ClipSize = 30
SWEP.Primary.ClipMax = 60
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Sound = Sound("Weapon_tmp.shot")
SWEP.CrouchBonus 				 	= 0.7
SWEP.MovePenalty			 	 	= 0.025
SWEP.JumpPenalty			 	 	= 0.4
SWEP.MaxCone 					 	= 0.05

SWEP.AimPatternX 		= function(t)
		return 0.0
	end
SWEP.AimPatternY 		= function(t)
		return 1.25 * t
	end
SWEP.BloomRecoverRate 	= 0.00054
SWEP.AimRecoverRate		= 0.2
SWEP.AimKick			= 0.075
SWEP.Primary.ShoveY         = 0.1
SWEP.Primary.ShoveX         = 0.3

-- Model properties
SWEP.UseHands = true
SWEP.ViewModelFlip = false
SWEP.ViewModelFOV = 64
SWEP.ViewModel = Model( "models/weapons/cstrike/c_smg_tmp.mdl" )
SWEP.WorldModel = Model( "models/weapons/w_smg_tmp.mdl" )

SWEP.IronSightsPos = Vector ( -6.896, -2.822, 2.134 )
SWEP.IronSightsAng = Vector ( 2.253, 0.209, 0.07 )

SWEP.Kind = WEAPON_EQUIP1
SWEP.AutoSpawnable = false
SWEP.AmmoEnt = "item_ammo_smg1_ttt"
SWEP.CanBuy = { ROLE_TRAITOR }
SWEP.InLoadoutFor = { nil }
SWEP.LimitedStock = true
SWEP.AllowDrop = true
SWEP.IsSilent = true
SWEP.NoSights = false

function SWEP:SetZoom(state)
   if CLIENT then return end
   if not (IsValid(self.Owner) and self.Owner:IsPlayer()) then return end
   if state then
      self.Owner:SetFOV(60, 0.2)
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

function SWEP:Deploy()
   self:SendWeaponAnim( ACT_VM_DRAW_SILENCED )
   return true
end

-- Equipment menu information is only needed on the client
if CLIENT then
   -- Text shown in the equip menu
   SWEP.EquipMenuData = {
      type = "Weapon",
      desc = "Suppressed SMG.\n\nVictims will not scream when killed."
   }
end