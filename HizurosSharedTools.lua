
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
local dumpTable
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

	function lib.debugTable(tbl)
		if type(tbl)~="table" then
			lib.debug(tbl)
			return;
		end
		local res = dumpTable(tbl);
		for i=1, #res do
			lib.debug(res[i])
		end
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
	local projectNames = { -- https://warcraft.wiki.gg/wiki/WOW_PROJECT_ID
		[1] = "Retail",
		[2] = "ClassicEra",
		[3] = "PlunderStorm",
		[5] = "BCClassic",
		[11] = "WrathClassic",
		[14] = "CataClassic",
		[18] = "Forever",
		[19] = "MistsClassic"
	}
	local currentName = "<"..(projectNames[WOW_PROJECT_ID] or ("Unknown projectID "..WOW_PROJECT_ID))..">"

	local function FactionInfoToTable(...)
		local info = {}
		info.name,info.description,info.reaction,info.currentReactionThreshold,info.nextReactionThreshold,info.currentStanding,info.atWarWith,info.canToggleAtWar,info.isHeader,info.isCollapsed,info.hasRep,info.isWatched,info.isChild,info.factionID,info.hasBonusRepGain,info.canBeLFGBonus = ...
		return info
	end

	lib.deprecated = {
		C_QuestLog = {
			GetInfo = function(questLogIndex)
				local info = {
					questLogIndex = questLogIndex,

					-- dummy entries. not returned by GetQuestLogTitle()
					campaignID = 0,
					difficultyLevel = 0,
					headerSortKey = false,
					isAbandonOnDisable = false,
					isAutoComplete = false,
					isBounty = false,
					isInternalOnly = false,
					overridesSortOrder = false,
					questClassification = false, -- Enum.QuestClassification
					readyForTranslation = false,
					sortAsNormalQuest = false,
					useMinimalHeader = false,
				}
				info.title, info.level, info.suggestedGroup, info.isHeader, info.isCollapsed, info.isComplete, info.frequency, info.questID, info.startEvent, info.displayQuestID, info.isOnMap, info.hasLocalPOI, info.isTask, info.isStory, info.isHidden, info.isScaling  = GetQuestLogTitle(questLogIndex);
				return info
			end,
			-- Broker_Everything/modules/questlog.lua
			-- Broker_Everything/modules/invasions.lua

			GetQuestTagInfo = function(questID)
				local info = {}
				info.tagID, info.tagName, info.worldQuestType, info.quality, info.isElite, info.tradeskillLineID, info.displayTimeLeft = GetQuestTagInfo(questID);
				return info
			end,
			-- Broker_Everything/modules/questlog.lua

			GetNumQuestLogEntries = true,
			-- Broker_Everything/modules/questlog.lua
		},

		C_Reputation = {
			GetFactionDataByIndex = function(index) -- new in 11.0
				return FactionInfoToTable(GetFactionInfo(index))
			end,
			-- Broker_Everything/modules/reputation.lua

			GetFactionDataByID = function(id) -- new in 11.0
				return FactionInfoToTable(GetFactionInfoByID(id))
			end,
			-- Broker_Everything/modules/emissaryquests.lua
			-- Broker_Everything/modules/reputation.lua
			-- Broker_Everything/modules/professions.lua
			-- Broker_Everything/modules/speed.lua
			-- FollowerLocationInfo/Journal.lua

			GetNumFactions = true,
			-- Broker_Everything/modules/reputation.lua

			ExpandFactionHeader = true,
			-- Broker_Everything/modules/reputation.lua

			CollapseFactionHeader = true,
			-- Broker_Everything/modules/reputation.lua
		},

		C_Item = {
			GetItemStats = true,
			-- Broker_Everything/modules/equipment.lua

			GetItemCooldown = {"C_Item","GetItemCooldown","C_Container","GetItemCooldown"},
			-- Broker_Everything/modules/gps.lua
		},

		C_AddOns = {
			GetAddOnMemoryUsage = true -- 12.1.5 currently not moved to C_AddOns table
			-- Broker_Everything/modules/system.lua
		},

		C_SpellBook = {
			GetSpellBookItemInfo = true
			-- Broker_Everything/modules/professions.lua
		},

		C_SpecializationInfo = {
			SetSpecialization = true,
			-- Broker_Everything/modules/classspecs.lua
		},

		ChatFrameUtil = {
			SendTell = "ChatFrame_SendTell",
			-- Broker_Everything/modules/friends.lua
			GetMobileEmbeddedTexture = "ChatFrame_GetMobileEmbeddedTexture",
			-- Broker_Everything/modules/guild.lua
		},

		TimeUtil = {
			GetRecentTimeDate = "RecentTimeDate",
			-- Broker_Everything/modules/guildlog.lua
		},
	}

	local function updateFunc(cTableName,funcName,func)

		-- is C_Table and function available?
		if _G[cTableName] and type(_G[cTableName][funcName])=="function" then
			lib.deprecated[cTableName][funcName] = _G[cTableName][funcName] -- new function
			if WOW_PROJECT_ID~=WOW_PROJECT_MAINLINE then
				lib.debug("<deprecated-api>",currentName,cTableName,funcName);
			end
			return
		end

		if type(func)=="function" then
			lib.deprecated[cTableName][funcName] = func  -- old function
			return
		elseif type(func)=="table" then
			-- is function in C_Table renamed?
			local a1,a2, b1,b2 = unpack(func)
			if type(_G[a1])=="table" and type(_G[a1][a2])=="function" then
				lib.deprecated[cTableName][funcName] = _G[a1][a2]  -- old function
				return
			elseif b1 and b2 and type(_G[b1])=="table" and type(_G[b1][b2])=="function" then
				lib.deprecated[cTableName][funcName] = _G[b1][b2]  -- old function
				lib.debug("<deprecated-api>",currentName,cTableName,funcName,"<not found. Hope the other works>",b1, b2)
				return
			end
		elseif type(func)=="string" and _G[func] then
			lib.deprecated[cTableName][funcName] = _G[func]  -- old function
			return
		end

		-- all failed try old function
		if _G[funcName] then
			lib.deprecated[cTableName][funcName] = _G[funcName] -- old function
			if WOW_PROJECT_ID==WOW_PROJECT_MAINLINE then
				lib.debug("<deprecated-api>",currentName,cTableName,funcName,"<cTableFuncNotFound>","<currentlyNotDeprecatedInRetail>");
			end
		else
			lib.debug("<deprecated-api>",currentName,cTableName,funcName,"<allFailed>","<dummyAdded>")
			lib.deprecated[cTableName][funcName] = function() end
		end
	end

	for cTableName, cTableFuncs in pairs(lib.deprecated) do
		if type(cTableFuncs)=="table" then
			for funcName, func in pairs(cTableFuncs) do
				updateFunc(cTableName,funcName,func)
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
		-- check: get problematic function problematic arguments
		if lib.IsSecretAccessDenied(...) then
			return false
		end
		-- try to execute function and catch errors
		if type(funcName)~="string" then
			funcName = "generalTesting"
		end
		if functions[funcName] then
			result = {pcall(functions[funcName],...)};
		elseif _G[funcName] then
			result = {pcall(_G[funcName],...)}
		end
		-- check return value containing problematic values
		if result and table.remove(result,1) and not lib.IsSecretAccessDenied(result) then
			return unpack(result)
		end
		return false;
	end

	function lib.IsSecretAccessDenied(...)
		local args = {...}
		if #args==1 and type(args[1])=="table" then
			args = args[1]
		end
		if not issecrettable(args) then
			return false
		end
		for _, value in pairs(args) do
			if issecretvalue(value) and canaccessvalue(value)==false then
				return true
			end
		end
		return false
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

