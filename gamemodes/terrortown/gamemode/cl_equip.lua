---- Traitor equipment menu
local GetTranslation = LANG.GetTranslation
local GetPTranslation = LANG.GetParamTranslation

-- create ClientConVars
local numColsVar = CreateClientConVar("ttt_bem_cols", 4, true, false, "Sets the number of columns in the Traitor/Detective menu's item list.")
local numRowsVar = CreateClientConVar("ttt_bem_rows", 5, true, false, "Sets the number of rows in the Traitor/Detective menu's item list.")
local itemSizeVar = CreateClientConVar("ttt_bem_size", 64, true, false, "Sets the item size in the Traitor/Detective menu's item list.")
local showCustomVar = CreateClientConVar("ttt_bem_marker_custom", 1, true, false, "Should custom items get a marker?")
local showFavoriteVar = CreateClientConVar("ttt_bem_marker_fav", 1, true, false, "Should favorite items get a marker?")
local showSlotVar = CreateClientConVar("ttt_bem_marker_slot", 1, true, false, "Should items get a slot-marker?")

-- get serverside ConVars
local allowChangeVar = GetConVar("ttt_bem_allow_change")
local serverColsVar = GetConVar("ttt_bem_sv_cols")
local serverRowsVar = GetConVar("ttt_bem_sv_rows")
local serverSizeVar = GetConVar("ttt_bem_sv_size")

-- add favorites DB functions
include("favorites_db.lua")

-- Buyable weapons are loaded automatically. Buyable items are defined in
-- equip_items_shd.lua

Srealweaponsshop = {}
Drealweaponsshop = {}
Trealweaponsshop = {}
SKrealweaponsshop = {}

net.Receive( "Sinweaponshopper", function()
   for k,v in pairs( net.ReadTable()) do
      if table.HasValue( Srealweaponsshop, v ) then
      else
         table.insert( Srealweaponsshop, v )
      end
   end
end)
net.Receive( "Dinweaponshopper", function()
   for k,v in pairs( net.ReadTable()) do
      if table.HasValue( Drealweaponsshop, v ) then
      else
         table.insert( Drealweaponsshop, v )
      end
   end
end)
net.Receive( "Tinweaponshopper", function()
   for k,v in pairs( net.ReadTable()) do
      if table.HasValue( Trealweaponsshop, v ) then
      else
         table.insert( Trealweaponsshop, v )
      end
   end
end)
net.Receive( "SKinweaponshopper", function()
   for k,v in pairs( net.ReadTable()) do
      if table.HasValue( SKrealweaponsshop, v ) then
      else
         table.insert( SKrealweaponsshop, v )
      end
   end
end)

function PopulateWeaponsShop(shop, role)
   for k,v in pairs( shop ) do 
      if v.name then
         swep = weapons.GetStored(v.name)
         if swep and swep.CanBuy and not table.HasValue(swep.CanBuy, role) then
            table.insert(swep.CanBuy, role)
         end
      end
   end
end


local Equipment = nil
function GetEquipmentForRole(role)
   local Players = {}
   local io = 0
   
   local tab = util.TableToJSON( Players ) -- Convert the player table to JSON
   PopulateWeaponsShop(Srealweaponsshop, ROLE_SURVIVALIST)
   PopulateWeaponsShop(Drealweaponsshop, ROLE_DETECTIVE)
   PopulateWeaponsShop(Trealweaponsshop, ROLE_TRAITOR)
   PopulateWeaponsShop(SKrealweaponsshop, ROLE_SERIALKILLER)
   
   -- need to build equipment cache?
   if not Equipment then
      -- start with all the non-weapon goodies
      local tbl = table.Copy(EquipmentItems)
      
      -- find buyable weapons to load info from
      for k, v in pairs(weapons.GetList()) do
         if v and v.CanBuy then
            local data = v.EquipMenuData or {}
            local base = {
               id       = WEPS.GetClass(v),
               name     = v.PrintName or "Unnamed",
               limited  = v.LimitedStock,
               kind     = v.Kind or WEAPON_NONE,
               slot     = (v.Slot or 0) + 1,
               material = v.Icon or "vgui/ttt/icon_id",
               -- the below should be specified in EquipMenuData, in which case
               -- these values are overwritten
               type     = "Type not specified",
               model    = "models/weapons/w_bugbait.mdl",
               desc     = "No description specified."
            };
            
            -- Force material to nil so that model key is used when we are
            -- explicitly told to do so (ie. material is false rather than nil).
            if data.modelicon then
               base.material = nil
            end
            
            table.Merge(base, data)
            
            -- add this buyable weapon to all relevant equipment tables
            for _, r in pairs(v.CanBuy) do
               table.insert(tbl[r], base)
            end
         end
      end
      
      -- mark custom items
      for r, is in pairs(tbl) do
         for _, i in pairs(is) do
            if i and i.id then
               i.custom = not table.HasValue(DefaultEquipment[r], i.id)
            end
         end
      end
      
      Equipment = tbl
   end
   
   return Equipment and Equipment[role] or {}
end


local function ItemIsWeapon(item) return not tonumber(item.id) end
local function CanCarryWeapon(item) return LocalPlayer():CanCarryType(item.kind) end

local color_bad = Color(244, 67, 54, 255)
local color_good = Color(76, 175, 80, 255)

-- Creates tabel of labels showing the status of ordering prerequisites
local function PreqLabels(parent, x, y)
   local tbl = {}
   
   tbl.credits = vgui.Create("DLabel", parent)
   --tbl.credits:SetTooltip(GetTranslation("equip_help_cost"))
   tbl.credits:SetPos(x, y)
   -- coins icon
   tbl.credits.img = vgui.Create( "DImage", parent )
   tbl.credits.img:SetSize(32, 32)
   tbl.credits.img:CopyPos(tbl.credits)
   tbl.credits.img:MoveLeftOf(tbl.credits)
   tbl.credits.img:SetImage("vgui/ttt/equip/coin.png")
   
   -- remaining credits text
   tbl.credits.Check = function(s, sel)
      local credits = LocalPlayer():GetCredits()
      return credits > 0, " " .. credits, GetPTranslation("equip_cost", {num = credits})
   end
   
   
   tbl.owned = vgui.Create("DLabel", parent)
   --tbl.owned:SetTooltip(GetTranslation("equip_help_carry"))
   tbl.owned:CopyPos(tbl.credits)
   tbl.owned:MoveRightOf(tbl.credits, y*3)
   -- carry icon
   tbl.owned.img = vgui.Create( "DImage", parent )
   tbl.owned.img:SetSize(32, 32)
   tbl.owned.img:CopyPos(tbl.owned)
   tbl.owned.img:MoveLeftOf(tbl.owned)
   tbl.owned.img:SetImage( "vgui/ttt/equip/briefcase.png" )
   
   tbl.owned.Check = function(s, sel)
      if ItemIsWeapon(sel) and (not CanCarryWeapon(sel)) then
         return false, sel.slot, GetPTranslation("equip_carry_slot", {slot = sel.slot})
      elseif (not ItemIsWeapon(sel)) and LocalPlayer():HasEquipmentItem(sel.id) then
         return false, "X", GetTranslation("equip_carry_own")
      else
         return true, "✔", GetTranslation("equip_carry")
      end
   end
   
   tbl.bought = vgui.Create("DLabel", parent)
   --tbl.bought:SetTooltip(GetTranslation("equip_help_stock"))
   tbl.bought:CopyPos(tbl.owned)
   tbl.bought:MoveRightOf(tbl.owned, y*3)
   -- stock icon
   tbl.bought.img = vgui.Create( "DImage", parent )
   tbl.bought.img:SetSize(32, 32)
   tbl.bought.img:CopyPos(tbl.bought)
   tbl.bought.img:MoveLeftOf(tbl.bought)
   tbl.bought.img:SetImage( "vgui/ttt/equip/package.png" )
   
   tbl.bought.Check = function(s, sel)
      if sel.limited and LocalPlayer():HasBought(tostring(sel.id)) then
         return false, "X", GetTranslation("equip_stock_deny")
      else
         return true, "✔", GetTranslation("equip_stock_ok")
      end
   end
   
   for k, pnl in pairs(tbl) do
      pnl:SetFont("DermaLarge")
   end
   
   return function(selected)
      local allow = true
      for k, pnl in pairs(tbl) do
         local result, text, tooltip = pnl:Check(selected)
         pnl:SetTextColor(result and COLOR_WHITE or color_bad)
         pnl:SetText(text)
         pnl:SizeToContents()
         pnl:SetTooltip(tooltip)
         pnl.img:SetImageColor(result and COLOR_WHITE or color_bad)
         pnl.img:SetTooltip(tooltip)
         allow = allow and result
      end
      return allow
   end
end

-- quick, very basic override of DPanelSelect
local PANEL = {}
local function DrawSelectedEquipment(pnl)
   surface.SetDrawColor(255, 200, 0, 255)
   surface.DrawOutlinedRect(0, 0, pnl:GetWide(), pnl:GetTall())
end

function PANEL:SelectPanel(pnl)
   self.BaseClass.SelectPanel(self, pnl)
   if pnl then
      pnl.PaintOver = DrawSelectedEquipment
   end
end
vgui.Register("EquipSelect", PANEL, "DPanelSelect")


local SafeTranslate = LANG.TryTranslation

local color_darkened = Color(255,255,255, 80)
-- TODO: make set of global role colour defs, these are same as wepswitch
local color_slot = {
   [ROLE_TRAITOR]   = Color(180, 50, 40, 255),
   [ROLE_DETECTIVE] = Color(50, 60, 180, 255),
   [ROLE_SURVIVALIST] = Color(255, 127, 80, 255),
   [ROLE_SERIALKILLER] = Color(85,	26,	139, 255)
};

local eqframe = nil

randomweaponshop = {}
Tranweaponshop = {}
Sranweaponshop = {}
Dranweaponshop = {}
SKranweaponshop = {}

net.Receive( "Tinranweaponshopper", function()
   for k,v in pairs( Tranweaponshop ) do 
      table.remove(Tranweaponshop, k)
   end
   for k,v in pairs( net.ReadTable()) do
      if table.HasValue( Tranweaponshop, v ) then
      else
         table.insert( Tranweaponshop, v )
      end
   end
end)

net.Receive( "Sinranweaponshopper", function()
   for k,v in pairs( Sranweaponshop ) do 
      table.remove(Sranweaponshop, k)
   end
   for k,v in pairs( net.ReadTable()) do
      if table.HasValue( Sranweaponshop, v ) then
      else
         table.insert( Sranweaponshop, v )
      end
   end
end)



net.Receive( "Dinranweaponshopper", function()
   for k,v in pairs( Dranweaponshop ) do 
      table.remove(Dranweaponshop, k)
   end
   for k,v in pairs( net.ReadTable()) do
      if table.HasValue( Dranweaponshop, v ) then
      else
         table.insert( Dranweaponshop, v )
      end
   end
end)

net.Receive( "SKinranweaponshopper", function()
   for k,v in pairs( SKranweaponshop ) do 
      table.remove(SKranweaponshop, k)
   end
   for k,v in pairs( net.ReadTable()) do
      if table.HasValue( SKranweaponshop, v ) then
      else
         table.insert( SKranweaponshop, v )
      end
   end
end) 

net.Receive( "randomweaponshoper", function()
   local randomweaponshopping = tonumber(net.ReadString())
   local Trandomweaponshopping = tonumber(net.ReadString())
   local Srandomweaponshopping = tonumber(net.ReadString())
   local Drandomweaponshopping = tonumber(net.ReadString())
   local SKrandomweaponshopping = tonumber(net.ReadString())
   
   if Trandomweaponshopping == 0 then
      if table.HasValue( randomweaponshop, "No T" ) then
      else
         table.insert( randomweaponshop, 2, "No T" )
      end
   elseif Trandomweaponshopping >= 1 then
      if table.HasValue( randomweaponshop, "T" ) then
      else
         table.insert( randomweaponshop, 2, "T" )
      end
   end 
   
   if Srandomweaponshopping == 0 then
      if table.HasValue( randomweaponshop, "No S" ) then
      else
         table.insert( randomweaponshop, 3, "No S" )
      end
   elseif Srandomweaponshopping >= 1 then
      if table.HasValue( randomweaponshop, "S" ) then
      else
         table.insert( randomweaponshop, 3, "S" )
      end
   end 
   
   if Drandomweaponshopping == 0 then
      if table.HasValue( randomweaponshop, "No D" ) then
      else
         table.insert( randomweaponshop, 4, "No D" )
      end
   elseif Drandomweaponshopping >= 1 then
      if table.HasValue( randomweaponshop, "D" ) then
      else
         table.insert( randomweaponshop, 4, "D" )
      end
   end 
   
   if SKrandomweaponshopping == 0 then
      if table.HasValue( randomweaponshop, "No SK" ) then
      else
         table.insert( randomweaponshop, 5, "No SK" )
      end
   elseif SKrandomweaponshopping >= 1 then
      if table.HasValue( randomweaponshop, "SK" ) then
      else
         table.insert( randomweaponshop, 5, "SK" )
      end
   end 
   
   if table.HasValue( randomweaponshop, randomweaponshopping ) then
   else
      table.insert( randomweaponshop, 1, randomweaponshopping )
   end
   
end)

