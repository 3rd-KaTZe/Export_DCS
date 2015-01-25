--[[
**************************************************************************
*     Module d'Export de données pour SIOC, et le KaTZ-Pit               *
*     Par KaTZe     -         http://www.3rd-wing.net                    *
*     Version v5.009            du   22/01/2015  pour le UH-1H           *
**************************************************************************
--]]

-- siocConfig.lua contient :
-- Script de configuration SIOC
-- Paramêtres IP : Host, Port
-- Ainsi que la plage d'Offset utilisée pour les valeurs KaTZ-Pit 
-- Si l'on veut décaler la plage rentrer une valeur (ex: 2000)

dofile ( lfs.writedir().."Scripts\\siocConfig.lua" )

-- creation de c , variable de socket #debug de Etcher
local c

-- Debug Mode, si True un fichier ".csv" est créé dans le répertoire
-- Saved Games\DCS\Export
-- Fichier Type "KTZ-SIOC5009_ComLog-yyyymmjj-hhmm.csv"
-- Info. envoyés par la fonction logCom()

------------------------------------------------------------------------
--    Fonction logCom , logging d'évènements dans un fichier .csv			  --******************************************************************
------------------------------------------------------------------------
function logCom(message)

	-- Création du fichier de log des communication serveur, s'il n'existe pas
	-- Format , KTZ-UH-SIOC5009_ComLog-yyyymmdd-hhmm.csv
	--
	if DEBUG_MODE and not fichierComLog then
       	fichierComLog = io.open(lfs.writedir().."Export\\KTZ-UH-SIOC5009_ComLog-"..os.date("%Y%m%d-%H%M")..".csv", "w");
				
		-- Ecriture de l'entète dans le fichier
		if fichierComLog then
			
			fichierComLog:write("*********************************************;\n");
			fichierComLog:write("*     Fichier Log des Communications SIOC   *;\n");
			fichierComLog:write("*     Par KaTZe  -  http://www.3rd-wing.net *;\n");
			fichierComLog:write("*     Version 5.0.09 du 22/01/2015          *;\n");
			fichierComLog:write("*********************************************;\n\n");
		end
    end
	
	-- Ecriture des données dans le fichier existant
	if fichierComLog then
        --fichierComLog:write(string.format(" %s ; %s",os.date("%d/%m/%y %H:%M:%S"),message),"\n");
		fichierComLog:write(string.format(" %s ; %s",os.clock(),message),"\n");
	end
end

---- *************************************************************************** Fonctions de connexion à  SIOC ********************************************************	   
------------------------------------------------------------------------
-- 	Login to SIOC													  --
------------------------------------------------------------------------
    
function Sioc_connect()
	
	-- Va chercher la config IP dans siocConfig
    host = siocConfig.hostIP or "127.0.0.1"
    port = siocConfig.hostPort or 8092
	
	logCom("fonction Sioc_connect")
    

		c = socket.try(socket.connect(host, port)) -- connect to the listener socket
		c:setoption("tcp-nodelay",true) -- set immediate transmission mode
		c:settimeout(.01) -- set the timeout for reading the socket)
  
------------------------------------------------------------------------
-- 	Offset de SIOC qui seront écoutés								  --
-- 	0001 = Commande générale										  --
-- 	0002 = Commande spéciale										  --
------------------------------------------------------------------------
	inputsTable = {}
	inputsTable [1]=1
	inputsTable [2]=2
	
	local lSIOC_Var, i
    local lSIOC_SendString = ""
    
    -- Generation de la "string" d'initialisation de SIOC (enregistrement des canaux écoutés)
    for lSIOC_Var,i in pairs(inputsTable)
    do
        lSIOC_SendString = lSIOC_SendString..lSIOC_Var..":"
    end
	
    -- Send the initstring
    socket.try(c:send("Arn.Inicio:"..lSIOC_SendString.."\n"))
	local messageContact = ("Arn.Inicio:"..lSIOC_SendString.."\n")
	
	messageInit = "INIT-->;" .. messageContact
	
end


