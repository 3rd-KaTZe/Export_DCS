k.common.getXYCoords = function (inLatitudeDegrees, inLongitudeDegrees)
		-- args: 2 numbers // Return two value in order: X, Y
        local pi = 3.141592

		local zeroX = 5000000
		local zeroZ = 6600000

		local centerX = 11465000 - zeroX --circle center
		local centerZ =  6500000 - zeroZ

		local pnSxW_X = 4468608 - zeroX -- point 40dgN : 24dgE
		local pnSxW_Z = 5730893 - zeroZ

		local pnNxW_X = 5357858 - zeroX -- point 48dgN : 24dgE
		local pnNxW_Z = 5828649 - zeroZ

--		local pnSxE_X = 4468608 - zeroX -- point 40dgN : 42dgE
--		local pnSxE_Z = 7269106 - zeroZ
--
--		local pnNxE_X = 5357858 - zeroX -- point 48dgN : 42dgE
--		local pnNxE_Z = 7171350 - zeroZ

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
	
	-- Fonction d'extraction des informations des zones de texte	
k.common.parse_indication = function (indicator_id)
	local ret = {}
	local li = list_indication(indicator_id)  -- list_indication is a DCS function extracting texte being displayed in the cockpit
	if li == "" then return nil end
	local m = li:gmatch("-----------------------------------------\n([^\n]+)\n([^\n]*)\n")
	while true do
		local name, value = m()
		if not name then break end
		ret[name] = value
	end
	return ret
end

k.common.uv26 = function()
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

k.info("common.lua chargé")