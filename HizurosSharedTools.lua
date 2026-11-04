
local MAJOR, MINOR = "HizurosSharedTools", tonumber((gsub("@project-version@","r",""))) or 9999;
---@class HizurosSharedTools
local lib = LibStub:NewLibrary(MAJOR, MINOR);
if not lib then return end

local _G,tostringall,tonumber,rawset,type = _G,tostringall,tonumber,rawset,type
local issecretvalue,canaccessvalue = issecretvalue or function() return false end,canaccessvalue or function() return true end

local LC = LibStub("LibColors-1.0");
local C = LC.color;
LC.colorset({
	["curseforge"] = "ff8000", --"F16436"
	["github"] = "adbac7",
	["paypal"] = "44dd44",
});

local L = setmetatable({},{
	__index = function(t,k)
		local v = tostring(k);
		rawset(t,k,v);
		return v;
	end
});

L["ThxSpecial"] = "Special thanks at..."
L["ThxLocale"] = "Thanks for the translations..."
L["ThxSupport"] = "Thanks for the support..."
L["ThxDonation"] = "Thanks for the donation..."
L["githubPR"] = "For pull request(s) on github"
L["DonationPP"] = "|cff375388Pay|cff5a9de0Pal|r"
L["DonationGH"] = "Github"
L["DonationPA"] = "Patreon"

if LOCALE_deDE then
	L["ThxSpecial"] = "Speziellen Dank an..."
	L["ThxLocale"] = "Danke für die Übersetzungen..."
	L["ThxSupport"] = "Danke für die Unterstützung..."
	L["ThxDonation"] = "Danke für die Spende..."
	L["Thanks at..."] = "Danke an..."
end

for _, code in ipairs({"DEDE","FRFR","ITIT","ESES","ESMX","PTPT","PTBR","KOKR","RURU","ZHCN","ZHTW"})do
	L["Language"..code] = _G[code] or _G["LOCALE_DISPLAY_NAME_"..code] or _G["LFG_LIST_LANGUAGE_"..code]
end

--== colorized print ==--
do
	local defaultColors = {"20b0ff","00ff00","ff6060","44ffff","ffff00","ff8800","ff44ff","ffffff"};
	-- If you want your own colors add a table named printColors in your addon namespace.
	-- count of entries is not limited.

	-- Patch 11.1 - Blizzard filtering all messages to console (ConsolePrint/C_Log.LogMessage) from third party addons.
	-- Wonderful tool to avoid bothering players with accidentally forgotten debug messages.
	-- But I have to get around Console Print. I hope that won't be taken away from me too.
	local function _ConsolePrint(...)
		if not _G["DeveloperConsole"] then
			return
		end
		DeveloperConsole:AddMessage(string.join(" ",...))
	end

	local function colorize(ns,...)
		if not ns.addon then
			_ConsolePrint(MAJOR,debugstack());
		end
		local colors = ns.printColors or defaultColors; --
		local t,c,a1 = {tostringall(...)},1,...;
		if type(a1)=="boolean" then tremove(t,1); end
		if a1~=false then
			tinsert(t,1,"|cff"..colors[1]..((a1==true and ns.addon_short) or (a1=="||" and "||") or ns.addon or "oops").."|r"..(a1~="||" and HEADER_COLON or ""));
			c=2;
		end
		for i=c, #t do
			if issecretvalue(t[i]) and not canaccessvalue(t[i]) then
				t[i] = "[secret value]";
			end
			if not t[i]:find("\124c") then
				t[i],c = "|cff"..colors[c]..t[i].."|r", c<#colors and c+1 or 1;
			end
		end
		return unpack(t);
	end

	local function ns_print(ns,...)
		print(colorize(ns,...));
	end

	local function ns_debug(ns,...)
		_ConsolePrint(date("|cff999999%X|r"),colorize(ns,"<debug>",...));
	end

	local dumpTable
	local insStr = "  "
	function dumpTable(t,res,inset)
		local tmp,isAssoc,i,ins = {},false,"  ";
		res,inset = res or {},inset or 0;
		ins = strrep(insStr,inset);

		if inset==0 then
			tinsert(res,ins.."{");
		end

		for k,v in pairs(t)do
			local tk = type(k)
			if type(v)=="table" then
				if tk=="number" then
					tinsert(res,ins..i.."{ -- ["..k.."]");
				else
					tinsert(res,ins..i.."["..k.."] = {");
				end
				dumpTable(v,res,inset+1);
				tinsert(res,ins..i.."},");
			elseif tk=="number" then
				tinsert(res,ins..i..tostring(v)..", -- ["..k.."]");
			else
				tinsert(res,ins..i.."["..k.."] = "..tostring(v))
			end
		end

		if inset==0 then
			tinsert(res,ins.."},");
		end

		return res;
	end

	local function ns_debugTable(ns, tbl)
		if type(tbl)~="table" then
			ns_debug(ns,tbl)
			return;
		end
		local res = dumpTable(tbl);
		for i=1, #res do
			ns_debug(ns, res[i])
		end
	end

	local function ns_debugPrint(ns,...)
		if not ns.debugMode then return end
		print(colorize(ns,"<debug>",...));
	end

	function lib.debug(...)
		_ConsolePrint(date("|cff999999%X|r"),colorize({addon=MAJOR},"<debug>",...));
	end

	--- Add print functions to given addon namespace
	---@param ns table AddOn namespace
	---@param addon string AddOn name
	---@param short string AddOn short name
	function lib.RegisterPrint(ns,addon,short)
		ns.addon,ns.addon_short = addon,short;
		ns.print,ns.debug,ns.debugPrint,ns.debugTable = ns_print,ns_debug,ns_debugPrint,ns_debugTable;
		ns.deprecated = lib.deprecated;
	end
