## Arcify

A [Monome Norns](https://monome.org/norns/) library for easily adding [Arc](https://monome.org/docs/arc/) support to existing sketches.

### Requirements

Norns OS v2.0 or greater.

### Usage

```lua
-- Include Arcify class
local Arcify = include("arcify/lib/arcify")

-- connect your arc to arcify
local an_arc = arc.connect()
local arcify = Arcify.new(an_arc)

-- pass arc data to Arcify
function an_arc.delta(n, delta)
    arcify:update(n, delta)
end

-- register parameters with arcify
arcify:register("cutoff")

-- change the feel of the encoder rate
arcify:register("cutoff", 5.0) -- fast
arcify:register("resonance", 0.1) -- slow

-- after registering params run add_arc_params()
-- to make them visible in norns params menu
arcify:add_arc_params()
```

### Roadmap

1. Reduce the amount of cruft library consumers need to deal with (`delta()`, `add_arc_params()` and `arc.connect()`)
2. Set more elegant and appropriate defaults for the scale (encoder rate) value.
3. Remove the need to `register()` params, and introspect them from the global `params.params_` table directly.
4. Add a shift key to add room for more param mappings.
