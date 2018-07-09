if SERVER then
  resource.AddFile("materials/vgui/ttt/icon_rg_defibrillator.png")
end

local STATE_NONE, STATE_PROGRESS, STATE_ERROR = 0, 1, 2
local color_red = Color(255, 0, 0)

SWEP.Base = "weapon_tttbase"

SWEP.HoldType = "slam"
SWEP.ViewModel = Model("models/weapons/v_c4.mdl")
SWEP.WorldModel = Model("models/weapons/w_c4.mdl")

util.PrecacheModel( "particle/particle_smokegrenade" ) 
util.PrecacheModel( "particle/particle_noisesphere" ) 

--- TTT Vars
SWEP.Kind = WEAPON_EQUIP2
SWEP.AutoSpawnable = false
SWEP.CanBuy = {ROLE_TRAITOR}
SWEP.LimitedStock = true

SWEP.TimeToDefib = 10

if CLIENT then
  SWEP.PrintName = "Defibrillator"
  SWEP.Slot = 7

  SWEP.Icon = "vgui/ttt/icon_rg_defibrillator.png"

  SWEP.EquipMenuData = {
    type = "item_weapon",
    name = "Defribrillator",
    desc = "Resurrect dead mates with this one!"
  }

  surface.CreateFont("DefibText", {
    font = "Tahoma",
    size = 13,
    weight = 700,
    shadow = true
  })

  function SWEP:DrawHUD()
    local state = self:GetDefibState()
    local scrW, scrH = ScrW(), ScrH()
    local progress = 1
    local outlineCol, progressCol, progressText = color_white, color_white, ""

    if state == STATE_PROGRESS then
      local startTime, endTime = self:GetDefibStartTime(), self:GetDefibStartTime() + self.TimeToDefib - 0.5

      progress = math.TimeFraction(startTime, endTime, CurTime())

      if progress <= 0 then
        return
      end

      outlineCol = Color(0, 100, 0)
      progressCol = Color(0, 255, 0, (math.abs(math.sin(RealTime() * 3)) * 100) + 20)
      progressText = self:GetStateText() or "DEFIBRILLATING"
    elseif state == STATE_ERROR then
      outlineCol = color_red
      progressCol = Color(255, 0, 0, math.abs(math.sin(RealTime() * 15)) * 255)
      progressText = self:GetStateText() or ""
    else
      return
    end

    progress = math.Clamp(progress, 0, 1)

    surface.SetDrawColor(outlineCol)
    surface.DrawOutlinedRect(scrW / 2 - (200 / 2) - 1, scrH / 2 + 10 - 1, 202, 16)

    surface.SetDrawColor(progressCol)
    surface.DrawRect(scrW / 2  - (200 / 2), scrH / 2 + 10, 200 * progress, 14)

    surface.SetFont("DefibText")
    local textW, textH = surface.GetTextSize(progressText)

    surface.SetTextPos(scrW / 2 - 100 + 2, scrH / 2 - 20 + textH)
    surface.SetTextColor(color_white)
    surface.DrawText(progressText)
  end
end

function SWEP:SetupDataTables()
  self:NetworkVar("Int", 0, "DefibState")
  self:NetworkVar("Float", 1, "DefibStartTime")

  self:NetworkVar("String", 0, "StateText")
end

function SWEP:Initialize()
  self:SetDefibState(STATE_NONE)
  self:SetDefibStartTime(0)
end

function SWEP:Deploy()
  self:SetDefibState(STATE_NONE)
  self:SetDefibStartTime(0)

  return true
end

function SWEP:Holster()
  self:SetDefibState(STATE_NONE)
  self:SetDefibStartTime(0)

  return true
end


function SWEP:PrimaryAttack()
  if CLIENT then return end

  local tr = util.TraceLine({
    start = self.Owner:EyePos(),
    endpos = self.Owner:EyePos() + self.Owner:GetAimVector() * 80,
    filter = self.Owner
  })

  if IsValid(tr.Entity) and tr.Entity:GetClass() == "prop_ragdoll" then
    if not tr.Entity.uqid then
      self:FireError("FAILURE - SUBJECT BRAINDEAD")
      return
    end

    local ply = player.GetByUniqueID(tr.Entity.uqid)

    if IsValid(ply) then
      self:BeginDefib(ply, tr.Entity)
    else
      self:FireError("FAILURE - SUBJECT BRAINDEAD")
      return
    end
  else
    self:FireError("FAILURE - INVALID TARGET")
  end
end

function SWEP:BeginDefib(ply, ragdoll)
  local spawnPos = self:FindPosition(self.Owner)

  if not spawnPos then
    self:FireError("FAILURE - INSUFFICIENT ROOM")
    return
  end

  self:SetStateText("DEFIBRILLATING - "..string.upper(ply:Name()))
  self:SetDefibState(STATE_PROGRESS)
  self:SetDefibStartTime(CurTime())

  self.TargetPly = ply
  self.TargetRagdoll = ragdoll

  self:SetNextPrimaryFire(CurTime() + self.TimeToDefib + 1)
end

