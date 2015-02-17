--[[
**************************************************************************
*     Module d'Export de données pour SIOC, et le KaTZ-Pit               *
*     Par KaTZe     -         http://www.3rd-wing.net                    *
*     Version 5010a  du   12/02/2015                                     *
**************************************************************************
--]]

-- siocConfig.lua contient :
-- Script de configuration SIOC
-- Paramêtres IP : Host, Port
-- Ainsi que la plage d'Offset utilisée pour les valeurs KaTZ-Pit 
-- Si l'on veut décaler la plage rentrer une valeur (ex: 2000)

-- dofile ( lfs.writedir().."Scripts\\siocConfig.lua" ) -- déplacé dans katze.lua
-- local c -- déplace dans katze.lua

------------------------------------------------------------------------
--    Fonction logCom												  --
------------------------------------------------------------------------
-- function logCom(message) -- déplacé dans katze.lua


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
			--logCom(messageEnvoye)
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
			--logData(message)
			-- longueur du message
			local longueur
			longueur = fin - debut
			-- logData(longueur)
			-- découpe du message en commande et envoi à lockon
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
						
					-- Envoi à LockOn
					LoSetCommand(valeur)
				
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
		
		-- ============== Parametres de Vol ===============================================================
		envoyerInfo(102,LoGetIndicatedAirSpeed() * 3.6 )-- m/sec converti en km/hr
		envoyerInfo(104,LoGetTrueAirSpeed() * 3.6)--m/sec
		envoyerInfo(106,LoGetMachNumber()*1000)-- mach * 1000
		
		envoyerInfo(112,LoGetAltitudeAboveSeaLevel()) -- Modif DCS FC3, export en mètres
		envoyerInfo(120,LoGetAltitudeAboveGroundLevel()) -- Modif DCS FC3, export en mètres
		envoyerInfo(130,LoGetVerticalVelocity()) -- m/sec
		
		
		-- ============== Parametres Attitude ==============================================================
		envoyerInfo(136,LoGetAngleOfAttack() * 573)	-- Export converti en 0.1 degrés
				
		-- Calcul de l'accélération, vecteur total G = Vx + Vy + Vz
		_Acceleration = LoGetAccelerationUnits()
		local Gmeter = _Acceleration.y / math.abs(_Acceleration.y) * math.sqrt(math.pow(_Acceleration.x,2)+math.pow(_Acceleration.y,2)+math.pow(_Acceleration.z,2))
		envoyerInfo(134,Gmeter*100) -- Export en x * G
		
		-- Table Pitch , Bank , Yaw
		pitch,bank,yaw = LoGetADIPitchBankYaw()
		envoyerInfo(140,pitch * 573) -- Export converti en 0.1 degrés
		envoyerInfo(142,bank * 573) -- Export converti en 0.1 degrés
		envoyerInfo(144,yaw * 573) -- Export converti en 0.1 degrés
		
		--envoyerInfo(131,LoGetMagneticYaw()*576) -- Indicateur virage
		envoyerInfo(132,LoGetSlipBallPosition()*100) -- Bille

		-- ============== Parametres HSI ==================================================================
		_ControlPanel_HSI = LoGetControlPanel_HSI()
		envoyerInfo(152,_ControlPanel_HSI.HeadingPointer * 573) -- CAP Export converti en 0.1 degrés)
		envoyerInfo(156,_ControlPanel_HSI.ADF_raw * 573) -- Waypoint Export converti en 0.1 degrés)
		envoyerInfo(154,_ControlPanel_HSI.RMI_raw * 573) -- Route Export converti en 0.1 degrés)
		
		
		-- ============== Parametres ILS ==================================================================
		-- a regrouper dans une seule valeur 50005000
		envoyerInfo(702,LoGetGlideDeviation() * 100)  -- ILS UP/Down
		envoyerInfo(704,LoGetSideDeviation() * 100)  -- ILS Latéral
				
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
			envoyerInfo(110,objPlayer.LatLongAlt.Alt*100)--ok
			--envoyerInfo(21,objPlayer.Heading*100)--ok
		end
		
		-- ============== Données de Navigation ===============================================================		
		local _Route = LoGetRoute()
		if _Route then
		
		-- Calcul de distance ay Way Point Pythagore sur deltaX, deltaZ (approximation géométrie plane)
		local distance = math.sqrt(math.pow(_Route.goto_point.world_point.x-myXCoord,2)+math.pow(_Route.goto_point.world_point.z-myZCoord,2))
			envoyerInfo(162,distance);
			
			-- Numéro du Way Point, correction de -1 because décalage avec affichage DCS
			envoyerInfo(160,_Route.goto_point.this_point_num - 1); 
			
			-- Position x du way point, sert à KaTZ-Pit pour identifier la piste sélectionnée en mode RTN, LDG
			envoyerInfo(706,_Route.goto_point.world_point.x*100); 
			--envoyerInfo(51,_Route.goto_point.world_point.y*100); -- inutilisé
			--envoyerInfo(52,_Route.goto_point.world_point.z*100); -- inutilisé
			--envoyerInfo(53,_Route.goto_point.speed_req) -- inutilisé
			-- envoyerInfo(54,_Route.goto_point.estimated_time) -- inutilisé
			-- envoyerInfo(51,_Route.goto_point.next_point_num)
			--envoyerInfo(56,table.getn(_Route.route)) -- inutilisé
		end	


		-- ============== Parametre TWS -- En développement =======================================================		
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
		--logData("TWS Détail ", "\n")
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
	     -- Export à la seconde
		--logCom ("time de la boucle 2 - Slow")
		--logCom(CurrentTime)
	
		-- ============== Horloge de Mission ============================================================		
		envoyerInfo(42,LoGetModelTime())-- Heure de la mission
		-- envoyerInfo(11,LoGetMissionStartTime())-- envoyé en début de mission
		
		envoyerInfo(128,LoGetBasicAtmospherePressure()*10)
		

		-- ============== Parametres Moteur Fuel (lents) ====================================================		
		_EngineInfo=LoGetEngineInfo()
		
		

		--envoyerInfo(43,_EngineInfo.Temperature.left)--- Export en °c
		--envoyerInfo(44,_EngineInfo.Temperature.right)--- Export en °c
		--envoyerInfo(45,_EngineInfo.HydraulicPressure.left*10)-- inutilisé
		--envoyerInfo(46,_EngineInfo.HydraulicPressure.right*10)-- inutilisé
		envoyerInfo(404,_EngineInfo.fuel_internal*100)--- Export en 0.01kg (100 UK (unité kero) = 1 kg)
		envoyerInfo(406,_EngineInfo.fuel_external*100)--- Export en 0.01kg (100 UK = 1 kg)
		
		-- Consommation Fuel, non utilisée, elle est mesurée dans SIOC par Delta Fuel sur 5 secondes
		local EngC_L = math.floor(_EngineInfo.FuelConsumption.left * 6)
		local EngC_R = math.floor(_EngineInfo.FuelConsumption.right * 6)
		envoyerInfo(206,50005000 + EngC_L * 10000 + EngC_R )
		
		-- envoyerInfo(56,_EngineInfo.FuelConsumption.left*6) --conversion kg/10sec (erreur ds LO200) en kg/mn
		-- envoyerInfo(57,_EngineInfo.FuelConsumption.right*6) --conversion kg/10sec (erreur ds LO200) en kg/mn
		-- envoyerInfo(58,(_EngineInfo.FuelConsumption.left + _LoGetEngineInfo.FuelConsumption.right)*6)
		
		-- ============== Status Eléments Mécaniques ========================================================		
		_MechInfo = LoGetMechInfo()
				
		-- "Truc", la valeur Check_WPS_MCP = 1 sera utilisée pour rescanner le weapon panel et les alarmes
		-- Utilisé train sorti, et AF
		Check_WPS_MCP = _MechInfo.gear.status + _MechInfo.speedbrakes.status
		--envoyerInfo(151,_MechInfo.canopy.status) -- Commande Verrière
		envoyerInfo(602,_MechInfo.canopy.value) -- Retour Position Verrière
		
		envoyerInfo(604,55 + _MechInfo.gear.status * 10 + _MechInfo.gear.value) -- Commande + Retour Train

		envoyerInfo(606,55 + _MechInfo.flaps.status * 10 + _MechInfo.flaps.value)	-- Volet + retour Posit
		
		envoyerInfo(608,55 + _MechInfo.speedbrakes.status * 10 + _MechInfo.speedbrakes.value)	-- Retour position AF
		
		envoyerInfo(620,5555 + _MechInfo.parachute.status * 1000 + _MechInfo.parachute.value * 100 +  _MechInfo.wheelbrakes.status * 10 + _MechInfo.wheelbrakes.value)

		
		-- Regrouper data Mech en 555555
		-- Gear_Main = _MechInfo.gear.main -- inutilisé
		--envoyerInfo("1213",_LoGetMechInfo.gear.main.nose.rod)	-- inutilisé	
		--envoyerInfo("1214",_LoGetMechInfo.gear.main.left.rod)-- inutilisé
		--envoyerInfo("1215",_LoGetMechInfo.gear.main.right.rod)-- inutilisé
		--envoyerInfo("1215",Gear_Main.left.rod)-- inutilisé
		
		
		-- ============== Status Armement ==================================================================		
		local _PayloadInfo = LoGetPayloadInfo()		
		
		
		-- Scan du Pylone sélectionné ---------------------------------------------------------------------
		local pylone_selec = _PayloadInfo.CurrentStation  -- Pylone selectionné
		local quantite_selec = 0 -- Quantité de munition dispo. (utilisé pour déclancher le chrono de tir de SIOC)
		
		envoyerInfo(1108,pylone_selec)
		
		if pylon_selec~= 0 then
				if _PayloadInfo.Stations[pylone_selec]~= nil then 
							
					quantite_selec = _PayloadInfo.Stations[pylone_selec].count
					envoyerInfo(1109,quantite_selec)
					
				end
		end
		
		-- Scan du Canon sélectionné ------------------------------------------------------------------------
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
		-- Le Scan est déclenché à l'arrêt verrière ouverte, ou en vol à la sortie des AF
		-- La valeur "Check_WPS_MCP" est utilisé pour déclancher le rescan du weapon panel
		-- A modifier lancer le scan au passage BVR, ou R2G (R-R, R-Sol)
			
		if Check_WPS_MCP == 1 then
			-- le weapon panel type a changé, on le scan
			
			-- Reset du panel armement et du nombre de fuel tank
			WeaponInit()
			local tank_nb = 0
			
			-- Scan du panel armement et envoi à SIOC
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

					-- incrément du nombre de fuel tank
						if type_1 == 1 then
							tank_nb = tank_nb + 1
						end	
															
				end
			end
			envoyerInfo(1106,tank_nb)
		end
		
		-- Scan des Quantités et Container, systématique chaque seconde --------------------------------------------
		-- Possibilité de le rendre conditionnel avec une variable checksum voir "if" ci dessous
		-- Comptage du nombre de munitions + paniers et export 
		for pylone=1,13 do
			if _PayloadInfo.Stations[pylone]~=nil then
				ammo = _PayloadInfo.Stations[pylone].count -- Lecture du nombre de munition restante
				container = _PayloadInfo.Stations[pylone].container and 1 or 0 -- Lecture et conversion en int, de la présence d'un pod
				ammo_export = ammo + container * 1000 -- valeur exporté = "ammo" ou "1000 + Ammo"
				-- un chiffre sur 4 digits, C:QQQ avec le container, puis la quantité d'ammo
						
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
			-- Conversion des variables Boléenne en Nombre 0 ou 1
			envoyerInfo(580,_MCP.MasterWarning and 1 or 0);
						
			if _MCP.MasterWarning or Check_WPS_MCP == 1 then   
				local REF = (_MCP.RightEngineFailure and 1 or 0);
				local LEF = (_MCP.LeftEngineFailure and 1 or 0);
				local APF = (_MCP.AutopilotFailure and 1 or 0);
				local ACMF = (_MCP.ECMFailure and 1 or 0);
				local EOSF = (_MCP.EOSFailure and 1 or 0);
				local RF = (_MCP.RadarFailure and 1 or 0);
				local GF = (_MCP.GearFailure and 1 or 0);
				local HF = (_MCP.HydraulicsFailure and 1 or 0);
				--local FTD = (_MCP.FuelTankDamage and 1 or 0);
			end
			
			local Alarm = 555555555 + HF * 10000000 + GF * 1000000 + RF * 100000 + EOSF * 10000 + ACMF * 1000 + APF * 100 + LEF * 10 + REF
			
			envoyerInfo(582,Alarm);
		 						
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
		
				
		
