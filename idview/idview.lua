-- ------------------------------------------------------------------------------
-- USER SETINGS
-- ------------------------------------------------------------------------------
settings = {
  -- colors: Windower color codes for each of the given kinds of text
  colors = {
      system = 7, -- [ID View], NPC:, Event:, Params:
      incoming = 7, -- INCOMING
      outgoing = 7, -- OUTGOING
      event_header = 207, -- CS Event (0x032), CS Event + Params (0x034)
      event_option = 53, -- Event Option (0x05B)
      event_update = 207, -- Event Update (0x05C)
      npc_chat = 160, -- NPC Chat (0x036)
      actor = 8, -- 01234567 (Name)
      event = 1, -- 123
      option = 14, -- 1
      message = 1, -- 12345
      params = 14, -- 0, 1, 2, 3, 4, 5, 6, 7
  }
}
---------------------------------------------------------------------------------

require 'luau'
require 'strings'
res = require('resources')
packets = require('packets')
pack = require('pack')
bit = require 'bit'

_addon.name = 'IDView'
_addon.version = '0.2'
_addon.author = 'ibm2431'
_addon.commands = {'idview'}

my_name = windower.ffxi.get_player().name

files = require('files')
file = T{}
file.simple = files.new('data/'.. my_name ..'/logs/simple.log', true)
file.raw = files.new('data/'.. my_name ..'/logs/raw.log', true)

---------------------------------------------------------------------------------


colors = { -- Preformatted character codes for log colors. Should not need to be modified.
  system = string.char(0x1F, settings.colors.system),
  incoming = string.char(0x1F, settings.colors.incoming),
  outgoing = string.char(0x1F, settings.colors.outgoing),
  event_header = string.char(0x1F, settings.colors.event_header),
  event_option = string.char(0x1F, settings.colors.event_option),
  event_update = string.char(0x1F, settings.colors.event_update),
  npc_chat = string.char(0x1F, settings.colors.npc_chat),
  actor = string.char(0x1F, settings.colors.actor),
  event = string.char(0x1F, settings.colors.event),
  option = string.char(0x1F, settings.colors.option),
  message = string.char(0x1F, settings.colors.message),
  params = string.char(0x1F, settings.colors.params),
}

h = { -- Headers for log string. ex: NPC:
  idview = colors.system .. '[ID View] ',
  actor = colors.system .. 'NPC: '.. colors.actor,
  event = colors.system .. 'Event: '.. colors.event,
  option = colors.system .. 'Option: '.. colors.option,
  message = colors.system .. 'Message: '.. colors.message,
  params = colors.system .. 'Params: '.. colors.params,
}

---------------------------------------------------------------------------------

-- ==================================================
-- ==    Packet Formatting Functions               ==
-- == Shamelessly stolen from Arcon's PacketViewer ==
-- ==================================================
do
    -- Precompute hex string tables for lookups, instead of constant computation.
    local top_row = '        |  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F      | 0123456789ABCDEF\n    ' .. '-':rep((16+1)*3 + 2) .. '  ' .. '-':rep(16 + 6) .. '\n'

    local chars = {}
    for i = 0x00, 0xFF do
        if i >= 0x20 and i < 0x7F then
            chars[i] = i:char()
        else
            chars[i] = '.'
        end
    end
    chars[0x5C] = '\\\\'
    chars[0x25] = '%%'

    local line_replace = {}
    for i = 0x01, 0x10 do
        line_replace[i] = '    %%%%3X |' .. ' %.2X':rep(i) .. ' --':rep(0x10 - i) .. '  %%%%3X | ' .. '%%s\n'
    end
    local short_replace = {}
    for i = 0x01, 0x10 do
        short_replace[i] = '%s':rep(i) .. '-':rep(0x10 - i)
    end

    -- Receives a byte string and returns a table-formatted string with 16 columns.
    string.hexformat_file = function(str, byte_colors)
        local length = #str
        local str_table = {}
        local from = 1
        local to = 16
        for i = 0, ((length - 1)/0x10):floor() do
            local partial_str = {str:byte(from, to)}
            local char_table = {
                [0x01] = chars[partial_str[0x01]],
                [0x02] = chars[partial_str[0x02]],
                [0x03] = chars[partial_str[0x03]],
                [0x04] = chars[partial_str[0x04]],
                [0x05] = chars[partial_str[0x05]],
                [0x06] = chars[partial_str[0x06]],
                [0x07] = chars[partial_str[0x07]],
                [0x08] = chars[partial_str[0x08]],
                [0x09] = chars[partial_str[0x09]],
                [0x0A] = chars[partial_str[0x0A]],
                [0x0B] = chars[partial_str[0x0B]],
                [0x0C] = chars[partial_str[0x0C]],
                [0x0D] = chars[partial_str[0x0D]],
                [0x0E] = chars[partial_str[0x0E]],
                [0x0F] = chars[partial_str[0x0F]],
                [0x10] = chars[partial_str[0x10]],
            }
            local bytes = (length - from + 1):min(16)
            str_table[i + 1] = line_replace[bytes]
                :format(unpack(partial_str))
                :format(short_replace[bytes]:format(unpack(char_table)))
                :format(i, i)
            from = to + 1
            to = to + 0x10
        end
        return '%s%s':format(top_row, table.concat(str_table))
    end
