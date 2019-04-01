-- arc_params: test
-- 1.0.0 - @mimetaur
--
-- attach arc encoders
-- directly to parameters
--

engine.name = "PolySub"

local polysub = require "we/lib/polysub"

local ArcParams = require "arc_params/lib/arc_params"

package.loaded["arc_params/lib/arc_params"] = nil

local a = arc.connect()
local arc_params = ArcParams.new(a)

function a.delta(n, delta)
    arc_params:update(n, delta)
end

local function start_note()
    local f = math.random(400, 500)
    print(f)
    engine.start(1, f)
    end_note_clock:start()
end

local function end_note()
    print("stopping")
    engine.stop(1)
end

start_note_clock = metro.init(start_note, 2, -1)
end_note_clock = metro.init(end_note, 1, 1)

function init()
    polysub:params()

    arc_params:register("cut")
    arc_params:register("level")
    arc_params:register("amprel")
    arc_params:register("timbre")
    arc_params:add_arc_params()

    engine.stopAll()
    start_note_clock:start()
end
