package.path  = package.path..";.\\LuaSocket\\?.lua"
package.cpath = package.cpath..";.\\LuaSocket\\?.dll"


k = {} -- création de la "master table"
k.config = {}
k.sioc = {}
k.loop = {} -- boucles d'export

k.debug = true

k.export_fc3_done = false -- l'export de FC3 a déjà été fait, ne plus le refaire en boucle pour rien
k.current_aircraft = nil -- appareil dans lequel l'utilisateur se trouve actuellement
k.log = nil -- fonction de logging
k.log_file = nil -- fichier log
dofile ( lfs.writedir().."Scripts\\siocConfig.lua" ) -- parsing des options
k.config.sioc.fast = (k.sioc.config.fast or 100) / 1000 -- intervalle boucle d'export rapide
k.config.sioc.slow = (k.sioc.config.slow or 500) / 1000 -- intervalle boucle d'export lente
k.config.sioc.ip = k.sioc.config.ip or "127.0.0.1" -- IP serveur SIOC
k.config.sioc.port = k.sioc.config.port or 8092 -- port serveur SIOC
k.config.fps = k.config.fps or 5 -- intervalle échantillonages FPS
k.sioc.ok = false -- "true" si le socket SIOC est connecté
k.sioc.socket = require("socket") -- socket SIOC client
k.sioc.contact = nil
k.sioc.msg = nil
k.sioc.connect = nil -- fonction de connection à sioc
k.sioc.write = nil -- fonction d'envoi des données à SIOC
k.sioc.read = nil -- fonction de réception des données SIOC
k.sioc.buffer = {} -- tampon SIOC

k.loop.fast = {} -- export rapide
k.loop.fast.func = nil 
k.loop.fast.next_sample = nil

k.loop.slow = {} -- export lent
k.loop.slow.func = nil -- fonction d'export lente
k.loop.slow.next_sample = nil

k.loop.fps = {} -- export lent
k.loop.fps.func = nil -- fonction d'export lente
k.loop.fps.next_sample = nil
k.loop.fps.counter = nil
k.loop.fps.max = nil
k.loop.fps.min = nil
k.loop.fps.tot = nil



k.export = {}
k.export.weapon_init = nil






k.log = function (message)

	-- Création du fichier de log des communication serveur, s'il n'existe pas
	-- Format , KTZ-SIOC3000_ComLog-yyyymmdd-hhmm.csv
	--
	if k.debug then
		
		if not k.log_file then
			-- création du fichier log si nécessaire
       			k.log_file = io.open(lfs.writedir().."Logs\\KatzePit\\KTZ-SIOC5010_ComLog-"..os.date("%Y%m%d-%H%M")..".csv", "w");
				
			-- Ecriture de l'entète dans le fichier
			if k.log_file then
				k.log_file:write("*********************************************;\n");
				k.log_file:write("*     Fichier Log des Communications SIOC   *;\n");
				k.log_file:write("*     Par KaTZe  -  http://www.3rd-wing.net *;\n");
				k.log_file:write("*     Version FC3  du 02/02/2015            *;\n");
				k.log_file:write("*********************************************;\n\n");
			end
			
		end
	
		-- Ecriture des données dans le fichier existant
		if k.log_file then
			k.log_file:write(string.format(" %s ; %s",os.clock(),message),"\n");
		end
	end
end

k.sioc.connect = function ()
	
	k.log("sioc_connect()")
	
	-- va chercher la config IP dans siocConfig
	-- on retombe sur les valeurs par défaut si on ne les trouve pas
	host = k.sioc_config.ip or "127.0.0.1"
    	port = k.sioc_config.port or 8092
	k.log("sioc_connect: ip:"..host.." port:"..port)
	
	k.log("sioc_connect: ouverture du socket")
	k.sioc.socket = socket.try(socket.connect(host, port)) -- connect to the listener socket
	k.log("sioc_connect: socket.tcp-nodelay: true")
	k.sioc.socket:setoption("tcp-nodelay",true) -- set immediate transmission mode
	k.log("sioc_connect: socket.timeout: 0.1")
	k.sioc.socket:settimeout(.01) -- set the timeout for reading the socket)
   
