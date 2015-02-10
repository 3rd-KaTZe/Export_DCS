exportFC3done = false
function rendre_hommage_au_grand_Katze()
	local lDevice = GetDevice(0)	
	if type(lDevice) == "table" then
		local myInfo = LoGetSelfData()
		if myInfo.Name ~= gCurrentAircraft then
			gCurrentAircraft = myInfo.Name
			if gCurrentAircraft == "A-10C" then
			elseif gCurrentAircraft == "Ka-50" then
				dofile(lfs.writedir()..'/Scripts/KTZ_SIOC_KA50.lua');
			elseif gCurrentAircraft == "Mi-8MT" then
				dofile(lfs.writedir()..'/Scripts/KTZ_SIOC_Mi8.lua');
			elseif gCurrentAircraft == "UH-1H" then
				dofile(lfs.writedir()..'/Scripts/KTZ_SIOC_UH1.lua');
			elseif gCurrentAircraft == "P-51D" then
			else
				dofile(lfs.writedir()..'/Scripts/KTZ_SIOC_FC3.lua');
			end   
		end  
	elseif not exportFC3done then
		exportFC3done = true
		dofile(lfs.writedir()..'/Scripts/KTZ_SIOC_FC3.lua');
	end
end