AddCSLuaFile()

if CLIENT then
   SWEP.PrintName = "Silenced AWP"
   SWEP.Slot = 6
   SWEP.Icon = "vgui/ttt/icon_awp"
   SWEP.IconLetter = "r"
end

SWEP.Base = "weapon_ttt_brekiy_base"
SWEP.HoldType = "ar2"

SWEP.Primary.Ammo = "none"
SWEP.Primary.Delay = 1
SWEP.Primary.Recoil = 0
SWEP.Primary.Cone = 0.02
SWEP.Primary.Damage = 300
SWEP.Primary.Automatic = false
SWEP.Primary.ClipSize = 1
SWEP.Primary.ClipMax = 1
SWEP.Primary.DefaultClip = 1
SWEP.Primary.Sound = Sound( "Weapon_silawp.shot" )
SWEP.Secondary.Sound = Sound( "Default.Zoom" )
SWEP.HeadshotMultiplier = 2.5
SWEP.CrouchBonus 				 	= 0.7
SWEP.MovePenalty			 	 	= 1
SWEP.JumpPenalty			 	 	= 0.1
SWEP.MaxCone 					 	= 0.1
SWEP.IronSightsConeMultiplier		= 0.001
SWEP.Tracer							= "None"

SWEP.UseHands = true
SWEP.ViewModelFlip = false
SWEP.ViewModelFOV = 61
SWEP.ViewModel = Model( "models/weapons/cstrike/c_snip_awp.mdl" )
SWEP.WorldModel = Model( "models/weapons/w_snip_awp.mdl" )

SWEP.IronSightsPos = Vector( 5, -15, -2 )
SWEP.IronSightsAng = Vector( 2.6, 1.37, 3.5 )

SWEP.Kind = WEAPON_EQUIP1
SWEP.AutoSpawnable = false
SWEP.AmmoEnt = "none"
SWEP.CanBuy = { ROLE_TRAITOR }
SWEP.InLoadoutFor = { nil }
SWEP.LimitedStock = true
SWEP.AllowDrop = true
SWEP.IsSilent = true
SWEP.NoSights = false

function SWEP:SetZoom( state )
   if CLIENT then
      return
   elseif IsValid( self.Owner ) and self.Owner:IsPlayer() then
      if state then
         self.Owner:SetFOV( 20, 0.2 )
      else
         self.Owner:SetFOV( 0, 0.2 )
      end
   end
end

function SWEP:PrimaryAttack( worldsnd )
   self.BaseClass.PrimaryAttack( self, worldsnd )
   self:SetNextSecondaryFire( CurTime() + 0.1 )
	timer.Simple(0.1, function()
		if self:GetIronsights() then self:SecondaryAttack() end -- unscope with each shot
	end )
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

	if CLIENT then
	   local scope = surface.GetTextureID( "sprites/scope" )
	   function self:DrawHUD()
		  if self:GetIronsights() then
			 surface.SetDrawColor( 0, 0, 0, 255 )

			 local scrW = ScrW()
			 local scrH = ScrH()

			 local x = scrW / 2.0
			 local y = scrH / 2.0
			 local scope_size = scrH

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

	   function self:AdjustMouseSensitivity()
		  return ( self:GetIronsights() and 0.2 ) or nil
	   end
	end
end

function SWEP:PreDrop()
   self:SetZoom( false )
   self:SetIronsights( false )
   return self.BaseClass.PreDrop( self )
end

-- Equipment menu information is only needed on the client
if CLIENT then
   SWEP.EquipMenuData = {
      type = "Weapon",
      desc = "Silenced single shot AWP. \nVictims will not scream when killed."
   }
end