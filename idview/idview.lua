
_addon.name = 'ID View'
_addon.version = '003'
_addon.date = '2019/10/26'
_addon.lib_version = '002'
_addon.author = 'ibm2431'
_addon.commands = {'idview'}

require('capture-lib')

idview = idview or {}

-- ------------------------------------------------------------------------------
-- DEFAULT USER SETTINGS
-- ------------------------------------------------------------------------------

idview.defaults = T{}

idview.defaults.mode = lib.mode.ACTIVE

idview.defaults.show_box = true -- shows the IDView info box
idview.defaults.auto_hide = true -- when an event finishes, auto-hide the box after 5 seconds
idview.defaults.auto_hide_time = 6 -- the number of seconds before hiding the box after event

idview.defaults.box = T{}
idview.defaults.box.max_num = 3
idview.defaults.box.spacing = 8
idview.defaults.box.pos   = T{}
idview.defaults.box.pos.x = 465
idview.defaults.box.pos.y = 540
idview.defaults.box.text       = {}
idview.defaults.box.text.size  = 11
idview.defaults.box.text.font  = 'Consolas'
idview.defaults.box.text.alpha = 255
idview.defaults.box.text.red   = 255
idview.defaults.box.text.green = 255
idview.defaults.box.text.blue  = 255

idview.defaults.bg = T{}
idview.defaults.bg.red   = 30
idview.defaults.bg.green = 30
idview.defaults.bg.blue  = 60
idview.defaults.bg.alpha = 230

idview.defaults.colors = T{}
idview.defaults.colors.actor        = 12 -- 01234567 (Name)
idview.defaults.colors.event        =  1 -- 123
idview.defaults.colors.event_header = 18 -- CS Event (0x032), CS Event + Params (0x034)
idview.defaults.colors.event_option =  9 -- Event Option (0x05B)
idview.defaults.colors.event_update =  9 -- Event Update (0x05C)
idview.defaults.colors.incoming     = 19 -- INCOMING
idview.defaults.colors.message      =  1 -- 12345
idview.defaults.colors.npc_chat     = 25 -- NPC Chat (0x036)
idview.defaults.colors.option       = 21 -- 1
idview.defaults.colors.outgoing     = 19 -- OUTGOING
idview.defaults.colors.params       = 21 -- 0, 1, 2, 3, 4, 5, 6, 7
idview.defaults.colors.system       = 19

idview.settings = config.load(idview.defaults)

---------------------------------------------------------------------------------
-- DISPLAY COLORS AND LOG HEADERS
---------------------------------------------------------------------------------

