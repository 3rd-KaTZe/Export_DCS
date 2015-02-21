-------------------------------------------------------------------------------
-- Initialisation de SIOC
k.sioc.ok = false -- "true" si le socket SIOC est connecté
k.sioc.socket = require("socket") -- socket SIOC client
k.sioc.buffer = {} -- tampon SIOC

k.sioc.connect = function () -- fonction de connection à sioc
	
	k.log("sioc_connect()")
	-- on retombe sur les valeurs par défaut si on ne les trouve pas
	host = k.config.sioc.ip or "127.0.0.1"
    port = k.config.sioc.port or 8092
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
	for x,i in pairs(inputs)
	do
	    s = s..x..":"
	end
	k.log("sioc_connect: handshake SIOC: "..s)
	
	k.log("sioc_connect: envoi du handshake à SIOC")
	socket.try(k.sioc.socket:send("Arn.Inicio:"..s.."\n"))
    	
	k.sioc.contact = ("Arn.Inicio:"..s.."\n")
	k.sioc.msg = "INIT-->;" .. k.sioc.contact
	k.log("sioc_connect: contact: "..k.sioc.contact)
	k.log("sioc_connect: msg: "..k.sioc.msg)
	k.sioc.ok = true
end

k.sioc.send = function (strAttribut,valeur)

		-- Option possible : Décalage des exports vers une plage SIOC
		-- Indiquer dans siocConfig.lua la plage désirée
		-- newAtt = tonumber(strAttribut) + siocConfig.plageSioc
		k.log("attrib: "..strAttribut)
		k.log("valeur: "..valeur)
		
		local strNew = tostring(strAttribut)
		
		local strValeur = string.format("%d",valeur);
		
		if (strValeur ~= k.sioc.buffer[strNew]) then
			-- On stock la nouvelle valeur dans la table buffer
			k.sioc.buffer[strNew] = strValeur ;
			-- Envoi de la nouvelle valeur
			socket.try(k.sioc.socket:send(string.format("Arn.Resp:%s=%.0f:\n",strNew,strValeur)))
			local messageEnvoye = "OUT--> ;" .. (string.format("Arn.Resp:%s=%.0f:",strNew,strValeur))
			-- Log du message envoyé
			k.log(messageEnvoye)
		end		
end

k.sioc.receive = function ()
	k.log("sioc.receive()")
	
	-- Check for data/string from the SIOC server on the socket
    --k.log("*** Fonction recupInfo activated","\n")
	
	-- socket.try(c:send("Arn.Resp"))
	local messageRecu = k.sioc.socket:receive()
    k.log(tostring(messageRecu))
	if messageRecu then
		
		local messagelog = "IN-->;".. tostring(messageRecu)
		k.log(messagelog)
		
		local s,l,typeMessage = string.find(messageRecu,"(Arn.%w+)");
		typeMessage = tostring(typeMessage);
        
		------------------------------------------------------------
		-- Les types de message acceptés :                        --
		--                                                        --
		-- Arn.Vivo   : Le serveur à reçu "Arn.Vivo": du client   -- 
		--              Le serveur répond "Arn.Vivo"              --
		--														  --
		-- Arn.Resp   : Message pour l'execution des commandes    --
		--              a noter que Arn.Resp:1=0: remets le       --
		--              cache valeur à 'nil' aussi aprés chaque   --
		--				commande exécuté                          --
		------------------------------------------------------------
		if typeMessage == "Arn.Resp" then
						
-----------------------------------------------------------------------------
-- 	Lecture du message												  --*************************************************************
----------------------------------------------------------------------------

			-- (message type par exemple :1=3:0=23:6=3456)
			local debut,fin,message = string.find(messageRecu,"([%d:=-]+)")
			-- k.log(message)
			-- longueur du message
			local longueur
			longueur = fin - debut
			--k.log(longueur)
			-- découpe du message en commande et envoi à DCS
						
			local commande,Schan,chan,Svaleur,valeur,i,a,b,c,d,e,f,lim,device,bouton,typbouton,val
			lim = 0

			while lim < longueur do
				a,b,commande = string.find(message,"([%d=-]+)", lim)
				--k.log(commande)
				c,d,Schan = string.find(commande, "([%d-]+)")
				chan = tonumber(Schan)
				--k.log(string.format(" Offset = %.0f",chan,"\n"))
				e,f,Svaleur = string.find(commande, "([%d-]+)",d+1)
								
				valeur = tonumber(Svaleur)
				--k.log(string.format(" Valeur = %.0f",valeur,"\n"))
				
				
