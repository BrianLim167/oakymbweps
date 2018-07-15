-- Custom TTT weapon base heavily derived from the original TTT base.
-- This is meant only for guns.
-- Aims to change recoil mechanics a bit. As such, most of the parameters
-- do not have comments and instead you can refer to the original code in the TTT base for that.

AddCSLuaFile()

SWEP.Kind = WEAPON_NONE
SWEP.CanBuy = nil

if CLIENT then
   SWEP.EquipMenuData = nil
   SWEP.Icon = "vgui/ttt/icon_nades"
end

SWEP.AutoSpawnable = false
SWEP.AllowDrop = true
SWEP.IsSilent = false

if CLIENT then
   SWEP.DrawCrosshair   = false
   SWEP.ViewModelFOV    = 82
   SWEP.ViewModelFlip   = true
   SWEP.CSMuzzleFlashes = true
end

SWEP.Base = "weapon_ttt_main_base"

function IsLocal()
	local test = false
	return test or ((game.SinglePlayer() and SERVER) or
	((not game.SinglePlayer()) and CLIENT))
end

function SWEP:SetupDataTables()
	self:SetupDataTablesBase()
end

function SWEP:SetupDataTablesBase()
	if self.SetupDataTablesMain then self:SetupDataTablesMain() end
	self:NetworkVar( "Float", 0, "Bloom"		)
	self:NetworkVar( "Float", 1, "AimPunch"		)
	self:NetworkVar( "Float", 2, "AimY"			)
	self:NetworkVar( "Float", 3, "AimX"			)
	self:NetworkVar( "Angle", 0, "AimAngles"	)
	
   self:NetworkVar("Bool", 3, "Ironsights")
	
	self:ResetData()
end

function SWEP:ResetData()
	self:SetBloom(0)
	self:SetAimPunch(0)
	self:SetAimY(0)
	self:SetAimX(0)
	self:SetAimAngles( Angle( 0, 0, 0 ) )
end

SWEP.Category           = "TTT Brekiy" -- Custom category for a custom base
SWEP.Spawnable          = false

SWEP.Weight             = 5
SWEP.AutoSwitchTo       = false
SWEP.AutoSwitchFrom     = false

SWEP.IsLooted			= false

SWEP.ShortLightBrightness = 1
SWEP.LongLightBrightness = -1

SWEP.Penetration = 100
SWEP.Primary.Sound          = Sound( "Weapon_Pistol.Empty" )
SWEP.Primary.Recoil         = 1.5
SWEP.Primary.Damage         = 1
SWEP.Primary.NumShots       = 1
SWEP.Primary.Cone           = 0.02
SWEP.Primary.Delay          = 0.15

SWEP.Primary.ClipSize       = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Automatic      = false
SWEP.Primary.Ammo           = "none"
SWEP.Primary.ClipMax        = -1

SWEP.Secondary.ClipSize     = 1
SWEP.Secondary.DefaultClip  = 1
SWEP.Secondary.Automatic    = false
SWEP.Secondary.Ammo         = "none"
SWEP.Secondary.ClipMax      = -1
--SWEP.ShellLoad 				 = false

SWEP.CrouchBonus 				 = 0.7
SWEP.MovePenalty			 	 = 2
SWEP.JumpPenalty			 	 = 3
SWEP.MaxCone 					 = 0.06

SWEP.AimPatternX 		= function(t)
		return 0.01 * t * math.sin(0.8 * t)
	end
SWEP.AimPatternY 		= function(t)
		return 0.375 * t
	end
SWEP.BloomRecoverRate 	= 0.005
SWEP.AimRecoverRate		= 0.35
SWEP.AimKick			= 0
SWEP.Primary.ShoveY         = 0.01
SWEP.Primary.ShoveX         = 0.2

