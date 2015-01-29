--[[
**************************************************************************
*     Module d'Export de données pour SIOC, et le KaTZ-Pit               *
*     Par KaTZe     -         http://www.3rd-wing.net                    *
*     Version KA-50_v5008  du   14/01/2015  pour le KH50                 *
**************************************************************************
--]]

-- siocConfig.lua contient :
-- Script de configuration SIOC
-- Paramêtres IP : Host, Port
-- Ainsi que la plage d'Offset utilisée pour les valeurs KaTZ-Pit 
-- Si l'on veut décaler la plage rentrer une valeur (ex: 2000)

dofile ( lfs.writedir().."Scripts\\siocConfig.lua" )
local c


-- Debug Mode, si True un fichier ".csv" est créé dans le répertoire
-- Saved Games\DCS\Export
-- Fichier Type "KTZ-SIOC3000_ComLog-yyyymmjj-hhmm.csv"
-- Info. envoyés par la fonction logCom()

------------------------------------------------------------------------
--    Fonction logCom												  --
------------------------------------------------------------------------
function logCom(message)

	-- Création du fichier de log des communication serveur, s'il n'existe pas
	-- Format , KTZ-SIOC5008_ComLog-yyyymmdd-hhmm.csv
	--
	if DEBUG_MODE and not fichierComLog then
       	fichierComLog = io.open(lfs.writedir().."Export\\KTZ-KA-SIOC5008_ComLog-"..os.date("%Y%m%d-%H%M")..".csv", "w");
				
		-- Ecriture de l'entète dans le fichier
		if fichierComLog then
			
			fichierComLog:write("*********************************************;\n");
			fichierComLog:write("*     Fichier Log des Communications SIOC   *;\n");
			fichierComLog:write("*     Par KaTZe  -  http://www.3rd-wing.net *;\n");
			fichierComLog:write("*     Version 5.0.01 du 23/11/2014          *;\n");
			fichierComLog:write("*********************************************;\n\n");
		end
    end
	
	-- Ecriture des données dans le fichier existant
	if fichierComLog then
        --fichierComLog:write(string.format(" %s ; %s",os.date("%d/%m/%y %H:%M:%S"),message),"\n");
		fichierComLog:write(string.format(" %s ; %s",os.clock(),message),"\n");
	end
end


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
    
    -- Generate the init string to SIOC (to register with SIOC which parameters we are interested in)
    for lSIOC_Var,i in pairs(inputsTable)
    do
        lSIOC_SendString = lSIOC_SendString..lSIOC_Var..":"
    end
	
    -- Send the initstring
    socket.try(c:send("Arn.Inicio:"..lSIOC_SendString.."\n"))
	local messageContact = ("Arn.Inicio:"..lSIOC_SendString.."\n")
	
	messageInit = "INIT-->;" .. messageContact
	
end


   
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


------------------------------------------------------------------------
-- 	Get Data from SIOC												  --
------------------------------------------------------------------------	
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
		if typeMessage == "Arn.Resp" then
			--logData("Message type Arn.Resp-----", "\n")
			--------------------------------------------------------
			-- Type = Arn.Resp:                                   --
			--------------------------------------------------------
			
			-- extraction du message 
			-- (message type par exemple :1=3:0=23:6=3456)
			local debut,fin,message = string.find(messageRecu,"([%d:=-]+)")
			--logCom(message)
			-- longueur du message
			local longueur
			longueur = fin - debut
			--logCom(longueur)
			-- découpe du message en commande et envoi à lockon
			-- (commandes type 1=3  0=23  6=3456)
			
			-- KaTZe Modif BS2, Commande codé sur 8 caracteres , TDDBBBVV
			-- DD = Device
			-- BBB = numero du bouton
			-- T = Type de bouton
			-- VV = Valeur recu
			
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
				
				if chan ==1 and valeur > 0 then
						
					-- Envoi à LockOn, commande type Classique FC3
					LoSetCommand(valeur)
				
				end
				
				if chan ==2 and valeur > 10000 then
					typbouton = tonumber(string.sub(Svaleur,1,1))
					device = tonumber(string.sub(Svaleur,2,3))
					bouton = tonumber(string.sub(Svaleur,4,6))
					pas = tonumber(string.sub(Svaleur,7,7))
					val = tonumber(string.sub(Svaleur,8,8))
				
					--logCom(string.format(" Device = %.0f",device,"\n"))
					--logCom(string.format(" Bouton = %.0f",bouton,"\n"))
					--logCom(string.format(" Type = %.0f",typbouton,"\n"))
					--logCom(string.format(" Valeur = %.0f",val,"\n"))
					
					if typbouton == 1 then
						-- Type interrupteur deux voies, val = val * 1000
						-- Envoi à LockOn, commande Device, Bouton + 3000 , Argument
						--GetDevice(device):performClickableAction(3000+bouton,val*1000)
						GetDevice(device):performClickableAction(3000+bouton,val)
						
					end
					
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
						-- Type interrupteur press bouton , val = val * 1000
						-- On envoie 1000 puis zero
						GetDevice(device):performClickableAction(3000+bouton,val)
						GetDevice(device):performClickableAction(3000+bouton,val*0)
												
					end
				
				end
								
				lim = b + 1
			end
			
		else
			--logData("---Log: SIOC Message Incorrect ; non type Arn.Resp ; Message Ignoré -----", "\n")
		end
    end
