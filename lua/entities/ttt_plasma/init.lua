AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
  self:SetModel("models/props_junk/PopCan01a.mdl")
  self:SetModelScale(0.05)
  self:SetMoveCollide(COLLISION_GROUP_PROJECTILE)
  self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_VPHYSICS)
  self:SetSolid(SOLID_CUSTOM)
  self:DrawShadow(false)
  util.SpriteTrail(self, 0, Color(100, 150, 255), false, 20, 0, 0.2, 0.5, "trails/physbeam.vmt")
  m_entLight = ents.Create("light_dynamic")
  m_entLight:SetColor(Color(100,150,255,255))
  m_entLight:SetKeyValue("brightness", "4")
  m_entLight:SetKeyValue("distance", "100")
  m_entLight:SetPos(self:GetPos())
  m_entLight:SetParent(self.Entity)
  m_entLight:Spawn()
  m_entLight:Activate()
  m_entLight:Fire("TurnOn", "", 0)
  self:DeleteOnRemove(m_entLight)
  local phys = self:GetPhysicsObject()
  if IsValid(phys) then
    phys:Wake()
    phys:SetMass(0.1)
    phys:EnableDrag(false)
    phys:EnableGravity(false)
    phys:SetBuoyancyRatio(0)
    end
end

function ENT:PhysicsCollide(data, physobj)
  local hitsounds = {
    "Weapon_plasma.hit1",
    "Weapon_plasma.hit2",
    "Weapon_plasma.hit3"
  }
  util.Decal("SmallScorch", data.HitPos + data.HitNormal , data.HitPos - data.HitNormal)
  util.BlastDamage(self, self:GetOwner(), self:GetPos(), 25, 15)
  self:EmitSound(table.Random(hitsounds))
  for k, v in pairs (ents.FindInSphere( self:GetPos(), 15 )) do
    if v:IsPlayer() and v:Alive() and (not v:IsSpec()) then
      v:Ignite(2)
    elseif v:IsWeapon() == 0 then
      v:Ignite(2)
    end
  end
  self:Remove()
end
