------------------------------------------------------------------------
--    KaTZ-Pit FC3 functions repo 									  --
------------------------------------------------------------------------

k.export.ka50.slow = function()
	k.debug("ka50.slow")
    
	-- Récupération des données à lire --------------------
	local MainPanel = GetDevice(0)
	
	--Check to see that the device is valid otherwise we return an emty string 
	if type(MainPanel) ~= "table" then
		return ""
	end
	
			
	-- ============== Valeur Alarme ============================================================		
	k.sioc.send(580,MainPanel:get_argument_value(44))		-- MasterWarning		
	
	-- ============== Horloge de Mission ============================================================		
	k.sioc.send(42,LoGetModelTime())-- Heure de la mission en secondes
	k.sioc.send(48,MainPanel:get_argument_value(72)*43200)-- Flight Time en secondes (12hr * 60mn * 60sec)
	k.sioc.send(52,MainPanel:get_argument_value(73)*1800)-- Chronometre en secondes (1 tour de cadran = 30mn * 60sec)
	
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


	k.sioc.send(260,Oil_P_Eng)		-- Engine Oil Pressure (L,R)
	k.sioc.send(265,Oil_P_GB)		-- GearBox Oil Pressure
	k.sioc.send(250,Oil_T_Eng)		-- Engine Oil Temp (L,R)
	k.sioc.send(255,Oil_T_GB)		-- GearBox Oil Temp 	

			
	-- ============== Parametres Fuel (lents) et démarrage ==============================================
	k.sioc.send(404,MainPanel:get_argument_value(137)* 800)-- Fuel Internal Forward : max 80		-- OK
	k.sioc.send(406,MainPanel:get_argument_value(138)* 800)-- Fuel Internal Aft : max 80			-- OK

	local APU_V1 = MainPanel:get_argument_value(162)	-- Voyant APU Valve Open
	local APU_V2 = MainPanel:get_argument_value(168)	-- Voyant APU Oil Pressure
	local APU_V3 = MainPanel:get_argument_value(174)	-- Voyant APU On
	local APU_V4 = MainPanel:get_argument_value(169)	-- APU RPM high
	local APU_V = 5555 + APU_V4 * 1000 + APU_V3 * 100 + APU_V2 * 10 + APU_V1
	k.sioc.send(310,APU_V)								-- Chaine Codage Voyants APU (5+A,5+B,5+C,5+D)
	
	local Fuel_V1 = MainPanel:get_argument_value(211)	-- Voyant Cross Feed Vanne
	local Fuel_V2 = MainPanel:get_argument_value(209)	-- Voyant Vanne Gauche
	local Fuel_V3 = MainPanel:get_argument_value(210)	-- Voyant Vanne Droit
	local Fuel_V = 555 + Fuel_V1 * 100 + Fuel_V2 * 10 + Fuel_V3
	k.sioc.send(430,Fuel_V)	


	--local Fuel_P1 = MainPanel:get_argument_value(441)	-- Voyant Pump Service
	local Fuel_P2 = MainPanel:get_argument_value(200)	-- Voyant Pump Av
	local Fuel_P3 = MainPanel:get_argument_value(201)	-- Voyant Pump Ar
	local Fuel_P = 555 + Fuel_P2 * 10 + Fuel_P3
	k.sioc.send(435,Fuel_P)		

	local Fuel_PE1 = MainPanel:get_argument_value(185)	-- Voyant Pump EL
	local Fuel_PE2 = MainPanel:get_argument_value(202)	-- Voyant Pump IL
	local Fuel_PE3 = MainPanel:get_argument_value(203)	-- Voyant Pump IR
	local Fuel_PE4 = MainPanel:get_argument_value(186)	-- Voyant Pump ER
	local Fuel_PE = 5555 + Fuel_PE1 * 1000 + Fuel_PE2 * 100 + Fuel_PE3 * 10 + Fuel_PE4
	k.sioc.send(440,Fuel_PE)		

	local Eng_Start_V = 5 + MainPanel:get_argument_value(163)  -- Voyant Start Valve
	k.sioc.send(352,Eng_Start_V)-- Voyant Ignition (Mi8) et Start Engine


	local COL = MainPanel:get_argument_value(554)
	local COR = MainPanel:get_argument_value(555)
	local BRot = MainPanel:get_argument_value(556)
	local CO = 555 + BRot * 100 + COL * 10 + COR
	k.sioc.send(220,CO)	-- Rotor Break + Levier CutOff Left Right

	k.sioc.send(356,MainPanel:get_argument_value(416) * 10000)-- Selecteur demarrage moteur (zero=APU, 1000=Left, 2000=Right, 3000=Up maintenance)
	k.sioc.send(358,MainPanel:get_argument_value(415) * 10000)-- Type demarrage  (=Start, 1000=Vent, 2000=Crabo)
	
	-- ============== Parametres Electrique  ===========================================================
	-- Panel Light --------------------------------------------------------------
	-- Position des switch Cockpit Lighting, Projo
	-- ============== Status Light et NavLight ========================================================
	local Light_S1 = MainPanel:get_argument_value(1001)		-- Position Switch Eclairage interne
	local Light_S2 = MainPanel:get_argument_value(300)		-- Position Switch Panel
	local Light_S3 = math.floor(MainPanel:get_argument_value(146)*10 + 0.2)		-- Position Switch Nav Light
	local Light_S4 = math.floor(MainPanel:get_argument_value(297)*10 + 0.2)		-- Position Switch Form Light
	local Light_S5 = MainPanel:get_argument_value(296)		-- Position Switch Blade Tip
	local Light_S6 = MainPanel:get_argument_value(228)		-- Position Switch Strobe
	local Light_S7 = math.floor(MainPanel:get_argument_value(382))		-- Position Switch Landing L onoff, 1=Allumé , 0.5=off , 0=retracté (export > on ne fait pas la diff entre off et retract)
	local Light_S8 = MainPanel:get_argument_value(383)		-- Position Switch Landing projo select
		
	local Light_SW = 55555555 + Light_S7 * 10000000 + Light_S8 * 1000000  + Light_S1 * 100000 + Light_S2 * 10000 + Light_S3 * 1000 + Light_S4 * 100 + Light_S5 * 10 + Light_S6
	k.sioc.send(520,Light_SW)								-- Position Switch Lights	
		
	k.sioc.send(522,MainPanel:get_argument_value(382) * 1000)								-- Position Switch DC
	k.sioc.send(523,MainPanel:get_argument_value(383) * 1000)	
		
		
	-- Panel DC --------------------------------------------------------------
	-- Regroupement des Voyants AC et DC dans deux valeurs export à 8 chiffres	
	
	local Elec_S1 = MainPanel:get_argument_value(264)		-- Position Switch Batterie L
	local Elec_S2 = MainPanel:get_argument_value(543)		-- Position Switch Batterie R
	
	local Elec_S7 = MainPanel:get_argument_value(262)		-- Position Switch Ground DC
		
	local Elec_V4 = MainPanel:get_argument_value(261)		-- Voyant Ground DC
	
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
	k.sioc.send(504,Elec_SW_DC)								-- Position Switch DC
	k.sioc.send(506,Elec_VDC)								-- Voyant Electric DC
	k.sioc.send(514,Elec_SW_AC)								-- Position Switch AC
	k.sioc.send(516,Elec_VAC)								-- Voyant Electric AC
	
	
	
	-- ============== Status Eléments Mécaniques ========================================================
	k.sioc.send(602,MainPanel:get_argument_value(533)*100)-- Porte Cockpit , 0 fermée , 100 ouverte	
	k.sioc.send(620,MainPanel:get_argument_value(571)*1000)-- Wheel brake
	k.sioc.send(622,MainPanel:get_argument_value(473)*1000)-- brake pressure
	

	local Train_1 = MainPanel:get_argument_value(63)-- Train AV Up
	local Train_2 = MainPanel:get_argument_value(59)-- Train L Up
	local Train_3 = MainPanel:get_argument_value(61)-- Train R Up
	local Train_4 = MainPanel:get_argument_value(64)-- Train AV Dwn
	local Train_5 = MainPanel:get_argument_value(60)-- Train L Dwn
	local Train_6 = MainPanel:get_argument_value(62)-- Train R Dwn
	
			
	local Train = 555555 + Train_1 * 100000 + Train_2 * 10000 + Train_3 * 1000 + Train_4 * 100 + Train_5 * 10 + Train_6 
	k.sioc.send(604,Train)

	-- ============== Status Armement ==================================================================

	local TGT_1 = MainPanel:get_argument_value(437)	-- Voyant Autoturn
	local TGT_2 = MainPanel:get_argument_value(438)	-- Voyant TGT Air
	local TGT_3 = MainPanel:get_argument_value(440)	-- Voyant TGT Mov
	local TGT_4 = MainPanel:get_argument_value(439)	-- Voyant TGT For
	local TGT_5 = MainPanel:get_argument_value(441)	-- Voyant TGT Clear	
	local TGT = 55555 + TGT_1 + 10000 + TGT_2 + 1000 + TGT_3 + 100 + TGT_4 + 10 +TGT_5
	k.sioc.send(1018,TGT)
	
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
	
	local Datalink_S1 = math.floor(MainPanel:get_argument_value(328)*10 + 0.2) -- Selecteur ID
	local Datalink_S2 = math.floor(MainPanel:get_argument_value(329)*10 + 0.2) -- Selecteur Data	

	local Datalink_L1 = 5555 + Datalink_T1 * 1000 + Datalink_T2 * 100 + Datalink_T3 * 10 + Datalink_T4
	local Datalink_L2 = 55555 + Datalink_W1 * 10000 + Datalink_W2 * 1000 + Datalink_W3 * 100 + Datalink_W4 * 10 + Datalink_W5
	local Datalink_L3 = 555555+ Datalink_S1 * 100000 + Datalink_S2 * 10000   + Datalink_V * 1000 + Datalink_C * 100 + Datalink_I * 10 + Datalink_S
	k.sioc.send(1002,Datalink_L1)
	k.sioc.send(1004,Datalink_L2)
	k.sioc.send(1006,Datalink_L3)

	-- Scan du Canon sélectionné ------------------------------------------------------------------------
	
	-- Pilototo --------------------------------------------------------------------------------
	local AP_B = math.floor(MainPanel:get_argument_value(330)*10)		-- K : Bank
	local AP_P = math.floor(MainPanel:get_argument_value(331)*10)		-- T : Pitch
	local AP_H = math.floor(MainPanel:get_argument_value(332)*10)		-- H : HDG
	local AP_A = math.floor(MainPanel:get_argument_value(333)*10)		-- B : Alt
	local AP_FD = math.floor(MainPanel:get_argument_value(334)*10)		--  : FD
	local SW_baro = math.floor(MainPanel:get_argument_value(335))		--  : Switch PA-Alti Baro/Rad
	local SW_hdgn = math.floor(MainPanel:get_argument_value(336))		--  : Switch PA-route : Heading/Course
	

	local AP = 5555555 + SW_baro * 1000000 + SW_hdgn * 100000 + AP_B * 10000 + AP_P * 1000 + AP_H * 100 + AP_A * 10 + AP_FD
	k.sioc.send(552,AP)
	
	
	local AP2_H = MainPanel:get_argument_value(175)		--  : Hover
	local AP2_D = MainPanel:get_argument_value(172)		--  : Descente	
	local AP2_ATT = math.floor(MainPanel:get_argument_value(437)*10)		--  : Autoturn		
	local AP2 = 555 + AP2_ATT * 100 + AP2_D * 10 + AP2_H 
	k.sioc.send(554,AP2)
	
	
	
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
	k.sioc.send(1015,Wpn)
	
	-- Export des voyants Master Arm et Canon ----------------------------------------------------------------------
	-- Export des switch réglage Canon ----------------------------------------------------------------------
			
	local Manauto = MainPanel:get_argument_value(403)
	local Burst = math.floor(MainPanel:get_argument_value(400)*10 + 0.2)
	local HeApi = MainPanel:get_argument_value(399)
	local Rof = MainPanel:get_argument_value(398)
	
	local Cannon = MainPanel:get_argument_value(177)
	local MasterArm = MainPanel:get_argument_value(167)
	
	k.sioc.send(1020,555555 + Manauto * 100000 + Burst * 10000 + HeApi * 1000 + Rof * 100 + Cannon * 10 + MasterArm)
	
	-- Export des switch panel weapon secondaire ----------------------------------------------------------------------
			
	local MasterSW = MainPanel:get_argument_value(387)
	local Train = MainPanel:get_argument_value(432)
	local K041 = MainPanel:get_argument_value(433)
	local HMS = MainPanel:get_argument_value(434)
	local Autotrack = MainPanel:get_argument_value(436)
	local Laser = MainPanel:get_argument_value(435)
	local Canonmov = math.floor(MainPanel:get_argument_value(431)*10 + 0.2)
			
	k.sioc.send(1021,5555555 + MasterSW * 1000000 + Train * 100000 + K041 * 10000 + HMS * 1000 + Autotrack * 100 + Laser * 10 + Canonmov)
	
	-- Voyant du panel Arm Secondaire
	local PA_aat = math.floor(MainPanel:get_argument_value(437)* 10 + 0.2) -- Touche Autoturn
	local PA_aaho = math.floor(MainPanel:get_argument_value(439)* 10 + 0.2) -- Touche AA, HeadOn
	local PA_aa = math.floor(MainPanel:get_argument_value(438)* 10 + 0.2)-- Touche Air Air
	local PA_movgnd = math.floor(MainPanel:get_argument_value(440)* 10 + 0.2) -- Touche Moving Ground Target
	local PA_reset = math.floor(MainPanel:get_argument_value(441)* 10 + 0.2) -- Touche Reset
	
	k.sioc.send(1022,55555 + PA_aat * 10000 + PA_aaho * 1000 + PA_aa * 100 + PA_movgnd * 10 + PA_reset)

	-- Export des quantités Rocket et Canon ----------------------------------------------------------------------
	local wpncnt, cannoncnt = k.export.ka50.get_weapon()
	if wpncnt and cannoncnt then
		k.sioc.send(1014,50005000+ wpncnt * 10000 + cannoncnt)
	end
	
	-- Export des réglages Shkval --------------------------------------------------------------------------------
	local SH_Hud = MainPanel:get_argument_value(409) -- Switch Hud Light
	local SH_Black = MainPanel:get_argument_value(404) -- Switch TV Black
	local SH_HMS = math.floor(MainPanel:get_argument_value(405)* 10 + 0.5) -- Rotactor HMS Bright
	local SH_Brt = math.floor(MainPanel:get_argument_value(406)* 10 + 0.5) -- Rotactor Shkval Bright
	local SH_Cont = math.floor(MainPanel:get_argument_value(407)* 10 + 0.5) -- Rotactor Shkval Contrast
	
	
	k.sioc.send(1038,55000000 + SH_Hud * 10000000 + SH_Black * 1000000 + SH_HMS * 10000 + SH_Brt * 100 + SH_Cont)
	
	-- Export de l'affichage du PVI800 ----------------------------------------------------------------------
	local pvi1, pvi2, pvi3, pvi4, pvi5, pvi6, pvi7, pvi8 = k.export.ka50.pvi800()
	if not pvi1 then pvi1 = 0 end
	if not pvi2 then pvi2 = 0 end
	if not pvi3 then pvi3 = 0 end
	if not pvi4 then pvi4 = 0 end
	if not pvi5 then pvi5 = 0 else pvi5 = 1 end
	if not pvi6 then pvi6 = 0 else pvi6 = 1 end
	if not pvi7 then pvi7 = 0 else pvi7 = 1 end
	if not pvi8 then pvi8 = 0 else pvi8 = 1 end
	
	
	k.sioc.send(171,pvi1)
	k.sioc.send(172,pvi2)
	k.sioc.send(173, 5000000 + pvi5 * 100000 + pvi6 * 10000 + pvi7 * 1000 + pvi8 * 100 + pvi3 * 10 + pvi4)
		
	-- Export du clavier PVI800
	local PVI_315 = math.floor(MainPanel:get_argument_value(315)* 10 + 0.2) -- Touche WPT
	local PVI_519 = math.floor(MainPanel:get_argument_value(519)* 10 + 0.2) -- Touche INU RERUN
	local PVI_316 = math.floor(MainPanel:get_argument_value(316)* 10 + 0.2)-- Touche FIX PNT
	local PVI_520 = math.floor(MainPanel:get_argument_value(520)* 10 + 0.2) -- Touche INU PREC
	local PVI_317 = math.floor(MainPanel:get_argument_value(317)* 10 + 0.2) -- Touche AIR FIED
	local PVI_521 = math.floor(MainPanel:get_argument_value(521)* 10 + 0.2) -- Touche INU NORM
	local PVI_318 = math.floor(MainPanel:get_argument_value(318)* 10 + 0.2) -- Touche NAV TGT
	local PVI_522 = math.floor(MainPanel:get_argument_value(522)* 10 + 0.2) -- Touche INIT PNT
	k.sioc.send(175, 55555555 + PVI_315 * 10000000 + PVI_519 * 1000000 + PVI_316 * 100000 + PVI_520 * 10000 + PVI_317 * 1000 + PVI_521 * 100 + PVI_318 * 10 + PVI_522)	
	
	-- Export du clavier PVI800
	local PVI_313 = math.floor(MainPanel:get_argument_value(313)* 10 + 0.2) -- Touche ENTER
	local PVI_314 = math.floor(MainPanel:get_argument_value(314)* 10 + 0.2) -- Touche RESET
	local PVI_319 = math.floor(MainPanel:get_argument_value(319)* 10 + 0.2) -- Touche SELF COOR
	local PVI_320 = math.floor(MainPanel:get_argument_value(320)* 10 + 0.2) -- Touche DTA DH
	local PVI_321 = math.floor(MainPanel:get_argument_value(321)* 10 + 0.2) -- Touche WIND
	local PVI_322 = math.floor(MainPanel:get_argument_value(322)* 10 + 0.2) -- Touche T-HEAD
	local PVI_323 = math.floor(MainPanel:get_argument_value(323)* 10 + 0.2) -- Touche HEAD
	k.sioc.send(176, 5555555 + PVI_313 * 1000000 + PVI_314 * 100000 + PVI_319 * 10000 + PVI_320 * 1000 + PVI_321 * 100 + PVI_322 * 10 + PVI_323)	
	
	-- Export des switches du PVI800
	local PVI_Inu = MainPanel:get_argument_value(325) -- Switch INU
	local PVI_DLink = MainPanel:get_argument_value(326) -- Switch DLink
	local PVI_Select = math.floor(MainPanel:get_argument_value(324)* 10 + 0.2) -- Selecteur
	k.sioc.send(177,550 + PVI_Inu * 100 + PVI_DLink * 10 + PVI_Select)

	k.sioc.send(178,MainPanel:get_argument_value(324)*1000)
	k.sioc.send(179,MainPanel:get_argument_value(320)*1000)

	
	-- Export de l'affichage de l'UV26 ----------------------------------------------------------------------
	local uv26 = k.export.ka50.uv26()
	if uv26 then 
		k.sioc.send(1040,5000 + uv26)
	end
	
	local UV_On = math.floor(MainPanel:get_argument_value(496) + 0.2)  -- 0 ou 1
	local LedLeft = MainPanel:get_argument_value(541)
	local LedRight = MainPanel:get_argument_value(542)
	local Side_SW = math.floor(MainPanel:get_argument_value(36) * 10 + 0.2)  -- 0 ou 0.1 ou 0.2
	local Num_SW = math.floor(MainPanel:get_argument_value(37) * 10 + 0.2)  -- 0 ou 0.1
	
	k.sioc.send(1042, 55555 + UV_On * 10000 + LedLeft * 1000 + LedRight * 100 + Num_SW * 10 + Side_SW)
		
	
	-- ============== Lecture de l'Abris =========================================================================	
			
	local Abris_on = MainPanel:get_argument_value(130)-- On/Off
			
	local c1 = 0
	local c2 = 0
	local c3 = 0
	local c4 = 0
	local c5 = 0
	
	local bout1,bout2,bout3,bout4,bout5  = k.export.ka50.get_abris()
	
		
	if bout5 then 
		c5 = k.export.ka50.abris_ref(bout5)
	end
	
	if bout4 then 
		c4 = k.export.ka50.abris_ref(bout4)
	end
	
	if bout3 then 
		c3 = k.export.ka50.abris_ref(bout3)
	end
	
	if bout2 then 
		c2 = k.export.ka50.abris_ref(bout2)
	end
	
	if bout1 then 
		c1 = k.export.ka50.abris_ref(bout1)
	end
	
		
				
		k.sioc.send(731,50005000 + c1 * 10000 + c2)
		k.sioc.send(732,50005000 + c3 * 10000 + c4)
		k.sioc.send(733,50005000 + Abris_on * 10000 + c5)
	
	
		
			
