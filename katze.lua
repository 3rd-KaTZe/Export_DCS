k = {} -- création de la "master table"
k.export_fc3_done = false -- l'export de FC3 a déjà été fait, ne plus le refaire en boucle pour rien
k.current_aircraft = nil -- appareil dans lequel l'utilisateur se trouve actuellement
k.c -- socket
k.log = nil
k.log_file = nil
k.sioc = {}
k.sioc.contact = nil
k.sioc.msg = nil
k.sioc.connect = nil
k.sioc.config = {}
k.sioc.buffer = {}


k.log = function (message)

	-- Création du fichier de log des communication serveur, s'il n'existe pas
	-- Format , KTZ-SIOC3000_ComLog-yyyymmdd-hhmm.csv
	--
	if DEBUG_MODE and not k.log_file then
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
	--fichierComLog:write(string.format(" %s ; %s",os.date("%d/%m/%y %H:%M:%S"),message),"\n");
		k.log_file:write(string.format(" %s ; %s",os.clock(),message),"\n");
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
	k.c = socket.try(socket.connect(host, port)) -- connect to the listener socket
	k.log("sioc_connect: socket.tcp-nodelay: true")
	k.c:setoption("tcp-nodelay",true) -- set immediate transmission mode
	k.log("sioc_connect: socket.timeout: 0.1")
	k.c:settimeout(.01) -- set the timeout for reading the socket)
   
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
	local strNew = tostring(tonumber(k) + sioc.config.plage)
	
	v = string.format("%d", v);
	
	if (strValeur ~= Data_Buffer[strNew]) then
		-- On stock la nouvelle valeur dans la table buffer
		Data_Buffer[strNew] = strValeur ;
		-- Envoi de la nouvelle valeur
		socket.try(c:send(string.format("Arn.Resp:%s=%.0f:\n",strNew,strValeur)))
		local messageEnvoye = "OUT--> ;" .. (string.format("Arn.Resp:%s=%.0f:",strNew,strValeur))
		-- Log du message envoyé
		--logCom(messageEnvoye)
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

dofile ( lfs.writedir().."Scripts\\siocConfig.lua" )