---- *************************************************************************** Fonctions d'envoi de donnée à SIOC ********************************************************	   
------------------------------------------------------------------------
-- 	Send Data to SIOC												  --
------------------------------------------------------------------------
function envoyerInfo(strAttribut,valeur)


		-- Décalage des exports vers une plage SIOC
		-- Indiquer dans siocConfig.lua la plage désirée
		newAtt = tonumber(strAttribut) + siocConfig.plageSioc
		local strNew = tostring(newAtt)
		
		local strValeur = string.format("%d",valeur);
		
		if (strValeur ~= Data_Buffer[strNew]) then
			-- On stock la nouvelle valeur dans la table buffer
			Data_Buffer[strNew] = strValeur ;
			-- Envoi de la nouvelle valeur
			socket.try(c:send(string.format("Arn.Resp:%s=%.0f:\n",strNew,strValeur)))
			local messageEnvoye = "OUT--> ;" .. (string.format("Arn.Resp:%s=%.0f:",strNew,strValeur))
			-- Log du message envoyé
			-- logCom(messageEnvoye)
		end		
	end

---- *************************************************************************** Fonctions de réception de commandes depuis SIOC ************************************************	
-----------------------------------------------------------------------------
-- 	Reception du message												  --***********************************************************
-----------------------------------------------------------------------------

function Reception_SIOC_Cmd()
	
	-- Check for data/string from the SIOC server on the socket
    --logCom("*** Fonction recupInfo activated","\n")
	
	-- socket.try(c:send("Arn.Resp"))
	local messageRecu = c:receive()
    
	if messageRecu then
		
		local messagelog = "IN-->;".. tostring(messageRecu)
		--logCom(messagelog)
		
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
			-- logCom(message)
			-- longueur du message
			local longueur
			longueur = fin - debut
			--logCom(longueur)
			-- découpe du message en commande et envoi à DCS
						
			local commande,Schan,chan,Svaleur,valeur,i,a,b,c,d,e,f,lim,device,bouton,typbouton,val
			lim = 0

			while lim < longueur do
				a,b,commande = string.find(message,"([%d=-]+)", lim)
				--logCom(commande)
				c,d,Schan = string.find(commande, "([%d-]+)")
				chan = tonumber(Schan)
				--logCom(string.format(" Offset = %.0f",chan,"\n"))
				e,f,Svaleur = string.find(commande, "([%d-]+)",d+1)
								
				valeur = tonumber(Svaleur)
				--logCom(string.format(" Valeur = %.0f",valeur,"\n"))
				
				
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
				
					--logCom(string.format(" Device = %.0f",device,"\n"))
					--logCom(string.format(" Bouton = %.0f",bouton,"\n"))
					--logCom(string.format(" Type = %.0f",typbouton,"\n"))
					--logCom(string.format(" Valeur = %.0f",val,"\n"))
					
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
			--logData("---Log: SIOC Message Incorrect ; non type Arn.Resp ; Message Ignoré -----", "\n")
		end
    end
end



---- *************************************************************************** Fonctions d'Export ********************************************************************	
----------------------------------------------------------------------------------------------------------------------------------
-- 	Export Rapide et Export Lent												  --
----------------------------------------------------------------------------------------------------------------------------------

