timer.Create( "Jestercommandsupdate", 0.1, 0, function()	
if gmod.GetGamemode().Name == "Trouble in Terrorist Town" then
hook.Add( "PostDrawTranslucentRenderables", "Icon", function()
	local GetPlayers = player.GetAll
    client = LocalPlayer()
    plys = GetPlayers()
	local indicator_mat = Material("vgui/ttt/sprite_traitor")
	local indicator_matjes = Material("vgui/ttt/icon_jes")
	local indicator_col = Color(255, 255, 255, 130)
	local indicator_coljes = Color(255, 255, 255, 130)
	
   if client:GetRole() == ROLE_TRAITOR then
if file.Read("rolecommands/jestericon.txt", "DATA") == "0" then	
      dir = client:GetForward() * -1
	
		  render.SetMaterial(indicator_matjes)
	  
      for i=1, #plys do
         ply = plys[i]
         if ply:GetRole() == ROLE_JESTER and ply != client then
            pos = ply:GetPos()
            pos.z = pos.z + 74

            render.DrawQuadEasy(pos, dir, 8, 8, indicator_coljes, 180)
         end
      end
	  end
	end
end)
end
end)