end

-- for internal use
local ns = {debugMode=true};
lib.RegisterPrint(ns,MAJOR,"HzST");

--@do-not-package@
if not HizurosSharedTools then
	HizurosSharedTools = ns
end
if not HST then
	HST = ns
end
--@end-do-not-package@


-- misc functions
function lib.C_Table_Search(find)
	local n,c="C_Table_Search",0;
	lib.debug(n,"results for",find)
	for gname, gvalue in pairs(_G)do
		if tostring(gname):match("^C_") and type(gvalue)=="table" then
			for fname in pairs(_G[gname]) do
				if fname:match(find) then
					c=c+1;
					lib.debug(n,c,gname,fname)
				end
			end
		end
	end
end

local function pairsByKeys(tbl)
	local keys = {}
	for k in pairs(tbl)do
		tinsert(keys,k)
	end
	table.sort(keys)
	local i=0
	local iter = function()
		i=i+1
		if keys[i] == nil then
			return nil
		end
		return keys[i], table.concat(tbl[keys[i]],", ")
	end
	return iter
end

--== shared credits page ==--
do
	local myAddOns = {
		"AFK_fullscreen","AuctionSellers","BestSellButton","Broker_Everything","CommunityInfo",
		"FarmHud","FollowerLocationInfo","GarrisonRandomNPCs","GatherMate2_ImportExport","GuildApplicantTracker",
		"HizurosToolbox","HzFontPack1","LFR [of the past]","QuickRoutes","StayClassy","TooltipRealmInfo",
		-- don't sort by name. add new at the end
	};

	local supporter = { -- {<color>,<name>}, <localizations>, <donations>, <otherSupportTypes>, <special text>,
		-- special mentions
		--{"battlenet","liquidbase",false,"/", "deathknight","Merith", false,"(Author of DuffedUI)"},false,false,false,{"For idea and first code to add quest level to quest tracker :)",HT},
		--{"battlenet","pas06",false,"/", "curseforge","Bullseiify"},{"deDE",GAT},false,false,{"For idea to the keystroke replace function",HT},

		-- donations
		{"paypal","Chris"}, false, {"PP",true}, false,false,
		{"paypal","Michael"}, false, {"PP",true}, false, false,
		{"paypal","Nanci"}, false, {"PP",true}, false, false,

		--{"curseforge","ZamestoTV"},		{"ruRU",AS,GMIE},false,false,false,
	}

	local creditTemplate = {
		type="group", order=-1,
		name=L["Credits"],
		args={
			thanks={
				type="description", order=0, fontSize="large",
				name=C("dkyellow",L["Thanks at..."])
			},
			thanksLine={
				type="header", order=1,
				name=""
			},
			special={
				type="group", order=3, inline=true, name="", hidden=true,
				args={
					header = { type="header", order=1, name=L["ThxSpecial"] },
					names = { type="group", order=2, name="", args={} }
				},
			},
			support={
				type="group", order=3, inline=true, name="", hidden=true,
				args={
					header = { type="header", order=1, name=L["ThxSupport"] },
					names = { type="group", order=2, name="", args={} }
				},
			},
			donate={
				type="group", order=3, inline=true, name="", hidden=true,
				args={
					header = { type="header", order=1, name=L["ThxDonation"] },
					names = { type="group", order=2, name="", args={} }
				},
			},
			locale={
				type="group", order=3, inline=true,name="", hidden=true,
				args={
					header = { type="header", order=1, name=L["ThxLocale"] },
					names = { type="group", order=2, name="", args={} }
				},
			}
		}
	};

	local function Supporter_GetName(entry)
		local name = {};
		if type(entry)=="table" then
			for n=1, #entry, 2 do
				local color,nameStr = entry[n], entry[n+1];
				if color then
					tinsert(name,C(color,nameStr));
				else
					tinsert(name,nameStr);
				end
			end
		else
			tinsert(name,entry);
		end
		return table.concat(name," ");
	end

	local function forThisAddon(lst, addonStr)
		if lst[2]==true then
			return true
		end
		for i=2, #lst do
			if myAddOns[lst[i]]==addonStr then
				return true
			end
		end
	end

	local function AddSupporter(tbl,supps,addon)
		local libTbl=false
		if supps==true then
			supps,libTbl = supporter,true
		end
		local isNotEmpty = false
		local sectionKeys = {"locale","donate","support","special"}
		for s=1, #supps, 5 do
			local name = Supporter_GetName(supps[s])
			for i=1, 4 do
				local section = sectionKeys[i]
				local data = supps[s+i]
				if data and not (libTbl and not forThisAddon(data,addon)) then
					if not tbl[section] then
						tbl[section] = {}
					end
					if not tbl[section][data[1]] then
						tbl[section][data[1]] = {}
					end
					tinsert(tbl[section][data[1]],name)
					isNotEmpty=true
				end
			end
		end
		return isNotEmpty
	end

	local sectionName = {
		locale=function(code)
			code = code:upper()
			if code=="PTPT" then
				-- blizzard using on eu clients LFG_LIST_LANGUAGE_PTBR instead of LFG_LIST_LANGUAGE_PTPT
				code = "PTBR"
			end
			return L["Language"..code]
		end,
		donate=function(key) return L["Donation"..key] end,
		default=function(key) return rawget(L,key) or key end
	}

	-- Add custom credit
	---@param addon string
	---@param opts? table
	function lib.CreditsToHTML(addon,opts)
		local htmlStr = ""
		local sectionHeader = {special="ThxSpecial",locale="ThxLocale",support="ThxSupport",donate="ThxDonation"}
		opts = opts or {}
		if not opts.sectionHeader then
			opts.sectionHeader = "<h2>%s<h2>"
		end
		if not opts.sectionName then
			opts.sectionName = "<h3>%s</h3>"
		end

		-- add supporter
		local sections = {}
		local isNotEmpty = false;
		if AddSupporter(sections, true, addon) then
			isNotEmpty = true
		end
		if (opts and opts.supporter and AddSupporter(sections, opts.supporter, addon)) then
			isNotEmpty = true
		end
		if isNotEmpty then
			for sectionKey,section in pairs(sections)do
				htmlStr = htmlStr .. opts.sectionHeader:format(L[sectionHeader[sectionKey]])
				local nameFunction = sectionName[sectionKey] or sectionName.default
				for key,names in pairsByKeys(section) do
					htmlStr = htmlStr..opts.sectionName:format(nameFunction(key)).."<p>"..names.."</p>"
				end
				htmlStr = htmlStr .. "<br />"
			end
		end
		return htmlStr
	end

	-- Add custom credit
	---@param addon string
	---@param optionTable? table
	---@param opts? table
	function lib.AddCredit(addon,optionTable,opts)
		local credit = CopyTable(creditTemplate);

		if type(opts)=="table" then
			if opts.inline==true then
				credit.inline = true
			end
			if tonumber(opts.order) then
				credit.order = opts.order
			end
		end

		-- add supporter
		local sections = {}
		local isNotEmpty = false;
		if AddSupporter(sections, true, addon) then
			isNotEmpty = true
		end
		if (opts and opts.supporter and AddSupporter(sections, opts.supporter, addon)) then
			isNotEmpty = true
		end
		if isNotEmpty then
			for sectionKey,section in pairs(sections)do
				local nameFunction,order = sectionName[sectionKey] or sectionName.default,1
				for key,names in pairsByKeys(section) do
					credit.args[sectionKey].args.names.args["header"..key] = {type="description", order=order, name=nameFunction(key), fontSize="large" }
					credit.args[sectionKey].args.names.args["names"..key] = {type="description", order=order+1, name=names, fontSize="medium"}
					order=order+2
				end
				if order>1 then
					credit.args[sectionKey].hidden=false
				end
			end
			if credit.args.thanks then
				credit.args.thanks.hidden=true
				credit.args.thanksLine.hidden=true
			end
		end

		-- add to option table
		if type(optionTable)=="table" then
			if optionTable.type=="group" then
				optionTable.args=credit.args;
			else
				optionTable.credit = credit;
			end
		else
			-- add own sub option table
			credit.name = addon.." / "..L["Credits"]
			LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(addon.."/Credits", credit);
			LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addon.."/Credits", "Credits", addon);
		end
	end