idview.colors = {}
idview.colors.log = { -- Preformatted character codes for log colors.
  SYSTEM       = lib.color[idview.settings.colors.system][1],
  INCOMING     = lib.color[idview.settings.colors.incoming][1],
  OUTGOING     = lib.color[idview.settings.colors.outgoing][1],
  EVENT_HEADER = lib.color[idview.settings.colors.event_header][1],
  EVENT_OPTION = lib.color[idview.settings.colors.event_option][1],
  EVENT_UPDATE = lib.color[idview.settings.colors.event_update][1],
  NPC_CHAT     = lib.color[idview.settings.colors.npc_chat][1],
  ACTOR        = lib.color[idview.settings.colors.actor][1],
  EVENT        = lib.color[idview.settings.colors.event][1],
  OPTION       = lib.color[idview.settings.colors.option][1],
  MESSAGE      = lib.color[idview.settings.colors.message][1],
  PARAMS       = lib.color[idview.settings.colors.params][1],
}
idview.colors.box = { -- \\cs(#,#,#) values for Windower text boxes
  SYSTEM       = lib.color[idview.settings.colors.system][2],
  INCOMING     = lib.color[idview.settings.colors.incoming][2],
  OUTGOING     = lib.color[idview.settings.colors.outgoing][2],
  EVENT_HEADER = lib.color[idview.settings.colors.event_header][2],
  EVENT_OPTION = lib.color[idview.settings.colors.event_option][2],
  EVENT_UPDATE = lib.color[idview.settings.colors.event_update][2],
  NPC_CHAT     = lib.color[idview.settings.colors.npc_chat][2],
  ACTOR        = lib.color[idview.settings.colors.actor][2],
  EVENT        = lib.color[idview.settings.colors.event][2],
  OPTION       = lib.color[idview.settings.colors.option][2],
  MESSAGE      = lib.color[idview.settings.colors.message][2],
  PARAMS       = lib.color[idview.settings.colors.params][2],
}

idview.h = { -- Headers for log string. ex: NPC:
  idview  = idview.colors.log.SYSTEM .. '[ID View] ',
  actor   = idview.colors.log.SYSTEM .. 'NPC: '    .. idview.colors.log.ACTOR,
  event   = idview.colors.log.SYSTEM .. 'Event: '  .. idview.colors.log.EVENT,
  option  = idview.colors.log.SYSTEM .. 'Option: ' .. idview.colors.log.OPTION,
  message = idview.colors.log.SYSTEM .. 'Message: '.. idview.colors.log.MESSAGE,
  params  = idview.colors.log.SYSTEM .. 'Params: ' .. idview.colors.log.PARAMS,
}

---------------------------------------------------------------------------------
-- VARIABLES AND TEMPLATES
---------------------------------------------------------------------------------

idview.template = {}
idview.template.EVENT    = ' ${dir|%s} ${type|%s}'.. 
                           idview.colors.box.SYSTEM ..'[ID View]\n Event: ${event|%s}'.. idview.colors.box.SYSTEM ..
                           ' Actor: ${actor|%s}\n '..idview.colors.box.SYSTEM ..'P: '.. idview.colors.box.PARAMS ..
                           '${p1|%s} ${p2|%s} ${p3|%s} ${p4|%s}\n    ${p5|%s} ${p6|%s} ${p7|%s} ${p8|%s}'
idview.template.OPTION   = ' ${dir|%s} ${type|%s}'..idview.colors.box.SYSTEM ..'[ID View]\n Event: ${event|%s} '..
                           idview.colors.box.SYSTEM ..'Actor: ${actor|%s}\n'..idview.colors.box.SYSTEM ..' Option: ${option|%s}\n '
idview.template.UPDATE   = ' ${dir|%s} ${type|%s}'.. idview.colors.box.SYSTEM ..'[ID View]\n'..
                           ' P: '.. idview.colors.box.PARAMS ..'${p1|%s} ${p2|%s} ${p3|%s} ${p4|%s}\n    ${p5|%s} ${p6|%s} ${p7|%s} ${p8|%s}'
idview.template.NPC_CHAT = ' ${dir|%s} ${type|%s}'..idview.colors.box.SYSTEM ..'[ID View]\n'..idview.colors.box.SYSTEM ..' Actor: ${actor|%s}\n'..
                           idview.colors.box.SYSTEM ..' Message: ${message|%s}\n '

idview.vars = {}
idview.vars.my_name = windower.ffxi.get_player().name

idview.vars.show_box = idview.settings.show_box
-- I really should not have to do this, but assigning box positions based off
-- of settings.box.pos.y directly will cause settings.box.pos.y to CHANGE
-- when I move a box that was previously assigned in that y position.
idview.vars.initial_x = idview.settings.box.pos.x
idview.vars.initial_y = idview.settings.box.pos.y
idview.vars.in_event = false
idview.vars.hide_ticking = false
idview.vars.color_testing = false

idview.vars.box_positions = {
  [1] = {x = idview.vars.initial_x, y = idview.vars.initial_y}
}
for i = 2, 10 do
  idview.vars.box_positions[i] = {
    x = idview.vars.initial_x,
    y = idview.vars.initial_y - (((idview.settings.box.text.size + idview.settings.box.spacing) * 4) * (i - 1))
  }
end

idview.vars.boxes = {}

idview.file = T{}
idview.file.simple = files.new('data/'.. idview.vars.my_name ..'/logs/simple.log', true)
idview.file.raw = files.new('data/'.. idview.vars.my_name ..'/logs/raw.log', true)

---------------------------------------------------------------------------------
-- PACKET PARSING INFORMATION
---------------------------------------------------------------------------------

idview.packets = {
  [0x032] = {
    dir = 'INCOMING <',
    text = 'CS Event (0x032): ',
    box_color = idview.colors.box.EVENT_HEADER,
    log_color = idview.colors.log.EVENT_HEADER,
    log_string = idview.h.actor..'%s, '.. idview.h.event..'%s, '.. idview.h.params..'%s',
    simple_string = ' NPC: %s\nEvent: %s\nParams: %s',
    string_params = function(info) return {[1] = info.actor, [2] = info.event, [3] = info.param_string} end,
    template = idview.template.EVENT,
  },
  [0x034] = {
    dir = 'INCOMING <',
    text = 'CS Event + Params (0x034): ',
    box_color = idview.colors.box.EVENT_HEADER,
    log_color = idview.colors.log.EVENT_HEADER,
    log_string = idview.h.actor..'%s, '.. idview.h.event..'%s, '.. idview.h.params..'%s',
    simple_string = ' NPC: %s\nEvent: %s\nParams: %s',
    string_params = function(info) return {[1] = info.actor, [2] = info.event, [3] = info.param_string} end,
    template = idview.template.EVENT,
  },
  [0x05C] = {
    dir = 'INCOMING <',
    text = 'Event Update (0x05C): ',
    box_color = idview.colors.box.EVENT_UPDATE,
    log_color = idview.colors.log.EVENT_UPDATE,
    log_string = idview.h.params..'%s',
    simple_string = ' \nParams: %s',
    string_params = function(info) return {[1] = info.param_string} end,
    template = idview.template.UPDATE,
  },
  [0x036] = {
    dir = 'INCOMING <',
    text = 'NPC Chat (0x036): ',
    box_color = idview.colors.box.NPC_CHAT,
    log_color = idview.colors.log.NPC_CHAT,
    log_string = idview.h.actor..'%s, '.. idview.h.message..'%s',
    simple_string = ' NPC: %s\nMessage: %s',
    string_params = function(info) return {[1] = info.actor, [2] = info.message} end,
    template = idview.template.NPC_CHAT,
  },
  [0x05B] = {
    dir = 'OUTGOING >',
    text = 'Event Option (0x05B): ',
    box_color = idview.colors.box.EVENT_OPTION,
    log_color = idview.colors.log.EVENT_OPTION,
    log_string = idview.h.actor..'%s, '.. idview.h.event..'%s, '.. idview.h.option..'%s',
    simple_string = ' NPC: %s\nEvent: %s\nOption: %s',
    string_params = function(info) return {[1] = info.actor, [2] = info.event, [3] = info.option} end,
    template = idview.template.OPTION,
  },
}

---------------------------------------------------------------------------------
-- COMMANDS
---------------------------------------------------------------------------------
idview.help_text = {
  ['box_test'] = "Displays a test box. Call again to hide, and save setting.",
  ['color_test'] = "Displays the color codes used by the addon",
  ['mode'] = "Sets mode: OFF | INFO | PASSIVE | ACTIVE",
  ['ver'] = "Shows addon (and library) version and date",
}

idview.commands = {
  ['color_test'] = function()
    if not idview.vars.color_testing then
      idview.vars.color_testing = lib.colorTest(idview.settings.box)
      idview.vars.color_testing:show()
    else
      idview.vars.color_testing:hide()
      idview.vars.color_testing = false
    end
  end,
  ['box_test'] = function ()
    idview.testBox()
  end,
  ['ver'] = function()
    windower.add_to_chat(1, idview.colors.log.SYSTEM .. _addon.name .. ': v'.. _addon.version .. ' ['.. _addon.date ..']')
    windower.add_to_chat(1, idview.colors.log.SYSTEM .. 'Library: v'.. lib.version .. ' ['.. lib.date ..'] (Expected: v'.. _addon.lib_version .. ')')
  end,
  ['mode'] = function(args)
    lib.setMode(idview.settings, args[1], idview.colors.log.SYSTEM, _addon.name)
    config.save(idview.settings)
  end,  
  ['help'] = function()
    lib.displayHelp(idview.help_text, idview.colors.log.SYSTEM, _addon.name)
  end,
}

---------------------------------------------------------------------------------
-- METHODS
---------------------------------------------------------------------------------

-- Sets up tables and files for use in the current zone
--------------------------------------------------
idview.setupZone = function(zone)
  local current_zone = res.zones[zone].en
  idview.file.simple = files.new('data/'.. idview.vars.my_name ..'/simple/'.. current_zone ..'.log', true)
  idview.file.raw = files.new('data/'.. idview.vars.my_name ..'/raw/'.. current_zone ..'.log', true)
end

-- Pulls apart params sent with an event CS packet
--------------------------------------------------
idview.getParams = function(params_string)
  local params = {}
  local final_param_string = ''
  local int_rep = 0
  for i=0, 6 do
    params[i + 1] = string.sub(params_string, (i*8)+1, (i*8) + 8)
    int_rep = lib.byteStringToInt(params[i + 1])
    params[i + 1] = tostring(int_rep)
    final_param_string = final_param_string .. int_rep .. ", "
  end
  params[8] = string.sub(params_string, (7*8)+1, (7*8) + 8)
  int_rep = lib.byteStringToInt(params[8])
  params[8] = tostring(int_rep)
  final_param_string = final_param_string .. int_rep
    
  return params, final_param_string
end

-- Handles writing an event to the info box
--------------------------------------------------
idview.writeBox = function(info)
  local packet_type = idview.packets[info.id]
  local template = packet_type.template
  
  box = texts.new(template, idview.settings.box)
  texts.pos(box, idview.vars.box_positions[1].x, idview.vars.box_positions[1].y)
  
  if info.dir == 'OUTGOING >' then
    box.dir = idview.colors.box.OUTGOING.. info.dir
  else
    box.dir = idview.colors.box.INCOMING.. info.dir
  end
  box.type = packet_type.box_color.. lib.padRight(packet_type.text, 31)
  if template ~= idview.template.UPDATE then
    box.actor = idview.colors.box.ACTOR.. info.actor
  end
  if (template == idview.template.EVENT) or (template == idview.template.UPDATE) then
    if template == idview.template.EVENT then
      box.event = idview.colors.box.EVENT.. lib.padLeft(info.event, 6)
    end
    box.p1 = lib.padLeft(info.params[1], 11)
    box.p2 = lib.padLeft(info.params[2], 11)
    box.p3 = lib.padLeft(info.params[3], 11)
    box.p4 = lib.padLeft(info.params[4], 11)
    box.p5 = lib.padLeft(info.params[5], 11)
    box.p6 = lib.padLeft(info.params[6], 11)
    box.p7 = lib.padLeft(info.params[7], 11)
    box.p8 = lib.padLeft(info.params[8], 11)
  end
  if template == idview.template.OPTION then
    box.event = idview.colors.box.EVENT.. lib.padLeft(info.event, 6)
    box.option = idview.colors.box.OPTION.. lib.padLeft(info.option, 5)
  elseif template == idview.template.NPC_CHAT then
    box.message = idview.colors.box.MESSAGE.. lib.padLeft(info.message, 5)
  end
  return box
end

-- Updates the info box with a table of information
--------------------------------------------------
idview.updateBox = function(info)
  if idview.vars.show_box then
    if info then
      if #idview.vars.boxes == idview.settings.box.max_num then
        local removed_box = table.remove(idview.vars.boxes, #idview.vars.boxes)
        removed_box:hide()
        texts.destroy(removed_box)
        removed_box = nil
      end
      for i = 1, #idview.vars.boxes do
        texts.pos(idview.vars.boxes[i], idview.vars.box_positions[i + 1].x, idview.vars.box_positions[i + 1].y)
      end
      new_box = idview.writeBox(info)
      table.insert(idview.vars.boxes, 1, new_box)
      new_box:show()
      if idview.settings.auto_hide and not idview.vars.hide_ticking then
        coroutine.schedule(function() idview.updateBox() end, idview.settings.auto_hide_time + 0.2)
        idview.vars.hide_ticking = true
      end
    elseif idview.settings.auto_hide and #idview.vars.boxes > 0 then
      if not idview.vars.in_event then
        local removed_box = table.remove(idview.vars.boxes, #idview.vars.boxes)
        removed_box:hide()
        texts.destroy(removed_box)
        removed_box = nil
        
        if #idview.vars.boxes == 0 then
          idview.vars.hide_ticking = false
        else
          coroutine.schedule(function() idview.updateBox() end, idview.settings.auto_hide_time + 0.2)
        end
      else
        coroutine.schedule(function() idview.updateBox() end, idview.settings.auto_hide_time + 0.2)
      end
    end
  end
end

-- Displays a test box that can be used to display / update box settings
--------------------------------------------------
idview.testBox = function()
  if not idview.vars.testing_box then
    local info = {
      dir = 'INCOMING <',
      id = 0x034,
      actor = '12345678 (Test Moogle)',
      event = '12345',
      params = {'123', '1234', '12345', '123456', '1234567', '12345678', '123456789', '1234567890'}
    }
    idview.vars.testing_box = idview.writeBox(info)
    idview.vars.testing_box:show()

  else
    local test_x, test_y = texts.pos(idview.vars.testing_box)
    idview.settings.box.pos.x = test_x
    idview.settings.box.pos.y = test_y
    config.save(idview.settings)
    idview.vars.testing_box:hide()
    idview.vars.testing_box = nil
    idview.vars.initial_x = idview.settings.box.pos.x
    idview.vars.initial_y = idview.settings.box.pos.y
    idview.vars.box_positions = {
      [1] = {x = idview.vars.initial_x, y = idview.vars.initial_y}
    }
    for i = 2, 10 do
      idview.vars.box_positions[i] = {
        x = idview.vars.initial_x,
        y = idview.vars.initial_y - (((idview.settings.box.text.size + idview.settings.box.spacing) * 4) * (i - 1))
      }
    end
  end
end

-- Builds a colorized chatlog string
--------------------------------------------------
idview.buildChatlogString = function(info)
  local packet_type = idview.packets[info.id]
  local chatlog_string = idview.h.idview
  
  local chatlog_info = packet_type.string_params(info)
  if chatlog_info[1] == info.actor then
    chatlog_info[1] = string.gsub(chatlog_info[1], ' ', ' '.. idview.colors.log.ACTOR)
  end
  if info.param_string then
    if chatlog_info[1] == info.param_string then
      chatlog_info[1] = string.gsub(chatlog_info[1], ' ', ' '.. idview.colors.log.PARAMS)
    elseif chatlog_info[3] == info.param_string then
      chatlog_info[3] = string.gsub(chatlog_info[3], ' ', ' '.. idview.colors.log.PARAMS)
    end
  end
  
  if info.dir == 'OUTGOING >' then
    chatlog_string = chatlog_string.. idview.colors.log.OUTGOING.. info.dir .. ' '
  else
    chatlog_string = chatlog_string.. idview.colors.log.INCOMING.. info.dir .. ' '
  end
  chatlog_string = chatlog_string.. packet_type.log_color.. packet_type.text.. packet_type.log_string
  
  chatlog_string = string.format(chatlog_string, unpack(chatlog_info))
  return chatlog_string
end

-- Builds a simple string for file logging
--------------------------------------------------
idview.buildSimpleString = function(info)
  local packet_type = idview.packets[info.id]
  local simple_info = packet_type.string_params(info)
  return string.format(info.dir .. packet_type.simple_string, unpack(simple_info))
end

-- Checks incoming chunks for event CSes or NPC chats and logs them
--------------------------------------------------
idview.checkChunk = function(dir, id, data)
  if idview.settings.mode == lib.mode.OFF then
    return
  end
  
  if idview.packets[id] and (idview.packets[id].dir == dir) then
    local update_packet = {}
    local info = {
      id = id,
      dir = dir
    }
    if id == 0x05B then
      update_packet = packets.parse('outgoing', data)
      idview.vars.in_event = false
    else
      update_packet = packets.parse('incoming', data)
    end
    
    if update_packet['NPC'] then
      info.actor = update_packet['NPC']
    elseif update_packet['Actor'] then
      info.actor = update_packet['Actor']
    elseif update_packet['Target'] then
      info.actor = update_packet['Target']
    end
    
    if info.actor then
      local mob = windower.ffxi.get_mob_by_id(info.actor)
      if mob and mob.name then
        info.actor = info.actor .. ' ('.. mob.name ..')'
      end
    end

    if update_packet['Message ID'] then
      info.message = tostring(update_packet['Message ID'])
    elseif update_packet['Option Index'] then
      idview.vars.in_event = false
      info.option = tostring(update_packet['Option Index'])
      info.event = string.format('%X', tonumber(update_packet['Menu ID'], 16))
    else
      idview.vars.in_event = true
      
      info.params, info.param_string = idview.getParams(string.sub(data:hex(), (0x04*2)+1, (0x24*2)))
      if update_packet['Menu ID'] then
        info.event = string.format('%X', tonumber(update_packet['Menu ID'], 16))
      end
    end
    
    if idview.settings.mode >= lib.mode.PASSIVE then
      local simple_string = idview.buildSimpleString(info)
      idview.file.simple:append(simple_string .. "\n\n")
      idview.file.raw:append(simple_string .. '\n'.. data:hexformat_file() .. '\n')
    end
    
    if idview.settings.mode >= lib.mode.ACTIVE or idview.settings.mode == lib.mode.INFO then
      windower.add_to_chat(idview.colors.log.SYSTEM, idview.buildChatlogString(info))
      idview.updateBox(info)
    end
  end
end

-- Checks for a valid command and executes it
--------------------------------------------------
idview.command = function(command, ...)
  local args = T{...}
  local result = idview.commands[command]
  if result then
    result(args)
  else
    local error_msg = '[ID View] Unknown command: '.. command ..'\n'.. idview.colors.log.SYSTEM..' Try //idview help'
    windower.add_to_chat(1, idview.colors.log.SYSTEM .. error_msg)
  end
end

-- Initializes and starts ID view
--------------------------------------------------
idview.initialize = function()
  lib.checkLibVer(_addon.name, _addon.lib_version, idview.colors.log.SYSTEM)
  windower.register_event('zone change', function(new, old) idview.setupZone(new) end)
  windower.register_event('outgoing chunk', function(id, data, modified, injected, blocked) idview.checkChunk('OUTGOING >', id, data) end)
  windower.register_event('incoming chunk', function(id, data, modified, injected, blocked) idview.checkChunk('INCOMING <', id, data) end)
  windower.register_event('addon command', idview.command)
  idview.setupZone(windower.ffxi.get_info().zone)
end


idview.initialize()
