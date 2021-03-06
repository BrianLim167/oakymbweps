if SERVER then
	AddCSLuaFile()
	resource.AddFile( "sound/weapons/ree/kslh/ak47_boltpull.wav" )
	resource.AddFile( "sound/weapons/ree/kslh/ak47_clipin.wav" )
	resource.AddFile( "sound/weapons/ree/kslh/ak47_clipout.wav" )
	resource.AddFile( "models/weapons/v_rif_ree_kslh.mdl" )
	resource.AddFile( "models/weapons/w_rif_ree_kslh47.mdl" )
	resource.AddFile( "materials/vgui/ttt/lykrast/icon_ap_golddragon.vmt" )
	resource.AddFile( "materials/vgui/ttt/lykrast/icon_ap_golddragon.vtf" )
	resource.AddFile( "materials/models/weapons/w_models/cf_ak47-beast/pv_ak47-beast.vmt" )
	resource.AddFile( "materials/models/weapons/v_models/cf_ak47-beast/eye.vmt" )
	resource.AddFile( "materials/models/weapons/v_models/cf_ak47-beast/eye.vtf" )
	resource.AddFile( "materials/models/weapons/v_models/cf_ak47-beast/pv_ak47-beast.vmt" )
	resource.AddFile( "materials/models/weapons/v_models/cf_ak47-beast/pv_ak47-beast.vtf" )
	resource.AddFile( "materials/models/weapons/v_models/cf_ak47-beast/pv_ak47-beast_s.vtf" )
end

SWEP.HoldType = "ar2"

if CLIENT then

   SWEP.PrintName = "Gold Dragon"
   SWEP.Slot = 6

   SWEP.Icon = "vgui/ttt/lykrast/icon_ap_golddragon"

   SWEP.EquipMenuData = {
      type = "item_weapon",
      desc = "Low damage, accurate assault rifle\n that sets enemies on fire."
   };
end


SWEP.Base = "weapon_ttt_brekiy_base"

SWEP.Primary.Damage      = 11
SWEP.Primary.Delay       = 0.11
SWEP.Primary.Cone        = 0.012
SWEP.Primary.ClipSize    = 30
SWEP.Primary.ClipMax     = 60
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Automatic   = true
SWEP.Primary.Ammo        = "smg1"
SWEP.Primary.Recoil      = 0.0175
SWEP.Primary.Sound       = "weapons/ree/kslh/kslh1.wav"
SWEP.CrouchBonus 				 	= 0.7
SWEP.MovePenalty			 	 	= 0.2
SWEP.JumpPenalty			 	 	= 0.1
SWEP.MaxCone 					 	= 0.06

SWEP.AimPatternX 		= function(t)
		return 0
	end
SWEP.AimPatternY 		= function(t)
		return 25 * t / (t + 20)
	end
SWEP.BloomRecoverRate 	= 0.00205
SWEP.AimRecoverRate		= 0.1
SWEP.AimKick			= 0.05
SWEP.Primary.ShoveY         = 0.2
SWEP.Primary.ShoveX         = 0.3

SWEP.AutoSpawnable = false
SWEP.Kind = WEAPON_EQUIP
SWEP.CanBuy = {ROLE_TRAITOR}
SWEP.LimitedStock = true

SWEP.AmmoEnt = "item_ammo_smg1_ttt"

SWEP.UseHands			= false
SWEP.ViewModelFlip		= true
SWEP.ViewModelFOV		= 75
SWEP.ViewModel  = "models/weapons/v_rif_ree_kslh.mdl"
SWEP.WorldModel = "models/weapons/w_rif_ree_kslh47.mdl"

SWEP.IronSightsPos = Vector(4.077, -4.277, 0.126)
SWEP.IronSightsAng = Vector(2.572, 0.222, 0.948)

function SWEP:IgniteTarget(att, path, dmginfo)

   local ent = path.Entity
	if ent == self.Owner then return end
   if not IsValid(ent) then return end

   if CLIENT and IsFirstTimePredicted() then
      if ent:GetClass() == "prop_ragdoll" then
         if ScorchUnderRagdoll then ScorchUnderRagdoll(ent) end
      end
      return
   end

   if SERVER then

      local dur = ent:IsPlayer() and 5 or 8

      -- disallow if prep or post round
      if ent:IsPlayer() and (not GAMEMODE:AllowPVP()) then return end

      ent:Ignite(dur, 100)

      ent.ignite_info = {att=dmginfo:GetAttacker(), infl=dmginfo:GetInflictor()}

      if ent:IsPlayer() then
         timer.Simple(dur + 0.1, function()
                                    if IsValid(ent) then
                                       ent.ignite_info = nil
                                    end
                                 end)
      end
   end
end

function SWEP:Callback( attacker, tr, dmginfo )
	self:IgniteTarget( attacker, tr, dmginfo )
end
	
--[[
function SWEP:ShootBullet_unused( dmg, recoil, numbul, cone )
   self:SendWeaponAnim(self.PrimaryAnim)

   self.Owner:MuzzleFlash()
   self.Owner:SetAnimation( PLAYER_ATTACK1 )

   if not IsFirstTimePredicted() then return end

   local sights = self:GetIronsights()

   numbul = numbul or 1
   cone   = cone   or 0.01
	
	local bulletAng = self.Owner:EyeAngles() + self:GetAimAngles()
	local dir = (bulletAng+ Angle(cone*360/math.pi*(math.random()-0.5),cone*360/math.pi*(math.random()-0.5),0)):Forward()
	local td = {}
	td.start = self.Owner:GetShootPos()
	td.endpos = td.start + 999999999*dir
	td.mask = MASK_SHOT
	local tr = util.TraceLine(td)
   local bullet = {}
   bullet.Num    = numbul
   bullet.Src    = self.Owner:GetShootPos()
   bullet.Dir    = dir
   bullet.Spread = Vector(0,0,0)--Vector( cone, cone, 0 )
   bullet.Tracer = self.TracerFrequency or 4
   bullet.TracerName = self.Tracer or "Tracer"
   bullet.Force  = dmg * 0.4
   bullet.Damage = dmg
   bullet.Callback = function( attacker, btr, dmginfo)
		self:Callback( attacker, tr, dmginfo )
		self:BulletPenetrate(0, bullet, attacker, tr, dmginfo)
	end
	--bullet.Callback = function(a, b, c)
	--return self:BulletPenetrate(0, a, b, c) end
	self.Owner:FireBullets( bullet )

   -- Owner can die after firebullets
	   
	self:ShootBulletBase( dmg, recoil, numbul, cone )
end]]--