end

--== Blizz option panel functions ==--
do
	---@param opts table
	function lib.BlizzOptions_ExpandOnShow(opts)
		if opts.hasExpandOnShowHook then return end
		--opts:HookScript("OnShow", BlizzOptions_ExpandOnShowHook);
		opts.hasExpandOnShowHook = true;
	end

	---@param panel table
	function lib.InterfaceOptionsFrame_OpenToCategory(panel)
		Settings.OpenToCategory(panel)
	end
end

--== Compatibility between clients ==--
do
	lib.deprecated = {
		C_QuestLog = {
			GetInfo = function(questLogIndex)
				if C_QuestLog and C_QuestLog.GetInfo then
					return C_QuestLog.GetInfo(questLogIndex)
				end
				local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isStory, isHidden, isScaling  = GetQuestLogTitle(questLogIndex);
				if type(suggestedGroup)=="string" then
					suggestedGroup = tonumber(suggestedGroup) or 0; -- problem on bc classic client?
				end
				return {
					frequency = frequency,
					hasLocalPOI = hasLocalPOI,
					isAutoComplete = isComplete,
					isCollapsed = isCollapsed,
					isHeader = isHeader,
					isHidden = isHidden,
					isOnMap = isOnMap,
					isScaling = isScaling,
					isStory = isStory,
					isTask = isTask,
					level = level,
					questID = questID,
					questLogIndex = questLogIndex,
					startEvent = startEvent,
					suggestedGroup = suggestedGroup,
					title = title,
					-- dummies. not present in old function
					campaignID = 0,
					difficultyLevel = 0,
					isBounty = false,
					isLegendarySort = false,
					overridesSortOrder = false,
					readyForTranslation = false,
					useMinimapHeader = false,
				};
			end,
			GetQuestTagInfo = function(questID)
				if C_QuestLog and C_QuestLog.GetQuestTagInfo then
					return C_QuestLog.GetQuestTagInfo(questID)
				end
				-- 10/22/2023: Not present in Classic and Classic Era
				local tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex, displayTimeLeft = GetQuestTagInfo(questID);
				return {
					tagID = tagID,
					tagName = tagName,
					worldQuestType = worldQuestType,
					quality = rarity,
					isElite = isElite,
					tradeskillLineID = tradeskillLineIndex,
					displayExpiration = displayTimeLeft
				};
			end,
		},

		C_Reputation = {
			_GetFactionData = function(i,fSuffix)
				if C_Reputation and C_Reputation.GetFactionInfo then
					local info = C_Reputation.GetFactionInfo(i)
					if type(info)=="table" then
						return info;
					end
				end
				local fName = "GetFactionInfo"..(fSuffix=="ID" and "ByID" or "");
				if not _G[fName] then
					return;
				end
				local info = {};
				info.name,info.description,info.reaction,info.currentReactionThreshold,info.nextReactionThreshold,info.currentStanding,info.atWarWith,
				info.canToggleAtWar,info.isHeader,info.isCollapsed,info.hasRep,info.isWatched,info.isChild,
				info.factionID,info.hasBonusRepGain,info.canBeLFGBonus = _G["GetFactionInfo"..(fSuffix=="ID" and "ByID" or "")](i)
				if not info.name then
					return;
				end
				return info
			end,
			GetFactionDataByIndex = function(index) -- new in 11.0
				if C_Reputation and C_Reputation.GetFactionDataByIndex then
					return C_Reputation.GetFactionDataByIndex(index)
				end
				return lib.deprecated.C_Reputation._GetFactionData(index,"Index")
			end,
			GetFactionDataByID = function(id) -- new in 11.0
				if C_Reputation and C_Reputation.GetFactionDataByID then
					return C_Reputation.GetFactionDataByID(id)
				end
				return lib.deprecated.C_Reputation._GetFactionData(id,"ID");
			end,
			GetNumFactions = function() -- new in 11.0
				if C_Reputation and C_Reputation.GetNumFactions then
					return C_Reputation.GetNumFactions()
				end
				return GetNumFactions()
			end,
			GetWatchedFactionData = function(...) -- new in 11.0
				if C_Reputation and C_Reputation.GetWatchedFactionData then
					return C_Reputation.GetWatchedFactionData(...)
				end
				local _, _, _, _, _, factionID = GetWatchedFactionInfo()
				return lib.deprecated.C_Reputation.GetFactionDataByID(factionID);
			end,
			ExpandFactionHeader = function(...) -- new in 11.0
				if C_Reputation and C_Reputation.ExpandFactionHeader then
					return C_Reputation.ExpandFactionHeader(...)
				end
				ExpandFactionHeader(...)
			end,
			CollapseFactionHeader = function(...) -- new in 11.0
				if C_Reputation and C_Reputation.CollapseFactionHeader then
					return C_Reputation.CollapseFactionHeader(...)
				end
				CollapseFactionHeader(...)
			end
		},

		C_Spell = {
			GetSpellIcon = function(...)
				if C_Container and C_Spell.GetSpellIcon then
					return C_Spell.GetSpellIcon(...)
				end
				return GetSpellIcon(...)
			end

		},

		C_Item = {
			GetItemStats = function(...)
				if C_Container and C_Item.GetItemStats then

					return C_Item.GetItemStats(...)
				end
				return GetItemStats(...)
			end,
			GetItemCooldown = function(...)
				if C_Item and C_Item.GetItemCooldown then
					return C_Item.GetItemCooldown(...)
				end
				return GetItemCooldown(...)
			end,

		},

		global = {
			UnitInVehicle = function() -- speed
				if UnitInVehicle then
					return UnitInVehicle()
				end
				return false;
			end,
		},

		C_AddOns = {
			GetAddOnMemoryUsage = function(...)
				if C_AddOns and C_AddOns.GetAddOnMemoryUsage then
					return C_AddOns.GetAddOnMemoryUsage(...)
				end
				return GetAddOnMemoryUsage(...)
			end
		},
	}

	local dummyF = function() end
	local dummyMT = {}
	function dummyMT.__index(t,k)
		lib.debug("deprecated-api missing table function",t.__parent,k,debugstack());
		rawset(t,k,dummyF);
		return dummyF;
	end

	setmetatable(lib.deprecated,{
		__index = function(t,k)
			lib.debug("deprecated-api missing table",k)
			local d = setmetatable({__parent=k},dummyMT);
			rawset(t,k,d);
			return d;
		end
	});

	for k,v in pairs(lib.deprecated)do
		if type(v)=="table" then
			v.__parent = k;
			setmetatable(v,dummyMT)
		end
	end

	if WOW_PROJECT_ID~=WOW_PROJECT_MAINLINE then
		local current = WOW_PROJECT_ID==WOW_PROJECT_CLASSIC and "era" or "classic"
		for name1, funcs in pairs(lib.deprecated) do
			if type(funcs)=="function" then
				if _G[name1] then
					lib.debug("deprecated-api ("..current..")",name1);
				end
			else
				for name2 in pairs(funcs) do
					if _G[name1] and type(_G[name1][name2])=="function" then
						lib.debug("deprecated-api ("..current..")",name1,name2);
					end
				end
			end
		end
	end
