package.path  = package.path..";.\\LuaSocket\\?.lua"
package.cpath = package.cpath..";.\\LuaSocket\\?.dll"

k = {}
k.current_aircraft = nil
k.config = {}
k.sioc = {}
k.loop = {} -- boucles d'export
k.loop = {}
k.loop.fast = nil
k.loop.slow = nil
k.ka50 = {}
k.ka50.export = {}
k.mi8 = {}
k.mi8.export = {}
k.uh1 = {}
k.uh1.export = {}
k.fc3 = {}
k.fc3.export = {}
k.loop.sample = {}
k.loop.sample.fast = nil
k.loop.sample.slow = nil
k.loop.sample.fps = nil
k.loop.next_sample = {}
k.loop.next_sample.fast = nil
k.loop.next_sample.slow = nil
k.loop.next_sample.fps = nil
k.loop.start_time = nil
k.loop.current_time = nil
k.loop.fps_counter = 0
k.loop.fps_tot = 0



-------------------------------------------------------------------------------
-- Logging & debug
k.debug = true
k.log_file = nil -- fichier log
k.log = function (message)

	-- Création du fichier de log des communication serveur, s'il n'existe pas
	-- Format , KTZ-SIOC3000_ComLog-yyyymmdd-hhmm.csv
	--
	if k.debug then
		
		if not k.log_file then
			-- création du fichier log si nécessaire
       			k.log_file = io.open(lfs.writedir().."Logs\\KatzePit\\KaTZPitLog_Flight_date_"..os.date("%Y%m%d-%H%M")..".csv", "w")
				
			-- Ecriture de l'entète dans le fichier
			if k.log_file then
				k.log_file:write("*********************************************;\n")
				k.log_file:write("*     Fichier Log des Communications SIOC   *;\n")
				k.log_file:write("*     Par KaTZe  -  http://www.3rd-wing.net *;\n")
				k.log_file:write("*     Version DCS-FC3  du 02/02/2015        *;\n")
				k.log_file:write("*********************************************;\n\n")
			end
			
		end
	
		-- Ecriture des données dans le fichier existant
		if k.log_file then
			k.log_file:write(string.format(" %s ; %s",os.clock(),message),"\n")
		end
	end
end

k.log("module de logging chargé")


-- k.log("remplacement de la fonction \"dofile\" par une version loggée")
-- old_dofile = dofile
-- new_dofile = function(p)
-- 	k.log("chargement du fichier "..(p or ""))
-- 	old_dofile(p)
-- end
-- dofile = new_dofile ()

-------------------------------------------------------------------------------
-- Fichier de configuration
k.log("chargement du fichier de configuration")
dofile ( lfs.writedir().."Scripts\\siocConfig.lua" ) -- parsing des options
k.config.sioc.fast = (k.config.sioc.fast or 100) / 1000 -- intervalle boucle d'export rapide
k.config.sioc.slow = (k.config.sioc.slow or 500) / 1000 -- intervalle boucle d'export lente
k.config.sioc.ip = k.config.sioc.ip or "127.0.0.1" -- IP serveur SIOC
k.config.sioc.port = k.config.sioc.port or 8092 -- port serveur SIOC
k.config.fps = k.config.fps or 5 -- intervalle échantillonages FPS
k.log("fast: "..k.config.sioc.fast)
k.log("slow: "..k.config.sioc.slow)
k.log("sioc ip: "..k.config.sioc.ip)
k.log("sioc port: "..k.config.sioc.port)
k.log("intervalle FPS: "..k.config.fps)



dofile(lfs.writedir().."Scripts\\sioc.lua")
dofile(lfs.writedir().."Scripts\\low_level.lua")


k.exportFC3done = false

function rendre_hommage_au_grand_Katze()
end


k.mission_start = function()
	k.log("début d'une nouvelle mission")
	k.log("remise à zéro des compteurs de FPS")
	k.loop.fps = {}
	k.loop.fps[10] = 0
	k.loop.fps[20] = 0
	k.loop.fps[30] = 0
	k.loop.fps[40] = 0
	k.loop.fps[50] = 0
	k.loop.fps[60] = 0
	k.loop.fps[70] = 0
	-- Mise à zero du panel armement dans SIOC
	
	k.log("test de la connexion avec SIOC")
	if k.sioc.ok then
		k.log("SIOC est connecté")
		if k.exportFC3done then
			k.log("remise à zéro du panel d'armement de FC3")
			k.fc3.weapon_init()
		end
		k.log("envoi à SIOC de l'heure de début de mission")
		k.sioc.send(41,k.loop.start_time)
	else
		k.log("SIOC n'est pas connecté")
	end
