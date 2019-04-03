AddCSLuaFile()
resource.AddFile("materials/VGUI/ttt/lykrast/icon_jetpack.vmt")
CreateConVar("ttt_jetpack_force",20,{FCVAR_ARCHIVE})

if( CLIENT ) then
    SWEP.PrintName = "Jet Pack";
    SWEP.Slot = 7;
    SWEP.DrawAmmo = false;
    SWEP.DrawCrosshair = false;
    SWEP.Icon = "VGUI/ttt/lykrast/icon_jetpack";
 
   SWEP.EquipMenuData = {
      type = "item_weapon",
      desc = "Select it and press Jump to propel upward.\n\nBeware the landing."
   };

end


SWEP.Base = "weapon_tttbase"
SWEP.Spawnable= false
SWEP.AdminSpawnable= true
SWEP.HoldType = "normal"
 
SWEP.Kind = WEAPON_EQUIP2
SWEP.CanBuy = {ROLE_TRAITOR}
if ROLE_SURVIVALIST then 
	SWEP.CanBuy                = {ROLE_TRAITOR, ROLE_SURVIVALIST}
end
 
SWEP.ViewModelFOV= 10
SWEP.ViewModelFlip= false
SWEP.ViewModel          = "models/weapons/v_crowbar.mdl"
SWEP.WorldModel      = "models/maxofs2d/thruster_propeller.mdl"
 
 --- PRIMARY FIRE ---
SWEP.Primary.Delay= 1
SWEP.Primary.Recoil= 0
SWEP.Primary.Damage= 0
SWEP.Primary.NumShots= 1
SWEP.Primary.Cone= 0
SWEP.Primary.ClipSize = 100
SWEP.Primary.ClipMax = 1000
SWEP.Primary.DefaultClip	= 100
SWEP.StoredAmmo				= 0
SWEP.Primary.Automatic   = false
SWEP.Primary.Ammo         = "GaussEnergy"
SWEP.NoSights = true

SWEP.Jetting = false

--[[
function SWEP:SetupDataTable()
	if self.SetupDataTablesMain then self:SetupDataTablesMain() end
end]]--

if CLIENT then

   local smokeparticles = {
	  --Model("particle/mat1"),
      Model("particle/particle_smokegrenade"),
      --Model("particle/particle_noisesphere")
   };

   function SWEP:CreateSmoke(center)
      local em = ParticleEmitter(center)

      for i=1, 20 do
         local p = em:Add(table.Random(smokeparticles), center)
         if p then
			p.starttime = CurTime()
			p.colortime = math.Rand(0.8,0.81)
			p.tickrate = 66
		 
			p.r1 = math.random(250, 255)
			p.g1 = math.random(220, 225)
			p.b1 = math.random(160, 170)
			
			p.r2 = math.random(35, 40)
			p.g2 = math.random(35, 35)
			p.b2 = math.random(25, 30)
		 
            p:SetColor(p.r1, p.g1, p.b1)
			--p:SetColor(render.ComputeLighting(p:GetPos(), Vector(0,0,1)))
            p:SetStartAlpha(250)
            p:SetEndAlpha(200)
			local randvel = VectorRand() * math.Rand(50, 100)
			if IsValid(self.Owner) then
				p:SetVelocity(randvel + self.Owner:GetVelocity() - 200*self.Owner:GetUp())
			else
				p:SetVelocity(randvel - 400*self:GetUp())
			end
				
            p:SetLifeTime(0)
            
            p:SetDieTime(math.Rand(2, 3))

            p:SetStartSize(math.random(20, 25))
            p:SetEndSize(math.random(18, 20))
            p:SetRoll(math.random(-180, 180))
            p:SetRollDelta(math.Rand(-0.1, 0.1))
            p:SetAirResistance(40)

            p:SetCollide(true)
            p:SetBounce(math.Rand(0.05,0.3))
			
			p:SetNextThink(CurTime())
			p:SetThinkFunction( function(pa)
				if p.starttime + p.colortime > CurTime() then
					local dr = (p.r2 - p.r1) * (CurTime() - p.starttime)/p.colortime
					local dg = (p.g2 - p.g1) * (CurTime() - p.starttime)/p.colortime
					local db = (p.b2 - p.b1) * (CurTime() - p.starttime)/p.colortime
					p:SetColor(p.r1 + dr, p.g1 + dg, p.b1 + db )
				end
				p:SetNextThink(CurTime() + 1/p.tickrate)
			end)

            --p:SetLighting(true)
         end
      end

      em:Finish()
   end
end

function SWEP:PrimaryAttack()
	self:SetOn(not self:GetOn())
   return false
end

function SWEP:DrawHUD()
	if CLIENT then
		self.BaseClass.DrawHUD(self)
		surface.SetFont( "TargetID" )
		surface.SetTextPos( math.floor(ScrW() / 2.0) + 20, math.floor(ScrH() / 2.0) - 20 )
		if self:GetOn() then
			surface.SetTextColor( 0, 255, 0 )
			surface.DrawText( "ON" )
		else
			surface.SetTextColor( 255, 0, 0 )
			surface.DrawText( "OFF" )
		end
	end
