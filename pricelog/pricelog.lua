require 'luau'
require 'strings'
res = require('resources')
packets = require('packets')
pack = require('pack')
bit = require 'bit'

_addon.name = 'PriceLog'
_addon.version = '0.1'
_addon.author = 'ibm2431'
_addon.commands = {'pricelog'}

my_name = windower.ffxi.get_player().name

files = require('files')
file = T{}
file.simple = files.new('data/'.. my_name ..'/logs/simple.log', true)
file.raw = files.new('data/'.. my_name ..'/logs/raw.log', true)

-- Prettily formats a packet. Shamelessly stolen from Arcon's Packet Viewer.
--------------------------------------------------
string.hexformat_file = (function()
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

    local line_replace = {}
    for i = 0x01, 0x10 do
        line_replace[i] = '    %%%%3X |' .. ' %.2X':rep(i) .. ' --':rep(0x10 - i) .. '  %%%%3X | ' .. '%%s\n'
    end
    local short_replace = {}
    for i = 0x01, 0x10 do
        short_replace[i] = '%s':rep(i) .. '-':rep(0x10 - i)
    end

    -- Receives a byte string and returns a table-formatted string with 16 columns.
    return function(str, byte_colors)
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
end)()

-- Sets up tables and files for use in the current zone
--------------------------------------------------
function setup_zone(zone)
  local current_zone = res.zones[zone].en;
  file.simple = files.new('data/'.. my_name ..'/simple/'.. current_zone ..'.log', true)
  file.raw = files.new('data/'.. my_name ..'/raw/'.. current_zone ..'.log', true)
end

-- Checks incoming chunks for price response and log them
--------------------------------------------------
function check_incoming_chunk(id, data, modified, injected, blocked)
  local update_packet = packets.parse('incoming', data)
  local log_string = "";
  local raw_header = "";
  local mob;
  local mob_name;
  log_string = "Incoming: ";
  if (id == 0x03D) then
	local bag = update_packet['Bag'];
	local index = update_packet['Inventory Index'];
	local item_id = windower.ffxi.get_items(bag, index)['id'];
	local item = res.items[item_id];

    log_string = log_string .. '0x03D (Price Response), ';
	log_string = log_string .. 'Item: ' .. item_id .. ' (' .. item['en'] ..')';
    log_string = log_string .. ' Price: ' .. update_packet['Price'];
  end
  
  if (log_string ~= "Incoming: ") then
    windower.add_to_chat(7, "[PriceLog] " .. log_string);
    file.simple:append(log_string .. "\n\n");
    file.raw:append(log_string .. '\n'.. data:hexformat_file() .. '\n');
  end
end

windower.register_event('zone change', function(new, old)
  setup_zone(new);
end)

windower.register_event('incoming chunk', check_incoming_chunk);
setup_zone(windower.ffxi.get_info().zone)
