-- Chargement des packages nécessaires à la création du socket SIOC
package.path  = package.path..";.\\LuaSocket\\?.lua"
package.cpath = package.cpath..";.\\LuaSocket\\?.dll"

-- Initialisation de la table principale
k = {
    debug_enabled = false,
    debug_file = false,
    current_aircraft = nil,
    config = {},
    common = {},
    sioc = {
        ok = false, -- "true" si le socket SIOC est connecté
        socket = require("socket"), -- socket SIOC client
        buffer = {}, -- tampon SIOC
    },
    loop = {
        fast = function() end,
        slow = function() end,
        sample = { fast=0.1, slow=0.5, fps=5 },
        next_sample = { fast=0, slow=0, fps=0 },
        fps = { counter = 0, total = 0, },
        start_time = 0,
        current_time = 0,
    },
    export = { ka50 = {}, mi8 = {}, uh1 = {}, fc3 = {} },
}

k.file_exists = function(p)
	local f=io.open(p,'r')
	if f~=nil then io.close(f) return  true else return false end
end

k.make_log_file = function()
	-- création, si nécessaire, di fichier de log
	if not k.debug_file then
		-- création du fichier log si nécessaire
		local p = lfs.writedir().."/Logs/KatzePit/KTZ-SIOC5010_ComLog-"..os.date("%Y%m%d-%H%M")..".csv"
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
	if k.debug_enabled then
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
	k.loop.fps = {[10]=0, [20]=0, [30]=0, [40]=0, [50]=0, [60]=0, [70]=0}
    k.loop.fps.counter = 0
    k.loop.fps.total = 0
	-- Mise à zero du panel armement dans SIOC
	
	k.debug("test de la connexion avec SIOC")
	if k.sioc.ok then
		k.debug("SIOC est connecté")

        k.debug("remise à zéro du panel d'armement de FC3")
        k.export.fc3.weapon_init()

		k.debug("envoi à SIOC de l'heure de début de mission")
		k.sioc.send(41,k.loop.start_time)
	else
		k.debug("SIOC n'est pas connecté")
	end
end

k.mission_end = function()
	k.info("  ","\n")
	k.info("--- Rapport de Vol ---" ,"\n")
	k.info(string.format(" Début de la mission : %.0f secondes",k.loop.start_time,"\n"))
	k.info(string.format(" Boucle rapide       : %.1f secondes",k.loop.sample.fast,"\n"))
	k.info(string.format(" Boucle lente        : %.1f secondes",k.loop.sample.slow,"\n"))
	k.info(string.format(" Boucle FPS          : %.1f secondes",k.loop.sample.fps,"\n"))
	
	-- log des résultats
	k.info(string.format(" Total Number of Frames = %.0f",k.loop.fps.total,"\n"))
	k.info(string.format(" Flight Duration = %.0f secondes",k.loop.current_time,"\n"))
	k.info("  ","\n")
	k.info(string.format("*** Average FPS =  %.1f ",k.loop.fps.total/k.loop.current_time,"\n"))
	k.info("  ","\n")
    for i=10, 70, 10 do
        local fps = k.loop.fps[i] / k.loop.fps.total * 100
        k.info(string.format("*** "..(i-10).." < FPS"..((" < "..(i+10)) and i < 70 or "").." = %.1f percent", fps,"\n"))
    end
	k.info("  ","\n")
	k.info("Miaou à tous !!!")
    k.info('         *                  *')
    k.info('             __                *')
    k.info("          ,db'    *     *")
    k.info('         ,d8/       *        *    *')
    k.info('         888')
    k.info('         `db\       *     *')
    k.info('           `o`_                    **')
    k.info('      *               *   *    _      *')
    k.info('            *                 / )')
    k.info('         *    (\__/) *       ( (  *')
    k.info('       ,-.,-.,)    (.,-.,-.,-.) ).,-.,-.')
    k.info('      | @|  ={      }= | @|  / / | @|o |')
    k.info('     _j__j__j_)     `-------/ /__j__j__j_')
    k.info('     ________(               /___________')
    k.info('      |  | @| \              || o|O | @|')
    k.info("      |o |  |,'\       ,   ,'\"|  |  |  |  hjw")
    k.info("     vV\|/vV|`-'\\  ,---\   | \Vv\hjwVv\//v")
    k.info('                _) )    `. \ /')
    k.info('               (__/       ) )')
    k.info('                         (_/')
	
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

	k.info("chargement de overload.lua")
	dofile(lfs.writedir().."/Scripts/overload.lua")
    k.info("KatzePit prêt ! Que le Miaou soit avec vous")
else
	k.info("erreur lors de la tentative de connexion à SIOC")
end