local function TraitorMenuPopup()
   -- calculate dimensions
   local numCols = serverColsVar:GetInt()
   local numRows = serverRowsVar:GetInt()
   local itemSize = serverSizeVar:GetInt()
   
   if allowChangeVar:GetBool() then
      numCols = numColsVar:GetInt()
      numRows = numRowsVar:GetInt()
      itemSize = itemSizeVar:GetInt()
   end
   -- margin
   local m = 5
   -- item list width
   local dlistw = ((itemSize + 2) * numCols) - 2 + 15
   local dlisth = ((itemSize + 2) * numRows) - 2 + 15
   -- right column width
   local diw = 270
   -- frame size
   local w = dlistw + diw + (m*4)
   local h = dlisth + 75
   
   local ply = LocalPlayer()
   if not IsValid(ply) or not ply:IsActiveSpecial() then
      return
   end
   
   -- Close any existing traitor menu
   if eqframe and IsValid(eqframe) then eqframe:Close() end
   
   local credits = ply:GetCredits()
   local can_order = credits > 0
   
   local dframe = vgui.Create("DFrame")
   dframe:SetSize(w, h)
   dframe:Center()
   dframe:SetTitle(GetTranslation("equip_title"))
   dframe:SetVisible(true)
   dframe:ShowCloseButton(true)
   dframe:SetMouseInputEnabled(true)
   dframe:SetDeleteOnClose(true)
   
   local dsheet = vgui.Create("DPropertySheet", dframe)
   
   -- Add a callback when switching tabs
   local oldfunc = dsheet.SetActiveTab
   dsheet.SetActiveTab = function(self, new)
      if self.m_pActiveTab != new and self.OnTabChanged then
         self:OnTabChanged(self.m_pActiveTab, new)
      end
      oldfunc(self, new)
   end
   
   dsheet:SetPos(0,0)
   dsheet:StretchToParent(m,m + 25,m,m)
   local padding = dsheet:GetPadding()
   
   local dequip = vgui.Create("DPanel", dsheet)
   dequip:SetPaintBackground(false)
   dequip:StretchToParent(padding,padding,padding,padding)
   
   -- Determine if we already have equipment
   local owned_ids = {}
   for _, wep in pairs(ply:GetWeapons()) do
      if IsValid(wep) and wep:IsEquipment() then
         table.insert(owned_ids, wep:GetClass())
      end
   end
   
   -- Stick to one value for no equipment
   if #owned_ids == 0 then
      owned_ids = nil
   end
   
   --- Construct icon listing
   --- icon size = 64 x 64
   local dlist = vgui.Create("EquipSelect", dequip)
   -- local dlistw = 288
   dlist:SetPos(0,0)
   dlist:SetSize(dlistw, dlisth)
   dlist:EnableVerticalScrollbar(true)
   dlist:EnableHorizontal(true)
   
   local items = GetEquipmentForRole(ply:GetRole())
   
   if table.HasValue( randomweaponshop, 1 ) then	
      if table.HasValue( randomweaponshop, "T" ) then	
         if ply:GetRole() == ROLE_TRAITOR then
            local Trandomitems = {}
            
            
            for k,v in pairs( items ) do 
               if v.id == 1 or v.id == 2 or v.id == 3 then
                  table.insert(Trandomitems, v)
               else
                  if table.HasValue( Tranweaponshop, v.id ) then
                     table.insert(Trandomitems, v)
                  else
                     if v.id == 1 or v.id == 2 or v.id == 3 then
                     else
                        table.remove(Trandomitems, k)
                     end
                  end
               end
            end
            
            
            local to_select = nil
            
            -- temp table for sorting
            local paneltablefav = {}
            local paneltable = {}
            
            for k, item in pairs(Trandomitems) do
               local ic = nil
               
               -- Create icon panel
               if item.material then
                  ic = vgui.Create("LayeredIcon", dlist)
                  
                  if item.custom && showCustomVar:GetBool() then
                     -- Custom marker icon
                     local marker = vgui.Create("DImage")
                     marker:SetImage("vgui/ttt/custom_marker")
                     marker.PerformLayout = function(s)
                        s:AlignBottom(2)
                        s:AlignRight(2)
                        s:SetSize(16, 16)
                     end
                     marker:SetTooltip(GetTranslation("equip_custom"))
                     
                     ic:AddLayer(marker)
                     
                     ic:EnableMousePassthrough(marker)
                  end
                  
                  -- Favorites marker icon
                  ic.favorite = false
                  local favorites = GetFavorites(ply:SteamID(), ply:GetRole())
                  if favorites then
                     if IsFavorite(favorites, item.id) then
                        ic.favorite = true
                        if showFavoriteVar:GetBool() then
                           local star = vgui.Create("DImage")
                           star:SetImage("icon16/star.png")
                           star.PerformLayout = function(s)
                              s:AlignTop(2)
                              s:AlignRight(2)
                              s:SetSize(12, 12)
                           end
                           star:SetTooltip("Favorite")
                           ic:AddLayer(star)
                           ic:EnableMousePassthrough(star)
                        end
                     end
                  end
                  
                  -- Slot marker icon
                  if ItemIsWeapon(item) && showSlotVar:GetBool() then
                     local slot = vgui.Create("SimpleIconLabelled")
                     slot:SetIcon("vgui/ttt/slotcap")
                     slot:SetIconColor(color_slot[ply:GetRole()] or COLOR_GREY)
                     slot:SetIconSize(16)
                     
                     slot:SetIconText(item.slot)
                     
                     slot:SetIconProperties(COLOR_WHITE,
                     "DefaultBold",
                     {opacity=220, offset=1},
                     {10, 8})
                     
                     ic:AddLayer(slot)
                     ic:EnableMousePassthrough(slot)
                  end
                  
                  ic:SetIconSize(itemSize)
                  ic:SetIcon(item.material)
               elseif item.model then
                  ic = vgui.Create("SpawnIcon", dlist)
                  ic:SetModel(item.model)
               else
                  ErrorNoHalt("Equipment item does not have model or material specified: " .. tostring(item) .. "\n")
               end
               
               ic.item = item
               
               local tip = SafeTranslate(item.name) .. " (" .. SafeTranslate(item.type) .. ")"
               ic:SetTooltip(tip)
               
               -- If we cannot order this item, darken it
               if ((not can_order) or
               -- already owned
               table.HasValue(owned_ids, item.id) or
               (tonumber(item.id) and ply:HasEquipmentItem(tonumber(item.id))) or
               -- already carrying a weapon for this slot
               (ItemIsWeapon(item) and (not CanCarryWeapon(item))) or
               -- already bought the item before
               (item.limited and ply:HasBought(tostring(item.id)))) then
                  
                  ic:SetIconColor(color_darkened)
               end
               
               if ic.favorite then
                  paneltablefav[k] = ic
               else
                  paneltable[k] = ic
               end
               
            end
            
            -- add favorites first
            for _, panel in pairs(paneltablefav) do
               dlist:AddPanel(panel)
            end
            -- non favorites second
            for _, panel in pairs(paneltable) do
               dlist:AddPanel(panel)
            end
            
            local bw, bh = 100, 25
            
            -- Whole right column
            local dih = h - bh - m*5
            -- local diw = w - dlistw - m*6 - 2
            local dinfobg = vgui.Create("DPanel", dequip)
            dinfobg:SetPaintBackground(false)
            dinfobg:SetSize(diw - m, dih)
            dinfobg:SetPos(dlistw + m, 0)
            
            -- item info pane
            local dinfo = vgui.Create("ColoredBox", dinfobg)
            dinfo:SetColor(Color(90, 90, 95))
            dinfo:SetPos(0,0)
            dinfo:StretchToParent(0, 0, m*2, 105)
            
            local dfields = {}
            for _, k in pairs({"name", "type", "desc"}) do
               dfields[k] = vgui.Create("DLabel", dinfo)
               dfields[k]:SetTooltip(GetTranslation("equip_spec_" .. k))
               dfields[k]:SetPos(m*3, m*2)
               dfields[k]:SetWidth(diw - m*6)
            end
            
            dfields.name:SetFont("TabLarge")
            
            dfields.type:SetFont("DermaDefault")
            dfields.type:MoveBelow(dfields.name)
            
            dfields.desc:SetFont("DermaDefaultBold")
            dfields.desc:SetContentAlignment(7)
            dfields.desc:MoveBelow(dfields.type, 1)
            
            local iw, ih = dinfo:GetSize()
            
            local dhelp = vgui.Create("DPanel", dinfobg)
            dhelp:SetPaintBackground(false)
            dhelp:SetSize(diw, 64)
            dhelp:MoveBelow(dinfo, m)
            
            local update_preqs = PreqLabels(dhelp, m*7, m*2)
            
            dhelp:SizeToContents()
            
            local dconfirm = vgui.Create("DButton", dinfobg)
            dconfirm:SetPos(0, dih - bh*2)
            dconfirm:SetSize(bw, bh)
            dconfirm:SetDisabled(true)
            dconfirm:SetText(GetTranslation("equip_confirm"))
            
            
            dsheet:AddSheet(GetTranslation("equip_tabtitle"), dequip, "icon16/bomb.png", false, false, "Traitor equipment menu")
            
            -- Item control
            if ply:HasEquipmentItem(EQUIP_RADAR) then
               local dradar = RADAR.CreateMenu(dsheet, dframe)
               dsheet:AddSheet(GetTranslation("radar_name"), dradar, "icon16/magnifier.png", false,false, "Radar control")
            end
            
            if ply:HasEquipmentItem(EQUIP_DISGUISE) then
               local ddisguise = DISGUISE.CreateMenu(dsheet)
               dsheet:AddSheet(GetTranslation("disg_name"), ddisguise, "icon16/user.png", false,false, "Disguise control")
            end
            
            -- Weapon/item control
            if IsValid(ply.radio) or ply:HasWeapon("weapon_ttt_radio") then
               local dradio = TRADIO.CreateMenu(dsheet)
               dsheet:AddSheet(GetTranslation("radio_name"), dradio, "icon16/transmit.png", false,false, "Radio control")
            end
            
            -- Credit transferring
            if credits > 0 then
               local dtransfer = CreateTransferMenu(dsheet)
               dsheet:AddSheet(GetTranslation("xfer_name"), dtransfer, "icon16/group_gear.png", false,false, "Transfer credits")
            end
            
            hook.Run("TTTEquipmentTabs", dsheet)
            
            
            -- couple panelselect with info
            dlist.OnActivePanelChanged = function(self, _, new)
               for k,v in pairs(new.item) do
                  if dfields[k] then
                     dfields[k]:SetText(SafeTranslate(v))
                     dfields[k]:SetAutoStretchVertical(true)
                     dfields[k]:SetWrap(true)
                  end
               end
               
               -- Trying to force everything to update to
               -- the right size is a giant pain, so just
               -- force a good size.
               dfields.desc:SetTall(70)
               
               can_order = update_preqs(new.item)
               
               dconfirm:SetDisabled(not can_order)
            end
            
            -- select first
            dlist:SelectPanel(to_select or dlist:GetItems()[1])
            
            -- prep confirm action
            dconfirm.DoClick = function()
               local pnl = dlist.SelectedPanel
               if not pnl or not pnl.item then return end
               local choice = pnl.item
               RunConsoleCommand("ttt_order_equipment", choice.id)
               dframe:Close()
            end
            
            -- update some basic info, may have changed in another tab
            -- specifically the number of credits in the preq list
            dsheet.OnTabChanged = function(s, old, new)
               if not IsValid(new) then return end
               
               if new:GetPanel() == dequip then
                  can_order = update_preqs(dlist.SelectedPanel.item)
                  dconfirm:SetDisabled(not can_order)
               end
            end
            
            local dcancel = vgui.Create("DButton", dframe)
            dcancel:SetPos(w - 13 - bw, h - bh - 16)
            dcancel:SetSize(bw, bh)
            dcancel:SetDisabled(false)
            dcancel:SetText(GetTranslation("close"))
            dcancel.DoClick = function()
               dframe:Close()
            end
            
            function file.AppendLine(filename, addme)
               data = file.Read(filename)
               if ( data ) then
                  file.Write(filename, data .. "\n" .. tostring(addme))
               else
                  file.Write(filename, tostring(addme))
               end
            end
            
            --add as favorite button
            dfav = vgui.Create("DButton", dinfobg)
            dfav:SetPos(0, dih - bh*2)
            dfav:MoveRightOf(dconfirm)
            dfav:SetSize(bh, bh)
            dfav:SetDisabled(false)
            dfav:SetText("")
            dfav:SetImage("icon16/star.png")
            dfav.DoClick = function()
               local ply = LocalPlayer()
               local role = ply:GetRole()
               local guid = ply:SteamID()
               local pnl = dlist.SelectedPanel
               if not pnl or not pnl.item then return end
               local choice = pnl.item
               local weapon = choice.id
               CreateFavTable()
               if pnl.favorite then
                  RemoveFavorite(guid, role, weapon)
               else
                  AddFavorite(guid, role, weapon)
               end
            end
            
            dframe:MakePopup()
            dframe:SetKeyboardInputEnabled(false)
            
            eqframe = dframe
         end
      end
      if table.HasValue( randomweaponshop, "S" ) then	
         if ply:GetRole() == ROLE_SURVIVALIST then
            local Srandomitems = {}
            
            
            for k,v in pairs( items ) do 
               if v.id == 1 or v.id == 2 or v.id == 3 then
                  table.insert(Srandomitems, v)
               else
                  if table.HasValue( Sranweaponshop, v.id ) then
                     table.insert(Srandomitems, v)
                  else
                     if v.id == 1 or v.id == 2 or v.id == 3 then
                     else
                        table.remove(Srandomitems, k)
                     end
                  end
               end
            end
            
            
            local to_select = nil
            
            -- temp table for sorting
            local paneltablefav = {}
            local paneltable = {}
            
            for k, item in pairs(Srandomitems) do
               local ic = nil
               
               -- Create icon panel
               if item.material then
                  ic = vgui.Create("LayeredIcon", dlist)
                  
                  if item.custom && showCustomVar:GetBool() then
                     -- Custom marker icon
                     local marker = vgui.Create("DImage")
                     marker:SetImage("vgui/ttt/custom_marker")
                     marker.PerformLayout = function(s)
                        s:AlignBottom(2)
                        s:AlignRight(2)
                        s:SetSize(16, 16)
                     end
                     marker:SetTooltip(GetTranslation("equip_custom"))
                     
                     ic:AddLayer(marker)
                     
                     ic:EnableMousePassthrough(marker)
                  end
                  
                  -- Favorites marker icon
                  ic.favorite = false
                  local favorites = GetFavorites(ply:SteamID(), ply:GetRole())
                  if favorites then
                     if IsFavorite(favorites, item.id) then
                        ic.favorite = true
                        if showFavoriteVar:GetBool() then
                           local star = vgui.Create("DImage")
                           star:SetImage("icon16/star.png")
                           star.PerformLayout = function(s)
                              s:AlignTop(2)
                              s:AlignRight(2)
                              s:SetSize(12, 12)
                           end
                           star:SetTooltip("Favorite")
                           ic:AddLayer(star)
                           ic:EnableMousePassthrough(star)
                        end
                     end
                  end
                  
                  -- Slot marker icon
                  if ItemIsWeapon(item) && showSlotVar:GetBool() then
                     local slot = vgui.Create("SimpleIconLabelled")
                     slot:SetIcon("vgui/ttt/slotcap")
                     slot:SetIconColor(color_slot[ply:GetRole()] or COLOR_GREY)
                     slot:SetIconSize(16)
                     
                     slot:SetIconText(item.slot)
                     
                     slot:SetIconProperties(COLOR_WHITE,
                     "DefaultBold",
                     {opacity=220, offset=1},
                     {10, 8})
                     
                     ic:AddLayer(slot)
                     ic:EnableMousePassthrough(slot)
                  end
                  
                  ic:SetIconSize(itemSize)
                  ic:SetIcon(item.material)
               elseif item.model then
                  ic = vgui.Create("SpawnIcon", dlist)
                  ic:SetModel(item.model)
               else
                  ErrorNoHalt("Equipment item does not have model or material specified: " .. tostring(item) .. "\n")
               end
               
               ic.item = item
               
               local tip = SafeTranslate(item.name) .. " (" .. SafeTranslate(item.type) .. ")"
               ic:SetTooltip(tip)
               
               -- If we cannot order this item, darken it
               if ((not can_order) or
               -- already owned
               table.HasValue(owned_ids, item.id) or
               (tonumber(item.id) and ply:HasEquipmentItem(tonumber(item.id))) or
               -- already carrying a weapon for this slot
               (ItemIsWeapon(item) and (not CanCarryWeapon(item))) or
               -- already bought the item before
               (item.limited and ply:HasBought(tostring(item.id)))) then
                  
                  ic:SetIconColor(color_darkened)
               end
               
               if ic.favorite then
                  paneltablefav[k] = ic
               else
                  paneltable[k] = ic
               end
               
            end
            
            -- add favorites first
            for _, panel in pairs(paneltablefav) do
               dlist:AddPanel(panel)
            end
            -- non favorites second
            for _, panel in pairs(paneltable) do
               dlist:AddPanel(panel)
            end
            
            local bw, bh = 100, 25
            
            -- Whole right column
            local dih = h - bh - m*5
            -- local diw = w - dlistw - m*6 - 2
            local dinfobg = vgui.Create("DPanel", dequip)
            dinfobg:SetPaintBackground(false)
            dinfobg:SetSize(diw - m, dih)
            dinfobg:SetPos(dlistw + m, 0)
            
            -- item info pane
            local dinfo = vgui.Create("ColoredBox", dinfobg)
            dinfo:SetColor(Color(90, 90, 95))
            dinfo:SetPos(0,0)
            dinfo:StretchToParent(0, 0, m*2, 105)
            
            local dfields = {}
            for _, k in pairs({"name", "type", "desc"}) do
               dfields[k] = vgui.Create("DLabel", dinfo)
               dfields[k]:SetTooltip(GetTranslation("equip_spec_" .. k))
               dfields[k]:SetPos(m*3, m*2)
               dfields[k]:SetWidth(diw - m*6)
            end
            
            dfields.name:SetFont("TabLarge")
            
            dfields.type:SetFont("DermaDefault")
            dfields.type:MoveBelow(dfields.name)
            
            dfields.desc:SetFont("DermaDefaultBold")
            dfields.desc:SetContentAlignment(7)
            dfields.desc:MoveBelow(dfields.type, 1)
            
            local iw, ih = dinfo:GetSize()
            
            local dhelp = vgui.Create("DPanel", dinfobg)
            dhelp:SetPaintBackground(false)
            dhelp:SetSize(diw, 64)
            dhelp:MoveBelow(dinfo, m)
            
            local update_preqs = PreqLabels(dhelp, m*7, m*2)
            
            dhelp:SizeToContents()
            
            local dconfirm = vgui.Create("DButton", dinfobg)
            dconfirm:SetPos(0, dih - bh*2)
            dconfirm:SetSize(bw, bh)
            dconfirm:SetDisabled(true)
            dconfirm:SetText(GetTranslation("equip_confirm"))
            
            
            dsheet:AddSheet(GetTranslation("equip_tabtitle"), dequip, "icon16/bomb.png", false, false, "Traitor equipment menu")
            
            -- Item control
            if ply:HasEquipmentItem(EQUIP_RADAR) then
               local dradar = RADAR.CreateMenu(dsheet, dframe)
               dsheet:AddSheet(GetTranslation("radar_name"), dradar, "icon16/magnifier.png", false,false, "Radar control")
            end
            
            if ply:HasEquipmentItem(EQUIP_DISGUISE) then
               local ddisguise = DISGUISE.CreateMenu(dsheet)
               dsheet:AddSheet(GetTranslation("disg_name"), ddisguise, "icon16/user.png", false,false, "Disguise control")
            end
            
            -- Weapon/item control
            if IsValid(ply.radio) or ply:HasWeapon("weapon_ttt_radio") then
               local dradio = TRADIO.CreateMenu(dsheet)
               dsheet:AddSheet(GetTranslation("radio_name"), dradio, "icon16/transmit.png", false,false, "Radio control")
            end
            
            -- Credit transferring
            if credits > 0 then
               local dtransfer = CreateTransferMenu(dsheet)
               dsheet:AddSheet(GetTranslation("xfer_name"), dtransfer, "icon16/group_gear.png", false,false, "Transfer credits")
            end
            
            hook.Run("TTTEquipmentTabs", dsheet)
            
            
            -- couple panelselect with info
            dlist.OnActivePanelChanged = function(self, _, new)
               for k,v in pairs(new.item) do
                  if dfields[k] then
                     dfields[k]:SetText(SafeTranslate(v))
                     dfields[k]:SetAutoStretchVertical(true)
                     dfields[k]:SetWrap(true)
                  end
               end
               
               -- Trying to force everything to update to
               -- the right size is a giant pain, so just
               -- force a good size.
               dfields.desc:SetTall(70)
               
               can_order = update_preqs(new.item)
               
               dconfirm:SetDisabled(not can_order)
            end
            
            -- select first
            dlist:SelectPanel(to_select or dlist:GetItems()[1])
            
            -- prep confirm action
            dconfirm.DoClick = function()
               local pnl = dlist.SelectedPanel
               if not pnl or not pnl.item then return end
               local choice = pnl.item
               RunConsoleCommand("ttt_order_equipment", choice.id)
               dframe:Close()
            end
            
            -- update some basic info, may have changed in another tab
            -- specifically the number of credits in the preq list
            dsheet.OnTabChanged = function(s, old, new)
               if not IsValid(new) then return end
               
               if new:GetPanel() == dequip then
                  can_order = update_preqs(dlist.SelectedPanel.item)
                  dconfirm:SetDisabled(not can_order)
               end
            end
            
            local dcancel = vgui.Create("DButton", dframe)
            dcancel:SetPos(w - 13 - bw, h - bh - 16)
            dcancel:SetSize(bw, bh)
            dcancel:SetDisabled(false)
            dcancel:SetText(GetTranslation("close"))
            dcancel.DoClick = function()
               dframe:Close()
            end
            
            function file.AppendLine(filename, addme)
               data = file.Read(filename)
               if ( data ) then
                  file.Write(filename, data .. "\n" .. tostring(addme))
               else
                  file.Write(filename, tostring(addme))
               end
            end
            
            --add as favorite button
            dfav = vgui.Create("DButton", dinfobg)
            dfav:SetPos(0, dih - bh*2)
            dfav:MoveRightOf(dconfirm)
            dfav:SetSize(bh, bh)
            dfav:SetDisabled(false)
            dfav:SetText("")
            dfav:SetImage("icon16/star.png")
            dfav.DoClick = function()
               local ply = LocalPlayer()
               local role = ply:GetRole()
               local guid = ply:SteamID()
               local pnl = dlist.SelectedPanel
               if not pnl or not pnl.item then return end
               local choice = pnl.item
               local weapon = choice.id
               CreateFavTable()
               if pnl.favorite then
                  RemoveFavorite(guid, role, weapon)
               else
                  AddFavorite(guid, role, weapon)
               end
            end
            
            dframe:MakePopup()
            dframe:SetKeyboardInputEnabled(false)
            
            eqframe = dframe
         end
      end
      if table.HasValue( randomweaponshop, "D" ) then	
         if ply:GetRole() == ROLE_DETECTIVE then
            local Drandomitems = {}
            
            
            for k,v in pairs( items ) do 
               if v.id == 1 or v.id == 2 or v.id == 3 then
                  table.insert(Drandomitems, v)
               else
                  if table.HasValue( Dranweaponshop, v.id ) then
                     table.insert(Drandomitems, v)
                  else
                     if v.id == 1 or v.id == 2 or v.id == 3 then
                     else
                        table.remove(Drandomitems, k)
                     end
                  end
               end
            end
            
            
            local to_select = nil
            
            -- temp table for sorting
            local paneltablefav = {}
            local paneltable = {}
            
            for k, item in pairs(Drandomitems) do
               local ic = nil
               
               -- Create icon panel
               if item.material then
                  ic = vgui.Create("LayeredIcon", dlist)
                  
                  if item.custom && showCustomVar:GetBool() then
                     -- Custom marker icon
                     local marker = vgui.Create("DImage")
                     marker:SetImage("vgui/ttt/custom_marker")
                     marker.PerformLayout = function(s)
                        s:AlignBottom(2)
                        s:AlignRight(2)
                        s:SetSize(16, 16)
                     end
                     marker:SetTooltip(GetTranslation("equip_custom"))
                     
                     ic:AddLayer(marker)
                     
                     ic:EnableMousePassthrough(marker)
                  end
                  
                  -- Favorites marker icon
                  ic.favorite = false
                  local favorites = GetFavorites(ply:SteamID(), ply:GetRole())
                  if favorites then
                     if IsFavorite(favorites, item.id) then
                        ic.favorite = true
                        if showFavoriteVar:GetBool() then
                           local star = vgui.Create("DImage")
                           star:SetImage("icon16/star.png")
                           star.PerformLayout = function(s)
                              s:AlignTop(2)
                              s:AlignRight(2)
                              s:SetSize(12, 12)
                           end
                           star:SetTooltip("Favorite")
                           ic:AddLayer(star)
                           ic:EnableMousePassthrough(star)
                        end
                     end
                  end
                  
                  -- Slot marker icon
                  if ItemIsWeapon(item) && showSlotVar:GetBool() then
                     local slot = vgui.Create("SimpleIconLabelled")
                     slot:SetIcon("vgui/ttt/slotcap")
                     slot:SetIconColor(color_slot[ply:GetRole()] or COLOR_GREY)
                     slot:SetIconSize(16)
                     
                     slot:SetIconText(item.slot)
                     
                     slot:SetIconProperties(COLOR_WHITE,
                     "DefaultBold",
                     {opacity=220, offset=1},
                     {10, 8})
                     
                     ic:AddLayer(slot)
                     ic:EnableMousePassthrough(slot)
                  end
                  
                  ic:SetIconSize(itemSize)
                  ic:SetIcon(item.material)
               elseif item.model then
                  ic = vgui.Create("SpawnIcon", dlist)
                  ic:SetModel(item.model)
               else
                  ErrorNoHalt("Equipment item does not have model or material specified: " .. tostring(item) .. "\n")
               end
               
               ic.item = item
               
               local tip = SafeTranslate(item.name) .. " (" .. SafeTranslate(item.type) .. ")"
               ic:SetTooltip(tip)
               
               -- If we cannot order this item, darken it
               if ((not can_order) or
               -- already owned
               table.HasValue(owned_ids, item.id) or
               (tonumber(item.id) and ply:HasEquipmentItem(tonumber(item.id))) or
               -- already carrying a weapon for this slot
               (ItemIsWeapon(item) and (not CanCarryWeapon(item))) or
               -- already bought the item before
               (item.limited and ply:HasBought(tostring(item.id)))) then
                  
                  ic:SetIconColor(color_darkened)
               end
               
               if ic.favorite then
                  paneltablefav[k] = ic
               else
                  paneltable[k] = ic
               end
               
            end
            
            -- add favorites first
            for _, panel in pairs(paneltablefav) do
               dlist:AddPanel(panel)
            end
            -- non favorites second
            for _, panel in pairs(paneltable) do
               dlist:AddPanel(panel)
            end
            
            local bw, bh = 100, 25
            
            -- Whole right column
            local dih = h - bh - m*5
            -- local diw = w - dlistw - m*6 - 2
            local dinfobg = vgui.Create("DPanel", dequip)
            dinfobg:SetPaintBackground(false)
            dinfobg:SetSize(diw - m, dih)
            dinfobg:SetPos(dlistw + m, 0)
            
            -- item info pane
            local dinfo = vgui.Create("ColoredBox", dinfobg)
            dinfo:SetColor(Color(90, 90, 95))
            dinfo:SetPos(0,0)
            dinfo:StretchToParent(0, 0, m*2, 105)
            
            local dfields = {}
            for _, k in pairs({"name", "type", "desc"}) do
               dfields[k] = vgui.Create("DLabel", dinfo)
               dfields[k]:SetTooltip(GetTranslation("equip_spec_" .. k))
               dfields[k]:SetPos(m*3, m*2)
               dfields[k]:SetWidth(diw - m*6)
            end
            
            dfields.name:SetFont("TabLarge")
            
            dfields.type:SetFont("DermaDefault")
            dfields.type:MoveBelow(dfields.name)
            
            dfields.desc:SetFont("DermaDefaultBold")
            dfields.desc:SetContentAlignment(7)
            dfields.desc:MoveBelow(dfields.type, 1)
            
            local iw, ih = dinfo:GetSize()
            
            local dhelp = vgui.Create("DPanel", dinfobg)
            dhelp:SetPaintBackground(false)
            dhelp:SetSize(diw, 64)
            dhelp:MoveBelow(dinfo, m)
            
            local update_preqs = PreqLabels(dhelp, m*7, m*2)
            
            dhelp:SizeToContents()
            
            local dconfirm = vgui.Create("DButton", dinfobg)
            dconfirm:SetPos(0, dih - bh*2)
            dconfirm:SetSize(bw, bh)
            dconfirm:SetDisabled(true)
            dconfirm:SetText(GetTranslation("equip_confirm"))
            
            
            dsheet:AddSheet(GetTranslation("equip_tabtitle"), dequip, "icon16/bomb.png", false, false, "Traitor equipment menu")
            
            -- Item control
            if ply:HasEquipmentItem(EQUIP_RADAR) then
               local dradar = RADAR.CreateMenu(dsheet, dframe)
               dsheet:AddSheet(GetTranslation("radar_name"), dradar, "icon16/magnifier.png", false,false, "Radar control")
            end
            
            if ply:HasEquipmentItem(EQUIP_DISGUISE) then
               local ddisguise = DISGUISE.CreateMenu(dsheet)
               dsheet:AddSheet(GetTranslation("disg_name"), ddisguise, "icon16/user.png", false,false, "Disguise control")
            end
            
            -- Weapon/item control
            if IsValid(ply.radio) or ply:HasWeapon("weapon_ttt_radio") then
               local dradio = TRADIO.CreateMenu(dsheet)
               dsheet:AddSheet(GetTranslation("radio_name"), dradio, "icon16/transmit.png", false,false, "Radio control")
            end
            
            -- Credit transferring
            if credits > 0 then
               local dtransfer = CreateTransferMenu(dsheet)
               dsheet:AddSheet(GetTranslation("xfer_name"), dtransfer, "icon16/group_gear.png", false,false, "Transfer credits")
            end
            
            hook.Run("TTTEquipmentTabs", dsheet)
            
            
            -- couple panelselect with info
            dlist.OnActivePanelChanged = function(self, _, new)
               for k,v in pairs(new.item) do
                  if dfields[k] then
                     dfields[k]:SetText(SafeTranslate(v))
                     dfields[k]:SetAutoStretchVertical(true)
                     dfields[k]:SetWrap(true)
                  end
               end
               
               -- Trying to force everything to update to
               -- the right size is a giant pain, so just
               -- force a good size.
               dfields.desc:SetTall(70)
               
               can_order = update_preqs(new.item)
               
               dconfirm:SetDisabled(not can_order)
            end
            
            -- select first
            dlist:SelectPanel(to_select or dlist:GetItems()[1])
            
            -- prep confirm action
            dconfirm.DoClick = function()
               local pnl = dlist.SelectedPanel
               if not pnl or not pnl.item then return end
               local choice = pnl.item
               RunConsoleCommand("ttt_order_equipment", choice.id)
               dframe:Close()
            end
            
            -- update some basic info, may have changed in another tab
            -- specifically the number of credits in the preq list
            dsheet.OnTabChanged = function(s, old, new)
               if not IsValid(new) then return end
               
               if new:GetPanel() == dequip then
                  can_order = update_preqs(dlist.SelectedPanel.item)
                  dconfirm:SetDisabled(not can_order)
               end
            end
            
            local dcancel = vgui.Create("DButton", dframe)
            dcancel:SetPos(w - 13 - bw, h - bh - 16)
            dcancel:SetSize(bw, bh)
            dcancel:SetDisabled(false)
            dcancel:SetText(GetTranslation("close"))
            dcancel.DoClick = function()
               dframe:Close()
            end
            
            function file.AppendLine(filename, addme)
               data = file.Read(filename)
               if ( data ) then
                  file.Write(filename, data .. "\n" .. tostring(addme))
               else
                  file.Write(filename, tostring(addme))
               end
            end
            
            --add as favorite button
            dfav = vgui.Create("DButton", dinfobg)
            dfav:SetPos(0, dih - bh*2)
            dfav:MoveRightOf(dconfirm)
            dfav:SetSize(bh, bh)
            dfav:SetDisabled(false)
            dfav:SetText("")
            dfav:SetImage("icon16/star.png")
            dfav.DoClick = function()
               local ply = LocalPlayer()
               local role = ply:GetRole()
               local guid = ply:SteamID()
               local pnl = dlist.SelectedPanel
               if not pnl or not pnl.item then return end
               local choice = pnl.item
               local weapon = choice.id
               CreateFavTable()
               if pnl.favorite then
                  RemoveFavorite(guid, role, weapon)
               else
                  AddFavorite(guid, role, weapon)
               end
            end
            
            dframe:MakePopup()
            dframe:SetKeyboardInputEnabled(false)
            
            eqframe = dframe
         end
      end
      if table.HasValue( randomweaponshop, "SK" ) then	
         if ply:GetRole() == ROLE_SERIALKILLER then
            local SKrandomitems = {}
            
            
            for k,v in pairs( items ) do 
               if v.id == 1 or v.id == 2 or v.id == 3 then
                  table.insert(SKrandomitems, v)
               else
                  if table.HasValue( SKranweaponshop, v.id ) then
                     table.insert(SKrandomitems, v)
                  else
                     if v.id == 1 or v.id == 2 or v.id == 3 then
                     else
                        table.remove(SKrandomitems, k)
                     end
                  end
               end
            end
            
            
            local to_select = nil
            
            -- temp table for sorting
            local paneltablefav = {}
            local paneltable = {}
            
            for k, item in pairs(SKrandomitems) do
               local ic = nil
               
               -- Create icon panel
               if item.material then
                  ic = vgui.Create("LayeredIcon", dlist)
                  
                  if item.custom && showCustomVar:GetBool() then
                     -- Custom marker icon
                     local marker = vgui.Create("DImage")
                     marker:SetImage("vgui/ttt/custom_marker")
                     marker.PerformLayout = function(s)
                        s:AlignBottom(2)
                        s:AlignRight(2)
                        s:SetSize(16, 16)
                     end
                     marker:SetTooltip(GetTranslation("equip_custom"))
                     
                     ic:AddLayer(marker)
                     
                     ic:EnableMousePassthrough(marker)
                  end
                  
                  -- Favorites marker icon
                  ic.favorite = false
                  local favorites = GetFavorites(ply:SteamID(), ply:GetRole())
                  if favorites then
                     if IsFavorite(favorites, item.id) then
                        ic.favorite = true
                        if showFavoriteVar:GetBool() then
                           local star = vgui.Create("DImage")
                           star:SetImage("icon16/star.png")
                           star.PerformLayout = function(s)
                              s:AlignTop(2)
                              s:AlignRight(2)
                              s:SetSize(12, 12)
                           end
                           star:SetTooltip("Favorite")
                           ic:AddLayer(star)
                           ic:EnableMousePassthrough(star)
                        end
                     end
                  end
                  
                  -- Slot marker icon
                  if ItemIsWeapon(item) && showSlotVar:GetBool() then
                     local slot = vgui.Create("SimpleIconLabelled")
                     slot:SetIcon("vgui/ttt/slotcap")
                     slot:SetIconColor(color_slot[ply:GetRole()] or COLOR_GREY)
                     slot:SetIconSize(16)
                     
                     slot:SetIconText(item.slot)
                     
                     slot:SetIconProperties(COLOR_WHITE,
                     "DefaultBold",
                     {opacity=220, offset=1},
                     {10, 8})
                     
                     ic:AddLayer(slot)
                     ic:EnableMousePassthrough(slot)
                  end
                  
                  ic:SetIconSize(itemSize)
                  ic:SetIcon(item.material)
               elseif item.model then
                  ic = vgui.Create("SpawnIcon", dlist)
                  ic:SetModel(item.model)
               else
                  ErrorNoHalt("Equipment item does not have model or material specified: " .. tostring(item) .. "\n")
               end
               
               ic.item = item
               
               local tip = SafeTranslate(item.name) .. " (" .. SafeTranslate(item.type) .. ")"
               ic:SetTooltip(tip)
               
               -- If we cannot order this item, darken it
               if ((not can_order) or
               -- already owned
               table.HasValue(owned_ids, item.id) or
               (tonumber(item.id) and ply:HasEquipmentItem(tonumber(item.id))) or
               -- already carrying a weapon for this slot
               (ItemIsWeapon(item) and (not CanCarryWeapon(item))) or
               -- already bought the item before
               (item.limited and ply:HasBought(tostring(item.id)))) then
                  
                  ic:SetIconColor(color_darkened)
               end
               
               if ic.favorite then
                  paneltablefav[k] = ic
               else
                  paneltable[k] = ic
               end
               
            end
            
            -- add favorites first
            for _, panel in pairs(paneltablefav) do
               dlist:AddPanel(panel)
            end
            -- non favorites second
            for _, panel in pairs(paneltable) do
               dlist:AddPanel(panel)
            end
            
            local bw, bh = 100, 25
            
            -- Whole right column
            local dih = h - bh - m*5
            -- local diw = w - dlistw - m*6 - 2
            local dinfobg = vgui.Create("DPanel", dequip)
            dinfobg:SetPaintBackground(false)
            dinfobg:SetSize(diw - m, dih)
            dinfobg:SetPos(dlistw + m, 0)
            
            -- item info pane
            local dinfo = vgui.Create("ColoredBox", dinfobg)
            dinfo:SetColor(Color(90, 90, 95))
            dinfo:SetPos(0,0)
            dinfo:StretchToParent(0, 0, m*2, 105)
            
            local dfields = {}
            for _, k in pairs({"name", "type", "desc"}) do
               dfields[k] = vgui.Create("DLabel", dinfo)
               dfields[k]:SetTooltip(GetTranslation("equip_spec_" .. k))
               dfields[k]:SetPos(m*3, m*2)
               dfields[k]:SetWidth(diw - m*6)
            end
            
            dfields.name:SetFont("TabLarge")
            
            dfields.type:SetFont("DermaDefault")
            dfields.type:MoveBelow(dfields.name)
            
            dfields.desc:SetFont("DermaDefaultBold")
            dfields.desc:SetContentAlignment(7)
            dfields.desc:MoveBelow(dfields.type, 1)
            
            local iw, ih = dinfo:GetSize()
            
            local dhelp = vgui.Create("DPanel", dinfobg)
            dhelp:SetPaintBackground(false)
            dhelp:SetSize(diw, 64)
            dhelp:MoveBelow(dinfo, m)
            
            local update_preqs = PreqLabels(dhelp, m*7, m*2)
            
            dhelp:SizeToContents()
            
            local dconfirm = vgui.Create("DButton", dinfobg)
            dconfirm:SetPos(0, dih - bh*2)
            dconfirm:SetSize(bw, bh)
            dconfirm:SetDisabled(true)
            dconfirm:SetText(GetTranslation("equip_confirm"))
            
            
            dsheet:AddSheet(GetTranslation("equip_tabtitle"), dequip, "icon16/bomb.png", false, false, "Traitor equipment menu")
            
            -- Item control
            if ply:HasEquipmentItem(EQUIP_RADAR) then
               local dradar = RADAR.CreateMenu(dsheet, dframe)
               dsheet:AddSheet(GetTranslation("radar_name"), dradar, "icon16/magnifier.png", false,false, "Radar control")
            end
            
            if ply:HasEquipmentItem(EQUIP_DISGUISE) then
               local ddisguise = DISGUISE.CreateMenu(dsheet)
               dsheet:AddSheet(GetTranslation("disg_name"), ddisguise, "icon16/user.png", false,false, "Disguise control")
            end
            
            -- Weapon/item control
            if IsValid(ply.radio) or ply:HasWeapon("weapon_ttt_radio") then
               local dradio = TRADIO.CreateMenu(dsheet)
               dsheet:AddSheet(GetTranslation("radio_name"), dradio, "icon16/transmit.png", false,false, "Radio control")
            end
            
            -- Credit transferring
            if credits > 0 then
               local dtransfer = CreateTransferMenu(dsheet)
               dsheet:AddSheet(GetTranslation("xfer_name"), dtransfer, "icon16/group_gear.png", false,false, "Transfer credits")
            end
            
            hook.Run("TTTEquipmentTabs", dsheet)
            
            
            -- couple panelselect with info
            dlist.OnActivePanelChanged = function(self, _, new)
               for k,v in pairs(new.item) do
                  if dfields[k] then
                     dfields[k]:SetText(SafeTranslate(v))
                     dfields[k]:SetAutoStretchVertical(true)
                     dfields[k]:SetWrap(true)
                  end
               end
               
               -- Trying to force everything to update to
               -- the right size is a giant pain, so just
               -- force a good size.
               dfields.desc:SetTall(70)
               
               can_order = update_preqs(new.item)
               
               dconfirm:SetDisabled(not can_order)
            end
            
            -- select first
            dlist:SelectPanel(to_select or dlist:GetItems()[1])
            
            -- prep confirm action
            dconfirm.DoClick = function()
               local pnl = dlist.SelectedPanel
               if not pnl or not pnl.item then return end
               local choice = pnl.item
               RunConsoleCommand("ttt_order_equipment", choice.id)
               dframe:Close()
            end
            
            -- update some basic info, may have changed in another tab
            -- specifically the number of credits in the preq list
            dsheet.OnTabChanged = function(s, old, new)
               if not IsValid(new) then return end
               
               if new:GetPanel() == dequip then
                  can_order = update_preqs(dlist.SelectedPanel.item)
                  dconfirm:SetDisabled(not can_order)
               end
            end
            
            local dcancel = vgui.Create("DButton", dframe)
            dcancel:SetPos(w - 13 - bw, h - bh - 16)
            dcancel:SetSize(bw, bh)
            dcancel:SetDisabled(false)
            dcancel:SetText(GetTranslation("close"))
            dcancel.DoClick = function()
               dframe:Close()
            end
            
            function file.AppendLine(filename, addme)
               data = file.Read(filename)
               if ( data ) then
                  file.Write(filename, data .. "\n" .. tostring(addme))
               else
                  file.Write(filename, tostring(addme))
               end
            end
            
            --add as favorite button
            dfav = vgui.Create("DButton", dinfobg)
            dfav:SetPos(0, dih - bh*2)
            dfav:MoveRightOf(dconfirm)
            dfav:SetSize(bh, bh)
            dfav:SetDisabled(false)
            dfav:SetText("")
            dfav:SetImage("icon16/star.png")
            dfav.DoClick = function()
               local ply = LocalPlayer()
               local role = ply:GetRole()
               local guid = ply:SteamID()
               local pnl = dlist.SelectedPanel
               if not pnl or not pnl.item then return end
               local choice = pnl.item
               local weapon = choice.id
               CreateFavTable()
               if pnl.favorite then
                  RemoveFavorite(guid, role, weapon)
               else
                  AddFavorite(guid, role, weapon)
               end
            end
            
            dframe:MakePopup()
            dframe:SetKeyboardInputEnabled(false)
            
            eqframe = dframe
         end
         
      end
      if table.HasValue( randomweaponshop, "No T" ) then
         if ply:GetRole() == ROLE_TRAITOR then
            local to_select = nil
            
            -- temp table for sorting
            local paneltablefav = {}
            local paneltable = {}
            
            for k, item in pairs(items) do
               local ic = nil
               
               -- Create icon panel
               if item.material then
                  ic = vgui.Create("LayeredIcon", dlist)
                  
                  if item.custom && showCustomVar:GetBool() then
                     -- Custom marker icon
                     local marker = vgui.Create("DImage")
                     marker:SetImage("vgui/ttt/custom_marker")
                     marker.PerformLayout = function(s)
                        s:AlignBottom(2)
                        s:AlignRight(2)
                        s:SetSize(16, 16)
                     end
                     marker:SetTooltip(GetTranslation("equip_custom"))
                     
                     ic:AddLayer(marker)
                     
                     ic:EnableMousePassthrough(marker)
                  end
                  
                  -- Favorites marker icon
                  ic.favorite = false
                  local favorites = GetFavorites(ply:SteamID(), ply:GetRole())
                  if favorites then
                     if IsFavorite(favorites, item.id) then
                        ic.favorite = true
                        if showFavoriteVar:GetBool() then
                           local star = vgui.Create("DImage")
                           star:SetImage("icon16/star.png")
                           star.PerformLayout = function(s)
                              s:AlignTop(2)
                              s:AlignRight(2)
                              s:SetSize(12, 12)
                           end
                           star:SetTooltip("Favorite")
                           ic:AddLayer(star)
                           ic:EnableMousePassthrough(star)
                        end
                     end
                  end
                  
                  -- Slot marker icon
                  if ItemIsWeapon(item) && showSlotVar:GetBool() then
                     local slot = vgui.Create("SimpleIconLabelled")
                     slot:SetIcon("vgui/ttt/slotcap")
                     slot:SetIconColor(color_slot[ply:GetRole()] or COLOR_GREY)
                     slot:SetIconSize(16)
                     
                     slot:SetIconText(item.slot)
                     
                     slot:SetIconProperties(COLOR_WHITE,
                     "DefaultBold",
                     {opacity=220, offset=1},
                     {10, 8})
                     
                     ic:AddLayer(slot)
                     ic:EnableMousePassthrough(slot)
                  end
                  
                  ic:SetIconSize(itemSize)
                  ic:SetIcon(item.material)
               elseif item.model then
                  ic = vgui.Create("SpawnIcon", dlist)
                  ic:SetModel(item.model)
               else
                  ErrorNoHalt("Equipment item does not have model or material specified: " .. tostring(item) .. "\n")
               end
               
               ic.item = item
               
               local tip = SafeTranslate(item.name) .. " (" .. SafeTranslate(item.type) .. ")"
               ic:SetTooltip(tip)
               
               -- If we cannot order this item, darken it
               if ((not can_order) or
               -- already owned
               table.HasValue(owned_ids, item.id) or
               (tonumber(item.id) and ply:HasEquipmentItem(tonumber(item.id))) or
               -- already carrying a weapon for this slot
               (ItemIsWeapon(item) and (not CanCarryWeapon(item))) or
               -- already bought the item before
               (item.limited and ply:HasBought(tostring(item.id)))) then
                  
                  ic:SetIconColor(color_darkened)
               end
               
               if ic.favorite then
                  paneltablefav[k] = ic
               else
                  paneltable[k] = ic
               end
               
            end
            
            -- add favorites first
            for _, panel in pairs(paneltablefav) do
               dlist:AddPanel(panel)
            end
            -- non favorites second
            for _, panel in pairs(paneltable) do
               dlist:AddPanel(panel)
            end
            
            local bw, bh = 100, 25
            
            -- Whole right column
            local dih = h - bh - m*5
            -- local diw = w - dlistw - m*6 - 2
            local dinfobg = vgui.Create("DPanel", dequip)
            dinfobg:SetPaintBackground(false)
            dinfobg:SetSize(diw - m, dih)
            dinfobg:SetPos(dlistw + m, 0)
            
            -- item info pane
            local dinfo = vgui.Create("ColoredBox", dinfobg)
            dinfo:SetColor(Color(90, 90, 95))
            dinfo:SetPos(0,0)
            dinfo:StretchToParent(0, 0, m*2, 105)
            
            local dfields = {}
            for _, k in pairs({"name", "type", "desc"}) do
               dfields[k] = vgui.Create("DLabel", dinfo)
               dfields[k]:SetTooltip(GetTranslation("equip_spec_" .. k))
               dfields[k]:SetPos(m*3, m*2)
               dfields[k]:SetWidth(diw - m*6)
            end
            
            dfields.name:SetFont("TabLarge")
            
            dfields.type:SetFont("DermaDefault")
            dfields.type:MoveBelow(dfields.name)
            
            dfields.desc:SetFont("DermaDefaultBold")
            dfields.desc:SetContentAlignment(7)
            dfields.desc:MoveBelow(dfields.type, 1)
            
            local iw, ih = dinfo:GetSize()
            
            local dhelp = vgui.Create("DPanel", dinfobg)
            dhelp:SetPaintBackground(false)
            dhelp:SetSize(diw, 64)
            dhelp:MoveBelow(dinfo, m)
            
            local update_preqs = PreqLabels(dhelp, m*7, m*2)
            
            dhelp:SizeToContents()
            
            local dconfirm = vgui.Create("DButton", dinfobg)
            dconfirm:SetPos(0, dih - bh*2)
            dconfirm:SetSize(bw, bh)
            dconfirm:SetDisabled(true)
            dconfirm:SetText(GetTranslation("equip_confirm"))
            
            
            dsheet:AddSheet(GetTranslation("equip_tabtitle"), dequip, "icon16/bomb.png", false, false, "Traitor equipment menu")
            
            -- Item control
            if ply:HasEquipmentItem(EQUIP_RADAR) then
               local dradar = RADAR.CreateMenu(dsheet, dframe)
               dsheet:AddSheet(GetTranslation("radar_name"), dradar, "icon16/magnifier.png", false,false, "Radar control")
            end
            
            if ply:HasEquipmentItem(EQUIP_DISGUISE) then
               local ddisguise = DISGUISE.CreateMenu(dsheet)
               dsheet:AddSheet(GetTranslation("disg_name"), ddisguise, "icon16/user.png", false,false, "Disguise control")
            end
            
            -- Weapon/item control
            if IsValid(ply.radio) or ply:HasWeapon("weapon_ttt_radio") then
               local dradio = TRADIO.CreateMenu(dsheet)
               dsheet:AddSheet(GetTranslation("radio_name"), dradio, "icon16/transmit.png", false,false, "Radio control")
            end
            
            -- Credit transferring
            if credits > 0 then
               local dtransfer = CreateTransferMenu(dsheet)
               dsheet:AddSheet(GetTranslation("xfer_name"), dtransfer, "icon16/group_gear.png", false,false, "Transfer credits")
            end
            
            hook.Run("TTTEquipmentTabs", dsheet)
            
            
            -- couple panelselect with info
            dlist.OnActivePanelChanged = function(self, _, new)
               for k,v in pairs(new.item) do
                  if dfields[k] then
                     dfields[k]:SetText(SafeTranslate(v))
                     dfields[k]:SetAutoStretchVertical(true)
                     dfields[k]:SetWrap(true)
                  end
               end
               
               -- Trying to force everything to update to
               -- the right size is a giant pain, so just
               -- force a good size.
               dfields.desc:SetTall(70)
               
               can_order = update_preqs(new.item)
               
               dconfirm:SetDisabled(not can_order)
            end
            
            -- select first
            dlist:SelectPanel(to_select or dlist:GetItems()[1])
            
            -- prep confirm action
            dconfirm.DoClick = function()
               local pnl = dlist.SelectedPanel
               if not pnl or not pnl.item then return end
               local choice = pnl.item
               RunConsoleCommand("ttt_order_equipment", choice.id)
               dframe:Close()
            end
            
            -- update some basic info, may have changed in another tab
            -- specifically the number of credits in the preq list
            dsheet.OnTabChanged = function(s, old, new)
               if not IsValid(new) then return end
               
               if new:GetPanel() == dequip then
                  can_order = update_preqs(dlist.SelectedPanel.item)
                  dconfirm:SetDisabled(not can_order)
               end
            end
            
            local dcancel = vgui.Create("DButton", dframe)
            dcancel:SetPos(w - 13 - bw, h - bh - 16)
            dcancel:SetSize(bw, bh)
            dcancel:SetDisabled(false)
            dcancel:SetText(GetTranslation("close"))
            dcancel.DoClick = function()
               dframe:Close()
            end
            
            function file.AppendLine(filename, addme)
               data = file.Read(filename)
               if ( data ) then
                  file.Write(filename, data .. "\n" .. tostring(addme))
               else
                  file.Write(filename, tostring(addme))
               end
            end
            
            --add as favorite button
            dfav = vgui.Create("DButton", dinfobg)
            dfav:SetPos(0, dih - bh*2)
            dfav:MoveRightOf(dconfirm)
            dfav:SetSize(bh, bh)
            dfav:SetDisabled(false)
            dfav:SetText("")
            dfav:SetImage("icon16/star.png")
            dfav.DoClick = function()
               local ply = LocalPlayer()
               local role = ply:GetRole()
               local guid = ply:SteamID()
               local pnl = dlist.SelectedPanel
               if not pnl or not pnl.item then return end
               local choice = pnl.item
               local weapon = choice.id
               CreateFavTable()
               if pnl.favorite then
                  RemoveFavorite(guid, role, weapon)
               else
                  AddFavorite(guid, role, weapon)
               end
            end
            
            dframe:MakePopup()
            dframe:SetKeyboardInputEnabled(false)
            
            eqframe = dframe
         end
      end
      if table.HasValue( randomweaponshop, "No S" ) then
         if ply:GetRole() == ROLE_SURVIVALIST then
            local to_select = nil
            
            -- temp table for sorting
            local paneltablefav = {}
            local paneltable = {}
            
            for k, item in pairs(items) do
               local ic = nil
               
               -- Create icon panel
               if item.material then
                  ic = vgui.Create("LayeredIcon", dlist)
                  
                  if item.custom && showCustomVar:GetBool() then
                     -- Custom marker icon
                     local marker = vgui.Create("DImage")
                     marker:SetImage("vgui/ttt/custom_marker")
                     marker.PerformLayout = function(s)
                        s:AlignBottom(2)
                        s:AlignRight(2)
                        s:SetSize(16, 16)
                     end
                     marker:SetTooltip(GetTranslation("equip_custom"))
                     
                     ic:AddLayer(marker)
                     
                     ic:EnableMousePassthrough(marker)
                  end
                  
                  -- Favorites marker icon
                  ic.favorite = false
                  local favorites = GetFavorites(ply:SteamID(), ply:GetRole())
                  if favorites then
                     if IsFavorite(favorites, item.id) then
                        ic.favorite = true
                        if showFavoriteVar:GetBool() then
                           local star = vgui.Create("DImage")
                           star:SetImage("icon16/star.png")
                           star.PerformLayout = function(s)
                              s:AlignTop(2)
                              s:AlignRight(2)
                              s:SetSize(12, 12)
                           end
                           star:SetTooltip("Favorite")
                           ic:AddLayer(star)
                           ic:EnableMousePassthrough(star)
                        end
                     end
                  end
                  
                  -- Slot marker icon
                  if ItemIsWeapon(item) && showSlotVar:GetBool() then
                     local slot = vgui.Create("SimpleIconLabelled")
                     slot:SetIcon("vgui/ttt/slotcap")
                     slot:SetIconColor(color_slot[ply:GetRole()] or COLOR_GREY)
                     slot:SetIconSize(16)
                     
                     slot:SetIconText(item.slot)
                     
                     slot:SetIconProperties(COLOR_WHITE,
                     "DefaultBold",
                     {opacity=220, offset=1},
                     {10, 8})
                     
                     ic:AddLayer(slot)
                     ic:EnableMousePassthrough(slot)
                  end
                  
                  ic:SetIconSize(itemSize)
                  ic:SetIcon(item.material)
               elseif item.model then
                  ic = vgui.Create("SpawnIcon", dlist)
                  ic:SetModel(item.model)
               else
                  ErrorNoHalt("Equipment item does not have model or material specified: " .. tostring(item) .. "\n")
               end
               
               ic.item = item
               
               local tip = SafeTranslate(item.name) .. " (" .. SafeTranslate(item.type) .. ")"
               ic:SetTooltip(tip)
               
               -- If we cannot order this item, darken it
               if ((not can_order) or
               -- already owned
               table.HasValue(owned_ids, item.id) or
               (tonumber(item.id) and ply:HasEquipmentItem(tonumber(item.id))) or
               -- already carrying a weapon for this slot
               (ItemIsWeapon(item) and (not CanCarryWeapon(item))) or
               -- already bought the item before
               (item.limited and ply:HasBought(tostring(item.id)))) then
                  
                  ic:SetIconColor(color_darkened)
               end
               
               if ic.favorite then
                  paneltablefav[k] = ic
               else
                  paneltable[k] = ic
               end
               
            end
            
            -- add favorites first
            for _, panel in pairs(paneltablefav) do
               dlist:AddPanel(panel)
            end
            -- non favorites second
            for _, panel in pairs(paneltable) do
               dlist:AddPanel(panel)
            end
            
            local bw, bh = 100, 25
            
            -- Whole right column
            local dih = h - bh - m*5
            -- local diw = w - dlistw - m*6 - 2
            local dinfobg = vgui.Create("DPanel", dequip)
            dinfobg:SetPaintBackground(false)
            dinfobg:SetSize(diw - m, dih)
            dinfobg:SetPos(dlistw + m, 0)
            
            -- item info pane
            local dinfo = vgui.Create("ColoredBox", dinfobg)
            dinfo:SetColor(Color(90, 90, 95))
            dinfo:SetPos(0,0)
            dinfo:StretchToParent(0, 0, m*2, 105)
            
            local dfields = {}
            for _, k in pairs({"name", "type", "desc"}) do
               dfields[k] = vgui.Create("DLabel", dinfo)
               dfields[k]:SetTooltip(GetTranslation("equip_spec_" .. k))
               dfields[k]:SetPos(m*3, m*2)
               dfields[k]:SetWidth(diw - m*6)
            end
            
            dfields.name:SetFont("TabLarge")
            
            dfields.type:SetFont("DermaDefault")
            dfields.type:MoveBelow(dfields.name)
            
            dfields.desc:SetFont("DermaDefaultBold")
            dfields.desc:SetContentAlignment(7)
            dfields.desc:MoveBelow(dfields.type, 1)
            
            local iw, ih = dinfo:GetSize()
            
            local dhelp = vgui.Create("DPanel", dinfobg)
            dhelp:SetPaintBackground(false)
            dhelp:SetSize(diw, 64)
            dhelp:MoveBelow(dinfo, m)
            
            local update_preqs = PreqLabels(dhelp, m*7, m*2)
            
            dhelp:SizeToContents()
            
            local dconfirm = vgui.Create("DButton", dinfobg)
            dconfirm:SetPos(0, dih - bh*2)
            dconfirm:SetSize(bw, bh)
            dconfirm:SetDisabled(true)
            dconfirm:SetText(GetTranslation("equip_confirm"))
            
            
            dsheet:AddSheet(GetTranslation("equip_tabtitle"), dequip, "icon16/bomb.png", false, false, "Traitor equipment menu")
            
            -- Item control
            if ply:HasEquipmentItem(EQUIP_RADAR) then
               local dradar = RADAR.CreateMenu(dsheet, dframe)
               dsheet:AddSheet(GetTranslation("radar_name"), dradar, "icon16/magnifier.png", false,false, "Radar control")
            end
            
            if ply:HasEquipmentItem(EQUIP_DISGUISE) then
               local ddisguise = DISGUISE.CreateMenu(dsheet)
               dsheet:AddSheet(GetTranslation("disg_name"), ddisguise, "icon16/user.png", false,false, "Disguise control")
            end
            
            -- Weapon/item control
            if IsValid(ply.radio) or ply:HasWeapon("weapon_ttt_radio") then
               local dradio = TRADIO.CreateMenu(dsheet)
               dsheet:AddSheet(GetTranslation("radio_name"), dradio, "icon16/transmit.png", false,false, "Radio control")
            end
            
            -- Credit transferring
            if credits > 0 then
               local dtransfer = CreateTransferMenu(dsheet)
               dsheet:AddSheet(GetTranslation("xfer_name"), dtransfer, "icon16/group_gear.png", false,false, "Transfer credits")
            end
            
            hook.Run("TTTEquipmentTabs", dsheet)
            
            
            -- couple panelselect with info
            dlist.OnActivePanelChanged = function(self, _, new)
               for k,v in pairs(new.item) do
                  if dfields[k] then
                     dfields[k]:SetText(SafeTranslate(v))
                     dfields[k]:SetAutoStretchVertical(true)
                     dfields[k]:SetWrap(true)
                  end
               end
               
               -- Trying to force everything to update to
               -- the right size is a giant pain, so just
               -- force a good size.
               dfields.desc:SetTall(70)
               
               can_order = update_preqs(new.item)
               
               dconfirm:SetDisabled(not can_order)
            end
            
            -- select first
            dlist:SelectPanel(to_select or dlist:GetItems()[1])
            
            -- prep confirm action
            dconfirm.DoClick = function()
               local pnl = dlist.SelectedPanel
               if not pnl or not pnl.item then return end
               local choice = pnl.item
               RunConsoleCommand("ttt_order_equipment", choice.id)
               dframe:Close()
            end
            
            -- update some basic info, may have changed in another tab
            -- specifically the number of credits in the preq list
            dsheet.OnTabChanged = function(s, old, new)
               if not IsValid(new) then return end
               
               if new:GetPanel() == dequip then
                  can_order = update_preqs(dlist.SelectedPanel.item)
                  dconfirm:SetDisabled(not can_order)
               end
            end
            
            local dcancel = vgui.Create("DButton", dframe)
            dcancel:SetPos(w - 13 - bw, h - bh - 16)
            dcancel:SetSize(bw, bh)
            dcancel:SetDisabled(false)
            dcancel:SetText(GetTranslation("close"))
            dcancel.DoClick = function()
               dframe:Close()
            end
            
            function file.AppendLine(filename, addme)
               data = file.Read(filename)
               if ( data ) then
                  file.Write(filename, data .. "\n" .. tostring(addme))
               else
                  file.Write(filename, tostring(addme))
               end
            end
            
            --add as favorite button
            dfav = vgui.Create("DButton", dinfobg)
            dfav:SetPos(0, dih - bh*2)
            dfav:MoveRightOf(dconfirm)
            dfav:SetSize(bh, bh)
            dfav:SetDisabled(false)
            dfav:SetText("")
            dfav:SetImage("icon16/star.png")
            dfav.DoClick = function()
               local ply = LocalPlayer()
               local role = ply:GetRole()
               local guid = ply:SteamID()
               local pnl = dlist.SelectedPanel
               if not pnl or not pnl.item then return end
               local choice = pnl.item
               local weapon = choice.id
               CreateFavTable()
               if pnl.favorite then
                  RemoveFavorite(guid, role, weapon)
               else
                  AddFavorite(guid, role, weapon)
               end
            end
            
            dframe:MakePopup()
            dframe:SetKeyboardInputEnabled(false)
            
            eqframe = dframe
         end
      end
      if table.HasValue( randomweaponshop, "No D" ) then
         if ply:GetRole() == ROLE_DETECTIVE then
            local to_select = nil
            
            -- temp table for sorting
            local paneltablefav = {}
            local paneltable = {}
            
            for k, item in pairs(items) do
               local ic = nil
               
               -- Create icon panel
               if item.material then
                  ic = vgui.Create("LayeredIcon", dlist)
                  
                  if item.custom && showCustomVar:GetBool() then
                     -- Custom marker icon
                     local marker = vgui.Create("DImage")
                     marker:SetImage("vgui/ttt/custom_marker")
                     marker.PerformLayout = function(s)
                        s:AlignBottom(2)
                        s:AlignRight(2)
                        s:SetSize(16, 16)
                     end
                     marker:SetTooltip(GetTranslation("equip_custom"))
                     
                     ic:AddLayer(marker)
                     
                     ic:EnableMousePassthrough(marker)
                  end
                  
                  -- Favorites marker icon
                  ic.favorite = false
                  local favorites = GetFavorites(ply:SteamID(), ply:GetRole())
                  if favorites then
                     if IsFavorite(favorites, item.id) then
                        ic.favorite = true
                        if showFavoriteVar:GetBool() then
                           local star = vgui.Create("DImage")
                           star:SetImage("icon16/star.png")
                           star.PerformLayout = function(s)
                              s:AlignTop(2)
                              s:AlignRight(2)
                              s:SetSize(12, 12)
                           end
                           star:SetTooltip("Favorite")
                           ic:AddLayer(star)
                           ic:EnableMousePassthrough(star)
                        end
                     end
                  end
                  
                  -- Slot marker icon
                  if ItemIsWeapon(item) && showSlotVar:GetBool() then
                     local slot = vgui.Create("SimpleIconLabelled")
                     slot:SetIcon("vgui/ttt/slotcap")
                     slot:SetIconColor(color_slot[ply:GetRole()] or COLOR_GREY)
                     slot:SetIconSize(16)
                     
                     slot:SetIconText(item.slot)
                     
                     slot:SetIconProperties(COLOR_WHITE,
                     "DefaultBold",
                     {opacity=220, offset=1},
                     {10, 8})
                     
                     ic:AddLayer(slot)
                     ic:EnableMousePassthrough(slot)
                  end
                  
                  ic:SetIconSize(itemSize)
                  ic:SetIcon(item.material)
               elseif item.model then
                  ic = vgui.Create("SpawnIcon", dlist)
                  ic:SetModel(item.model)
               else
                  ErrorNoHalt("Equipment item does not have model or material specified: " .. tostring(item) .. "\n")
               end
               
               ic.item = item
               
               local tip = SafeTranslate(item.name) .. " (" .. SafeTranslate(item.type) .. ")"
               ic:SetTooltip(tip)
               
               -- If we cannot order this item, darken it
               if ((not can_order) or
               -- already owned
               table.HasValue(owned_ids, item.id) or
               (tonumber(item.id) and ply:HasEquipmentItem(tonumber(item.id))) or
               -- already carrying a weapon for this slot
               (ItemIsWeapon(item) and (not CanCarryWeapon(item))) or
               -- already bought the item before
               (item.limited and ply:HasBought(tostring(item.id)))) then
                  
                  ic:SetIconColor(color_darkened)
               end
               
               if ic.favorite then
                  paneltablefav[k] = ic
               else
                  paneltable[k] = ic
               end
               
            end
            
            -- add favorites first
            for _, panel in pairs(paneltablefav) do
               dlist:AddPanel(panel)
            end
            -- non favorites second
            for _, panel in pairs(paneltable) do
               dlist:AddPanel(panel)
            end
            
            local bw, bh = 100, 25
            
            -- Whole right column
            local dih = h - bh - m*5
            -- local diw = w - dlistw - m*6 - 2
            local dinfobg = vgui.Create("DPanel", dequip)
            dinfobg:SetPaintBackground(false)
            dinfobg:SetSize(diw - m, dih)
            dinfobg:SetPos(dlistw + m, 0)
            
            -- item info pane
            local dinfo = vgui.Create("ColoredBox", dinfobg)
            dinfo:SetColor(Color(90, 90, 95))
            dinfo:SetPos(0,0)
            dinfo:StretchToParent(0, 0, m*2, 105)
            
            local dfields = {}
            for _, k in pairs({"name", "type", "desc"}) do
               dfields[k] = vgui.Create("DLabel", dinfo)
               dfields[k]:SetTooltip(GetTranslation("equip_spec_" .. k))
               dfields[k]:SetPos(m*3, m*2)
               dfields[k]:SetWidth(diw - m*6)
            end
            
            dfields.name:SetFont("TabLarge")
            
            dfields.type:SetFont("DermaDefault")
            dfields.type:MoveBelow(dfields.name)
            
            dfields.desc:SetFont("DermaDefaultBold")
            dfields.desc:SetContentAlignment(7)
            dfields.desc:MoveBelow(dfields.type, 1)
            
            local iw, ih = dinfo:GetSize()
            
            local dhelp = vgui.Create("DPanel", dinfobg)
            dhelp:SetPaintBackground(false)
            dhelp:SetSize(diw, 64)
            dhelp:MoveBelow(dinfo, m)
            
            local update_preqs = PreqLabels(dhelp, m*7, m*2)
            
            dhelp:SizeToContents()
            
            local dconfirm = vgui.Create("DButton", dinfobg)
            dconfirm:SetPos(0, dih - bh*2)
            dconfirm:SetSize(bw, bh)
            dconfirm:SetDisabled(true)
            dconfirm:SetText(GetTranslation("equip_confirm"))
            
            
            dsheet:AddSheet(GetTranslation("equip_tabtitle"), dequip, "icon16/bomb.png", false, false, "Traitor equipment menu")
            
            -- Item control
            if ply:HasEquipmentItem(EQUIP_RADAR) then
               local dradar = RADAR.CreateMenu(dsheet, dframe)
               dsheet:AddSheet(GetTranslation("radar_name"), dradar, "icon16/magnifier.png", false,false, "Radar control")
            end
            
            if ply:HasEquipmentItem(EQUIP_DISGUISE) then
               local ddisguise = DISGUISE.CreateMenu(dsheet)
               dsheet:AddSheet(GetTranslation("disg_name"), ddisguise, "icon16/user.png", false,false, "Disguise control")
            end
            
            -- Weapon/item control
            if IsValid(ply.radio) or ply:HasWeapon("weapon_ttt_radio") then
               local dradio = TRADIO.CreateMenu(dsheet)
               dsheet:AddSheet(GetTranslation("radio_name"), dradio, "icon16/transmit.png", false,false, "Radio control")
            end
            
            -- Credit transferring
            if credits > 0 then
               local dtransfer = CreateTransferMenu(dsheet)
               dsheet:AddSheet(GetTranslation("xfer_name"), dtransfer, "icon16/group_gear.png", false,false, "Transfer credits")
            end
            
            hook.Run("TTTEquipmentTabs", dsheet)
            
            
            -- couple panelselect with info
            dlist.OnActivePanelChanged = function(self, _, new)
               for k,v in pairs(new.item) do
                  if dfields[k] then
                     dfields[k]:SetText(SafeTranslate(v))
                     dfields[k]:SetAutoStretchVertical(true)
                     dfields[k]:SetWrap(true)
                  end
               end
               
               -- Trying to force everything to update to
               -- the right size is a giant pain, so just
               -- force a good size.
               dfields.desc:SetTall(70)
               
               can_order = update_preqs(new.item)
               
               dconfirm:SetDisabled(not can_order)
            end
            
            -- select first
            dlist:SelectPanel(to_select or dlist:GetItems()[1])
            
            -- prep confirm action
            dconfirm.DoClick = function()
               local pnl = dlist.SelectedPanel
               if not pnl or not pnl.item then return end
               local choice = pnl.item
               RunConsoleCommand("ttt_order_equipment", choice.id)
               dframe:Close()
            end
            
            -- update some basic info, may have changed in another tab
            -- specifically the number of credits in the preq list
            dsheet.OnTabChanged = function(s, old, new)
               if not IsValid(new) then return end
               
               if new:GetPanel() == dequip then
                  can_order = update_preqs(dlist.SelectedPanel.item)
                  dconfirm:SetDisabled(not can_order)
               end
            end
            
            local dcancel = vgui.Create("DButton", dframe)
            dcancel:SetPos(w - 13 - bw, h - bh - 16)
            dcancel:SetSize(bw, bh)
            dcancel:SetDisabled(false)
            dcancel:SetText(GetTranslation("close"))
            dcancel.DoClick = function()
               dframe:Close()
            end
            
            function file.AppendLine(filename, addme)
               data = file.Read(filename)
               if ( data ) then
                  file.Write(filename, data .. "\n" .. tostring(addme))
               else
                  file.Write(filename, tostring(addme))
               end
            end
            
            --add as favorite button
            dfav = vgui.Create("DButton", dinfobg)
            dfav:SetPos(0, dih - bh*2)
            dfav:MoveRightOf(dconfirm)
            dfav:SetSize(bh, bh)
            dfav:SetDisabled(false)
            dfav:SetText("")
            dfav:SetImage("icon16/star.png")
            dfav.DoClick = function()
               local ply = LocalPlayer()
               local role = ply:GetRole()
               local guid = ply:SteamID()
               local pnl = dlist.SelectedPanel
               if not pnl or not pnl.item then return end
               local choice = pnl.item
               local weapon = choice.id
               CreateFavTable()
               if pnl.favorite then
                  RemoveFavorite(guid, role, weapon)
               else
                  AddFavorite(guid, role, weapon)
               end
            end
            
            dframe:MakePopup()
            dframe:SetKeyboardInputEnabled(false)
            
            eqframe = dframe
         end
      end
      if table.HasValue( randomweaponshop, "No SK" ) then
         if ply:GetRole() == ROLE_SERIALKILLER then
            local to_select = nil
            
            -- temp table for sorting
            local paneltablefav = {}
            local paneltable = {}
            
            for k, item in pairs(items) do
               local ic = nil
               
               -- Create icon panel
               if item.material then
                  ic = vgui.Create("LayeredIcon", dlist)
                  
                  if item.custom && showCustomVar:GetBool() then
                     -- Custom marker icon
                     local marker = vgui.Create("DImage")
                     marker:SetImage("vgui/ttt/custom_marker")
                     marker.PerformLayout = function(s)
                        s:AlignBottom(2)
                        s:AlignRight(2)
                        s:SetSize(16, 16)
                     end
                     marker:SetTooltip(GetTranslation("equip_custom"))
                     
                     ic:AddLayer(marker)
                     
                     ic:EnableMousePassthrough(marker)
                  end
                  
                  -- Favorites marker icon
                  ic.favorite = false
                  local favorites = GetFavorites(ply:SteamID(), ply:GetRole())
                  if favorites then
                     if IsFavorite(favorites, item.id) then
                        ic.favorite = true
                        if showFavoriteVar:GetBool() then
                           local star = vgui.Create("DImage")
                           star:SetImage("icon16/star.png")
                           star.PerformLayout = function(s)
                              s:AlignTop(2)
                              s:AlignRight(2)
                              s:SetSize(12, 12)
                           end
                           star:SetTooltip("Favorite")
                           ic:AddLayer(star)
                           ic:EnableMousePassthrough(star)
                        end
                     end
                  end
                  
                  -- Slot marker icon
                  if ItemIsWeapon(item) && showSlotVar:GetBool() then
                     local slot = vgui.Create("SimpleIconLabelled")
                     slot:SetIcon("vgui/ttt/slotcap")
                     slot:SetIconColor(color_slot[ply:GetRole()] or COLOR_GREY)
                     slot:SetIconSize(16)
                     
                     slot:SetIconText(item.slot)
                     
                     slot:SetIconProperties(COLOR_WHITE,
                     "DefaultBold",
                     {opacity=220, offset=1},
                     {10, 8})
                     
                     ic:AddLayer(slot)
                     ic:EnableMousePassthrough(slot)
                  end
                  
                  ic:SetIconSize(itemSize)
                  ic:SetIcon(item.material)
               elseif item.model then
                  ic = vgui.Create("SpawnIcon", dlist)
                  ic:SetModel(item.model)
               else
                  ErrorNoHalt("Equipment item does not have model or material specified: " .. tostring(item) .. "\n")
               end
               
               ic.item = item
               
               local tip = SafeTranslate(item.name) .. " (" .. SafeTranslate(item.type) .. ")"
               ic:SetTooltip(tip)
               
               -- If we cannot order this item, darken it
               if ((not can_order) or
               -- already owned
               table.HasValue(owned_ids, item.id) or
               (tonumber(item.id) and ply:HasEquipmentItem(tonumber(item.id))) or
               -- already carrying a weapon for this slot
               (ItemIsWeapon(item) and (not CanCarryWeapon(item))) or
               -- already bought the item before
               (item.limited and ply:HasBought(tostring(item.id)))) then
                  
                  ic:SetIconColor(color_darkened)
               end
               
               if ic.favorite then
                  paneltablefav[k] = ic
               else
                  paneltable[k] = ic
               end
               
            end
            
            -- add favorites first
            for _, panel in pairs(paneltablefav) do
               dlist:AddPanel(panel)
            end
            -- non favorites second
            for _, panel in pairs(paneltable) do
               dlist:AddPanel(panel)
            end
            
            local bw, bh = 100, 25
            
            -- Whole right column
            local dih = h - bh - m*5
            -- local diw = w - dlistw - m*6 - 2
            local dinfobg = vgui.Create("DPanel", dequip)
            dinfobg:SetPaintBackground(false)
            dinfobg:SetSize(diw - m, dih)
            dinfobg:SetPos(dlistw + m, 0)
            
            -- item info pane
            local dinfo = vgui.Create("ColoredBox", dinfobg)
            dinfo:SetColor(Color(90, 90, 95))
            dinfo:SetPos(0,0)
            dinfo:StretchToParent(0, 0, m*2, 105)
            
            local dfields = {}
            for _, k in pairs({"name", "type", "desc"}) do
               dfields[k] = vgui.Create("DLabel", dinfo)
               dfields[k]:SetTooltip(GetTranslation("equip_spec_" .. k))
               dfields[k]:SetPos(m*3, m*2)
               dfields[k]:SetWidth(diw - m*6)
            end
            
            dfields.name:SetFont("TabLarge")
            
            dfields.type:SetFont("DermaDefault")
            dfields.type:MoveBelow(dfields.name)
            
            dfields.desc:SetFont("DermaDefaultBold")
            dfields.desc:SetContentAlignment(7)
            dfields.desc:MoveBelow(dfields.type, 1)
            
            local iw, ih = dinfo:GetSize()
            
            local dhelp = vgui.Create("DPanel", dinfobg)
            dhelp:SetPaintBackground(false)
            dhelp:SetSize(diw, 64)
            dhelp:MoveBelow(dinfo, m)
            
            local update_preqs = PreqLabels(dhelp, m*7, m*2)
            
            dhelp:SizeToContents()
            
            local dconfirm = vgui.Create("DButton", dinfobg)
            dconfirm:SetPos(0, dih - bh*2)
            dconfirm:SetSize(bw, bh)
            dconfirm:SetDisabled(true)
            dconfirm:SetText(GetTranslation("equip_confirm"))
            
            
            dsheet:AddSheet(GetTranslation("equip_tabtitle"), dequip, "icon16/bomb.png", false, false, "Traitor equipment menu")
            
            -- Item control
            if ply:HasEquipmentItem(EQUIP_RADAR) then
               local dradar = RADAR.CreateMenu(dsheet, dframe)
               dsheet:AddSheet(GetTranslation("radar_name"), dradar, "icon16/magnifier.png", false,false, "Radar control")
            end
            
            if ply:HasEquipmentItem(EQUIP_DISGUISE) then
               local ddisguise = DISGUISE.CreateMenu(dsheet)
               dsheet:AddSheet(GetTranslation("disg_name"), ddisguise, "icon16/user.png", false,false, "Disguise control")
            end
            
            -- Weapon/item control
            if IsValid(ply.radio) or ply:HasWeapon("weapon_ttt_radio") then
               local dradio = TRADIO.CreateMenu(dsheet)
               dsheet:AddSheet(GetTranslation("radio_name"), dradio, "icon16/transmit.png", false,false, "Radio control")
            end
            
            -- Credit transferring
            if credits > 0 then
               local dtransfer = CreateTransferMenu(dsheet)
               dsheet:AddSheet(GetTranslation("xfer_name"), dtransfer, "icon16/group_gear.png", false,false, "Transfer credits")
            end
            
            hook.Run("TTTEquipmentTabs", dsheet)
            
            
            -- couple panelselect with info
            dlist.OnActivePanelChanged = function(self, _, new)
               for k,v in pairs(new.item) do
                  if dfields[k] then
                     dfields[k]:SetText(SafeTranslate(v))
                     dfields[k]:SetAutoStretchVertical(true)
                     dfields[k]:SetWrap(true)
                  end
               end
               
               -- Trying to force everything to update to
               -- the right size is a giant pain, so just
               -- force a good size.
               dfields.desc:SetTall(70)
               
               can_order = update_preqs(new.item)
               
               dconfirm:SetDisabled(not can_order)
            end
            
            -- select first
            dlist:SelectPanel(to_select or dlist:GetItems()[1])
            
            -- prep confirm action
            dconfirm.DoClick = function()
               local pnl = dlist.SelectedPanel
               if not pnl or not pnl.item then return end
               local choice = pnl.item
               RunConsoleCommand("ttt_order_equipment", choice.id)
               dframe:Close()
            end
            
            -- update some basic info, may have changed in another tab
            -- specifically the number of credits in the preq list
            dsheet.OnTabChanged = function(s, old, new)
               if not IsValid(new) then return end
               
               if new:GetPanel() == dequip then
                  can_order = update_preqs(dlist.SelectedPanel.item)
                  dconfirm:SetDisabled(not can_order)
               end
            end
            
            local dcancel = vgui.Create("DButton", dframe)
            dcancel:SetPos(w - 13 - bw, h - bh - 16)
            dcancel:SetSize(bw, bh)
            dcancel:SetDisabled(false)
            dcancel:SetText(GetTranslation("close"))
            dcancel.DoClick = function()
               dframe:Close()
            end
            
            function file.AppendLine(filename, addme)
               data = file.Read(filename)
               if ( data ) then
                  file.Write(filename, data .. "\n" .. tostring(addme))
               else
                  file.Write(filename, tostring(addme))
               end
            end
            
            --add as favorite button
            dfav = vgui.Create("DButton", dinfobg)
            dfav:SetPos(0, dih - bh*2)
            dfav:MoveRightOf(dconfirm)
            dfav:SetSize(bh, bh)
            dfav:SetDisabled(false)
            dfav:SetText("")
            dfav:SetImage("icon16/star.png")
            dfav.DoClick = function()
               local ply = LocalPlayer()
               local role = ply:GetRole()
               local guid = ply:SteamID()
               local pnl = dlist.SelectedPanel
               if not pnl or not pnl.item then return end
               local choice = pnl.item
               local weapon = choice.id
               CreateFavTable()
               if pnl.favorite then
                  RemoveFavorite(guid, role, weapon)
               else
                  AddFavorite(guid, role, weapon)
               end
            end
            
            dframe:MakePopup()
            dframe:SetKeyboardInputEnabled(false)
            
            eqframe = dframe
         end
      end
   elseif table.HasValue( randomweaponshop, 0 ) then	
      local to_select = nil
      
      -- temp table for sorting
      local paneltablefav = {}
      local paneltable = {}
      
      for k, item in pairs(items) do
         local ic = nil
         
         -- Create icon panel
         if item.material then
            ic = vgui.Create("LayeredIcon", dlist)
            
            if item.custom && showCustomVar:GetBool() then
               -- Custom marker icon
               local marker = vgui.Create("DImage")
               marker:SetImage("vgui/ttt/custom_marker")
               marker.PerformLayout = function(s)
                  s:AlignBottom(2)
                  s:AlignRight(2)
                  s:SetSize(16, 16)
               end
               marker:SetTooltip(GetTranslation("equip_custom"))
               
               ic:AddLayer(marker)
               
               ic:EnableMousePassthrough(marker)
            end
            
            -- Favorites marker icon
            ic.favorite = false
            local favorites = GetFavorites(ply:SteamID(), ply:GetRole())
            if favorites then
               if IsFavorite(favorites, item.id) then
                  ic.favorite = true
                  if showFavoriteVar:GetBool() then
                     local star = vgui.Create("DImage")
                     star:SetImage("icon16/star.png")
                     star.PerformLayout = function(s)
                        s:AlignTop(2)
                        s:AlignRight(2)
                        s:SetSize(12, 12)
                     end
                     star:SetTooltip("Favorite")
                     ic:AddLayer(star)
                     ic:EnableMousePassthrough(star)
                  end
               end
            end
            
            -- Slot marker icon
            if ItemIsWeapon(item) && showSlotVar:GetBool() then
               local slot = vgui.Create("SimpleIconLabelled")
               slot:SetIcon("vgui/ttt/slotcap")
               slot:SetIconColor(color_slot[ply:GetRole()] or COLOR_GREY)
               slot:SetIconSize(16)
               
               slot:SetIconText(item.slot)
               
               slot:SetIconProperties(COLOR_WHITE,
               "DefaultBold",
               {opacity=220, offset=1},
               {10, 8})
               
               ic:AddLayer(slot)
               ic:EnableMousePassthrough(slot)
            end
            
            ic:SetIconSize(itemSize)
            ic:SetIcon(item.material)
         elseif item.model then
            ic = vgui.Create("SpawnIcon", dlist)
            ic:SetModel(item.model)
         else
            ErrorNoHalt("Equipment item does not have model or material specified: " .. tostring(item) .. "\n")
         end
         
         ic.item = item
         
         local tip = SafeTranslate(item.name) .. " (" .. SafeTranslate(item.type) .. ")"
         ic:SetTooltip(tip)
         
         -- If we cannot order this item, darken it
         if ((not can_order) or
         -- already owned
         table.HasValue(owned_ids, item.id) or
         (tonumber(item.id) and ply:HasEquipmentItem(tonumber(item.id))) or
         -- already carrying a weapon for this slot
         (ItemIsWeapon(item) and (not CanCarryWeapon(item))) or
         -- already bought the item before
         (item.limited and ply:HasBought(tostring(item.id)))) then
            
            ic:SetIconColor(color_darkened)
         end
         
         if ic.favorite then
            paneltablefav[k] = ic
         else
            paneltable[k] = ic
         end
         
      end
      
      -- add favorites first
      for _, panel in pairs(paneltablefav) do
         dlist:AddPanel(panel)
      end
      -- non favorites second
      for _, panel in pairs(paneltable) do
         dlist:AddPanel(panel)
      end
      
      local bw, bh = 100, 25
      
      -- Whole right column
      local dih = h - bh - m*5
      -- local diw = w - dlistw - m*6 - 2
      local dinfobg = vgui.Create("DPanel", dequip)
      dinfobg:SetPaintBackground(false)
      dinfobg:SetSize(diw - m, dih)
      dinfobg:SetPos(dlistw + m, 0)
      
      -- item info pane
      local dinfo = vgui.Create("ColoredBox", dinfobg)
      dinfo:SetColor(Color(90, 90, 95))
      dinfo:SetPos(0,0)
      dinfo:StretchToParent(0, 0, m*2, 105)
      
      local dfields = {}
      for _, k in pairs({"name", "type", "desc"}) do
         dfields[k] = vgui.Create("DLabel", dinfo)
         dfields[k]:SetTooltip(GetTranslation("equip_spec_" .. k))
         dfields[k]:SetPos(m*3, m*2)
         dfields[k]:SetWidth(diw - m*6)
      end
      
      dfields.name:SetFont("TabLarge")
      
      dfields.type:SetFont("DermaDefault")
      dfields.type:MoveBelow(dfields.name)
      
      dfields.desc:SetFont("DermaDefaultBold")
      dfields.desc:SetContentAlignment(7)
      dfields.desc:MoveBelow(dfields.type, 1)
      
      local iw, ih = dinfo:GetSize()
      
      local dhelp = vgui.Create("DPanel", dinfobg)
      dhelp:SetPaintBackground(false)
      dhelp:SetSize(diw, 64)
      dhelp:MoveBelow(dinfo, m)
      
      local update_preqs = PreqLabels(dhelp, m*7, m*2)
      
      dhelp:SizeToContents()
      
      local dconfirm = vgui.Create("DButton", dinfobg)
      dconfirm:SetPos(0, dih - bh*2)
      dconfirm:SetSize(bw, bh)
      dconfirm:SetDisabled(true)
      dconfirm:SetText(GetTranslation("equip_confirm"))
      
      
      dsheet:AddSheet(GetTranslation("equip_tabtitle"), dequip, "icon16/bomb.png", false, false, "Traitor equipment menu")
      
      -- Item control
      if ply:HasEquipmentItem(EQUIP_RADAR) then
         local dradar = RADAR.CreateMenu(dsheet, dframe)
         dsheet:AddSheet(GetTranslation("radar_name"), dradar, "icon16/magnifier.png", false,false, "Radar control")
      end
      
      if ply:HasEquipmentItem(EQUIP_DISGUISE) then
         local ddisguise = DISGUISE.CreateMenu(dsheet)
         dsheet:AddSheet(GetTranslation("disg_name"), ddisguise, "icon16/user.png", false,false, "Disguise control")
      end
      
      -- Weapon/item control
      if IsValid(ply.radio) or ply:HasWeapon("weapon_ttt_radio") then
         local dradio = TRADIO.CreateMenu(dsheet)
         dsheet:AddSheet(GetTranslation("radio_name"), dradio, "icon16/transmit.png", false,false, "Radio control")
      end
      
      -- Credit transferring
      if credits > 0 then
         local dtransfer = CreateTransferMenu(dsheet)
         dsheet:AddSheet(GetTranslation("xfer_name"), dtransfer, "icon16/group_gear.png", false,false, "Transfer credits")
      end
      
      hook.Run("TTTEquipmentTabs", dsheet)
      
      
      -- couple panelselect with info
      dlist.OnActivePanelChanged = function(self, _, new)
         for k,v in pairs(new.item) do
            if dfields[k] then
               dfields[k]:SetText(SafeTranslate(v))
               dfields[k]:SetAutoStretchVertical(true)
               dfields[k]:SetWrap(true)
            end
         end
         
         -- Trying to force everything to update to
         -- the right size is a giant pain, so just
         -- force a good size.
         dfields.desc:SetTall(70)
         
         can_order = update_preqs(new.item)
         
         dconfirm:SetDisabled(not can_order)
      end
      
      -- select first
      dlist:SelectPanel(to_select or dlist:GetItems()[1])
      
      -- prep confirm action
      dconfirm.DoClick = function()
         local pnl = dlist.SelectedPanel
         if not pnl or not pnl.item then return end
         local choice = pnl.item
         RunConsoleCommand("ttt_order_equipment", choice.id)
         dframe:Close()
      end
      
      -- update some basic info, may have changed in another tab
      -- specifically the number of credits in the preq list
      dsheet.OnTabChanged = function(s, old, new)
         if not IsValid(new) then return end
         
         if new:GetPanel() == dequip then
            can_order = update_preqs(dlist.SelectedPanel.item)
            dconfirm:SetDisabled(not can_order)
         end
      end
      
      local dcancel = vgui.Create("DButton", dframe)
      dcancel:SetPos(w - 13 - bw, h - bh - 16)
      dcancel:SetSize(bw, bh)
      dcancel:SetDisabled(false)
      dcancel:SetText(GetTranslation("close"))
      dcancel.DoClick = function()
         dframe:Close()
      end
      
      function file.AppendLine(filename, addme)
         data = file.Read(filename)
         if ( data ) then
            file.Write(filename, data .. "\n" .. tostring(addme))
         else
            file.Write(filename, tostring(addme))
         end
      end
      
      --add as favorite button
      dfav = vgui.Create("DButton", dinfobg)
      dfav:SetPos(0, dih - bh*2)
      dfav:MoveRightOf(dconfirm)
      dfav:SetSize(bh, bh)
      dfav:SetDisabled(false)
      dfav:SetText("")
      dfav:SetImage("icon16/star.png")
      dfav.DoClick = function()
         local ply = LocalPlayer()
         local role = ply:GetRole()
         local guid = ply:SteamID()
         local pnl = dlist.SelectedPanel
         if not pnl or not pnl.item then return end
         local choice = pnl.item
         local weapon = choice.id
         CreateFavTable()
         if pnl.favorite then
            RemoveFavorite(guid, role, weapon)
         else
            AddFavorite(guid, role, weapon)
         end
      end
      
      dframe:MakePopup()
      dframe:SetKeyboardInputEnabled(false)
      
      eqframe = dframe
   else
      local to_select = nil
      
      -- temp table for sorting
      local paneltablefav = {}
      local paneltable = {}
      
      for k, item in pairs(items) do
         local ic = nil
         
         -- Create icon panel
         if item.material then
            ic = vgui.Create("LayeredIcon", dlist)
            
            if item.custom && showCustomVar:GetBool() then
               -- Custom marker icon
               local marker = vgui.Create("DImage")
               marker:SetImage("vgui/ttt/custom_marker")
               marker.PerformLayout = function(s)
                  s:AlignBottom(2)
                  s:AlignRight(2)
                  s:SetSize(16, 16)
               end
               marker:SetTooltip(GetTranslation("equip_custom"))
               
               ic:AddLayer(marker)
               
               ic:EnableMousePassthrough(marker)
            end
            
            -- Favorites marker icon
            ic.favorite = false
            local favorites = GetFavorites(ply:SteamID(), ply:GetRole())
            if favorites then
               if IsFavorite(favorites, item.id) then
                  ic.favorite = true
                  if showFavoriteVar:GetBool() then
                     local star = vgui.Create("DImage")
                     star:SetImage("icon16/star.png")
                     star.PerformLayout = function(s)
                        s:AlignTop(2)
                        s:AlignRight(2)
                        s:SetSize(12, 12)
                     end
                     star:SetTooltip("Favorite")
                     ic:AddLayer(star)
                     ic:EnableMousePassthrough(star)
                  end
               end
            end
            
            -- Slot marker icon
            if ItemIsWeapon(item) && showSlotVar:GetBool() then
               local slot = vgui.Create("SimpleIconLabelled")
               slot:SetIcon("vgui/ttt/slotcap")
               slot:SetIconColor(color_slot[ply:GetRole()] or COLOR_GREY)
               slot:SetIconSize(16)
               
               slot:SetIconText(item.slot)
               
               slot:SetIconProperties(COLOR_WHITE,
               "DefaultBold",
               {opacity=220, offset=1},
               {10, 8})
               
               ic:AddLayer(slot)
               ic:EnableMousePassthrough(slot)
            end
            
            ic:SetIconSize(itemSize)
            ic:SetIcon(item.material)
         elseif item.model then
            ic = vgui.Create("SpawnIcon", dlist)
            ic:SetModel(item.model)
         else
            ErrorNoHalt("Equipment item does not have model or material specified: " .. tostring(item) .. "\n")
         end
         
         ic.item = item
         
         local tip = SafeTranslate(item.name) .. " (" .. SafeTranslate(item.type) .. ")"
         ic:SetTooltip(tip)
         
         -- If we cannot order this item, darken it
         if ((not can_order) or
         -- already owned
         table.HasValue(owned_ids, item.id) or
         (tonumber(item.id) and ply:HasEquipmentItem(tonumber(item.id))) or
         -- already carrying a weapon for this slot
         (ItemIsWeapon(item) and (not CanCarryWeapon(item))) or
         -- already bought the item before
         (item.limited and ply:HasBought(tostring(item.id)))) then
            
            ic:SetIconColor(color_darkened)
         end
         
         if ic.favorite then
            paneltablefav[k] = ic
         else
            paneltable[k] = ic
         end
         
      end
      
      -- add favorites first
      for _, panel in pairs(paneltablefav) do
         dlist:AddPanel(panel)
      end
      -- non favorites second
      for _, panel in pairs(paneltable) do
         dlist:AddPanel(panel)
      end
      
      local bw, bh = 100, 25
      
      -- Whole right column
      local dih = h - bh - m*5
      -- local diw = w - dlistw - m*6 - 2
      local dinfobg = vgui.Create("DPanel", dequip)
      dinfobg:SetPaintBackground(false)
      dinfobg:SetSize(diw - m, dih)
      dinfobg:SetPos(dlistw + m, 0)
      
      -- item info pane
      local dinfo = vgui.Create("ColoredBox", dinfobg)
      dinfo:SetColor(Color(90, 90, 95))
      dinfo:SetPos(0,0)
      dinfo:StretchToParent(0, 0, m*2, 105)
      
      local dfields = {}
      for _, k in pairs({"name", "type", "desc"}) do
         dfields[k] = vgui.Create("DLabel", dinfo)
         dfields[k]:SetTooltip(GetTranslation("equip_spec_" .. k))
         dfields[k]:SetPos(m*3, m*2)
         dfields[k]:SetWidth(diw - m*6)
      end
      
      dfields.name:SetFont("TabLarge")
      
      dfields.type:SetFont("DermaDefault")
      dfields.type:MoveBelow(dfields.name)
      
      dfields.desc:SetFont("DermaDefaultBold")
      dfields.desc:SetContentAlignment(7)
      dfields.desc:MoveBelow(dfields.type, 1)
      
      local iw, ih = dinfo:GetSize()
      
      local dhelp = vgui.Create("DPanel", dinfobg)
      dhelp:SetPaintBackground(false)
      dhelp:SetSize(diw, 64)
      dhelp:MoveBelow(dinfo, m)
      
      local update_preqs = PreqLabels(dhelp, m*7, m*2)
      
      dhelp:SizeToContents()
      
      local dconfirm = vgui.Create("DButton", dinfobg)
      dconfirm:SetPos(0, dih - bh*2)
      dconfirm:SetSize(bw, bh)
      dconfirm:SetDisabled(true)
      dconfirm:SetText(GetTranslation("equip_confirm"))
      
      
      dsheet:AddSheet(GetTranslation("equip_tabtitle"), dequip, "icon16/bomb.png", false, false, "Traitor equipment menu")
      
      -- Item control
      if ply:HasEquipmentItem(EQUIP_RADAR) then
         local dradar = RADAR.CreateMenu(dsheet, dframe)
         dsheet:AddSheet(GetTranslation("radar_name"), dradar, "icon16/magnifier.png", false,false, "Radar control")
      end
      
      if ply:HasEquipmentItem(EQUIP_DISGUISE) then
         local ddisguise = DISGUISE.CreateMenu(dsheet)
         dsheet:AddSheet(GetTranslation("disg_name"), ddisguise, "icon16/user.png", false,false, "Disguise control")
      end
      
      -- Weapon/item control
      if IsValid(ply.radio) or ply:HasWeapon("weapon_ttt_radio") then
         local dradio = TRADIO.CreateMenu(dsheet)
         dsheet:AddSheet(GetTranslation("radio_name"), dradio, "icon16/transmit.png", false,false, "Radio control")
      end
      
      -- Credit transferring
      if credits > 0 then
         local dtransfer = CreateTransferMenu(dsheet)
         dsheet:AddSheet(GetTranslation("xfer_name"), dtransfer, "icon16/group_gear.png", false,false, "Transfer credits")
      end
      
      hook.Run("TTTEquipmentTabs", dsheet)
      
      
      -- couple panelselect with info
      dlist.OnActivePanelChanged = function(self, _, new)
         for k,v in pairs(new.item) do
            if dfields[k] then
               dfields[k]:SetText(SafeTranslate(v))
               dfields[k]:SetAutoStretchVertical(true)
               dfields[k]:SetWrap(true)
            end
         end
         
         -- Trying to force everything to update to
         -- the right size is a giant pain, so just
         -- force a good size.
         dfields.desc:SetTall(70)
         
         can_order = update_preqs(new.item)
         
         dconfirm:SetDisabled(not can_order)
      end
      
      -- select first
      dlist:SelectPanel(to_select or dlist:GetItems()[1])
      
      -- prep confirm action
      dconfirm.DoClick = function()
         local pnl = dlist.SelectedPanel
         if not pnl or not pnl.item then return end
         local choice = pnl.item
         RunConsoleCommand("ttt_order_equipment", choice.id)
         dframe:Close()
      end
      
      -- update some basic info, may have changed in another tab
      -- specifically the number of credits in the preq list
      dsheet.OnTabChanged = function(s, old, new)
         if not IsValid(new) then return end
         
         if new:GetPanel() == dequip then
            can_order = update_preqs(dlist.SelectedPanel.item)
            dconfirm:SetDisabled(not can_order)
         end
      end
      
      local dcancel = vgui.Create("DButton", dframe)
      dcancel:SetPos(w - 13 - bw, h - bh - 16)
      dcancel:SetSize(bw, bh)
      dcancel:SetDisabled(false)
      dcancel:SetText(GetTranslation("close"))
      dcancel.DoClick = function()
         dframe:Close()
      end
      
      function file.AppendLine(filename, addme)
         data = file.Read(filename)
         if ( data ) then
            file.Write(filename, data .. "\n" .. tostring(addme))
         else
            file.Write(filename, tostring(addme))
         end
      end
      
      --add as favorite button
      dfav = vgui.Create("DButton", dinfobg)
      dfav:SetPos(0, dih - bh*2)
      dfav:MoveRightOf(dconfirm)
      dfav:SetSize(bh, bh)
      dfav:SetDisabled(false)
      dfav:SetText("")
      dfav:SetImage("icon16/star.png")
      dfav.DoClick = function()
         local ply = LocalPlayer()
         local role = ply:GetRole()
         local guid = ply:SteamID()
         local pnl = dlist.SelectedPanel
         if not pnl or not pnl.item then return end
         local choice = pnl.item
         local weapon = choice.id
         CreateFavTable()
         if pnl.favorite then
            RemoveFavorite(guid, role, weapon)
         else
            AddFavorite(guid, role, weapon)
         end
      end
      
      dframe:MakePopup()
      dframe:SetKeyboardInputEnabled(false)
      
      eqframe = dframe
   end
