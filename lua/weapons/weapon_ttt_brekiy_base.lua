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
function SWEP:BulletPenetrate(hitNum, bul, attacker, tr, dmginfo)
	if (bul.Damage <= 1) then return false end
	if (hitNum > 16) then return false end

	--multiplier for bullet damage upon impact with material
	matImpactMul = {
	[MAT_METAL] =		0.8,
	[MAT_VENT] =		0.8,
	[MAT_GRATE] =		0.8,
	[MAT_COMPUTER] =	0.8,
	[MAT_CONCRETE] =	0.85,
	[MAT_FLESH] =		0.9,
	[MAT_DIRT] =		0.9,
	[MAT_GRASS] =		0.9,
	[MAT_TILE] =		0.9,
	[MAT_SAND] =		0.9,
	[MAT_PLASTIC] =		0.95,
	[MAT_WOOD] =		0.95,
	[MAT_GLASS] =		1,
	}
	
	--material's resistance to a penetrating bullet
	matResistance = {
	[MAT_METAL] =		0.2,
	[MAT_VENT] =		0.2,
	[MAT_GRATE] =		0.2,
	[MAT_COMPUTER] =	0.95,
	[MAT_CONCRETE] =	0.1,
	[MAT_FLESH] =		0.05,
	[MAT_DIRT] =		0.05,
	[MAT_GRASS] =		0.05,
	[MAT_TILE] =		0.04,
	[MAT_SAND] =		0.03,
	[MAT_PLASTIC] =		0.02,
	[MAT_WOOD] =		0.05,
	[MAT_GLASS] =		0.02,
	}
	
	matDecal = {
	[MAT_METAL] =		"Impact.Metal",
	[MAT_VENT] =		"Impact.Metal",
	[MAT_GRATE] =		"Impact.Metal",
	[MAT_COMPUTER] =	"Impact.Metal",
	[MAT_CONCRETE] =	"Impact.Concrete",
	[MAT_FLESH] =		"Blood",
	[MAT_DIRT] =		"ExplosiveGunshot",
	[MAT_GRASS] =		"ExplosiveGunshot",
	[MAT_TILE] =		"ExplosiveGunshot",
	[MAT_SAND] =		"Impact.Sand",
	[MAT_PLASTIC] =		"ExplosiveGunshot",
	[MAT_WOOD] =		"Impact.Wood",
	[MAT_GLASS] =		"Impact.Glass",
	}
	
	local dmgImpactMul = matImpactMul[tr.MatType] or 0.95
	local dmgResistance = matResistance[tr.MatType] or 0.05
	
	local aimNorm = (tr.HitPos - tr.StartPos):GetNormalized()
	if (!aimNorm or aimNorm == Vector(0,0,0)) then aimNorm = bul.Dir end
	local pen = bul.Damage * dmgImpactMul / dmgResistance
	local penVec = aimNorm * pen -- Penetration vector
	local penTraceLine = {}
	
	if (tr.HitWorld) then
		local penTrace = {}
		penTrace.start = tr.HitPos + aimNorm
		penTrace.endpos = penTrace.start + penVec
		penTrace.filter = game:GetWorld()
		penTraceLine = util.TraceLine(penTrace)
		if (penTraceLine.FractionLeftSolid != 1) then
			penTraceLine.HitPos = penTraceLine.StartPos + penTraceLine.FractionLeftSolid * (penTraceLine.HitPos - penTraceLine.StartPos)
		end
		local penDist = 1
		
		-- static props are considered part of the world, but don't behave well with FractionLeftSolid, so they have to be traced manually
		while (penTraceLine.Entity == game.GetWorld() and penTraceLine.FractionLeftSolid == 0 and penTraceLine.StartSolid and penTraceLine.AllSolid and penDist < pen) do
			penTrace.start = penTraceLine.HitPos + aimNorm
			penTrace.endpos = penTraceLine.HitPos
			penTraceLine = util.TraceLine(penTrace)
			if (penTraceLine.FractionLeftSolid != 1) then
				penTraceLine.HitPos = penTraceLine.StartPos + penTraceLine.FractionLeftSolid * (penTraceLine.HitPos - penTraceLine.StartPos)
			end
			penDist = penDist + 1
		end
		
	elseif (tr.Entity) then
		local outsideTrace = {}
		outsideTrace.start = tr.HitPos + aimNorm
		outsideTrace.endpos = outsideTrace.start + penVec
		outsideTrace.filter = tr.Entity
		local outsideTraceLine = util.TraceLine(outsideTrace)
		local penTrace = {}
		penTrace.start = outsideTraceLine.HitPos - aimNorm
		penTrace.endpos = tr.HitPos
		penTraceLine = util.TraceLine(penTrace)
	else
		return
	end
	penTraceLine.HitPos = penTraceLine.HitPos + aimNorm
	
	
	print(penTraceLine.Entity)
	--print(penTraceLine.HitPos - tr.HitPos)
	print(penTraceLine.Fraction)
	--print(penTraceLine.FractionLeftSolid)
	--print(penTraceLine.AllSolid)
	--print(penTraceLine.StartSolid)
	print((penTraceLine.HitPos - tr.HitPos):Length())
	print("--------------------------")
	
	
	local checkMat = {}
	checkMat.start = penTraceLine.HitPos
	checkMat.endpos = tr.HitPos
	checkMat.filter = {}
	checkMat.mask = MASK_SHOT
	local checkMatLine = util.TraceLine(checkMat)
	checkMatLine.MatType = checkMatLine.MatType or tr.MatType
	
	
	local exitShot = {}
	exitShot.Num = 1
	exitShot.Src = penTraceLine.HitPos
	exitShot.Dir = aimNorm
	exitShot.Spread = Vector(0, 0, 0)
	dmgImpactMul = matImpactMul[checkMatLine.MatType] or 0.95
	dmgResistance = matResistance[checkMatLine.MatType] or 0.05
	exitShot.Damage = bul.Damage * dmgImpactMul - (penTraceLine.HitPos - tr.HitPos):Length() * dmgResistance
	if (exitShot.Damage < 1) then return end
	exitShot.Force = 0.4 * exitShot.Damage
	exitShot.Tracer = self.TracerFrequency or 4
	exitShot.TracerName = self.Tracer or "Tracer"
	if tr.Entity and !tr.Entity:IsWorld() then exitShot.IgnoreEntity = tr.Entity end
	exitShot.Callback = function( attacker, callback_tr, dmginfo)
		self:Callback( attacker, callback_tr, dmginfo )
		self:BulletPenetrate(hitNum + 1, exitShot, attacker, callback_tr, dmginfo)
	end
	attacker:FireBullets(exitShot)
	
	if CLIENT then
		util.Decal( matDecal[checkMatLine.MatType] or "ExplosiveGunshot", penTraceLine.HitPos, tr.HitPos )
	end
