--[[
**************************************************************************
*     Module d'Export de données pour SIOC, et le KaTZ-Pit               *
*     Par KaTZe     -         http://www.3rd-wing.net                    *
*     Version KA-50_v5008  du   14/01/2015  pour le KH50                 *
**************************************************************************
--]]

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

function()
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

		local Elec_V11 = MainPanel:get_argument_value(290)		-- EEG Left
		local Elec_V10 = MainPanel:get_argument_value(292)		-- EEH Right
		

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
		-- Export des switch réglage Canon ----------------------------------------------------------------------
				
		local Manauto = MainPanel:get_argument_value(403)
		local Burst = math.floor(MainPanel:get_argument_value(400)*10 + 0.2)
		local HeApi = MainPanel:get_argument_value(399)
		local Rof = MainPanel:get_argument_value(398)
		
		local Cannon = MainPanel:get_argument_value(177)
		local MasterArm = MainPanel:get_argument_value(167)
		
		envoyerInfo(1020,555555 + Manauto * 100000 + Burst * 10000 + HeApi * 1000 + Rof * 100 + Cannon * 10 + MasterArm)
		
	
		
		-- Export des quantités Rocket et Canon ----------------------------------------------------------------------
		local wpncnt, cannoncnt = get_Weapon()
		if wpncnt and cannoncnt then
			envoyerInfo(1014,50005000+ wpncnt * 10000 + cannoncnt)
		end
		
		-- Export des switch réglage cannon ----------------------------------------------------------------------
		
		
		
		
		
		
		-- Export de l'affichage du PVI800 ----------------------------------------------------------------------
		local pvi1, pvi2, pvi3, pvi4 = get_PVI800()
		if not pvi1 then pvi1 = 0 end
		if not pvi2 then pvi2 = 0 end
		if not pvi3 then pvi3 = 0 end
		if not pvi4 then pvi4 = 0 end
		
			envoyerInfo(171,pvi1)
			envoyerInfo(172,pvi2)
			envoyerInfo(173, 50005000 + pvi3 * 10000 + pvi4)
		

		
		
		-- Export de l'affichage de l'UV26 ----------------------------------------------------------------------
		local uv26 = get_UV26()
		if uv26 then 
			envoyerInfo(1040,5000 + uv26)
		end
		
			local UV_On = math.floor(MainPanel:get_argument_value(496) + 0.2)  -- 0 ou 1
			local LedLeft = MainPanel:get_argument_value(541)
			local LedRight = MainPanel:get_argument_value(542)
			local Side_SW = math.floor(MainPanel:get_argument_value(36) * 10 + 0.2)  -- 0 ou 0.1 ou 0.2
			local Num_SW = math.floor(MainPanel:get_argument_value(37) * 10 + 0.2)  -- 0 ou 0.1
			
			envoyerInfo(1042, 55555 + UV_On * 10000 + LedLeft * 1000 + LedRight * 100 + Num_SW * 10 + Side_SW)
			
			envoyerInfo(1046,MainPanel:get_argument_value(496)*1000)
			
			
		
		
		
		
		-- ============== Lecture de l'Abris =========================================================================	
				
		local Abris_on = MainPanel:get_argument_value(130)-- On/Off
				
		local c1 = 0
		local c2 = 0
		local c3 = 0
		local c4 = 0
		local c5 = 0
		
		local bout1,bout2,bout3,bout4,bout5  = get_Abris()
		
		if bout1 then 
			c1 = abris_ref(bout1)
		end
		
		if bout2 then 
			c2 = abris_ref(bout2)
		end
		
		if bout3 then 
			c3 = abris_ref(bout3)
		end
		
		if bout4 then 
			c4 = abris_ref(bout4)
		end
		
		if bout5 then 
			c5 = abris_ref(bout5)
		end
		
			
					
			envoyerInfo(731,50005000 + c1 * 10000 + c2)
			envoyerInfo(732,50005000 + c3 * 10000 + c4)
			envoyerInfo(733,50005000 + Abris_on * 10000 + c5)
		
		
			
			
			
		
end
		
		
		
