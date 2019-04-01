-- arc_params: test
-- 1.0.0 - @mimetaur
--
-- attach arc encoders
-- directly to parameters
--

engine.name = "PolySub"

local polysub = require "we/lib/polysub"

package.loaded["arc_params/lib/arc_params"] = nil
ArcParams = nil
local ArcParams = require "arc_params/lib/arc_params"
local speed = 0.4

local a = arc.connect()
local arc_params = ArcParams.new(a)

function a.delta(n, delta)
    arc_params:update(n, delta)
    redraw()
end

local function start_note()
    local f1 = math.random(params:get("lo_freq"), params:get("hi_freq"))

    engine.start(1, f1)
    engine.start(2, f1 * 2)
    engine.start(3, f1 * 4)
    end_note_clock:start()
end

local function end_note()
    engine.stop(1)
    engine.stop(2)
    engine.stop(3)
end

start_note_clock = metro.init(start_note, speed * 2, -1)
end_note_clock = metro.init(end_note, speed, 1)

function init()
    polysub:params()

    params:add {
        type = "number",
        id = "lo_freq",
        name = "lowest random freq",
        min = 100,
        max = 400,
        default = 160
    }
    params:add {
        type = "number",
        id = "hi_freq",
        name = "highest random freq",
        min = 400,
        max = 1200,
        default = 800
    }

    -- TODO make more elegant default scaling

    -- register parameters
    -- and assign them to a particular encoder
    -- encoder num, param name, scaling amount, round?
    arc_params:register_at(1, "lo_freq", 0.25, true)
    arc_params:register_at(2, "hi_freq", 0.25, true)
    arc_params:register_at(3, "amprel", 0.01)
    arc_params:register_at(4, "shape", 0.005)
    -- these params can be chosen from the
    -- settings screen but aren't assigned to encoders
    -- encoder num, param name, scaling amount, round?

    arc_params:register("level", 0.1)
    arc_params:register("timbre", 0.1)
    arc_params:register_at("cutoff", 0.1)

    arc_params:add_arc_params()

    engine.stopAll()
    start_note_clock:start()
end

function redraw()
    screen.clear()
    screen.move(6, 6)
    screen.text("Arc Params")
    screen.move(6, 18)
    for i = 1, 4 do
        local name = arc_params:param_name_at_encoder(i)
        if name then
            screen.text(i .. ": " .. arc_params:param_name_at_encoder(i))
        else
            screen.text(i .. ": unassigned")
        end
        screen.move(6, 18 + (8 * i))
    end
    screen.update()
end
