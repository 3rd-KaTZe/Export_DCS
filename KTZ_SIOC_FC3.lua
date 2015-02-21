------------------------------------------------------------------------
--    KaTZ-Pit FC3 functions repo 									  --
------------------------------------------------------------------------

k.fc3.weapon_init = function(self)
	local pylone
	--logData(" Mise à zero du panel armement")
			
	k.sioc.send(1110,0)
	k.sioc.send(1105,0)
	k.sioc.send(1106,0)
					
	for pylone=1,13 do
			k.sioc.send(1110+pylone,0)
			k.sioc.send(1125+pylone,0)
	end
end
	
k.fc3.export.slow = function(self)
	if LoGetIndicatedAirSpeed() ~= nil then
			
		-- ============== Horloge de Mission ============================================================		
		k.sioc.send(42,LoGetModelTime())-- Heure de la mission
		k.sioc.send(128,LoGetBasicAtmospherePressure()*10) -- QNH
		
		-- ============== Parametres Moteur Fuel (lents) ====================================================		
		
		local _EngineInfo = LoGetEngineInfo()
		
		k.sioc.send(404,_EngineInfo.fuel_internal*100)--- Export en 0.01kg (100 UK (unité kero) = 1 kg)
		k.sioc.send(406,_EngineInfo.fuel_external*100)--- Export en 0.01kg (100 UK = 1 kg)
		
		-- Consommation Fuel, non utilisée, elle est mesurée dans SIOC par Delta Fuel sur 5 secondes
		--local EngC_L = math.floor(_EngineInfo.FuelConsumption.left * 6)
		--local EngC_R = math.floor(_EngineInfo.FuelConsumption.right * 6)
		--k.sioc.send(206,50005000 + EngC_L * 10000 + EngC_R )
		
		
		-- ============== Status Eléments Mécaniques ========================================================		
		local _MechInfo = LoGetMechInfo()
				
		-- "Truc", la valeur Check_WPS_MCP = 1 sera utilisée pour rescanner le weapon panel et les alarmes
		-- Utilisé train sorti, et AF
		local Check_WPS_MCP = _MechInfo.gear.status + _MechInfo.speedbrakes.status
		
		--k.sioc.send(151,_MechInfo.canopy.status) -- Commande Verrière
		k.sioc.send(602,_MechInfo.canopy.value) -- Retour Position Verrière
		
		k.sioc.send(604,55 + _MechInfo.gear.status * 10 + _MechInfo.gear.value) -- Commande + Retour Train

		k.sioc.send(606,55 + _MechInfo.flaps.status * 10 + _MechInfo.flaps.value)	-- Volet + retour Posit
		
		k.sioc.send(608,55 + _MechInfo.speedbrakes.status * 10 + _MechInfo.speedbrakes.value)	-- Retour position AF
		
		k.sioc.send(620,5555 + _MechInfo.parachute.status * 1000 + _MechInfo.parachute.value * 100 +  _MechInfo.wheelbrakes.status * 10 + _MechInfo.wheelbrakes.value)

		
		-- ============== Status Armement ==================================================================		
		local _PayloadInfo = LoGetPayloadInfo()		
		
		-- Scan du Pylone sélectionné ---------------------------------------------------------------------
		local pylone_selec = _PayloadInfo.CurrentStation  -- Pylone selectionné
		local quantite_selec = 0 -- Quantité de munition dispo. (utilisé pour déclancher le chrono de tir de SIOC)
		
		k.sioc.send(1108,pylone_selec)
		
		if pylon_selec~= 0 then
				if _PayloadInfo.Stations[pylone_selec]~= nil then 
							
					quantite_selec = _PayloadInfo.Stations[pylone_selec].count
					k.sioc.send(1109,quantite_selec)
					
				end
		end
		
		-- Scan du Canon sélectionné ------------------------------------------------------------------------
		local canon = _PayloadInfo.Cannon.shells  -- Nombre de munitions canon restantes
		k.sioc.send(1105,canon)
		
		
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
			k.fc3.weapon_init()
			local tank_nb = 0
			
			-- Scan du panel armement et envoi à SIOC
			for pylone=1,13 do
				if _PayloadInfo.Stations[pylone]~=nil then
					local type_arme = _PayloadInfo.Stations[pylone].weapon
					local type_arme_num = tonumber(type_arme.level1..type_arme.level2..type_arme.level3..type_arme.level4)
					local type_1 = tonumber(type_arme.level1)
					local type_2 = tonumber(type_arme.level2)
					local type_3 = tonumber(type_arme.level3)
					local type_4 = tonumber(type_arme.level4)
					
					-- un chiffre sur 7 digits, 1:22:33:44 avec les valeurs des 4 types de la munition 
					local ammo_typ = type_1 * 1000000 + type_2 * 10000 + type_3 * 100 + type_4		
					k.sioc.send(1125+pylone,ammo_typ)

					-- incrément du nombre de fuel tank
						if type_1 == 1 then
							tank_nb = tank_nb + 1
						end	
															
				end
			end
			k.sioc.send(1106,tank_nb)
		end
		
		-- Scan des Quantités et Container, systématique chaque seconde --------------------------------------------
		-- Possibilité de le rendre conditionnel avec une variable checksum voir "if" ci dessous
		-- Comptage du nombre de munitions + paniers et export 
		for pylone=1,13 do
			if _PayloadInfo.Stations[pylone]~=nil then
				local ammo = _PayloadInfo.Stations[pylone].count -- Lecture du nombre de munition restante
				local container = _PayloadInfo.Stations[pylone].container and 1 or 0 -- Lecture et conversion en int, de la présence d'un pod
				local ammo_export = ammo + container * 1000 -- valeur exporté = "ammo" ou "1000 + Ammo"
				-- un chiffre sur 4 digits, C:QQQ avec le container, puis la quantité d'ammo
						
				quant_checksum = quant_checksum + ammo_export
				
				-- if quant_checksum ~= old_checksum then
				k.sioc.send(1110+pylone ,ammo_export)
				-- old_checksum = quant_checksum
				
			end	
		end
		
		quant_checksum = quant_checksum + canon
		k.sioc.send(1110,quant_checksum)
		
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
						
			k.sioc.send(652,_numMaster)
			k.sioc.send(654,_numSubmode)
			k.sioc.send(556,_numACS)
			-- Automanette			
			--k.sioc.send(184,_NavigationInfo.ACS.autothrust and 1 or 0)
		end

		
		-- ============== Module Alarme ==================================================================================		
		local _MCP = LoGetMCPState()
		
		if _MCP then
			-- Conversion des variables Boléenne en Nombre 0 ou 1
			k.sioc.send(580,_MCP.MasterWarning and 1 or 0);
						
			if _MCP.MasterWarning == 1 then   
				local REF = (_MCP.RightEngineFailure and 1 or 0);
				local LEF = (_MCP.LeftEngineFailure and 1 or 0);
				local APF = (_MCP.AutopilotFailure and 1 or 0);
				local ACMF = (_MCP.ECMFailure and 1 or 0);
				local EOSF = (_MCP.EOSFailure and 1 or 0);
				local RF = (_MCP.RadarFailure and 1 or 0);
				local GF = (_MCP.GearFailure and 1 or 0);
				local HF = (_MCP.HydraulicsFailure and 1 or 0);
				local FTD = (_MCP.FuelTankDamage and 1 or 0);
			
			
			local Alarm = 555555555 + HF * 10000000 + GF * 1000000 + RF * 100000 + EOSF * 10000 + ACMF * 1000 + APF * 100 + LEF * 10 + REF
			
			k.sioc.send(582,Alarm);
			
			end
								
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
	end
	