end

k.export.ka50.fast = function()
    k.debug('ka50 fast')

	-- Récupération des données à lire --------------------
	local lMainPanel = GetDevice(0)
	
	--Check to see that the device is valid otherwise we return an emty string 
	if type(lMainPanel) ~= "table" then
		return ""
	end
	
	
	lMainPanel:update_arguments()
	
	-- ============== Position des Commandes de vol =========================================================================
	-- Stick Roll/pitch Position
	k.sioc.send(80,50005000 + math.floor(lMainPanel:get_argument_value(71)*1000) * 10000 +  math.floor(lMainPanel:get_argument_value(74)*1000))
	-- Rudder + Collective
	k.sioc.send(82,50005000 + math.floor(lMainPanel:get_argument_value(266)* -1000) * 10000 +  math.floor(lMainPanel:get_argument_value(104)*1000))
	
	-- ============== Parametres de Vol ===============================================================
	k.sioc.send(102,lMainPanel:get_argument_value(51)*370) 	-- IAS max speed 350km/hr -- linéaire export valeur vraie
	k.sioc.send(130,lMainPanel:get_argument_value(24)*300) 	-- Vario (-30m/s , +30 m/s) -- linéaire export valeur vraie
	
	k.sioc.send(112,lMainPanel:get_argument_value(87)*10000) -- Alti Baro 1000m
	k.sioc.send(120,lMainPanel:get_argument_value(94)*1000) 	-- Alti Radar valeur non linéaire export rotation aiguille
			
	
	k.sioc.send(140,lMainPanel:get_argument_value(143)*1000)	-- Pitch
	k.sioc.send(142,lMainPanel:get_argument_value(142)*1000)	-- Bank
	
	k.sioc.send(150,lMainPanel:get_argument_value(11)*1000)	-- Boussole
	
	-- ============== Parametres  ==============================================================
	

	-- ============== Parametres HSI ==================================================================
	
	
	k.sioc.send(152,lMainPanel:get_argument_value(112)*3600) -- CAP (Export 0.1 degrés)
	k.sioc.send(156,lMainPanel:get_argument_value(115)*3600) -- Waypoint (Ecart par rapport à la couronne des caps)
	k.sioc.send(154,lMainPanel:get_argument_value(118)*3600) --5 Course (Ecart par rapport à la couronne des caps)
	
	
	local WP_Dist_1 = math.floor(lMainPanel:get_argument_value(528)*10)
	local WP_Dist_10 = math.floor(lMainPanel:get_argument_value(527)*10)
	local WP_Dist_100 = math.floor(lMainPanel:get_argument_value(117)*10)
	
	k.sioc.send(162,WP_Dist_100*1000 + WP_Dist_10*100 + WP_Dist_1*10) -- Waypoint Distance 0.1km
	
	-- ============== Parametres ILS ==================================================================
	
	-- ============== Parametres Rotor =================================================================
	
	k.sioc.send(230,lMainPanel:get_argument_value(52)*110) -- Rotor rpm : max 110
	k.sioc.send(232,lMainPanel:get_argument_value(53)*140 + 10) -- Rotor pitch : gradué de 1° à 15° ( * 14 +1)	
			
			
	-- ============== Parametres Moteur (Fast) ================================================================
	local RPM_L = math.floor(lMainPanel:get_argument_value(135)*1100)		-- rpm left : max 110
	local RPM_R = math.floor(lMainPanel:get_argument_value(136)*1100)		-- rpm right : max 110
	local RPM_data = 50005000 + RPM_L * 10000 + RPM_R
	k.sioc.send(202,RPM_data)									-- Groupage RPM L et R dans une donnée
	
	
	local EngT_L =	math.floor(lMainPanel:get_argument_value(133)*1200)		-- temp left : max 120
	local EngT_R = math.floor(lMainPanel:get_argument_value(134)*1200)		-- temp right : max 120
	local EngT = 50005000 + EngT_L * 10000 + EngT_R
	k.sioc.send(204,EngT)									-- Groupage Température L et R dans une donnée
	
	
	k.sioc.send(210,lMainPanel:get_argument_value(592)*100)			-- mode moteur : index gradué de 0 à 10					
	k.sioc.send(212,lMainPanel:get_argument_value(234)*50 + 50)		-- mode moteur : gradué de 5 à 10 ( * 5 +5)	
	k.sioc.send(213,lMainPanel:get_argument_value(235)*50 + 50)		-- mode moteur : gradué de 5 à 10 ( * 5 +5)
	-- Variables non groupées pour les simpit		
	
	-- ============== Parametres APU ===================================================================
	k.sioc.send(300,50005000 + lMainPanel:get_argument_value(6) * 900)-- Température APU : max 900°
	
