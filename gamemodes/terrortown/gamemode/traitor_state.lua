function GetTraitors()
   local trs = {}
   for k,v in ipairs(player.GetAll()) do
      if v:GetTraitor() then table.insert(trs, v) end
   end

   return trs
end

function CountTraitors() return #GetTraitors() end

---- Role state communication

-- Send every player their role
local function SendPlayerRoles()
   for k, v in pairs(player.GetAll()) do
      net.Start("TTT_Role")
         net.WriteUInt(v:GetRole(), 3)
      net.Send(v)
   end
end

local function SendRoleListMessage(role, role_ids, ply_or_rf)
   net.Start("TTT_RoleList")
      net.WriteUInt(role, 3)

      -- list contents
      local num_ids = #role_ids
      net.WriteUInt(num_ids, 8)
      for i=1, num_ids do
         net.WriteUInt(role_ids[i] - 1, 7)
      end

   if ply_or_rf then net.Send(ply_or_rf)
   else net.Broadcast() end
end

local function SendRoleList(role, ply_or_rf, pred)
   local role_ids = {}
   for k, v in pairs(player.GetAll()) do
      if v:IsRole(role) then
         if not pred or (pred and pred(v)) then
            table.insert(role_ids, v:EntIndex())
         end
      end
   end

   SendRoleListMessage(role, role_ids, ply_or_rf)
end

-- Tell traitors about other traitors

function SendTraitorList(ply_or_rf, pred) SendRoleList(ROLE_TRAITOR, ply_or_rf, pred) end
function SendDetectiveList(ply_or_rf) SendRoleList(ROLE_DETECTIVE, ply_or_rf) end
function SendSurvivalistList(ply_or_rf) SendRoleList(ROLE_SURVIVALIST, ply_or_rf) end
function SendJesterList(ply_or_rf) SendRoleList(ROLE_JESTER, ply_or_rf) end
function SendResurrectorList(ply_or_rf) SendRoleList(ROLE_RESURRECTOR, ply_or_rf) end
function SendSerialkillerList(ply_or_rf) SendRoleList(ROLE_SERIALKILLER, ply_or_rf) end
function SendInfectedList(ply_or_rf) SendRoleList(ROLE_INFECTED, ply_or_rf) end

-- this is purely to make sure last round's traitors/dets ALWAYS get reset
-- not happy with this, but it'll do for now
function SendInnocentList(ply_or_rf)
   -- Send innocent and detectives a list of actual innocents + traitors, while
   -- sending traitors only a list of actual innocents.
   local inno_ids = {}
   local traitor_ids = {}
   for k, v in pairs(player.GetAll()) do
      if v:IsRole(ROLE_INNOCENT) then
         table.insert(inno_ids, v:EntIndex())
      elseif v:IsRole(ROLE_TRAITOR) then
         table.insert(traitor_ids, v:EntIndex())
      end
   end

   -- traitors get actual innocent, so they do not reset their traitor mates to
   -- innocence
   SendRoleListMessage(ROLE_INNOCENT, inno_ids, GetTraitorFilter())

   -- detectives and innocents get an expanded version of the truth so that they
   -- reset everyone who is not detective
   table.Add(inno_ids, traitor_ids)
   table.Shuffle(inno_ids)
   SendRoleListMessage(ROLE_INNOCENT, inno_ids, GetInnocentFilter())
end

function SendConfirmedTraitors(ply_or_rf)
   SendTraitorList(ply_or_rf, function(p) return p:GetNWBool("body_found") end)
end

function SendFullStateUpdate()
   SendPlayerRoles()
   SendInnocentList()
   SendTraitorList(GetTraitorFilter())
   SendDetectiveList()
   SendSurvivalistList()
   SendJesterList()
   SendResurrectorList()
   SendSerialkillerList()
   SendInfectedList()
   -- not useful to sync confirmed traitors here
end

