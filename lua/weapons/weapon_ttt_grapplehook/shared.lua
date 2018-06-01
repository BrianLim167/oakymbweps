SWEP.Author                     = "Therius"
SWEP.Contact            = "codystep09@gmail.com"
SWEP.Purpose            = "Pull yourself to heaven's heights."
SWEP.Instructions       = "Left click to fire"
 
SWEP.PrintName    = "Grappling Hook"
 
SWEP.Spawnable                  = true
SWEP.AdminSpawnable             = false
if CLIENT then
 
   SWEP.Slot         = 6
 
   SWEP.ViewModelFlip = false
 
   SWEP.EquipMenuData = {
      type = "item_weapon",
      desc = "Hook onto buildings and climb to your heart's \ncontent!"
   };
 
   SWEP.Icon = "lks/icon_lks_crossbow.png"
end
 
if SERVER then
   resource.AddFile("materials/lks/icon_lks_crossbow.png")
end
 
SWEP.SlotPos                    = 0
SWEP.DrawAmmo                   = true
SWEP.DrawCrosshair              = true
SWEP.ViewModel                  = "models/weapons/v_crossbow.mdl"
SWEP.WorldModel                 = "models/weapons/w_crossbow.mdl"
 
SWEP.Primary.ClipSize = 100
SWEP.Primary.DefaultClip    = 100
SWEP.Primary.ClipMax = 101
SWEP.Primary.Ammo       = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo       = "none"
 
SWEP.Kind = WEAPON_EQUIP
SWEP.CanBuy = {ROLE_DETECTIVE} -- only detectives can buy
SWEP.LimitedStock = false -- only buyable once
SWEP.WeaponID = AMMO_GRAPPLE
 
local sndPowerUp                = Sound("weapons/crossbow/hit1.wav")
local sndPowerDown              = Sound("Airboat.FireGunRevDown")
local sndTooFar                 = Sound("buttons/button10.wav")
 
function SWEP:IsEquipment() return true end
 
function SWEP:Initialize()
 
        //self:SetClip1( 100 )
        nextshottime = CurTime()
        self:SetWeaponHoldType( "smg" )
        self.zoomed = false
       
end
 
function SWEP:Think()
 
        if (!self.Owner || self.Owner == NULL) then return end
		if (not IsValid(self.Owner)) or (not self.Owner:Alive()) or self.Owner:IsNPC() then return end
       
        if ( self.Owner:KeyPressed( IN_ATTACK ) ) then
       
                self:StartAttack()
               
        elseif ( self.Owner:KeyDown( IN_ATTACK ) && inRange ) then
       
                self:UpdateAttack()
               
        elseif ( self.Owner:KeyReleased( IN_ATTACK ) && inRange && self:Clip1() > 0 ) then
       
                self:EndAttack( false )
       
        end
 
end
 
function SWEP:Deploy()
        self:EndAttack()
end
 
function SWEP:GetIronsights() return false end
 
function SWEP:DoTrace( endpos )
        local trace = {}
                trace.start = self.Owner:GetShootPos()
                trace.endpos = trace.start + (self.Owner:GetAimVector() * 14096) --14096 is length modifier.
                if(endpos) then trace.endpos = (endpos - self.Tr.HitNormal * 7) end
                trace.filter = { self.Owner, self.Weapon }
               
        self.Tr = nil
        self.Tr = util.TraceLine( trace )
end
 
function SWEP:StartAttack()
        if not (self:Clip1() > 0) then return end
                if IsValid( self.Owner ) then timer.Destroy( "GrapplingAmmoTickUp" .. self.Owner:SteamID() ) end
        -- Get begining and end poins of trace.
        local gunPos = self.Owner:GetShootPos() -- Start of distance trace.
        local disTrace = self.Owner:GetEyeTrace() -- Store all results of a trace in disTrace.
        local hitPos = disTrace.HitPos -- Stores Hit Position of disTrace.
       
        -- Calculate Distance
        -- Thanks to rgovostes for this code.
        local x = (gunPos.x - hitPos.x)^2;
        local y = (gunPos.y - hitPos.y)^2;
        local z = (gunPos.z - hitPos.z)^2;
        local distance = math.sqrt(x + y + z);
       
        -- Only latches if distance is less than distance CVAR, or CVAR negative
        local distanceCvar = GetConVarNumber("grapple_distance")
        inRange = false
        if distanceCvar < 0 or distance <= distanceCvar then
                inRange = true
        end
       
        if inRange then
                if (SERVER) then
                       
                        timer.Create( "GrapplingAmmoTick" .. self.Owner:SteamID(), 0.2, 0, function()
                                if IsValid( self ) and self:Clip1() <= 0 then
                                        self:EndAttack(true)
                                        if self.Beam then self.Beam:Remove() end
                                        self.Beam = nil
                                elseif IsValid( self ) then
                                        self:TakePrimaryAmmo(2)
                                end
                        end )
                       
                        if (!self.Beam) then -- If the beam does not exist, draw the beam.
                                -- grapple_beam
                                self.Beam = ents.Create( "trace1" )
                                        self.Beam:SetPos( self.Owner:GetShootPos() )
                                self.Beam:Spawn()
                        end
                       
                        self.Beam:SetParent( self.Owner )
                        self.Beam:SetOwner( self.Owner )
               
                end
               
                self:DoTrace()
                self.speed = 10000 -- Rope latch speed. Was 3000.
                self.startTime = CurTime()
                self.endTime = CurTime() + self.speed
                self.dt = -1
               
                if (SERVER && self.Beam) then
                        self.Beam:GetTable():SetEndPos( self.Tr.HitPos )
                end
               
                self:UpdateAttack()
               
                self.Weapon:EmitSound( sndPowerUp )
        else
                -- Play a sound
                self.Weapon:EmitSound( sndPowerUp )
        end
