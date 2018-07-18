if SERVER then
   AddCSLuaFile( "weapon_ttt_bulldozer.lua" )
   resource.AddFile("materials/vgui/ttt/icon_bulldozer.vmt")
end

SWEP.HoldType			= "shotgun"

if CLIENT then
   SWEP.PrintName = "Bulldozer"

	SWEP.Slot = 2
     SWEP.EquipMenuData = {
      type = "item_weapon",
      desc = "The deadly Bulldozer Armor. \nYou get +20HP and an automatic shotgun, but everyone knows you put it on."
   };
   
   SWEP.Icon = "vgui/ttt/icon_bulldozer"
end

SWEP.Base		= "weapon_ttt_brekiy_base"
SWEP.Spawnable = true

SWEP.Kind = WEAPON_HEAVY
SWEP.CanBuy = {ROLE_TRAITOR, ROLE_DETECTIVE}
SWEP.LimitedStock = true
SWEP.WeaponID = AMMO_BULLDOZER

SWEP.AllowDrop = false

SWEP.Primary.Ammo = "Buckshot"
SWEP.Primary.Damage = 9
SWEP.Primary.Cone = 0.043
SWEP.Primary.Delay = 0.28
SWEP.Primary.ClipSize = 7
SWEP.Primary.ClipMax = 21
SWEP.Primary.DefaultClip = 7
SWEP.Primary.Automatic = true
SWEP.Primary.NumShots = 7
SWEP.AutoSpawnable      = false
SWEP.AmmoEnt = "item_box_buckshot_ttt"
SWEP.HeadshotMultiplier = 2
SWEP.CrouchBonus 				 	= 1
SWEP.MovePenalty			 	 	= 0
SWEP.JumpPenalty			 	 	= 0.1
SWEP.MaxCone 					 	= 0.15
SWEP.TracerFrequency				= 1

SWEP.AimPatternX 		= function(t)
		return 0
	end
SWEP.AimPatternY 		= function(t)
		return 2.25*t
	end
SWEP.BloomRecoverRate 	= 0.001
SWEP.AimRecoverRate		= 0.3
SWEP.AimKick			= 4
SWEP.Primary.ShoveY         = 0.2
SWEP.Primary.ShoveX         = 0.2

SWEP.UseHands			= true
SWEP.ViewModelFlip		= false
SWEP.ViewModelFOV		= 62
SWEP.ViewModel			= "models/weapons/cstrike/c_shot_xm1014.mdl"
SWEP.WorldModel			= "models/weapons/w_shot_xm1014.mdl"
SWEP.Primary.Sound		= Sound( "Weapon_xm1014.shot" )
SWEP.Primary.Recoil		= 0.015
SWEP.AutoSwitchTo       = true

SWEP.IronSightsPos = Vector(-6.881, -9.214, 2.66)
SWEP.IronSightsAng = Vector(-0.101, -0.7, -0.201)

SWEP.reloadtimer = 0

function SWEP:OnDrop()
   self:Remove()
end

function SWEP:WasBought(buyer)
   if IsValid(buyer) then -- probably already self.Owner
      buyer:SetModel( "models/player/riot.mdl" )
	  buyer:GiveAmmo( 7, "Buckshot" )
	  local health = buyer:Health()
		buyer:SetHealth( health + 20 )
		buyer:ChatPrint("Warning, you cannot drop this weapon!")
		for k, v in pairs(player.GetAll()) do
	v:ChatPrint(buyer:Nick() ..  " has bought BullDozer Armour!" )
		end
	end
end

function SWEP:SetupDataTables()
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
   --if self:GetNextSecondaryFire() > CurTime() then return end
   self:SetIronsights(not self:GetIronsights())
   self:SetNextSecondaryFire(CurTime() + 0.3)
end
