--[[
**************************************************************************
*     Module d'Export de donn�es pour SIOC, et le KaTZ-Pit               *
*     Par KaTZe     -         http://www.3rd-wing.net                    *
*     Version 3.0.16  du   02/11/2014                                     *
**************************************************************************
--]]

-- siocConfig.lua contient :
-- Script de configuration SIOC
-- Param�tres IP : Host, Port
-- Ainsi que la plage d'Offset utilis�e pour les valeurs KaTZ-Pit 
-- Si l'on veut d�caler la plage rentrer une valeur (ex: 2000)

dofile ( lfs.writedir().."Scripts\\siocConfig.lua" )
local c


-- Debug Mode, si True un fichier ".csv" est cr�� dans le r�pertoire
-- Saved Games\DCS\Export
-- Fichier Type "KTZ-SIOC3000_ComLog-yyyymmjj-hhmm.csv"
-- Info. envoy�s par la fonction logCom()

------------------------------------------------------------------------
--    Fonction logCom												  --
------------------------------------------------------------------------
function logCom(message)

	-- Cr�ation du fichier de log des communication serveur, s'il n'existe pas
	-- Format , KTZ-SIOC3000_ComLog-yyyymmdd-hhmm.csv
	--
	if DEBUG_MODE and not fichierComLog then
       	fichierComLog = io.open(lfs.writedir().."Logs\\KatzePit\\KTZ-SIOC3000_ComLog-"..os.date("%Y%m%d-%H%M")..".csv", "w");
				
		-- Ecriture de l'ent�te dans le fichier
		if fichierComLog then
			
			fichierComLog:write("*********************************************;\n");
			fichierComLog:write("*     Fichier Log des Communications SIOC   *;\n");
			fichierComLog:write("*     Par KaTZe  -  http://www.3rd-wing.net *;\n");
			fichierComLog:write("*     Version FC3  du 02/02/2015            *;\n");
			fichierComLog:write("*********************************************;\n\n");
		end
    end
	
	-- Ecriture des donn�es dans le fichier existant
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
-- 	Offset de SIOC qui seront �cout�s								  --
-- 	0001 = Commande g�n�rale										  --
-- 	0002 = Commande sp�ciale										  --
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


		-- D�calage des exports vers une plage SIOC
		-- Indiquer dans siocConfig.lua la plage d�sir�e
		newAtt = tonumber(strAttribut) + siocConfig.plageSioc
		local strNew = tostring(newAtt)
		
		local strValeur = string.format("%d",valeur);
		
		if (strValeur ~= Data_Buffer[strNew]) then
			-- On stock la nouvelle valeur dans la table buffer
			Data_Buffer[strNew] = strValeur ;
			-- Envoi de la nouvelle valeur
			socket.try(c:send(string.format("Arn.Resp:%s=%.0f:\n",strNew,strValeur)))
			local messageEnvoye = "OUT--> ;" .. (string.format("Arn.Resp:%s=%.0f:",strNew,strValeur))
			-- Log du message envoy�
			logCom(messageEnvoye)
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
		logCom(messagelog)
		
		local s,l,typeMessage = string.find(messageRecu,"(Arn.%w+)");
		typeMessage = tostring(typeMessage);
        
		------------------------------------------------------------
		-- Les types de message accept�s :                        --
		--                                                        --
		-- Arn.Vivo   : Le serveur � re�u "Arn.Vivo": du client   -- implementation � tester
		--              Le serveur r�pond "Arn.Vivo"              --
		--														  --
		-- Arn.Resp   : Message pour l'execution des commandes    -- r�ponse de SIOC
		--              seul deux valeurs sont accept�es:         --
		--				0=[valeur] -> le param�tres valeur(      )--
		-- 				1=[valeur] -> le param�tre commande		  --
		--				Ex:Arn.Resp:0=5000:1=3: ou Arn.Resp:1=145:--
		--              a noter que Arn.Resp:1=0: remets le       --
		--              cache valeur � 'nil' aussi apr�s chaque   --
		--				commande ex�cut�                          --
		------------------------------------------------------------
		if typeMessage == "Arn.Resp" then
			--logData("Message type Arn.Resp-----", "\n")
			--------------------------------------------------------
			-- Type = Arn.Resp:                                   --
			--------------------------------------------------------
			
			-- extraction du message 
			-- (message type par exemple :1=3:0=23:6=3456)
			local debut,fin,message = string.find(messageRecu,"([%d:=-]+)")
			--logData(message)
			-- longueur du message
			local longueur
			longueur = fin - debut
			-- logData(longueur)
			-- d�coupe du message en commande et envoi � lockon
			-- (commandes type 1=3  0=23  6=3456)
			
			local commande,Schan,chan,Svaleur,valeur,i,a,b,c,d,e,f,lim
			lim = 0

			while lim < longueur do
				a,b,commande = string.find(message,"([%d=-]+)", lim)
				--logData(commande)
				c,d,Schan = string.find(commande, "([%d-]+)")
				chan = tonumber(Schan)
				--logData(string.format(" Offset = %.0f",chan,"\n"))
				e,f,Svaleur = string.find(commande, "([%d-]+)",d+1)
				valeur = tonumber(Svaleur)
				--logData(string.format(" Valeur = %.0f",valeur,"\n"))
				
				if chan ==1 and valeur > 0 then
						
					-- Envoi � LockOn
					LoSetCommand(valeur)
				
				end
								
				lim = b + 1
			end
			
		else
			--logData("---Log: SIOC Message Incorrect ; non type Arn.Resp ; Message Ignor� -----", "\n")
		end
    end