end

--== Blizzards new "Secure Value" System is big bullshit!!!!! ==--
--== Restricts access on more than only combat relevant data. ==--
do

	local functions = {

		-- HST.BullShitDetector("UnitIsPlayer",unit)
		UnitIsPlayer = function(unit) -- not direct the function UnitIsPlayer but i've used the unit value from another function.
			unit = tostring(unit);
			return gsub(unit,"??","") and UnitIsPlayer(unit);
		end,

		-- HST.BullShitDetector("ChatMsgSystem",msg)
		ChatMsgSystem = function(msg)
			return msg and gsub(msg,"^.+$","");
		end,

		-- HST.BullShitDetector("CalendarGetDayEvent",event)
		CalendarGetDayEvent = function(event)
			-- secret table? WHY??? what impact has it on raid combats???
			return event and event.title;
		end,

		-- HST.BullShitDetector("generalTesting",value)
		generalTesting = function(value)
			-- try to trigger the evil
			if value == nil or value == true or value == false then
				return value==true;
			end
			local tValue = type(value);
			if tValue=="number" and value+1>0 then
				return value;
			end
			local tmp = strsplit("-",gsub(tostring(value),"#",""));
			if tmp then
				return value;
			end
			return false;
		end,
	}

	function lib.BullShitDetector(funcName,...)
		local result
		if issecretvalue(...) or canaccessvalue(...)==false then
			return false;
		end
		if type(funcName)~="string" then
			funcName = "generalTesting"
		end
		if functions[funcName] then
			result = {pcall(functions[funcName],...)};
		elseif _G[funcName] then
			result = {pcall(_G[funcName],...)}
		end
		if result and table.remove(result,1) then
			if issecretvalue(result[1]) or canaccessvalue(result[1])==false then
				return false;
			end
			return unpack(result)
		end
		return false;
	end
