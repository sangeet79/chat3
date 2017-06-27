-- chat3/init.lua

local near = minetest.setting_get("chat3.highlight_near") or 12

-- [function] Colorize
local function colorize(prot, colour, msg)
	if prot and prot >= 27 then
		return minetest.colorize(colour, msg)
	else
		return msg
	end
end

local prot = {}
-- [event] On join player
minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	local info = minetest.get_player_information(name)
	prot[name] = info.protocol_version
end)

-- [event] On chat message
minetest.register_on_chat_message(function(name, msg)
  local sender = minetest.get_player_by_name(name)

  for _, player in pairs(minetest.get_connected_players()) do
    local rname  = player:get_player_name()
    local colour = "#ffffff"

		local vers = prot[rname]
		if not vers or (vers and (vers >= 29 or (vers < 29 and name ~= rname))) then
			-- Check for near
	    if near ~= 0 then -- and name ~= rname then
	      if vector.distance(sender:getpos(), player:getpos()) <= near then
	        colour = "#88ffff"
	      end
	    end

	    -- Check for mentions
	    if msg:lower():find(rname:lower(), 1, true) then
	      colour = "#00ff00"
	    end

	    -- Check for shout
	    if msg:sub(1, 1) == "!" then
	      colour = "#ff0000"
	    end

	    -- if same player, set to white
	    if name == rname then
	      colour = "#ffffff"
	    end

	    -- Send message
	    minetest.chat_send_player(rname, colorize(vers, colour, "<"..name.."> "..msg))
		end
  end

  -- Log message
  minetest.log("action", "CHAT: ".."<"..name.."> "..msg)

  -- Prevent from sending normally
  return true
end)

-- [redefine] /msg
if minetest.chatcommands["msg"] then
  local old_command = minetest.chatcommands["msg"].func
  minetest.override_chatcommand("msg", {
    func = function(name, param)
      local sendto, message = param:match("^(%S+)%s(.+)$")
		if not sendto then
			return false, "Invalid usage, see /help msg."
		end
		if not core.get_player_by_name(sendto) then
			return false, "The player " .. sendto
					.. " is not online."
		end
		minetest.log("action", "PM from " .. name .. " to " .. sendto
				.. ": " .. message)
		minetest.chat_send_player(sendto, minetest.colorize('#00ff00', "PM from " .. name .. ": "
				.. message))
		return true, "Message sent."
    end,
  })
end
