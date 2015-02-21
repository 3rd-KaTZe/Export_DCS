env.info("KTZ_PIT: chargement du module \"logging\"")

k.log_file = nil -- fichier log

k.make_log_file = function()
	-- création, si nécessaire, di fichier de log
	if not k.log_file then
		-- création du fichier log si nécessaire
		local p = k.dir.logs.."/KTZ-SIOC5010_ComLog-"..os.date("%Y%m%d-%H%M")..".csv"
       		k.log_file = io.open(p, "w")
		-- Ecriture de l'entête dans le fichier
		if k.log_file then
			k.log_file:write("*********************************************;\n")
			k.log_file:write("*     Fichier Log des Communications SIOC   *;\n")
			k.log_file:write("*     Par KaTZe  -  http://www.3rd-wing.net *;\n")
			k.log_file:write("*     Version FC3  du 02/02/2015            *;\n")
			k.log_file:write("*********************************************;\n\n")
		else
			env.info("KTZ_PIT: erreur lors de la création du fichier log: "..p)
		end
	end
end

k.log = function (message)
	-- Création du fichier de log des communication serveur, s'il n'existe pas
	-- Format , KTZ-SIOC3000_ComLog-yyyymmdd-hhmm.csv
	--
	if k.debug then
		k.make_log_file()
		-- Ecriture des données dans le fichier existant
		if k.log_file then
			k.log_file:write(string.format(" %s ; %s",os.clock(),message),"\n")
		end
		-- Ecriture dans "dcs.log"
		env.info("KTZ_PIT: "..message)
	end
end

k.info = function(message)
	
	-- fonction d'information, prévue pour être appelée beaucoup moins souvent que "k.log()"
	-- ne dépend pas de "k.debug", active en permanence
	k.make_log_file()
	-- Ecriture des données dans le fichier existant
	if k.log_file then
		k.log_file:write(string.format(" %s ; %s",os.clock(),message),"\n")
	end
	-- Ecriture dans "dcs.log"
	env.info("KTZ_PIT: "..message)
end
	

env.info("KTZ_PIT: chargement du module \"logging\" réussi")
