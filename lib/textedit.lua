--
-- simple text editor
-- @its_your_bedtime
--

local COLS, ROWS = 32, 7

-- a cell is stored as plain text; it is word-wrapped only for display
local textedit = {
    chars = {},   -- the text being edited, one character per entry
    cur = 0,      -- number of characters before the cursor
    top = 1,      -- first visible row
    running = false,
    evaluated = false,
}

-- Text of a cell. Cells saved by older versions are tables of lines.
textedit.text = function(cell)
  if type(cell) ~= 'table' then return cell or '' end
  local s = ''
  for i = 1, #cell do
    local l = table.concat(cell[i])
    -- keep a line break where it can't split a word
    if #l > 0 and #s > 0 and #cell[i - 1] < COLS and s:sub(-1) == ')' and l:sub(1, 1) == '(' then
      s = s .. '\n'
    end
    s = s .. l
  end
  return s
end

-- Rows as {first, last} character indices: break at newlines, else after
-- the last space that fits, else in the middle of a word.
local function layout(chars)
  local rows, s, space = {}, 1, nil
  for i = 1, #chars do
    local c = chars[i]
    if c == '\n' then
      rows[#rows + 1] = {s, i - 1}
      s, space = i + 1, nil
    else
      if i - s + 1 > COLS and c ~= ' ' then
        local e = space or i - 1
        rows[#rows + 1] = {s, e}
        s, space = e + 1, nil
      end
      if c == ' ' then space = i end
    end
  end
  rows[#rows + 1] = {s, #chars}
  return rows
end

-- Row and column of the cursor. At a wrap the cursor belongs to the next row.
local function locate(rows, cur)
  for r = #rows, 1, -1 do
    if cur >= rows[r][1] - 1 and cur <= rows[r][2] then return r, cur - rows[r][1] + 1 end
  end
  return 1, 0
end

textedit.open = function(self, cell)
  self.chars = {}
  for c in textedit.text(cell):gmatch(utf8.charpattern) do self.chars[#self.chars + 1] = c end
  self.cur, self.top = #self.chars, 1
end

textedit.store = function(self)
  local s = table.concat(self.chars)
  return s:match('%S') and s or nil
end

textedit.insert = function(self, c)
  table.insert(self.chars, self.cur + 1, c)
  self.cur = self.cur + 1
end

textedit.vertical = function(self, d)
  local rows = layout(self.chars)
  local r, col = locate(rows, self.cur)
  local row = rows[r + d]
  if not row then return end
  local last = row[2]
  -- stay on the row when its end is a wrap
  if rows[r + d + 1] and rows[r + d + 1][1] == last + 1 then last = last - 1 end
  self.cur = math.max(row[1] - 1, math.min(row[1] - 1 + col, last))
end

textedit.kb_code = function(self, c, val)
  if keyboard.state.UP then
    self:vertical(-1)
  elseif keyboard.state.LEFT then
    self.cur = util.clamp(self.cur - 1, 0, #self.chars)
  elseif keyboard.state.RIGHT then
    self.cur = util.clamp(self.cur + 1, 0, #self.chars)
  elseif keyboard.state.DOWN then
    self:vertical(1)
  elseif keyboard.state.BACKSPACE then
    if self.cur > 0 then
      table.remove(self.chars, self.cur)
      self.cur = self.cur - 1
    end
  elseif keyboard.state.DELETE then
    if self.cur < #self.chars then table.remove(self.chars, self.cur + 1) end
  elseif keyboard.state.ENTER then
    if not keyboard.shift() then self:insert('\n') end
  end
end

textedit.kb_char = function(self, k)
  if k ~= nil then self:insert(k) end
end

textedit.render = function(blink, run, output)
    screen.font_face(25)
    screen.font_size(6)

    screen.level(run % 2 == 0 and 6 or 1)
    screen.rect(124, 60, 4, 4)
    screen.fill()

    if textedit.evaluated then
        screen.level(2)
        screen.rect(0, 0, 128, 57)
        screen.fill()
        textedit.evaluated = false
    end

    screen.level(15)

    -- scroll with the cursor
    local rows = layout(textedit.chars)
    local r, col = locate(rows, textedit.cur)
    textedit.top = util.clamp(textedit.top, math.max(1, r - ROWS + 1), r)

    for i = 1, ROWS do
        local row = rows[i + textedit.top - 1]
        if not row then break end
        screen.move(0, 8 * i)
        screen.text(table.concat(textedit.chars, '', row[1], row[2]))
        screen.stroke()
    end

    screen.level(3)
    screen.move(0, 63)
    screen.text(output[#output])
    screen.stroke()

    if blink then
        screen.level(2)
        screen.rect(math.min(col, COLS - 1) * 4, ((r - textedit.top + 1) * 8) - 6, 3, 7)
        screen.fill()
    end
end

return textedit
