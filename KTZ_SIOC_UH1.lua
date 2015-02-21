------------------------------------------------------------------------
--    KaTZ-Pit FC3 functions repo 									  --
------------------------------------------------------------------------

k.uh1.export.slow = function(self)
	 -- Attention !!!!!!!! pour boucle lente, le nom est différent que boucle rapide : Device(0) >> MainPanel
		local MainPanel = GetDevice(0)
		-- Test de la précence de Device 0 , comme table  valide
		if type(MainPanel) ~= "table" then
			return ""
		end
		MainPanel:update_arguments()
		
		-- ============== Valeur Test ============================================================		
		
		-- ============== Horloge de Mission ============================================================		
		
		k.sioc.send(42,LoGetModelTime())-- Heure de la mission
		
		-- ============== Parametres de Vol (lents) ====================================================

		-- ADI
		local ADI_FF = math.floor(MainPanel:get_argument_value(148))		-- ADI Failure Flag
		local ADI_IDX = MainPanel:get_argument_value(138)*1000	-- ADI Index
		k.sioc.send(146,50005000 + 10000 * ADI_FF + ADI_IDX)	
		
		-- Altitude Radar , Index Low et High
		local Altirad_HDX = math.floor(MainPanel:get_argument_value(466) * 1000) -- Index High Setting
		local Altirad_LDX = MainPanel:get_argument_value(444) * 1000 -- Index Low Setting
		k.sioc.send(124,50005000 + 10000 * Altirad_HDX + Altirad_LDX)

		-- Alarme Low et High , Flag on/off
		local Altirad_HF = math.floor(MainPanel:get_argument_value(465)+0.2) -- Alti Rad high alti Alarme
		local Altirad_LF = math.floor(MainPanel:get_argument_value(447)+0.2) -- Alti Rad low alti Alarme
		local Altirad_O = MainPanel:get_argument_value(467) -- Alti Rad Off Flag
		k.sioc.send(126,555 + Altirad_HF * 100 + Altirad_LF * 10 + Altirad_O)
		
		
		-- ============== Parametres Moteur (lents) ====================================================
		
		local Oil_P_1 = math.floor(MainPanel:get_argument_value(113)*1000)	-- Oil Pressure : non linéaire export cadran
		local Oil_P_2 = 0	-- Non utilisé sur UH-1 un seul moteur
		local Oil_PGB_1 = math.floor(MainPanel:get_argument_value(115)*1000)	-- Oil Pressure Gear Box		
		
		local Oil_T_1 = math.floor(MainPanel:get_argument_value(114)*1000)	-- Oil Temp left : non linéaire export cadran
		local Oil_T_2 = 0  -- Non utilisé sur UH-1 un seul moteur	
		local Oil_TGB_1 = math.floor(MainPanel:get_argument_value(116) * 1000)	-- Oil Temp Gear Box : non linéaire export cadran

		k.sioc.send(260,50005000 + 10000 * Oil_P_1 + Oil_P_2)		-- Engine Oil Pressure (L,R)
		k.sioc.send(265,50005000 + Oil_PGB_1)						-- GearBox Oil Pressure
		k.sioc.send(250,50005000 + 10000 * Oil_T_1 + Oil_T_2)		-- Engine Oil Temp (L,R)
		k.sioc.send(255,50005000 + Oil_TGB_1)						-- GearBox Oil Temp 	

	
		-- ============== Switch Moteur Engine Panel ==============================================
		
		local EngStart =  MainPanel:get_argument_value(213)
		local Trim = MainPanel:get_argument_value(89)	-- Force Trim		
		local Hyd = MainPanel:get_argument_value(90) 	-- HYD CONT
		
		local RmpLow = MainPanel:get_argument_value(80)  	-- Low Rpm
		local Fuel = MainPanel:get_argument_value(81)  	-- Fuel On/Off
		local Gov =  MainPanel:get_argument_value(85)  	-- Gov On/Off
		local Ice =  MainPanel:get_argument_value(84)	-- De-Ice
		
		k.sioc.send(270,5555555 + Ice * 1000000 + Gov * 100000 + Fuel *  10000 + RmpLow * 1000  + Hyd * 100 + Trim * 10  + EngStart)

		-- ============== Parametres Fuel (lents)  =======================================================
		
		local Fuel_qty = MainPanel:get_argument_value(239)* 1000  -- valeur non linéaire à ajuster	
		local Fuel_sel = math.floor(MainPanel:get_argument_value(126)* 1000)	-- Fuel Pressure sur UH-1
		k.sioc.send(404,50005000 + Fuel_sel*10000 + Fuel_qty) -- Utilisation du canal Fuel Internal Forward
			
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
		k.sioc.send(504,Elec_SW_DC)								-- Position Switch DC
			
		
		-- Voyants --------------------------------------------------------------
		-- Regroupement des Position Switches AC et DC sur une valeur (Canal Voyant AC de SIOC)

		local Elec_V6 = MainPanel:get_argument_value(107)		-- Voyant Gen1
		local Elec_V7 = 0
		local Elec_V8 = MainPanel:get_argument_value(108)		-- Voyant Ground AC
		local Elec_V9 = MainPanel:get_argument_value(106)		-- Voyant Hacheur DCAC PO500

		k.sioc.send(516,5555 + Elec_V9 * 1000 + Elec_V8 * 100 + Elec_V7 * 10 + Elec_V6) -- Voyant Electric AC
		
		-- Voltage AC et DC --------------------------------------------------------------
		local VoltAC = math.floor(MainPanel:get_argument_value(150)*1000)		-- Voltage AC
		local VoltDC = MainPanel:get_argument_value(149)*1000		-- Voltage DC
		k.sioc.send(510,50005000 + VoltAC * 10000 + VoltDC) 
			 

		-- ============== Status Eléments Mécaniques ======================================================== WIP : a mettre à jour pour Mi-8
		--local DoorL = math.floor(MainPanel:get_argument_value(420)*10) -- Porte Cockpit , Left0 fermée , 1 ouverte	
		--local DoorR = math.floor(MainPanel:get_argument_value(422)*10) -- Porte Cockpit , Right0 fermée , 1 ouverte
		--k.sioc.send(602,55 + DoorL * 10 + DoorR) -- Positions Portes

		-- ============== Données de Navigation ===============================================================	
			
		
		-- ============== Status Armement ==================================================================

		local WPN_8 = math.floor(MainPanel:get_argument_value(252)) -- Switch Masterarm
		local WPN_8a = math.floor(MainPanel:get_argument_value(254)+0.5) -- Lamp Masterarm Armed
		local WPN_8b = math.floor(MainPanel:get_argument_value(255)+0.5) -- Lamp Masterarm Safe
		local WPN_9 = math.floor(MainPanel:get_argument_value(253)) -- Switch Gun Select L-R-All
		local WPN_10 = math.floor(MainPanel:get_argument_value(256)) -- Switch 40-275-762
		local WPN_11 = math.floor(MainPanel:get_argument_value(257)*10+0.2) -- Selecteur 7 Posit Rocket Pair
		k.sioc.send(1020,555550 + WPN_8 * 100000 + WPN_8a * 10000 + WPN_8b * 1000 + WPN_9 * 100 + WPN_10 * 10 + WPN_11)

		
		-- ============== Status Flare ==================================================================
		
		local FLR_5 = math.floor(MainPanel:get_argument_value(456)) -- Safe Arm Flare
		local FLR_5B = math.floor(MainPanel:get_argument_value(458)+0.5) -- Armed Lamp
		local FLR_nb = math.floor(MainPanel:get_argument_value(460)*10+ 0.2 ) * 10 + math.floor(MainPanel:get_argument_value(461)*10) 	-- Flare Number
		
		-- Chaff Non modelisées dans DCS
		--local FLR_9 = math.floor(MainPanel:get_argument_value(459)) -- Man Prgm
		-- local FLR_chaf = math.floor(MainPanel:get_argument_value(462)*10) * 10 + math.floor(MainPanel:get_argument_value(463)*10) 	-- Chaff Number
		
		k.sioc.send(1025,5500 + FLR_5 * 1000 + FLR_5B * 100 + FLR_nb)		-- Position Switch, Lamp, et nb flare
		-- k.sioc.send(1027,50005000 + FLR_nb * 10000 + FLR_chaf)		
					
		-- ============== Module Alarme ==================================================================================	
		local Alrm_Fire = math.floor(MainPanel:get_argument_value(275)) -- Alarme Fire
		local Alrm_Rpm = math.floor(MainPanel:get_argument_value(276)) -- Alarme Low RPM
		local Alrm_MW = math.floor(MainPanel:get_argument_value(277)) -- Alarme MAster Warning
		local V_Start = math.floor(MainPanel:get_argument_value(213)) -- Engine Start
		k.sioc.send(574,5555 + Alrm_Fire * 1000 + Alrm_Rpm * 100 + Alrm_MW * 10 + V_Start)
		
		
		
		-- ============== Miaou the end ==================================================================================		
		