--SWEP.Penetration 						= 0
--work on this later
function SWEP:BulletPenetrate(hitNum, attacker, tr, dmginfo)
	if true then return end
	print("BulletPenetrate funct")
	print("hitNum: ", hitNum, "penetration power: ", self.Penetration)
	local penetrate = self.Penetration
	local dmgMult = 1
	
	-- Prevent the bullet from going through more than 2 surfaces
	-- This is for performance and shit
	if(hitNum > 2) then 
		print("Bullet hit too many surfaces") 
		return false 
	end
	
	-- The bullet can penetrate different amounts of material
	-- and takes a damage penalty according to the material
	if (tr.MatType == MAT_METAL or tr.MatType == MAT_VENT or 
		tr.MatType == MAT_COMPUTER or tr.MatType == MAT_GRATE) then
		penetrate = penetrate * 0.3
		dmgMult = 0.3
	elseif (tr.MatType == MAT_CONCRETE) then
		penetrate = penetrate * 0.5
		dmgMult = 0.5
	elseif(tr.MatType == MAT_DIRT or tr.MatType == MAT_TILE or tr.MatType == MAT_SAND) then
		penetrate = penetrate * 0.7
		dmgMult = 0.7
	elseif (tr.MatType == MAT_PLASTIC or tr.MatType == MAT_WOOD) then
		penetrate = penetrate * 0.85
		dmgMult = 0.85
	end
	print("Penetration calculated: ", penetrate, " units")
	print("Dmg and mult:", self.Primary.Damage, dmgMult)
	print(tr.Normal)
	local penVec = tr.Normal * penetrate * 2 -- Penetration vector
	local penTrace = {}
	penTrace.endpos = tr.HitPos
	penTrace.start = tr.HitPos + penVec
	penTrace.filter = {}
	penTrace.mask = MASK_SHOT
	local penTraceLine = util.TraceLine(penTrace)
	print("Trace created")
	
	if (penTraceLine.StartSolid or penTraceLine.Fraction >= 1.0 or tr.Fraction <= 0.0) then 
		print("Bullet did not penetrate!")
		--return false 
	end
	
	local newHit = 0
	if(tr.MatType == MAT_GLASS) then newHit = 1 end
	
	print("Making penetrated shot")
	
	local exitShot = {}
	exitShot.Num = 1
	exitShot.src = penTraceLine.HitPos --+ penVec
	exitShot.dir = -penTraceLine.Normal
	exitShot.spread = Vector(0, 0, 0)
	exitShot.dmg = self.Primary.Damage * dmgMult
	exitShot.force = self.Primary.Damage * dmgMult * 0.4
	exitShot.Tracer = 1
	exitShot.tracerName = "AR2Tracer"
	if(SERVER) then
		exitShot.Callback = function( attacker, tr, dmginfo)
			self:Callback( attacker, tr, dmginfo )
			self:BulletPenetrate(hitNum + newHit, attacker, tr, dmginfo)
		end
	end
	print("Bullet penetrated")
	attacker:FireBullets(exitShot)
	print("exitShot fired")
end 

function SWEP:SecondaryAttack()
   if self.NoSights or (not self.IronSightsPos) then return end
   --if self:GetNextSecondaryFire() > CurTime() then return end

   self:SetIronsights(not self:GetIronsights())

   self:SetNextSecondaryFire(CurTime() + 0.3)
end

function SWEP:SetZoom(state)
end

-- Hollow Rating Damage
function SWEP:HollowDamageTarget( att, path, dmginfo )
	if not IsValid(path) then return 0 end
	local ent = path.Entity
	if not IsValid(ent) then return 0 end
	
	if SERVER then
		if ent:IsPlayer() and GAMEMODE:AllowPVP() then
			local rating = self.Primary.HollowRating or ent:GetMaxHealth() or 1000
			local dmg = math.floor( (ent:GetMaxHealth() - ent:Health()) / rating )
		end
	end
	return hollow_dmg
end

function SWEP:PrimaryAttack(worldsnd)
	self:PrimaryAttackBase(worldsnd)

	self:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
	self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
end

