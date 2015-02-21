------------------------------------------------------------------------
--    KaTZ-Pit FC3 functions repo 									  --
------------------------------------------------------------------------

k.mi8.export.slow = function(self)
	k.log("mi8.export.low")
	
	
	-- Attention !!!!!!!! pour boucle lente, le nom est différent que boucle rapide : Device(0) >> MainPanel
		local MainPanel = GetDevice(0)
		-- Test de la précence de Device 0 , comme table  valide
		if type(MainPanel) ~= "table" then
			return ""
		end
		MainPanel:update_arguments()
		
		-- ============== Valeur Test ============================================================		
		--k.sioc.send(22,MainPanel:get_argument_value(277)*1000)		-- K : Fuel Qty Switch		
	
		-- ============== Horloge de Mission ============================================================		
		k.sioc.send(42,LoGetModelTime())-- Heure de la mission
		k.sioc.send(48,MainPanel:get_argument_value(52)*43200)-- Flight Time en secondes (12hr * 60mn * 60sec)
		k.sioc.send(52,MainPanel:get_argument_value(54)*3600)-- Chronometre en secondes (1 tour de cadran = 60mn * 60sec)
		
		
		-- ============== Parametres de Vol (lents) ====================================================

		-- ADI
		local ADI_FF = math.floor(MainPanel:get_argument_value(14))		-- ADI Failure Flag
		local ADI_IDX = MainPanel:get_argument_value(820)*1000	-- ADI Index
		local ADI_FI = 50005000 + 10000 * ADI_FF + ADI_IDX
		k.sioc.send(146,ADI_FI)	
		
		-- ALTIRAD : Low Index Setting sur Canal "Altirad_DX"
		k.sioc.send(124,50005000 + MainPanel:get_argument_value(31) * 1000) 
		
		-- Alarme Low et High , Flag on/off
		local Altirad_HF = 0 -- Alti Rad high alti Alarme (pas utilisé sur Mi-8)
		local Altirad_LF = math.floor(MainPanel:get_argument_value(30)+0.2) -- Alti Rad low alti Alarme
		local Altirad_O = MainPanel:get_argument_value(35) -- Alti Rad On Button
		k.sioc.send(126,555 + Altirad_HF * 100 + Altirad_LF * 10 + Altirad_O)
		
				
		
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


		k.sioc.send(260,Oil_P_Eng)		-- Engine Oil Pressure (L,R)
		k.sioc.send(265,Oil_P_GB)		-- GearBox Oil Pressure
		k.sioc.send(250,Oil_T_Eng)		-- Engine Oil Temp (L,R)
		k.sioc.send(255,Oil_T_GB)		-- GearBox Oil Temp 	

    
		
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
		k.sioc.send(310,APU_V)								-- Chaine Codage Voyants APU (5+A,5+B,5+C,5+D)

		k.sioc.send(315,MainPanel:get_argument_value(412) * 1000)-- APU Type demarrage  (=Start, 1000=Vent, 2000=Crabo)
		
	
		-- ============== Démarrage Moteur ==============================================
		local COL = MainPanel:get_argument_value(204)
		local COR = MainPanel:get_argument_value(206)
		local BRot = MainPanel:get_argument_value(208)
		local CO = 555 + BRot * 100 + COL * 10 + COR

		k.sioc.send(220,CO)	-- Rotor Break + Levier CutOff Left Right

		local Eng_Start_V = 55 + MainPanel:get_argument_value(420) * 10 + MainPanel:get_argument_value(424)
		k.sioc.send(352,Eng_Start_V)-- Voyant Ignition et Start Engine
				
		k.sioc.send(356,MainPanel:get_argument_value(422) * 1000)-- Selecteur demarrage moteur (zero=APU, 1000=Left, 2000=Right, 3000=Up maintenance)
		k.sioc.send(358,MainPanel:get_argument_value(423) * 1000)-- Type demarrage  (=Start, 1000=Vent, 2000=Crabo)


		-- ============== Parametres Fuel (lents)  =======================================================
		local Fuel_qty = MainPanel:get_argument_value(62)* 1000  -- valeur non linéaire à ajuster	
		local Fuel_sel = math.floor(MainPanel:get_argument_value(61) * 10 + 0.2) -- +0.2 pour arrondi selecteur
		local Fuel_data = 50005000 + Fuel_sel*10000 + Fuel_qty
		k.sioc.send(404,Fuel_data) -- Utilisation du canal Fuel Internal Forward

		local Fuel_V1 = MainPanel:get_argument_value(431)	-- Voyant Cross Feed Vanne
		local Fuel_V2 = MainPanel:get_argument_value(427)	-- Voyant Vanne Gauche
		local Fuel_V3 = MainPanel:get_argument_value(429)	-- Voyant Vanne Droit
		local Fuel_V = 555 + Fuel_V1 * 100 + Fuel_V2 * 10 + Fuel_V3
		k.sioc.send(430,Fuel_V)	

		local Fuel_P1 = MainPanel:get_argument_value(441)	-- Voyant Pump Service
		local Fuel_P2 = MainPanel:get_argument_value(442)	-- Voyant Pump Gauche
		local Fuel_P3 = MainPanel:get_argument_value(443)	-- Voyant Pump Droit
		local Fuel_P = 555 + Fuel_P1 * 100 + Fuel_P2 * 10 + Fuel_P3
		k.sioc.send(435,Fuel_P)			
				
			
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
		
		-- k.sioc.send(502,MainPanel:get_argument_value(494) * 1000)-- Position Selecteur Voltmetre DC
		k.sioc.send(504,Elec_SW_DC)								-- Position Switch DC
		k.sioc.send(506,Elec_VDC)								-- Voyant Electric DC
		
		
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
		
				
		-- k.sioc.send(512,MainPanel:get_argument_value(535) * 1000)-- Position Selecteur Voltmetre AC
		k.sioc.send(514,Elec_SW_AC)								-- Position Switch AC
		k.sioc.send(516,Elec_VAC)								-- Voyant Electric AC
		
		--k.sioc.send(530,MainPanel:get_argument_value(539) * 1000)-- Stby Gen Load
		
		-- ============== Status Light et NavLight ========================================================
		local Light_S1 = MainPanel:get_argument_value(333)		-- Position Switch Dome_L
		local Light_S2 = MainPanel:get_argument_value(489)		-- Position Switch Dome_R
		local Light_S3 = MainPanel:get_argument_value(513)		-- Position Switch Nav Light
		local Light_S4 = MainPanel:get_argument_value(514)		-- Position Switch Form Light
		local Light_S5 = MainPanel:get_argument_value(515)		-- Position Switch Blade Tip
		local Light_S6 = MainPanel:get_argument_value(516)		-- Position Switch Strobe
		local Light_S7 = MainPanel:get_argument_value(837)		-- Position Switch Landing Light L
		local Light_S8 = MainPanel:get_argument_value(838)		-- Position Switch Landing Light R
		
		local Light_SW = 55555555 + Light_S7 * 10000000 + Light_S8 * 1000000  + Light_S1 * 100000 + Light_S2 * 10000 + Light_S3 * 1000 + Light_S4 * 100 + Light_S5 * 10 + Light_S6
		k.sioc.send(520,Light_SW)								-- Position Switch Lights
	

		-- ============== Status Eléments Mécaniques ======================================================== WIP : a mettre à jour pour Mi-8
		k.sioc.send(602,MainPanel:get_argument_value(215))-- Porte Cockpit , 0 fermée , 100 ouverte	
		k.sioc.send(620,MainPanel:get_argument_value(881)*1000)-- Wheel brake
		--k.sioc.send(208,MainPanel:get_argument_value(473)*1000)-- brake pressure
		

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
		local Dop_Off = MainPanel:get_argument_value(65)

		local Doppler_data1 = 50005000 + FP_100 * 10000000 + FP_10 * 1000000 + FP_1 * 10000 + DA_100 * 1000 + DA_10 * 100 + DA_1 
		local Doppler_data2 = 50005000 + MA_100 * 10000000 + MA_10 * 1000000 + MA_1 * 100000 + MA_01
		local Doppler_flag = Dop_On + DA_F *10 + FP_F * 100 + Dop_Off * 1000 + 5555
		
		k.sioc.send(672,Doppler_data1)
		k.sioc.send(674,Doppler_data2)
		k.sioc.send(676,Doppler_flag)
				
		-- ============== Parametre Diss15  =======================================================		
		-- Drift and Ground indicator
		local DS_V1 = MainPanel:get_argument_value(796)  	-- Voyant Memory
		local DS_V2 = MainPanel:get_argument_value(795)	-- Shutter de l'indication Distance
		
		local DS_V = 55 + DS_V2 * 10 + DS_V1
		
		k.sioc.send(684,DS_V)	-- Diss15 Memory Voyant + Shutter
		
		-- ============== Parametre Ark 9  =======================================================		
		-- Drift and Ground indicator
		local ARK9_S1 = MainPanel:get_argument_value(469)		-- Selection Main-STBY
		local ARK9_S2 = MainPanel:get_argument_value(444)		-- Selection TLF-TLG
		local ARK9_S3 = math.floor(MainPanel:get_argument_value(446) * 10 + 0.3)	-- Selection OFF COMP ANT LOOP (0 à 3)
		-- ajout de 0.3 avant math.floor pour régler problèmes fréquents d'arrondi de DCS
		local ARK9_S4 = math.floor(MainPanel:get_argument_value(451) * 10 + 0.3)		-- Fine Tune MAIN (-2 à 4)
		local ARK9_S5 = math.floor(MainPanel:get_argument_value(449) * 10 + 0.3)		-- Fine Tune STBY (-2 à 4)
		
		local ARK9_S = 55555 + ARK9_S5 * 10000 + ARK9_S4 * 1000 + ARK9_S3 * 100 + ARK9_S2 * 10 + ARK9_S1
		
		k.sioc.send(662,ARK9_S)   -- Variable Switch ARK-9
		
		
		local ARK9_MF1 = math.floor(MainPanel:get_argument_value(678) * 20 + 0.3) + 1		-- Freq mHz Main
		local ARK9_MF2 = math.floor(MainPanel:get_argument_value(452) * 10 + 0.3)			-- Freq kHz Main
		-- ajout de 0.3 avant math.floor pour régler problèmes fréquents d'arrondi de DCS
		local ARK9_MF =  ARK9_MF1 * 100 + ARK9_MF2 * 10
				
		local ARK9_RF1 = math.floor(MainPanel:get_argument_value(675) * 20 + 0.3)+1		-- Freq Decimal Reserve
		local ARK9_RF2 = math.floor(MainPanel:get_argument_value(450) * 10 + 0.3)		-- Freq Decimal Reserve
		local ARK9_RF =  ARK9_RF1 * 100 + ARK9_RF2 * 10
		
		local ARK9_F =  50005000 + ARK9_RF * 10000 + ARK9_MF
		k.sioc.send(664,ARK9_F)   -- Fréquence ARK-9
		
		
		local ARK9_Signal = math.floor(MainPanel:get_argument_value(681) * 1000)
		local ARK9_Gain = math.floor(MainPanel:get_argument_value(448) * 1000)		
		local ARK9_Data = 50005000 + ARK9_Gain * 10000 + ARK9_Signal
		k.sioc.send(666,ARK9_Data)   -- Signal Reception , Réglage Gain	
		
		
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
		
		k.sioc.send(660,ARKUD)   -- Variable Switch ARK-UD
		
		-- ============== Parametre Selection Ark9-ArkUD  =======================================================		
		-- Position Switches MW/VHF
		k.sioc.send(668,5 + math.floor(MainPanel:get_argument_value(858)+0.2)) 
		
		
		-- ============== Status Armement ==================================================================

		-- Scan du Canon sélectionné -------------------------------------------------------------------
		-- Scan du Panel Armement ----------------------------------------------------------------------	


		-- UV-26 -------------------------------------------------------------------		
		-- Export de l'affichage de l'UV26 ----------------------------------------------------------------------
		local uv26 = k.common.export.uv26()
		local luv = string.len (uv26)
						
		if luv == 0 then 
			uv26 = 0
		end
		
		k.sioc.send(1040,5000 + uv26)
			
		
		
			local UV_On = math.floor(MainPanel:get_argument_value(910) + 0.2)  -- 0 ou 1
			local LedLeft = MainPanel:get_argument_value(892)
			local LedRight = MainPanel:get_argument_value(891)
			local Side_SW = math.floor(MainPanel:get_argument_value(859) * 2 + 0.2)  -- 0 ou 0.5 ou 1
			local Num_SW = math.floor(MainPanel:get_argument_value(913) + 0.2 )  -- 0 ou 1
			
			k.sioc.send(1042, 55555 + UV_On * 10000 + LedLeft * 1000 + LedRight * 100 + Num_SW * 10 + Side_SW)
			
				
				
		
		
				
		-- ============== Module Alarme ==================================================================================		
		
		    
		
