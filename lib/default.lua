--
-- default project: a small techno patch
--
-- drums are the 909 / 808 kits that ship with norns (dust/audio/common),
-- the bass is audio/saw-c1.wav from this script
--

local default = {}

local BPM, LENGTH = 132, 16

local function samples()
  local kit = _path.audio .. 'common/'
  return {
    [0] = kit .. '909/909-BD.wav',
    [1] = kit .. '909/909-CH.wav',
    [2] = kit .. '909/909-OH.wav',
    [3] = kit .. '909/909-CP.wav',
    [4] = kit .. '909/909-RS.wav',
    [5] = kit .. '808/808-LT.wav',
    [6] = norns.state.path .. 'audio/saw-c1.wav',
    [7] = kit .. '909/909-RC.wav',
  }
end

local sample_params = {
  amp_1 = -8, amp_2 = -10, amp_4 = -6, amp_5 = -6, amp_6 = -6, amp_7 = -12,
  filter_resonance_6 = 0.6,
}

local init_cell = [[
(def scale (list 60 60 63 67 58 72))
(def cut 400)
(def sweep (lambda () (if (> cut 5000) (set! cut 400) (set! cut (+ cut 45)))))
(def hat (lambda () (begin (ctf (rnd 4000 16000)) (vel (/ (rnd 25 80) 100)))))]]

local GHOST = '(if (> (rnd 100) 65) (sample 15 0) (sample 15 (#f)))'
local BASS = '(sweep) (ctf cut)'

-- step = { track 1, track 2, track 3, track 4 }, track = { sample, note, expression }
-- 1: kick, with a ghost kick on step 15 that comes and goes
-- 2: hats with random brightness and velocity, clap on 2 and 4
-- 3: rim and tom, looping every 12 steps against the bar
-- 4: bass with a slow filter sweep; one note is rewritten from the scale each bar
local pattern = {
  [1]  = { {0, 'C3'},        {1, 'C3', '(hat)'}, {4, 'C3'},                           {nil, nil, '(note (rnd 1 16) (get scale (rnd 6)))'} },
  [2]  = { {},               {1, 'C3', '(hat)'}, {},                                  {} },
  [3]  = { {},               {2, 'C3'},          {},                                  {6, 'C3', BASS} },
  [4]  = { {},               {1, 'C3', '(hat)'}, {4, 'G3', '(note (@) (rnd 60 72))'}, {6, 'C3', BASS} },
  [5]  = { {0, 'C3'},        {3, 'C3'},          {},                                  {} },
  [6]  = { {},               {1, 'C3', '(hat)'}, {},                                  {} },
  [7]  = { {},               {2, 'C3'},          {5, 'C3'},                           {6, 'd3', BASS} },
  [8]  = { {},               {1, 'C3', '(hat)'}, {},                                  {6, 'C3', BASS} },
  [9]  = { {0, 'C3'},        {1, 'C3', '(hat)'}, {},                                  {} },
  [10] = { {},               {1, 'C3', '(hat)'}, {4, 'C4'},                           {} },
  [11] = { {},               {2, 'C3'},          {5, 'G2', '(note (@) (rnd 50 62))'}, {6, 'C3', BASS} },
  [12] = { {},               {1, 'C3', '(hat)'}, {nil, nil, '(jmp 0)'},               {6, 'G3', BASS} },
  [13] = { {0, 'C3', GHOST}, {3, 'C3'},          {},                                  {} },
  [14] = { {},               {1, 'C3', '(hat)'}, {},                                  {} },
  [15] = { {},               {2, 'C3'},          {},                                  {6, 'a2', BASS} },
  [16] = { {},               {1, 'C3', '(hat)'}, {},                                  {6, 'C4', BASS} },
}

default.load = function(lisp)
  for id, file in pairs(samples()) do
    if util.file_exists(file) then
      params:set('sample_' .. id, file)
      params:set('play_mode_' .. id, 4)
    else
      print('nispm: default sample not found: ' .. file)
    end
  end
  for id, v in pairs(sample_params) do params:set(id, v) end

  for step, tracks in pairs(pattern) do
    for tr = 1, 4 do
      local smp, note, expr = tracks[tr][1], tracks[tr][2], tracks[tr][3]
      lisp.pat[step][tr * 3 - 2] = smp and tostring(smp)
      lisp.pat[step][tr * 3 - 1] = note
      lisp.pat[step][tr * 3] = expr
    end
  end

  lisp.length = LENGTH
  lisp.bpm = BPM
  lisp.metro:bpm_change(BPM)
  lisp.init_cell = init_cell
  lisp.run_init()
end

return default