end
concommand.Add("ttt_cl_traitorpopup", TraitorMenuPopup)

local function ForceCloseTraitorMenu(ply, cmd, args)
   if IsValid(eqframe) then
      eqframe:Close()
   end
end
concommand.Add("ttt_cl_traitorpopup_close", ForceCloseTraitorMenu)

function GM:OnContextMenuOpen()
   local r = GetRoundState()
   if r == ROUND_ACTIVE and not (LocalPlayer():GetTraitor() or LocalPlayer():GetDetective() or LocalPlayer():GetSurvivalist() or LocalPlayer():GetSerialkiller()) then
      return
   elseif r == ROUND_POST or r == ROUND_PREP then
      CLSCORE:Reopen()
      return
   end
   
   RunConsoleCommand("ttt_cl_traitorpopup")
end

local function ReceiveEquipment()
   local ply = LocalPlayer()
   if not IsValid(ply) then return end
   
   ply.equipment_items = net.ReadUInt(16)
end
net.Receive("TTT_Equipment", ReceiveEquipment)

local function ReceiveEquipment2()
   local DermaPanel = vgui.Create( "DFrame" )
   DermaPanel:SetPos( 50,50 )
   DermaPanel:SetSize( 500, 700 )
   DermaPanel:SetTitle( "Testing Derma Stuff" )
   DermaPanel:SetVisible( true )
   DermaPanel:SetDraggable( true )
   DermaPanel:ShowCloseButton( true )
   DermaPanel:MakePopup()
   
   local DermaListView = vgui.Create("DListView")
   DermaListView:SetParent(DermaPanel)
   DermaListView:SetPos(25, 50)
   DermaListView:SetSize(450, 500)
   DermaListView:SetMultiSelect(false)
   DermaListView:AddColumn("Name") -- Add column
   DermaListView:AddColumn("In Game Name")
   
   local menu = vgui.Create( "DComboBox")
   menu:SetParent(DermaPanel)
   menu:SetPos(25, 560)
   menu:SetText( "Survivalist" )
   menu:AddChoice("Traitor")
   menu:AddChoice("Detective")
   menu:AddChoice("Survivalist")
   menu:AddChoice("SerialKiller")
   
   local TextEntry = vgui.Create( "DTextEntry", frame ) -- create the form as a child of frame
   TextEntry:SetParent(DermaPanel)
   TextEntry:SetSize(100, 25)
   TextEntry:SetPos( 390, 560 )
   TextEntry:SetText( "Sample String" )
   TextEntry.OnEnter = function( self )
      //	chat.AddText( self:GetValue() )	-- print the form's text as server text
   end
   
   local button = vgui.Create( "Button" )
   button:SetParent(DermaPanel)
   button:SetSize( 150, 30 )
   button:SetPos( 175, 600 )
   button:SetVisible( true )
   button:SetText( "Click Me" )
   function button:DoClick()
      local Players = {}
      local io = 0
      for k,v in pairs( weapons.GetList() ) do 
         if v.ClassName == TextEntry:GetValue() then
            io = io + 1
            Players[v.PrintName] = { name = TextEntry:GetValue(), traitor = menu:GetValue() }
            if menu:GetValue() == "Survivalist" then
               net.Start( "Survivalistshop" )
               net.WriteString("Survivalist")
               net.WriteString(TextEntry:GetValue())
               net.WriteTable( Players )
               print(TextEntry:GetValue())
               net.SendToServer()
            elseif menu:GetValue() == "Detective" then
               net.Start( "Detectiveshop" )
               net.WriteString("Survivalist")
               net.WriteString(TextEntry:GetValue())
               net.WriteTable( Players )
               print(TextEntry:GetValue())
               net.SendToServer()
            elseif menu:GetValue() == "Traitor" then
               net.Start( "Traitorshop" )
               net.WriteString("Survivalist")
               net.WriteString(TextEntry:GetValue())
               net.WriteTable( Players )
               print(TextEntry:GetValue())
               net.SendToServer()
            elseif menu:GetValue() == "SerialKiller" then
               net.Start( "SerialKillershop" )
               net.WriteString("Survivalist")
               net.WriteString(TextEntry:GetValue())
               net.WriteTable( Players )
               print(TextEntry:GetValue())
               net.SendToServer()
            end
         end
      end
   end
   
   for k,v in pairs(weapons.GetList()) do
      if v.Base == "weapon_tttbase" then
         DermaListView:AddLine(v.ClassName,v.PrintName) -- Add lines
      end
   end
