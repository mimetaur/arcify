## Arcify

A [Monome Norns](https://monome.org/norns/) library for easily adding [Arc](https://monome.org/docs/arc/) support to existing sketches.

### Requirements

* Norns OS v2.0 or greater.
* A Monome Arc (or the desire to support one in your Norns sketch)
* We/ TestSine Engine (If you want to test this script)

### Usage

```lua
-- create Arcify class and arcify object
local Arcify = include("lib/arcify")
local arcify = Arcify.new()

-- by default, it takes care of arc connection
-- if you need access to the arc object,
-- create it and pass it to Arcify
local my_arc = arc.connect()
local anotherArcify = Arcify.new(my_arc)

-- by default, Arcify updates the encoder rings itself
-- if you need to do it only on demand
local onDemandArcify = Arcify.new(my_arc, false)

function init()
    -- register parameters with arcify
    -- using a default encoder rate
    arcify:register("cutoff")

    -- change the feel of the encoder rate
    arcify:register("cutoff", 5.0) -- fast
    arcify:register("resonance", 0.1) -- slow

    -- after registering all your params run add_params()
    -- to make them visible in norns params menu
    arcify:add_params()
end

function key(n, z)
    -- if you want to use a shift key with Arcify
    -- pass key params in
    arcify:handle_shift(n, z)
    redraw()
end
```

### Roadmap
1. If there isn’t an Arc plugged in, don’t build the Arcify params.
2. Set more elegant and appropriate defaults for the scale (encoder rate) value.
3. Build shift mode params only if user enables shift mode.
4. Remove the need to `register()` params, and introspect them from the global `params.params_` table directly.

### LuaDoc
See [the docs](https://mimetaur.github.io/arcify/doc/)
