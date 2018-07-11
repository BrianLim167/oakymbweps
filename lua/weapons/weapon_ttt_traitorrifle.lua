if SERVER then
   --AddCSLuaFile( "shared.lua" )
   resource.AddFile( "materials/vgui/ttt/icon_scout.vmt" )
end

if CLIENT then
   SWEP.PrintName = "Silenced Scout"
   SWEP.Slot = 7
   SWEP.Icon = "vgui/ttt/icon_scout"
   SWEP.EquipMenuData = {
      type = "item_weapon",
      desc = "A silenced scout. It looks like a regular scout to innocents."
   };
end

SWEP.Base = "weapon_ttt_brekiy_base"
SWEP.HoldType = "ar2"

SWEP.ShortLightBrightness = -10
SWEP.LongLightBrightness = -50

SWEP.Primary.Ammo = "357"
SWEP.Primary.Delay = 1.5
SWEP.Primary.Recoil = 0
SWEP.Primary.Cone = 0.015
SWEP.Primary.Damage = 55
SWEP.Primary.Automatic = false
SWEP.Primary.ClipSize = 10
SWEP.Primary.DefaultClip = 10
SWEP.Primary.Sound = Sound( "Weapon_m4s.shot")
SWEP.Secondary.Sound = Sound( "Default.Zoom" )
SWEP.HeadshotMultiplier = 4
SWEP.Primary.NumShots	= 1
SWEP.CrouchBonus 				 	= 0.7
SWEP.MovePenalty			 	 	= 0.05
SWEP.JumpPenalty			 	 	= 0.3
SWEP.MaxCone 					 	= 0.065
SWEP.IronSightsConeMultiplier		= 0.001

SWEP.AimPatternX 		= function(t)
		return 0
	end
SWEP.AimPatternY 		= function(t)
		return 0
	end
SWEP.BloomRecoverRate 	= 0.0075
SWEP.AimRecoverRate		= 0.25
SWEP.AimKick			= 2.75
SWEP.Primary.ShoveY         = 0.5
SWEP.Primary.ShoveX         = 1.0

--- Model settings
SWEP.UseHands = true
SWEP.ViewModelFlip = false
SWEP.ViewModelFOV = 70
SWEP.ViewModel = "models/weapons/cstrike/c_snip_scout.mdl"
SWEP.WorldModel = "models/weapons/w_snip_scout.mdl"

SWEP.IronSightsPos = Vector( 5, -15, -2 )
SWEP.IronSightsAng = Vector( 2.6, 1.37, 3.5 )

SWEP.Kind = WEAPON_EQUIP1

SWEP.AutoSpawnable = false
SWEP.CanBuy = { ROLE_TRAITOR }

if ROLE_SURVIVALIST then 
	SWEP.CanBuy                = {ROLE_TRAITOR, ROLE_SURVIVALIST}
end

SWEP.InLoadoutFor = { nil }
SWEP.LimitedStock = true
SWEP.AllowDrop = true

SWEP.IsSilent = true

SWEP.NoSights = false

if CLIENT then
   SWEP.EquipMenuData = {
      type = "item_weapon",
      desc = "Silenced scout."
   };
end

function SWEP:SetZoom(state)
    if CLIENT then 
       return
    elseif IsValid(self.Owner) and self.Owner:IsPlayer() then
       if state then
          self.Owner:SetFOV(20, 0.3)
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
    
    bIronsights = not self:GetIronsights()
    
    self:SetIronsights( bIronsights )
    
    if SERVER then
        self:SetZoom(bIronsights)
     else
        self:EmitSound(self.Secondary.Sound)
    end
    
    self:SetNextSecondaryFire( CurTime() + 0.3)
	
	if CLIENT then
	   local scope = surface.GetTextureID("sprites/scope")
	   function self:DrawHUD()
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

	   function self:AdjustMouseSensitivity()
		  return (self:GetIronsights() and 0.2) or nil
	   end
	end
end

function SWEP:PreDrop()
    self:SetZoom( false )
    self:SetIronsights( false )
    return self.BaseClass.PreDrop(self)
end
