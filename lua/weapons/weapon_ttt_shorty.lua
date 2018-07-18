if CLIENT then
	SWEP.PrintName = "Shorty"
	SWEP.Author = "TFlippy"
	
	SWEP.Slot = 1
	SWEP.Icon = "tflippy/vgui/ttt/icon_loco12g"
	
	SWEP.ViewModelFOV  = 75
	SWEP.ViewModelFlip = true
end

SWEP.Base = "weapon_ttt_brekiy_base"

SWEP.Kind = WEAPON_PISTOL
SWEP.LimitedStock = false
SWEP.AllowDrop = true
SWEP.AutoSpawnable = true
SWEP.IsSilent = false
SWEP.NoSights  = false
SWEP.Primary.Automatic = false

SWEP.Primary.Damage	= 4
SWEP.HeadshotMultiplier = 1.5
SWEP.Primary.NumShots = 20
SWEP.Primary.Cone = 0.04
SWEP.Primary.Delay = 0.35
SWEP.Primary.Recoil	= 0.035

SWEP.AimPatternX 		= function(t)
		return 0
	end
SWEP.AimPatternY 		= function(t)
		return 0.5 * t
	end
SWEP.BloomRecoverRate 	= 0.00151
SWEP.AimRecoverRate		= 0.35
SWEP.AimKick			= 5
SWEP.Primary.ShoveY         = 0.4
SWEP.Primary.ShoveX         = 2

SWEP.Primary.ClipSize = 2
SWEP.Primary.ClipMax = 20
SWEP.Primary.DefaultClip = 2
SWEP.Primary.Ammo = "Buckshot"
SWEP.AmmoEnt = "item_box_buckshot_ttt"
SWEP.CrouchBonus 				 	= 1
SWEP.MovePenalty			 	 	= 0
SWEP.JumpPenalty			 	 	= 0.1
SWEP.MaxCone 					 	= 0.45
SWEP.IronSightsConeMultiplier		= 0.8
SWEP.TracerFrequency				= 1

SWEP.IronSightsPos = Vector( 4.25, -2, 1.5 )
SWEP.IronSightsAng = Vector( 2.2, -0.1, 0 )

SWEP.HoldType = "smg"
SWEP.UseHands	= true
SWEP.ViewModel  = "models/weapons/v_shot_loco12g.mdl"
SWEP.WorldModel = "models/weapons/w_shot_loco12g.mdl"
SWEP.Primary.Sound = "TFlippy_Locomotive12G.Shoot"

function SWEP:SetupDataTables()
	self:SetupDataTablesBase()
   self:DTVar("Bool", 0, "reloading")

   return self.BaseClass.SetupDataTables(self)
end

function SWEP:Reload()
   if self.dt.reloading then return end
   if not IsFirstTimePredicted() then return end
   if self:Clip1() < self.Primary.ClipSize and self.Owner:GetAmmoCount( self.Primary.Ammo ) > 0 then
      if self:StartReload() then
         return
      end
   end
end

function SWEP:StartReload()
   if self.dt.reloading then
      return false
   end
   
   self:SetIronsights( false )
   if not IsFirstTimePredicted() then return false end
   self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
   
   local ply = self.Owner
   
   if not ply or ply:GetAmmoCount(self.Primary.Ammo) <= 0 then 
      return false
   end

   local wep = self
   
   if wep:Clip1() >= self.Primary.ClipSize then 
      return false 
   end

   wep:SendWeaponAnim(ACT_SHOTGUN_RELOAD_START)
   self.reloadtimer =  CurTime() + wep:SequenceDuration()
   self.dt.reloading = true

   return true
end

function SWEP:PerformReload()
   local ply = self.Owner
   self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )

   if not ply or ply:GetAmmoCount(self.Primary.Ammo) <= 0 then return end

   if self:Clip1() >= self.Primary.ClipSize then return end

   self.Owner:RemoveAmmo( 1, self.Primary.Ammo, false )
   self:SetClip1( self:Clip1() + 1 )

   self:SendWeaponAnim(ACT_VM_RELOAD)

   self.reloadtimer = CurTime() + self:SequenceDuration()
end

function SWEP:FinishReload()
   self.dt.reloading = false
   self:SendWeaponAnim(ACT_SHOTGUN_RELOAD_FINISH)
   
   self.reloadtimer = CurTime() + self:SequenceDuration()
end

function SWEP:CanPrimaryAttack()
   if self:Clip1() <= 0 then
      self:EmitSound( "Weapon_Shotgun.Empty" )
      self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
      return false
   end
   return true
end

function SWEP:Think()
	self:ThinkBase()
   if self.dt.reloading and IsFirstTimePredicted() then
      if self.Owner:KeyDown(IN_ATTACK) then
         self:FinishReload()
         return
      end
      if self.reloadtimer <= CurTime() then
         if self.Owner:GetAmmoCount(self.Primary.Ammo) <= 0 then
            self:FinishReload()
         elseif self:Clip1() < self.Primary.ClipSize then
            self:PerformReload()
         else
            self:FinishReload()
         end
         return            
      end
   end
end

function SWEP:Deploy()
   self.dt.reloading = false
   self.reloadtimer = 0
   return self.BaseClass.Deploy(self)
end

function SWEP:SecondaryAttack()
   if self.NoSights or (not self.IronSightsPos) or self.dt.reloading then return end
   self:SetIronsights(not self:GetIronsights())
   self:SetNextSecondaryFire(CurTime() + 0.3)
end