## Arcify

A [Monome Norns](https://monome.org/norns/) library for easily adding [Arc](https://monome.org/docs/arc/) support to existing sketches.

### Requirements

* Norns OS v2.0 or greater.
* A Monome Arc (or the desire to support one in your Norns sketch)

### Usage

```lua
-- create Arcify class and arcify object
local Arcify = include("arcify/lib/arcify")
local arcify = Arcify.new()

-- by default, it takes care of arc connection
-- if you need access to the arc object,
-- create it and pass it to Arcify
local my_arc = arc.connect()
local anotherArcify = Arcify.new(my_arc)

-- by default, Arcify updates the encoder rings itself
-- if you need to do it only on demand
local onDemandArcify = Arcify.new(my_arc, false)

-- register parameters with arcify
-- using a default encoder rate
arcify:register("cutoff")

-- change the feel of the encoder rate
arcify:register("cutoff", 5.0) -- fast
arcify:register("resonance", 0.1) -- slow

-- after registering all your params run add_params()
-- to make them visible in norns params menu
arcify:add_params()
```

### Roadmap
1. Set more elegant and appropriate defaults for the scale (encoder rate) value.
2. Remove the need to `register()` params, and introspect them from the global `params.params_` table directly.
3. Add a shift key to add room for more param mappings.