end
net.Receive("weaponshopper", ReceiveEquipment2)


local function ReceiveCredits()
   local ply = LocalPlayer()
   if not IsValid(ply) then return end
   
   ply.equipment_credits = net.ReadUInt(8)
end
net.Receive("TTT_Credits", ReceiveCredits)

local r = 0
local function ReceiveBought()
   local ply = LocalPlayer()
   if not IsValid(ply) then return end
   
   ply.bought = {}
   local num = net.ReadUInt(8)
   for i=1,num do
      local s = net.ReadString()
      if s != "" then
         table.insert(ply.bought, s)
      end
   end
   
   -- This usermessage sometimes fails to contain the last weapon that was
   -- bought, even though resending then works perfectly. Possibly a bug in
   -- bf_read. Anyway, this hack is a workaround: we just request a new umsg.
   if num != #ply.bought and r < 10 then -- r is an infinite loop guard
      RunConsoleCommand("ttt_resend_bought")
      r = r + 1
   else
      r = 0
   end
end
net.Receive("TTT_Bought", ReceiveBought)

-- Player received the item he has just bought, so run clientside init
local function ReceiveBoughtItem()
   local is_item = net.ReadBit() == 1
   local id = is_item and net.ReadUInt(16) or net.ReadString()
   
   -- I can imagine custom equipment wanting this, so making a hook
   hook.Run("TTTBoughtItem", is_item, id)