-----------------------------------------------------------------------------
-- 	Interpretation des commandes										  --*************************************************************
----------------------------------------------------------------------------
				
				-----------------------------------------------------------------
				-- Canal #1 : Commande type FC2
				-----------------------------------------------------------------
				if chan ==1 and valeur > 0 then
						
					-- Envoi à LockOn, commande type Classique FC3
					LoSetCommand(valeur)
				
				end
				
				-----------------------------------------------------------------
				-- Canal #2 : Commande type DCS
				-----------------------------------------------------------------
				
				-- KaTZe Modif BS2, Commande codée sur 8 caracteres , TDDBBBPV
				-- T = Type de bouton
				-- DD = Device
				-- BBB = numero du bouton
				-- P = Pas du rotateur
				-- V = Valeur recu
				
				
				if chan ==2 and valeur > 0 then
					typbouton = tonumber(string.sub(Svaleur,1,1))
					device = tonumber(string.sub(Svaleur,2,3))
					bouton = tonumber(string.sub(Svaleur,4,6))
					pas = tonumber(string.sub(Svaleur,7,7))
					val = tonumber(string.sub(Svaleur,8,8))
				
					--k.log(string.format(" Device = %.0f",device,"\n"))
					--k.log(string.format(" Bouton = %.0f",bouton,"\n"))
					--k.log(string.format(" Type = %.0f",typbouton,"\n"))
					--k.log(string.format(" Valeur = %.0f",val,"\n"))
					
					-----------------------------------------------------------------
					-- Type 1 : Simple On/Off
					if typbouton == 1 then
						-- Type interrupteur deux voies
						-- Envoi à LockOn, commande Device, Bouton + 3000 , Argument
						GetDevice(device):performClickableAction(3000+bouton,val)
						
					end
					
					-----------------------------------------------------------------
					-- Type 2 : Simple On/Off avec Capot sur KA50 ... inutilisé sur Mi-8 ou UH-1
					-- La séquence capot/bouton/capot est créé en 3 commandes successives par javascript
					if typbouton == 2 then
						-- Type interrupteur deux voies, avec capot , val = val * 1000
						-- On ouvre, bascule, ferme
						GetDevice(device):performClickableAction(3000+bouton+1,val)
						GetDevice(device):performClickableAction(3000+bouton,val)
						GetDevice(device):performClickableAction(3000+bouton+1,val)
						
					end
					
					-----------------------------------------------------------------
					-- Type 3 : 3 positions Bas/Mid/Haut
					if typbouton == 3 then
						-- Type interrupteur 3 positions  -1 , 0 , +1
						-- On décale de -1 i.e. 0>>-1 , 1>>0 , 2>>1
						GetDevice(device):performClickableAction(3000+bouton,(val-1))
																		
					end
					
					-----------------------------------------------------------------
					-- Type 4 : Rotateur Multiple (Décimal) ... 
					if typbouton == 4 then
					
						-- Type interrupteur rotary , 0.0 , 0.1 , 0.2 , 0.3 , ...
						-- On envoie des valeur de 0 à X
					
						if pas < 2 then  -- Pas à 0 ou 1, incrément par 0.1
							GetDevice(device):performClickableAction(3000+bouton,val/10)
						end
						
						if pas == 2 then -- Pas à 2 , incrément par 0.05
							GetDevice(device):performClickableAction(3000+bouton,val/20)
						end
						
						
												
					end
					-----------------------------------------------------------------
					-- Type 5 : Press Bouton ... commande suivie de mise à zero
					if typbouton == 5 then
						-- Type interrupteur press bouton
						-- On envoie 1 puis zero
						GetDevice(device):performClickableAction(3000+bouton,val)
						GetDevice(device):performClickableAction(3000+bouton,val*0)
												
					end
					
					
					-----------------------------------------------------------------
					-- Type 6 : Rotateur Multiple (Décimal , Centré sur zero)
					
					if typbouton == 6 then
						-- Rotateur centré sur 0 , pas de 0.1, décalage négatif de "pas"/10
						-- exemple si pas = 5 , alors 0 --> -0.5 , 1 --> -0.4 , ... 5 --> 0 , 9 --> 0.4
						GetDevice(device):performClickableAction(3000+bouton,val/10 - pas/10)
																		
					end
					
					
					-----------------------------------------------------------------
					-- Type 7 : Rotateur Multiple (Centésimal)
					if typbouton == 7 then
						-- Rotateur centesimal , incrément = ( 10 * pas + val )/ 100
						GetDevice(device):performClickableAction(3000+bouton,(pas * 10 + val)/100)
																		
					end
					
					
				
				end
								
				lim = b + 1
			end
			
		else
			-- k.log("---Log: SIOC Message Incorrect ; non type Arn.Resp ; Message Ignoré -----", "\n")
		end
    end
end