end



------------------------------------------------------------------------
-- 	Export de LockOn												  --
------------------------------------------------------------------------
function Envoi_Data_SIOC_fast()
	    -- Export à la 200ms
		--logCom ("time de la boucle 1 - Fast")
		--logCom(CurrentTime)
		
		-- Récupération des données à lire --------------------
		local lMainPanel = GetDevice(0)
		
		--Check to see that the device is valid otherwise we return an emty string 
		if type(lMainPanel) ~= "table" then
			return ""
		end
		
		
		lMainPanel:update_arguments()
		
		-- ============== Clock =========================================================================
		-- Inutile, time est récupéré avec LoGetModelTime()
		--envoyerInfo(20,lMainPanel:get_argument_value(167)*1000)
		--envoyerInfo(21,lMainPanel:get_argument_value(48)*1000)
		--envoyerInfo(22,lMainPanel:get_argument_value(173)*1000)
		--envoyerInfo(23,lMainPanel:get_argument_value(177)*1000)
		--envoyerInfo(22,lMainPanel:get_argument_value(70)*60)
		
		-- ============== Parametres de Vol ===============================================================
		envoyerInfo(102,lMainPanel:get_argument_value(51)*370) 	-- IAS max speed 350km/hr -- linéaire export valeur vraie
		envoyerInfo(130,lMainPanel:get_argument_value(24)*300) 	-- Vario (-30m/s , +30 m/s) -- linéaire export valeur vraie
		
		envoyerInfo(112,lMainPanel:get_argument_value(87)*10000) -- Alti Baro 1000m
		envoyerInfo(120,lMainPanel:get_argument_value(94)*1000) 	-- Alti Radar valeur non linéaire export rotation aiguille
				
		
		envoyerInfo(140,lMainPanel:get_argument_value(143)*1000)	-- Pitch
		envoyerInfo(142,lMainPanel:get_argument_value(142)*1000)	-- Bank
		
		envoyerInfo(150,lMainPanel:get_argument_value(11)*1000)	-- Boussole
		
		-- ============== Parametres  ==============================================================
		

		-- ============== Parametres HSI ==================================================================
		
		
		envoyerInfo(152,lMainPanel:get_argument_value(112)*3600) -- CAP (Export 0.1 degrés)
		envoyerInfo(156,lMainPanel:get_argument_value(115)*3600) -- Waypoint (Ecart par rapport à la couronne des caps)
		envoyerInfo(154,lMainPanel:get_argument_value(118)*3600) --5 Course (Ecart par rapport à la couronne des caps)
		
		
		local WP_Dist_1 = math.floor(lMainPanel:get_argument_value(528)*10)
		local WP_Dist_10 = math.floor(lMainPanel:get_argument_value(527)*10)
		local WP_Dist_100 = math.floor(lMainPanel:get_argument_value(117)*10)
		
		envoyerInfo(162,WP_Dist_100*1000 + WP_Dist_10*100 + WP_Dist_1*10) -- Waypoint Distance 0.1km
				
		
		
		-- ============== Parametres ILS ==================================================================
		
		-- ============== Parametres Rotor =================================================================
		
		envoyerInfo(230,lMainPanel:get_argument_value(52)*110) -- Rotor rpm : max 110
		envoyerInfo(232,lMainPanel:get_argument_value(53)*140 + 10) -- Rotor pitch : gradué de 1° à 15° ( * 14 +1)	
				
				
		-- ============== Parametres Moteur (Fast) ================================================================
		local RPM_L = math.floor(lMainPanel:get_argument_value(135)*1100)		-- rpm left : max 110
		local RPM_R = math.floor(lMainPanel:get_argument_value(136)*1100)		-- rpm right : max 110
		local RPM_data = 50005000 + RPM_L * 10000 + RPM_R
		envoyerInfo(202,RPM_data)									-- Groupage RPM L et R dans une donnée
		
		
		local EngT_L =	math.floor(lMainPanel:get_argument_value(133)*1200)		-- temp left : max 120
		local EngT_R = math.floor(lMainPanel:get_argument_value(134)*1200)		-- temp right : max 120
		local EngT = 50005000 + EngT_L * 10000 + EngT_R
		envoyerInfo(204,EngT)									-- Groupage Température L et R dans une donnée
		
		
		envoyerInfo(210,lMainPanel:get_argument_value(592)*100)			-- mode moteur : index gradué de 0 à 10					
		envoyerInfo(212,lMainPanel:get_argument_value(234)*50 + 50)		-- mode moteur : gradué de 5 à 10 ( * 5 +5)	
		envoyerInfo(213,lMainPanel:get_argument_value(235)*50 + 50)		-- mode moteur : gradué de 5 à 10 ( * 5 +5)
		-- Variables non groupées pour les simpit		
		
		
		
		-- ============== Parametres APU ===================================================================
		envoyerInfo(300,50005000 + lMainPanel:get_argument_value(6) * 900)-- Température APU : max 900°

		
				
		-- ============== Position de l'Avion ===============================================================	

		


		--envoyerInfo(569,lMainPanel:get_argument_value(82)*1000)		--  : RAlt Danger				
		
		
		-- ============== Données de Navigation ===============================================================		
		


		-- ============== Parametre TWS -- En développement =======================================================		
		


		