end

k.fc3.export.fast = function(self)
	if LoGetIndicatedAirSpeed() ~= nil then
					
		-- ============== Parametres de Vol ===============================================================
		k.sioc.send(102,LoGetIndicatedAirSpeed() * 3.6 )-- m/sec converti en km/hr
		k.sioc.send(104,LoGetTrueAirSpeed() * 3.6)--m/sec
		k.sioc.send(106,LoGetMachNumber()*1000)-- mach * 1000
		
		k.sioc.send(112,LoGetAltitudeAboveSeaLevel()) -- Modif DCS FC3, export en mètres
		k.sioc.send(120,LoGetAltitudeAboveGroundLevel()) -- Modif DCS FC3, export en mètres
		k.sioc.send(130,LoGetVerticalVelocity()) -- m/sec
		
		
		-- ============== Parametres Attitude ==============================================================
		k.sioc.send(136,LoGetAngleOfAttack() * 573)	-- Export converti en 0.1 degrés
				
		-- Calcul de l'accélération, vecteur total G = Vx + Vy + Vz
		local _Acceleration = LoGetAccelerationUnits()
		local Gmeter = _Acceleration.y / math.abs(_Acceleration.y) * math.sqrt(math.pow(_Acceleration.x,2)+math.pow(_Acceleration.y,2)+math.pow(_Acceleration.z,2))
		k.sioc.send(134,Gmeter*100) -- Export en x * G
		
		-- Table Pitch , Bank , Yaw
		local pitch,bank,yaw = LoGetADIPitchBankYaw()
		k.sioc.send(140,pitch * 573) -- Export converti en 0.1 degrés
		k.sioc.send(142,bank * 573) -- Export converti en 0.1 degrés
		k.sioc.send(144,yaw * 573) -- Export converti en 0.1 degrés
		
		--k.sioc.send(131,LoGetMagneticYaw()*576) -- Indicateur virage
		k.sioc.send(132,LoGetSlipBallPosition()*100) -- Bille

		-- ============== Parametres HSI ==================================================================
		local _ControlPanel_HSI = LoGetControlPanel_HSI()
		k.sioc.send(152,_ControlPanel_HSI.HeadingPointer * 573) -- CAP Export converti en 0.1 degrés)
		k.sioc.send(156,_ControlPanel_HSI.ADF_raw * 573) -- Waypoint Export converti en 0.1 degrés)
		k.sioc.send(154,_ControlPanel_HSI.RMI_raw * 573) -- Route Export converti en 0.1 degrés)
		
		
		-- ============== Parametres ILS ==================================================================
		-- a regrouper dans une seule valeur 50005000
		k.sioc.send(702,LoGetGlideDeviation() * 100)  -- ILS UP/Down
		k.sioc.send(704,LoGetSideDeviation() * 100)  -- ILS Latéral
				
		-- ============== Parametres Moteur ================================================================
		local _EngineInfo=LoGetEngineInfo()
		local rpmL = math.floor(_EngineInfo.RPM.left*10)  
		local rpmR = _EngineInfo.RPM.right*10             
		k.sioc.send(202,50005000 + rpmL * 10000 + rpmR )
		
		local EngT_L = math.floor(_EngineInfo.Temperature.left)
		local EngT_R = _EngineInfo.Temperature.right
		k.sioc.send(204,50005000 + EngT_L * 10000 + EngT_R )

				
		-- ============== Position de l'Avion ===============================================================		
		local myXCoord, myZCoord
		if LoGetPlayerPlaneId() then
			local objPlayer = LoGetObjectById(LoGetPlayerPlaneId())
			myXCoord, myZCoord = k.common.export.getXYCoords(objPlayer.LatLongAlt.Lat, objPlayer.LatLongAlt.Long)
			
			-- k.sioc.send("13",objPlayer.Subtype)--ok
			-- k.sioc.send("14",obj.Country)
			-- k.sioc.send("15",_Coalition[objPlayer.Coalition])
			--k.sioc.send(95,objPlayer.Type.level1*100)--ok
			--k.sioc.send(96,objPlayer.Type.level2*100)--ok
			--k.sioc.send(97,objPlayer.Type.level3*100)--ok
			--k.sioc.send(98,objPlayer.Type.level4*100)--ok
			--k.sioc.send(82,myXCoord*100)--ok
			--k.sioc.send(83,myZCoord*100)--ok
			--k.sioc.send(85,objPlayer.LatLongAlt.Lat*100)--ok
			--k.sioc.send(86,objPlayer.LatLongAlt.Long*100)--ok
			k.sioc.send(110,objPlayer.LatLongAlt.Alt*100)--ok
			--k.sioc.send(21,objPlayer.Heading*100)--ok
		end
		
		-- ============== Données de Navigation ===============================================================		
		local _Route = LoGetRoute()
		if _Route then
		
		-- Calcul de distance ay Way Point Pythagore sur deltaX, deltaZ (approximation géométrie plane)
		local distance = math.sqrt(math.pow(_Route.goto_point.world_point.x-myXCoord,2)+math.pow(_Route.goto_point.world_point.z-myZCoord,2))
			k.sioc.send(162,distance);
			
			-- Numéro du Way Point, correction de -1 because décalage avec affichage DCS
			k.sioc.send(160,_Route.goto_point.this_point_num - 1); 
			
			-- Position x du way point, sert à KaTZ-Pit pour identifier la piste sélectionnée en mode RTN, LDG
			k.sioc.send(706,_Route.goto_point.world_point.x*100); 
			--k.sioc.send(51,_Route.goto_point.world_point.y*100); -- inutilisé
			--k.sioc.send(52,_Route.goto_point.world_point.z*100); -- inutilisé
			--k.sioc.send(53,_Route.goto_point.speed_req) -- inutilisé
			-- k.sioc.send(54,_Route.goto_point.estimated_time) -- inutilisé
			-- k.sioc.send(51,_Route.goto_point.next_point_num)
			--k.sioc.send(56,table.getn(_Route.route)) -- inutilisé
		end
	end
	
end	

k.log("export FC3 chargés")
