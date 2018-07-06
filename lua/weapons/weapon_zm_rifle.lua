AddCSLuaFile()

SWEP.HoldType           = "ar2"

if CLIENT then
   SWEP.PrintName          = "Scout"
   SWEP.Slot               = 2
   SWEP.Icon = "vgui/ttt/icon_scout"
end

SWEP.Base      = "weapon_ttt_brekiy_base"
SWEP.Spawnable = true

SWEP.Kind = WEAPON_HEAVY
SWEP.WeaponID = AMMO_RIFLE

SWEP.Primary.Delay     = 1.5
SWEP.Primary.Recoil    = 0
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "357"
SWEP.Primary.Damage = 55
SWEP.Primary.Cone = 0.025
SWEP.Primary.ClipSize = 10
SWEP.Primary.ClipMax = 20
SWEP.Primary.DefaultClip = 10
SWEP.IronSightsConeMultiplier		= 0.01
SWEP.CrouchBonus 				 	= 0.7
SWEP.MovePenalty			 	 	= 0.05
SWEP.JumpPenalty			 	 	= 0.3
SWEP.MaxCone 					 	= 0.065

SWEP.AimPatternX 		= function(t)
		return 0
	end
SWEP.AimPatternY 		= function(t)
		return 1 * t
	end
SWEP.BloomRecoverRate 	= 0.0075
SWEP.AimRecoverRate		= 0.25
SWEP.AimKick			= 3
SWEP.Primary.ShoveY         = 1
SWEP.Primary.ShoveX         = 1.15

SWEP.HeadshotMultiplier = 4

SWEP.AutoSpawnable      = true
SWEP.AmmoEnt = "item_ammo_357_ttt"

SWEP.UseHands			= true
SWEP.ViewModelFlip		= false
SWEP.ViewModelFOV		= 54
SWEP.ViewModel          = Model("models/weapons/cstrike/c_snip_scout.mdl")
SWEP.WorldModel         = Model("models/weapons/w_snip_scout.mdl")

SWEP.Primary.Sound = Sound("Weapon_scout.shot")

SWEP.Secondary.Sound = Sound("Default.Zoom")

SWEP.IronSightsPos      = Vector( 5, -15, -2 )
SWEP.IronSightsAng      = Vector( 2.6, 1.37, 3.5 )

function SWEP:SetZoom(state)
    if CLIENT then
       return
    elseif IsValid(self.Owner) and self.Owner:IsPlayer() then
       if state then
          self.Owner:SetFOV(15, 0.3)
       else
          self.Owner:SetFOV(0, 0.2)
       end
    end
end

function SWEP:PrimaryAttack()
	if self:CanPrimaryAttack() then
		self:PrimaryAttackBase()
		timer.Simple(0.1, function()
			if self:GetIronsights() then self:SecondaryAttack() end -- unscope with each shot
		end )
	end

	self:SetNextSecondaryFire( CurTime() + 0.099 )
	self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
end

-- Add some zoom to ironsights for this gun
function SWEP:SecondaryAttack()
    if not self.IronSightsPos then return end
    if self:GetNextSecondaryFire() > CurTime() then return end

    local bIronsights = not self:GetIronsights()

    self:SetIronsights( bIronsights )

    if SERVER then
        self:SetZoom(bIronsights)
     else
        self:EmitSound(self.Secondary.Sound)
    end

    self:SetNextSecondaryFire( CurTime() + 0.3)
end

function SWEP:PreDrop()
    self:SetZoom(false)
    self:SetIronsights(false)
    return self.BaseClass.PreDrop(self)
end

if CLIENT then
   local scope = surface.GetTextureID("sprites/scope")
   function SWEP:DrawHUD()
      if self:GetIronsights() then
         surface.SetDrawColor( 0, 0, 0, 255 )
         
         local x = ScrW() / 2.0
         local y = ScrH() / 2.0
         local scope_size = ScrH()

         -- crosshair
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


         -- cover edges
         local sh = scope_size / 2
         local w = (x - sh) + 2
         surface.DrawRect(0, 0, w, scope_size)
         surface.DrawRect(x + sh - 2, 0, w, scope_size)

         surface.SetDrawColor(255, 0, 0, 255)
         surface.DrawLine(x, y, x + 1, y + 1)

         -- scope
         surface.SetTexture(scope)
         surface.SetDrawColor(255, 255, 255, 255)

         surface.DrawTexturedRectRotated(x, y, scope_size, scope_size, 0)

      else
         return self.BaseClass.DrawHUD(self)
      end
   end

   function SWEP:AdjustMouseSensitivity()
      return (self:GetIronsights() and 0.2) or nil
   end
end