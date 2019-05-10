AddCSLuaFile("shared.lua")
 
if (CLIENT) then
  SWEP.PrintName = "Plasma Gun" 
  SWEP.Author = "brekiy"
  SWEP.Slot = 2
  SWEP.SlotPos = 5
  SWEP.Purpose = "pbbbbbbt"
  SWEP.Instructions = "pbbbbbbt"
end

SWEP.Base    = "weapon_ttt_brekiy_base"
SWEP.Kind = WEAPON_HEAVY
 
SWEP.EquipMenuData = {
  name = "Plasmagun",
  type = "item_weapon",
  desc = "Shoots hot plasma bolts that have a bit of splash damage and can light things on fire.\nDon't let it overheat or you'll get roasted."
};
SWEP.Icon = "vgui/ttt/icon_polter"

SWEP.CanBuy = {ROLE_TRAITOR}
SWEP.LimitedStock = true

if ROLE_SURVIVALIST then 
  SWEP.CanBuy = {ROLE_TRAITOR, ROLE_SURVIVALIST}
end

SWEP.AutoSpawnable = false
SWEP.AdminSpawnable = true
SWEP.InLoadoutFor = nil
SWEP.AllowDrop = true
SWEP.IsSilent = false
SWEP.NoSights = true

SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_irifle.mdl"
SWEP.WorldModel = "models/weapons/w_IRifle.mdl"
SWEP.ViewModelFOV    = 54
SWEP.ViewModelFlip    = false
SWEP.Category      = "Explosives"

SWEP.HoldType      = "ar2"

SWEP.Primary.Recoil = 0
SWEP.Primary.Delay = 0.125
SWEP.Primary.Damage = 15
SWEP.Primary.ClipSize = 150
SWEP.Primary.DefaultClip = 150
SWEP.Primary.ClipMax = 150
SWEP.Primary.Cone = 0.2
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "AirboatGun"
SWEP.Primary.Sound = Sound( "Weapon_plasma.shot" )
SWEP.Primary.ShoveX = 0.15
SWEP.Primary.ShoveY = 0.25

SWEP.Secondary.ClipSize    = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic   = false
SWEP.Secondary.Ammo        = "none"
SWEP.Secondary.Delay       = 0.5

SWEP.OverheatSound = Sound("Weapon_plasma.overheat")
SWEP.OverheatFinishSound = Sound("Weapon_plasma.overheat_finish")
SWEP.CurHeat = 0
SWEP.MaxHeat = 30
SWEP.BuildupHeat = 1.25
SWEP.InCooldown = false
SWEP.IsShooting = false
SWEP.CooldownRate = 1
SWEP.CooldownFreq = 0.1
SWEP.NextCool = 0

function SWEP:Holster()
  self:HolsterBase()
  self.IsShooting = false
  self.DeployTime = 0
  self.HolsterTime = CurTime()
  return true
end

function SWEP:Deploy()
  self:SendWeaponAnim(ACT_VM_DRAW)
  self.IsShooting = false
  self.DeployTime = CurTime()
  return true
end

function SWEP:Think()
  self:ThinkBase()
  if not IsFirstTimePredicted() then return end
  if self.Owner:KeyDown(IN_ATTACK) and not self.InCooldown and self:CanPrimaryAttack() then
    self.IsShooting = true
  else
    self.IsShooting = false
  end
  if self.CurHeat > 0 and not self.IsShooting then
    local t = CurTime()
    if t > self.NextCool then
      self.CurHeat = self.CurHeat - self.CooldownRate
      if self.CurHeat <= 0 then
        self.CurHeat = 0
        self.InCooldown = false
      end
      self.NextCool = t + self.CooldownFreq
    end
  end
end

function SWEP:PrimaryAttackBase()
  if (not IsFirstTimePredicted()) or (not self:CanPrimaryAttack()) or self.InCooldown then return end
  if self.CurHeat >= self.MaxHeat then self:Overheat() return end
  self.CurHeat = self.CurHeat + self.BuildupHeat
  self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
  self.Owner:SetAnimation(PLAYER_ATTACK1)
  self:TakePrimaryAmmo(1)
  if SERVER then
    local pos = self.Owner:GetShootPos()
    local heatCone = self.Primary.Cone * (self.CurHeat / 4 + 1)
    local spr = Angle(math.random(-heatCone,heatCone),
                      math.random(-heatCone,heatCone),
                      math.random(-heatCone,heatCone))
    local ang = self.Owner:GetAimVector():Angle() + spr
    local ent = ents.Create("ttt_plasma")
    ent:SetAngles(ang)
    ent:SetPos(pos)
    ent:SetOwner(self.Owner)
    ent:Spawn()
    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
      phys:SetVelocity(ang:Forward() * 1500)
    end
  end
  if not worldsnd then
    self:EmitSound(self.Primary.Sound, self.Primary.SoundLevel)
  elseif SERVER then
    sound.Play(self.Primary.Sound, self:GetPos(), self.Primary.SoundLevel)
  end
  self.Owner:ViewPunch(Angle(self.Primary.ShoveY*math.Rand(-1,1), self.Primary.ShoveX*math.Rand(-1,1), 0))
end

function SWEP:Reload()
  return false
end

function SWEP:Overheat()
  -- do a bit of burn damage to the player
  self:SendWeaponAnim(ACT_VM_RELOAD)
  self.InCooldown = true
  if SERVER then
    local dmg = DamageInfo()
    dmg:SetDamage(10)
    dmg:SetAttacker(self.Owner)
    dmg:SetDamageType(DMG_BURN)
    if IsValid(self.Owner) then
      self.Owner:TakeDamageInfo(dmg)
    end
  end
  if SERVER then
    sound.Play(self.OverheatSound, self:GetPos(), self.Primary.SoundLevel)
  else
    self:EmitSound(self.OverheatSound, self.Primary.SoundLevel)
  end
end

if CLIENT then
  local surface = surface
   function SWEP:DrawHUD()
      local x = ScrW() / 2.0
      local y = ScrH() / 2.0

      local heat = self.CurHeat
      local max = self.MaxHeat

      if LocalPlayer():IsTraitor() then
         surface.SetDrawColor(255, 0, 0, 255)
      else
         surface.SetDrawColor(0, 255, 0, 255)
      end

      surface.DrawCircle(x, y, 15, surface.GetDrawColor())

      if heat > 0 then
         y = y + (y / 3)
         local w, h = 300, 20

         surface.DrawOutlinedRect(x - w/2, y - h, w, h)

         if LocalPlayer():IsTraitor() then
            surface.SetDrawColor(255, 0, 0, 155)
         else
            surface.SetDrawColor(0, 255, 0, 155)
         end

         surface.DrawRect(x - w/2, y - h, w * (heat/max), h)
         surface.SetFont("TabLarge")
         surface.SetTextColor(255, 255, 255, 180)
         surface.SetTextPos( (x - w / 2) + 3, y - h - 15)
         surface.DrawText("HEAT")
      end
   end
end
