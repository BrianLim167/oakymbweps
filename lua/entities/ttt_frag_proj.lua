-- Frag grenade projectile

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "ttt_basegrenade_proj"
ENT.Model = Model( "models/weapons/w_eq_fraggrenade_thrown.mdl" )

ENT.IsHitExploder = false

AccessorFunc( ENT, "radius", "Radius", FORCE_NUMBER )
AccessorFunc( ENT, "dmg", "Dmg", FORCE_NUMBER )

function ENT:Initialize()
   if not self:GetRadius() then self:SetRadius( 400 ) end
   if not self:GetDmg() then self:SetDmg(75) end

   return self.BaseClass.Initialize( self )
end

function ENT:Explode( tr )
   if SERVER then
      self:SetNoDraw( true )
      self:SetSolid( SOLID_NONE )

      -- Pull out of the surface
      if tr.Fraction != 1.0 then
         self:SetPos( tr.HitPos + tr.HitNormal * 0.6 )
      end

      local pos = self:GetPos()

      if util.PointContents( pos ) == CONTENTS_WATER then
         self:Remove()
         return
      end

      local effect = EffectData()
      effect:SetStart( pos )
      effect:SetOrigin( pos )
      effect:SetScale( self:GetRadius() * 0.6 )
      effect:SetRadius( self:GetRadius() )
      effect:SetMagnitude( self.dmg )

      if tr.Fraction != 1.0 then
         effect:SetNormal( tr.HitNormal )
      end

      util.Effect( "Explosion", effect, true, true )

      util.BlastDamage( self, self:GetThrower(), pos, self:GetRadius(), self:GetDmg() )

      self:SetDetonateExact( 0 )

      self:Remove()
   else
	local pos = self:GetPos()
	local index = self:EntIndex()
	timer.Simple(0.1, function()
		local boomlight = DynamicLight( index )
		if ( boomlight ) then
			boomlight.pos = pos+Vector(0,0,10)
			boomlight.r = 200
			boomlight.g = 130
			boomlight.b = 30
			boomlight.brightness = 3
			boomlight.Decay = 1000
			boomlight.Size = 1200
			boomlight.DieTime = CurTime() + 1
			boomlight.style = 0
		end
	end)
	
      local spos = self:GetPos()
      local trs = util.TraceLine( { start=spos + Vector( 0, 0, 64 ), endpos = spos + Vector( 0, 0, -128 ), filter = self } )
      util.Decal( "Scorch", trs.HitPos + trs.HitNormal, trs.HitPos - trs.HitNormal )

      self:SetDetonateExact( 0 )
   end
end