end



------------------------------------------------------------------------
-- 	Export de LockOn												  --
------------------------------------------------------------------------
function Envoi_Data_SIOC_fast()
	    -- Export � la 200ms
		logCom ("time de la boucle 1 - Fast")
		logCom(CurrentTime)
		
		-- ============== Parametres de Vol ===============================================================
		envoyerInfo(102,LoGetIndicatedAirSpeed() * 3.6 )-- m/sec converti en km/hr
		envoyerInfo(104,LoGetTrueAirSpeed() * 3.6)--m/sec
		envoyerInfo(106,LoGetMachNumber()*100)-- mach * 100
		
		envoyerInfo(112,LoGetAltitudeAboveSeaLevel()) -- Modif DCS FC3, export en m�tres
		envoyerInfo(120,LoGetAltitudeAboveGroundLevel()) -- Modif DCS FC3, export en m�tres
		envoyerInfo(130,LoGetVerticalVelocity()) -- m/sec
		
		
		-- ============== Parametres Attitude ==============================================================
		envoyerInfo(136,LoGetAngleOfAttack() * 573)	-- Export converti en 0.1 degr�s
				
		-- Calcul de l'acc�l�ration, vecteur total G = Vx + Vy + Vz
		_Acceleration = LoGetAccelerationUnits()
		local Gmeter = _Acceleration.y / math.abs(_Acceleration.y) * math.sqrt(math.pow(_Acceleration.x,2)+math.pow(_Acceleration.y,2)+math.pow(_Acceleration.z,2))
		envoyerInfo(134,Gmeter*100) -- Export en x * G
		
		-- Table Pitch , Bank , Yaw
		pitch,bank,yaw = LoGetADIPitchBankYaw()
		envoyerInfo(140,pitch * 573) -- Export converti en 0.1 degr�s
		envoyerInfo(142,bank * 573) -- Export converti en 0.1 degr�s
		envoyerInfo(144,yaw * 573) -- Export converti en 0.1 degr�s
		
		--envoyerInfo(131,LoGetMagneticYaw()*576) -- Indicateur virage
		envoyerInfo(132,LoGetSlipBallPosition()*100) -- Bille

		-- ============== Parametres HSI ==================================================================
		_ControlPanel_HSI = LoGetControlPanel_HSI()
		envoyerInfo(152,_ControlPanel_HSI.HeadingPointer * 573) -- CAP Export converti en 0.1 degr�s)
		envoyerInfo(156,_ControlPanel_HSI.ADF_raw * 573) -- Waypoint Export converti en 0.1 degr�s)
		envoyerInfo(154,_ControlPanel_HSI.RMI_raw * 573) -- Route Export converti en 0.1 degr�s)
		
		
		-- ============== Parametres ILS ==================================================================
		-- a regrouper dans une seule valeur 50005000
		envoyerInfo(702,LoGetGlideDeviation() * 100)  -- ILS UP/Down
		envoyerInfo(704,LoGetSideDeviation() * 100)  -- ILS Lat�ral
				
		-- ============== Parametres Moteur ================================================================
		_EngineInfo=LoGetEngineInfo()
		local rpmL = math.floor(_EngineInfo.RPM.left*10)  
		local rpmR = _EngineInfo.RPM.right*10             
		envoyerInfo(202,50005000 + rpmL * 10000 + rpmR )
		
		local EngT_L = math.floor(_EngineInfo.Temperature.left)
		local EngT_R = _EngineInfo.Temperature.right
		envoyerInfo(204,50005000 + EngT_L * 10000 + EngT_R )

				
		-- ============== Position de l'Avion ===============================================================		
		local myXCoord, myZCoord
		if LoGetPlayerPlaneId() then
			local objPlayer = LoGetObjectById(LoGetPlayerPlaneId())
			myXCoord, myZCoord = getXYCoords(objPlayer.LatLongAlt.Lat, objPlayer.LatLongAlt.Long)
			
			-- envoyerInfo("13",objPlayer.Subtype)--ok
			-- envoyerInfo("14",obj.Country)
			-- envoyerInfo("15",_Coalition[objPlayer.Coalition])
			--envoyerInfo(95,objPlayer.Type.level1*100)--ok
			--envoyerInfo(96,objPlayer.Type.level2*100)--ok
			--envoyerInfo(97,objPlayer.Type.level3*100)--ok
			--envoyerInfo(98,objPlayer.Type.level4*100)--ok
			--envoyerInfo(82,myXCoord*100)--ok
			--envoyerInfo(83,myZCoord*100)--ok
			--envoyerInfo(85,objPlayer.LatLongAlt.Lat*100)--ok
			--envoyerInfo(86,objPlayer.LatLongAlt.Long*100)--ok
			--envoyerInfo(87,objPlayer.LatLongAlt.Alt*100)--ok
			--envoyerInfo(21,objPlayer.Heading*100)--ok
		end
		
		-- ============== Donn�es de Navigation ===============================================================		
		local _Route = LoGetRoute()
		if _Route then
		
		-- Calcul de distance ay Way Point Pythagore sur deltaX, deltaZ (approximation g�om�trie plane)
		local distance = math.sqrt(math.pow(_Route.goto_point.world_point.x-myXCoord,2)+math.pow(_Route.goto_point.world_point.z-myZCoord,2))
			envoyerInfo(162,distance);
			
			-- Num�ro du Way Point, correction de -1 because d�calage avec affichage DCS
			envoyerInfo(160,_Route.goto_point.this_point_num - 1); 
			
			-- Position x du way point, sert � KaTZ-Pit pour identifier la piste s�lectionn�e en mode RTN, LDG
			envoyerInfo(706,_Route.goto_point.world_point.x*100); 
			--envoyerInfo(51,_Route.goto_point.world_point.y*100); -- inutilis�
			--envoyerInfo(52,_Route.goto_point.world_point.z*100); -- inutilis�
			--envoyerInfo(53,_Route.goto_point.speed_req) -- inutilis�
			-- envoyerInfo(54,_Route.goto_point.estimated_time) -- inutilis�
			-- envoyerInfo(51,_Route.goto_point.next_point_num)
			--envoyerInfo(56,table.getn(_Route.route)) -- inutilis�
		end	


		-- ============== Parametre TWS -- En d�veloppement =======================================================		
		_TWSInfo = LoGetTWSInfo()
		--logData("TWS Export ", "\n")	
		--logData(_TWSInfo.mode)
		
		if _TWSInfo.mode then
		--LogData("TWS Mode ", "\n")	
		--logData(string.format(" TWS Mode = %.0f",_TWSInfo.mode,"\n"))
		--logData(string.format(" TWS Emmiters = %.0f",table.getn(_TWSInfo.Emitters),"\n"))
		--local _SignalType ={scan=0,lock=1,missile_radio_guided=2,track_while_scan=3}
		end
	
		if _TWSInfo then
		--logData("TWS D�tail ", "\n")
		--for k,v in pairs(_TWSInfo.Emitters) do
		--	    local objEmitters = LoGetObjectById(v.ID)
					--logData(string.format(" Mission Time = %.0f secondes",CurrentTime,"\n"))
					--logData(string.format(" Emmiters en cours = %.0f",k,"\n"))
					-- logData(string.format(" Emmiters type = %.0f",objEmitters.Type,"\n"))
					--logData(v.SignalType)			
					--logData(string.format(" Emmiters power = %.0f",v.Power*1000,"\n"))
					--logData(string.format(" Emmiters azimuth = %.0f",v.Azimuth*1000,"\n"))
					--logData(string.format(" Emmiters priority = %.0f",v.Priority*1000,"\n"))

					--envoyerInfo(596+5*k,k)
					--envoyerInfo(597+5*k,v.Power*1000)
					--envoyerInfo(598+5*k,v.Azimuth*1000)
					--envoyerInfo(599+5*k,v.Priority*1000)
		--end
		end
					
		--[[
		local _SignalType ={scan=0,lock=0,missile_radio_guided=0,track_while_scan=0}
		local _SignalTypeValeur ={scan=0,lock=1,missile_radio_guided=2,track_while_scan=3}
		local _SignalTypeCode = 0;
		self.envoyerInfo("162",_LoGetTWSInfo.Mode) -- (0 - all|1 - lock only|2 - launch only)
		self.envoyerInfo("163",table.getn(_LoGetTWSInfo.Emitters)) --  
  		for k,v in pairs(_LoGetTWSInfo.Emitters) do
 			if self.specialInfos[3]==k then -- 10/05/2008
			    local objEmitters = LoGetObjectById(v.ID)
				local EmitterXCoord,EmitterZCoord = self.getXYCoords(objEmitters.LatLongAlt.Lat, objEmitters.LatLongAlt.Long)
				self.envoyerInfo("180",k); -- Emitter en cours
				self.envoyerInfo("164",objEmitters.Type)
				-- Objets subtype :
				--	Airplane = 1, Helicopter = 2, Moving = 8, Standing = 9, Tank = 17, SAM	= 16,
	 			--	Ship = 12, Missile = 4, Bomb = 5, Shell = 6, Rocket = 7, Airdrome = 13
				self.envoyerInfo("165",objEmitters.Subtype)
				--self.envoyerInfo("166",obj.Country)
				self.envoyerInfo("167",_Coalition[objEmitters.Coalition])
				self.envoyerInfo("168",EmitterXCoord*100)
				self.envoyerInfo("169",EmitterZCoord*100)
				self.envoyerInfo("170",objEmitters.LatLongAlt.Lat*100)
				self.envoyerInfo("171",objEmitters.LatLongAlt.Long*100)
				self.envoyerInfo("172",objEmitters.LatLongAlt.Alt*100)
				self.envoyerInfo("173",objEmitters.Heading*100)
				self.envoyerInfo("174",v.ID)
				self.envoyerInfo("175",tonumber(v.Type.level1..v.Type.level2..v.Type.level3..v.Type.level4))
				self.envoyerInfo("176",v.Power*1000)
				self.envoyerInfo("177",v.Azimuth*1000)
				self.envoyerInfo("178",v.Priority)
				self.envoyerInfo("179",_SignalType[v.SignalType])

			end
			
			if _SignalType[v.SignalType]==0 then
				_SignalType[v.SignalType] = 1;
				_SignalTypeCode = _SignalTypeCode + math.pow(2, _SignalTypeValeur[v.SignalType])
			end
		--]]




		
	end	

