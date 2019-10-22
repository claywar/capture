
require 'luau'
require 'strings'
res = require('resources')
packets = require('packets')
pack = require('pack')
bit = require 'bit'
texts  = require('texts')
files = require('files')

-------------------------------------------

lib = {}
lib.version = '001'
lib.date = '2019/10/21'

lib.color = {
   [1] = {string.char(0x1F,   1), '\\cs(255, 255, 255)'},
   [2] = {string.char(0x1F,  17), '\\cs(230, 255, 255)'},
   [3] = {string.char(0x1F,  20), '\\cs(255, 200, 230)'},
   [4] = {string.char(0x1F,   2), '\\cs(255, 180, 185)'},
   [5] = {string.char(0x1F,   3), '\\cs(255, 150, 150)'},
   [6] = {string.char(0x1F, 123), '\\cs(255, 115, 170)'},
   [7] = {string.char(0x1F,  39), '\\cs(255,  60,  90)'},
   [8] = {string.char(0x1F, 129), '\\cs(255, 255, 215)'},
   [9] = {string.char(0x1F,  53), '\\cs(225, 220, 185)'},
  [10] = {string.char(0x1F,  63), '\\cs(255, 255, 185)'},
  [11] = {string.char(0x1F,  36), '\\cs(255, 255,  90)'},
  [12] = {string.char(0x1F,   8), '\\cs(255, 205, 255)'},
  [13] = {string.char(0x1F,   4), '\\cs(255, 150, 255)'},
  [14] = {string.char(0x1E,  72), '\\cs(250,  60, 255)'},
  [15] = {string.char(0x1F, 200), '\\cs(190,  90, 255)'},
  [16] = {string.char(0x1E,   3), '\\cs(150, 150, 255)'},
  [17] = {string.char(0x1E,  71), '\\cs(115, 170, 255)'},
  [18] = {string.char(0x1F, 207), '\\cs(150, 175, 255)'},
  [19] = {string.char(0x1F,   7), '\\cs(200, 160, 255)'},
  [20] = {string.char(0x1F,  30), '\\cs(205, 255, 255)'},
  [21] = {string.char(0x1F,   6), '\\cs(170, 255, 235)'},
  [22] = {string.char(0x1F,   5), '\\cs(90,  255, 255)'},
  [23] = {string.char(0x1E,  83), '\\cs(65,  255, 210)'},
  [24] = {string.char(0x1F, 158), '\\cs(30,  255,  70)'},
  [25] = {string.char(0x1F, 160), '\\cs(155, 155, 195)'},
  [26] = {string.char(0x1E,  65), '\\cs(60,   60, 110)'},
}

lib.mode = {
  OFF     = 0,
  INFO    = 1,
  PASSIVE = 2,
  ACTIVE  = 3,
  CAPTURE = 4
}

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

-- ======================
-- == Helper Functions ==
-- ======================

-- Converts a string in base base to a number.
--------------------------------------------------
lib.toDec = function(numstr, base)
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
lib.byteStringToInt = function(x)
  x = lib.toDec(x, 16)
  x = bit.bswap(x)
  return x
end

-- Pads a string to the left
--------------------------------------------------
lib.padLeft = function(str, length, char)
  local padded = string.rep(char or ' ', length - #str) .. str
  return padded
end

-- Pads a string to the right
--------------------------------------------------
lib.padRight = function(str, length, char)
  local padded = str .. string.rep(char or ' ', length - #str)
  return padded
end

-- Checks an NPC's "raw name" (from packet) and ensures
-- we don't write "unwritable" ASCII characters to our files
--------------------------------------------------
lib.handleNpcRawName = function(name)
  name_bytes = {name:byte(1, #name)}
  local byte_string = '_MALFORMED_ASCII:'
  local malformed_ascii = false
  for _, byte_value in ipairs(name_bytes) do
    byte_string = byte_string .. byte_value .. '_'
    if (byte_value <= 31) or (byte_value >= 127) then
      malformed_ascii = true
    end
  end
  if malformed_ascii then
    return byte_string
  else
    return name
  end
end

-- Spits out the colors and codes used by addons in the capture suite
-- Will print colors directly to the chatlog and a box
-- Returns the box so you can hide or show it
--------------------------------------------------
lib.colorTest = function(box_settings)
  local chatlog_line = ''
  local box_text = ' '
  for code = 1, 16 do
    chatlog_line = chatlog_line .. lib.colors[code][1].. string.format("%02d ", code)
    box_text = box_text .. lib.colors[code][2].. string.format("%02d ", code) .. '\\cr'
  end
  windower.add_to_chat(1, chatlog_line)
  box_text = box_text .. '\n '
  
  chatlog_line = ''
  for code = 17, 26 do
    chatlog_line = chatlog_line .. lib.colors[code][1].. string.format("%02d ", code)
    box_text = box_text .. lib.colors[code][2].. string.format("%02d ", code) .. '\\cr'
  end
  windower.add_to_chat(1, chatlog_line)
  
  if box_settings then
    local color_box = texts.new(box_text, box_settings)
    texts.pos(color_box, windower.get_windower_settings().x_res*1/3, windower.get_windower_settings().y_res*2/3)
    return color_box
  end
  return false
end

-- Displays a print out of the commands of an associated addon
--------------------------------------------------
lib.displayHelp = function(commands, color_code, addon_name)
  if not color_code then color_code = '' end
  if addon_name then
    windower.add_to_chat(1, color_code .. '['.. addon_name .. ' Commands]')
  end
  for command, text in pairs(commands) do
    windower.add_to_chat(1, color_code .. command .. ': '.. text)
  end
end

-- Changes the mode of an addon
--------------------------------------------------
lib.setMode = function(settings, new_mode, color_code, addon_name)
  if not color_code then color_code = '' end
  if not new_mode then new_mode = '' end
  
  new_mode = string.upper(new_mode)
  mode_setting = lib.mode[new_mode]
  if mode_setting then
    settings.mode = mode_setting
  end
  if addon_name then
    if mode_setting then
      windower.add_to_chat(1, color_code .. '['.. addon_name .. '] Mode: '.. new_mode)
    else
      windower.add_to_chat(1, color_code .. '['.. addon_name .. '] Unknown mode: '.. new_mode ..'. Ignored.')
    end
  else
    if mode_setting then
      windower.add_to_chat(1, color_code .. 'Mode: '.. new_mode)
    else
      windower.add_to_chat(1, color_code .. 'Unknown mode: '.. new_mode ..'. Ignored.')
    end
  end
end