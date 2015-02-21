local PrevLuaExportStart=LuaExportStart;

LuaExportStart=function()

---- (Hook) Works once just before mission start.
	k.mission_start(); -- Initialisation du FPS checker
			
	if PrevLuaExportStart then
		PrevLuaExportStart();
	end
end


------------------------------------------------------------------------
--    Séquence : avant chaque image            							  --
------------------------------------------------------------------------
-- Rien par défaut


------------------------------------------------------------------------
--    Séquence : après chaque image            						  --
------------------------------------------------------------------------
-- On compare le time code avec les compteurs de déclenchement

local prevNextEvent = LuaExportActivityNextEvent

LuaExportActivityNextEvent = function(t)
	
	local lDevice = GetDevice(0)
	if type(lDevice) == "table" then
		k.log("lDevice est une table, on est sous DCS")
		local myInfo = LoGetSelfData()
		if myInfo.Name ~= k.current_aircraft then
			k.exportFC3done = false
			k.current_aircraft = myInfo.Name
			if k.current_aircraft == "Ka-50" then
				k.log("remplacement des boucles fast & slow par celles du Kamov")
				k.loop.fast = k.ka50.export.fast
				k.loop.slow = k.ka50.export.slow
			elseif k.current_aircraft == "Mi-8MT" then
				k.log("remplacement des boucles fast & slow par celles du gros veau")
				k.loop.fast = k.mi8.export.fast
				k.loop.slow = k.mi8.export.slow
			elseif k.current_aircraft == "UH-1H" then
				k.log("remplacement des boucles fast & slow par celles du Huey")
				k.loop.fast = k.uh1.export.fast
				k.loop.slow = k.uh1.export.slow
			end		
		end
	elseif not k.exportFC3done then
		k.log("lDevice n'est pas une table et FC3 n'est pas initialisé")
		-- encore nécessaire ?
		k.exportFC3done = true
		k.log("remplacement des boucles fast & slow par celles de FC3")
		k.loop.fast = k.fc3.export.fast
		k.loop.slow = k.fc3.export.slow
	else
		k.log("lDevice n'est pas une table et FC3 est déjà initialisé")
	end
		
	if prevNextEvent then
		prevNextEvent(t)
	end
	
	return t + 1

end
	


local PrevLuaExportAfterNextFrame=LuaExportAfterNextFrame;

LuaExportAfterNextFrame = function()
-- (Hook) Works just after every simulation frame.
	k.log("LuaExportAfterNextFrame miaou")
	
	-- Incrément des fps à chaque frame
	k.loop.fps_counter = k.loop.fps_counter + 1
	
	-- k.loop.fps_counter.tot = k.loop.fps_counter.tot + 1 -- buggé
	k.loop.current_time = LoGetModelTime()
	k.log("current time "..k.loop.current_time)
	k.log("next_sample.fast: "..k.loop.next_sample.fast)
	if k.loop.current_time >= k.loop.next_sample.fast then --*************************************** Boucle Rapide
		
		if k.sioc.ok and k.loop.fast ~= nil then
			k.log("loop.fast")
			k.sioc.receive() -- Reception Commande
			k.loop.fast()  -- Export séquence rapide
		end
		
		-- calcul de la date de fin du prochain intervalle de temps
		k.loop.next_sample.fast = k.loop.current_time + k.loop.sample.fast
		
		
	end
	if k.loop.current_time >= k.loop.next_sample.slow then --*************************************** Boucle Lente
		
		if k.sioc.ok and k.loop.slow ~= nil then
			k.loop.slow() -- Export séquence lente
		end
		-- calcul de la date de fin du prochain intervalle de temps
		k.loop.next_sample.slow = k.loop.current_time + k.loop.sample.slow
		
	end
	
	
	if k.loop.current_time >= k.loop.next_sample.fps then --*************************************** Boucle FPS
		
		-- Interval de mesure des fps (defaut 5 secondes)
		-- Incrément des frames totale de mission
		k.loop.fps_tot = k.loop.fps_tot + k.loop.fps_counter
		
		-- Classement du nombre de frames de l'intervalle de temps dans l'histogramme
		if k.loop.fps_counter < 10 * k.loop.sample.fps then
			k.loop.fps[10] = k.loop.fps[10] + k.loop.fps_counter
		elseif k.loop.fps_counter < 20 * k.loop.sample.fps then
			k.loop.fps[20] = k.loop.fps[20] + k.loop.fps_counter
		elseif k.loop.fps_counter < 30 * k.loop.sample.fps then
			k.loop.fps[30] = k.loop.fps[30] + k.loop.fps_counter
		elseif k.loop.fps_counter < 40 * k.loop.sample.fps then
			k.loop.fps[40] = k.loop.fps[40] + k.loop.fps_counter
		elseif k.loop.fps_counter < 50 * k.loop.sample.fps then
			k.loop.fps[50] = k.loop.fps[50] + k.loop.fps_counter
		elseif k.loop.fps_counter < 60 * k.loop.sample.fps then
			k.loop.fps[60] = k.loop.fps[60] + k.loop.fps_counter
		else
			k.loop.fps[70] = k.loop.fps[70] + k.loop.fps_counter
		end	
		
		-- remise à zero du compteur de frame de l'intervalle de temps
		k.loop.fps_counter = 0
		
		-- calcul de la date de fin du prochain intervalle de temps
		k.loop.next_sample.fps = k.loop.current_time + k.loop.sample.fps
	
	end
		
	if PrevLuaExportAfterNextFrame then
		PrevLuaExportAfterNextFrame()
	end
end



------------------------------------------------------------------------
--    Séquence : Fin de mission (ExportStop)         				  --
------------------------------------------------------------------------


local PrevLuaExportStop=LuaExportStop;

LuaExportStop=function()

	k.mission_end(); -- Finalisation du FPS checker

	if PrevLuaExportStop then
		PrevLuaExportStop();
	end
end
