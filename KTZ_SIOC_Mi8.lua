--[[
**************************************************************************
*     Module d'Export de données pour SIOC, et le KaTZ-Pit               *
*     Par KaTZe     -         http://www.3rd-wing.net                    *
*     Version v5.008            du   14/01/2015  pour le Mi8              *
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
-- Fichier Type "KTZ-SIOC5008_ComLog-yyyymmjj-hhmm.csv"
-- Info. envoyés par la fonction logCom()

------------------------------------------------------------------------
--    Fonction logCom , logging d'évènements dans un fichier .csv			  --******************************************************************
------------------------------------------------------------------------
function logCom(message)

	-- Création du fichier de log des communication serveur, s'il n'existe pas
	-- Format , KTZ-SIOC5008_ComLog-yyyymmdd-hhmm.csv
	--
	if DEBUG_MODE and not fichierComLog then
       	fichierComLog = io.open(lfs.writedir().."Export\\KTZ-Mi-SIOC5008_ComLog-"..os.date("%Y%m%d-%H%M")..".csv", "w");
				
		-- Ecriture de l'entète dans le fichier
		if fichierComLog then
			
			fichierComLog:write("*********************************************;\n");
			fichierComLog:write("*     Fichier Log des Communications SIOC   *;\n");
			fichierComLog:write("*     Par KaTZe  -  http://www.3rd-wing.net *;\n");
			fichierComLog:write("*     Version 5.0.08 du 14/01/2015          *;\n");
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
				-- P = Pas du rotateur (reserve , pas encore utilise)
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
						-- Type interrupteur deux voies, val = val * 1000
						-- Envoi à LockOn, commande Device, Bouton + 3000 , Argument
						GetDevice(device):performClickableAction(3000+bouton,val)
						
					end
					
					-----------------------------------------------------------------
					-- Type 2 : Simple On/Off avec Capot sur KA50 ... inutilisé sur Mi-8
					-- La séquence capot/bouton/capot est créé en 3 commandes successives par javascript
					if typbouton == 2 then
						-- Type interrupteur deux voies, avec capot , val = val * 1000
						-- On ouvre, bascule, ferme
						GetDevice(device):performClickableAction(3000+bouton+1,val*1000)
						GetDevice(device):performClickableAction(3000+bouton,val*1000)
						GetDevice(device):performClickableAction(3000+bouton+1,val*1000)
						
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
						-- Type interrupteur press bouton , val = val * 1000
						-- On envoie 1000 puis zero
						GetDevice(device):performClickableAction(3000+bouton,val*1000)
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
	    -- Export à la 200ms
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
		
		-- ============== Clock =========================================================================
		-- Inutile, time est récupéré avec LoGetModelTime()

		-- ============== Contrôle de l'appareil =========================================================================		
		--envoyerInfo(123,MainPanel:get_argument_value(191) * 1000)-- Position Collectif , WIP pour Gilles : a mettre à jour pour Mi-8
		envoyerInfo(22,lMainPanel:get_argument_value(859)*1000)
		
		
		-- ============== Parametres de Vol ===============================================================
		envoyerInfo(102,lMainPanel:get_argument_value(24)*1000) 	-- IAS max speed 350km/hr ... valeur non linéaire à ajuster dans html

		envoyerInfo(112,lMainPanel:get_argument_value(19)*10000) 	-- Alti Baro 0-1000m
		envoyerInfo(120,lMainPanel:get_argument_value(34)*1000) 	-- Alti Radar valeur non linéaire
		
		envoyerInfo(130,lMainPanel:get_argument_value(16)*1000) 	-- Vario (-30m/s , +30 m/s) ... valeur non linéaire à ajuster dans html
		
		envoyerInfo(140,lMainPanel:get_argument_value(12)* -1000)	-- Pitch (ADI)
		envoyerInfo(142,lMainPanel:get_argument_value(13)*1000)	-- Bank ou Roll (ADI)
		
		
		--envoyerInfo(150,lMainPanel:get_argument_value(11)*1000)	-- Boussole
		
		local EUP_S = math.floor(lMainPanel:get_argument_value(22)*1000)	-- EUP_Speed
		local EUP_SS = math.floor(lMainPanel:get_argument_value(23)*1000)	-- EUP_Sideslip
		local EUP = 50005000 + EUP_S * 10000 + EUP_SS
		envoyerInfo(180,EUP)	-- EUP_Data
		
		-- ============== Parametres  ==============================================================
		

		-- ============== Parametres HSI ==================================================================
		
		
		envoyerInfo(152,lMainPanel:get_argument_value(25)*3600) -- CAP (Export 0.1 degrés)
		envoyerInfo(154,lMainPanel:get_argument_value(27)*3600) -- Course (Ecart par rapport à la couronne des caps)
		envoyerInfo(156,lMainPanel:get_argument_value(28)*3600) -- Waypoint (Ecart par rapport à la couronne des caps)
		
				
		-- ============== Parametres ILS ==================================================================
		
		-- ============== Parametres Rotor =================================================================
		
		envoyerInfo(230,lMainPanel:get_argument_value(42)*1100) -- Rotor rpm : max 110
		envoyerInfo(232,lMainPanel:get_argument_value(36)*1000) -- Rotor pitch : gradué de 1° à 15° ( * 14 +1) ... valeur non linéaire à ajuster dans html	
				
				
		-- ============== Parametres Moteur (Fast) ================================================================
		local RPM_L = math.floor(lMainPanel:get_argument_value(40)*1100)		-- rpm left : max 110
		local RPM_R = math.floor(lMainPanel:get_argument_value(41)*1100)		-- rpm right : max 110
		local RPM_data = 50005000 + RPM_L * 10000 + RPM_R
		envoyerInfo(202,RPM_data)									-- Groupage RPM L et R dans une donnée
		
		
		local EngT_L =	math.floor(lMainPanel:get_argument_value(43)*1200)		-- temp left : max 120
		local EngT_R = math.floor(lMainPanel:get_argument_value(45)*1200)		-- temp right : max 120
		local EngT = 50005000 + EngT_L * 10000 + EngT_R
		envoyerInfo(204,EngT)									-- Groupage Température L et R dans une donnée
		
		
		envoyerInfo(210,lMainPanel:get_argument_value(39)*100)		    -- mode moteur Index : gradué de 1 à 10	
		envoyerInfo(212,lMainPanel:get_argument_value(37)*50 + 50)		-- mode moteur Gauche : gradué de 5 à 10 ( * 5 +5)	
		envoyerInfo(213,lMainPanel:get_argument_value(38)*50 + 50)		-- mode moteur Droit : gradué de 5 à 10 ( * 5 +5) 
		-- Variables non groupées pour les simpit
				
		
		-- ============== Parametres APU ===================================================================
		local APU_T = math.floor(lMainPanel:get_argument_value(402) * 1000 )		-- Température APU
		local APU_P = math.floor(lMainPanel:get_argument_value(403)	* 1000 )		-- Pression Air comprimé de l'APU 
		local APU_data = 50005000 + APU_P * 10000 + APU_T				-- +50005000 pour gérer 0 et valeurs négatives
		
		envoyerInfo(300,APU_data)	-- Groupage Pression + Température dans une donnée

		-- ============== Position de l'Avion ===============================================================		
		
		
		-- ============== Données de Navigation ===============================================================		
		
		
		-- ============== Parametre Drift Indicator  =======================================================		
		-- Drift and Ground indicator
		
		local D_A = math.floor(lMainPanel:get_argument_value(791) * 1000 )  -- Diss15 Drift Angle
								
		local DS_C = lMainPanel:get_argument_value(792) * 10 -- Diss15 Speed x00
		local DS_D = lMainPanel:get_argument_value(793) * 10 -- Diss15 Speed 0x0
		local DS_U = lMainPanel:get_argument_value(794) * 10 -- Diss15 Speed 00x
		
		local Drift_Data = 50005000 + D_A * 10000 + math.floor(DS_C) * 100 + math.floor(DS_D) * 10 + math.floor(DS_U)
		envoyerInfo(682,Drift_Data) 
		
		
		-- Sling indicator		
		
		local Sling_UD = lMainPanel:get_argument_value(828)*1000	-- Up-Down	
		local Sling_LR = lMainPanel:get_argument_value(829)*1000	-- Left Right	
		local Sling_FB = lMainPanel:get_argument_value(830)*1000	-- Forward Back	
		local Sling_Off = lMainPanel:get_argument_value(831) + 0.3	-- Voyant Off (+0.3 pour arrondi à 1)	
		
		local Sling_3D = 50005000 + 10000 * math.floor(Sling_Off) + Sling_UD  	-- groupage vario et on/off
		local Sling_2D = 50005000 + 10000 * math.floor(Sling_FB) + Sling_LR					-- groupage avant/arriere et gauche/droite
		
		envoyerInfo(692,Sling_3D) 
		envoyerInfo(694,Sling_2D) 
		
		
end	

function Envoi_Data_SIOC_slow()
	    -- Export à la seconde
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
		--envoyerInfo(22,MainPanel:get_argument_value(277)*1000)		-- K : Fuel Qty Switch		
	
		-- ============== Horloge de Mission ============================================================		
		envoyerInfo(42,LoGetModelTime())-- Heure de la mission
		
		
		-- ============== Parametres de Vol (lents) ====================================================

		-- ADI
		local ADI_FF = math.floor(MainPanel:get_argument_value(14))		-- ADI Failure Flag
		local ADI_IDX = MainPanel:get_argument_value(820)*1000	-- ADI Index
		local ADI_FI = 50005000 + 10000 * ADI_FF + ADI_IDX
		envoyerInfo(146,ADI_FI)	
		
		-- ALTIRAD : Low Index Setting sur Canal "Altirad_DX"
		envoyerInfo(124,50005000 + MainPanel:get_argument_value(31) * 1000) 
		
		-- Alarme Low et High , Flag on/off
		local Altirad_HF = 0 -- Alti Rad high alti Alarme (pas utilisé sur Mi-8)
		local Altirad_LF = math.floor(MainPanel:get_argument_value(30)+0.2) -- Alti Rad low alti Alarme
		local Altirad_O = MainPanel:get_argument_value(35) -- Alti Rad On Button
		envoyerInfo(126,555 + Altirad_HF * 100 + Altirad_LF * 10 + Altirad_O)
		
				
		
		-- ============== Parametres Moteur (lents) ====================================================
		
		local Oil_P_1 = math.floor(MainPanel:get_argument_value(115)*80)	-- Oil Pressure left gradué 0-8 kg/cm²
		local Oil_P_2 = math.floor(MainPanel:get_argument_value(117)*80)	-- Oil Pressure right
		local Oil_P_Eng = 50005000 + 10000 * Oil_P_1 + Oil_P_2

		local Oil_PGB_1 = math.floor(MainPanel:get_argument_value(111)*80)	-- Oil Pressure Gear Box
		local Oil_P_GB = 50005000 + Oil_PGB_1		
		

		local Oil_T_1 = math.floor((MainPanel:get_argument_value(116)+0.25) * 200 -50)	-- Oil Temp left : gradué de -50 à 150 (sortie -0.25 + .75)	
		local Oil_T_2 = math.floor((MainPanel:get_argument_value(118)+0.25) * 200 -50)	-- Oil Temp left : gradué de -50 à 150 (sortie -0.25 + .75)	
		local Oil_T_Eng = 50005000 + 10000 * Oil_T_1 + Oil_T_2

		local Oil_TGB_1 = math.floor((MainPanel:get_argument_value(114)+0.25) * 200 -50)	-- Oil Temp Gear Box : gradué de -5 à 15 ( * 200 - 50)	
		local Oil_T_GB = 50005000 + Oil_TGB_1


		envoyerInfo(260,Oil_P_Eng)		-- Engine Oil Pressure (L,R)
		envoyerInfo(265,Oil_P_GB)		-- GearBox Oil Pressure
		envoyerInfo(250,Oil_T_Eng)		-- Engine Oil Temp (L,R)
		envoyerInfo(255,Oil_T_GB)		-- GearBox Oil Temp 	

    
		
		-- Pilototo -------------------------------------------------------------------------------- WIP : a mettre à jour pour Mi-8
				
		
		-- Moteur APU -----------------------------------------------------------------------------------------------------
		-- NEW --- V006 --- Les données boléennes de voyants ou d'interrupteur sont groupées dans un seul export
		-- Export nombre à 8 chiffres (type : 87654321), chaque position reprend la valeur d'un élément
		-- (0,1 pour les boléens, ou -1,0,1 pour les switches 3 voies, ou 0,1,2,,,9 pour les rotateurs
		-- on ajoute +5 a chaque veleur pour gérer 0 et valeurs négatives
		-- le nombre est décodé dans javascript pour le KaTZ-Pit ou dans SIOC pour les simpit

		-- ============== Démarrage APU ==============================================

		local APU_V1 = MainPanel:get_argument_value(414)	-- Voyant APU Ignition
		local APU_V2 = MainPanel:get_argument_value(416)	-- Voyant APU Oil Pressure
		local APU_V3 = MainPanel:get_argument_value(417)	-- Voyant APU RPM OK
		local APU_V4 = MainPanel:get_argument_value(418)	-- APU RPM high
		local APU_V = 5555 + APU_V4 * 1000 + APU_V3 * 100 + APU_V2 * 10 + APU_V1
		envoyerInfo(310,APU_V)								-- Chaine Codage Voyants APU (5+A,5+B,5+C,5+D)

		envoyerInfo(315,MainPanel:get_argument_value(412) * 1000)-- APU Type demarrage  (=Start, 1000=Vent, 2000=Crabo)
		
	
		-- ============== Démarrage Moteur ==============================================
		local COL = MainPanel:get_argument_value(204)
		local COR = MainPanel:get_argument_value(206)
		local BRot = MainPanel:get_argument_value(208)
		local CO = 555 + BRot * 100 + COL * 10 + COR

		envoyerInfo(220,CO)	-- Rotor Break + Levier CutOff Left Right

		local Eng_Start_V = 55 + MainPanel:get_argument_value(420) * 10 + MainPanel:get_argument_value(424)
		envoyerInfo(352,Eng_Start_V)-- Voyant Ignition et Start Engine
				
		envoyerInfo(356,MainPanel:get_argument_value(422) * 1000)-- Selecteur demarrage moteur (zero=APU, 1000=Left, 2000=Right, 3000=Up maintenance)
		envoyerInfo(358,MainPanel:get_argument_value(423) * 1000)-- Type demarrage  (=Start, 1000=Vent, 2000=Crabo)


		-- ============== Parametres Fuel (lents)  =======================================================
		local Fuel_qty = MainPanel:get_argument_value(62)* 1000  -- valeur non linéaire à ajuster	
		local Fuel_sel = math.floor(MainPanel:get_argument_value(61) * 10 + 0.2) -- +0.2 pour arrondi selecteur
		local Fuel_data = 50005000 + Fuel_sel*10000 + Fuel_qty
		envoyerInfo(404,Fuel_data) -- Utilisation du canal Fuel Internal Forward

		local Fuel_V1 = MainPanel:get_argument_value(431)	-- Voyant Cross Feed Vanne
		local Fuel_V2 = MainPanel:get_argument_value(427)	-- Voyant Vanne Gauche
		local Fuel_V3 = MainPanel:get_argument_value(429)	-- Voyant Vanne Droit
		local Fuel_V = 555 + Fuel_V1 * 100 + Fuel_V2 * 10 + Fuel_V3
		envoyerInfo(430,Fuel_V)	

		local Fuel_P1 = MainPanel:get_argument_value(441)	-- Voyant Pump Service
		local Fuel_P2 = MainPanel:get_argument_value(442)	-- Voyant Pump Gauche
		local Fuel_P3 = MainPanel:get_argument_value(443)	-- Voyant Pump Droit
		local Fuel_P = 555 + Fuel_P1 * 100 + Fuel_P2 * 10 + Fuel_P3
		envoyerInfo(435,Fuel_P)			
				
			
		-- ============== Parametres Electrique  ===========================================================
		-- Panel DC --------------------------------------------------------------
		-- Regroupement des Voyants AC et DC dans deux valeurs export à 8 chiffres	
		local Elec_V1 = MainPanel:get_argument_value(504)		-- Voyant Rec1
		local Elec_V2 = MainPanel:get_argument_value(505)		-- Voyant Rec2
		local Elec_V3 = MainPanel:get_argument_value(506)		-- Voyant Rec3
		local Elec_V4 = MainPanel:get_argument_value(507)		-- Voyant Ground DC
		local Elec_V5 = MainPanel:get_argument_value(508)		-- Voyant Test APU-Rec
				
		local Elec_VDC = 55555 + Elec_V5 * 10000 + Elec_V4 * 1000 + Elec_V3 * 100 + Elec_V2 * 10 + Elec_V1
				
		
		-- Regroupement des Position Switches AC et DC dans deux valeurs export à 8 chiffres
		-- Valeur codée sur +5 = zero , pour gérer facilemet les valeurs négatives
		-- et les zero non significatifs (décallage position)
		
		local Elec_S1 = MainPanel:get_argument_value(495)		-- Position Switch Batterie L
		local Elec_S2 = MainPanel:get_argument_value(496)		-- Position Switch Batterie R
		local Elec_S3 = MainPanel:get_argument_value(497)		-- Stby Gen ex APU	
		local Elec_S4 = MainPanel:get_argument_value(499)		-- Position Switch Rectifier 1
		local Elec_S5 = MainPanel:get_argument_value(500)		-- Position Switch Rectifier 2
		local Elec_S6 = MainPanel:get_argument_value(501)		-- Position Switch Rectifier 3
		local Elec_S7 = MainPanel:get_argument_value(502)		-- Position Switch Ground DC
		local Elec_S8 = MainPanel:get_argument_value(503)		-- Rec ex APU	

		local Elec_SW_DC = 55555555 + Elec_S8 * 10000000 + Elec_S7 * 1000000 + Elec_S6 * 100000 + Elec_S5 * 10000 + Elec_S4 * 1000 + Elec_S3 * 100 + Elec_S2 * 10 + Elec_S1
		
		-- envoyerInfo(502,MainPanel:get_argument_value(494) * 1000)-- Position Selecteur Voltmetre DC
		envoyerInfo(504,Elec_SW_DC)								-- Position Switch DC
		envoyerInfo(506,Elec_VDC)								-- Voyant Electric DC
		
		
		-- Panel AC --------------------------------------------------------------

		local Elec_V6 = MainPanel:get_argument_value(543)		-- Voyant Gen1
		local Elec_V7 = MainPanel:get_argument_value(544)		-- Voyant Gen2
		local Elec_V8 = MainPanel:get_argument_value(545)		-- Voyant Ground AC
		local Elec_V9 = MainPanel:get_argument_value(546)		-- Voyant Hacheur DCAC PO500

		local Elec_VAC = 5555 + Elec_V9 * 1000 + Elec_V8 * 100 + Elec_V7 * 10 + Elec_V6		
		
		local EleAc_S1 = MainPanel:get_argument_value(538)		-- Position Switch Generatrice LH
		local EleAc_S2 = MainPanel:get_argument_value(539)		-- Position Switch Generatrice RH
		local EleAc_S3 = MainPanel:get_argument_value(540)		-- Position Switch Ground AC
		local EleAc_S4 = MainPanel:get_argument_value(541)		-- Position Switch Hacheur DCAC 115V
		local EleAc_S5 = MainPanel:get_argument_value(542)		-- Position Switch Hacheur DCAC 36V
		
		local Elec_SW_AC = 55555 + EleAc_S5 * 10000 + EleAc_S4 * 1000 + EleAc_S3 * 100 + EleAc_S2 * 10 + EleAc_S1
		
				
		-- envoyerInfo(512,MainPanel:get_argument_value(535) * 1000)-- Position Selecteur Voltmetre AC
		envoyerInfo(514,Elec_SW_AC)								-- Position Switch AC
		envoyerInfo(516,Elec_VAC)								-- Voyant Electric AC
		
		--envoyerInfo(530,MainPanel:get_argument_value(539) * 1000)-- Stby Gen Load
		 
		

		-- ============== Status Eléments Mécaniques ======================================================== WIP : a mettre à jour pour Mi-8
		envoyerInfo(602,MainPanel:get_argument_value(215))-- Porte Cockpit , 0 fermée , 100 ouverte	
		envoyerInfo(620,MainPanel:get_argument_value(881)*1000)-- Wheel brake
		--envoyerInfo(208,MainPanel:get_argument_value(473)*1000)-- brake pressure
		

		-- ============== Données de Navigation ===============================================================	
		-- Doppler Diss15
		
		local DA_100 = math.floor(MainPanel:get_argument_value(799) * 10) -- Diss15 Drift Angle KM
		local DA_10 = math.floor(MainPanel:get_argument_value(800) * 10)
		local DA_1 = math.floor(MainPanel:get_argument_value(801) * 100)
		local DA_F = MainPanel:get_argument_value(802)
		
		local FP_100 = math.floor(MainPanel:get_argument_value(806) * 10) -- Diss15 Flight Path KM
		local FP_10 = math.floor(MainPanel:get_argument_value(807) * 10) 
		local FP_1 = math.floor(MainPanel:get_argument_value(808) * 100) 
		local FP_F = MainPanel:get_argument_value(805)
		
		local MA_100 = math.floor(MainPanel:get_argument_value(811) * 10) -- Diss15 Map Angle
		local MA_10 = math.floor(MainPanel:get_argument_value(812) * 10) 
		local MA_1 = math.floor(MainPanel:get_argument_value(813) * 10 + 0.5) 
		local MA_01 = math.floor(MainPanel:get_argument_value(814) * 60) -- export en minute d'angle
		
		local Dop_On = MainPanel:get_argument_value(817)

		local Doppler_data1 = 50005000 + FP_100 * 10000000 + FP_10 * 1000000 + FP_1 * 10000 + DA_100 * 1000 + DA_10 * 100 + DA_1 
		local Doppler_data2 = 50005000 + MA_100 * 10000000 + MA_10 * 1000000 + MA_1 * 100000 + MA_01
		local Doppler_flag = Dop_On + DA_F *10 + FP_F * 100 + 555
		
		envoyerInfo(672,Doppler_data1)
		envoyerInfo(674,Doppler_data2)
		envoyerInfo(676,Doppler_flag)
				
		-- ============== Parametre Diss15  =======================================================		
		-- Drift and Ground indicator
		local DS_V1 = MainPanel:get_argument_value(796)  	-- Voyant Memory
		local DS_V2 = MainPanel:get_argument_value(795)	-- Shutter de l'indication Distance
		
		local DS_V = 55 + DS_V2 * 10 + DS_V1
		
		envoyerInfo(684,DS_V)	-- Diss15 Memory Voyant + Shutter
		
		-- ============== Parametre Ark 9  =======================================================		
		-- Drift and Ground indicator
		local ARK9_S1 = MainPanel:get_argument_value(469)		-- Selection Main-STBY
		local ARK9_S2 = MainPanel:get_argument_value(444)		-- Selection TLF-TLG
		local ARK9_S3 = math.floor(MainPanel:get_argument_value(446) * 10 + 0.3)	-- Selection OFF COMP ANT LOOP (0 à 3)
		-- ajout de 0.3 avant math.floor pour régler problèmes fréquents d'arrondi de DCS
		local ARK9_S4 = math.floor(MainPanel:get_argument_value(451) * 10 + 0.3)		-- Fine Tune MAIN (-2 à 4)
		local ARK9_S5 = math.floor(MainPanel:get_argument_value(449) * 10 + 0.3)		-- Fine Tune STBY (-2 à 4)
		
		local ARK9_S = 55555 + ARK9_S5 * 10000 + ARK9_S4 * 1000 + ARK9_S3 * 100 + ARK9_S2 * 10 + ARK9_S1
		
		envoyerInfo(662,ARK9_S)   -- Variable Switch ARK-9
		
		
		local ARK9_MF1 = math.floor(MainPanel:get_argument_value(678) * 20 + 0.3) + 1		-- Freq mHz Main
		local ARK9_MF2 = math.floor(MainPanel:get_argument_value(452) * 10 + 0.3)			-- Freq kHz Main
		-- ajout de 0.3 avant math.floor pour régler problèmes fréquents d'arrondi de DCS
		local ARK9_MF =  ARK9_MF1 * 100 + ARK9_MF2 * 10
				
		local ARK9_RF1 = math.floor(MainPanel:get_argument_value(675) * 20 + 0.3)+1		-- Freq Decimal Reserve
		local ARK9_RF2 = math.floor(MainPanel:get_argument_value(450) * 10 + 0.3)		-- Freq Decimal Reserve
		local ARK9_RF =  ARK9_RF1 * 100 + ARK9_RF2 * 10
		
		local ARK9_F =  50005000 + ARK9_RF * 10000 + ARK9_MF
		envoyerInfo(664,ARK9_F)   -- Fréquence ARK-9
		
		
		local ARK9_Signal = math.floor(MainPanel:get_argument_value(681) * 1000)
		local ARK9_Gain = math.floor(MainPanel:get_argument_value(448) * 1000)		
		local ARK9_Data = 50005000 + ARK9_Gain * 10000 + ARK9_Signal
		envoyerInfo(666,ARK9_Data)   -- Signal Reception , Réglage Gain	
		
		
		-- ============== Parametre Ark UD  =======================================================		
		-- Position Switches 
		local ARKUD_S1 = math.floor(MainPanel:get_argument_value(456) *10 + 0.2)		-- Selecteur de Mode
		local ARKUD_S2 = MainPanel:get_argument_value(453)		-- Selection sensitivity
		local ARKUD_S3 = MainPanel:get_argument_value(454)		-- Selection VHF UHF
		local ARKUD_S4 = math.floor(MainPanel:get_argument_value(457) * 10 + 0.2)		-- Selecteur de Channel ajout de 0.2 pour pb arrondi
		local ARKUD_S5 = math.floor(MainPanel:get_argument_value(455) * 9.3)		-- Bouton Volume
		local ARKUD_S6 = MainPanel:get_argument_value(458)		-- Voyant 1
		local ARKUD_S7 = MainPanel:get_argument_value(459)		-- Voyant 2
		local ARKUD_S8 = MainPanel:get_argument_value(460)		-- Voyant 3
		
				
		local ARKUD = 55500555 + ARKUD_S8 * 10000000 + ARKUD_S7 * 10000000 + ARKUD_S6 * 1000000 + ARKUD_S5 * 10000 + ARKUD_S4 * 1000 + ARKUD_S3 * 100 + ARKUD_S2 * 10 + ARKUD_S1
		
		envoyerInfo(660,ARKUD)   -- Variable Switch ARK-UD
		
		-- ============== Parametre Selection Ark9-ArkUD  =======================================================		
		-- Position Switches MW/VHF
		envoyerInfo(668,5 + math.floor(MainPanel:get_argument_value(858)+0.2)) 
		
		
		-- ============== Status Armement ==================================================================

		-- Scan du Canon sélectionné -------------------------------------------------------------------
		-- Scan du Panel Armement ----------------------------------------------------------------------		
				
				
		
		
				
		-- ============== Module Alarme ==================================================================================		
		
		
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
SamplingPeriod_1 = 0.2 -- Interval de séquence rapide en secondes (défaut 200 millisecondes)
SamplingPeriod_2 = 1   -- Interval de séquence lente en secondes (défaut 1 seconde)

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