function SendRoleReset(ply_or_rf)
   local plys = player.GetAll()

   net.Start("TTT_RoleList")
      net.WriteUInt(ROLE_INNOCENT, 3)

      net.WriteUInt(#plys, 8)
      for k, v in pairs(plys) do
         net.WriteUInt(v:EntIndex() - 1, 7)
      end

   if ply_or_rf then net.Send(ply_or_rf)
   else net.Broadcast() end
end

---- Console commands

local function request_rolelist(ply)
   -- Client requested a state update. Note that the client can only use this
   -- information after entities have been initialised (e.g. in InitPostEntity).
   if GetRoundState() != ROUND_WAIT then

      SendRoleReset(ply)
      SendDetectiveList(ply)
	  SendSurvivalistList(ply)
	  SendJesterList(ply)
	  SendResurrectorList(ply)
	  SendSerialkillerList(ply)
      SendInfectedList(ply)

      if ply:IsTraitor() then
         SendTraitorList(ply)
      else
         SendConfirmedTraitors(ply)
      end
   end
end
concommand.Add("_ttt_request_rolelist", request_rolelist)

local function force_terror(ply)
   ply:SetRole(ROLE_INNOCENT)
   ply:UnSpectate()
   ply:SetTeam(TEAM_TERROR)

   ply:StripAll()

   ply:Spawn()
   ply:PrintMessage(HUD_PRINTTALK, "You are now on the terrorist team.")

   SendFullStateUpdate()
end
concommand.Add("ttt_force_terror", force_terror, nil, nil, FCVAR_CHEAT)

local function force_traitor(ply)
   ply:SetRole(ROLE_TRAITOR)

   SendFullStateUpdate()
end
concommand.Add("ttt_force_traitor", force_traitor, nil, nil, FCVAR_CHEAT)

local function force_detective(ply)
   ply:SetRole(ROLE_DETECTIVE)

   SendFullStateUpdate()
end
concommand.Add("ttt_force_detective", force_detective, nil, nil, FCVAR_CHEAT)

local function force_survivalist(ply)
   ply:SetRole(ROLE_SURVIVALIST)

   SendFullStateUpdate()
end
concommand.Add("ttt_force_survivalist", force_survivalist, nil, nil, FCVAR_CHEAT)

local function force_jester(ply)
   ply:SetRole(ROLE_JESTER)

   SendFullStateUpdate()
end
concommand.Add("ttt_force_jester", force_jester, nil, nil, FCVAR_CHEAT)

local function force_resurrector(ply)
   ply:SetRole(ROLE_RESURRECTOR)

   SendFullStateUpdate()
end
concommand.Add("ttt_force_phoenix", force_resurrector, nil, nil, FCVAR_CHEAT)

local function force_serialkiller(ply)
   ply:SetRole(ROLE_SERIALKILLER)

   SendFullStateUpdate()
end
concommand.Add("ttt_force_serialkiller", force_serialkiller, nil, nil, FCVAR_CHEAT)

local function force_infected(ply)
   ply:SetRole(ROLE_INFECTED)

   SendFullStateUpdate()
end
concommand.Add("ttt_force_infected", force_infected, nil, nil, FCVAR_CHEAT)

local function force_spectate(ply, cmd, arg)
   if IsValid(ply) then
      if #arg == 1 and tonumber(arg[1]) == 0 then
         ply:SetForceSpec(false)
      else
         if not ply:IsSpec() then
            ply:Kill()
         end

         GAMEMODE:PlayerSpawnAsSpectator(ply)
         ply:SetTeam(TEAM_SPEC)
         ply:SetForceSpec(true)
         ply:Spawn()

         ply:SetRagdollSpec(false) -- dying will enable this, we don't want it here
      end
   end
end
concommand.Add("ttt_spectate", force_spectate)
net.Receive("TTT_Spectate", function(l, pl)
   force_spectate(pl, nil, { net.ReadBool() and 1 or 0 })
end)