end
 
function SWEP:UpdateAttack()
        if not (self:Clip1() > 0) then
                if self.Beam then self.Beam:Remove() end
                self.Beam = nil
                self:EndAttack( true )
                return
        end
        self.Owner:LagCompensation( true )
       
        if (!endpos) then endpos = self.Tr.HitPos end
       
        if (SERVER && self.Beam) then
                self.Beam:GetTable():SetEndPos( endpos )
        end
 
        lastpos = endpos
       
       
                        if ( self.Tr.Entity:IsValid() ) then
                       
                                        endpos = self.Tr.Entity:GetPos()
                                        if ( SERVER ) then
                                        self.Beam:GetTable():SetEndPos( endpos )
                                        end
                       
                        end
                       
                        local vVel = (endpos - self.Owner:GetPos())
                        local Distance = endpos:Distance(self.Owner:GetPos())
                       
                        local et = (self.startTime + (Distance/self.speed))
                        if(self.dt != 0) then
                                self.dt = (et - CurTime()) / (et - self.startTime)
                        end
                        if(self.dt < 0) then
                                self.Weapon:EmitSound( sndPowerUp )
                                self.dt = 0
                        end
                       
                        if(self.dt == 0) then
                        zVel = self.Owner:GetVelocity().z
                        vVel = vVel:GetNormalized()*(math.Clamp(Distance,0,7))
                                if( SERVER ) then
                                local gravity = GetConVarNumber("sv_Gravity")
                                vVel:Add(Vector(0,0,(gravity/100)*1.5)) -- Player speed. DO NOT MESS WITH THIS VALUE!
                                if(zVel < 0) then
                                        vVel:Sub(Vector(0,0,zVel/100))
                                end
                                self.Owner:SetVelocity(vVel)
                                end
                        end
       
        endpos = nil
       
        self.Owner:LagCompensation( false )
       
end
 
function SWEP:EndAttack( delay )       
       
        local delay = delay or false
        if self.Owner and IsValid( self.Owner ) and self.Owner:SteamID() then
                timer.Destroy( "GrapplingAmmoTick" .. self.Owner:SteamID() )
                if delay == true then
                        timer.Create( "GrapplingAmmoTickDelay" .. self.Owner:SteamID(), 3, 1, function()
                                timer.Create( "GrapplingAmmoTickUp" .. self.Owner:SteamID(), 0.33, 0, function()
                                        if IsValid( self ) and self:Clip1() < 100 then self:SetClip1( self:Clip1() + 1 ) end
                                end )
                        end )
                else
                        timer.Destroy( "GrapplingAmmoTickDelay" )
                        timer.Create( "GrapplingAmmoTickUp" .. self.Owner:SteamID(), 0.33, 0, function()
                                if IsValid( self ) and self:Clip1() < 100 then self:SetClip1( self:Clip1() + 1 ) end
                        end )
                end
        end
       
        if ( CLIENT ) then return end
        if ( !self.Beam ) then return end
       
        if IsValid( self ) and self.Beam then self.Beam:Remove() end
        self.Beam = nil
       
end
 
function SWEP:Holster()
        self:EndAttack( false )
        if IsValid( self.Owner ) then timer.Destroy( "GrapplingAmmoTickUp" .. self.Owner:SteamID() ) end
        return true
end
 
function SWEP:OnDrop()
        self:EndAttack( false )
        if IsValid( self.Owner ) then timer.Destroy( "GrapplingAmmoTickUp" .. self.Owner:SteamID() ) end       
end
 
function SWEP:OnRemove()
        self:EndAttack( false )
        if IsValid( self.Owner ) then timer.Destroy( "GrapplingAmmoTickUp" .. self.Owner:SteamID() ) end
        return true
end
 
function SWEP:DampenDrop()
   -- For some reason gmod drops guns on death at a speed of 400 units, which
   -- catapults them away from the body. Here we want people to actually be able
   -- to find a given corpse's weapon, so we override the velocity here and call
   -- this when dropping guns on death.
   local phys = self:GetPhysicsObject()
   if IsValid(phys) then
      phys:SetVelocityInstantaneous(Vector(0,0,-75) + phys:GetVelocity() * 0.001)
      phys:AddAngleVelocity(phys:GetAngleVelocity() * -0.99)
   end
end
 
function SWEP:PrimaryAttack()
end
 
function SWEP:SecondaryAttack()
end