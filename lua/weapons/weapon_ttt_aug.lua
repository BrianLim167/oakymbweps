AddCSLuaFile()

if CLIENT then
   SWEP.PrintName = "AUG"
   SWEP.Slot = 2
   SWEP.Icon = "vgui/ttt/icon_aug"
   SWEP.IconLetter = "e"
end

SWEP.Base = "weapon_ttt_brekiy_base"
SWEP.HoldType = "ar2"

SWEP.Primary.Ammo 				= "SMG1"
SWEP.Primary.Delay 				= 0.17
SWEP.Primary.Recoil 				= 0.0025
SWEP.Primary.Cone 				= 0.011
SWEP.Primary.Damage 				= 16
SWEP.Primary.Automatic 			= true
SWEP.Primary.ClipSize 			= 30
SWEP.Primary.ClipMax 			= 60
SWEP.Primary.DefaultClip 		= 30
SWEP.Primary.Sound 				= Sound( "Weapon_aug.shot" )
SWEP.Primary.SoundEmpty			= Sound( "Weapon_IRifle.Empty" )
SWEP.Secondary.Sound 			= Sound( "Default.Zoom" )
SWEP.HeadshotMultiplier 		= 2.7
SWEP.IronSightsConeMultiplier		= 0.5
SWEP.CrouchBonus 				 	= 0.7
SWEP.MovePenalty			 	 	= 1
SWEP.JumpPenalty			 	 	= 0.1
SWEP.MaxCone 					 	= 0.07
SWEP.IronSightsConeMultiplier		= 0.1
SWEP.TracerFrequency				= 1

SWEP.AimPatternX 		= function(t)
		return 0.1 * t * math.sin(0.8 * t)
	end
SWEP.AimPatternY 		= function(t)
		return 25 * t / (t + 15)
	end
SWEP.BloomRecoverRate 	= 0.005
SWEP.AimRecoverRate		= 0.35
SWEP.AimKick			= 0.15
SWEP.Primary.ShoveY         = 0.2
SWEP.Primary.ShoveX         = 0.3

SWEP.UseHands = true
SWEP.ViewModelFlip = false
SWEP.ViewModelFOV = 55
SWEP.ViewModel = Model( "models/weapons/cstrike/c_rif_aug.mdl" )
SWEP.WorldModel = Model( "models/weapons/w_rif_aug.mdl" )

SWEP.IronSightsPos = Vector( 5, -15, -2 )
SWEP.IronSightsAng = Vector( 2.6, 1.37, 3.5 )

SWEP.Kind = WEAPON_HEAVY
SWEP.AutoSpawnable = true
SWEP.AmmoEnt = "item_ammo_smg1_ttt"
SWEP.AllowDrop = true
SWEP.IsSilent = false
SWEP.NoSights = false

function SWEP:SetZoom( state )
   if CLIENT then
      return
   elseif IsValid( self.Owner ) and self.Owner:IsPlayer() then
      if state then
         self.Owner:SetFOV(30, 0.2)
      else
         self.Owner:SetFOV(0, 0.2)
      end
   end
end

function SWEP:PrimaryAttack( worldsnd )
   self.BaseClass.PrimaryAttack( self, worldsnd )
   self:SetNextSecondaryFire( CurTime() + 0.1 )
end

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

if CLIENT then
   local scope = surface.GetTextureID( "sprites/scope" )
   function SWEP:DrawHUD()
      if self:GetIronsights() then
         surface.SetDrawColor( 0, 0, 0, 255 )

         local scrW = ScrW()
         local scrH = ScrH()

         local x = scrW / 2.0
         local y = scrH / 2.0
         local scope_size = scrH

         -- Crosshair
         local gap = 80
         local length = scope_size
         surface.DrawLine( x - length, y, x - gap, y )
         surface.DrawLine( x + length, y, x + gap, y )
         surface.DrawLine( x, y - length, x, y - gap )
         surface.DrawLine( x, y + length, x, y + gap )

         gap = 0
         length = 50
         surface.DrawLine( x - length, y, x - gap, y )
         surface.DrawLine( x + length, y, x + gap, y )
         surface.DrawLine( x, y - length, x, y - gap )
         surface.DrawLine( x, y + length, x, y + gap )

         -- Cover edges
         local sh = scope_size / 2
         local w = ( x - sh ) + 2
         surface.DrawRect( 0, 0, w, scope_size )
         surface.DrawRect( x + sh - 2, 0, w, scope_size )

         -- Cover gaps on top and bottom of screen
         surface.DrawLine( 0, 0, scrW, 0 )
         surface.DrawLine( 0, scrH - 1, scrW, scrH - 1 )

         surface.SetDrawColor( 255, 0, 0, 255 )
         surface.DrawLine( x, y, x + 1, y + 1 )

         -- Scope
         surface.SetTexture( scope )
         surface.SetDrawColor( 255, 255, 255, 255 )

         surface.DrawTexturedRectRotated( x, y, scope_size, scope_size, 0 )
      else
         return self.BaseClass.DrawHUD( self )
      end
   end

   function SWEP:AdjustMouseSensitivity()
      return ( self:GetIronsights() and 0.35 ) or nil
   end
end