end

-- Converts a string in base base to a number.
--------------------------------------------------
function string.todec(numstr, base)
    -- Create a table of allowed values according to base and how much each is worth.
    local digits = {}
    local val = 0
    for c in ('0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'):gmatch('.') do
        digits[c] = val
        val = val + 1
        if val == base then
            break
        end
    end
    
    local index = base^(#numstr-1)
    local acc = 0
    for c in numstr:gmatch('.') do
        acc = acc + digits[c]*index
        index = index/base
    end
    
    return acc
end

-- Converts a byte string to a proper integer keeping endianness into account
--------------------------------------------------
function byte_string_to_int(x)
  x = string.todec(x, 16);
  x = bit.bswap(x);
  return x;
end

-- Pulls apart params sent with an event CS packet
--------------------------------------------------
function get_params(params_string)
  local params = {}
  local final_param_string = '';
  local colorized_params = '';
  local int_rep = 0;
  for i=0, 6 do
    params[i + 1] = string.sub(params_string, (i*8)+1, (i*8) + 8);
    int_rep = byte_string_to_int(params[i + 1])
    final_param_string = final_param_string .. int_rep .. ", ";
    colorized_params = colorized_params .. colors.params .. int_rep .. ", ";
  end
  params[8] = string.sub(params_string, (7*8)+1, (7*8) + 8);
  int_rep = byte_string_to_int(params[8])
  final_param_string = final_param_string .. int_rep;
  colorized_params = colorized_params .. colors.params .. int_rep;
    
  return final_param_string, colorized_params;
end

-- Sets up tables and files for use in the current zone
--------------------------------------------------
function setup_zone(zone)
  local current_zone = res.zones[zone].en;
  file.simple = files.new('data/'.. my_name ..'/simple/'.. current_zone ..'.log', true)
  file.raw = files.new('data/'.. my_name ..'/raw/'.. current_zone ..'.log', true)
end

-- Checks outgoing chunks for dialog choices and logs them
--------------------------------------------------
function check_outgoing_chunk(id, data, modified, injected, blocked)
  local update_packet = packets.parse('outgoing', data)
  local log_string = "";
  local mob;
  local mob_name;

  local type, actor, colored_actor, event, option = nil;
  local simple_string = ''; -- For files
  local log_string = ''; -- For chatlog

  if (id == 0x05B) then
    -- Dialog Choice
    type = 'Event Option (0x05B): ';
    type_color = colors.event_option;
    actor = update_packet['Target'];
    mob = windower.ffxi.get_mob_by_id(update_packet['Target']);
    if (mob) then mob_name = mob.name end;
    if (mob_name) then 
      colored_actor = actor .. ' '.. colors.actor .. '('.. mob.name ..')';
      actor = actor .. ' ('.. mob.name ..')' ;
    end
    event = string.format('%05X', tonumber(update_packet['Menu ID'], 16));
    option = update_packet['Option Index'];

    simple_string = "OUTGOING > " .. type .. 'NPC: ' .. actor .. ', Event: '.. event .. ', Option: '.. option;
    log_string = h.idview.. colors.outgoing ..'%s'.. type_color..'%s'..  h.actor..'%s, '.. h.event..'%s, '.. h.option..'%s';
    log_string = string.format(log_string, "OUTGOING > ", type, colored_actor, event, option);
  end
  
  if (log_string ~= '') then
    windower.add_to_chat(7, log_string);
    file.simple:append(simple_string .. "\n\n");
    file.raw:append(simple_string .. '\n'.. data:hexformat_file() .. '\n');
  end
end

-- Checks incoming chunks for event CSes or NPC chats and logs them
--------------------------------------------------
function check_incoming_chunk(id, data, modified, injected, blocked)
  local update_packet = packets.parse('incoming', data)
  local mob;
  local mob_name;
  
  local type, actor, colored_actor, event, params, colored_params = nil;
  local simple_string = ''; -- For files
  local log_string = ''; -- For chatlog
  
  if (id == 0x036) then
    -- NPC Chat
      
    type = 'NPC Chat (0x036): ';
    type_color = colors.npc_chat;
    actor = update_packet['Actor'];
    colored_actor = actor
    mob = windower.ffxi.get_mob_by_id(update_packet['Actor']);
    if (mob) then mob_name = mob.name end;
    if (mob_name) then
      colored_actor = actor .. ' '.. colors.actor .. '('.. mob.name ..')';
      actor = actor .. ' ('.. mob.name ..')';
    end
    local message = update_packet['Message ID'];

    simple_string = "INCOMING < " .. type .. 'NPC: ' .. actor .. ', Message: '.. message;
    log_string = h.idview.. colors.incoming ..'%s'.. type_color..'%s'..  h.actor..'%s, '.. h.message..'%s';
    log_string = string.format(log_string, "INCOMING < ", type, colored_actor, message);
  elseif ((id == 0x032) or (id == 0x034) or (id == 0x05C)) then
    local type_color = ''
    -- Event CS
    if (id == 0x032) then
      type = 'CS Event (0x032): ';
      type_color = colors.event_header;
    elseif (id == 0x034) then
      type = 'CS Event + Params (0x034): ';
      type_color = colors.event_header;
    elseif (id == 0x05C) then
      type = 'Event Update (0x05C): ';
      type_color = colors.event_update;
    end
    
    if (id ~= 0x05C) then
      actor = update_packet['NPC'];
      mob = windower.ffxi.get_mob_by_id(update_packet['NPC']);
      if (mob) then mob_name = mob.name end;
      if (mob_name) then
        colored_actor = actor .. ' '.. colors.actor .. '('.. mob.name ..')';
        actor = actor .. ' ('.. mob.name ..')';
      end
      event = string.format('%05X', tonumber(update_packet['Menu ID'], 16));
    end
    
    local params = nil
    if (id == 0x05C) then
      params, colored_params = get_params(string.sub(data:hex(), (0x04*2)+1, (0x24*2)));
      simple_string = "INCOMING < " .. type .. 'Params: '.. params;
      log_string = h.idview.. colors.incoming..'%s'.. type_color..'%s'.. h.params..'%s';
      log_string = string.format(log_string, "INCOMING < ", type, colored_params);
    else
      params, colored_params = get_params(string.sub(data:hex(), (0x04*2)+1, (0x24*2)));
      simple_string = "INCOMING < " .. type .. 'NPC: ' .. actor .. ', Event: '.. event.. ', Params: '.. params;
      log_string = h.idview.. colors.incoming ..'%s'.. type_color..'%s'..  h.actor..'%s, '.. h.event..'%s, '.. h.params..'%s';
      log_string = string.format(log_string, "INCOMING < ", type, colored_actor, event, colored_params);
    end
  end
  
  if (log_string ~= '') then
    windower.add_to_chat(7, log_string);
    file.simple:append(simple_string .. "\n\n");
    file.raw:append(simple_string .. '\n'.. data:hexformat_file() .. '\n');
  end
end

windower.register_event('zone change', function(new, old)
  setup_zone(new);
end)

windower.register_event('outgoing chunk', check_outgoing_chunk);
windower.register_event('incoming chunk', check_incoming_chunk);
setup_zone(windower.ffxi.get_info().zone)
