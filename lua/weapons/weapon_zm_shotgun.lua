AddCSLuaFile()

SWEP.HoldType	  = "shotgun"

if CLIENT then
   SWEP.PrintName = "M1014"

   SWEP.Slot = 2
   SWEP.Icon = "vgui/ttt/icon_shotgun"
end


SWEP.Base		= "weapon_ttt_brekiy_base"
SWEP.Spawnable = true

SWEP.Kind = WEAPON_HEAVY
SWEP.WeaponID = AMMO_SHOTGUN

if ROLE_SURVIVALIST then 
	SWEP.CanBuy                = {ROLE_SURVIVALIST}
end


SWEP.Primary.Ammo = "Buckshot"
SWEP.Primary.Damage = 4
SWEP.Primary.Cone = 0.017
SWEP.Primary.Delay = 0.55
SWEP.Primary.ClipSize = 6
SWEP.Primary.ClipMax = 24
SWEP.Primary.DefaultClip = 6
SWEP.Primary.Automatic = false
SWEP.Primary.NumShots = 12
SWEP.AutoSpawnable      = true
SWEP.AmmoEnt = "item_box_buckshot_ttt"
SWEP.HeadshotMultiplier = 2
SWEP.CrouchBonus 				 	= 1
SWEP.MovePenalty			 	 	= 0.25
SWEP.JumpPenalty			 	 	= 0.5
SWEP.MaxCone 					 	= 0.2

SWEP.UseHands			= true
SWEP.ViewModelFlip		= false
SWEP.ViewModelFOV		= 64
SWEP.ViewModel			= "models/weapons/cstrike/c_shot_xm1014.mdl"
SWEP.WorldModel			= "models/weapons/w_shot_xm1014.mdl"
SWEP.Primary.Sound		= Sound("Weapon_xm1014.shot")
SWEP.Primary.Recoil		= 0.08

SWEP.AimPatternX 		= function(t)
		return 0
	end
SWEP.AimPatternY 		= function(t)
		return 10*t
	end
SWEP.BloomRecoverRate 	= 0.008
SWEP.AimRecoverRate		= 0.75
SWEP.AimKick			= 4.5
SWEP.Primary.ShoveY         = 1.1
SWEP.Primary.ShoveX         = 1.7

SWEP.IronSightsPos = Vector(-6.881, -9.214, 2.66)
SWEP.IronSightsAng = Vector(-0.101, -0.7, -0.201)

SWEP.reloadtimer = 0

function SWEP:SetupDataTables()
	self:SetupDataTablesBase()
   self:DTVar("Bool", 0, "reloading")

   return self.BaseClass.SetupDataTables(self)
end

function SWEP:Reload()
	self.AimPunch = 0
	self:AimPunchEvent()

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