function Envoi_Data_SIOC_slow()
	     -- Export � la seconde
		logCom ("time de la boucle 2 - Slow")
		logCom(CurrentTime)
	
		-- ============== Horloge de Mission ============================================================		
		envoyerInfo(42,LoGetModelTime())-- Heure de la mission
		-- envoyerInfo(11,LoGetMissionStartTime())-- envoy� en d�but de mission
		
		--envoyerInfo(40,LoGetBasicAtmospherePressure())
		

		-- ============== Parametres Moteur Fuel (lents) ====================================================		
		_EngineInfo=LoGetEngineInfo()
		
		

		--envoyerInfo(43,_EngineInfo.Temperature.left)--- Export en �c
		--envoyerInfo(44,_EngineInfo.Temperature.right)--- Export en �c
		--envoyerInfo(45,_EngineInfo.HydraulicPressure.left*10)-- inutilis�
		--envoyerInfo(46,_EngineInfo.HydraulicPressure.right*10)-- inutilis�
		envoyerInfo(404,_EngineInfo.fuel_internal*100)--- Export en 0.01kg (100 UK (unit� kero) = 1 kg)
		envoyerInfo(406,_EngineInfo.fuel_external*100)--- Export en 0.01kg (100 UK = 1 kg)
		
		-- Consommation Fuel, non utilis�e, elle est mesur�e dans SIOC par Delta Fuel sur 5 secondes
		local EngC_L = math.floor(_EngineInfo.FuelConsumption.left * 6)
		local EngC_R = math.floor(_EngineInfo.FuelConsumption.right * 6)
		envoyerInfo(206,50005000 + EngC_L * 10000 + EngC_R )
		
		-- envoyerInfo(56,_EngineInfo.FuelConsumption.left*6) --conversion kg/10sec (erreur ds LO200) en kg/mn
		-- envoyerInfo(57,_EngineInfo.FuelConsumption.right*6) --conversion kg/10sec (erreur ds LO200) en kg/mn
		-- envoyerInfo(58,(_EngineInfo.FuelConsumption.left + _LoGetEngineInfo.FuelConsumption.right)*6)
		
		-- ============== Status El�ments M�caniques ========================================================		
		_MechInfo = LoGetMechInfo()
				
		-- "Truc", la valeur Check_WPS_MCP = 1 sera utilis�e pour rescanner le weapon panel et les alarmes
		-- Utilis� train sorti, et AF
		Check_WPS_MCP = _MechInfo.gear.status + _MechInfo.speedbrakes.status
		--envoyerInfo(151,_MechInfo.canopy.status) -- Commande Verri�re
		envoyerInfo(602,_MechInfo.canopy.value) -- Retour Position Verri�re
		
		envoyerInfo(604,55 + _MechInfo.gear.status * 10 + _MechInfo.gear.value) -- Commande + Retour Train

		envoyerInfo(606,55 + _MechInfo.flaps.status * 10 + _MechInfo.flaps.value)	-- Volet + retour Posit
		
		envoyerInfo(608,55 + _MechInfo.speedbrakes.status * 10 + _MechInfo.speedbrakes.value)	-- Retour position AF
		
		envoyerInfo(620,5555 + _MechInfo.parachute.status * 1000 + _MechInfo.parachute.value * 100 +  _MechInfo.wheelbrakes.status * 10 + _MechInfo.wheelbrakes.value)

		
		-- Regrouper data Mech en 555555
		-- Gear_Main = _MechInfo.gear.main -- inutilis�
		--envoyerInfo("1213",_LoGetMechInfo.gear.main.nose.rod)	-- inutilis�	
		--envoyerInfo("1214",_LoGetMechInfo.gear.main.left.rod)-- inutilis�
		--envoyerInfo("1215",_LoGetMechInfo.gear.main.right.rod)-- inutilis�
		--envoyerInfo("1215",Gear_Main.left.rod)-- inutilis�
		
		
		-- ============== Status Armement ==================================================================		
		local _PayloadInfo = LoGetPayloadInfo()		
		
		
		-- Scan du Pylone s�lectionn� ---------------------------------------------------------------------
		local pylone_selec = _PayloadInfo.CurrentStation  -- Pylone selectionn�
		local quantite_selec = 0 -- Quantit� de munition dispo. (utilis� pour d�clancher le chrono de tir de SIOC)
		
		envoyerInfo(1108,pylone_selec)
		
		if pylon_selec~= 0 then
				if _PayloadInfo.Stations[pylone_selec]~= nil then 
							
					quantite_selec = _PayloadInfo.Stations[pylone_selec].count
					envoyerInfo(1109,quantite_selec)
					
				end
		end
		
		-- Scan du Canon s�lectionn� ------------------------------------------------------------------------
		local canon = _PayloadInfo.Cannon.shells  -- Nombre de munitions canon restantes
		envoyerInfo(1105,canon)
		
		
		-- Scan du Panel Armement ----------------------------------------------------------------------
		local pylone
		local ammo
		local container
		local ammo_export
		
		local type_arme
		local type_arme_num
		local type_1
		local type_2
		local type_3
		local type_4
		local ammo_typ
		
		local quant_checksum = 0

		
		
		-- Scan des Type d'arme, conditionnel ------------------------------------------------------------------------
		-- Le Scan est d�clench� � l'arr�t verri�re ouverte, ou en vol � la sortie des AF
		-- La valeur "Check_WPS_MCP" est utilis� pour d�clancher le rescan du weapon panel
		-- A modifier lancer le scan au passage BVR, ou R2G (R-R, R-Sol)
			
		if Check_WPS_MCP == 1 then
			-- le weapon panel type a chang�, on le scan
			
			-- Reset du panel armement et du nombre de fuel tank
			WeaponInit()
			local tank_nb = 0
			
			-- Scan du panel armement et envoi � SIOC
			for pylone=1,13 do
				if _PayloadInfo.Stations[pylone]~=nil then
					type_arme = _PayloadInfo.Stations[pylone].weapon
					type_arme_num = tonumber(type_arme.level1..type_arme.level2..type_arme.level3..type_arme.level4)
					type_1 = tonumber(type_arme.level1)
					type_2 = tonumber(type_arme.level2)
					type_3 = tonumber(type_arme.level3)
					type_4 = tonumber(type_arme.level4)
					
					-- un chiffre sur 7 digits, 1:22:33:44 avec les valeurs des 4 types de la munition 
					ammo_typ = type_1 * 1000000 + type_2 * 10000 + type_3 * 100 + type_4		
					envoyerInfo(1125+pylone,ammo_typ)

					-- incr�ment du nombre de fuel tank
						if type_1 == 1 then
							tank_nb = tank_nb + 1
						end	
															
				end
			end
			envoyerInfo(1106,tank_nb)
		end
		
		-- Scan des Quantit�s et Container, syst�matique chaque seconde --------------------------------------------
		-- Possibilit� de le rendre conditionnel avec une variable checksum voir "if" ci dessous
		-- Comptage du nombre de munitions + paniers et export 
		for pylone=1,13 do
			if _PayloadInfo.Stations[pylone]~=nil then
				ammo = _PayloadInfo.Stations[pylone].count -- Lecture du nombre de munition restante
				container = _PayloadInfo.Stations[pylone].container and 1 or 0 -- Lecture et conversion en int, de la pr�sence d'un pod
				ammo_export = ammo + container * 1000 -- valeur export� = "ammo" ou "1000 + Ammo"
				-- un chiffre sur 4 digits, C:QQQ avec le container, puis la quantit� d'ammo
						
				quant_checksum = quant_checksum + ammo_export
				
				-- if quant_checksum ~= old_checksum then
				envoyerInfo(1110+pylone ,ammo_export)
				-- old_checksum = quant_checksum
				
			end	
		end
		
		quant_checksum = quant_checksum + canon
		envoyerInfo(1110,quant_checksum)
		
		-- ============== Module de Navigation =========================================================================		
		-- Module de Navigation
		local _NavigationInfo = LoGetNavigationInfo()
		if _NavigationInfo then
			
			local _strMaster = _NavigationInfo.SystemMode.master
			local _strSubmode = _NavigationInfo.SystemMode.submode
			local _strACS = _NavigationInfo.ACS.mode
			
			-- Modes de Navigation, Combat
			local _tabMaster = {
							NAV=1, BVR=2, CAC=3, LNG=6, A2G=7, OFF=9  
							}
							
			local _numMaster = _tabMaster[_strMaster]
						
			-- Modes de Navigation, Combat			
			local _tabSubmode = {
							ROUTE=11, ARRIVAL=12, LANDING=13, GUN=21, RWS=22, TWS=23, STT=24, VERTICAL_SCAN=33, BORE=34, HELMET=35, FLOOD=61, UNGUIDED=71, PINPOINT=72, ETS=73, OFF=99
							}
			local _numSubmode = _tabSubmode[_strSubmode]
			
			-- Modes de PilotAuto			
			local _tabACS = {
							FOLLOW_ROUTE=1, BARO_HOLD=2, RADIO_HOLD=3, BARO_ROLL_HOLD=4, HORIZON_HOLD=5, PITCH_BANK_HOLD=6, OFF=9
							}
			local _numACS = _tabACS[_strACS]
						
			envoyerInfo(652,_numMaster)
			envoyerInfo(654,_numSubmode)
			envoyerInfo(556,_numACS)
			-- Automanette			
			--envoyerInfo(184,_NavigationInfo.ACS.autothrust and 1 or 0)
		end

		
		-- ============== Module Alarme ==================================================================================		
		_MCP = LoGetMCPState()
		
		if _MCP then
			-- Conversion des variables Bol�enne en Nombre 0 ou 1
			envoyerInfo(580,_MCP.MasterWarning and 1 or 0);
						
			--if _MCP.MasterWarning or Check_WPS_MCP == 1 then   
			--	local REF = (_MCP.RightEngineFailure and 1 or 0);
			--	local LEF = (_MCP.LeftEngineFailure and 1 or 0);
			--	local APF = (_MCP.AutopilotFailure and 1 or 0);
			--	local ACMF = (_MCP.ECMFailure and 1 or 0);
			--	local EOSF = (_MCP.EOSFailure and 1 or 0);
			--	local RF = (_MCP.RadarFailure and 1 or 0);
			--	local GF = (_MCP.GearFailure and 1 or 0);
			--	local HF = (_MCP.HydraulicsFailure and 1 or 0);
			--	local FTD = (_MCP.FuelTankDamage and 1 or 0);
			--end
			
			--local Alarm = 555555555 + FTD * 100000000 + HF * 10000000 + GF * 1000000 + RF * 100000 + EOSF * 10000 + ACMF * 1000 + APF * 100 + LEF * 10 + REF
			
			--envoyerInfo(582,Alarm);
		 						
		end
		
		
		--[[ "LeftEngineFailure"
		"RightEngineFailure"
		"HydraulicsFailure"
		"ACSFailure"
		"AutopilotFailure"
		"AutopilotOn"
		"MasterWarning"
		"LeftTailPlaneFailure"
		"RightTailPlaneFailure"
		"LeftAileronFailure"
		"RightAileronFailure"
		"CanopyOpen"
		"CannonFailure"
		"StallSignalization"
		"LeftMainPumpFailure"
		"RightMainPumpFailure"
		"LeftWingPumpFailure"
		"RightWingPumpFailure"
		"RadarFailure"
		"EOSFailure"
		"MLWSFailure"
		"RWSFailure"
		"ECMFailure"
		"GearFailure"
		"MFDFailure"
		"HUDFailure"
		"HelmetFailure"
		"FuelTankDamage" ]]--
		
				
		
