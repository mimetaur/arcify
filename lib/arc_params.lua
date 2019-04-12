local ArcParams = {}
ArcParams.__index = ArcParams

-- constants
local LO_LED = 1
local HI_LED = 64
local MIN_INTENSITY = 0
local MAX_INTENSITY = 15
local DEFAULT_INTENSITY = 12
local NO_ASSIGMENT = "none"
local VALID_ORIENTATIONS = {0, 180}
local INTEGER_SCALE_FACTOR = 0.000001
local DEFAULT_SCALE = 0.001

-- utility functions
local function is_valid_orientation(orientation)
    local is_valid = false
    for _, valid_orientation in ipairs(VALID_ORIENTATIONS) do
        if orientation == valid_orientation then
            is_valid = true
        end
    end
    return is_valid
end

local function round_delta(delta)
    if delta > 0 then
        return math.ceil(delta)
    else
        return math.floor(delta)
    end
end

local function scale_delta(delta, scale)
    return delta * scale
end

local function default_encoder_state()
    return {false, false, false, false}
end

local function param_info(name)
    local p = nil
    local id = params.lookup[name]
    p = params.params[id]
    return p
end

local function build_option_param(p)
    local newp = {}

    newp.friendly_name = p.name
    newp.name = p.id
    newp.min = 1
    newp.max = p.count
    newp.scale = (1 / p.count) * INTEGER_SCALE_FACTOR
    newp.is_rounded = true

    return newp
end

local function build_number_param(p, scale, is_rounded)
    local newp = {}

    newp.friendly_name = p.name
    newp.name = p.id
    newp.min = p.min
    newp.max = p.max
    newp.is_rounded = is_rounded or false
    if is_rounded then
        if not scale then
            scale = (1 / (max - min)) * INTEGER_SCALE_FACTOR
        end
    end
    newp.scale = scale or DEFAULT_SCALE

    return newp
end

local function build_taper_param(p, scale, is_rounded)
    local newp = {}

    newp.friendly_name = p.name
    newp.name = p.id
    newp.min = p.min
    newp.max = p.max
    newp.is_rounded = is_rounded or false
    if is_rounded then
        if not scale then
            scale = (1 / (max - min)) * INTEGER_SCALE_FACTOR
        end
    end
    newp.scale = scale or DEFAULT_SCALE

    return newp
end

local function build_control_param(p, scale, is_rounded)
    local cs = p.controlspec

    local newp = {}

    newp.friendly_name = p.name
    newp.name = p.id
    newp.min = cs.minval
    newp.max = cs.maxval
    newp.scale = scale or DEFAULT_SCALE
    newp.is_rounded = is_rounded

    return newp
end

-- private methods
local function draw_leds(self, num, amount, intensity)
    local orient = self.orientation_

    if orient == 0 then
        for i = LO_LED, amount do
            self.a_:led(num, i, intensity)
        end
    elseif orient == 180 then
        local offset = 32
        for i = offset, offset + amount do
            local val = i
            if val > 64 then
                val = val - 64
            end
            self.a_:led(num, val, intensity)
        end
    end
end

local function flip_encoder_order(self)
    local new_encoders = default_encoder_state()
    local j = 4
    for i = 1, 4 do
        new_encoders[j] = self.encoders_[i]
        j = j - 1
    end
    self.encoders_ = new_encoders
end

local function redraw_ring(self, num, e)
    if e then
        if e.name and e.min and e.max then
            local param_led = math.ceil(util.linlin(e.min, e.max, LO_LED, HI_LED, params:get(e.name)))
            local intensity = e.intensity or DEFAULT_INTENSITY
            draw_leds(self, num, param_led, intensity)
        end
    end
end

local function redraw_all(self)
    self.a_:all(0)
    if self.is_active_ then
        for num, name in ipairs(self.encoders_) do
            local param = self.params_[name]
            if param then
                redraw_ring(self, num, param)
            end
        end
    end
    self.a_:refresh()
end

--- Params as options.
-- Builds an array of registered params starting with "none"
local function params_as_options(self)
    local param_names = {}
    table.insert(param_names, NO_ASSIGMENT)
    for name, _ in pairs(self.params_) do
        table.insert(param_names, name)
    end
    return param_names
end

local function build_encoder_mapping_param(self, encoder_num)
    local opts = params_as_options(self)
    local param_id = "arc_encoder" .. encoder_num .. "_mapping"
    params:add {
        type = "option",
        id = param_id,
        name = "Arc #" .. encoder_num,
        options = opts,
        default = 1,
        action = function(value)
            local opt_name = opts[value]
            if self.params_[opt_name] then
                self:map_encoder(encoder_num, opt_name)
            elseif opt_name == NO_ASSIGMENT then
                self:clear_encoder_mapping(encoder_num)
            end
        end
    }
end