function SWEP:PrimaryAttackBase(worldsnd)
   if not self:CanPrimaryAttack() then return end

   if not worldsnd then
      self:EmitSound( self.Primary.Sound, self.Primary.SoundLevel )
   elseif SERVER then
      sound.Play(self.Primary.Sound, self:GetPos(), self.Primary.SoundLevel)
   end

   self:ShootBullet(self.Primary.Damage, self.Primary.Recoil, self.Primary.NumShots, self:GetPrimaryCone())

   self:TakePrimaryAmmo( 1 )

   local owner = self.Owner
   if not IsValid(owner) or owner:IsNPC() or (not owner.ViewPunch) then return end
   
   self:SetAimPunch( self:GetAimPunch() + 1 )
	--if CLIENT then self.Owner:PrintMessage(HUD_PRINTTALK, tostring( self:GetAimPunch() ) .. " " .. tostring( 30-self:Clip1() ) ) end
   self:SetBloom( self:GetBloom() + self.Primary.Recoil )
   if self:GetBloom() < -self.Primary.Cone then
		self:SetBloom( -self.Primary.Cone )
	end
end

function SWEP:ShootBullet( dmg, recoil, numbul, cone )
   self:SendWeaponAnim(self.PrimaryAnim)

   self.Owner:MuzzleFlash()
   self.Owner:SetAnimation( PLAYER_ATTACK1 )

   if not IsFirstTimePredicted() then return end

   local sights = self:GetIronsights()

   numbul = numbul or 1
   cone   = cone   or 0.01
	
	local bulletAng = self.Owner:EyeAngles() + self:GetAimAngles()
   local bullet = {}
   bullet.Num    = numbul
   bullet.Src    = self.Owner:GetShootPos()
   bullet.Dir    = bulletAng:Forward()
   bullet.Spread = Vector( cone, cone, 0 )
   bullet.Tracer = 4
   bullet.TracerName = self.Tracer or "Tracer"
   bullet.Force  = dmg * 0.4
   bullet.Damage = dmg + self:HollowDamageTarget( attacker, tr, dmginfo )
   bullet.Callback = function( attacker, tr, dmginfo)
		self:Callback( attacker, tr, dmginfo )
		self:BulletPenetrate(0, attacker, tr, dmginfo)
	end
	self.Owner:FireBullets( bullet )

   -- Owner can die after firebullets
	   
	self:ShootBulletBase( dmg, recoil, numbul, cone )
end

function SWEP:Callback( attacker, tr, dmginfo )
end

function SWEP:ShootBulletBase( dmg, recoil, numbul, cone )
   if (not IsValid(self.Owner)) or (not self.Owner:Alive()) or self.Owner:IsNPC() then return end
	
	if ((game.SinglePlayer() and SERVER) or
       ((not game.SinglePlayer()) and CLIENT and IsFirstTimePredicted())) then
	   
	   local ShortLightBrightness = (self.Owner == LocalPlayer() and -0 or 0) + self.ShortLightBrightness
	   local LongLightBrightness = (self.Owner == LocalPlayer() and -0 or 0) + self.LongLightBrightness
	   local ShortRange = (self.Owner == LocalPlayer() and -0 or 0) + 250
	   local LongRange = (self.Owner == LocalPlayer() and -0 or 0) + 600
	   
		local rh = self.Owner:LookupAttachment("anim_attachment_RH")
		local rhposang = self.Owner:GetAttachment(rh)
		local shortlight = DynamicLight( self:EntIndex() )
		if ( shortlight ) then
			shortlight.pos = rhposang.Pos + rhposang.Ang:Forward()*self:OBBMaxs().x
			shortlight.r = 200
			shortlight.g = 160
			shortlight.b = 80
			shortlight.brightness = ShortLightBrightness
			shortlight.Decay = 250
			shortlight.Size = ShortRange
			shortlight.DieTime = CurTime() + 0.04
			shortlight.style = 0
		end
		--local longlight = DynamicLight( self:EntIndex() )
		if ( longlight ) then
			longlight.pos = rhposang.Pos + rhposang.Ang:Forward()*self:OBBMaxs().x
			longlight.r = 255
			longlight.g = 180
			longlight.b = 25
			longlight.brightness = LongLightBrightness
			longlight.Decay = 250
			longlight.Size = LongRange
			longlight.DieTime = CurTime() + 0.04
			longlight.style = 0
		end
	
		local eyeang
		eyeang = self.Owner:EyeAngles()
		eyeang.pitch = eyeang.pitch - (math.Rand(self.AimKick / 2, self.AimKick))
		eyeang.yaw = eyeang.yaw - (math.Rand(-self.AimKick / 4, self.AimKick / 4))
		self.Owner:SetEyeAngles(eyeang)
	end
	
	local dy = self.AimPatternY(self:GetAimPunch()+1) - self.AimPatternY(self:GetAimPunch())
	local dx = self.AimPatternX(self:GetAimPunch()+1) - self.AimPatternX(self:GetAimPunch())
	
	local aimy = self:GetAimY()+dy
	local aimx = self:GetAimX()+dx
	
	self:SetAimY(aimy)
	self:SetAimX(aimx)
	
	self.Owner:ViewPunch( -(self.Owner:GetViewPunchAngles()+0.25*(Angle(aimy,aimx,0))) )
	self.Owner:ViewPunch( Angle(self.Primary.ShoveY*math.Rand(-1,1), self.Primary.ShoveX*math.Rand(-1,1), 0) )