end
net.Receive("TTT_BoughtItem", ReceiveBoughtItem)


local confetti = Material( "confetti.png" )

local Equipmentnew = nil
net.Receive( "NewConfetti", function()
   local ent = net.ReadEntity()
   
   ent:EmitSound("BirthdayParty.mp3") --Play the sound
   
   local pos = ent:GetPos() + Vector( 0, 0, ent:OBBMaxs().z )
   
   if ent.GetShootPos then
      pos = ent:GetShootPos()
   end
   
   local velMax = 200
   local gravMax = 50
   
   local gravity = Vector( math.random( -gravMax, gravMax ), math.random( -gravMax, gravMax ), math.random( -gravMax, 0 ) )
   
   --Handles particles
   local emitter = ParticleEmitter( pos, true )
   for I = 1, 150 do
      local p = emitter:Add( confetti, pos )
      p:SetStartSize( math.random( 6, 10 ) )
      p:SetEndSize( 0 )
      p:SetAngles( Angle( math.random( 0, 360 ), math.random( 0, 360 ), math.random( 0, 360 ) ) )
      p:SetAngleVelocity( Angle( math.random( 5, 50 ), math.random( 5, 50 ), math.random( 5, 50 ) ) )
      p:SetVelocity( Vector( math.random( -velMax, velMax ), math.random( -velMax, velMax ), math.random( -velMax, velMax ) ) )
      p:SetColor( 255, 255, 255 )
      p:SetDieTime( math.random( 4, 7 ) )
      p:SetGravity( gravity )
      p:SetAirResistance( 125 )
   end
end)


