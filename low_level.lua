k.common = {}
k.common.export = {}

k.common.export.getXYCoords = function (inLatitudeDegrees, inLongitudeDegrees) 
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
	
	-- Fonction d'extraction des informations des zones de texte	
k.common.export.parse_indication = function (indicator_id)
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

k.common.export.uv26 = function()
-- Fonction de lecture de l'afficheur de l'UV26

	local UV26 = k.common.export.parse_indication(7)
	if not UV26 then
		local emptyline = 0
		return emptyline
	else 
		local txt = UV26["txt_digits"]
		return txt
	end
end

k.file_exists = function(p)
	local f=io.open(p,'r')
	if f~=nil then io.close(f) return  true else return false end
end

k.update_fps=function()
	return -- fonction complètement buggée. J'avais du que j'aurais du réfléchir pour celle là ... à refaire, pas grave =) Miaou !
	
	-- k.loop.fps.tot = k.loop.fps.tot + k.loop.fps_counter -- Compteur du total de frames
	
	-- -- log(string.format("*** Fonction K_AtInterval @= %.2f",CurrentTime,"\n"))
	-- -- Classement du nombre de frames de l'intervalle de temps dans l'histogramme
	-- if k.loop.fps.counter < 10 * k.loop.sample.fps then
	-- 	k.loop.fps[10] = k.loop.fps[10] + k.loop.fps.counter
	-- elseif k.loop.fps.counter < 20 * SamplingPeriod then
	-- 	k.loop.fps[20] = k.loop.fps[20] + k.loop.fps.counter
	-- elseif k.loop.fps.counter < 30 * SamplingPeriod then
	-- 	k.loop.fps[30] = k.loop.fps[30] + k.loop.fps.counter
	-- elseif k.loop.fps.counter < 40 * SamplingPeriod then
	-- 	k.loop.fps[40] = k.loop.fps[40] + k.loop.fps.counter
	-- elseif k.loop.fps.counter < 50 * SamplingPeriod then
	-- 	k.loop.fps[50] = k.loop.fps[50] + k.loop.fps.counter
	-- elseif k.loop.fps.counter < 60 *SamplingPeriod then
	-- 	k.loop.fps[60] = k.loop.fps[60] + k.loop.fps.counter
	-- else
	-- 	k.loop.fps[70] = k.loop.fps[70] + k.loop.fps.counter
	-- end
end