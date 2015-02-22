-- Chargement des packages nécessaires à la création du socket SIOC
package.path  = package.path..";.\\LuaSocket\\?.lua"
package.cpath = package.cpath..";.\\LuaSocket\\?.dll"

-- Initialisation de la table principale
k = {}
k.current_aircraft = nil
k.config = {}
k.common = {}
k.sioc = {}
k.sioc.ok = false -- "true" si le socket SIOC est connecté
k.sioc.socket = require("socket") -- socket SIOC client
k.sioc.buffer = {} -- tampon SIOC

k.loop = {} -- boucles d'export
k.loop = {}
k.loop.fast = nil
k.loop.slow = nil
k.export = {
    ka50 = {},
    mi8 = {},
    uh1 = {},
    fc3 = {}
}
k.loop.sample = {fast=0.1, slow=0.5, fps=5}
k.loop.next_sample = {fast=0, slow=0, fps=0}
k.loop.start_time = nil
k.loop.current_time = nil
k.loop.fps = {
    counter = 0,
    total = 0
}

k.file_exists = function(p)
	local f=io.open(p,'r')
	if f~=nil then io.close(f) return  true else return false end
end

-------------------------------------------------------------------------------
-- Logging & debug
k.debug = true
k.debug_file = nil

k.make_log_file = function()
	-- création, si nécessaire, di fichier de log
	if not k.debug_file then
		-- création du fichier log si nécessaire
		local p = k.dir.logs.."/KTZ-SIOC5010_ComLog-"..os.date("%Y%m%d-%H%M")..".csv"
       		k.debug_file = io.open(p, "w")
		-- Ecriture de l'entête dans le fichier
		if k.debug_file then
			k.debug_file:write("*********************************************;\n")
			k.debug_file:write("*     Fichier Log des Communications SIOC   *;\n")
			k.debug_file:write("*     Par KaTZe  -  http://www.3rd-wing.net *;\n")
			k.debug_file:write("*     Version FC3  du 02/02/2015            *;\n")
			k.debug_file:write("*********************************************;\n\n")
		else
			env.info("KTZ_PIT: erreur lors de la création du fichier log: "..p)
		end
	end
end

k.debug = function (message)
	-- Création du fichier de log des communication serveur, s'il n'existe pas
	-- Format , KTZ-SIOC3000_ComLog-yyyymmdd-hhmm.csv
	--
	if k.debug then
		k.make_log_file()
		-- Ecriture des données dans le fichier existant
		if k.debug_file then
			k.debug_file:write(string.format(" %s ; %s",os.clock(),message),"\n")
		end
		-- Ecriture dans "dcs.log"
        if env ~= nil then
		    env.info("KTZ_PIT: "..message)
        end
	end
end

k.info = function(message)
	k.make_log_file()
	if k.debug_file then
		k.debug_file:write(string.format(" %s ; %s",os.clock(),message),"\n")
	end
    if env ~= nil then
	    env.info("KTZ_PIT: "..message)
    end
end

k.info("chargement de katze.lua")
dofile ( lfs.writedir().."Scripts\\katze_config.lua" )

k.sioc.ip = k.sioc.ip or "127.0.0.1" -- IP serveur SIOC
k.info("IP serveur SIOC: "..k.sioc.ip)

k.sioc.port = k.sioc.port or 8092 -- port serveur SIOC
k.info("port serveur SIOC: "..k.sioc.port)

k.loop.sample.fast = (k.loop.sample.fast or 100) / 1000 -- intervalle boucle d'export rapide
k.info("Export rapide: toutes les "..k.loop.sample.fast.." secondes")

k.loop.sample.slow = (k.loop.sample.slow or 500) / 1000 -- intervalle boucle d'export lente
k.info("Export lent: toutes les "..k.loop.sample.slow.." secondes")

k.loop.sample.fps = k.loop.sample.fps or 5 -- intervalle échantillonages FPS
k.info("Export des FPS: toutes les "..k.loop.sample.fps.." secondes")

k.info('Chargement de sioc.lua')
dofile(lfs.writedir().."Scripts\\sioc.lua")

k.info('Chargement de common.lua')
dofile(lfs.writedir().."Scripts\\common.lua")


k.exportFC3done = false

function rendre_hommage_au_grand_Katze()
    -- NE PAS SUPPRIMER --
end