function Envoi_Data_SIOC_fast()
	    -- Timing réglé entre 100ms et 200ms
		--logCom ("time de la boucle 1 - Fast")
		--logCom(CurrentTime)
				
		-- Récupération des données à lire --------------------
		-- Attention !!!!!!!! pour boucle rapide, le nom est différent que boucle lente : Device(0) >> lMainPanel
		local lMainPanel = GetDevice(0)
		
		-- Test de la précence de Device 0 , comme table  valide
		if type(lMainPanel) ~= "table" then
			return ""
		end
		
		
		lMainPanel:update_arguments()

		-- ============== Debug 21 à 29 =========================================================================
		-- Zone utilisé pour tester de nouvelles valeurs
		--envoyerInfo(21,lMainPanel:get_argument_value(465)*100)
		--envoyerInfo(22,lMainPanel:get_argument_value(447)*100)
		--envoyerInfo(23,lMainPanel:get_argument_value(456)*100)
		--envoyerInfo(24,lMainPanel:get_argument_value(457)*100)
		--envoyerInfo(25,lMainPanel:get_argument_value(464)*100)
		--envoyerInfo(26,lMainPanel:get_argument_value(460)*100)
		--envoyerInfo(27,lMainPanel:get_argument_value(461)*1000)
		--envoyerInfo(28,lMainPanel:get_argument_value(45)*1000)
		--envoyerInfo(29,lMainPanel:get_argument_value(180)*1000)

		
		-- ============== Clock =========================================================================
		-- Inutile, time est récupéré avec LoGetModelTime()

		-- ============== Contrôle de l'appareil =========================================================================		
				
		-- ============== Parametres de Vol ===============================================================
		envoyerInfo(102,lMainPanel:get_argument_value(117)*1000) 	-- IAS Badin

		
		envoyerInfo(112, 50005000 + math.floor(lMainPanel:get_argument_value(179) * 1000) * 10000 + lMainPanel:get_argument_value(180) * 1000)
		-- Alti Baro deux aiguilles

		envoyerInfo(120,lMainPanel:get_argument_value(443)*1000) 	-- Alti Radar valeur non linéaire
		
		envoyerInfo(130,lMainPanel:get_argument_value(134)*1000) 	-- Vario (-30m/s , +30 m/s) ... valeur non linéaire à ajuster dans html
		
		envoyerInfo(140,lMainPanel:get_argument_value(143)* -1000)	-- Pitch (ADI)
		envoyerInfo(142,lMainPanel:get_argument_value(142)*1000)	-- Bank ou Roll (ADI)
		
		
		--envoyerInfo(150,lMainPanel:get_argument_value(11)*1000)	-- Boussole
		
		local EUP_S = math.floor(lMainPanel:get_argument_value(132)*1000)	-- EUP_Speed
		local EUP_SS = math.floor(lMainPanel:get_argument_value(133)*1000)	-- EUP_Sideslip
		local EUP = 50005000 + EUP_S * 10000 + EUP_SS
		envoyerInfo(180,EUP)	-- EUP_Data

		-- Donnée Altiradar

		local Altirad1 = math.floor((lMainPanel:get_argument_value(468)+ 0.02) *10)
		local Altirad2 = math.floor((lMainPanel:get_argument_value(469)+ 0.02) *10)
		local Altirad3 = math.floor((lMainPanel:get_argument_value(470)+ 0.02) *10)
		local Altirad4 = math.floor((lMainPanel:get_argument_value(471)+ 0.02) *10)
		envoyerInfo(122,(500000000 + Altirad1 * 1000000 + Altirad2 * 10000 + Altirad3 * 100 + Altirad4))	
		
		-- ============== Parametres  ==============================================================

		-- ============== Parametres HSI ==================================================================
		
		envoyerInfo(152,lMainPanel:get_argument_value(165)*3600) -- CAP (Export 0.1 degrés)
		envoyerInfo(154,lMainPanel:get_argument_value(160)*3600) -- Course (Ecart par rapport à la couronne des caps)
		envoyerInfo(156,lMainPanel:get_argument_value(159)*3600) -- Waypoint (Ecart par rapport à la couronne des caps)
				
		-- ============== Parametres ILS ==================================================================
		
		-- ============== Parametres Rotor =================================================================
		
		envoyerInfo(230,lMainPanel:get_argument_value(123)*1100) -- Rotor rpm : max 110
				
		-- ============== Parametres Moteur (Fast) ================================================================
		
		local RPM_L = math.floor(lMainPanel:get_argument_value(122)*1100)		-- rpm left : max 110
		local RPM_R = 0	-- rpm right : unused on UH1
		envoyerInfo(202,50005000 + RPM_L * 10000 + RPM_R)									-- Groupage RPM L et R dans une donnée
		
		
		local EngT_L =	math.floor(lMainPanel:get_argument_value(121)*1000)		-- temp left : max 1000
		local EngT_R = 0	-- temp right : unused on UH1 
		envoyerInfo(204,50005000 + EngT_L * 10000 + EngT_R)									-- Groupage Température L et R dans une donnée
		
							
		
		-- ============== Parametres Turbine Torque/Rpm/Exhaust ===================================================================
		
		local Torque = math.floor(lMainPanel:get_argument_value(124)*1000)
		local Gas = math.floor(lMainPanel:get_argument_value(119)*1000)

		envoyerInfo(240,50005000 + Torque * 10000 + Gas)
		envoyerInfo(242,50005000 + lMainPanel:get_argument_value(121)*1000) -- Exhaust Temperature

		-- ============== Position de l'Avion ===============================================================		
		
end	