end	

function Envoi_Data_SIOC_slow()
	     -- Export à la seconde
		--logCom ("time de la boucle 2 - Slow")
		--logCom(CurrentTime)
		
		-- Récupération des données à lire --------------------
		local MainPanel = GetDevice(0)
		
		--Check to see that the device is valid otherwise we return an emty string 
		if type(MainPanel) ~= "table" then
			return ""
		end
		
				
		-- ============== Valeur Test ============================================================		
		envoyerInfo(22,MainPanel:get_argument_value(277)*1000)		-- K : Fuel Qty Switch		
		envoyerInfo(23,MainPanel:get_argument_value(191) * 1000)-- Position Collectif
	
		-- ============== Horloge de Mission ============================================================		
		envoyerInfo(42,LoGetModelTime())-- Heure de la mission
		
		
		-- ============== Parametres Moteur (lents) ====================================================

		local Oil_P_1 = math.floor(MainPanel:get_argument_value(252)*80)	-- Oil Pressure left gradué 0-8 kg/cm²
		local Oil_P_2 = math.floor(MainPanel:get_argument_value(253)*80)	-- Oil Pressure right
		local Oil_P_Eng = 50005000 + 10000 * Oil_P_1 + Oil_P_2

		local Oil_PGB_1 = math.floor(MainPanel:get_argument_value(254)*80)	-- Oil Pressure Gear Box
		local Oil_P_GB = 50005000 + Oil_PGB_1		
		

		local Oil_T_1 = math.floor(MainPanel:get_argument_value(255) * 240 - 60)	-- Oil Temp left : gradué de -6 à 18
		local Oil_T_2 = math.floor(MainPanel:get_argument_value(256) * 240 - 60)	-- Oil Temp left : gradué de -6 à 18
		local Oil_T_Eng = 50005000 + 10000 * Oil_T_1 + Oil_T_2

		local Oil_TGB_1 = math.floor(MainPanel:get_argument_value(257) * 200 -50)	-- Oil Temp Gear Box : gradué de -5 à 15 ( * 200 - 50)	
		local Oil_T_GB = 50005000 + Oil_TGB_1


		envoyerInfo(260,Oil_P_Eng)		-- Engine Oil Pressure (L,R)
		envoyerInfo(265,Oil_P_GB)		-- GearBox Oil Pressure
		envoyerInfo(250,Oil_T_Eng)		-- Engine Oil Temp (L,R)
		envoyerInfo(255,Oil_T_GB)		-- GearBox Oil Temp 	

		
				
		-- ============== Parametres Fuel (lents) et démarrage ==============================================
		envoyerInfo(404,MainPanel:get_argument_value(137)* 800)-- Fuel Internal Forward : max 80		-- OK
		envoyerInfo(406,MainPanel:get_argument_value(138)* 800)-- Fuel Internal Aft : max 80			-- OK

		local APU_V1 = MainPanel:get_argument_value(162)	-- Voyant APU Valve Open
		local APU_V2 = MainPanel:get_argument_value(168)	-- Voyant APU Oil Pressure
		local APU_V3 = MainPanel:get_argument_value(174)	-- Voyant APU On
		local APU_V4 = MainPanel:get_argument_value(169)	-- APU RPM high
		local APU_V = 5555 + APU_V4 * 1000 + APU_V3 * 100 + APU_V2 * 10 + APU_V1
		envoyerInfo(310,APU_V)								-- Chaine Codage Voyants APU (5+A,5+B,5+C,5+D)
		
		local Fuel_V1 = MainPanel:get_argument_value(211)	-- Voyant Cross Feed Vanne
		local Fuel_V2 = MainPanel:get_argument_value(209)	-- Voyant Vanne Gauche
		local Fuel_V3 = MainPanel:get_argument_value(210)	-- Voyant Vanne Droit
		local Fuel_V = 555 + Fuel_V1 * 100 + Fuel_V2 * 10 + Fuel_V3
		envoyerInfo(430,Fuel_V)	


		--local Fuel_P1 = MainPanel:get_argument_value(441)	-- Voyant Pump Service
		local Fuel_P2 = MainPanel:get_argument_value(200)	-- Voyant Pump Av
		local Fuel_P3 = MainPanel:get_argument_value(201)	-- Voyant Pump Ar
		local Fuel_P = 555 + Fuel_P2 * 10 + Fuel_P3
		envoyerInfo(435,Fuel_P)		

		local Fuel_PE1 = MainPanel:get_argument_value(185)	-- Voyant Pump EL
		local Fuel_PE2 = MainPanel:get_argument_value(202)	-- Voyant Pump IL
		local Fuel_PE3 = MainPanel:get_argument_value(203)	-- Voyant Pump IR
		local Fuel_PE4 = MainPanel:get_argument_value(186)	-- Voyant Pump ER
		local Fuel_PE = 5555 + Fuel_PE1 * 1000 + Fuel_PE2 * 100 + Fuel_PE3 * 10 + Fuel_PE4
		envoyerInfo(440,Fuel_PE)		

		local Eng_Start_V = 5 + MainPanel:get_argument_value(163)  -- Voyant Start Valve
		envoyerInfo(352,Eng_Start_V)-- Voyant Ignition (Mi8) et Start Engine


		local COL = MainPanel:get_argument_value(554)
		local COR = MainPanel:get_argument_value(555)
		local BRot = MainPanel:get_argument_value(556)
		local CO = 555 + BRot * 100 + COL * 10 + COR
		envoyerInfo(220,CO)	-- Rotor Break + Levier CutOff Left Right

		
		envoyerInfo(356,MainPanel:get_argument_value(416) * 10000)-- Selecteur demarrage moteur (zero=APU, 1000=Left, 2000=Right, 3000=Up maintenance)
		envoyerInfo(358,MainPanel:get_argument_value(415) * 10000)-- Type demarrage  (=Start, 1000=Vent, 2000=Crabo)
				

		
		-- ============== Parametres Electrique  ===========================================================
		-- Panel DC --------------------------------------------------------------
		-- Regroupement des Voyants AC et DC dans deux valeurs export à 8 chiffres	
		
		local Elec_S1 = MainPanel:get_argument_value(264)		-- Position Switch Batterie L
		local Elec_S2 = MainPanel:get_argument_value(543)		-- Position Switch Batterie R
		--envoyerInfo(80,MainPanel:get_argument_value(264) * 1000)-- Position Switch Batterie L
		--envoyerInfo(81,MainPanel:get_argument_value(543) * 1000)-- Position Switch Batterie R
		local Elec_S7 = MainPanel:get_argument_value(262)		-- Position Switch Ground DC
		--envoyerInfo(82,MainPanel:get_argument_value(262) * 1000)-- Position Switch Ground DC
		
		local Elec_V4 = MainPanel:get_argument_value(261)		-- Voyant Ground DC
		--envoyerInfo(83,MainPanel:get_argument_value(261) * 1000)-- Voyant Ground DC
		
		-- Panel AC --------------------------------------------------------------

		
		local EleAc_S3 = MainPanel:get_argument_value(267)		-- Position Switch Ground AC
		local Elec_V8 = MainPanel:get_argument_value(586)		-- Voyant Ground AC
		
		
		local EleAc_S4 = MainPanel:get_argument_value(270)		-- Position Switch Hacheur DCAC 115V
		local Elec_V9 = MainPanel:get_argument_value(212)		-- Voyant Hacheur DCAC PO500
		
		
		local EleAc_S1 = MainPanel:get_argument_value(268)		-- Position Switch Generatrice LH
		local EleAc_S2 = MainPanel:get_argument_value(269)		-- Position Switch Generatrice RH

		local Elec_V10 = MainPanel:get_argument_value(290)		-- EEG Left
		local Elec_V11 = MainPanel:get_argument_value(292)		-- EEH Right
		

		local Elec_VDC = 55555 + Elec_V4 * 1000
		local Elec_SW_DC = 55555555 + Elec_S7 * 1000000 + Elec_S2 * 10 + Elec_S1		
		local Elec_VAC = 555555 + Elec_V11 * 100000 + Elec_V10 * 10000 + Elec_V9 * 1000 + Elec_V8 * 100 
		local Elec_SW_AC = 55555 + EleAc_S4 * 1000 + EleAc_S3 * 100 + EleAc_S2 * 10 + EleAc_S1
		envoyerInfo(504,Elec_SW_DC)								-- Position Switch DC
		envoyerInfo(506,Elec_VDC)								-- Voyant Electric DC
		envoyerInfo(514,Elec_SW_AC)								-- Position Switch AC
		envoyerInfo(516,Elec_VAC)								-- Voyant Electric AC
		
		
		
		-- ============== Status Eléments Mécaniques ========================================================
		envoyerInfo(602,MainPanel:get_argument_value(533)*100)-- Porte Cockpit , 0 fermée , 100 ouverte	
		envoyerInfo(620,MainPanel:get_argument_value(571)*1000)-- Wheel brake
		envoyerInfo(622,MainPanel:get_argument_value(473)*1000)-- brake pressure
		

		local Train_1 = MainPanel:get_argument_value(63)-- Train AV Up
		local Train_2 = MainPanel:get_argument_value(59)-- Train L Up
		local Train_3 = MainPanel:get_argument_value(61)-- Train R Up
		local Train_4 = MainPanel:get_argument_value(64)-- Train AV Dwn
		local Train_5 = MainPanel:get_argument_value(60)-- Train L Dwn
		local Train_6 = MainPanel:get_argument_value(62)-- Train R Dwn
		
				
		local Train = 555555 + Train_1 * 100000 + Train_2 * 10000 + Train_3 * 1000 + Train_4 * 100 + Train_5 * 10 + Train_6 
		envoyerInfo(604,Train)

		-- ============== Status Armement ==================================================================

		local TGT_1 = MainPanel:get_argument_value(437)	-- Voyant Autoturn
		local TGT_2 = MainPanel:get_argument_value(438)	-- Voyant TGT Air
		local TGT_3 = MainPanel:get_argument_value(440)	-- Voyant TGT Mov
		local TGT_4 = MainPanel:get_argument_value(439)	-- Voyant TGT For
		local TGT_5 = MainPanel:get_argument_value(441)	-- Voyant TGT Clear	
		local TGT = 55555 + TGT_1 + 10000 + TGT_2 + 1000 + TGT_3 + 100 + TGT_4 + 10 +TGT_5
		envoyerInfo(1018,TGT)
		
		-- =============== DataLink ======================================================
		local Datalink_T1 = MainPanel:get_argument_value(21)*10-- Target1
		local Datalink_T2 = MainPanel:get_argument_value(22)*10-- Target2
		local Datalink_T3 = MainPanel:get_argument_value(23)*10-- Target3
		local Datalink_T4 = MainPanel:get_argument_value(50)*10-- Target4
		local Datalink_W1 = MainPanel:get_argument_value(17)*10-- Wing1
		local Datalink_W2 = MainPanel:get_argument_value(18)*10-- Wing2
		local Datalink_W3 = MainPanel:get_argument_value(19)*10-- Wing3
		local Datalink_W4 = MainPanel:get_argument_value(20)*10-- Wing4
		local Datalink_W5 = MainPanel:get_argument_value(16)*10-- All
		local Datalink_V = MainPanel:get_argument_value(15)*10-- Vierge
		local Datalink_C = MainPanel:get_argument_value(161)*10-- Clear
		local Datalink_I = MainPanel:get_argument_value(150)*10-- Ingress
		local Datalink_S = MainPanel:get_argument_value(159)*10-- SendMem

		local Datalink_L1 = 5555 + Datalink_T1 * 1000 + Datalink_T2 * 100 + Datalink_T3 * 10 + Datalink_T4
		local Datalink_L2 = 55555 + Datalink_W1 * 10000 + Datalink_W2 * 1000 + Datalink_W3 * 100 + Datalink_W4 * 10 + Datalink_W5
		local Datalink_L3 = 5555 + Datalink_V * 1000 + Datalink_C * 100 + Datalink_I * 10 + Datalink_S
		envoyerInfo(1002,Datalink_L1)
		envoyerInfo(1004,Datalink_L2)
		envoyerInfo(1005,Datalink_L3)

		
		
		-- Scan du Canon sélectionné ------------------------------------------------------------------------
		
		-- Pilototo --------------------------------------------------------------------------------
		local AP_B = math.floor(MainPanel:get_argument_value(330)*10)		-- K : Bank
		local AP_P = math.floor(MainPanel:get_argument_value(331)*10)		-- T : Pitch
		local AP_H = math.floor(MainPanel:get_argument_value(332)*10)		-- H : HDG
		local AP_A = math.floor(MainPanel:get_argument_value(333)*10)		-- B : Alt
		local AP_FD = math.floor(MainPanel:get_argument_value(334)*10)		--  : FD

		local AP = 55555 + AP_B * 10000 + AP_P * 1000 + AP_H * 100 + AP_A * 10 + AP_FD
		envoyerInfo(552,AP)

		
		local AP2_H = MainPanel:get_argument_value(175)		--  : Hover
		local AP2_D = MainPanel:get_argument_value(172)		--  : Descente		
		local AP2 = 55 + AP2_D * 10 + AP2_H 
		envoyerInfo(554,AP2)
		
		
		
		-- Scan du Panel Armement ----------------------------------------------------------------------
		local Wpn_S1 = MainPanel:get_argument_value(388)-- Select W1
		local Wpn_S2 = MainPanel:get_argument_value(389)-- Select W2
		local Wpn_S3 = MainPanel:get_argument_value(390)-- Select W3
		local Wpn_S4 = MainPanel:get_argument_value(391)-- Select W4
		local Wpn_P1 = MainPanel:get_argument_value(392)-- Presence W1
		local Wpn_P2 = MainPanel:get_argument_value(393)-- Presence W2
		local Wpn_P3 = MainPanel:get_argument_value(394)-- Presence W3
		local Wpn_P4 = MainPanel:get_argument_value(395)-- Presence W4
		local Wpn = 55555555 + Wpn_S1 * 10000000 + Wpn_S2 * 1000000 + Wpn_S3 * 100000 + Wpn_S4 * 10000 + Wpn_P1 * 1000 + Wpn_P2 * 100 + Wpn_P3 * 10 + Wpn_P4
		envoyerInfo(1015,Wpn)
		
		-- Export des voyants Master Arm et Canon ----------------------------------------------------------------------
		envoyerInfo(1016,55 + MainPanel:get_argument_value(177)*10 + MainPanel:get_argument_value(167))
		
		
		
		-- ============== Module de Navigation =========================================================================		
		-- Module de Navigation
		
		-- ============== Module Alarme ==================================================================================		
		
		