--[[  Old MPC � modifier		-- MPC State *******************************
		_LoGetMCPState = LoGetMCPState()
		local _compteur = 0
		local _MCPState = 0
		for n,v in pairs(_LoGetMCPState) do
			if (v) then
			
				_MCPState = _MCPState + math.pow(2,_compteur)
			end
			_compteur = _compteur + 1
		end
		envoyerInfo("71",_MCPState) -- Voir d�tails dans notice
]]--			
	end

	
	-- Mise � zero initiale du panel armement (CHECK , Six pylones ... autres avions ???)
function WeaponInit()
		local pylone
		--logData(" Mise � zero du panel armement")
				
		envoyerInfo(1110,0)
		envoyerInfo(1105,0)
		envoyerInfo(1106,0)
						
		for pylone=1,13 do
				envoyerInfo(1110+pylone,0)
				envoyerInfo(1125+pylone,0)
				-- envoyerInfo(140+pylone,0)
				-- envoyerInfo(155+pylone,0)
				-- envoyerInfo(170+pylone,0)
				-- envoyerInfo(185+pylone,0)
		end
end			
	
	
	------------------------------------------------------------------------
	--    Fonction pour le calcul des coordonn�es 						  --
	--	  Merci � Mnemonic                           					  --
	------------------------------------------------------------------------
	getXYCoords = function(inLatitudeDegrees, inLongitudeDegrees) -- args: 2 numbers // Return two value in order: X, Y
        local pi = 3.141592

		local zeroX = 5000000
		local zeroZ = 6600000

		local centerX = 11465000 - zeroX --circle center
		local centerZ =  6500000 - zeroZ

		local pnSxW_X = 4468608 - zeroX -- point 40dgN : 24dgE
		local pnSxW_Z = 5730893 - zeroZ

		local pnNxW_X = 5357858 - zeroX -- point 48dgN : 24dgE
		local pnNxW_Z = 5828649 - zeroZ

		local pnSxE_X = 4468608 - zeroX -- point 40dgN : 42dgE
		local pnSxE_Z = 7269106 - zeroZ

		local pnNxE_X = 5357858 - zeroX -- point 48dgN : 42dgE
		local pnNxE_Z = 7171350 - zeroZ

		local lenNorth = math.sqrt((pnNxW_X-centerX)*(pnNxW_X-centerX) + (pnNxW_Z-centerZ)*(pnNxW_Z-centerZ))
		local lenSouth = math.sqrt((pnSxW_X-centerX)*(pnSxW_X-centerX) + (pnSxW_Z-centerZ)*(pnSxW_Z-centerZ))
		local lenN_S = lenSouth - lenNorth

		local RealAngleMaxLongitude = math.atan ((pnSxW_Z - centerZ)/(pnSxW_X - centerX)) * 180/pi
		-- borders
		local EndWest = 24
		local EndEast = 42
		local EndNorth = 48
		local EndSouth = 40
		local MiddleLongitude = (EndWest + EndEast) / 2
		local ToLengthN_S = ((EndNorth - EndSouth) / lenN_S)
		local ToAngleW_E = (MiddleLongitude - EndWest) / RealAngleMaxLongitude

		local ToDegree = 360/(2*pi)
	    -- Lo coordinates system
	    local realAng = (inLongitudeDegrees - MiddleLongitude) / ToAngleW_E / ToDegree;
	    local realLen = lenSouth - (inLatitudeDegrees - EndSouth) / ToLengthN_S;
	    local outX = centerX - realLen * math.cos (realAng);
	    local outZ = centerZ + realLen * math.sin (realAng);
	    return outX, outZ
	end	


	
