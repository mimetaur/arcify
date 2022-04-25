local mod = require 'core/mods'
local Arcify = include("arcify/lib/arcify")
local tabutil = require "tabutil"

local arcify
local map_param_ids
local sens_max = 2048
local sens_div = sens_max / 16
local sens_default = sens_max / 4

local exclude_list = { -- Don't auto-add these params
  "output_level",
  "input_level",
  "monitor_level",
  "engine_level",
  "softcut_level",
  "tape_level",
  "headphone_gain",
  "rev_eng_input",
  "rev_cut_input",
  "rev_monitor_input",
  "rev_tape_input",
  "rev_return_level",
  "rev_pre_delay",
  "rev_lf_fc",
  "rev_low_time",
  "rev_mid_time",
  "rev_hf_damping",
  "comp_mix",
  "comp_ratio",
  "comp_threshold",
  "comp_attack",
  "comp_release",
  "comp_pre_gain",
  "comp_post_gain",
  "cut_input_adc",
  "cut_input_eng",
  "cut_input_tape",
  "clock_tempo",
  "link_quantum",
  "clock_crow_out_div",
  "clock_crow_in_div"
}

local function apply_scale(i)
  local scale = params:get("arcify".. i .. "_scale") / sens_div
  local target_param = map_param_ids[params:get("arcify" .. i .. "_target")]
  arcify:register(target_param, scale, false)
end

local function apply_mapping(i)
  arcify:clear_encoder_mapping(i, false)
  if params:get("arcify" .. i .. "_target") ~= 1 then
    arcify:map_encoder(i, map_param_ids[params:get("arcify" .. i .. "_target")], false)
    apply_scale(i)
  end
end


local function add_params()
  params:add_group("ARCIFY", 8)
  -- generate a list of modifyable params, excluding the above list
  map_param_ids = {false}
  local map_param_names = {"none"}
  local pl = params.params
  for k,v in pairs(params.params) do
    local is_excluded = tabutil.contains(exclude_list, v.id)
    if is_excluded ~= true then
      if (v.id and v.t == 1) or (v.id and v.t == 3) then
        table.insert(map_param_ids, v.id)
        table.insert(map_param_names, v.name)
        local scale = sens_default / sens_div
        arcify:register(v.id, scale, false)
      end
    end
  end

  for i = 1, 4 do
    params:add{
      type = "option",
      id = "arcify" .. i .. "_target",
      name = "arc " .. i .. " target",
      options = map_param_names,
      action = function(x)
        apply_mapping(i)
      end
    }
    params:add{
      type = "number",
      id = "arcify".. i .. "_scale",
      name = "arc " .. i .. " sensivity",
      min = 1,
      max = sens_max,
      default = sens_default,
      action = function(x)
        apply_scale(i)
      end
    }
  end
end

mod.hook.register("script_pre_init", "arcify", function()
  local script_init = init
  init = function ()
    script_init()
    arcify = Arcify.new()
    add_params()
    -- must reload default params, because the arc params weren't present for first pset load
    params:default()
    for i=1,4 do
      apply_mapping(i)
    end
  end
end)