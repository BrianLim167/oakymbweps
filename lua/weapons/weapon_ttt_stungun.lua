AddCSLuaFile()

SWEP.HoldType = "smg"

if CLIENT then
   SWEP.PrintName = "UMP Prototype"
   SWEP.Slot      = 6

   SWEP.Icon = "vgui/ttt/icon_ump"

   SWEP.ViewModelFOV = 72

   SWEP.EquipMenuData = {
      type = "item_weapon",
      desc = "A special gun that fires shocking bullets. The target's aim will be thrown off."
   };
end

SWEP.Base = "weapon_ttt_brekiy_base"

SWEP.Kind = WEAPON_EQUIP
SWEP.WeaponID = AMMO_STUN
SWEP.CanBuy = {ROLE_DETECTIVE}
SWEP.LimitedStock = false

SWEP.Primary.Damage = 12
SWEP.Primary.Delay = 0.1
SWEP.Primary.Cone = 0.012
SWEP.Primary.ClipSize = 25
SWEP.Primary.ClipMax = 60
SWEP.Primary.DefaultClip	= 25
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "smg1"
SWEP.AutoSpawnable      = false
SWEP.AmmoEnt = "item_ammo_smg1_ttt"
SWEP.Primary.Recoil		= 0.00015
SWEP.Primary.Sound		= Sound( "Weapon_ump45.shot" )
SWEP.CrouchBonus 				 	= 0.7
SWEP.MovePenalty			 	 	= 0.25
SWEP.JumpPenalty			 	 	= 3
SWEP.MaxCone 					 	= 0.06

SWEP.AimPatternX 		= function(t)
		return 0
	end
SWEP.AimPatternY 		= function(t)
		return 1.75 * t
	end
SWEP.BloomRecoverRate 	= 0.05
SWEP.AimRecoverRate		= 0.35
SWEP.AimKick			= 1

SWEP.UseHands			= true
SWEP.ViewModelFlip		= false
SWEP.ViewModelFOV		= 54
SWEP.ViewModel			= "models/weapons/cstrike/c_smg_ump45.mdl"
SWEP.WorldModel			= "models/weapons/w_smg_ump45.mdl"

SWEP.HeadshotMultiplier = 2

SWEP.IronSightsPos = Vector(-8.735, -10, 4.039)
SWEP.IronSightsAng = Vector(-1.201, -0.201, -2)

function SWEP:ShootBullet( dmg, recoil, numbul, cone )
   local sights = self:GetIronsights()

   numbul = numbul or 1
   cone   = cone   or 0.01

   -- 10% accuracy bonus when sighting
   cone = sights and (cone * 0.9) or cone

   local bullet = {}
   bullet.Num    = numbul
   bullet.Src    = self.Owner:GetShootPos()
   bullet.Dir    = self.Owner:GetAimVector()
   bullet.Spread = Vector( cone, cone, 0 )
   bullet.Tracer = 4
   bullet.Force  = 5
   bullet.Damage = dmg

   bullet.Callback = function(att, tr, dmginfo)
						self:HollowDamageTarget( attacker, tr, dmginfo )
                        if SERVER or (CLIENT and IsFirstTimePredicted()) then
                           local ent = tr.Entity
                           if (not tr.HitWorld) and IsValid(ent) then
                              local edata = EffectData()

                              edata:SetEntity(ent)
                              edata:SetMagnitude(3)
                              edata:SetScale(2)

                              util.Effect("TeslaHitBoxes", edata)

                              if SERVER and ent:IsPlayer() then
                                 local eyeang = ent:EyeAngles()
                                 local j = 10
                                 eyeang.pitch = math.Clamp(eyeang.pitch + math.Rand(-j, j), -90, 90)
                                 eyeang.yaw = math.Clamp(eyeang.yaw + math.Rand(-j, j), -90, 90)
                                 ent:SetEyeAngles(eyeang)
                              end
                           end
                        end
                     end


   self.Owner:FireBullets( bullet )
   self:SendWeaponAnim(self.PrimaryAnim)
   
   self.IsAimRecover = false
   timer.Create( "AimRecoverPause", self.Primary.Delay, 1, function() self.IsAimRecover = true end )

   -- Owner can die after firebullets, giving an error at muzzleflash
   if not IsValid(self.Owner) or not self.Owner:Alive() then return end

   self.Owner:MuzzleFlash()
   self.Owner:SetAnimation( PLAYER_ATTACK1 )

   if self.Owner:IsNPC() then return end
	   
	local eyeang = self.Owner:EyeAngles()
	eyeang.pitch = eyeang.pitch - (math.Rand(self.AimKick / 2, self.AimKick))
	eyeang.yaw = eyeang.yaw - (math.Rand(-self.AimKick / 4, self.AimKick / 4))
	self.Owner:SetEyeAngles(eyeang)
end