function Envoi_Data_SIOC_slow()
	    -- Export lent entre 500ms et une seconde
		--logCom ("time de la boucle 2 - Slow")
		--logCom(CurrentTime)
		
		-- Attention !!!!!!!! pour boucle lente, le nom est différent que boucle rapide : Device(0) >> MainPanel
		local MainPanel = GetDevice(0)
		-- Test de la précence de Device 0 , comme table  valide
		if type(MainPanel) ~= "table" then
			return ""
		end
		MainPanel:update_arguments()
		
		-- ============== Valeur Test ============================================================		
		
		-- ============== Horloge de Mission ============================================================		
		
		envoyerInfo(42,LoGetModelTime())-- Heure de la mission
		
		-- ============== Parametres de Vol (lents) ====================================================

		-- ADI
		local ADI_FF = math.floor(MainPanel:get_argument_value(148))		-- ADI Failure Flag
		local ADI_IDX = MainPanel:get_argument_value(138)*1000	-- ADI Index
		envoyerInfo(146,50005000 + 10000 * ADI_FF + ADI_IDX)	
		
		-- Altitude Radar , Index Low et High
		local Altirad_HDX = math.floor(MainPanel:get_argument_value(466) * 1000) -- Index High Setting
		local Altirad_LDX = MainPanel:get_argument_value(444) * 1000 -- Index Low Setting
		envoyerInfo(124,50005000 + 10000 * Altirad_HDX + Altirad_LDX)

		-- Alarme Low et High , Flag on/off
		local Altirad_HF = math.floor(MainPanel:get_argument_value(465)+0.2) -- Alti Rad high alti Alarme
		local Altirad_LF = math.floor(MainPanel:get_argument_value(447)+0.2) -- Alti Rad low alti Alarme
		local Altirad_O = MainPanel:get_argument_value(467) -- Alti Rad Off Flag
		envoyerInfo(126,555 + Altirad_HF * 100 + Altirad_LF * 10 + Altirad_O)
		
		
		-- ============== Parametres Moteur (lents) ====================================================
		
		local Oil_P_1 = math.floor(MainPanel:get_argument_value(113)*1000)	-- Oil Pressure : non linéaire export cadran
		local Oil_P_2 = 0	-- Non utilisé sur UH-1 un seul moteur
		local Oil_PGB_1 = math.floor(MainPanel:get_argument_value(115)*1000)	-- Oil Pressure Gear Box		
		
		local Oil_T_1 = math.floor(MainPanel:get_argument_value(114)*1000)	-- Oil Temp left : non linéaire export cadran
		local Oil_T_2 = 0  -- Non utilisé sur UH-1 un seul moteur	
		local Oil_TGB_1 = math.floor(MainPanel:get_argument_value(116) * 1000)	-- Oil Temp Gear Box : non linéaire export cadran

		envoyerInfo(260,50005000 + 10000 * Oil_P_1 + Oil_P_2)		-- Engine Oil Pressure (L,R)
		envoyerInfo(265,50005000 + Oil_PGB_1)						-- GearBox Oil Pressure
		envoyerInfo(250,50005000 + 10000 * Oil_T_1 + Oil_T_2)		-- Engine Oil Temp (L,R)
		envoyerInfo(255,50005000 + Oil_TGB_1)						-- GearBox Oil Temp 	

	
		-- ============== Switch Moteur Engine Panel ==============================================
		
		local EngStart =  MainPanel:get_argument_value(213)
		local Trim = MainPanel:get_argument_value(89)	-- Force Trim		
		local Hyd = MainPanel:get_argument_value(90) 	-- HYD CONT
		
		local RmpLow = MainPanel:get_argument_value(80)  	-- Low Rpm
		local Fuel = MainPanel:get_argument_value(81)  	-- Fuel On/Off
		local Gov =  MainPanel:get_argument_value(85)  	-- Gov On/Off
		local Ice =  MainPanel:get_argument_value(84)	-- De-Ice
		
		envoyerInfo(270,5555555 + Ice * 1000000 + Gov * 100000 + Fuel *  10000 + RmpLow * 1000  + Hyd * 100 + Trim * 10  + EngStart)

		-- ============== Parametres Fuel (lents)  =======================================================
		
		local Fuel_qty = MainPanel:get_argument_value(239)* 1000  -- valeur non linéaire à ajuster	
		local Fuel_sel = math.floor(MainPanel:get_argument_value(126)* 1000)	-- Fuel Pressure sur UH-1
		envoyerInfo(404,50005000 + Fuel_sel*10000 + Fuel_qty) -- Utilisation du canal Fuel Internal Forward
			
		-- ============== Parametres Electrique  ===========================================================
		
		-- Regroupement des Position Switches AC et DC sur une valeur (Canal switch DC de SIOC)
				
		local Elec_S1 = MainPanel:get_argument_value(219)		-- Position Switch Batterie 
		local Elec_S2 = MainPanel:get_argument_value(220)		-- Stby Gen	
		local Elec_S3 = MainPanel:get_argument_value(221)		-- Non Essential Bus
		local Elec_S4 = math.floor(MainPanel:get_argument_value(218)*10+0.2)		-- DC Voltmetre
		local Elec_S5 = 0 -- Non utilisé sur UH-1
		local Elec_S6 = math.floor(MainPanel:get_argument_value(214)*10+0.2)		-- AC Voltmetre
		local Elec_S7 = MainPanel:get_argument_value(215)		-- Inverter
		local Elec_S8 = MainPanel:get_argument_value(238)		-- Pitot

		local Elec_SW_DC = 55050555 + Elec_S8 * 10000000 + Elec_S7 * 1000000 + Elec_S6 * 100000 + Elec_S5 * 10000 + Elec_S4 * 1000 + Elec_S3 * 100 + Elec_S2 * 10 + Elec_S1
		envoyerInfo(504,Elec_SW_DC)								-- Position Switch DC
			
		
		-- Voyants --------------------------------------------------------------
		-- Regroupement des Position Switches AC et DC sur une valeur (Canal Voyant AC de SIOC)

		local Elec_V6 = MainPanel:get_argument_value(107)		-- Voyant Gen1
		local Elec_V7 = 0
		local Elec_V8 = MainPanel:get_argument_value(108)		-- Voyant Ground AC
		local Elec_V9 = MainPanel:get_argument_value(106)		-- Voyant Hacheur DCAC PO500

		envoyerInfo(516,5555 + Elec_V9 * 1000 + Elec_V8 * 100 + Elec_V7 * 10 + Elec_V6) -- Voyant Electric AC
		
		-- Voltage AC et DC --------------------------------------------------------------
		local VoltAC = math.floor(MainPanel:get_argument_value(150)*1000)		-- Voltage AC
		local VoltDC = MainPanel:get_argument_value(149)*1000		-- Voltage DC
		envoyerInfo(510,50005000 + VoltAC * 10000 + VoltDC) 
			 

		-- ============== Status Eléments Mécaniques ======================================================== WIP : a mettre à jour pour Mi-8
		--local DoorL = math.floor(MainPanel:get_argument_value(420)*10) -- Porte Cockpit , Left0 fermée , 1 ouverte	
		--local DoorR = math.floor(MainPanel:get_argument_value(422)*10) -- Porte Cockpit , Right0 fermée , 1 ouverte
		--envoyerInfo(602,55 + DoorL * 10 + DoorR) -- Positions Portes

		-- ============== Données de Navigation ===============================================================	
			
		
		-- ============== Status Armement ==================================================================

		local WPN_8 = math.floor(MainPanel:get_argument_value(252)) -- Switch Masterarm
		local WPN_8a = math.floor(MainPanel:get_argument_value(254)+0.5) -- Lamp Masterarm Armed
		local WPN_8b = math.floor(MainPanel:get_argument_value(255)+0.5) -- Lamp Masterarm Safe
		local WPN_9 = math.floor(MainPanel:get_argument_value(253)) -- Switch Gun Select L-R-All
		local WPN_10 = math.floor(MainPanel:get_argument_value(256)) -- Switch 40-275-762
		local WPN_11 = math.floor(MainPanel:get_argument_value(257)*10+0.2) -- Selecteur 7 Posit Rocket Pair
		envoyerInfo(1020,555550 + WPN_8 * 100000 + WPN_8a * 10000 + WPN_8b * 1000 + WPN_9 * 100 + WPN_10 * 10 + WPN_11)

		
		-- ============== Status Flare ==================================================================
		
		local FLR_5 = math.floor(MainPanel:get_argument_value(456)) -- Safe Arm Flare
		local FLR_5B = math.floor(MainPanel:get_argument_value(458)+0.5) -- Armed Lamp
		local FLR_nb = math.floor(MainPanel:get_argument_value(460)*10+ 0.2 ) * 10 + math.floor(MainPanel:get_argument_value(461)*10) 	-- Flare Number
		
		-- Chaff Non modelisées dans DCS
		--local FLR_9 = math.floor(MainPanel:get_argument_value(459)) -- Man Prgm
		-- local FLR_chaf = math.floor(MainPanel:get_argument_value(462)*10) * 10 + math.floor(MainPanel:get_argument_value(463)*10) 	-- Chaff Number
		
		envoyerInfo(1025,5500 + FLR_5 * 1000 + FLR_5B * 100 + FLR_nb)		-- Position Switch, Lamp, et nb flare
		-- envoyerInfo(1027,50005000 + FLR_nb * 10000 + FLR_chaf)		
					
		-- ============== Module Alarme ==================================================================================	
		local Alrm_Fire = math.floor(MainPanel:get_argument_value(275)) -- Alarme Fire
		local Alrm_Rpm = math.floor(MainPanel:get_argument_value(276)) -- Alarme Low RPM
		local Alrm_MW = math.floor(MainPanel:get_argument_value(277)) -- Alarme MAster Warning
		local V_Start = math.floor(MainPanel:get_argument_value(213)) -- Engine Start
		envoyerInfo(574,5555 + Alrm_Fire * 1000 + Alrm_Rpm * 100 + Alrm_MW * 10 + V_Start)
		
		
		
		-- ============== Miaou the end ==================================================================================			
				