k.mission_start = function()
	k.debug("début d'une nouvelle mission")
	k.debug("remise à zéro des compteurs de FPS")
	k.loop.fps = {}
	k.loop.fps[10] = 0
	k.loop.fps[20] = 0
	k.loop.fps[30] = 0
	k.loop.fps[40] = 0
	k.loop.fps[50] = 0
	k.loop.fps[60] = 0
	k.loop.fps[70] = 0
	-- Mise à zero du panel armement dans SIOC
	
	k.debug("test de la connexion avec SIOC")
	if k.sioc.ok then
		k.debug("SIOC est connecté")
		if k.exportFC3done then
			k.debug("remise à zéro du panel d'armement de FC3")
			k.fc3.weapon_init()
		end
		k.debug("envoi à SIOC de l'heure de début de mission")
		k.sioc.send(41,k.loop.start_time)
	else
		k.debug("SIOC n'est pas connecté")
	end
end

k.mission_end = function()
	k.debug("  ","\n")
	k.debug("--- Rapport de Vol ---" ,"\n")
	k.debug(string.format(" Mission Start Time (secondes) = %.0f",k.loop.start_time,"\n"))
	k.debug(string.format(" Sampling Period 1 = %.1f secondes",k.loop.sample.fast,"\n"))
	k.debug(string.format(" Sampling Period 2 = %.1f secondes",k.loop.sample.slow,"\n"))
	k.debug(string.format(" Sampling Period FPS = %.1f secondes",k.loop.sample.fps,"\n"))
	-- imprimer l'histogramme FPS
	k.loop.fps_histo = {}
	k.loop.fps_histo[10] = k.loop.fps[10] / k.loop.fps.total * 100
	k.loop.fps_histo[20] = k.loop.fps[20] / k.loop.fps.total * 100
	k.loop.fps_histo[30] = k.loop.fps[30] / k.loop.fps.total * 100
	k.loop.fps_histo[40] = k.loop.fps[40] / k.loop.fps.total * 100
	k.loop.fps_histo[50] = k.loop.fps[50] / k.loop.fps.total * 100
	k.loop.fps_histo[60] = k.loop.fps[60] / k.loop.fps.total * 100
	k.loop.fps_histo[70] = k.loop.fps[70] / k.loop.fps.total * 100
	
	-- log des résultats
	k.debug(string.format(" Total Number of Frames = %.0f",k.loop.fps.total,"\n"))
	k.debug(string.format(" Flight Duration = %.0f secondes",k.loop.current_time,"\n"))
	k.debug("  ","\n")
	k.debug(string.format("*** Average FPS =  %.1f ",k.loop.fps.total/k.loop.current_time,"\n"))
	k.debug("  ","\n")
	k.debug(string.format("*** FPS < 10      = %.1f percent",k.loop.fps_histo[10],"\n"))
	k.debug(string.format("*** 10 < FPS < 20 = %.1f percent",k.loop.fps_histo[20],"\n"))
	k.debug(string.format("*** 20 < FPS < 30 = %.1f percent",k.loop.fps_histo[30],"\n"))
	k.debug(string.format("*** 30 < FPS < 40 = %.1f percent",k.loop.fps_histo[40],"\n"))
	k.debug(string.format("*** 40 < FPS < 50 = %.1f percent",k.loop.fps_histo[50],"\n"))
	k.debug(string.format("*** 50 < FPS < 60 = %.1f percent",k.loop.fps_histo[60],"\n"))
	k.debug(string.format("*** 60 < FPS      = %.1f percent",k.loop.fps_histo[70],"\n"))
	k.debug("  ","\n")
	k.debug("Miaou à tous !!!")
	
	
	
	
	
	
end

k.info("chargement des pits")
k.file = {
	lfs.writedir().."/Scripts/KTZ_SIOC_FC3.lua",
	lfs.writedir().."/Scripts/KTZ_SIOC_Mi8.lua",
	lfs.writedir().."/Scripts/KTZ_SIOC_UH1.lua",
	lfs.writedir().."/Scripts/KTZ_SIOC_KA50.lua"
}

for i=1, #k.file, 1 do
	local f = k.file[i]
	k.debug("test de l'existence de "..f)
	if k.file_exists(f) then
		k.info("Chargement du pit: "..f)
		dofile(f)
	end
end

k.info("tentative de connexion à SIOC")
k.sioc.connect()
if k.sioc.ok then
	k.info("SIOC connecté")
	k.loop.start_time = LoGetMissionStartTime()
	k.loop.current_time = LoGetModelTime()
		
	k.loop.next_sample.fast = k.loop.current_time + k.loop.sample.fast
	k.loop.next_sample.slow = k.loop.current_time + k.loop.sample.slow
	k.loop.next_sample.fps = k.loop.current_time + k.loop.sample.fps

	k.debug("chargement de overload.lua")
	dofile(lfs.writedir().."/Scripts/overload.lua")
else
	k.info("erreur lors de la tentative de connexion à SIOC")
end