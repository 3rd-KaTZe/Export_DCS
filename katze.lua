exportFC3done = false
function rendre_hommage_au_grand_Katze()
	la_petite_chatte = false
	local lDevice = GetDevice(0)
	if type(lDevice) == "table" then
		local myInfo = LoGetSelfData()
		if myInfo.Name ~= gCurrentAircraft then
			gCurrentAircraft = myInfo.Name
			if gCurrentAircraft == "A-10C" then
			elseif gCurrentAircraft == "Ka-50" then
				la_petite_chatte = '/Scripts/KTZ_SIOC_KA50.lua'
			elseif gCurrentAircraft == "Mi-8MT" then
				la_petite_chatte = '/Scripts/KTZ_SIOC_Mi8.lua'
			elseif gCurrentAircraft == "UH-1H" then
				la_petite_chatte = '/Scripts/KTZ_SIOC_UH1.lua'
			end
		end
	elseif not exportFC3done then
		exportFC3done = true
		la_petite_chatte = '/Scripts/KTZ_SIOC_FC3.lua'
	end
	if la_petite_chatte then
		if remplir_la_gamelle_de(la_petite_chatte) then
			changer_la_litiere_de(la_petite_chatte)
		then
	end
end

function remplir_la_gamelle_de(chaton)
	local f=io.open(name,'r')
	if f~=nil then io.close(f) return  true else return false end
end

function changer_la_litiere_de(vieux_matou)
	dofile(lfs.writedir()..vieux_matou);
end