end
	


---- *************************************************************************** Main Program ********************************************************************	
----------------------------------------------------------------------------------------------------------------------------------
-- 	Séquenceur de tâche												  --
----------------------------------------------------------------------------------------------------------------------------------


DEBUG_MODE = true; 	-- activation du log -------------------------------------------
Sioc_OK = true
Data_Buffer = {}

--- *** Connexion à SIOC *** -------------------------------------------------------
logCom("Connexion à SIOC, ouverture Socket")
package.path  = package.path..";.\\LuaSocket\\?.lua"
package.cpath = package.cpath..";.\\LuaSocket\\?.dll"
socket = require("socket")
	
	
--- *** Gestion des erreurs de connection à SIOC *** --------------------------------
--- Test ajouté pour résoudre le problème de plantage DCS, si SIOC pas demarré
	if pcall(Sioc_connect) then
		logCom("SIOC Connection OK")
		Sioc_OK = true
		
	else
		logCom("SIOC Connection problème, pas de SIOC")
		Sioc_OK = false
	end

StartTime = LoGetMissionStartTime()
CurrentTime = LoGetModelTime()

--- *************** TIMING DES DEUX BOUCLES ****************************************************************************
SamplingPeriod_1 = 0.1 -- Interval de séquence rapide en secondes (défaut 200 millisecondes)
SamplingPeriod_2 = 0.5   -- Interval de séquence lente en secondes (défaut 1 seconde)
--- *************** TIMING DES DEUX BOUCLES ****************************************************************************



