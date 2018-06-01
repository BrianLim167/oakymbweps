AddCSLuaFile()
if ( SERVER ) then
resource.AddFile("lua/entities/sent_molotov.lua")
resource.AddFile("lua/entities/sent_molotov_timed.lua")
resource.AddFile("lua/entities/sent_firecontroller/shared.lua")
resource.AddFile("lua/entities/sent_firecontroller/init.lua")
resource.AddFile("lua/entities/sent_firecontroller/cl_init.lua")
resource.AddFile("lua/effects/molotov_explosion/init.lua")
resource.AddFile("particles/extinguisher.pcf")
resource.AddFile("models/weapons/v_molotov.dx80.vtx")
resource.AddFile("models/weapons/v_molotov.dx90.vtx")
resource.AddFile("models/weapons/v_molotov.mdl")
resource.AddFile("models/weapons/v_molotov.sw.vtx")
resource.AddFile("models/weapons/v_molotov.vvd")
resource.AddFile("models/weapons/v_molotov.xbox.vtx")
resource.AddFile("materials/nyan/killicon2.png")
resource.AddFile("materials/vgui/entities/molotov_cocktail.vtf")
resource.AddFile("materials/vgui/entities/molotov_cocktail.vmt")
resource.AddFile("materials/sprites/w_icons3.vtf")
resource.AddFile("materials/nyan/killicon.png")
resource.AddFile("materials/particle/mat1.vtf")
resource.AddFile("materials/particle/mat1.vmt")
resource.AddFile("materials/models/weapons/w_molotov/rag.vtf")
resource.AddFile("materials/models/weapons/w_molotov/rag.vmt")
resource.AddFile("materials/models/weapons/w_molotov/molotov.vtf")
resource.AddFile("materials/models/weapons/w_molotov/molotov.vmt")
resource.AddFile("models/weapons/w_molotov.mdl")
resource.AddFile("materials/molotov.png")
resource.AddFile("models/weapons/v_molotov.mdl")
resource.AddFile("models/props_junk/garbage_glassbottle003a.mdl")
 end
 
if ( CLIENT ) then
	SWEP.PrintName			= "Molotov Cocktail" 
	SWEP.Author				= "SmiteTheHero"
	SWEP.Slot				= 7
	SWEP.Slotpos			= 5
	SWEP.DrawAmmo 			= false
	SWEP.DrawCrosshair 		= false 	
	SWEP.SlotPos			= 5
	SWEP.Contact 			= "smitethehero@hotmail.co.uk"
	SWEP.Purpose 			= "Starts Fires and its fun"
	SWEP.Instructions 		= "Left click to Throw, Right click to Roll"
end

SWEP.Base = "weapon_tttbase"
SWEP.Kind = WEAPON_EQUIP1
 
 SWEP.EquipMenuData = {
      name = "Molotov Cocktail",
      type = "item_weapon",
      desc = "Sets the world on fire!\nJust one try, but a heavy explosion."
   };
SWEP.Icon = "materials/molotov.png"

SWEP.CanBuy = {ROLE_TRAITOR}
SWEP.LimitedStock = true

SWEP.AutoSpawnable = false
SWEP.AdminSpawnable = true
SWEP.InLoadoutFor = nil
SWEP.AllowDrop = true
SWEP.IsSilent = false
SWEP.NoSights = false

SWEP.ViewModel			= "models/weapons/v_molotov.mdl"
SWEP.WorldModel			= "models/props_junk/garbage_glassbottle003a.mdl"
SWEP.ViewModelFOV		= 64
SWEP.Category			= "Explosives"

SWEP.Weight				= 1
SWEP.AutoSwitchTo		= false
SWEP.AutoSwitchFrom		= false
SWEP.Spawnable			= true
SWEP.HoldType			= "grenade"

SWEP.Primary.Recoil			= 0
SWEP.Primary.Delay 			= 0
SWEP.Primary.Damage			= 0
SWEP.Primary.ClipSize		= 1
SWEP.Primary.Reload 		= 0
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "molotov"
SWEP.Primary.DefaultClip    = 1

SWEP.Secondary.Delay		= 0
SWEP.Secondary.ClipSize		= 1
SWEP.Secondary.DefaultClip	= 1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "molotov"

function SWEP:Initialize()
	util.PrecacheSound( "WeaponFrag.Throw" )
	util.PrecacheModel( "models/weapons/w_molotov.mdl" )
	self:SetHoldType( self.HoldType )
end

function SWEP:Think()
end

function SWEP:PrimaryAttack()
    if ( self.Owner:GetAmmoCount( "molotov" ) < 0 ) then return end
	if ( CLIENT ) then return end
	local Molotov = ents.Create( "sent_molotov" )
	Molotov:SetOwner( self.Owner )
	Molotov:SetPhysicsAttacker(self.Owner)
	Molotov:SetPos( self.Owner:GetShootPos() )
	Molotov:Spawn()

	local mPhys = Molotov:GetPhysicsObject()
	local Force = self.Owner:GetAimVector() * 2555

	mPhys:ApplyForceCenter( Force )

	self.Weapon:EmitSound( "WeaponFrag.Throw" )
	self.Weapon:SendWeaponAnim( ACT_VM_THROW )
	timer.Simple( 0.5, function() if ( IsValid( self ) ) then self:SendWeaponAnim( ACT_VM_DRAW ) end end )
	self.Weapon:SetNextPrimaryFire( CurTime() + 3 )
	self.Weapon:SetNextSecondaryFire( CurTime() + 2 )
	self.Weapon:Remove()
end

function SWEP:SecondaryAttack()
    if ( self.Owner:GetAmmoCount( "molotov" ) < 0 ) then return end
	if ( CLIENT ) then return end
	local Molotov = ents.Create( "sent_molotov_timed" )
	Molotov:SetOwner( self.Owner )
	Molotov:SetPhysicsAttacker(self.Owner)
	Molotov:SetPos( self.Owner:GetShootPos() )
	Molotov:Spawn()

	local mPhys = Molotov:GetPhysicsObject()
	local Force = self.Owner:GetAimVector() * 500

	mPhys:ApplyForceCenter( Force )

	self:EmitSound( "WeaponFrag.Throw" )
	self:SendWeaponAnim( ACT_VM_THROW )
	timer.Simple( 0.5, function() if ( IsValid( self ) ) then  self:SendWeaponAnim( ACT_VM_DRAW ) end end )
	self:SetNextSecondaryFire( CurTime() + 2 )
	self:SetNextPrimaryFire( CurTime() + 2 )
	self.Weapon:Remove()
end

function SWEP:Deploy()
	self:SendWeaponAnim( ACT_VM_DRAW )
end

function SWEP:Reload()
	return false
end