--[[  Old MPC à modifier		-- MPC State *******************************
		_LoGetMCPState = LoGetMCPState()
		local _compteur = 0
		local _MCPState = 0
		for n,v in pairs(_LoGetMCPState) do
			if (v) then
			
				_MCPState = _MCPState + math.pow(2,_compteur)
			end
			_compteur = _compteur + 1
		end
		envoyerInfo("71",_MCPState) -- Voir détails dans notice
]]--			
	end

	
	-- Mise à zero initiale du panel armement (CHECK , Six pylones ... autres avions ???)
function WeaponInit()
		local pylone
		--logData(" Mise à zero du panel armement")
				
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
	--    Fonction pour le calcul des coordonnées 						  --
	--	  Merci à Mnemonic                           					  --
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
-- 	MAIN PROGRAMME 											  --
------------------------------------------------------------------------


DEBUG_MODE = true; 	-- fichier ..
Sioc_OK = true
Data_Buffer = {}


logCom("Connection à SIOC, ouverture Socket")
package.path  = package.path..";.\\LuaSocket\\?.lua"
package.cpath = package.cpath..";.\\LuaSocket\\?.dll"
socket = require("socket")
	
	
	-- Gestion des erreurs de connection à SIOC
	if pcall(Sioc_connect) then
		logCom("SIOC Connection OK")
		Sioc_OK = true
	else
		logCom("SIOC Connection problème, pas de SIOC")
		Sioc_OK = false
	end