------------------------------------------------------------------------
-- 	S�quenceur de t�che												  --
------------------------------------------------------------------------


DEBUG_MODE = true; 	-- fichier ..
Sioc_OK = true
Data_Buffer = {}


logCom("Connection � SIOC, ouverture Socket")
package.path  = package.path..";.\\LuaSocket\\?.lua"
package.cpath = package.cpath..";.\\LuaSocket\\?.dll"
socket = require("socket")
	
	
	-- Gestion des erreurs de connection � SIOC
	if pcall(Sioc_connect) then
		logCom("SIOC Connection OK")
		Sioc_OK = true
		
	else
		logCom("SIOC Connection probl�me, pas de SIOC")
		Sioc_OK = false
	end

--logCom(Sioc_OK	)
logCom("LogetMissionStartTime")	
StartTime = LoGetMissionStartTime()
CurrentTime = LoGetModelTime()
SamplingPeriod_1 = 0.2 -- Interval de s�quence rapide en secondes (d�faut 200 millisecondes)
SamplingPeriod_2 = 1   -- Interval de s�quence lente en secondes (d�faut 1 seconde)

-- Initialisation des d�clencheurs rapides et lents
NextSampleTime_1 = CurrentTime + SamplingPeriod_1
NextSampleTime_2 = CurrentTime + SamplingPeriod_2