end

k.mission_end = function()
	k.log("  ","\n")
	k.log("--- Rapport de Vol ---" ,"\n")
	k.log(string.format(" Mission Start Time (secondes) = %.0f",k.loop.start_time,"\n"))	
	k.log(string.format(" Sampling Period 1 = %.1f secondes",k.loop.sample.fast,"\n"))
	k.log(string.format(" Sampling Period 2 = %.1f secondes",k.loop.sample.slow,"\n"))
	k.log(string.format(" Sampling Period FPS = %.1f secondes",k.loop.sample.fps,"\n"))
	-- imprimer l'histogramme FPS
	k.loop.fps_histo = {}
	k.loop.fps_histo[10] = k.loop.fps[10] / k.loop.fps_tot * 100
	k.loop.fps_histo[20] = k.loop.fps[20] / k.loop.fps_tot * 100
	k.loop.fps_histo[30] = k.loop.fps[30] / k.loop.fps_tot * 100
	k.loop.fps_histo[40] = k.loop.fps[40] / k.loop.fps_tot * 100
	k.loop.fps_histo[50] = k.loop.fps[50] / k.loop.fps_tot * 100
	k.loop.fps_histo[60] = k.loop.fps[60] / k.loop.fps_tot * 100
	k.loop.fps_histo[70] = k.loop.fps[70] / k.loop.fps_tot * 100
	
	-- log des résultats
	k.log(string.format(" Total Number of Frames = %.0f",k.loop.fps_tot,"\n"))
	k.log(string.format(" Flight Duration = %.0f secondes",k.loop.current_time,"\n"))
	k.log("  ","\n")
	k.log(string.format("*** Average FPS =  %.1f ",k.loop.fps_tot/k.loop.current_time,"\n"))
	k.log("  ","\n")
	k.log(string.format("*** FPS < 10      = %.1f percent",k.loop.fps_histo[10],"\n"))
	k.log(string.format("*** 10 < FPS < 20 = %.1f percent",k.loop.fps_histo[20],"\n"))
	k.log(string.format("*** 20 < FPS < 30 = %.1f percent",k.loop.fps_histo[30],"\n"))
	k.log(string.format("*** 30 < FPS < 40 = %.1f percent",k.loop.fps_histo[40],"\n"))
	k.log(string.format("*** 40 < FPS < 50 = %.1f percent",k.loop.fps_histo[50],"\n"))
	k.log(string.format("*** 50 < FPS < 60 = %.1f percent",k.loop.fps_histo[60],"\n"))
	k.log(string.format("*** 60 < FPS      = %.1f percent",k.loop.fps_histo[70],"\n"))
	k.log("  ","\n")
	k.log("Miaou à tous !!!")
	
	
	
	
	
	
end


k.log("tentative de connexion à SIOC")
-- if pcall(k.sioc.connect) then
k.sioc.connect()
if k.sioc.ok then
	k.log("SIOC connecté")
	k.loop.sample.fast = k.config.sioc.fast
	k.loop.sample.slow = k.config.sioc.slow
	k.loop.sample.fps = k.config.sioc.fps
	k.loop.start_time = LoGetMissionStartTime()
	k.loop.current_time = LoGetModelTime()
		
	k.loop.next_sample.fast = k.loop.current_time + k.loop.sample.fast
	k.loop.next_sample.slow = k.loop.current_time + k.loop.sample.slow
	k.loop.next_sample.fps = k.loop.current_time + k.loop.sample.fps

	k.log("chargement des overload")
	dofile(lfs.writedir().."/Scripts/overload.lua")
else
	k.log("erreur lors de la tentative de connexion")
end

k.file = {
	lfs.writedir().."/Scripts/KTZ_SIOC_FC3.lua",
	lfs.writedir().."/Scripts/KTZ_SIOC_Mi8.lua",
	lfs.writedir().."/Scripts/KTZ_SIOC_UH1.lua",
	lfs.writedir().."/Scripts/KTZ_SIOC_KA50.lua"
}


k.log("import des fichiers d'exports pour chaque pit")
for i=1, #k.file, 1 do
	f = k.file[i]
	k.log("test de l'existence de "..f)
	if k.file_exists(f) then
		k.log(f.." existe, chargement")
		dofile(f)
	end
end