end

k.export.ka50.abris_ref = function(item)


	local abrismenu = {"ACTIV","ADD","ADD LIN","ADD PNT","ARC","AUTO","CALC","CANCEL","CLEAR","CTRL","DELETE","DRAW","EDIT","ENTER","ERBL","FPL","GNSS","HSI","INFO","LOAD","MAP","MARKER","MENU","MOVE","NAME","NAV","NE","REST","OPTION","PLAN","PLAN","SAVE","SCALE-","SCALE+","SEARCH","SELECT","SETUP","SUSP","SYST","TEST","TGT VS","TO","TYPE","USER","VNAV","VNAV TO","WPT",""}
  
	for ii,xx in pairs(abrismenu) do
		if item == xx then
		return ii 
		end
	end
	
	return 48
	
	
end

k.export.ka50.get_weapon = function()
-- Fonction de lecture du nombre de munitions restantes

	local weapon_data = k.common.parse_indication(6)
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

k.export.ka50.pvi800 = function()
-- Fonction de l'afficheur PVI

	local pvi_data = k.common.parse_indication(5)
			if not pvi_data then
				--local emptyline = string.format("%20s", "") -- 20 spaces
				local emptyline = 0 --"miaou"
				return emptyline, emptyline
			
			else 
				
				local pvi_1 = pvi_data["txt_VIT"]
				local pvi_2 = pvi_data["txt_NIT"]
				local pvi_3 = pvi_data["txt_OIT_PPM"]
				local pvi_4 = pvi_data["txt_OIT_NOT"]
				local pvi_5 = pvi_data["txt_VIT_apostrophe1"]
				local pvi_6 = pvi_data["txt_VIT_apostrophe2"]
				local pvi_7 = pvi_data["txt_NIT_apostrophe1"]
				local pvi_8 = pvi_data["txt_NIT_apostrophe2"]
				
				
				return pvi_1 , pvi_2 , pvi_3 , pvi_4 , pvi_5 , pvi_6 , pvi_7 , pvi_8
										
			end
end

k.export.ka50.get_abris = function ()
-- fonction de lecture des codes des 5 boutons de l'Abris

	local abris_data = k.common.parse_indication(3)
			if not abris_data then
				local emptyline = 0 --"Miaou"
				--local emptyline = string.format("%20s", "") -- 20 spaces
				-- On retourne ligne vide pour les 5 boutons
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

k.export.ka50.uv26 = function()
-- Fonction de lecture de l'afficheur de l'UV26

	local UV26 = k.common.parse_indication(7)
	if not UV26 then
		local emptyline = 0
		return emptyline
	else 
		local txt = UV26["txt_digits"]
		return txt
	end
end

k.info("KTZ_SIOC_KA50 chargé")