end 

function SWEP:SecondaryAttack()
   if self.NoSights or (not self.IronSightsPos) then return end
   if self:GetNextSecondaryFire() > CurTime() then return end

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
	
	local hollow_dmg = 0
	
	if SERVER then
		if ent:IsPlayer() and GAMEMODE:AllowPVP() then
			local rating = self.Primary.HollowRating or ent:GetMaxHealth() or 1000
			hollow_dmg = math.floor( (ent:GetMaxHealth() - ent:Health()) / rating )
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

   self:ShootBullet(self.Primary.Damage + self:HollowDamageTarget( attacker, tr, dmginfo ),
					self.Primary.Recoil, self.Primary.NumShots, self:GetPrimaryCone())

   self:TakePrimaryAmmo( 1 )

   local owner = self.Owner
   if not IsValid(owner) or owner:IsNPC() or (not owner.ViewPunch) then return end
   
   self:SetAimPunch( self:GetAimPunch() + 1 )
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
	
	for i=1,numbul do
		local bulletAng = self.Owner:EyeAngles() + self:GetAimAngles()
		local dir = (bulletAng+ Angle(cone*360/math.pi*(math.random()-0.5),cone*360/math.pi*(math.random()-0.5),0)):Forward()
	   local bullet = {}
	   bullet.Num    = 1
	   bullet.Src    = self.Owner:GetShootPos()
	   bullet.Dir    = dir:GetNormalized()
	   bullet.Spread = Vector(0,0,0)--Vector( cone, cone, 0 )
	   bullet.Tracer = self.TracerFrequency or 4
	   bullet.TracerName = self.Tracer or "Tracer"
	   bullet.Force  = dmg * 0.4
	   bullet.Damage = dmg
	   bullet.Callback = function( attacker, tr, dmginfo)
			self:Callback( attacker, tr, dmginfo )
			self:BulletPenetrate(0, bullet, attacker, tr, dmginfo)
		end
		self.Owner:FireBullets( bullet )
	end

   -- Owner can die after firebullets
	   
	self:ShootBulletBase( dmg, recoil, numbul, cone )
end

function SWEP:Callback( attacker, tr, dmginfo )
end

function SWEP:ShootBulletBase( dmg, recoil, numbul, cone )
   if (not IsValid(self.Owner)) or (not self.Owner:Alive()) or self.Owner:IsNPC() then return end
	
	if ((game.SinglePlayer() and SERVER) or
       ((not game.SinglePlayer()) and CLIENT and IsFirstTimePredicted())) then
	   
	   --local ShortLightBrightness = (self.Owner == LocalPlayer() and -0 or 0) + self.ShortLightBrightness
	   --local LongLightBrightness = (self.Owner == LocalPlayer() and -0 or 0) + self.LongLightBrightness
	   --local ShortRange = (self.Owner == LocalPlayer() and -0 or 0) + 250
	   --local LongRange = (self.Owner == LocalPlayer() and -0 or 0) + 600
	   local ShortLightBrightness = self.ShortLightBrightness
	   local LongLightBrightness = self.LongLightBrightness
	   local ShortRange = 250
	   local LongRange = 600
	   
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
	
	self.Owner:ViewPunch( -(self.Owner:GetViewPunchAngles()+0.35*(Angle(aimy,aimx,0))) )
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