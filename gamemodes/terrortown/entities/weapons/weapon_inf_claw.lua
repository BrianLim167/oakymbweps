AddCSLuaFile()

SWEP.Base = "weapon_tttbase"
SWEP.PrintName = "Claws"
SWEP.Instructions = "Left click to attack, right click to leap, reload to activate 'night vision'."
SWEP.Spawnable = true
SWEP.AdminSpawnable = false

SWEP.HoldType = "fist"
SWEP.ViewModel			= "models/weapons/c_arms_cstrike.mdl"
SWEP.WorldModel			= ""

SWEP.HitDistance = 150

SWEP.Primary.Damage = 40
SWEP.Primary.ClipSize		= 1
SWEP.Primary.DefaultClip	= 1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "none"
SWEP.Primary.Delay = 0.7
 
SWEP.Secondary.ClipSize		= 5
SWEP.Secondary.DefaultClip	= 5
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"
SWEP.Secondary.Delay = 1.2

halosdgj = false

SWEP.Kind                   = WEAPON_EQUIP1
SWEP.WeaponID               = AMMO_KNIFE

SWEP.AllowDelete             = true -- never removed for weapon reduction
SWEP.AllowDrop = false

SWEP.Nightvision = false
SWEP.NextReload = CurTime()

local sound_single = Sound("weapons/slam/throw.wav")
local sound_open = Sound("Flesh.ImpactHard")

SWEP.Slot				= 6
SWEP.SlotPos			= 6

if ( SERVER ) then
	util.AddNetworkString( "AM_NightvisionOn" )
	util.AddNetworkString( "AM_NightvisionOff" )
end

function SWEP:Initialize()
    self:SetHoldType("fist")

	self:SetWeaponHoldType( self.HoldType )
	
end

local function OpenableEnt(ent)
   local cls = ent:GetClass()
   if ent:GetName() == "" then
      return OPEN_NO
   elseif cls == "prop_door_rotating" then
      return OPEN_ROT
   elseif cls == "func_door" or cls == "func_door_rotating" then
      return OPEN_DOOR
   elseif cls == "func_button" then
      return OPEN_BUT
   elseif cls == "func_movelinear" then
      return OPEN_NOTOGGLE
   else
      return OPEN_NO
   end
end


local function CrowbarCanUnlock(t)
   return not GAMEMODE.crowbar_unlocks or GAMEMODE.crowbar_unlocks[t]
end


-- will open door AND return what it did
function SWEP:OpenEnt(hitEnt)
   -- Get ready for some prototype-quality code, all ye who read this
   if SERVER and GetConVar("ttt_crowbar_unlocks"):GetBool() then
      local openable = OpenableEnt(hitEnt)

      if openable == OPEN_DOOR or openable == OPEN_ROT then
         local unlock = CrowbarCanUnlock(openable)
         if unlock then
            hitEnt:Fire("Unlock", nil, 0)
         end

         if unlock or hitEnt:HasSpawnFlags(256) then
            if openable == OPEN_ROT then
               hitEnt:Fire("OpenAwayFrom", self.Owner, 0)
            end
            hitEnt:Fire("Toggle", nil, 0)
         else
            return OPEN_NO
         end
      elseif openable == OPEN_BUT then
         if CrowbarCanUnlock(openable) then
            hitEnt:Fire("Unlock", nil, 0)
            hitEnt:Fire("Press", nil, 0)
         else
            return OPEN_NO
         end
      elseif openable == OPEN_NOTOGGLE then
         if CrowbarCanUnlock(openable) then
            hitEnt:Fire("Open", nil, 0)
         else
            return OPEN_NO
         end
      end
      return openable
   else
      return OPEN_NO
   end
end