-- *** Initialisation des déclencheurs rapides et lents *** -------------------------
NextSampleTime_1 = CurrentTime + SamplingPeriod_1
NextSampleTime_2 = CurrentTime + SamplingPeriod_2

KTZ_DATA =
{
-- Fonction au démarrage mission -----------------------------------------------------------------


	KD_Start=function(self)
				
		logCom("  ","\n")
		logCom("*** Fonction KD_Start ***","\n")
		logCom(string.format(" Mission Start Time = %.0f",StartTime,"\n"))	
		logCom(string.format(" Sampling Period 1 = %.1f secondes",NextSampleTime_1,"\n"))
		logCom(string.format(" Sampling Period 2 = %.1f secondes",NextSampleTime_2,"\n"))
		
		-- local name = LoGetPilotName()
		--logCom(name)
		logCom("  ","\n")
		
		if Sioc_OK then
			logCom("*** SIOC OK ***","\n")
			-- Envoi à SIOC de l'heure de début de mission
			envoyerInfo(41,LoGetMissionStartTime())
			-- envoyerInfo(6,LoGetPlayerPlaneId())
			
		else
		
			logCom("*** SIOC Probleme ***","\n")
			
		end
				
	end,

-- Fonction avant chaque image ---------------------------------------------------------------------
	KD_BeforeNextFrame=function(self)
		-- logCom(string.format("*** Fonction KD_BeforeNextFrame @= %.2f",CurrentTime,"\n"))
		-- Option Réception des ordres de SIOC à chaque image (défaut dans la séquence lente)
		-- Reception_SIOC_Cmd()
	end,
	
-- Fonction après chaque image ---------------------------------------------------------------------
	KD_AfterNextFrame=function(self)
		-- Récupération du Time Code, utilisé par le séquenceur pour test et déclancher les séquences rapides et lentes
		CurrentTime = LoGetModelTime()
	end,

-- Fonction à chaque intervalle de temps type 1 -----------------------------------------------------
-- Séquence rapide : défaut 200 millisecondes
	KD_AtInterval_1=function(self)
				
		-- logCom(string.format("*** Fonction KD_AtInterval_1 @= %.2f",CurrentTime,"\n"))
		-- calcul de la date de fin du prochain intervalle de temps
		NextSampleTime_1 = CurrentTime + SamplingPeriod_1
	
		
		if Sioc_OK then
			-- Fonction d'envoi des données à SIOC (liste rapide)
			Envoi_Data_SIOC_fast()
		
			-- Option Réception des ordres de SIOC séquence rapide
			Reception_SIOC_Cmd()
		
		end
	
	end,

-- Fonction à chaque intervalle de temps type 2 --------------------------------------------------------
-- Séquence lente : défaut 1 seconde
	KD_AtInterval_2=function(self)
				
		-- logCom(string.format("*** Fonction KD_AtInterval_2 @= %.2f",CurrentTime,"\n"))
		-- calcul de la date de fin du prochain intervalle de temps
		NextSampleTime_2 = CurrentTime + SamplingPeriod_2
	
		
		if Sioc_OK then
			-- Fonction d'envoi des données à SIOC (liste lente)
			Envoi_Data_SIOC_slow()
		end	
		
		-- Option Réception des ordres de SIOC séquence lente
		-- Reception_SIOC_Cmd()
				
	end,	
	
-- Fonction fin de mission -----------------------------------------------------------------------------
	KD_Stop=function(self)
	
	-- Par défaut, Rien ... possibilité d'imprimer un rapport de mission avec LogCom ... à développer
	-- logCom(messageInit)
	logCom("*** Fonction KD_Stop ***")
	logCom("  ","\n")
		
	-- log des résultats
	logCom(string.format(" Flight Duration = %.0f secondes",CurrentTime,"\n"))
	logCom("  ","\n")
	logCom("  ","\n")
	logCom("Miaou à tous !!!")
		
	end,
		
}