end

function SWEP:GetPrimaryCone()
   local cone = (self.Primary.Cone or 0.2) + (self:GetBloom() or 0.0)
   cone = math.max(0.001, cone)
	cone = cone + ((self.MovePenalty / 100) * self.Owner:GetVelocity():Length()*cone)
	if self.Owner:Crouching() then cone = cone * self.CrouchBonus end
	if !self.Owner:IsOnGround() then cone = cone * (self.JumpPenalty + 1) end
	if self:GetIronsights() then cone = cone * (self.IronSightsConeMultiplier or 0.7) end
	if self.MaxCone < cone then cone = self.MaxCone end
   return cone
end

function SWEP:GetHeadshotMultiplier(victim, dmginfo)
   return self.HeadshotMultiplier
end

function SWEP:AimPunchEvent()
	if (not IsValid(self.Owner)) or (not self.Owner:Alive()) then return end
	
	if self.Primary.Recoil >= 0 then
		self:SetBloom( math.max( 0, self:GetBloom() - self.BloomRecoverRate ) )
	else
		self:SetBloom( math.min( 0, self:GetBloom() + self.BloomRecoverRate ) )
	end
	
	local aimy = self:GetAimY()
	local aimx = self:GetAimX()
	local aimr = math.sqrt( math.pow(aimy, 2), math.pow(aimx, 2) )
	
	
	-- 
	if aimr > 0 then
		
		self:SetAimPunch( math.max( 0, self:GetAimPunch() * (1 - self.AimRecoverRate/aimr) ) )
		
		local aimynew = aimy - self.AimRecoverRate * (aimy/aimr) 
		local aimxnew = aimx - self.AimRecoverRate * (aimx/aimr) 
		if aimynew > 0 then
			aimy = aimynew
			aimx = aimxnew
		else
			aimy = 0
			aimx = 0
			self.Owner:SetViewPunchAngles( Angle(0,0,0) )
		end
	end
	self:SetAimY(aimy)
	self:SetAimX(aimx)
	self:SetAimAngles(Angle(-aimy,-aimx,0))
	
	self.aimy = aimy
	self.aimx = aimx
	
end

function SWEP:Reload()
    if (self:Clip1() == self.Primary.ClipSize or
        self.Owner:GetAmmoCount(self.Primary.Ammo) <= 0) then
       return
    end
    self:DefaultReload(ACT_VM_RELOAD)
    self:SetIronsights(false)
    self:SetZoom(false)
	self:ResetData()
end

function SWEP:Holster()
   self:SetIronsights( false )
   self:SetZoom( false )
   return true
end

function SWEP:Think()
	self:ThinkBase()
end

function SWEP:ThinkBase()
	if (not IsValid(self.Owner)) or (not self.Owner:Alive()) or self.Owner:IsNPC() then return end
	self:AimPunchEvent()
		
	--local inaccMult = 1 + self.Owner:GetWalkSpeed() * 0.75
end