end

function SWEP:Initialize()
	self:NetworkVar("Bool", 4, "DeathJetting"	)
	self:NetworkVar("Bool", 5, "On"				)
	self:SetDeathJetting(false)
	self:SetOn(false)

   if SERVER and IsValid(self.Owner) then
      self.Owner:DrawViewModel(false)
   end
	
	function jet()
		if not IsValid(self) then return end
	
		if IsValid(self.Owner) then self:SetDeathJetting(false) end
	
		if not (IsValid(self.Owner) or self:GetDeathJetting()) then
			if CLIENT then self:StopSound("thruster") end
			timer.Remove("BurnFuel" .. self:EntIndex())
			if not timer.Exists("GainFuel" .. self:EntIndex()) then
				timer.Create("GainFuel" .. self:EntIndex(), 0.25, 0, function()
					self:SetClip1(math.min(self:Clip1()+1, self.Primary.ClipSize))
				end)
			end
			self.Jetting = false
			return
		end
		
		if (self:GetDeathJetting() or self.Owner:KeyDown(IN_JUMP)) and self:Clip1() > 0 and self:GetOn() then
			if IsFirstTimePredicted() then
				if self:GetDeathJetting() then
					local phys = self:GetPhysicsObject()
					if IsValid(phys) then
						phys:ApplyForceCenter(self:GetUp() * 500)
					end
				else
					self.Owner:SetVelocity(self.Owner:GetUp() * GetConVarNumber("ttt_jetpack_force"))--8.8)
				end
			end
			if CLIENT then
				local jetlight = DynamicLight( self:EntIndex() )
				if ( jetlight ) then
					jetlight.pos = self:GetPos()
					jetlight.r = 200
					jetlight.g = 160
					jetlight.b = 80
					jetlight.brightness = 1
					jetlight.Decay = 0
					jetlight.Size = 1000
					jetlight.DieTime = CurTime() + 0.08
					jetlight.style = 0
					--jetlight.nomodel = true
					--jetlight:SetParent(self)
				end
			end
			if not self.Jetting then
				if CLIENT then
					local snd = {}
					snd.name = "thruster"
					snd.sound = "ambient/gas/cannister_loop.wav"
					snd.volume = 1
					snd.pitch = 100
					snd.level = 100
					snd.channel = CHAN_AUTO
					sound.Add(snd)
					self:EmitSound("thruster")
				end
				timer.Remove("GainFuel" .. self:EntIndex())
				timer.Create("BurnFuel" .. self:EntIndex(), 0.1, 0, function()
					self:SetClip1(math.max(self:Clip1()-1, 0))
					
					if CLIENT then
						self:CreateSmoke(self:GetPos() - 15* self:GetUp())
					end
				end)
				self.Jetting = true
			end
		end
		
		if not ((self:GetDeathJetting() or self.Owner:KeyDown(IN_JUMP)) and self:Clip1() > 0 and self:GetOn()) then
			if CLIENT then self:StopSound("thruster") end
			timer.Remove("BurnFuel" .. self:EntIndex())
			if not timer.Exists("GainFuel" .. self:EntIndex()) then
				timer.Create("GainFuel" .. self:EntIndex(), 0.25, 0, function()
					self:SetClip1(math.min(self:Clip1()+1, self.Primary.ClipSize))
				end)
			end
			self.Jetting = false
			self:SetDeathJetting(false)
		end
				
	end
	hook.Add("Think", "jet" .. self:EntIndex(), jet)
	
   return true
end

function SWEP:PreDrop(isdeath)
	if not isdeath then
		if CLIENT then self:StopSound("thruster") end
		timer.Remove("BurnFuel" .. self:EntIndex())
	elseif isdeath and self.Owner:KeyDown(IN_JUMP) and self:Clip1() > 0 and self:GetOn() then
		if CLIENT then
			self:StopSound("thruster")
			--self:EmitSound("thruster")
		end
		self:SetDeathJetting(true)
	end
end

--[[
function SWEP:OnDrop()
	self:StopSound("thruster")
	
	if IsValid(self.Owner) then
		timer.Remove("BurnFuel" .. self:EntIndex())
	end
end
]]--

function SWEP:OnRemove()
	if CLIENT then self:StopSound("thruster") end
	
	if IsValid(self.Owner) then
		timer.Remove("GainFuel" .. self:EntIndex())
		timer.Remove("BurnFuel" .. self:EntIndex())
	end
	
	hook.Remove("Think", "jet" .. self:EntIndex())
end

function SWEP:DrawWorldModel()
   if not IsValid(self.Owner) then
      self:DrawModel()
   end
end

function SWEP:DrawWorldModelTranslucent()
end