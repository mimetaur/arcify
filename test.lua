-- arc_params: test
-- 1.0.0 - @mimetaur
--
-- attach arc encoders
-- directly to parameters
--

engine.name = "PolySub"

local polysub = require "we/lib/polysub"

local ArcParams = require "arc_params/lib/arc_params"

local start_note = {}
local end_note = {}

local function start_note()
    local f = math.random(400, 1200)
    engine.start(1, f)
    end_note:start()
end

local function end_note()
end

function init()
    polysub:params()

    arc_params:register("cut")
    arc_params:register("level")
    arc_params:register("timbre")
    arc_params:register("detune")
    arc_params:add_arc_params()

    start_note = metro.init(start_note, 4, -1)
    end_note = metro.init(end_note, 2, 1)

    engine.stopAll()
    start_note:start()
end
