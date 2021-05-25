-- LuaRadio script for processing recorded WAVs from Hydrogen line phased array
--
local params = {...}             -- Parameters passed at execution
local samp_rate = 1048576
local wavin = radio.WAVFileSource(params[1], 4) -- Read src as $1

local c = 2998e5
local ant_freq = 142e7
local rad_freq = 7e7
local wlen = c / ant_freq
local element_spacing = wlen / 2

local angle {
   array1 = 90,
   array2 = 90,
   array3 = 90,
   array4 = 90,
            }

local tdelay {
   array1 = math.sin(angle.array1) * element_spacing / c,
   array2 = math.sin(angle.array2) * element_spacing / c,
   array3 = math.sin(angle.array3) * element_spacing / c,
   array4 = math.sin(angle.array4) * element_spacing / c,
             }

-- Block variables

local pdelay {
   array1 = radio.DelayBlock(tdelay.array1 / (1 / samp_rate)),
   array2 = radio.DelayBlock(tdelay.array2 / (1 / samp_rate)),
   array3 = radio.DelayBlock(tdelay.array3 / (1 / samp_rate)),
   array4 = radio.DelayBlock(tdelay.array4 / (1 / samp_rate)),
             }

-- 70MHz Bandpass filter
local bp_filter = radio.BandpassFilterBlock(256, {695e5, 705e5})

-- Add blocks for merging signals
-- Arrays 1 & 2 into block A, 3 & 4 into block B, blocks A & B into block C
local addA = radio.AddBlock()
local addB = radio.AddBlock()
local addC = radio.AddBlock()

-- Throttle
local throttle = radio.ThrottleBlock()

-- Plotter
local gplot = radio.GnuplotXYplotSink()

-- Connecting blocks

-- Phase delays
top:connect(wavin, 'out1', pdelay.array1, 'in')
top:connect(wavin, 'out2', pdelay.array2, 'in')
top:connect(wavin, 'out3', pdelay.array3, 'in')
top:connect(wavin, 'out4', pdelay.array4, 'in')

-- Combining signals
top:connect(pdelay.array1, 'out', addA, 'in1')
top:connect(pdelay.array2, 'out', addA, 'in2')
top:connect(pdelay.array3, 'out', addB, 'in1')
top:connect(pdelay.array4, 'out', addB, 'in2')
top:connect(addA, 'out', addC, 'in1')
top:connect(AddB, 'out', addC, 'in2')

-- These all have one input and one output so I think I can be less verbose
top:connect(addC, bp_filter, throttle, gplot)

-- Blocks should be all connected, now I just have to figure out how to cycle
-- through the angles sample-by-sample