local serialkillers = Material( "smokey.png" )

local Equipmentnew = nil
net.Receive( "Newserialkillers", function()
   local ent = net.ReadEntity()
   
   local pos = ent:GetPos() + Vector( 0, 0, 50 )
   
   
   local velMax = 200
   local velFax = 50
   local gravMax = 5
   
   local gravity = Vector( math.random( -gravMax, gravMax ), math.random( -gravMax, gravMax ), math.random( -gravMax, 0 ) )
   
   --Handles particles
   local emitter = ParticleEmitter( pos, true )
   for I = 1, 150 do
      local p = emitter:Add( serialkillers, pos )
      p:SetStartSize( math.random( 6, 10 ) )
      p:SetEndSize( 0 )
      p:SetAngles( Angle( math.random( 0, 360 ), math.random( 0, 360 ), math.random( 0, 360 ) ) )
      p:SetAngleVelocity( Angle( math.random( 5, 50 ), math.random( 5, 50 ), math.random( 5, 50 ) ) )
      p:SetVelocity( Vector( math.random( -velFax, velFax ), math.random( -velFax, velFax ), math.random( -velFax, velFax ) ) )
      p:SetColor( 0, 0, 0 )
      p:SetDieTime( 0.5 )
      p:SetGravity( gravity )
      p:SetAirResistance( 125 )
   end
end)