end



---- *************************************************************************** Main Program ********************************************************************	
------------------------------------------------------------------------
-- 	Séquenceur de tâche												  --
------------------------------------------------------------------------


DEBUG_MODE = true; 	-- activation du log -------------------------------
Sioc_OK = true
Data_Buffer = {}

--- *** Connexion à SIOC *** -------------------------------------------------------
logCom("Connexion à SIOC, ouverture Socket")
package.path  = package.path..";.\\LuaSocket\\?.lua"
package.cpath = package.cpath..";.\\LuaSocket\\?.dll"
socket = require("socket")
	
	
--- *** Gestion des erreurs de connection à SIOC *** --------------------------------
	if pcall(Sioc_connect) then
		logCom("SIOC Connection OK")
		Sioc_OK = true
		
	else
		logCom("SIOC Connection problème, pas de SIOC")
		Sioc_OK = false
	end


--- logCom("LogetMissionStartTime")	
StartTime = LoGetMissionStartTime()
CurrentTime = LoGetModelTime()
SamplingPeriod_1 = 0.1 -- Interval de séquence rapide en secondes (défaut 200 millisecondes)
SamplingPeriod_2 = 0.5   -- Interval de séquence lente en secondes (défaut 1 seconde)

-- *** Initialisation des déclencheurs rapides et lents *** -------------------------
NextSampleTime_1 = CurrentTime + SamplingPeriod_1
NextSampleTime_2 = CurrentTime + SamplingPeriod_2

