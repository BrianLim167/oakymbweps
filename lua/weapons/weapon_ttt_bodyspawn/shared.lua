-- traitor equipment: body spawner

if SERVER then
   AddCSLuaFile( "shared.lua" )
  resource.AddFile("materials/vgui/ttt/icon_deathfaker.png")
end

SWEP.HoldType = "slam"

if CLIENT then
   SWEP.PrintName = "Death Faker"
   SWEP.Slot				= 6

   SWEP.EquipMenuData = {
      type  = "item_weapon",
      name  = "Death Faker",
      desc  = "Spawns a dead body killed with a random weapon"
   };

   SWEP.Icon = "vgui/ttt/icon_deathfaker.png"
end

SWEP.Base = "weapon_tttbase"

SWEP.Kind = WEAPON_EQUIP
SWEP.CanBuy = {ROLE_TRAITOR} -- only traitors can buy
SWEP.WeaponID = AMMO_BODYSPAWNER

SWEP.UseHands			= true
SWEP.ViewModelFlip		= false
SWEP.ViewModelFOV		= 54
SWEP.ViewModel  = Model("models/weapons/cstrike/c_c4.mdl")
SWEP.WorldModel = Model("models/weapons/w_c4.mdl")

SWEP.DrawCrosshair      = false
SWEP.ViewModelFlip      = false
SWEP.Primary.ClipSize       = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Automatic      = true
SWEP.Primary.Ammo       = "none"
SWEP.Primary.Delay = 5.0

SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Automatic    = true
SWEP.Secondary.Ammo     = "none"
SWEP.Secondary.Delay = 1.0

SWEP.NoSights = true

local throwsound = Sound( "Weapon_SLAM.SatchelThrow" )

function SWEP:PrimaryAttack()
   self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
   if SERVER then
	self:BodyDrop()
   end
end

function SWEP:SecondaryAttack()
end

-- mostly replicating HL2DM slam throw here
function SWEP:BodyDrop()
	local dmg = DamageInfo()
	
	ply = table.Random(player.GetAll());
	
	while (ply==self.Owner) do
		ply = table.Random(player.GetAll());
	end
	
	dmg:SetAttacker(ply)
	dmg:SetInflictor(ply)
	dmg:SetDamage(10)
	dmg:SetDamageType( DMG_BULLET ) 

   local rag = CORPSE.Create(self.Owner, ply, dmg)
   CORPSE.SetCredits(rag, 0)
   rag.killer_sample = nil
   self.Weapon:EmitSound(throwsound)
   self.Weapon:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
   
   self:Remove()
end

function SWEP:Reload()
   return false
end

function SWEP:OnRemove()
   if CLIENT and IsValid(self.Owner) and self.Owner == LocalPlayer() and self.Owner:Alive() then
      RunConsoleCommand("lastinv")
   end
end