function GetEquipmentForRoleAll(role)
   local Players = {}
   local io = 0
   local realweapons = {}
   
   -- need to build equipment cache?
   if not Equipmentnew then
      -- start with all the non-weapon goodies
      local tbl = table.Copy(EquipmentItems)
      
      -- find buyable weapons to load info from
      for k, v in pairs(weapons.GetList()) do
         if v and v.CanBuy then
            local data = v.EquipMenuData or {}
            local base = {
               id       = WEPS.GetClass(v),
               name     = v.PrintName or "Unnamed",
               limited  = v.LimitedStock,
               kind     = v.Kind or WEAPON_NONE,
               slot     = (v.Slot or 0) + 1,
               material = v.Icon or "vgui/ttt/icon_id",
               -- the below should be specified in EquipMenuData, in which case
               -- these values are overwritten
               type     = "Type not specified",
               model    = "models/weapons/w_bugbait.mdl",
               desc     = "No description specified."
            };
            
            -- Force material to nil so that model key is used when we are
            -- explicitly told to do so (ie. material is false rather than nil).
            if data.modelicon then
               base.material = nil
            end
            
            -- add this buyable weapon to all relevant equipment tables
            table.insert(tbl[1], base)
         end
      end
      
      -- mark custom items
      for r, is in pairs(tbl) do
         for _, i in pairs(is) do
            if i and i.id then
               i.custom = not table.HasValue(DefaultEquipment[r], i.id)
            end
         end
      end
      
      Equipmentnew = tbl
   end
   
   return Equipmentnew and Equipmentnew[1] or {}