local function build_orientation_param(self)
    params:add {
        type = "option",
        id = "arc_orientation",
        name = "arc orientation",
        options = VALID_ORIENTATIONS,
        default = 1,
        action = function(value)
            self:change_orientation(VALID_ORIENTATIONS[value])
        end
    }
end

--- Create a new ArcParams object.
function ArcParams.new(a, do_update_self)
    local ap = {}
    ap.a_ = a
    ap.params_ = {}
    ap.encoders_ = default_encoder_state()
    ap.is_active_ = true
    ap.orientation_ = 0
    ap.do_update_self_ = do_update_self or true

    if ap.do_update_self_ then
        local function redraw_callback()
            redraw_all(ap)
        end

        local rate = 1 / 30 -- 30 fps
        ap.on_redraw_ = metro.init(redraw_callback, rate, -1)
        ap.on_redraw_:start()
    end
    setmetatable(ap, ArcParams)
    return ap
end

function ArcParams:add_arc_params()
    params:add_separator()
    build_orientation_param(self)
    for i = 1, 4 do
        build_encoder_mapping_param(self, i)
    end

    -- defaults
    local options_index = {}
    for i, opt in ipairs(params_as_options(self)) do
        options_index[opt] = i
    end

    for i = 1, 4 do
        local enc = self.encoders_[i]
        if enc then
            local id = "arc_encoder" .. i .. "_mapping"
            local value = options_index[enc]
            print(id, value, enc)
            params:set(id, value)
        end
    end
end

function ArcParams:register_at(encoder_num_, name_, scale_, is_rounded_)
    local status = self:register(name_, scale_, is_rounded_)
    if status then
        self:map_encoder(encoder_num_, name_)
    end
end

function ArcParams:register(name_, scale_, is_rounded_)
    if not name_ then
        print("Param is missing a name. Not registered.")
        return
    end
    -- from https://github.com/monome/norns/blob/dev/lua/core/paramset.lua
    -- TODO is there a way to introspect this from Norns code?
    -- or is it worth filing a PR to expose this from their code?

    -- currently valid types are:
    -- tNUMBER, tOPTION, tCONTROL
    local types = {
        tSEPARATOR = 0,
        tNUMBER = 1,
        tOPTION = 2,
        tCONTROL = 3,
        tFILE = 4,
        tTAPER = 5,
        tTRIGGER = 6
    }

    local p = param_info(name_)
    if not p then
        print("Referencing invalid param. Not registered.")
        return
    end

    local np = {}

    if p.t == types.tNUMBER then
        self.params_[name_] = build_number_param(p, scale_, is_rounded_)
    elseif p.t == types.tOPTION then
        self.params_[name_] = build_option_param(p)
    elseif p.t == types.tCONTROL then
        self.params_[name_] = build_control_param(p, scale_, is_rounded_)
    elseif p.t == types.tTAPER then
        self.params_[name_] = build_taper_param(p, scale_, is_rounded_)
    else
        print("Referencing invalid param. May be an unsupported type. Not registered.")
        return
    end
    return true
end

function ArcParams:map_encoder(position, param_name)
    if param_name == "none" then
        return
    elseif position < 1 or position > 4 then
        print("Invalid arc encoder number: " .. position)
        return
    elseif not self.params_[param_name] then
        print("Invalid parameter name: " .. param_name .. "at" .. position)
        return
    end
    self.encoders_[position] = param_name
end

function ArcParams:clear_encoder_mapping(position)
    if position < 1 or position > 4 then
        print("Invalid arc encoder number: " .. position)
        return
    end
    self.encoders_[position] = false
end

function ArcParams:clear_all_encoder_mappings()
    self.encoders_ = default_encoder_state()
end

--- Update a particular encoder
function ArcParams:update(num, delta)
    if not self.is_active_ then
        return
    end
    local encoder_mapping = self.encoders_[num]
    local param = self.params_[encoder_mapping]
    if encoder_mapping and param then
        local new_delta = scale_delta(delta, param.scale)
        if param.is_rounded then
            new_delta = round_delta(new_delta)
        end
        local value = params:get(param.name) + new_delta
        params:set(param.name, value)
    end
end

function ArcParams:param_id_at_encoder(enc_num)
    return self.encoders_[enc_num]
end

function ArcParams:param_name_at_encoder(enc_num)
    local id = self.encoders_[enc_num]
    if id then
        return self.params_[id].friendly_name
    end
end

function ArcParams:is_active()
    return self.is_active_
end

function ArcParams:activate()
    self.is_active_ = true
end

function ArcParams:deactivate()
    self.is_active_ = false
end

function ArcParams:toggle_orientation()
    if self.orientation_ == 0 then
        self:change_orientation(180)
    else
        self:change_orientation(0)
    end
end

function ArcParams:change_orientation(new_orientation)
    if is_valid_orientation(new_orientation) then
        self.orientation_ = new_orientation
        flip_encoder_order(self)
    end
end

function ArcParams:redraw()
    redraw_all(self)
end

return ArcParams