function SWEP:PrimaryAttack()
   self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )

   local anim = "fists_right"
   local vm = self.Owner:GetViewModel()
   local owner = self.Owner

   if not IsValid(self.Owner) then return end

   if self.Owner.LagCompensation then -- for some reason not always true
      self.Owner:LagCompensation(true)
   end

   local spos = self.Owner:GetShootPos()
   local sdest = spos + (self.Owner:GetAimVector() * 70)

   local tr_main = util.TraceLine({start=spos, endpos=sdest, filter=self.Owner, mask=MASK_SHOT_HULL})
   local hitEnt = tr_main.Entity

   self.Weapon:EmitSound(sound_single)

   if IsValid(hitEnt) or tr_main.HitWorld then
      vm:SendViewModelMatchingSequence(vm:LookupSequence(anim))
      owner:ViewPunch( Angle( 4, 4, 0 ) )
      self.Owner:SetAnimation( PLAYER_ATTACK1 )
	  
	  self.Weapon:EmitSound(sound_open)

      if not (CLIENT and (not IsFirstTimePredicted())) then
         local edata = EffectData()
         edata:SetStart(spos)
         edata:SetOrigin(tr_main.HitPos)
         edata:SetNormal(tr_main.Normal)
         edata:SetSurfaceProp(tr_main.SurfaceProps)
         edata:SetHitBox(tr_main.HitBox)
         --edata:SetDamageType(DMG_CLUB)
         edata:SetEntity(hitEnt)

         if hitEnt:IsPlayer() or hitEnt:GetClass() == "prop_ragdoll" then
            util.Effect("BloodImpact", edata)

            -- does not work on players rah
            --util.Decal("Blood", tr_main.HitPos + tr_main.HitNormal, tr_main.HitPos - tr_main.HitNormal)

            -- do a bullet just to make blood decals work sanely
            -- need to disable lagcomp because firebullets does its own
            self.Owner:LagCompensation(false)
            self.Owner:FireBullets({Num=1, Src=spos, Dir=self.Owner:GetAimVector(), Spread=Vector(0,0,0), Tracer=0, Force=1, Damage=0})
         else
            util.Effect("Stunstickimpact", edata)
         end
      end
   else
      vm:SendViewModelMatchingSequence(vm:LookupSequence(anim))
      owner:ViewPunch( Angle( 4, 4, 0 ) )
      self.Owner:SetAnimation( PLAYER_ATTACK1 )
   end


   if CLIENT then
      -- used to be some shit here
   else -- SERVER

      -- Do another trace that sees nodraw stuff like func_button
      local tr_all = nil
      tr_all = util.TraceLine({start=spos, endpos=sdest, filter=self.Owner})

      if hitEnt and hitEnt:IsValid() then
         if self:OpenEnt(hitEnt) == OPEN_NO and tr_all.Entity and tr_all.Entity:IsValid() then
            -- See if there's a nodraw thing we should open
            self:OpenEnt(tr_all.Entity)
         end

         local dmg = DamageInfo()
         dmg:SetDamage(self.Primary.Damage)
         dmg:SetAttacker(self.Owner)
         dmg:SetInflictor(self.Weapon)
         dmg:SetDamageForce(self.Owner:GetAimVector() * 1500)
         dmg:SetDamagePosition(self.Owner:GetPos())
         dmg:SetDamageType(DMG_CLUB)

         hitEnt:DispatchTraceAttack(dmg, spos + (self.Owner:GetAimVector() * 3), sdest)

--         self.Weapon:SendWeaponAnim( ACT_VM_HITCENTER )         

--         self.Owner:TraceHullAttack(spos, sdest, Vector(-16,-16,-16), Vector(16,16,16), 30, DMG_CLUB, 11, true)
--         self.Owner:FireBullets({Num=1, Src=spos, Dir=self.Owner:GetAimVector(), Spread=Vector(0,0,0), Tracer=0, Force=1, Damage=20})
      
      else