-- Declencheur de séquence (depuis export.lua)
----------------------------------------------------------------------------------------------------------------------------------------------------
--    Séquence : Démarrage de mission (ExportStart)    			  **********************************************************************************
----------------------------------------------------------------------------------------------------------------------------------------------------

do
	local PrevLuaExportStart=LuaExportStart;

	LuaExportStart=function()
		KTZ_DATA:KD_Start();
		
		if PrevLuaExportStart then
			PrevLuaExportStart();
		end
	end
end

------------------------------------------------------------------------
--    Séquence : avant chaque image            							  --
------------------------------------------------------------------------
-- Rien par défaut

do
	local PrevLuaExportBeforeNextFrame=LuaExportBeforeNextFrame;

	LuaExportBeforeNextFrame=function()
		-- Non actif par défaut 
		-- KTZ_DATA:KD_BeforeNextFrame();
						
		if PrevLuaExportBeforeNextFrame then
			PrevLuaExportBeforeNextFrame();
		end
	end
end

------------------------------------------------------------------------
--    Séquence : après chaque image            						  --
------------------------------------------------------------------------
-- On compare le time code avec les compteurs de déclenchement

do
	local PrevLuaExportAfterNextFrame=LuaExportAfterNextFrame;

	LuaExportAfterNextFrame=function()
		KTZ_DATA:KD_AfterNextFrame();
			if CurrentTime >= NextSampleTime_1 then
				KTZ_DATA:KD_AtInterval_1();  -- Déclencheur séquence rapide
			end
			if CurrentTime >= NextSampleTime_2 then
				KTZ_DATA:KD_AtInterval_2();  -- Déclencheur séquence lente
			end
			
		if PrevLuaExportAfterNextFrame then
			PrevLuaExportAfterNextFrame();
		end
	end
end


------------------------------------------------------------------------
--    Séquence : Fin de mission (ExportStop)         				  --
------------------------------------------------------------------------

do
	local PrevLuaExportStop=LuaExportStop;

	LuaExportStop=function()
		KTZ_DATA:KD_Stop();

		if PrevLuaExportStop then
			PrevLuaExportStop();
		end
	end
end