--logCom("Séquenceur")

KTZ_DATA =
{
-- Fonction au démarrage mission


	KD_Start=function(self)
		
		
		
		logCom("  ","\n")
		logCom("*** Fonction KD_Start ***","\n")
		logCom(string.format(" Mission Start Time = %.0f",StartTime,"\n"))	
		logCom(string.format(" Sampling Period 1 = %.1f secondes",NextSampleTime_1,"\n"))
		logCom(string.format(" Sampling Period 2 = %.1f secondes",NextSampleTime_2,"\n"))
		
		
		logCom("  ","\n")
		
		if Sioc_OK then
			logCom("*** SIOC OK ***","\n")
			-- Envoi à SIOC de l'heure de début de mission
			envoyerInfo(41,LoGetMissionStartTime())
			
			local MyHeloId = LoGetSelfData()
			
			if type(MyHeloId) ~= "table" then
				logCom ("*** Ben !!! ...  LoGetSelfData() çà merde encore ***")
				
				else
				logCom ("*** Plane ID 2 ***",MyHeloId.Name)
						
			end
						
			
		else
		
			logCom("*** SIOC Probleme ***","\n")
			
		end
		
		
		
		
			
		
	end,

-- Fonction avant chaque image	
	KD_BeforeNextFrame=function(self)
		-- logCom(string.format("*** Fonction KD_BeforeNextFrame @= %.2f",CurrentTime,"\n"))
		-- Option Réception des ordres de SIOC à chaque image (défaut dans la séquence lente)
		-- Reception_SIOC_Cmd()
	end,
	
-- Fonction après chaque image
	KD_AfterNextFrame=function(self)
		-- Récupération du Time Code, utilisé par le séquenceur pour test et déclancher les séquences rapides et lentes
		CurrentTime = LoGetModelTime()
	end,

-- Fonction à chaque intervalle de temps type 1
-- Séquence rapide : défaut 200 millisecondes
	KD_AtInterval_1=function(self)
				
		-- logCom(string.format("*** Fonction KD_AtInterval_1 @= %.2f",CurrentTime,"\n"))
		-- calcul de la date de fin du prochain intervalle de temps
		NextSampleTime_1 = CurrentTime + SamplingPeriod_1
	
		
		if Sioc_OK then
			-- Fonction d'envoi des données à SIOC (liste fast)
			Envoi_Data_SIOC_fast()
		
			-- Option Réception des ordres de SIOC séquence rapide (par défaut dans la séquence lente)
			Reception_SIOC_Cmd()
		
		end
	
	end,

-- Fonction à chaque intervalle de temps type 2
-- Séquence lente : défaut 1 seconde
	KD_AtInterval_2=function(self)
				
		-- logCom(string.format("*** Fonction KD_AtInterval_2 @= %.2f",CurrentTime,"\n"))
		-- calcul de la date de fin du prochain intervalle de temps
		NextSampleTime_2 = CurrentTime + SamplingPeriod_2
	
		
		if Sioc_OK then
			-- Fonction d'envoi des données à SIOC (liste lente)
			Envoi_Data_SIOC_slow()
		end	
		
		-- Réception des ordres de SIOC séquence lente (par défaut)
		-- Reception_SIOC_Cmd()
				
	end,	
	
-- Fonction fin de mission
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
------------------------------------------------------------------------
--    Séquence : Démarrage de mission (ExportStart)    			  --
------------------------------------------------------------------------

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