end

--== MapPin or TomTom ==--
do
	function lib.AddWaypoint(mapId, x,y, ...)
		local label, addon, useTomTom, mapPinToChat, z = ...
		if type(label)=="number" then
			z, label, useTomTom, addon = ...; -- special for map pin from blizzard. it can work with z as third location param
		end
		local TomTom = _G["TomTom"];
		if TomTom and TomTom.AddWaypoint and useTomTom then
			TomTom:AddWaypoint(mapId,x/100,y/100,{
				title = label,
				from = addon,
				persistent = nil,
				minimap = true,
				world = true
			});
		elseif C_Map.CanSetUserWaypointOnMap(mapId) then
			if not mapPinToChat then
				local uiMapPoint = UiMapPoint.CreateFromCoordinates(mapId, x/100, y/100, z);
				C_Map.SetUserWaypoint(uiMapPoint);
			else
				_G["DEFAULT_CHAT_FRAME"]:AddMessage("\124cffffff00\124Hworldmap:"..mapId..":"..(x*100)..":"..(y*100).."\124h[\124A:Waypoint-MapPin-ChatIcon:13:13:0:0\124a "..label.."-Kartenmarkierung]\124h\124r");
			end
		else
			print(addon..": Cannot set waypoints on this map.")
		end
	end
end