if Sioc_OK then
	
	-- Mise à zero du panel armement dans SIOC
	WeaponInit()
	
	-- Envoi à SIOC de l'heure de début de mission
	StartTime = LoGetMissionStartTime()
	envoyerInfo(41,StartTime)
	
	CurrentTime = LoGetModelTime()
-- Va chercher la config IP dans siocConfig
   	--SamplingPeriod_1 = 0.1 -- Interval de séquence rapide en secondes (défaut 100 millisecondes)
	--SamplingPeriod_2 = 0.5   -- Interval de séquence lente en secondes (défaut 0.5 seconde)
	SamplingPeriod_1 = (siocConfig.timing_fast / 1000) or 0.1
	SamplingPeriod_2 = (siocConfig.timing_slow / 1000) or 0.5
	SamplingPeriod_FPS = 5  -- Interval de mesure des fps (défaut 5 secondes)

	logCom("  ","\n")
	logCom("--- Initialisation du Séquenceur ---" ,"\n")
	logCom(string.format(" Mission Start Time (secondes) = %.0f",StartTime,"\n"))	
	logCom(string.format(" Sampling Period 1 = %.1f secondes",SamplingPeriod_1,"\n"))
	logCom(string.format(" Sampling Period 2 = %.1f secondes",SamplingPeriod_2,"\n"))
	logCom(string.format(" Sampling Period FPS = %.1f secondes",SamplingPeriod_FPS,"\n"))

	-- Initialisation des déclencheurs rapides, lents et FPS
	NextSampleTime_1 = CurrentTime + SamplingPeriod_1
	NextSampleTime_2 = CurrentTime + SamplingPeriod_2
	NextSampleTime_FPS = CurrentTime + SamplingPeriod_FPS

	logCom("  ","\n")
	logCom("---KaTZe Log: KTZ-FPS-Check Activated ----")
	fps_counter = 0
	fps_max = 0
	fps_min = 0
	fps_tot = 0
	fps_0_10 = 0
	fps_10_20 = 0
	fps_20_30 = 0
	fps_30_40 = 0
	fps_40_50 = 0
	fps_50 = 0
	