logCom("S�quenceur")

KTZ_DATA =
{
-- Fonction au d�marrage mission


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
			-- Envoi � SIOC de l'heure de d�but de mission
			envoyerInfo(41,LoGetMissionStartTime())
			-- Mise � zero du panel armement dans SIOC
			WeaponInit()
		else
		
			logCom("*** SIOC Probleme ***","\n")
			
		end
		
		
		
		
			
		
	end,

-- Fonction avant chaque image	
	KD_BeforeNextFrame=function(self)
		-- logCom(string.format("*** Fonction KD_BeforeNextFrame @= %.2f",CurrentTime,"\n"))
		-- Option R�ception des ordres de SIOC � chaque image (d�faut dans la s�quence lente)
		-- Reception_SIOC_Cmd()
	end,
	
-- Fonction apr�s chaque image
	KD_AfterNextFrame=function(self)
		-- R�cup�ration du Time Code, utilis� par le s�quenceur pour test et d�clancher les s�quences rapides et lentes
		CurrentTime = LoGetModelTime()
	end,

-- Fonction � chaque intervalle de temps type 1
-- S�quence rapide : d�faut 200 millisecondes
	KD_AtInterval_1=function(self)
				
		-- logCom(string.format("*** Fonction KD_AtInterval_1 @= %.2f",CurrentTime,"\n"))
		-- calcul de la date de fin du prochain intervalle de temps
		NextSampleTime_1 = CurrentTime + SamplingPeriod_1
	
		
		if Sioc_OK then
			-- Fonction d'envoi des donn�es � SIOC (liste fast)
			Envoi_Data_SIOC_fast()
		
			-- Option R�ception des ordres de SIOC s�quence rapide (par d�faut dans la s�quence lente)
			Reception_SIOC_Cmd()
		
		end
	
	end,

-- Fonction � chaque intervalle de temps type 2
-- S�quence lente : d�faut 1 seconde
	KD_AtInterval_2=function(self)
				
		-- logCom(string.format("*** Fonction KD_AtInterval_2 @= %.2f",CurrentTime,"\n"))
		-- calcul de la date de fin du prochain intervalle de temps
		NextSampleTime_2 = CurrentTime + SamplingPeriod_2
	
		
		if Sioc_OK then
			-- Fonction d'envoi des donn�es � SIOC (liste lente)
			Envoi_Data_SIOC_slow()
		end	
		
		-- R�ception des ordres de SIOC s�quence lente (par d�faut)
		-- Reception_SIOC_Cmd()
				
	end,	
	
-- Fonction fin de mission
	KD_Stop=function(self)
	
	-- Par d�faut, Rien ... possibilit� d'imprimer un rapport de mission avec LogCom ... � d�velopper
	-- logCom(messageInit)
	--logCom("*** Fonction KD_Stop ***")
	--logCom("  ","\n")
		
	-- log des r�sultats
	--logCom(string.format(" Flight Duration = %.0f secondes",CurrentTime,"\n"))
	--logCom("  ","\n")
	--logCom("  ","\n")
	--logCom("Miaou � tous !!!")
		
	end,
		
}


