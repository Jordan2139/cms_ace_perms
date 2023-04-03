local cache = {}
local loaded_list = {}
local apiKey, communityId, apiUrl, serverId, apiIdType, debugMode

RegisterNetEvent('SonoranCMS::Plugins::GiveInfo', function(pluginName, payload)
	if pluginName == GetCurrentResourceName() then
		apiKey = payload.apiKey
		communityId = payload.communityId
		apiUrl = payload.apiUrl
		serverId = payload.serverId
		apiIdType = payload.apiIdType
		debugMode = payload.debugMode
	end
end)

function errorLog(message)
	return print('^1[ERROR - Sonoran CMS Ace Perms - ' .. os.date('%c') .. ' ' .. message .. '^0');
end

function infoLog(message)
	return print('[INFO - Sonoran CMS Ace Perms - ' .. os.date('%c') .. ' ' .. message .. '^0');
end

function wait(seconds)
	os.execute("sleep " .. tonumber(seconds))
end


function initialize()
	if GetResourceState('sonorancms') ~= 'started' then
		errorLog('SonoranCMS Core Is Not Started! Not loading addon...')
	else
		cache = json.decode(LoadResourceFile(GetCurrentResourceName(), 'cache.json'))
		TriggerEvent('sonorancms::RegisterPushEvent', 'ACCOUNT_UPDATED', 'sonoran_permissions::rankupdate')
		infoLog('Checking resource version...');
		TriggerEvent('SonoranCMS::Plugins::Loaded', GetCurrentResourceName())
		wait(2)
		RegisterNetEvent('sonoran_permissions::rankupdate', function(data)
			local ppermissiondata = data.data.primaryRank
			local ppermissiondatas = data.data.secondaryRanks
			local identifier = data.data.activeApiIds
			if data.key == apiKey then
				for _, g in pairs(identifier) do
					if loaded_list[g] ~= nil then
						for k, v in pairs(loaded_list[g]) do
							local has = false
							for _, b in pairs(ppermissiondatas) do
								if b == k then
									has = true
								end
							end
							if ppermissiondata == v then
								has = true
							end
							if not has then
								loaded_list[g][k] = nil

								ExecuteCommand('remove_principal identifier.' .. apiIdType .. ':' .. g .. ' ' .. v)
								if Config.offline_cache then
									cache[g][k] = nil
									SaveResourceFile(GetCurrentResourceName(), 'cache.json', json.encode(cache))
								end
							end
						end
					end
				end
				if ppermissiondata ~= '' or ppermissiondata ~= nil then
					if Config.rank_mapping[ppermissiondata] ~= nil then
						for _, b in pairs(identifier) do
							ExecuteCommand('add_principal identifier.' .. apiIdType .. ':' .. b .. ' ' .. Config.rank_mapping[ppermissiondata])
							if loaded_list[b] == nil then
								loaded_list[b] = {[ppermissiondata] = Config.rank_mapping[ppermissiondata]}
							else
								loaded_list[b][ppermissiondata] = Config.rank_mapping[ppermissiondata]
							end
							if Config.offline_cache then
								if cache[b] == nil then
									cache[b] = {[ppermissiondata] = 'add_principal identifier.' .. apiIdType .. ':' .. b .. ' ' .. Config.rank_mapping[ppermissiondata]}
									SaveResourceFile(GetCurrentResourceName(), 'cache.json', json.encode(cache))
								else
									cache[b][ppermissiondata] = 'add_principal identifier.' .. apiIdType .. ':' .. b .. ' ' .. Config.rank_mapping[ppermissiondata]
									SaveResourceFile(GetCurrentResourceName(), 'cache.json', json.encode(cache))
								end
							end
						end
					end
				end
				if ppermissiondatas ~= nil then
					for _, v in pairs(ppermissiondatas) do
						if Config.rank_mapping[v] ~= nil then
							for _, b in pairs(identifier) do
								ExecuteCommand('add_principal identifier.' .. apiIdType .. ':' .. b .. ' ' .. Config.rank_mapping[v])
								if loaded_list[b] == nil then
									loaded_list[b] = {[v] = Config.rank_mapping[v]}
								else
									loaded_list[b][v] = Config.rank_mapping[v]
								end
								if Config.offline_cache then
									if cache[b] == nil then
										cache[b] = {[v] = 'add_principal identifier.' .. apiIdType .. ':' .. b .. ' ' .. Config.rank_mapping[v]}
										SaveResourceFile(GetCurrentResourceName(), 'cache.json', json.encode(cache))
									else
										cache[b][v] = 'add_principal identifier.' .. apiIdType .. ':' .. b .. ' ' .. Config.rank_mapping[v]
										SaveResourceFile(GetCurrentResourceName(), 'cache.json', json.encode(cache))
									end
								end
							end
						end
					end
				end
			end
		end)

		AddEventHandler('playerConnecting', function(_, _, deferrals)
			deferrals.defer();
			deferrals.update('Grabbing API ID and getting your permissions...')
			local identifier
			for _, v in pairs(GetPlayerIdentifiers(source)) do
				if string.sub(v, 1, string.len(apiIdType .. ':')) == apiIdType .. ':' then
					identifier = string.sub(v, string.len(apiIdType .. ':') + 1)
				end
			end
			exports['sonorancms']:performApiRequest({{['apiId'] = identifier}}, 'GET_ACCOUNT_RANKS', function(res)
				if #res > 2 then
					local ppermissiondata = json.decode(res)
					if loaded_list[identifier] ~= nil then
						for k, v in pairs(loaded_list[identifier]) do
							local has = false
							for l, b in pairs(ppermissiondata) do
								if b == k then
									has = true
								end
							end
							if not has then
								loaded_list[identifier][k] = nil
								ExecuteCommand('remove_principal identifier.' .. apiIdType .. ':' .. identifier .. ' ' .. v)
								if Config.offline_cache then
									cache[identifier][k] = nil
									SaveResourceFile(GetCurrentResourceName(), 'cache.json', json.encode(cache))
								end
							end
						end
					end
					for _, v in pairs(ppermissiondata) do
						if Config.rank_mapping[v] ~= nil then
							ExecuteCommand('add_principal identifier.' .. apiIdType .. ':' .. identifier .. ' ' .. Config.rank_mapping[v])
							if loaded_list[identifier] == nil then
								loaded_list[identifier] = {[v] = Config.rank_mapping[v]}
							else
								loaded_list[identifier][v] = Config.rank_mapping[v]
							end
							if Config.offline_cache then
								if cache[identifier] == nil then
									cache[identifier] = {[v] = 'add_principal identifier.' .. apiIdType .. ':' .. identifier .. ' ' .. Config.rank_mapping[v]}
									SaveResourceFile(GetCurrentResourceName(), 'cache.json', json.encode(cache))
								else
									cache[identifier][v] = 'add_principal identifier.' .. apiIdType .. ':' .. identifier .. ' ' .. Config.rank_mapping[v]
									SaveResourceFile(GetCurrentResourceName(), 'cache.json', json.encode(cache))
								end
							end
						end
					end
					deferrals.done()
				elseif Config.offline_cache then
					if cache[identifier] ~= nil then
						for _, v in pairs(cache[identifier]) do
							if string.sub(v, 1, string.len('')) == 'add_principal' then
								ExecuteCommand(v)
								if loaded_list[identifier] == nil then
									loaded_list[identifier] = {[v] = Config.rank_mapping[v]}
								else
									loaded_list[identifier][v] = Config.rank_mapping[v]
								end
							end
						end
					end
					deferrals.done()
				end
			end)
		end)

		RegisterCommand('refreshpermissions', function(src, _, _)
			local identifier
			for _, v in pairs(GetPlayerIdentifiers(src)) do
				if string.sub(v, 1, string.len(apiIdType .. ':')) == apiIdType .. ':' then
					identifier = string.sub(v, string.len(apiIdType .. ':') + 1)
				end
			end
			local payload = {}
			payload['id'] = communityId
			payload['key'] = apiKey
			payload['type'] = 'GET_ACCOUNT_RANKS'
			payload['data'] = {{['apiId'] = identifier}}
			exports['sonorancms']:performApiRequest({{['apiId'] = identifier}}, 'GET_ACCOUNT_RANKS', function(res)
				if #res > 2 then
					local ppermissiondata = json.decode(res)
					if loaded_list[identifier] ~= nil then
						for k, v in pairs(loaded_list[identifier]) do
							local has = false
							for l, b in pairs(ppermissiondata) do
								if b == k then
									has = true
								end
							end
							if not has then
								loaded_list[identifier][k] = nil
								ExecuteCommand('remove_principal identifier.' .. apiIdType .. ':' .. identifier .. ' ' .. v)
								if Config.offline_cache then
									cache[identifier][k] = nil
									SaveResourceFile(GetCurrentResourceName(), 'cache.json', json.encode(cache))
								end
							end
						end
					end
					for _, v in pairs(ppermissiondata) do
						if Config.rank_mapping[v] ~= nil then
							ExecuteCommand('add_principal identifier.' .. apiIdType .. ':' .. identifier .. ' ' .. Config.rank_mapping[v])
							if loaded_list[identifier] == nil then
								loaded_list[identifier] = {[v] = Config.rank_mapping[v]}
							else
								loaded_list[identifier][v] = Config.rank_mapping[v]
							end
							if Config.offline_cache then
								if cache[identifier] == nil then
									cache[identifier] = {[v] = 'add_principal identifier.' .. apiIdType .. ':' .. identifier .. ' ' .. Config.rank_mapping[v]}
									SaveResourceFile(GetCurrentResourceName(), 'cache.json', json.encode(cache))
								else
									cache[identifier][v] = 'add_principal identifier.' .. apiIdType .. ':' .. identifier .. ' ' .. Config.rank_mapping[v]
									SaveResourceFile(GetCurrentResourceName(), 'cache.json', json.encode(cache))
								end
							end
						end
					end
				elseif Config.offline_cache then
					if cache[identifier] ~= nil then
						for _, v in pairs(cache[identifier]) do
							if string.sub(v, 1, string.len('')) == 'add_principal' then
								ExecuteCommand(v)
								if loaded_list[identifier] == nil then
									loaded_list[identifier] = {[v] = Config.rank_mapping[v]}
								else
									loaded_list[identifier][v] = Config.rank_mapping[v]
								end
							end
						end
					end
				end
			end, 'POST', json.encode(payload), {['Content-Type'] = 'application/json'})
		end)

		RegisterCommand('permissiontest', function(src, args, _)
			if IsPlayerAceAllowed(src, args[1]) then
				TriggerClientEvent('chat:addMessage', src, {color = {0, 255, 0}, multiline = true, args = {'SonoranPermissions', 'true'}})
			else
				TriggerClientEvent('chat:addMessage', src, {color = {255, 0, 0}, multiline = true, args = {'SonoranPermissions', 'false'}})
			end
		end, false)

		AddEventHandler('playerDropped', function()
			local src = source
			local identifier
			for _, v in pairs(GetPlayerIdentifiers(src)) do
				if string.sub(v, 1, string.len(apiIdType .. ':')) == apiIdType .. ':' then
					identifier = string.sub(v, string.len(apiIdType .. ':') + 1)
				end
			end

			if loaded_list[identifier] ~= nil then
				for _, v in pairs(loaded_list[identifier]) do
					ExecuteCommand('remove_principal identifier.' .. apiIdType .. ':' .. identifier .. ' ' .. v)
				end
			end
		end)
	end

end

initialize();

AddEventHandler('onServerResourceStart',  function(resourceName)
	if resourceName == 'sonorancms' then
		infoLog('sonorancms core has been (re)started! reinitializing addon!')
		initialize()
	end
end)