end

k.uh1.export.fast = function(self)
	    		
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
		--k.sioc.send(21,lMainPanel:get_argument_value(465)*100)
		--k.sioc.send(22,lMainPanel:get_argument_value(447)*100)
		--k.sioc.send(23,lMainPanel:get_argument_value(456)*100)
		--k.sioc.send(24,lMainPanel:get_argument_value(457)*100)
		--k.sioc.send(25,lMainPanel:get_argument_value(464)*100)
		--k.sioc.send(26,lMainPanel:get_argument_value(460)*100)
		--k.sioc.send(27,lMainPanel:get_argument_value(461)*1000)
		--k.sioc.send(28,lMainPanel:get_argument_value(45)*1000)
		--k.sioc.send(29,lMainPanel:get_argument_value(180)*1000)

		
		-- ============== Clock =========================================================================
		-- Inutile, time est récupéré avec LoGetModelTime()

		-- ============== Contrôle de l'appareil =========================================================================		
				
		-- ============== Parametres de Vol ===============================================================
		k.sioc.send(102,lMainPanel:get_argument_value(117)*1000) 	-- IAS Badin

		
		k.sioc.send(112, 50005000 + math.floor(lMainPanel:get_argument_value(179) * 1000) * 10000 + lMainPanel:get_argument_value(180) * 1000)
		-- Alti Baro deux aiguilles

		k.sioc.send(120,lMainPanel:get_argument_value(443)*1000) 	-- Alti Radar valeur non linéaire
		
		k.sioc.send(130,lMainPanel:get_argument_value(134)*1000) 	-- Vario (-30m/s , +30 m/s) ... valeur non linéaire à ajuster dans html
		
		k.sioc.send(140,lMainPanel:get_argument_value(143)* -1000)	-- Pitch (ADI)
		k.sioc.send(142,lMainPanel:get_argument_value(142)*1000)	-- Bank ou Roll (ADI)
		
		
		--k.sioc.send(150,lMainPanel:get_argument_value(11)*1000)	-- Boussole
		
		local EUP_S = math.floor(lMainPanel:get_argument_value(132)*1000)	-- EUP_Speed
		local EUP_SS = math.floor(lMainPanel:get_argument_value(133)*1000)	-- EUP_Sideslip
		local EUP = 50005000 + EUP_S * 10000 + EUP_SS
		k.sioc.send(180,EUP)	-- EUP_Data

		-- Donnée Altiradar

		local Altirad1 = math.floor((lMainPanel:get_argument_value(468)+ 0.02) *10)
		local Altirad2 = math.floor((lMainPanel:get_argument_value(469)+ 0.02) *10)
		local Altirad3 = math.floor((lMainPanel:get_argument_value(470)+ 0.02) *10)
		local Altirad4 = math.floor((lMainPanel:get_argument_value(471)+ 0.02) *10)
		k.sioc.send(122,(500000000 + Altirad1 * 1000000 + Altirad2 * 10000 + Altirad3 * 100 + Altirad4))	
		
		-- ============== Parametres  ==============================================================

		-- ============== Parametres HSI ==================================================================
		
		k.sioc.send(152,lMainPanel:get_argument_value(165)*3600) -- CAP (Export 0.1 degrés)
		k.sioc.send(154,lMainPanel:get_argument_value(160)*3600) -- Course (Ecart par rapport à la couronne des caps)
		k.sioc.send(156,lMainPanel:get_argument_value(159)*3600) -- Waypoint (Ecart par rapport à la couronne des caps)
				
		-- ============== Parametres ILS ==================================================================
		
		-- ============== Parametres Rotor =================================================================
		
		k.sioc.send(230,lMainPanel:get_argument_value(123)*1100) -- Rotor rpm : max 110
				
		-- ============== Parametres Moteur (Fast) ================================================================
		
		local RPM_L = math.floor(lMainPanel:get_argument_value(122)*1100)		-- rpm left : max 110
		local RPM_R = 0	-- rpm right : unused on UH1
		k.sioc.send(202,50005000 + RPM_L * 10000 + RPM_R)									-- Groupage RPM L et R dans une donnée
		
		
		local EngT_L =	math.floor(lMainPanel:get_argument_value(121)*1000)		-- temp left : max 1000
		local EngT_R = 0	-- temp right : unused on UH1 
		k.sioc.send(204,50005000 + EngT_L * 10000 + EngT_R)									-- Groupage Température L et R dans une donnée
		
							
		
		-- ============== Parametres Turbine Torque/Rpm/Exhaust ===================================================================
		
		local Torque = math.floor(lMainPanel:get_argument_value(124)*1000)
		local Gas = math.floor(lMainPanel:get_argument_value(119)*1000)

		k.sioc.send(240,50005000 + Torque * 10000 + Gas)
		k.sioc.send(242,50005000 + lMainPanel:get_argument_value(121)*1000) -- Exhaust Temperature

		-- ============== Position de l'Avion ===============================================================		
end

k.log("export Huey chargés")