--         if tr_main.HitWorld then
--            self.Weapon:SendWeaponAnim( ACT_VM_HITCENTER )
--         else
--            self.Weapon:SendWeaponAnim( ACT_VM_MISSCENTER )
--         end

         -- See if our nodraw trace got the goods
         if tr_all.Entity and tr_all.Entity:IsValid() then
            self:OpenEnt(tr_all.Entity)
         end
      end
   end

   if self.Owner.LagCompensation then
      self.Owner:LagCompensation(false)
   end
end


function SWEP:SecondaryAttack()

	if ( SERVER ) then
	
		if ( not self:CanSecondaryAttack() ) or self.Owner:IsOnGround() == false then return end
	
		local JumpSounds = { "npc/fast_zombie/leap1.wav", "npc/zombie/zo_attack2.wav", "npc/fast_zombie/fz_alert_close1.wav", "npc/zombie/zombie_alert1.wav" }
		self.SecondaryDelay = CurTime()+10
		self.Owner:SetVelocity( self.Owner:GetForward() * 200 + Vector(0,0,400) )
		self.Owner:EmitSound( JumpSounds[math.random(4)], 100, 100 )
		self:SetNextSecondaryFire( CurTime() + self.Secondary.Delay )
		
	end
end


--[[function SWEP:Reload()

	if ( SERVER ) then
		if self.NextReload > CurTime() then return end
	
		self.NextReload = CurTime() + 2
		local ply = self:GetOwner()
		if self.Nightvision == false then
			self.Nightvision = true
			net.Start( "AM_NightvisionOn" )
			net.WriteEntity( ply )
			net.Send( ply )
		elseif self.Nightvision == true then
			self.Nightvision = false
			net.Start( "AM_NightvisionOff" )
			net.WriteEntity( ply )
			net.Send( ply )
		end
	end
	
end]]--

function SWEP:Deploy()
  local vm = self.Owner:GetViewModel()
  vm:SendViewModelMatchingSequence( vm:LookupSequence( "fists_draw" ) )

	if ( SERVER ) then
		self.Owner.ShouldReduceFallDamage = true
		return true
	end
end

function SWEP:OnRemove()
	
	if ( SERVER ) then
	self.Nightvision = false
		if self.Nightvision == true then
			self.Nightvision = false
			local ply = self:GetOwner()
			net.Start( "AM_NightvisionOff" )
			net.WriteEntity( ply )
			net.Send( ply )
		end
	end
	
end


function SWEP:Holster()

	if ( SERVER ) then
		local ply = self:GetOwner()
		self.Nightvision = false
		net.Start( "AM_NightvisionOff" )
		net.WriteEntity( ply )
		net.Send( ply )
		self.Owner.ShouldReduceFallDamage = false
		return true
	end
	
end


if( CLIENT ) then

	net.Receive( "AM_NightvisionOn", function ( len, ply )
		local ply = net.ReadEntity()
		am_nightvision = DynamicLight( 0 )
		if ( am_nightvision ) then
			halosdgj = true
			am_nightvision.Pos = ply:GetPos()
			am_nightvision.r = 11
			am_nightvision.g = 50
			am_nightvision.b = 4
			am_nightvision.Brightness = 1
			am_nightvision.Size = 2000
			am_nightvision.DieTime = CurTime()+100000
			am_nightvision.Style = 1
		end
		timer.Create( "AM_LightTimer", 0.05, 0, function()
			am_nightvision.Pos = ply:GetPos()
		end)
	hook.Add( "PreDrawHalos", "AddHalos", function()
	local staff = {}

	for k, v in pairs( player.GetAll() ) do
	if v:Alive() and v:GetRole() ~= ROLE_INFECTED then
			table.insert( staff, v )
	end
	end
		
if halosdgj == true then
	halo.Add( staff, Color( 255, 0, 0 ), 0, 0, 2, true, true )
end
	
end )
	end)
	
	net.Receive( "AM_NightvisionOff", function ( len, ply )
		local ply = net.ReadEntity()
		timer.Destroy( "AM_LightTimer" )
		if am_nightvision then
			halosdgj = false
			am_nightvision.DieTime = CurTime()+0.1
		end
	end)

end
