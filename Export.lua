--- DO NOT EDIT.
--- This file is for reference purposes only
--- All user modifications should go to $HOME\Saved Games\DCS\Scripts\Export.lua

-- Data export script for Lock On version 1.2.
-- Copyright (C) 2006, Eagle Dynamics.
-- See http://www.lua.org for Lua script system info 
-- We recommend to use the LuaSocket addon (http://www.tecgraf.puc-rio.br/luasocket) 
-- to use standard network protocols in Lua scripts.
-- LuaSocket 2.0 files (*.dll and *.lua) are supplied in the Scripts/LuaSocket folder
-- and in the installation folder of the Lock On version 1.2. 

-- Please, set EnableExportScript = true in the Config/Export/Config.lua file
-- to activate this script!

-- Expand the functionality of following functions for your external application needs.
-- Look into ./Temp/Error.log for this script errors, please.

-- Uncomment if using Vector class from the Config/Export/Vector.lua file 
--[[	
LUA_PATH = "?;?.lua;./Config/Export/?.lua"
require 'Vector'
-- See the Config/Export/Vector.lua file for Vector class details, please.
--]]

local default_output_file = nil

function LuaExportStart()
-- Works once just before mission start.


end

function LuaExportBeforeNextFrame()
-- Works just before every simulation frame.



end

function LuaExportAfterNextFrame()
-- Works just after every simulation frame.



end

function LuaExportStop()
-- Works once just after mission stop.
-- Close files and/or connections here.
-- 1) File
   if default_output_file then
	  default_output_file:close()
	  default_output_file = nil
   end
-- 2) Socket
--	socket.try(c:send("quit")) -- to close the listener socket
--	c:close()
end

-- Fonction de selection de script export en fonction de l'appareil
gCurrentAircraft = "Fonction de selection de script export"

function LuaExportActivityNextEvent(t)
	t = t + 1
	local lDevice = GetDevice(0)	
	if type(lDevice) == "table" then
		local myInfo = LoGetSelfData()
		if myInfo.Name ~= gCurrentAircraft then
			gCurrentAircraft = myInfo.Name
			if gCurrentAircraft == "A-10C" then
			elseif gCurrentAircraft == "Ka-50" then
				dofile(lfs.writedir()..'Scripts\\KTZ_SIOC_KA50_v5008.lua'); 
			elseif gCurrentAircraft == "Mi-8MT" then
				dofile(lfs.writedir()..'Scripts\\KTZ_SIOC_Mi8_v5008.lua');
			elseif gCurrentAircraft == "UH-1H" then
			dofile(lfs.writedir()..'Scripts\\KTZ_SIOC_UH1_v5009.lua');
			else -- Unknown aircraft; assume Flaming Cliffs
				dofile(lfs.writedir()..'Scripts\\KTZ_SIOC_v3021.lua'); 
			end
		end
	end
	return t
end

--function LuaExportActivityNextEvent(t)
--	local tNext = t
	
	
-- Put your event code here and increase tNext for the next event
-- so this function will be called automatically at your custom
-- model times. 
-- If tNext == t then the activity will be terminated.



-- dofile ( lfs.writedir().."Scripts\\KTZ_Perf_Log-302.lua" )
-- dofile ( lfs.writedir().."Scripts\\KTZ_fps_check-300.lua" )
-- dofile ( lfs.writedir().."Scripts\\KTZ_fps_record-300.lua" )
-- local Tacviewlfs=require('lfs');dofile(Tacviewlfs.writedir()..'Scripts/TacviewExportDCS.lua')


-- dofile(lfs.writedir()..'Scripts\\KTZ_SIOC_v3021.lua'); 
--dofile(lfs.writedir()..'Scripts\\KTZ_SIOC_KA50_v005.lua'); 
--dofile(lfs.writedir()..'Scripts\\KTZ_SIOC_Mi8_v5006.lua'); 

-- dofile(lfs.writedir()..'Scripts\\CACH3_ExportDCS.lua'); 