------------------------------------------------------------------------
-- 	Offset de SIOC qui seront écoutés								  --
-- 	0001 = Commande générale										  --
-- 	0002 = Commande spéciale										  --
------------------------------------------------------------------------

	inputs = {}
	inputs [1]=1
	inputs [2]=2
	
	local x, i
    	local s = ""
    
	k.log("sioc_connect: création du handshake de SIOC")
	for x,i in pairs(inputsTable)
	do
	    s = s..x..":"
	end
	k.log("sioc_connect: handshake SIOC: "..s)
	
    	k.log("sioc_connect: envoi du handshake à SIOC")
    	socket.try(c:send("Arn.Inicio:"..s.."\n"))
    	
	k.sioc.contact = ("Arn.Inicio:"..s.."\n")
	k.sioc.msg = "INIT-->;" .. messageContact
	k.log("sioc_connect: contact: "..contact)
	k.log("sioc_connect: msg: "..msg
	
end

k.sioc.write = function (k, v)
	-- k: clef
	-- v: valeur


	-- Décalage des exports vers une plage SIOC
	-- Indiquer dans siocConfig.lua la plage désirée
	k = tostring(tonumber(k) + sioc.config.plage)
	
	v = string.format("%d", v);
	
	if (v ~= sioc.buffer[k]) then
		-- On stock la nouvelle valeur dans la table buffer
		sioc.buffer[k] = v ;
		-- Envoi de la nouvelle valeur
		local msg = string.format("Arn.Resp:%s=%.0f:\n",k,v)
		socket.try(k.sioc.socket:send(msg))
		-- k.log(msg)
	end		
end

k.sioc.read = function()
	
	-- Check for data/string from the SIOC server on the socket
    --logCom("*** Fonction recupInfo activated","\n")
	
	-- socket.try(c:send("Arn.Resp"))
	local msg = sioc.socket:receive()
    
	if msg then
		-- k.log("IN-->;".. tostring(messageRecu))
		
		local s,e,m = string.find(msg,"(Arn.%w+)");
		m = tostring(m);
        
		------------------------------------------------------------
		-- Les types de message acceptés :                        --
		--                                                        --
		-- Arn.Vivo   : Le serveur à reçu "Arn.Vivo": du client   -- implementation à tester
		--              Le serveur répond "Arn.Vivo"              --
		--														  --
		-- Arn.Resp   : Message pour l'execution des commandes    -- réponse de SIOC
		--              seul deux valeurs sont acceptées:         --
		--				0=[valeur] -> le paramètres valeur(      )--
		-- 				1=[valeur] -> le paramètre commande		  --
		--				Ex:Arn.Resp:0=5000:1=3: ou Arn.Resp:1=145:--
		--              a noter que Arn.Resp:1=0: remets le       --
		--              cache valeur à 'nil' aussi aprés chaque   --
		--				commande exécuté                          --
		------------------------------------------------------------
		if m == "Arn.Resp" then
			--logData("Message type Arn.Resp-----", "\n")
			--------------------------------------------------------
			-- Type = Arn.Resp:                                   --
			--------------------------------------------------------
			
			-- extraction du message 
			-- (message type par exemple :1=3:0=23:6=3456)
			local s,e,m = string.find(msg,"([%d:=-]+)")
			--logData(message)
			-- longueur du message
			local l = e - s
			-- logData(longueur)
			-- découpe du message en commande et envoi à lockon
			-- (commandes type 1=3  0=23  6=3456)
			
			local cmd,c,v,i,e,ee
			-- cmd: commande
			-- c: canal
			-- v: valeur
			-- i: index
			-- e: fin du message précédent
			-- ee: fin de la partie "canal" dans le message courant
			local x = 0

			while x < l do
				-- récupération du premier message
				_,e,cmd = string.find(msg,"([%d=-]+)", x)
				k.log("sioc.read(): commande: "..cmd)
				
				-- récupération du canal
				_,ee,c = string.find(cmd, "([%d-]+)")
				c = tonumber(c)
				k.log("sioc.read(): canal: "..c)
				
				-- récupération de la valeur
				_,_,v = string.find(cmd, "([%d-]+)",ee+1)
				v = tonumber(v)
				k.log("sioc.read(): valeur: "..v)
				
				
				if c == 1 and v > 0 then
					k.log("sioc.read(): envoi de la valeur à DCS")
					LoSetCommand(v)
				end
					
				-- passage au message suivant			
				x = y + 1
			end
			
		else
			k.log("sioc.read(): erreur: message SIOC incorrect: "..msg)
		end
    end
end

function rendre_hommage_au_grand_Katze()
	local todo_file = false -- fichier à lire
	local l_device = GetDevice(0)
	if type(l_device) == "table" then -- on est dans un appareil DCS, pas FC3
		local my_info = LoGetSelfData()
		if my_info.Name ~= k.current_aircraft then -- arrivée cockpit ou changement d'appareil
			k.current_aircraft = my_info.Name
			if k.current_aircraft == "A-10C" then
			elseif k.current_aircraft == "Ka-50" then
				todo_file = '/Scripts/KTZ_SIOC_KA50.lua'
			elseif k.current_aircraft == "Mi-8MT" then
				todo_file = '/Scripts/KTZ_SIOC_Mi8.lua'
			elseif k.current_aircraft == "UH-1H" then
				todo_file = '/Scripts/KTZ_SIOC_UH1.lua'
			end
		else
			-- on est toujours dans le même appareil
		end
		k.exportFC3done = false -- remise à zéro au cas où on retourne dans un appareil FC3 par la suite
	elseif not exportFC3done then
		exportFC3done = true
		todo_file = '/Scripts/KTZ_SIOC_FC3.lua'
	end
	if todo_file then -- s'il faut charger un ficier
		if file_exists(todo_file) then -- et que ce fichier existe
			dofile(lfs.writedir()..todo_file) -- alors charger le fichier
		end
	end
end

function file_exists(chaton)
	local f=io.open(lfs.writedir()..chaton,'r')
	if f~=nil then io.close(f) return  true else return false end
end



if pcall(k.sioc.connect) then
	k.log("connection SIOC établie")
	k.sioc.ok = true
else
	k.log("échec lors de la connexion à SIOC")
	k.sioc.ok = false
end

if k.sioc.ok then
	
	-- Mise à zero du panel armement dans SIOC
	k.export.weapon_init()
	
	-- Envoi à SIOC de l'heure de début de mission
	local mission_start = LoGetMissionStartTime()
	local cur_time = LoGetModelTime()
	
	k.sioc.write(41,mission_start)

	k.log("  ","\n")
	k.log("--- Initialisation du Séquenceur ---" ,"\n")
	k.log(string.format(" Début de mission (secondes) = %.0f",mission_start,"\n"))	
	k.log(string.format(" Boucle rapide = %.1f secondes",k.config.sioc.fast,"\n"))
	k.log(string.format(" Boucle rapide = %.1f secondes",k.config.sioc.slow,"\n"))
	k.log(string.format(" Echantillonnage FPS = %.1f secondes",k.config.fps,"\n"))

	-- Initialisation des déclencheurs rapides, lents et FPS
	k.loop.fast.next_sample = cur_time + k.config.sioc.fast
	k.loop.slow.next_sample  = cur_time + k.config.sioc.slow
	k.loop.fps.next_sample  = cur_time + k.config.fps

	k.log("  ","\n")
	k.log("---KaTZe Log: KTZ-FPS-Check Activated ----")
end