function SWEP:FireError(err)
  if err then
    self:SetStateText(err)
  else
    self:SetStateText("")
  end

  self:SetDefibState(STATE_ERROR)

  timer.Simple(1, function()
    if IsValid(self) then
      self:SetDefibState(STATE_NONE)
      self:SetStateText("")
    end
  end)

  self:SetNextPrimaryFire(CurTime() + 1.2)
end

function SWEP:FireSuccess()
  self:SetDefibState(STATE_NONE)
  self:SetNextPrimaryFire(CurTime() + 1)
  
  hook.Call("UsedDefib", GAMEMODE, self.Owner)

  self:Remove()
end

function SWEP:Think()
  if CLIENT then return end

  if self:GetDefibState() == STATE_PROGRESS then
    if not IsValid(self.Owner) then
      self:FireError()
      return
    end

    if not (IsValid(self.TargetPly) and IsValid(self.TargetRagdoll)) then
      self:FireError("ERROR - SUBJECT BRAINDEAD")
      return
    end

    local tr = util.TraceLine({
      start = self.Owner:EyePos(),
      endpos = self.Owner:EyePos() + self.Owner:GetAimVector() * 80,
      filter = self.Owner
    })

    if tr.Entity ~= self.TargetRagdoll then
      self:FireError("ERROR - TARGET LOST")
      return
    end

    if CurTime() >= self:GetDefibStartTime() + self.TimeToDefib then
      if self:HandleRespawn() then
        self:FireSuccess()
      else
        self:FireError("ERROR - INSUFFICIENT ROOM")
        return
      end
    end


    self:NextThink(CurTime())
    return true
  end
end

local healsound = Sound("items/medshot4.wav")

function SWEP:HandleRespawn()
  local ply, ragdoll = self.TargetPly, self.TargetRagdoll
  local spawnPos = self:FindPosition(self.Owner)

  if not spawnPos then
    return false
  end

  local credits = CORPSE.GetCredits(ragdoll, 0)

  ply:SpawnForRound(true)
  ply:SetCredits(credits)
  ply:SetPos(spawnPos)
  ply:SetEyeAngles(Angle(0, ragdoll:GetAngles().y, 0))
  
	local cues = {
	   Sound("ttt/thump01e.mp3"),
	   Sound("ttt/thump02e.mp3")
	};
	sound.Play(table.Random(cues), spawnPos, 160, 100, 1)

   local smokeparticles = {
	  Model("particle/particle_smokegrenade"),
	  Model("particle/particle_noisesphere")
   };

   function CreateSmoke(center)
		if CLIENT then
		  local em = ParticleEmitter(center) 

		  local r = 20
		  for i=1, 20 do
			 local prpos = VectorRand() * r
			 prpos.z = prpos.z + 32
			 local p = em:Add(table.Random(smokeparticles), center + prpos)
			 if p then
				local gray = math.random(150, 240)
				p:SetColor(gray, gray, gray)
				p:SetStartAlpha(255)
				p:SetEndAlpha(200)
				p:SetVelocity(VectorRand() * math.Rand(1200, 1600))
				p:SetLifeTime(0)
				
				p:SetDieTime(math.Rand(50, 70))

				p:SetStartSize(math.random(140, 150))
				p:SetEndSize(math.random(1, 40))
				p:SetRoll(math.random(-180, 180))
				p:SetRollDelta(math.Rand(-0.1, 0.1))
				p:SetAirResistance(500)

				p:SetCollide(true)
				p:SetBounce(0.4)

				--p:SetLighting(false)
			 end
		  end

		  em:Finish()
		end
   end
	local spos = spawnPos
	local trs = util.TraceLine({start=spos + Vector(0,0,64), endpos=spos + Vector(0,0,-128), filter={ragdoll,ply}})
	util.Decal("SmallScorch", trs.HitPos + trs.HitNormal, trs.HitPos - trs.HitNormal) 

	--if tr.Fraction != 1.0 then
	--	spos = tr.HitPos + tr.HitNormal * 0.6
	--end
	if trs.Fraction != 1.0 then
		spos = trs.HitPos + trs.HitNormal * 10
	end

	-- Smoke particles can't get cleaned up when a round restarts, so prevent
	-- them from existing post-round.
	if GetRoundState() != ROUND_POST then 
		CreateSmoke(spos)
	end

  ragdoll:Remove()
  self:EmitSound(healsound)
  return true
end


local Positions = {}
for i=0,360,22.5 do table.insert( Positions, Vector(math.cos(i),math.sin(i),0) ) end -- Populate Around Player
table.insert(Positions, Vector(0, 0, 1)) -- Populate Above Player

function SWEP:FindPosition(ply)
  local size = Vector(32, 32, 72)
  
  local StartPos = ply:GetPos() + Vector(0, 0, size.z/2)
  
  local len = #Positions
  
  for i = 1, len do
    local v = Positions[i]
    local Pos = StartPos + v * size * 1.5
    
    local tr = {}
    tr.start = Pos
    tr.endpos = Pos
    tr.mins = size / 2 * -1
    tr.maxs = size / 2
    local trace = util.TraceHull(tr)
    
    if(not trace.Hit) then
      return Pos - Vector(0, 0, size.z/2)
    end
  end

  return false
end