end	

KTZ_DATA =
{
	-- Fonction au démarrage mission -------------------------------------------------------------------------
	KD_Start=function(self)
	
		logCom("  ","\n")
		logCom("--- Export Start ---" ,"\n")
		logCom("  ","\n")
		
	end,

	-- Fonction avant chaque image -------------------------------------------------------------------------------	
	KD_BeforeNextFrame=function(self)
				
	end,
	
	-- Fonction après chaque image ------------------------------------------------------------------------------------
	KD_AfterNextFrame=function(self)
		-- Récupération du Time Code, utilisé par le séquenceur pour test et déclancher les séquences rapides et lentes
		-- Incrémentation du compteur de FPS
		fps_counter = fps_counter + 1
		CurrentTime = LoGetModelTime()
	end,

	-- Fonction à chaque intervalle de temps type 1 -----------------------------------------------------------------------
	-- Séquence rapide : défaut 100 millisecondes
	KD_AtInterval_1=function(self)
				
		-- calcul de la date de fin du prochain intervalle de temps
		NextSampleTime_1 = CurrentTime + SamplingPeriod_1
			
		if Sioc_OK then
			-- Fonction d'envoi des données à SIOC (liste fast)
			Envoi_Data_SIOC_fast()
			-- Option Réception des ordres de SIOC séquence rapide (par défaut dans la séquence lente)
			Reception_SIOC_Cmd()
		end
	
	end,

	-- Fonction à chaque intervalle de temps type 2 -----------------------------------------------------------------------
	-- Séquence lente : défaut 0.5 seconde
	KD_AtInterval_2=function(self)
				
		-- logCom(string.format("*** Fonction KD_AtInterval_2 @= %.2f",CurrentTime,"\n"))
		-- calcul de la date de fin du prochain intervalle de temps
		NextSampleTime_2 = CurrentTime + SamplingPeriod_2
		
		if Sioc_OK then
			-- Fonction d'envoi des données à SIOC (liste lente)
			Envoi_Data_SIOC_slow()
		end	
						
	end,	
	
	-- Fonction à chaque intervalle de temps de mesure FPS  -----------------------------------------------------------------------
	-- Défaut 5 secondes	
	KD_AtInterval_FPS=function(self)
	
		fps_tot = fps_tot + fps_counter -- Compteur du total de frames
	
		-- logCom(string.format("*** Fonction K_AtInterval_FPS @= %.2f",CurrentTime,"\n"))
		-- Classement du nombre de frames de l'intervalle de temps dans l'histogramme
		
		if fps_counter < 10 * SamplingPeriod_FPS then
			fps_0_10 = fps_0_10 + fps_counter
		else
			if fps_counter < 20 * SamplingPeriod_FPS then
				fps_10_20 = fps_10_20 + fps_counter
			else
				if fps_counter < 30 * SamplingPeriod_FPS then
					fps_20_30 = fps_20_30 + fps_counter
				else
					if fps_counter < 40 * SamplingPeriod_FPS then
						fps_30_40 = fps_30_40 + fps_counter
					else
						if fps_counter < 50 * SamplingPeriod_FPS then
							fps_40_50 = fps_40_50 + fps_counter
						else
							fps_50 = fps_50 + fps_counter
						end
					end
				end	
			end
		end

		-- remise à zero du compteur de frame de l'intervalle de temps
		fps_counter = 0
		-- calcul de la date de fin du prochain intervalle de temps
		NextSampleTime_FPS = CurrentTime + SamplingPeriod_FPS
		
end,
	
	-- Fonction fin de mission -----------------------------------------------------------------------
	KD_Stop=function(self)
	
	-- Calcul des pourcentages de chaque tranche de l'histogramme
	local histo_0_10 = fps_0_10 / fps_tot * 100
	local histo_10_20 = fps_10_20 / fps_tot * 100
	local histo_20_30 = fps_20_30 / fps_tot * 100
	local histo_30_40 = fps_30_40 / fps_tot * 100
	local histo_40_50 = fps_40_50 / fps_tot * 100
	local histo_50 = fps_50 / fps_tot * 100
	

	-- logCom(messageInit)
	logCom("  ","\n")
	logCom("*** Fin du Vol ***")
	logCom("  ","\n")
		
	-- log des résultats
	logCom(string.format(" Flight Duration = %.0f secondes",CurrentTime,"\n"))
	logCom("  ","\n")
	logCom("*** Information de FPS, histogramme sur le vol ***")
	logCom("  ","\n")
	logCom(string.format(" Total Number of Frames = %.0f",fps_tot,"\n"))
	logCom(string.format(" Flight Duration = %.0f secondes",CurrentTime,"\n"))
	logCom("  ","\n")
	logCom(string.format("*** Average FPS =  %.1f ",fps_tot/CurrentTime,"\n"))
	logCom("  ","\n")
	logCom(string.format("*** FPS < 10      = %.1f percent",histo_0_10,"\n"))
	logCom(string.format("*** 10 < FPS < 20 = %.1f percent",histo_10_20,"\n"))
	logCom(string.format("*** 20 < FPS < 30 = %.1f percent",histo_20_30,"\n"))
	logCom(string.format("*** 30 < FPS < 40 = %.1f percent",histo_30_40,"\n"))
	logCom(string.format("*** 40 < FPS < 50 = %.1f percent",histo_40_50,"\n"))
	logCom(string.format("*** 50 < FPS      = %.1f percent",histo_50,"\n"))
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
			if CurrentTime >= NextSampleTime_FPS then
				KTZ_DATA:KD_AtInterval_FPS(); -- Déclencheur séquence ultra lente
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