end

k.mi8.export.fast = function(self)
	k.log("mi8.export.fast")

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
		
		
		-- ============== Debug =========================================================================
		k.sioc.send(20,lMainPanel:get_argument_value(342)*1000) 
		k.sioc.send(21,lMainPanel:get_argument_value(343)*1000) 
		k.sioc.send(22,lMainPanel:get_argument_value(344)*1000) 
		k.sioc.send(23,lMainPanel:get_argument_value(345)*1000) 

		-- ============== Contrôle de l'appareil =========================================================================		
		--k.sioc.send(123,MainPanel:get_argument_value(191) * 1000)-- Position Collectif , WIP pour Gilles : a mettre à jour pour Mi-8
		--k.sioc.send(22,lMainPanel:get_argument_value(859)*1000)
		
		
		-- ============== Parametres de Vol ===============================================================
		k.sioc.send(102,lMainPanel:get_argument_value(24)*1000) 	-- IAS max speed 350km/hr ... valeur non linéaire à ajuster dans html

		k.sioc.send(112,lMainPanel:get_argument_value(19)*10000) 	-- Alti Baro 0-1000m
		k.sioc.send(120,lMainPanel:get_argument_value(34)*1000) 	-- Alti Radar valeur non linéaire
		
		k.sioc.send(130,lMainPanel:get_argument_value(16)*1000) 	-- Vario (-30m/s , +30 m/s) ... valeur non linéaire à ajuster dans html
		
		k.sioc.send(140,lMainPanel:get_argument_value(12)* -1000)	-- Pitch (ADI)
		k.sioc.send(142,lMainPanel:get_argument_value(13)*1000)	-- Bank ou Roll (ADI)
		
		
		--k.sioc.send(150,lMainPanel:get_argument_value(11)*1000)	-- Boussole
		
		local EUP_S = math.floor(lMainPanel:get_argument_value(22)*1000)	-- EUP_Speed
		local EUP_SS = math.floor(lMainPanel:get_argument_value(23)*1000)	-- EUP_Sideslip
		local EUP = 50005000 + EUP_S * 10000 + EUP_SS
		k.sioc.send(180,EUP)	-- EUP_Data
		
		-- ============== Parametres  ==============================================================
		

		-- ============== Parametres HSI ==================================================================
		
		
		k.sioc.send(152,lMainPanel:get_argument_value(25)*3600) -- CAP (Export 0.1 degrés)
		k.sioc.send(154,lMainPanel:get_argument_value(27)*3600) -- Course (Ecart par rapport à la couronne des caps)
		k.sioc.send(156,lMainPanel:get_argument_value(28)*3600) -- Waypoint (Ecart par rapport à la couronne des caps)
		
				
		-- ============== Parametres ILS ==================================================================
		
		-- ============== Parametres Rotor =================================================================
		
		k.sioc.send(230,lMainPanel:get_argument_value(42)*1100) -- Rotor rpm : max 110
		k.sioc.send(232,lMainPanel:get_argument_value(36)*1000) -- Rotor pitch : gradué de 1° à 15° ( * 14 +1) ... valeur non linéaire à ajuster dans html	
				
				
		-- ============== Parametres Moteur (Fast) ================================================================
		local RPM_L = math.floor(lMainPanel:get_argument_value(40)*1100)		-- rpm left : max 110
		local RPM_R = math.floor(lMainPanel:get_argument_value(41)*1100)		-- rpm right : max 110
		local RPM_data = 50005000 + RPM_L * 10000 + RPM_R
		k.sioc.send(202,RPM_data)									-- Groupage RPM L et R dans une donnée
		
		
		local EngT_L =	math.floor(lMainPanel:get_argument_value(43)*1200)		-- temp left : max 120
		local EngT_R = math.floor(lMainPanel:get_argument_value(45)*1200)		-- temp right : max 120
		local EngT = 50005000 + EngT_L * 10000 + EngT_R
		k.sioc.send(204,EngT)									-- Groupage Température L et R dans une donnée
		
		
		k.sioc.send(210,lMainPanel:get_argument_value(39)*100)		    -- mode moteur Index : gradué de 1 à 10	
		k.sioc.send(212,lMainPanel:get_argument_value(37)*50 + 50)		-- mode moteur Gauche : gradué de 5 à 10 ( * 5 +5)	
		k.sioc.send(213,lMainPanel:get_argument_value(38)*50 + 50)		-- mode moteur Droit : gradué de 5 à 10 ( * 5 +5) 
		-- Variables non groupées pour les simpit
				
		
		-- ============== Parametres APU ===================================================================
		local APU_T = math.floor(lMainPanel:get_argument_value(402) * 1000 )		-- Température APU
		local APU_P = math.floor(lMainPanel:get_argument_value(403)	* 1000 )		-- Pression Air comprimé de l'APU 
		local APU_data = 50005000 + APU_P * 10000 + APU_T				-- +50005000 pour gérer 0 et valeurs négatives
		
		k.sioc.send(300,APU_data)	-- Groupage Pression + Température dans une donnée

		-- ============== Position de l'Avion ===============================================================		
		
		
		-- ============== Données de Navigation ===============================================================		
		
		
		-- ============== Parametre Drift Indicator  =======================================================		
		-- Drift and Ground indicator
		
		local D_A = math.floor(lMainPanel:get_argument_value(791) * 1000 )  -- Diss15 Drift Angle
								
		local DS_C = lMainPanel:get_argument_value(792) * 10 -- Diss15 Speed x00
		local DS_D = lMainPanel:get_argument_value(793) * 10 -- Diss15 Speed 0x0
		local DS_U = lMainPanel:get_argument_value(794) * 10 -- Diss15 Speed 00x
		
		local Drift_Data = 50005000 + D_A * 10000 + math.floor(DS_C) * 100 + math.floor(DS_D) * 10 + math.floor(DS_U)
		k.sioc.send(682,Drift_Data) 
		
		
		-- Sling indicator		
		
		local Sling_UD = lMainPanel:get_argument_value(828)*1000	-- Up-Down	
		local Sling_LR = lMainPanel:get_argument_value(829)*1000	-- Left Right	
		local Sling_FB = lMainPanel:get_argument_value(830)*1000	-- Forward Back	
		local Sling_Off = lMainPanel:get_argument_value(831) + 0.3	-- Voyant Off (+0.3 pour arrondi à 1)	
		
		local Sling_3D = 50005000 + 10000 * math.floor(Sling_Off) + Sling_UD  	-- groupage vario et on/off
		local Sling_2D = 50005000 + 10000 * math.floor(Sling_FB) + Sling_LR					-- groupage avant/arriere et gauche/droite
		
		k.sioc.send(692,Sling_3D) 
		k.sioc.send(694,Sling_2D) 
		   		
		
	end	
	
k.log("export Mi8 chargés")