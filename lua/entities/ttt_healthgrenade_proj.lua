-- fix by aampersands (comments are tagged with &&)
AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "ttt_basegrenade_proj"
ENT.Model = Model("models/weapons/w_eq_smokegrenade_thrown.mdl")

ENT.PrintName = "Health Grenade"


function ENT:Initialize()
  self.fuse = 4 --timer starts 4 seconds after thrown &&
  self.duration = 30 --when the healing effect ends

  self.timer = CurTime() + self.fuse 
  self.healgas = nil
  self.Spammed = false

  return self.BaseClass.Initialize(self)
end

function Heal(ply)
    if (ply:Health() < 100) and (ply:Health() > 1) then
        ply:SetHealth(ply:Health() + 1)
    elseif  (ply:Health() >= 100) then
        else
    end
end

function ENT:Think() 
    --Generate healing gas &&
    if self.timer < CurTime() then
        if (!IsValid(self.healgas) && !self.Spammed) then
            self.Spammed = true
            if ( SERVER ) then
                ents.Create("env_smoketrail")
                self.healgas = ents.Create("env_smoketrail")
                self.healgas:SetPos(self.Entity:GetPos())
                self.healgas:SetKeyValue("spawnradius","150")
                self.healgas:SetKeyValue("minspeed","0.5")
                self.healgas:SetKeyValue("maxspeed","2")
                self.healgas:SetKeyValue("startsize","800")
                self.healgas:SetKeyValue("endsize","50")
                self.healgas:SetKeyValue("endcolor","0 255 169")
                self.healgas:SetKeyValue("startcolor","0 255 169")
                self.healgas:SetKeyValue("opacity","3")
                self.healgas:SetKeyValue("spawnrate","60")
                self.healgas:SetKeyValue("lifetime","10")
                self.healgas:SetParent(self.Entity)
                self.healgas:Spawn()
                self.healgas:Activate()
                self.healgas:Fire("turnon","", 0.1)
                local exp = ents.Create("env_explosion")
                exp:SetKeyValue("spawnflags",461)
                exp:SetPos(self.Entity:GetPos())
                exp:Spawn()
                exp:Fire("explode","",0)
                self:EmitSound(Sound("BaseSmokeEffect.Sound"))
            end
        end
        --Apply healing effect &&
        local pos = self.Entity:GetPos()
        local maxrange = 256

        for k,v in pairs(player.GetAll()) do
            local plpos = v:GetPos()
            local dist = -pos:Distance(plpos)+maxrange
            if (pos:Distance(plpos)<=maxrange) then
                local trace = {}
                    trace.start = self.Entity:GetPos()
                    trace.endpos = v:GetPos()+Vector(0,0,24)
                    trace.filter = { v, self.Entity }
                    trace.mask = COLLISION_GROUP_PLAYER
                tr = util.TraceLine(trace)
                --ensures line of sight &&
                if (tr.Fraction==1) then
                  Heal(v)
                end
            end
        end

        if (CurTime() > self.timer + self.duration) then --5 is how long it takes for smoke to fade &&
            if IsValid(self.healgas) then
                self.healgas:Remove()
            end
        end
        if (CurTime() > self.timer + self.duration) then
            self:Remove()
        end
        self.Entity:NextThink(CurTime()+0.2) --possibly adjusts healing rate, not sure if works &&
        return true
    end
end

function ENT:Explode(tr)
end