-- Declencheur de s�quence (depuis export.lua)
------------------------------------------------------------------------
--    S�quence : D�marrage de mission (ExportStart)    			  --
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
--    S�quence : avant chaque image            							  --
------------------------------------------------------------------------
-- Rien par d�faut

do
	local PrevLuaExportBeforeNextFrame=LuaExportBeforeNextFrame;

	LuaExportBeforeNextFrame=function()
		-- Non actif par d�faut 
		-- KTZ_DATA:KD_BeforeNextFrame();
						
		if PrevLuaExportBeforeNextFrame then
			PrevLuaExportBeforeNextFrame();
		end
	end
end

------------------------------------------------------------------------
--    S�quence : apr�s chaque image            						  --
------------------------------------------------------------------------
-- On compare le time code avec les compteurs de d�clenchement

do
	local PrevLuaExportAfterNextFrame=LuaExportAfterNextFrame;

	LuaExportAfterNextFrame=function()
		KTZ_DATA:KD_AfterNextFrame();
			if CurrentTime >= NextSampleTime_1 then
				KTZ_DATA:KD_AtInterval_1();  -- D�clencheur s�quence rapide
			end
			if CurrentTime >= NextSampleTime_2 then
				KTZ_DATA:KD_AtInterval_2();  -- D�clencheur s�quence lente
			end
			
		if PrevLuaExportAfterNextFrame then
			PrevLuaExportAfterNextFrame();
		end
	end
end


------------------------------------------------------------------------
--    S�quence : Fin de mission (ExportStop)         				  --
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



