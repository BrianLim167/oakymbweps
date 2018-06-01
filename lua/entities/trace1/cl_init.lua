include('shared.lua')

//local matBeam		 		= Material( "egon_middlebeam" )
local matBeam		 		= Material( "cable/rope" )

/*---------------------------------------------------------
   Name: Initialize
---------------------------------------------------------*/
function ENT:Initialize()		

	self.Size = 0
	self.MainStart = self.Entity:GetPos()
	self.MainEnd = self:GetEndPos()
	self.dAng = (self.MainEnd - self.MainStart):Angle()
	//Changed from 3000 to match hook speed.
	self.speed = 10000
	self.startTime = CurTime()
	self.endTime = CurTime() + self.speed
	self.dt = -1
	
end

function ENT:Think()

	self.Entity:SetRenderBoundsWS( self:GetEndPos(), self.Entity:GetPos(), Vector()*8 )
	
	self.Size = math.Approach( self.Size, 1, 10*FrameTime() )
	
end


function ENT:DrawMainBeam( StartPos, EndPos, dt, dist )

	local TexOffset = 0
	
	local ca = Color(255,255,255,255)
	
	EndPos = StartPos + (self.dAng * ((1 - dt)*dist))
	
	// Cool Beam
	render.SetMaterial( matBeam )
	render.DrawBeam( EndPos, StartPos, 
	//32
					2, 
					TexOffset*-0.4, TexOffset*-0.4 + StartPos:Distance(EndPos) / 256, 
					ca )


end

function ENT:Draw()

	local Owner = self.Entity:GetOwner()
	if (!Owner || Owner == NULL) then return end

	local StartPos 		= self.Entity:GetPos()
	local EndPos 		= self:GetEndPos()
	local ViewModel 	= (Owner == LocalPlayer())
	local vm1 = Owner:GetViewModel()
	local vm2 = Owner:GetActiveWeapon()
	
	if (EndPos == Vector(0,0,0)) then return end
	
	// If it's the local player we start at the viewmodel
	if ( Owner == LocalPlayer() ) then
	     
		local vm1 = Owner:GetViewModel()
		if (!vm1 || vm1 == NULL) then return end 
		local attachment = vm1:GetAttachment(1)
		if attachment then
		StartPos = attachment.Pos
		end
	else
	// If we're viewing another player we start at their weapon
	
		local vm2 = Owner
		if (!vm2 || vm2 == NULL) then return end
		local attachment = vm2:GetAttachment(vm2:LookupAttachment( "anim_attachment_RH" ))
		if attachment then
		StartPos = attachment.Pos
		end
	
	end
//end	
	// offset the texture coords so it looks like it's scrolling
	local TexOffset = CurTime() * -2
	
	// Make the texture coords relative to distance so they're always a nice size
	local Distance = EndPos:Distance( StartPos ) * self.Size

	local et = (self.startTime + (Distance/self.speed))
	if(self.dt != 0) then
		self.dt = (et - CurTime()) / (et - self.startTime)
	end
	if(self.dt < 0) then
		self.dt = 0
	end
	self.dAng = (EndPos - StartPos):Angle():Forward()

	gbAngle = (EndPos - StartPos):Angle()
	local Normal 	= gbAngle:Forward()

	// Draw the beam
	self:DrawMainBeam( StartPos, StartPos + Normal * Distance, self.dt, Distance )
	 
end
/*---------------------------------------------------------
   Name: IsTranslucent
---------------------------------------------------------*/
function ENT:IsTranslucent()
	return true
end
