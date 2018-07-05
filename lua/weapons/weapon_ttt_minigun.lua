if SERVER then
   AddCSLuaFile( "shared.lua" )
   resource.AddFile("tflppy/vgui/ttt/icon_minigun.vmt")
   resource.AddFile("tflppy/vgui/ttt/icon_minigun.vtf")
end

if CLIENT then
   SWEP.PrintName = "M61 Vulcan"
   SWEP.Author = "TFlippy"
   
   SWEP.Slot = 6
   SWEP.Icon = "tflippy/vgui/ttt/icon_minigun"
   
   SWEP.EquipMenuData = {
   type = "Weapon",
   desc = "A fucking minigun. Slows you down when you carry it, even in your inventory."
   };
end

SWEP.Base			= "weapon_ttt_brekiy_base"

SWEP.HoldType		= "shotgun"
SWEP.AutoSpawnable	  = false
SWEP.AllowDrop = true
SWEP.IsSilent = false
SWEP.NoSights = true
SWEP.Kind = WEAPON_EQUIP1

SWEP.Primary.Delay	   = 0.08
SWEP.Primary.Recoil	  = 0.005
SWEP.Primary.Automatic   = true
SWEP.ViewModelFOV  = 50
SWEP.ViewModelFlip = false
SWEP.CSMuzzleFlashes = true
SWEP.Primary.ClipSize	= 250
SWEP.Primary.ClipMax	 = 0
SWEP.Primary.DefaultClip = 250
SWEP.Primary.Ammo		= "AirboatGun"
SWEP.HeadshotMultiplier = 2
SWEP.CrouchBonus 				 	= 0.7
SWEP.MovePenalty			 	 	= 1.2
SWEP.JumpPenalty			 	 	= 2
SWEP.MaxCone 					 	= 0.065

SWEP.AimKick				= 0.05
SWEP.Primary.ShoveY         = 0.1
SWEP.Primary.ShoveX         = 0.3

SWEP.CanBuy = { ROLE_TRAITOR }
SWEP.LimitedStock = true

SWEP.Primary.Damage	  = 15
SWEP.Primary.Cone	= 0.012
SWEP.Primary.NumShots = 0

SWEP.IronSightsPos = Vector(-3.80, 1.00, 2.00)
SWEP.IronSightsAng = Vector(0.12, -0.02, 0.00)

SWEP.UseHands	= false
SWEP.ViewModel	= "models/weapons/v_minigunvulcan.mdl"
SWEP.WorldModel	= "models/weapons/w_m134_minigun.mdl"
SWEP.Primary.Sound = Sound( "BlackVulcan.TFlippy.Single" )
SWEP.Secondary.Sound = Sound("Default.Zoom")

local SpinMod = 1
SWEP.IsShooting = false
SWEP.SpinTime = 0.2

function SWEP:Deploy()
	self:SendWeaponAnim(ACT_VM_DRAW)
	if self.Owner:SteamID() then
		timer.Destroy(self.Owner:SteamID() .. "_SpinMod")
	end
	SpinMod = SpinMod-SpinMod+1
	self.IsShooting = false
	return true
end

function SWEP:OnRemove()
	if self.Owner:SteamID() then
		timer.Destroy(self.Owner:SteamID() .. "_SpinMod")
	end
	SpinMod = SpinMod-SpinMod+1
	self.IsShooting = false
end

function SWEP:Holster()
	if self.Owner:SteamID() then
		timer.Destroy(self.Owner:SteamID() .. "_SpinMod")
	end
	SpinMod = SpinMod-SpinMod+1
	self.IsShooting = false
	return true
end

function MinigunSpeedMod(ply, speed)
	if ply:HasWeapon("ttt_minigun") then
		return 0.75
	end
end

hook.Add("TTTPlayerSpeed", "MinigunSpeed", MinigunSpeedMod )

function SWEP:Think()
	self:ThinkBase()
	if self.IsShooting == true and IsValid(self.Owner) and self.Owner:IsTerror() then
		if self.Owner:KeyReleased( IN_ATTACK) then
			if self.Owner:SteamID() then
				timer.Destroy(self.Owner:SteamID() .. "_SpinMod")
			end
			SpinMod = SpinMod-SpinMod+1
			self.IsShooting = false 
		end
	end
end		
		
function SWEP:PrimaryAttack(worldsnd)	

		self:SetNextSecondaryFire( CurTime() + self.SpinTime/SpinMod )
		self:SetNextPrimaryFire( CurTime() + self.SpinTime/SpinMod )   

		if not self:CanPrimaryAttack() then return end
		
		if SERVER then
			self.Owner:LagCompensation(true)
		end
		
		if not self.IsShooting == true then
			self.IsShooting = true
			timer.Create(self.Owner:SteamID() .. "_SpinMod", 0.25, 20,
				function()
					
					SpinMod = math.Approach( SpinMod, 5,  0.22)	
				end)
		end
		
		self:PrimaryAttackBase(worldsnd)
		
		if SERVER then
			self.Owner:LagCompensation(false)
		end
end