function abris_ref(item)

	-- liste complète , problème caractère /\
	-- local abrismenu = {"/\","\/",">",">>","ACTIV","ADD","ADD LIN","ADD PNT","ARC","AUTO","CALC","CANCEL","CLEAR","CTRL","DELETE","DRAW","EDIT","ENTER","ERBL","FPL","GNSS","HSI","INFO","LOAD","MAP","MARKER","MENU","MOVE","NAME","NAV","NE","REST"	,"OPTION","PLAN","PLAN","SAVE","SCALE -","SCALE +","SEARCH","SELECT","SETUP","SUSP","SYST","TEST","TGT VS","TO","TYPE","USER","VNAV","VNAV TO","WPT"}


	local abrismenu = {"ACTIV","ADD","ADD LIN","ADD PNT","ARC","AUTO","CALC","CANCEL","CLEAR","CTRL","DELETE","DRAW","EDIT","ENTER","ERBL","FPL","GNSS","HSI","INFO","LOAD","MAP","MARKER","MENU","MOVE","NAME","NAV","NE","REST","OPTION","PLAN","PLAN","SAVE","SCALE -","SCALE +","SEARCH","SELECT","SETUP","SUSP","SYST","TEST","TGT VS","TO","TYPE","USER","VNAV","VNAV TO","WPT",""}
  
	local count
	count = 0
	
	for ii,xx in pairs(abrismenu) do
		if item == xx then
		--logCom(item)
		--logCom(ii)
		return ii 
		end
	end
	
end

function parse_indication(indicator_id)
	local ret = {}
	local li = list_indication(indicator_id)
	if li == "" then return nil end
	local m = li:gmatch("-----------------------------------------\n([^\n]+)\n([^\n]*)\n")
	while true do
        local name, value = m()
        if not name then break end
		ret[name] = value
	end
	return ret
end

function get_UV26()
-- Fonction de lecture de l'afficheur de l'UV26

	local UV26 = parse_indication(7)
			if not UV26 then
				local emptyline = 0
				return emptyline
			
			else 
			local txt = UV26["txt_digits"]
				return txt
			end
end

function get_Weapon()
-- Fonction de lecture du nombre de munitions restantes

	local weapon_data = parse_indication(6)
			if not weapon_data then
				local emptyline = 0 --string.format("%20s", "") -- 20 spaces
				--local emptyline = "miaou"
				return emptyline, emptyline
			
			else 
				local weap_count = weapon_data["txt_weap_count"]
				local cannon_count = weapon_data["txt_cannon_count"]
				return weap_count,cannon_count
										
			end
end

function get_PVI800()
-- Fonction de l'afficheur PVI

	local pvi_data = parse_indication(5)
			if not pvi_data then
				--local emptyline = string.format("%20s", "") -- 20 spaces
				local emptyline = 0 --"miaou"
				return emptyline, emptyline
			
			else 
				local pvi_1 = pvi_data["txt_VIT"]
				local pvi_2 = pvi_data["txt_NIT"]
				local pvi_3 = pvi_data["txt_OIT_PPM"]
				local pvi_4 = pvi_data["txt_OIT_NOT"]
				
				return pvi_1 , pvi_2 , pvi_3 , pvi_4
										
			end
end

function get_Abris()
-- fonction de lecture des codes des 5 boutons de l'Abris

	local abris_data = parse_indication(3)
			if not abris_data then
				local emptyline = 0 --"Miaou"
				--local emptyline = string.format("%20s", "") -- 20 spaces
				-- On retourne ligne vide pour les 5 bouton
				return emptyline, emptyline, emptyline, emptyline, emptyline
			
			else 
				local b1 = abris_data["button1"]
				local b2 = abris_data["button2"]
				local b3 = abris_data["button3"]
				local b4 = abris_data["button4"]
				local b5 = abris_data["button5"]
				
				return b1,b2,b3,b4,b5
										
			end
end



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

if Sioc_OK then

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
-- Fonction au démarrage mission


	KD_Start=function(self)
	
	logCom("  ","\n")
		logCom("--- Export Start ---" ,"\n")
		logCom("  ","\n")
			
	end,

-- Fonction avant chaque image	
	KD_BeforeNextFrame=function(self)
		
	end,
	
-- Fonction après chaque image
	KD_AfterNextFrame=function(self)
		-- Récupération du Time Code, utilisé par le séquenceur pour test et déclancher les séquences rapides et lentes
		-- Incrémentation du compteur de FPS
		fps_counter = fps_counter + 1
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
	
-- Fonction fin de mission
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