end

net.Receive( "newshop", function()
   local DermaPanel = vgui.Create( "DFrame" )
   DermaPanel:SetPos( 50,50 )
   DermaPanel:SetSize( 500, 700 )
   DermaPanel:SetTitle( "Weapon Shop Adder" )
   DermaPanel:SetVisible( true )
   DermaPanel:SetDraggable( true )
   DermaPanel:ShowCloseButton( true )
   DermaPanel:MakePopup()
   function DermaPanel:Paint( w, h )
      draw.RoundedBox( 0, 0, 0, w, h, Color( 100, 100, 100 ) )
   end
   
   local DScrollPanel = vgui.Create( "DScrollPanel", DermaPanel )
   DScrollPanel:SetSize( 400, 250 )
   DScrollPanel:Center()
   
   local sbar = DScrollPanel:GetVBar()
   function sbar:Paint( w, h )
      draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 100 ) )
   end
   function sbar.btnUp:Paint( w, h )
      draw.RoundedBox( 0, 0, 0, w, h, Color( 200, 100, 0 ) )
   end
   function sbar.btnDown:Paint( w, h )
      draw.RoundedBox( 0, 0, 0, w, h, Color( 200, 100, 0 ) )
   end
   function sbar.btnGrip:Paint( w, h )
      draw.RoundedBox( 0, 0, 0, w, h, Color( 100, 200, 0 ) )
   end
   
   local w, h = 570, 412
   
   --- Construct icon listing
   local dlist = vgui.Create("EquipSelect", DermaPanel)
   dlist:SetPos(0,20)
   dlist:SetSize(415, h - 75)
   dlist:EnableVerticalScrollbar(true)
   dlist:EnableHorizontal(true)
   dlist:SetPadding(4)
   
   local ply = LocalPlayer()
   
   local items = GetEquipmentForRoleAll(ply:GetRole())
   
   local to_select = nil
   for k, item in pairs(items) do
      local ic = nil
      
      -- Create icon panel
      if item.material then
         if item.custom then
            -- Custom marker icon
            ic = vgui.Create("LayeredIcon", dlist)
            
            local marker = vgui.Create("DImage")
            marker:SetImage("vgui/ttt/custom_marker")
            marker.PerformLayout = function(s)
               s:AlignBottom(2)
               s:AlignRight(2)
               s:SetSize(16, 16)
            end
            marker:SetTooltip(GetTranslation("equip_custom"))
            
            ic:AddLayer(marker)
            
            ic:EnableMousePassthrough(marker)
         elseif not ItemIsWeapon(item) then
            ic = vgui.Create("SimpleIcon", dlist)
         else
            ic = vgui.Create("LayeredIcon", dlist)
         end
         
         -- Slot marker icon
         if ItemIsWeapon(item) then
            local slot = vgui.Create("SimpleIconLabelled")
            slot:SetIcon("vgui/ttt/slotcap")
            slot:SetIconColor(color_slot[1] or COLOR_GREY)
            slot:SetIconSize(16)
            
            slot:SetIconText(item.slot)
            
            slot:SetIconProperties(COLOR_WHITE,
            "DefaultBold",
            {opacity=220, offset=1},
            {10, 8})
            
            ic:AddLayer(slot)
            ic:EnableMousePassthrough(slot)
         end
         
         ic:SetIconSize(64)
         ic:SetIcon(item.material)
      elseif item.model then
         ic = vgui.Create("SpawnIcon", dlist)
         ic:SetModel(item.model)
      else
         ErrorNoHalt("Equipment item does not have model or material specified: " .. tostring(item) .. "\n")
      end
      
      ic.item = item
      
      local tip = SafeTranslate(item.name) .. " (" .. SafeTranslate(item.type) .. ")"
      ic:SetTooltip(tip)
      
      -- If we cannot order this item, darken it
      if ((not can_order) or
      -- already owned
      table.HasValue(owned_ids, item.id) or
      (tonumber(item.id) and ply:HasEquipmentItem(tonumber(item.id))) or
      -- already carrying a weapon for this slot
      (ItemIsWeapon(item) and (not CanCarryWeapon(item))) or
      -- already bought the item before
      (item.limited and ply:HasBought(tostring(item.id)))) then
         
         ic:SetIconColor(color_darkened)
      end
      
      dlist:AddPanel(ic)
   end
   dlist:SelectPanel(to_select or dlist:GetItems()[1])
   
   local bw, bh = 425, 25
   
   -- margin
   local m = 5
   
   local dih = h - bh - m*5
   
   local menu = vgui.Create( "DComboBox")
   menu:SetParent(DermaPanel)
   menu:SetPos(25, 560)
   menu:SetText( "Survivalist" )
   menu:AddChoice("Traitor")
   menu:AddChoice("Detective")
   menu:AddChoice("Survivalist")
   menu:AddChoice("SerialKiller")
   
   dlist:SelectPanel(to_select or dlist:GetItems()[1])
   
   dfav = vgui.Create("DButton", DermaPanel)
   dfav:SetSize( 150, 30 )
   dfav:SetPos( 175, 600 )
   dfav:SetVisible( true )
   dfav:SetText( "Click Me" )
   dfav.DoClick = function()
      local ply = LocalPlayer()
      local role = ply:GetRole()
      local guid = ply:SteamID()
      local pnl = dlist.SelectedPanel
      if not pnl or not pnl.item then return end
      local choice = pnl.item
      local weapon = choice.id
      
      local Players = {}
      local io = 0
      for k,v in pairs( weapons.GetList() ) do 
         if v.ClassName == weapon then
            io = io + 1
            Players[v.PrintName] = { name = weapon, traitor = menu:GetValue() }
            if menu:GetValue() == "Survivalist" then
               net.Start( "Survivalistshop" )
               net.WriteString("Survivalist")
               net.WriteString(weapon)
               net.WriteTable( Players )
               print(weapon)
               net.SendToServer()
            elseif menu:GetValue() == "Detective" then
               net.Start( "Detectiveshop" )
               net.WriteString("Detective")
               net.WriteString(weapon)
               net.WriteTable( Players )
               print(weapon)
               net.SendToServer()
            elseif menu:GetValue() == "Traitor" then
               net.Start( "Traitorshop" )
               net.WriteString("Traitor")
               net.WriteString(weapon)
               net.WriteTable( Players )
               print(weapon)
               net.SendToServer()
            elseif menu:GetValue() == "SerialKiller" then
               net.Start( "SerialKillershop" )
               net.WriteString("SerialKiller")
               net.WriteString(weapon)
               net.WriteTable( Players )
               print(weapon)
               net.SendToServer()
            end
         end
      end
      
   end
   
   
end)