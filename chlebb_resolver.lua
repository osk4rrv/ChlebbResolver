--[[ 
Chlebb Resolver.lua
branch: debug
writted by chlebb with a help of osk4rrv&some shit chinisse ai. 
]]

local function safe_ui_reference(tab, container, name)
    local values = {pcall(ui.reference, tab, container, name)}
    if not values[1] then
        return nil, nil, nil
    end
    return values[2], values[3], values[4]
end

local rage_enabled_ref, rage_enabled_hotkey_ref =
    safe_ui_reference("RAGE", "Aimbot", "Enabled")
local automatic_fire_ref =
    safe_ui_reference("RAGE", "Other", "Automatic fire")
local minimum_damage_ref =
    safe_ui_reference("RAGE", "Aimbot", "Minimum damage")
local damage_override_ref, damage_override_hotkey_ref, damage_override_value_ref =
    safe_ui_reference("RAGE", "Aimbot", "Minimum damage override")

-- reqs
local bit = require("bit")
local vector = require("vector")
local trace_ok, trace = pcall(require, "gamesense/trace")
if not trace_ok then
    trace = nil
end

-- ui
local enable = ui.new_checkbox("RAGE", "Other", "Enable Chlebb Resolver")
local resolver_type = ui.new_combobox("RAGE", "Other", "Resolver Type", {"Animstate", "Lby", "Lby+Animstate"})
local learning = ui.new_checkbox("RAGE", "Other", "Learning")
local extrapolation = ui.new_checkbox("RAGE", "Other", "Extrapolation")
local extrapolation_ticks = ui.new_slider("RAGE", "Other", "Extrapolation Maximum Ticks", 1, 16, 8, true, "t")
local hold_shot = ui.new_checkbox("RAGE", "Other", "Hold Shot")
local modes = ui.new_multiselect("RAGE", "Other", "Modes", {
    "Handle Defensive (beta)", -- compatibility master: enables all defensive modules
    "Anti-Defensive AA",
    "Anti-Defensive Flick",
    "Anti-Tickbase Exploit",
    "Handle LBY Breaks (beta)",
    "Anti-Aim Correction",
    "Anti-Backtrack",
    "Anti-LagComp Break",
    "Anti-Exploit (AX)"
})
local autostop = ui.new_checkbox("RAGE", "Other", "Smart AutoStop")
local clantag = ui.new_checkbox("RAGE", "Other", "Clantag")
local trash = ui.new_checkbox("RAGE", "Other", "Trashtalk")
local console_logs = ui.new_checkbox("RAGE", "Other", "Console Logs")
local god_mode = ui.new_checkbox("RAGE", "Other", "Autosniper God Mode")

local function update_ui_visibility()
    local enabled = ui.get(enable)
    if enabled then
        ui.set_visible(learning, enabled)
        ui.set_visible(extrapolation, enabled)
        ui.set_visible(extrapolation_ticks, enabled and ui.get(extrapolation))
        ui.set_visible(hold_shot, enabled)
        ui.set_visible(modes, enabled)
        ui.set_visible(autostop, enabled)
        ui.set_visible(clantag, enabled)
        ui.set_visible(trash, enabled)
        ui.set_visible(resolver_type, enabled)
        ui.set_visible(console_logs, enabled)
        ui.set_visible(god_mode, enabled)
    else
        ui.set_visible(learning, false)
        ui.set_visible(extrapolation, false)
        ui.set_visible(extrapolation_ticks, false)
        ui.set_visible(hold_shot, false)
        ui.set_visible(modes, false)
        ui.set_visible(autostop, false)
        ui.set_visible(clantag, false)
        ui.set_visible(trash, false)
        ui.set_visible(resolver_type, false)
        ui.set_visible(console_logs, false)
        ui.set_visible(god_mode, false)
    end
end

ui.set_callback(enable, update_ui_visibility)
ui.set_callback(extrapolation, update_ui_visibility)

update_ui_visibility()

-- ffi def

local chlebb_ffi = require("ffi")

local chlebb_animstate_offset = 0x9960
local chlebb_animlayer_offset = 0x2980
local chlebb_max_animlayers = 15

local chlebb_ffi_ok, chlebb_ffi_error = pcall(chlebb_ffi.cdef, [[
    typedef struct {
        float x;
        float y;
        float z;
    } chlebb_vec3_t;

    typedef struct {
        float m[3][4];
    } chlebb_matrix3x4_t;

    typedef struct {
        unsigned char r;
        unsigned char g;
        unsigned char b;
        unsigned char a;
    } chlebb_color_t;

    typedef struct {
        void* vtable;

        char chlebb_pad_0004[0x18];

        float m_flLastClientSideAnimationUpdateTime;
        int m_iLastClientSideAnimationUpdateFramecount;
        float m_flAnimUpdateDelta;

        float m_flEyeYaw;
        float m_flPitch;
        float m_flGoalFeetYaw;
        float m_flCurrentFeetYaw;
        float m_flCurrentTorsoYaw;

        float m_flUnknownVelocityLean;
        float m_flLeanAmount;

        char chlebb_pad_003C[0x4];

        float m_flFeetCycle;
        float m_flFeetYawRate;

        char chlebb_pad_004C[0x4];

        float m_fDuckAmount;
        float m_fLandingDuckAdditiveSomething;

        char chlebb_pad_005C[0x4];

        float m_vOriginX;
        float m_vOriginY;
        float m_vOriginZ;

        float m_vLastOriginX;
        float m_vLastOriginY;
        float m_vLastOriginZ;

        float m_vVelocityX;
        float m_vVelocityY;

        char chlebb_pad_0084[0x4];

        float m_flUnknownFloat1;

        char chlebb_pad_0090[0x8];

        float m_flUnknownFloat2;
        float m_flUnknownFloat3;
        float m_flUnknown;

        float m_flSpeed2D;
        float m_flUpVelocity;
        float m_flSpeedNormalized;
        float m_flFeetSpeedForwardsOrSideWays;
        float m_flFeetSpeedUnknownForwardOrSideways;
        float m_flTimeSinceStartedMoving;
        float m_flTimeSinceStoppedMoving;

        bool m_bOnGround;
        bool m_bInHitGroundAnimation;

        char chlebb_pad_00CC[0x2];

        float m_flJumpToFall;
        float m_flTimeSinceInAir;
        float m_flLastOriginZ;
        float m_flHeadHeightOrOffsetFromHittingGroundAnimation;
        float m_flStopToFullRunningFraction;

        char chlebb_pad_00E8[0x4];

        float m_flMagicFraction;

        char chlebb_pad_00F0[0x3C];

        float m_flWorldForce;

        char chlebb_pad_0130[0x1CE];

        float m_flMaxYaw;
    } chlebb_animstate_t;

    typedef struct {
        int m_nOrder;
        int m_nSequence;

        float m_flPrevCycle;
        float m_flWeight;
        float m_flWeightDeltaRate;
        float m_flPlaybackRate;
        float m_flCycle;

        void* m_pOwner;

        float m_flLayerAnimtime;
        float m_flLayerFadeOuttime;
        float m_flBlendIn;
        float m_flBlendOut;

        bool m_bClientBlend;

        char chlebb_pad_0038[0x3];
    } chlebb_animationlayer_t;

    typedef struct {
        void* vtable;

        char chlebb_pad_0004[0x18];

        float m_flSimulationTime;
        float m_flOldSimulationTime;
        float m_flAnimTime;
        float m_flOldAnimTime;

        int m_fEffects;
        int m_nRenderMode;
        int m_nRenderFX;

        chlebb_color_t m_RenderColor;

        int m_nModelIndex;
        int m_nBody;
        int m_nSkin;
        int m_nSequence;

        float m_flFrameRate;
        float m_flFrame;
        float m_flCycle;
        float m_flPlaybackRate;

        void* m_pAnimOverlays;
        int m_nNumAnimOverlays;

        bool m_bClientSideAnimation;

        char chlebb_pad_clientside[0x3];

        float m_flFadeScale;

        int m_nHitboxSet;

        void* m_pRenderable;
        void* m_pNetworkable;

        char chlebb_pad_0084[0x4];

        float m_vecVelocity[3];
        float m_vecBaseVelocity[3];
        float m_vecViewOffset[3];
        float m_vecOrigin[3];

        float m_angRotation[3];
        float m_angEyeAngles[2];

        float m_flLowerBodyYawTarget;

        int m_fFlags;
        int m_nTickBase;

        float m_flDuckAmount;

        int m_iHealth;
        int m_lifeState;

        float m_flPoseParameter[24];

        int m_nNewSequenceParity;
        int m_nResetEventsParity;
        int m_nMuzzleFlashParity;
        int m_hLightingOrigin;

        float m_flWeight;

        int m_nOrder;
    } chlebb_player_t;
]])

-- error handler
if not chlebb_ffi_ok then
    client.color_log(255, 50, 50, "[Chlebb FFI] cdef error: ", tostring(chlebb_ffi_error))
end

-- helpers
local chlebb_resolver_ffi = {}

local function chlebb_normalize_yaw(yaw)
    yaw = tonumber(yaw) or 0

    while yaw > 180 do
        yaw = yaw - 360
    end

    while yaw < -180 do
        yaw = yaw + 360
    end

    return yaw
end

local function chlebb_is_valid_address(address)
    if address == nil then
        return false
    end
    address = tonumber(address)
    return address ~= nil and address > 0x10000
end

local function chlebb_safe_read_uint32(address)
    if not chlebb_is_valid_address(address) then
        return nil
    end

    if memory == nil or type(memory.read_uint32) ~= "function" then
        return nil
    end

    local success, value = pcall(memory.read_uint32, address)

    if not success or not chlebb_is_valid_address(value) then
        return nil
    end

    return value
end

function chlebb_resolver_ffi.get_entity_address(entindex)
    if type(entindex) ~= "number" then
        return nil
    end

    if entindex < 1 or entindex > 64 then
        return nil
    end

    if type(entity.get_address) == "function" then
        local success, address = pcall(entity.get_address, entindex)

        if success and chlebb_is_valid_address(address) then
            return tonumber(address)
        end
    end

    return nil
end

function chlebb_resolver_ffi.read_animstate(entindex)
    if not chlebb_ffi_ok then
        return nil
    end

    local entity_address =
        chlebb_resolver_ffi.get_entity_address(entindex)

    if not entity_address then
        return nil
    end

    local animstate_address = chlebb_safe_read_uint32(
        entity_address + chlebb_animstate_offset
    )

    if not animstate_address then
        return nil
    end

    local destination =
        chlebb_ffi.new("chlebb_animstate_t[1]")

    local success = pcall(function()
        chlebb_ffi.copy(
            destination,
            chlebb_ffi.cast("const void*", animstate_address),
            chlebb_ffi.sizeof("chlebb_animstate_t")
        )
    end)

    if not success then
        return nil
    end

    return destination[0]
end

function chlebb_resolver_ffi.read_player(entindex)
    if not chlebb_ffi_ok then
        return nil
    end

    local entity_address =
        chlebb_resolver_ffi.get_entity_address(entindex)

    if not entity_address then
        return nil
    end

    local destination =
        chlebb_ffi.new("chlebb_player_t[1]")

    local success = pcall(function()
        chlebb_ffi.copy(
            destination,
            chlebb_ffi.cast("const void*", entity_address),
            chlebb_ffi.sizeof("chlebb_player_t")
        )
    end)

    if not success then
        return nil
    end

    return destination[0]
end

function chlebb_resolver_ffi.read_animation_layers(entindex, count)
    if not chlebb_ffi_ok then
        return {}
    end

    count = tonumber(count) or chlebb_max_animlayers
    count = math.max(1, math.min(count, chlebb_max_animlayers))

    local entity_address =
        chlebb_resolver_ffi.get_entity_address(entindex)

    if not entity_address then
        return {}
    end

    local overlays_address = chlebb_safe_read_uint32(
        entity_address + chlebb_animlayer_offset
    )

    if not overlays_address then
        return {}
    end

    local layers = {}
    local layer_size =
        chlebb_ffi.sizeof("chlebb_animationlayer_t")

    for layer_index = 0, count - 1 do
        local current_address =
            overlays_address + layer_index * layer_size

        local destination =
            chlebb_ffi.new("chlebb_animationlayer_t[1]")

        local success = pcall(function()
            chlebb_ffi.copy(
                destination,
                chlebb_ffi.cast(
                    "const void*",
                    current_address
                ),
                layer_size
            )
        end)

        if success then
            layers[layer_index + 1] = destination[0]
        end
    end

    return layers
end

function chlebb_resolver_ffi.get_desync_delta(entindex)
    local animstate =
        chlebb_resolver_ffi.read_animstate(entindex)

    if not animstate then
        return 0
    end

    local eye_yaw =
        tonumber(animstate.m_flEyeYaw) or 0

    local goal_feet_yaw =
        tonumber(animstate.m_flGoalFeetYaw) or 0

    local current_feet_yaw =
        tonumber(animstate.m_flCurrentFeetYaw) or 0

    local eye_goal_delta = math.abs(
        chlebb_normalize_yaw(eye_yaw - goal_feet_yaw)
    )

    local eye_current_delta = math.abs(
        chlebb_normalize_yaw(eye_yaw - current_feet_yaw)
    )

    local feet_delta = math.abs(
        chlebb_normalize_yaw(
            goal_feet_yaw - current_feet_yaw
        )
    )

    return math.max(
        eye_goal_delta,
        eye_current_delta,
        feet_delta
    )
end

function chlebb_resolver_ffi.get_velocity_2d(entindex)
    local player =
        chlebb_resolver_ffi.read_player(entindex)

    if not player then
        return 0
    end

    local velocity_x =
        tonumber(player.m_vecVelocity[0]) or 0

    local velocity_y =
        tonumber(player.m_vecVelocity[1]) or 0

    return math.sqrt(
        velocity_x * velocity_x +
        velocity_y * velocity_y
    )
end

function chlebb_resolver_ffi.get_layer(entindex, layer_index)
    layer_index = tonumber(layer_index)

    if not layer_index then
        return nil
    end

    layer_index = math.floor(layer_index)

    if layer_index < 1 or
       layer_index > chlebb_max_animlayers then
        return nil
    end

    local layers =
        chlebb_resolver_ffi.read_animation_layers(
            entindex,
            layer_index
        )
    return layers[layer_index]
end

-- extrapolation / resolver runtime
local FL_ONGROUND = 1
local PLAYER_SOLID_MASK = 0x201400B
local DEFAULT_GRAVITY = 800
local MAX_PLAYER_SPEED = 320
local MAX_DESYNC = 58
local DEFENSIVE_FORWARD_SHIFT_TICKS = 17
local DEFENSIVE_FLICK_DELTA = 65
local DEFENSIVE_FLICK_RETURN_DELTA = 24
local DEFENSIVE_MIN_HOLD_TICKS = 12
local DEFENSIVE_MAX_HOLD_TICKS = 32
local DEFENSIVE_RECOVERY_RECORDS = 2
-- Hidden core module: intentionally has no UI entry. It is active whenever
-- extrapolation is enabled and reconstructs plausible >64u lag-comp breaks.
local HIDDEN_ANTI_LC_BREAK = true
local LC_BREAK_DISTANCE = 64
local LC_MAX_RECONSTRUCT_DISTANCE = 128
local LC_ABSOLUTE_MAX_DERIVED_SPEED = 480
local LC_MIN_SIM_TICKS = 2
local LC_MAX_SIM_TICKS = 17
local LC_CANDIDATE_SCORE = 0.48
local LC_CONFIRM_SCORE = 0.68
local LC_HOLD_TICKS = 8
local LC_RECOVERY_RECORDS = 2

-- Anti-Backtrack: detect enemies manipulating simulation time / the lag-comp
-- window to keep stale hitboxes valid (backtrack abuse). When confirmed the
-- resolver anchors on the newest server record, extrapolation/early-shot are
-- disabled for the target and the ragebot is forced onto the head record.
local ANTIBACKTRACK_SIMTIME_JITTER            = 0.015 -- oscillation magnitude (s)            
local ANTIBACKTRACK_CONFIRM_EVENTS            = 3   -- suspicious events needed to confirm    
local ANTIBACKTRACK_HOLD_TICKS                = 32  -- 0.5s @ 64t keep active after last event
local ANTIBACKTRACK_DECAY_TICKS               = 96  -- 1.5s @ 64t full confidence decay
local ANTIBACKTRACK_HISTORY_SIZE              = 16  -- simtime samples retained

-- LBY-Breaker detection: analyse animlayer 3 (adjust) cycle/weight transitions
-- and LBY update deltas to decide whether the enemy is breaking LBY. When the
-- breaker is NOT active, the LBY signal is the most reliable desync anchor and
-- the hybrid resolver prefers it. When the breaker IS active, animstate is the
-- only reliable signal because LBY is being spoofed.
local LBYBREAKER_ADJUST_WEIGHT_THRESHOLD  = 0.95
local LBYBREAKER_ADJUST_CYCLE_THRESHOLD   = 0.92
local LBYBREAKER_LBY_DELTA_BREAK          = 60   -- delta > 60 => broken LBY
local LBYBREAKER_LBY_DELTA_SOFT           = 40   -- delta > 40 => suspicious
local LBYBREAKER_BALANCE_RATE_THRESHOLD   = 0.25 -- feetyawrate magnitude
local LBYBREAKER_CONFIRM_EVENTS           = 3
local LBYBREAKER_HOLD_TICKS               = 64   -- 1s @ 64t keep breaker flag
local LBYBREAKER_DECAY_TICKS              = 128  -- 2s @ 64t full decay
local LBYBREAKER_HISTORY_SIZE             = 12

-- Hold Shot: when the resolver predicts a better shooting opportunity within
-- HOLD_SHOT_MAX_WAIT ticks (e.g. enemy about to stop, peek into open, recover
-- from defensive), it suppresses the current early-shot so the ragebot fires
-- at the higher-damage / higher-hit-chance moment instead.
local HOLD_SHOT_MAX_WAIT_TICKS            = 6
local HOLD_SHOT_MIN_DAMAGE_GAIN           = 12   -- absolute damage gain required
local HOLD_SHOT_MIN_DAMAGE_RATIO          = 1.25 -- 25% more damage
local HOLD_SHOT_MIN_HITCHANCE_GAIN        = 0.12 -- 12% HC gain
local HOLD_SHOT_DEFENSIVE_RECOVER_TICKS   = 4    -- wait if defensive ends soon
local HOLD_SHOT_COOLDOWN_TICKS            = 3    -- avoid re-evaluating every tick

-- Autostop improvements: friction-aware counter-strafe with predictive stop
-- horizon and surface factor compensation. The engine applies sv_friction to
-- the velocity each tick; a single counter-strafe impulse must overcome both
-- the residual velocity and the next-tick friction drop.
local AUTOSTOP_FRICTION_DEFAULT           = 5.5
local AUTOSTOP_STOPSPEED_DEFAULT          = 80
local AUTOSTOP_COUNTERSTRAFE_FORCE        = 450
local AUTOSTOP_PREDICT_TICKS              = 4
local AUTOSTOP_AIR_STOP_SPEED             = 30
local AUTOSTOP_GROUND_STOP_SPEED          = 2.5
local AUTOSTOP_SURFACETRACE_UP            = 2
local AUTOSTOP_SURFACETRACE_DOWN          = 6

-- Defensive exploit detection improvements: tickbase-delta analysis (the
-- canonical defensive signature is m_nTickBase > tickcount, meaning the
-- enemy has queued commands to shift tickbase back), animlayer weight
-- inversion (defensive AA breaks the movement layer), and velocity-vector
-- discontinuity (defensive flicks cause instantaneous velocity rotation).
local DEFENSIVE_TICKBASE_DELTA_TICKS      = 2    -- tickbase > tickcount + N
local DEFENSIVE_TICKBASE_RESET_GAP        = 64
local DEFENSIVE_VELOCITY_ROTATION_DEG     = 75   -- instant velocity yaw rotation
local DEFENSIVE_VELOCITY_ROTATION_SPEED   = 40   -- only flag if speed > this
local DEFENSIVE_ANIMLAYER_INVERT_WEIGHT   = 0.30 -- movement weight drops below
local DEFENSIVE_ANIMLAYER_INVERT_PLAYBACK = 0.0  -- playback near zero while moving
local DEFENSIVE_SIMTIME_FUTURE_TICKS      = 2    -- simtime > curtime + N ticks
local DEFENSIVE_MULTI_EVENT_THRESHOLD     = 3    -- >=N distinct anomalies

-- Extrapolation improvements: acceleration-aware friction model, surface
-- speed factor (sv_maxspeed / surfaceData.maxSpeedFactor), air strafe
-- prediction (accel capped by airaccelerate), and multi-step collision
-- resolution with up to 2 slide bounces.
local EXTRAP_SURFACETRACE_UP              = 2
local EXTRAP_SURFACETRACE_DOWN            = 4
local EXTRAP_MAX_SLIDE_BOUNCES            = 2
local EXTRAP_AIR_ACCEL_DEFAULT            = 12
local EXTRAP_ACCEL_DEFAULT                = 5.5
local EXTRAP_MAX_SPEED_DEFAULT            = 320
local EXTRAP_FRICTION_DECAY_MIN           = 0.55
local EXTRAP_TURN_RATE_DECAY              = 0.82
local EXTRAP_STEP_SIZE                    = 18.0
local EXTRAP_GROUND_NORMAL_Z              = 0.55
local EXTRAP_WALL_NORMAL_Z                = 0.7

-- Game animation layer constants are zero-based. Lua tables returned by the
-- FFI helper are one-based, so callers must request/access index + 1.
-- Defined early so the LBY-breaker detector and the resolver can both use them.
local ANIMLAYER_MOVEMENT = 6
local ANIMLAYER_ADJUST = 3

-- This is the only authoritative per-player extrapolation tick result.
-- A shot copies it at aim_fire time so delayed hit/miss events cannot read a
-- value which already belongs to a newer record or another target.
local final_ticks = {}
local prediction_state = {}
local resolver_state = {}
local shot_data = {}
local runtime_active = false
local last_early_shot_tick = -1024
-- Hold Shot: per-target hold state. When hold_until_tick >= current tick the
-- early-shot path is suppressed so the ragebot waits for the predicted better
-- opportunity. last_eval_tick prevents re-evaluating every command tick.
local hold_shot_state = {}
local last_hold_eval_tick = -1024
local chlebb_extrap = { applied = {} }
local chlebb_god = { active = false }

local function chlebb_clamp(value, minimum, maximum)
    value = tonumber(value) or 0
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

local function chlebb_round(value)
    value = tonumber(value) or 0
    if value >= 0 then
        return math.floor(value + 0.5)
    end
    return math.ceil(value - 0.5)
end

local function chlebb_is_finite(value)
    return type(value) == "number" and value == value and
        value ~= math.huge and value ~= -math.huge
end

local function chlebb_sign(value)
    if value > 0 then return 1 end
    if value < 0 then return -1 end
    return 0
end

local function chlebb_length_2d(x, y)
    return math.sqrt((x or 0) * (x or 0) + (y or 0) * (y or 0))
end

local function chlebb_angle_delta(first, second)
    return chlebb_normalize_yaw((tonumber(first) or 0) - (tonumber(second) or 0))
end

-- Vector math helpers. All operate on plain {x,y,z} tables so they compose
-- with the FFI cast results and the network record fields without conversion.
local function chlebb_vec3(x, y, z) return {x = x or 0, y = y or 0, z = z or 0} end

local function chlebb_vec_add(a, b)
    return {x = (a.x or 0) + (b.x or 0), y = (a.y or 0) + (b.y or 0), z = (a.z or 0) + (b.z or 0)}
end

local function chlebb_vec_sub(a, b)
    return {x = (a.x or 0) - (b.x or 0), y = (a.y or 0) - (b.y or 0), z = (a.z or 0) - (b.z or 0)}
end

local function chlebb_vec_scale(a, s)
    s = tonumber(s) or 0
    return {x = (a.x or 0) * s, y = (a.y or 0) * s, z = (a.z or 0) * s}
end

local function chlebb_vec_dot(a, b)
    return (a.x or 0) * (b.x or 0) + (a.y or 0) * (b.y or 0) + (a.z or 0) * (b.z or 0)
end

local function chlebb_vec_cross(a, b)
    return {
        x = (a.y or 0) * (b.z or 0) - (a.z or 0) * (b.y or 0),
        y = (a.z or 0) * (b.x or 0) - (a.x or 0) * (b.z or 0),
        z = (a.x or 0) * (b.y or 0) - (a.y or 0) * (b.x or 0)
    }
end

local function chlebb_vec_length(a)
    return math.sqrt(chlebb_vec_dot(a, a))
end

local function chlebb_vec_length_2d(a)
    return math.sqrt((a.x or 0) ^ 2 + (a.y or 0) ^ 2)
end

local function chlebb_vec_normalize(a)
    local len = chlebb_vec_length(a)
    if len <= 1e-6 then return {x = 0, y = 0, z = 0} end
    return {x = a.x / len, y = a.y / len, z = a.z / len}
end

local function chlebb_vec_normalize_2d(a)
    local len = chlebb_vec_length_2d(a)
    if len <= 1e-6 then return {x = 0, y = 0, z = a.z or 0} end
    return {x = a.x / len, y = a.y / len, z = a.z or 0}
end

-- Project vector a onto vector b (component of a along b).
local function chlebb_vec_project(a, b)
    local bsqr = chlebb_vec_dot(b, b)
    if bsqr <= 1e-6 then return {x = 0, y = 0, z = 0} end
    local scale = chlebb_vec_dot(a, b) / bsqr
    return chlebb_vec_scale(b, scale)
end

-- Reject vector a from vector b (component of a perpendicular to b).
local function chlebb_vec_reject(a, b)
    local proj = chlebb_vec_project(a, b)
    return chlebb_vec_sub(a, proj)
end

-- Angle (degrees) between two 2D vectors, signed by the cross product z.
local function chlebb_vec_angle_between_2d(a, b)
    local len_a = chlebb_vec_length_2d(a)
    local len_b = chlebb_vec_length_2d(b)
    if len_a <= 1e-6 or len_b <= 1e-6 then return 0 end
    local dot = chlebb_vec_dot(a, b) / (len_a * len_b)
    local cross_z = (a.x or 0) * (b.y or 0) - (a.y or 0) * (b.x or 0)
    local angle = math.deg(math.acos(chlebb_clamp(dot, -1, 1)))
    if cross_z < 0 then angle = -angle end
    return chlebb_normalize_yaw(angle)
end

-- Convert a world yaw (degrees) into a 2D unit direction vector.
local function chlebb_yaw_to_vec(yaw)
    local r = math.rad(tonumber(yaw) or 0)
    return {x = math.cos(r), y = math.sin(r), z = 0}
end

-- Convert a 2D vector into a world yaw (degrees).
local function chlebb_vec_to_yaw(a)
    return math.deg(math.atan2(a.y or 0, a.x or 0))
end

-- Bit-field helpers for entity flags (FL_* / m_fFlags bit testing).
local FL_DUCKING     = bit.lshift(1, 1)    -- 2
local FL_WATERJUMP   = bit.lshift(1, 2)    -- 4
local FL_FROZEN      = bit.lshift(1, 4)    -- 16
local FL_DUCKING_2   = bit.lshift(1, 14)   -- 16384 (m_bDucked netflag)

local function chlebb_flag_set(flags, flag_bit)
    return bit.band(tonumber(flags) or 0, flag_bit) ~= 0
end

local function chlebb_safe_ui_get(ref, fallback)
    if ref == nil then return fallback end
    local ok, value = pcall(ui.get, ref)
    if not ok or value == nil then return fallback end
    return value
end

local function chlebb_cvar_number(name, fallback)
    if cvar ~= nil then
        local object = cvar[name]
        if object ~= nil then
            local ok, value = pcall(function()
                return object:get_float()
            end)
            value = tonumber(value)
            if ok and value ~= nil then return value end
        end
    end

    if type(client.get_cvar) == "function" then
        local ok, value = pcall(client.get_cvar, name)
        value = tonumber(value)
        if ok and value ~= nil then return value end
    end

    return fallback
end

local function chlebb_get_prop(entindex, prop, array_index)
    local ok, first, second, third
    if array_index ~= nil then
        ok, first, second, third = pcall(entity.get_prop, entindex, prop, array_index)
    else
        ok, first, second, third = pcall(entity.get_prop, entindex, prop)
    end
    if not ok then return nil end
    return first, second, third
end

local function chlebb_set_origin(entindex, x, y, z)
    if not chlebb_is_finite(x) or not chlebb_is_finite(y) or not chlebb_is_finite(z) then
        return false
    end
    local ok = pcall(entity.set_prop, entindex, "m_vecOrigin", x, y, z)
    if not ok then
        ok = pcall(entity.set_prop, entindex, "m_vecOrigin[0]", x)
        pcall(entity.set_prop, entindex, "m_vecOrigin[1]", y)
        pcall(entity.set_prop, entindex, "m_vecOrigin[2]", z)
    end
    pcall(entity.set_prop, entindex, "m_vecAbsOrigin", x, y, z)
    return ok
end

local CHLEBB_BONE_MATRIX_OFFSETS = { 0x26A8, 0x2698, 0x2914 }

function chlebb_extrap.shift_bones(entindex, dx, dy, dz)
    if not chlebb_ffi_ok then return false end
    if dx == 0 and dy == 0 and dz == 0 then return true end
    local entity_address = chlebb_resolver_ffi.get_entity_address(entindex)
    if entity_address == nil then return false end
    for index = 1, #CHLEBB_BONE_MATRIX_OFFSETS do
        local bones = chlebb_safe_read_uint32(entity_address + CHLEBB_BONE_MATRIX_OFFSETS[index])
        if bones ~= nil then
            local ok = pcall(function()
                local matrices = chlebb_ffi.cast("chlebb_matrix3x4_t*", bones)
                for bone = 0, 127 do
                    matrices[bone].m[0][3] = matrices[bone].m[0][3] + dx
                    matrices[bone].m[1][3] = matrices[bone].m[1][3] + dy
                    matrices[bone].m[2][3] = matrices[bone].m[2][3] + dz
                end
            end)
            if ok then return true end
        end
    end
    return false
end

function chlebb_extrap.restore(entindex, unshift_bones)
    local saved = chlebb_extrap.applied[entindex]
    if saved == nil then return end
    chlebb_set_origin(entindex, saved.x, saved.y, saved.z)
    if unshift_bones and saved.bones then
        chlebb_extrap.shift_bones(entindex, -saved.dx, -saved.dy, -saved.dz)
    end
    chlebb_extrap.applied[entindex] = nil
end

function chlebb_extrap.restore_all(unshift_bones)
    local pending = {}
    for entindex in pairs(chlebb_extrap.applied) do
        pending[#pending + 1] = entindex
    end
    for index = 1, #pending do
        chlebb_extrap.restore(pending[index], unshift_bones)
    end
end

function chlebb_extrap.discard()
    for entindex in pairs(chlebb_extrap.applied) do
        chlebb_extrap.applied[entindex] = nil
    end
end

function chlebb_extrap.prepare_read()
    local pending = {}
    for entindex in pairs(chlebb_extrap.applied) do
        pending[#pending + 1] = entindex
    end
    for index = 1, #pending do
        local entindex = pending[index]
        local saved = chlebb_extrap.applied[entindex]
        if saved ~= nil then
            local cx, cy, cz = chlebb_get_prop(entindex, "m_vecOrigin")
            local still_ours = chlebb_is_finite(cx) and
                chlebb_length_2d(cx - (saved.x + saved.dx), cy - (saved.y + saved.dy)) < 4 and
                math.abs((cz or 0) - (saved.z + saved.dz)) < 8
            if still_ours then
                chlebb_extrap.restore(entindex, true)
            else
                chlebb_extrap.applied[entindex] = nil
            end
        end
    end
end

function chlebb_extrap.apply_player(entindex)
    if not ui.get(extrapolation) then
        chlebb_extrap.restore(entindex, true)
        return
    end
    local state = prediction_state[entindex]
    if state == nil or state.predicted == nil or state.record == nil then
        chlebb_extrap.restore(entindex, true)
        return
    end
    if (state.final_ticks or 0) <= 0 or state.teleport or state.quarantined then
        chlebb_extrap.restore(entindex, true)
        return
    end
    local predicted = state.predicted
    local record = state.record
    local dx = predicted.x - record.x
    local dy = predicted.y - record.y
    local dz = predicted.z - record.z
    local displacement = chlebb_length_2d(dx, dy)
    if displacement < 0.5 or displacement > 128 then
        chlebb_extrap.restore(entindex, true)
        return
    end

    local saved = chlebb_extrap.applied[entindex]
    if saved ~= nil then
        if math.abs(saved.dx - dx) < 0.05 and
           math.abs(saved.dy - dy) < 0.05 and
           math.abs(saved.dz - dz) < 0.05 then
            chlebb_set_origin(entindex, predicted.x, predicted.y, predicted.z)
            return
        end
        chlebb_set_origin(entindex, predicted.x, predicted.y, predicted.z)
        chlebb_extrap.shift_bones(entindex, dx - saved.dx, dy - saved.dy, dz - saved.dz)
        saved.dx, saved.dy, saved.dz = dx, dy, dz
        return
    end

    local ox, oy, oz = chlebb_get_prop(entindex, "m_vecOrigin")
    if not chlebb_is_finite(ox) or not chlebb_is_finite(oy) or not chlebb_is_finite(oz) then
        return
    end
    if not chlebb_set_origin(entindex, predicted.x, predicted.y, predicted.z) then return end
    local bones = chlebb_extrap.shift_bones(entindex, dx, dy, dz)
    chlebb_extrap.applied[entindex] = {
        x = ox, y = oy, z = oz,
        dx = dx, dy = dy, dz = dz,
        bones = bones
    }
end

function chlebb_extrap.apply_all()
    if not ui.get(enable) or not ui.get(extrapolation) then
        chlebb_extrap.restore_all(true)
        return
    end
    local seen = {}
    local players = entity.get_players(true) or {}
    for index = 1, #players do
        local entindex = players[index]
        seen[entindex] = true
        if entity.is_alive(entindex) and not entity.is_dormant(entindex) then
            chlebb_extrap.apply_player(entindex)
        else
            chlebb_extrap.restore(entindex, true)
        end
    end
    local stale = {}
    for entindex in pairs(chlebb_extrap.applied) do
        if not seen[entindex] then stale[#stale + 1] = entindex end
    end
    for index = 1, #stale do
        chlebb_extrap.restore(stale[index], true)
    end
end

local function chlebb_get_origin(entindex)
    local saved = chlebb_extrap.applied[entindex]
    if saved ~= nil then
        return saved.x, saved.y, saved.z
    end
    local x, y, z = chlebb_get_prop(entindex, "m_vecOrigin")
    if not chlebb_is_finite(x) and type(entity.get_origin) == "function" then
        local ok, ox, oy, oz = pcall(entity.get_origin, entindex)
        if ok then x, y, z = ox, oy, oz end
    end
    if not chlebb_is_finite(x) or not chlebb_is_finite(y) or not chlebb_is_finite(z) then
        return nil
    end
    return x, y, z
end

local function chlebb_get_velocity(entindex)
    local x, y, z = chlebb_get_prop(entindex, "m_vecVelocity")
    if not chlebb_is_finite(x) then x = chlebb_get_prop(entindex, "m_vecVelocity[0]") end
    if not chlebb_is_finite(y) then y = chlebb_get_prop(entindex, "m_vecVelocity[1]") end
    if not chlebb_is_finite(z) then z = chlebb_get_prop(entindex, "m_vecVelocity[2]") end
    return tonumber(x) or 0, tonumber(y) or 0, tonumber(z) or 0
end

local function chlebb_get_base_velocity(entindex)
    local x, y, z = chlebb_get_prop(entindex, "m_vecBaseVelocity")
    return tonumber(x) or 0, tonumber(y) or 0, tonumber(z) or 0
end

local function chlebb_get_hull(entindex)
    local min_x, min_y, min_z = chlebb_get_prop(entindex, "m_vecMins")
    local max_x, max_y, max_z = chlebb_get_prop(entindex, "m_vecMaxs")
    local duck = tonumber((chlebb_get_prop(entindex, "m_flDuckAmount"))) or 0

    min_x = chlebb_is_finite(min_x) and min_x or -16
    min_y = chlebb_is_finite(min_y) and min_y or -16
    min_z = chlebb_is_finite(min_z) and min_z or 0
    max_x = chlebb_is_finite(max_x) and max_x or 16
    max_y = chlebb_is_finite(max_y) and max_y or 16
    max_z = chlebb_is_finite(max_z) and max_z or (72 - 18 * chlebb_clamp(duck, 0, 1))

    return min_x, min_y, min_z, max_x, max_y, max_z
end

-- modes implementation
local function i_modes(mode_name)
    local selected = ui.get(modes) or {}
    for index = 1, #selected do
        if selected[index] == mode_name then
            return true
        end
    end
    return false
end

local function chlebb_defensive_mode(mode_name)
    return i_modes("Handle Defensive (beta)") or i_modes(mode_name)
end

local function chlebb_any_defensive_mode()
    return chlebb_defensive_mode("Anti-Defensive AA") or
        chlebb_defensive_mode("Anti-Defensive Flick") or
        chlebb_defensive_mode("Anti-Tickbase Exploit")
end

-- autostop implementation. Friction-aware counter-strafe with a predictive
-- stop horizon: it simulates the next AUTOSTOP_PREDICT_TICKS of friction to
-- find the minimal counter-impulse that brings the local player below the
-- stop threshold, then converts that world-space impulse into cmd forwardmove
-- / sidemove. Returns true only once the local player is actually stopped.
local function i_autostop(cmd)
    if not ui.get(autostop) then return true end

    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then return false end

    local flags = tonumber((chlebb_get_prop(local_player, "m_fFlags"))) or 0
    local on_ground = chlebb_flag_set(flags, FL_ONGROUND)
    local velocity_x, velocity_y, velocity_z = chlebb_get_velocity(local_player)
    local speed = chlebb_length_2d(velocity_x, velocity_y)

    -- In air: cannot counter-strafe, only report whether slow enough.
    if not on_ground then
        return speed <= AUTOSTOP_AIR_STOP_SPEED
    end

    -- Already stopped: clear move and confirm.
    if speed <= AUTOSTOP_GROUND_STOP_SPEED then
        cmd.forwardmove = 0
        cmd.sidemove = 0
        return true
    end

    local interval = globals.tickinterval()
    if not chlebb_is_finite(interval) or interval <= 0 then interval = 1 / 64 end

    -- Engine friction model (PM_Friction): each tick the speed drops by
    --   drop = max(speed, sv_stopspeed) * sv_friction * interval
    -- Simulate AUTOSTOP_PREDICT_TICKS ahead to find the residual speed the
    -- counter-strafe must additionally cancel.
    local friction = chlebb_clamp(chlebb_cvar_number("sv_friction", AUTOSTOP_FRICTION_DEFAULT), 0, 20)
    local stop_speed = chlebb_clamp(chlebb_cvar_number("sv_stopspeed", AUTOSTOP_STOPSPEED_DEFAULT), 0, 250)
    local sim_vx, sim_vy = velocity_x, velocity_y
    local sim_speed = speed
    for _ = 1, AUTOSTOP_PREDICT_TICKS do
        if sim_speed <= 0.1 then break end
        local control = math.max(sim_speed, stop_speed)
        local drop = control * friction * interval
        local new_speed = math.max(0, sim_speed - drop)
        if new_speed <= 0 then sim_vx, sim_vy, sim_speed = 0, 0, 0 break end
        local scale = new_speed / sim_speed
        sim_vx = sim_vx * scale
        sim_vy = sim_vy * scale
        sim_speed = new_speed
    end

    -- If friction alone stops us within the horizon, just zero the move and
    -- let the engine coast to a stop. No need to waste a counter-strafe.
    if sim_speed <= AUTOSTOP_GROUND_STOP_SPEED then
        cmd.forwardmove = 0
        cmd.sidemove = 0
        return false
    end

    -- Required counter-impulse: cancel the residual velocity vector plus a
    -- small margin so the next-tick friction does not leave us above the
    -- threshold. The impulse is applied as a world-space acceleration which
    -- we convert to forwardmove/sidemove via the cmd yaw basis.
    local counter_vx = -sim_vx
    local counter_vy = -sim_vy
    local counter_speed = chlebb_length_2d(counter_vx, counter_vy)
    if counter_speed <= 0.1 then
        cmd.forwardmove = 0
        cmd.sidemove = 0
        return false
    end

    -- Scale the counter-impulse so a single tick of counter-strafe at
    -- AUTOSTOP_COUNTERSTRAFE_FORCE cancels it. The engine treats
    -- forwardmove/sidemove as a wishdir; the actual accel is capped by
    -- sv_accelerate, so we over-drive by 1.15 to ensure the stop completes.
    local unit_x = counter_vx / counter_speed
    local unit_y = counter_vy / counter_speed
    local impulse_scale = chlebb_clamp(counter_speed / (AUTOSTOP_COUNTERSTRAFE_FORCE * interval), 0, 1) * 1.15

    local yaw = tonumber(cmd.yaw)
    if yaw == nil then
        local _, camera_yaw = client.camera_angles()
        yaw = camera_yaw or 0
    end
    local radians = math.rad(yaw)
    local cos_y, sin_y = math.cos(radians), math.sin(radians)
    -- World impulse -> local move basis (forward, left).
    local world_x = unit_x * AUTOSTOP_COUNTERSTRAFE_FORCE * impulse_scale
    local world_y = unit_y * AUTOSTOP_COUNTERSTRAFE_FORCE * impulse_scale
    cmd.forwardmove = chlebb_clamp(
        world_x * cos_y + world_y * sin_y,
        -AUTOSTOP_COUNTERSTRAFE_FORCE,
        AUTOSTOP_COUNTERSTRAFE_FORCE
    )
    cmd.sidemove = chlebb_clamp(
        -(world_x * sin_y) + world_y * cos_y,
        -AUTOSTOP_COUNTERSTRAFE_FORCE,
        AUTOSTOP_COUNTERSTRAFE_FORCE
    )

    -- Clear movement buttons so the engine does not fight the counter-strafe.
    cmd.in_forward = 0
    cmd.in_back = 0
    cmd.in_moveleft = 0
    cmd.in_moveright = 0
    return false
end

local function chlebb_trace_skip(entindex)
    return function(other_entindex)
        if other_entindex == entindex then return true end
        local ok, classname = pcall(entity.get_classname, other_entindex)
        if not ok then return false end
        return classname == "CCSPlayer"
    end
end

local function chlebb_trace_player_move(entindex, start_x, start_y, start_z, end_x, end_y, end_z, hull)
    if trace ~= nil and type(trace.hull) == "function" then
        local ok, result = pcall(
            trace.hull,
            vector(start_x, start_y, start_z),
            vector(end_x, end_y, end_z),
            vector(hull.min_x, hull.min_y, hull.min_z),
            vector(hull.max_x, hull.max_y, hull.max_z),
            {skip = chlebb_trace_skip(entindex), mask = PLAYER_SOLID_MASK}
        )

        if ok and result ~= nil and result.end_pos ~= nil then
            local position = result.end_pos
            local fraction = tonumber(result.fraction)
            if fraction == nil then
                local full_x, full_y, full_z = end_x - start_x, end_y - start_y, end_z - start_z
                local done_x, done_y, done_z = position.x - start_x, position.y - start_y, position.z - start_z
                local full_length = math.sqrt(full_x * full_x + full_y * full_y + full_z * full_z)
                local done_length = math.sqrt(done_x * done_x + done_y * done_y + done_z * done_z)
                fraction = full_length > 0 and done_length / full_length or 1
            end

            local normal_x, normal_y, normal_z
            if result.plane ~= nil and result.plane.normal ~= nil then
                normal_x = tonumber(result.plane.normal.x)
                normal_y = tonumber(result.plane.normal.y)
                normal_z = tonumber(result.plane.normal.z)
            end

            return position.x, position.y, position.z,
                chlebb_clamp(fraction, 0, 1), normal_x, normal_y, normal_z
        end
    end

    -- Core GameSense exposes line traces, not a hull normal. Trace the feet,
    -- pelvis and head and conservatively stop at the first collision.
    local heights = {
        math.max(2, hull.min_z + 2),
        chlebb_clamp((hull.max_z - hull.min_z) * 0.5, 18, 36),
        math.max(20, hull.max_z - 2)
    }
    local fraction = 1
    for index = 1, #heights do
        local height = heights[index]
        local ok, current_fraction = pcall(
            client.trace_line,
            entindex,
            start_x,
            start_y,
            start_z + height,
            end_x,
            end_y,
            end_z + height
        )
        if ok and chlebb_is_finite(current_fraction) then
            fraction = math.min(fraction, chlebb_clamp(current_fraction, 0, 1))
        end
    end

    return start_x + (end_x - start_x) * fraction,
        start_y + (end_y - start_y) * fraction,
        start_z + (end_z - start_z) * fraction,
        fraction, nil, nil, nil
end

local function chlebb_limit_horizontal_velocity(x, y, limit)
    local speed = chlebb_length_2d(x, y)
    if speed <= limit or speed <= 0 then return x, y end
    local scale = limit / speed
    return x * scale, y * scale
end

--[=[
Legacy extrapolator retained in source for reference only. It is deliberately
excluded from compilation so there is one authoritative runtime pipeline.

-- Keep the prediction horizon close to the newest server state.  The UI value
-- is a ceiling, not a request to always simulate that many ticks.
local function chlebb_extrapolation_tick_count(choke_ticks, stale_ticks, confidence, maximum_ticks)
    local observed_ticks = math.max(tonumber(choke_ticks) or 0, tonumber(stale_ticks) or 0)
    maximum_ticks = math.max(0, tonumber(maximum_ticks) or 0)
    if observed_ticks <= 0 or maximum_ticks <= 0 then return 0 end

    local tick_interval = globals.tickinterval()
    if not chlebb_is_finite(tick_interval) or tick_interval <= 0 then
        tick_interval = 1 / 64
    end

    local latency = 0
    if type(client.latency) == "function" then
        local ok, value = pcall(client.latency)
        if ok and chlebb_is_finite(value) then latency = value end
    end
    local latency_ticks = chlebb_clamp(chlebb_round(math.max(0, latency) / tick_interval), 0, 16)

    -- Simulation time already includes much of the receive/interpolation delay.
    -- Ping therefore limits the horizon instead of being added to it, which
    -- prevents high-ping clients from predicting past the server position.
    local network_horizon = math.max(1, latency_ticks + 1)
    local horizon = math.min(observed_ticks, network_horizon)
    confidence = chlebb_clamp(tonumber(confidence) or 0, 0, 1)
    if confidence < 0.35 then return 0 end

    local ticks = chlebb_round(horizon * (0.35 + confidence * 0.65))
    if ticks == 0 then ticks = 1 end
    return chlebb_clamp(ticks, 0, maximum_ticks)
end

local function chlebb_simulate_movement(entindex, record, ticks)
    local tick_interval = globals.tickinterval()
    if not chlebb_is_finite(tick_interval) or tick_interval <= 0 then
        tick_interval = 1 / 64
    end

    local gravity = chlebb_clamp(chlebb_cvar_number("sv_gravity", DEFAULT_GRAVITY), 100, 2000)
    local friction = chlebb_clamp(chlebb_cvar_number("sv_friction", DEFAULT_FRICTION), 0, 20)
    local stop_speed = chlebb_clamp(chlebb_cvar_number("sv_stopspeed", DEFAULT_STOPSPEED), 0, 250)
    local max_velocity = chlebb_clamp(chlebb_cvar_number("sv_maxvelocity", 3500), 320, 5000)
    local step_size = 18.0

    local x, y, z = record.x, record.y, record.z
    local velocity_x, velocity_y, velocity_z = record.vx, record.vy, record.vz
    local base_x, base_y, base_z = record.base_vx, record.base_vy, record.base_vz
    local acceleration_x, acceleration_y = record.ax or 0, record.ay or 0
    local turn_rate = tonumber(record.turn_rate) or 0
    local on_ground = record.on_ground
    local collided = false
    -- The ducking simulation modifies max_z.  Copy the hull so a retry with a
    -- shorter horizon starts from the same networked record.
    local hull = {
        min_x = record.hull.min_x, min_y = record.hull.min_y, min_z = record.hull.min_z,
        max_x = record.hull.max_x, max_y = record.hull.max_y, max_z = record.hull.max_z
    }
    local duck_amount = tonumber(record.duck_amount) or 0
    local duck_target = tonumber(record.duck_target) or duck_amount

    local drive_x, drive_y = acceleration_x, acceleration_y
    if on_ground then
        local speed = chlebb_length_2d(velocity_x, velocity_y)
        if speed > 0.1 then
            -- Recorded acceleration is already the net result of input and
            -- friction. Compensate the simulated friction so we do not apply
            -- it a second time while extrapolating the observed movement.
            local friction_accel = math.max(speed, stop_speed) * friction
            local friction_x = -(velocity_x / speed) * friction_accel
            local friction_y = -(velocity_y / speed) * friction_accel
            drive_x = acceleration_x - friction_x
            drive_y = acceleration_y - friction_y
        end
    end
    drive_x, drive_y = chlebb_limit_horizontal_velocity(drive_x, drive_y, MAX_ACCELERATION)

    for _ = 1, ticks do
        if duck_amount ~= duck_target then
            local duck_rate = 0.1
            if duck_target > duck_amount then
                duck_amount = math.min(duck_amount + duck_rate, duck_target)
            else
                duck_amount = math.max(duck_amount - duck_rate, duck_target)
            end
            hull.max_z = 72 - 18 * chlebb_clamp(duck_amount, 0, 1)
        end

        local speed_before = chlebb_length_2d(velocity_x, velocity_y)
        if speed_before > 30 and math.abs(turn_rate) > 15 then
            local turn_angle = math.rad(chlebb_clamp(turn_rate * tick_interval, -30, 30))
            local cos_t = math.cos(turn_angle)
            local sin_t = math.sin(turn_angle)
            local new_vx = velocity_x * cos_t - velocity_y * sin_t
            local new_vy = velocity_x * sin_t + velocity_y * cos_t
            velocity_x, velocity_y = new_vx, new_vy
            local new_dx = drive_x * cos_t - drive_y * sin_t
            local new_dy = drive_x * sin_t + drive_y * cos_t
            drive_x, drive_y = new_dx, new_dy
            local new_ax = acceleration_x * cos_t - acceleration_y * sin_t
            local new_ay = acceleration_x * sin_t + acceleration_y * cos_t
            acceleration_x, acceleration_y = new_ax, new_ay
        end

        if on_ground then
            local speed = chlebb_length_2d(velocity_x, velocity_y)
            if speed > 0.1 then
                local drop = math.max(speed, stop_speed) * friction * tick_interval
                local new_speed = math.max(0, speed - drop)
                local scale = new_speed / speed
                velocity_x = velocity_x * scale
                velocity_y = velocity_y * scale
            end
            velocity_x = velocity_x + drive_x * tick_interval
            velocity_y = velocity_y + drive_y * tick_interval
            velocity_z = 0
        else
            velocity_x = velocity_x + acceleration_x * tick_interval
            velocity_y = velocity_y + acceleration_y * tick_interval
        end

        velocity_x, velocity_y = chlebb_limit_horizontal_velocity(
            velocity_x,
            velocity_y,
            MAX_PLAYER_SPEED * 1.25
        )
        velocity_z = chlebb_clamp(velocity_z, -max_velocity, max_velocity)

        local move_x = (velocity_x + base_x) * tick_interval
        local move_y = (velocity_y + base_y) * tick_interval
        local move_z
        if on_ground then
            move_z = base_z * tick_interval
        else
            move_z = (velocity_z + base_z) * tick_interval -
                0.5 * gravity * tick_interval * tick_interval
            velocity_z = velocity_z - gravity * tick_interval
        end

        local target_x, target_y, target_z = x + move_x, y + move_y, z + move_z
        local next_x, next_y, next_z, fraction, normal_x, normal_y, normal_z =
            chlebb_trace_player_move(entindex, x, y, z, target_x, target_y, target_z, hull)

        x, y, z = next_x, next_y, next_z
        if fraction < 0.999 then
            collided = true
            if normal_x ~= nil and normal_y ~= nil and normal_z ~= nil then
                local dot = velocity_x * normal_x + velocity_y * normal_y + velocity_z * normal_z
                if dot < 0 then
                    velocity_x = velocity_x - normal_x * dot
                    velocity_y = velocity_y - normal_y * dot
                    velocity_z = velocity_z - normal_z * dot
                end
                if normal_z > 0.7 and move_z <= 0 then
                    on_ground = true
                    velocity_z = 0
                end

                if fraction < 0.999 and normal_z < 0.7 then
                    local remaining = 1 - fraction
                    local slide_x = velocity_x * tick_interval * remaining
                    local slide_y = velocity_y * tick_interval * remaining
                    local slide_z = velocity_z * tick_interval * remaining
                    local sx2, sy2, sz2, sf2, _, _, _ =
                        chlebb_trace_player_move(entindex, x, y, z, x + slide_x, y + slide_y, z + slide_z, hull)
                    x, y, z = sx2, sy2, sz2
                    if sf2 < 0.999 then
                        velocity_x, velocity_y = 0, 0
                    end
                end
            else
                velocity_x, velocity_y = 0, 0
                if move_z <= 0 then
                    on_ground = true
                    velocity_z = 0
                end
            end
        end

        local probe_x, probe_y, probe_z, probe_fraction, _, _, probe_normal_z =
            chlebb_trace_player_move(entindex, x, y, z + 1, x, y, z - 4, hull)
        local has_ground = probe_fraction < 0.999 and
            (probe_normal_z == nil or probe_normal_z > 0.55)

        if has_ground and velocity_z <= 0 then
            x, y, z = probe_x, probe_y, probe_z
            on_ground = true
            velocity_z = 0
        elseif on_ground and not has_ground then
            on_ground = false
        end
    end

    return {
        x = x, y = y, z = z,
        vx = velocity_x, vy = velocity_y, vz = velocity_z,
        on_ground = on_ground,
        collided = collided
    }
end

-- Build an independent record for command-time revalidation. Network updates
-- can arrive between the regular prediction pass and an early-shot command.
local function chlebb_build_fresh_record(entindex, prediction)
    local x, y, z = chlebb_get_origin(entindex)
    if x == nil then return nil end

    local vx, vy, vz = chlebb_get_velocity(entindex)
    local base_vx, base_vy, base_vz = chlebb_get_base_velocity(entindex)
    local min_x, min_y, min_z, max_x, max_y, max_z = chlebb_get_hull(entindex)
    local flags = tonumber((chlebb_get_prop(entindex, "m_fFlags"))) or 0
    local duck_now = tonumber((chlebb_get_prop(entindex, "m_flDuckAmount"))) or 0
    local duck_target = bit.band(flags, 2) ~= 0 and 1 or 0

    return {
        x = x, y = y, z = z,
        vx = vx, vy = vy, vz = vz,
        base_vx = base_vx, base_vy = base_vy, base_vz = base_vz,
        ax = prediction.ax or 0, ay = prediction.ay or 0, az = prediction.az or 0,
        turn_rate = prediction.turn_rate or 0,
        on_ground = bit.band(flags, FL_ONGROUND) ~= 0,
        duck_amount = duck_now,
        duck_target = duck_target,
        hull = {
            min_x = min_x, min_y = min_y, min_z = min_z,
            max_x = max_x, max_y = max_y, max_z = max_z
        }
    }, x, y, z
end

-- Retained as a compatibility/reference implementation; the record-based
-- implementation below is the only one used by runtime callbacks.
local function chlebb_update_prediction_legacy(entindex)
    local x, y, z = chlebb_get_origin(entindex)
    if x == nil then
        final_ticks[entindex] = 0
        prediction_state[entindex] = nil
        return nil
    end

    local velocity_x, velocity_y, velocity_z = chlebb_get_velocity(entindex)
    local base_x, base_y, base_z = chlebb_get_base_velocity(entindex)
    local flags = tonumber((chlebb_get_prop(entindex, "m_fFlags"))) or 0
    local on_ground = bit.band(flags, FL_ONGROUND) ~= 0
    local simtime = tonumber((chlebb_get_prop(entindex, "m_flSimulationTime"))) or 0
    local old_simtime = tonumber((chlebb_get_prop(entindex, "m_flOldSimulationTime"))) or simtime
    local tick_interval = globals.tickinterval()
    if not chlebb_is_finite(tick_interval) or tick_interval <= 0 then tick_interval = 1 / 64 end

    local state = prediction_state[entindex] or {
        ax = 0, ay = 0, az = 0,
        turn_rate = 0,
        choke_ticks = 0,
        confidence = 0.65
    }
    local previous = state.sample
    local simulation_delta = previous and (simtime - previous.simtime) or (simtime - old_simtime)
    local simulation_ticks = simulation_delta > 0 and chlebb_round(simulation_delta / tick_interval) or 0
    local received_update = previous == nil or math.abs(simtime - previous.simtime) > 0.00001
    local teleport = false
    local defensive = previous ~= nil and (simulation_delta < -tick_interval or simulation_ticks > 16)

    if received_update and previous ~= nil and simulation_delta > 0 and simulation_delta <= 0.5 then
        local delta_x, delta_y, delta_z = x - previous.x, y - previous.y, z - previous.z
        local distance_2d = chlebb_length_2d(delta_x, delta_y)
        teleport = distance_2d > 64

        if not teleport then
            local derived_x = delta_x / simulation_delta
            local derived_y = delta_y / simulation_delta
            local derived_z = delta_z / simulation_delta
            if chlebb_length_2d(derived_x, derived_y) < 1000 then
                velocity_x = velocity_x * 0.65 + derived_x * 0.35
                velocity_y = velocity_y * 0.65 + derived_y * 0.35
                velocity_z = velocity_z * 0.65 + derived_z * 0.35
            end
        end

        local raw_ax = (velocity_x - previous.vx) / simulation_delta
        local raw_ay = (velocity_y - previous.vy) / simulation_delta
        local raw_az = (velocity_z - previous.vz) / simulation_delta
        raw_ax, raw_ay = chlebb_limit_horizontal_velocity(raw_ax, raw_ay, MAX_ACCELERATION)
        raw_az = chlebb_clamp(raw_az, -MAX_ACCELERATION, MAX_ACCELERATION)
        state.ax = state.ax * 0.55 + raw_ax * 0.45
        state.ay = state.ay * 0.55 + raw_ay * 0.45
        state.az = state.az * 0.55 + raw_az * 0.45

        local previous_speed = chlebb_length_2d(previous.vx, previous.vy)
        local current_speed = chlebb_length_2d(velocity_x, velocity_y)
        if previous_speed > 20 and current_speed > 20 then
            local previous_yaw = math.deg(math.atan2(previous.vy, previous.vx))
            local current_yaw = math.deg(math.atan2(velocity_y, velocity_x))
            local raw_turn_rate = chlebb_angle_delta(current_yaw, previous_yaw) / simulation_delta
            raw_turn_rate = chlebb_clamp(raw_turn_rate, -720, 720)
            state.turn_rate = state.turn_rate * 0.55 + raw_turn_rate * 0.45
        else
            state.turn_rate = state.turn_rate * 0.65
        end
    end

    local current_tick = globals.tickcount()
    if teleport then state.teleport_until = current_tick + 8 end
    if defensive then state.defensive_until = current_tick + 8 end
    local teleport_active = (state.teleport_until or 0) > current_tick
    local defensive_active = (state.defensive_until or 0) > current_tick

    if received_update then
        -- Always clear an old choke value when a normal record arrives; keeping
        -- it would make later records extrapolate as if they were still stale.
        state.choke_ticks = chlebb_clamp(math.max(0, simulation_ticks - 1), 0, 16)
        state.sample = {
            x = x, y = y, z = z,
            vx = velocity_x, vy = velocity_y, vz = velocity_z,
            simtime = simtime
        }
    end

    local speed = chlebb_length_2d(velocity_x, velocity_y)
    local acceleration = chlebb_length_2d(state.ax, state.ay)
    local stale_ticks = chlebb_clamp(
        chlebb_round(math.max(0, globals.curtime() - simtime) / tick_interval),
        0,
        32
    )
    local confidence = 1
    confidence = confidence - chlebb_clamp(acceleration / MAX_ACCELERATION, 0, 1) * 0.38
    confidence = confidence - chlebb_clamp(math.abs(state.turn_rate) / 360, 0, 1) * 0.34
    if stale_ticks > 2 then
        confidence = confidence - chlebb_clamp((stale_ticks - 2) / 6, 0, 1) * 0.35
    end
    if not on_ground then confidence = confidence * 0.88 end
    if previous == nil then confidence = math.min(confidence, 0.68) end
    if teleport_active or defensive_active then confidence = math.min(confidence, 0.22) end
    confidence = chlebb_clamp(confidence, 0.15, 1)
    state.confidence = state.confidence * 0.55 + confidence * 0.45

    local maximum_ticks = ui.get(extrapolation_ticks) or 0
    local final_tick_value = 0

    if ui.get(extrapolation) and maximum_ticks > 0 and
       (speed >= 1 or math.abs(velocity_z) >= 5) then
        final_tick_value = chlebb_extrapolation_tick_count(
            state.choke_ticks,
            stale_ticks,
            state.confidence,
            maximum_ticks
        )
        if teleport_active or defensive_active then
            -- Teleports and defensive updates invalidate the movement trend.
            -- Retain the record, but do not invent a future position from it.
            final_tick_value = 0
        end
    end

    local min_x, min_y, min_z, max_x, max_y, max_z = chlebb_get_hull(entindex)
    local duck_now = tonumber((chlebb_get_prop(entindex, "m_flDuckAmount"))) or 0
    local duck_target_val = tonumber((chlebb_get_prop(entindex, "m_flDuckSpeed"))) or 0
    if duck_target_val > 0 then
        duck_target_val = bit.band(tonumber((chlebb_get_prop(entindex, "m_fFlags"))) or 0, 2) ~= 0 and 1 or 0
    else
        duck_target_val = duck_now
    end
    local record = {
        x = x, y = y, z = z,
        vx = velocity_x, vy = velocity_y, vz = velocity_z,
        base_vx = base_x, base_vy = base_y, base_vz = base_z,
        ax = state.ax, ay = state.ay, az = state.az,
        turn_rate = state.turn_rate or 0,
        on_ground = on_ground,
        duck_amount = duck_now,
        duck_target = duck_target_val,
        hull = {
            min_x = min_x, min_y = min_y, min_z = min_z,
            max_x = max_x, max_y = max_y, max_z = max_z
        }
    }
    local predicted = chlebb_simulate_movement(entindex, record, final_tick_value)

    if predicted.collided then
        local safe_ticks = math.min(final_tick_value, math.max(1, chlebb_round(final_tick_value * 0.5)))
        -- Do not keep the position from the longer, collided simulation after
        -- shortening the tick count: it belongs to a different time horizon.
        if safe_ticks ~= final_tick_value then
            final_tick_value = safe_ticks
            predicted = chlebb_simulate_movement(entindex, record, final_tick_value)
        end
    end

    final_ticks[entindex] = final_tick_value

    state.x, state.y, state.z = x, y, z
    state.vx, state.vy, state.vz = velocity_x, velocity_y, velocity_z
    state.speed = speed
    state.flags = flags
    state.on_ground = on_ground
    state.simtime = simtime
    state.simulation_ticks = simulation_ticks
    state.stale_ticks = stale_ticks
    state.teleport = teleport_active
    state.defensive = defensive_active
    state.final_ticks = final_tick_value
    state.predicted = predicted
    state.displacement = chlebb_length_2d(predicted.x - x, predicted.y - y)
    prediction_state[entindex] = state
    return state
end
]=]

-- LBY-Breaker detector. Inspects animlayer 3 (adjust / balance) cycle and
-- weight transitions plus the LBY update delta and feet yaw rate to determine
-- whether the enemy is breaking LBY. Returns: active (bool), confidence [0,1],
-- reason. State is kept per-player on the resolver state table.
local function chlebb_detect_lby_breaker(entindex, state, lby, previous_lby, eye_yaw, speed_2d, animstate, layers)
    if state == nil then return false, 0, "none" end

    local br = state.lby_breaker or {
        history = {},
        events = 0,
        confirmed = false,
        confirm_tick = -1024,
        last_event_tick = -1024,
        last_reason = "none",
        last_lby = nil,
        last_moving_lby = nil,
        last_move_tick = nil
    }

    local current_tick = globals.tickcount()
    local event_score = 0
    local reason = "none"

    -- 1) LBY delta vs previous LBY. A legitimate standing update snaps LBY
    --    *toward* the eye yaw (any magnitude, whenever the 1.1s timer fires),
    --    so a large snap alone proves nothing. Only a snap that leaves the
    --    LBY far from the eye yaw afterwards is breaker evidence.
    if previous_lby ~= nil then
        local lby_delta = math.abs(chlebb_angle_delta(lby, previous_lby))
        local eye_delta = math.abs(chlebb_angle_delta(lby, eye_yaw))
        if eye_delta >= LBYBREAKER_LBY_DELTA_SOFT and speed_2d < 80 then
            if lby_delta >= LBYBREAKER_LBY_DELTA_BREAK then
                event_score = event_score + 0.55
                reason = "lby-snap-hard"
            elseif lby_delta >= LBYBREAKER_LBY_DELTA_SOFT then
                event_score = event_score + 0.30
                reason = "lby-snap-soft"
            end
        end
    end

    -- 2) Standing LBY suppression: while standing, the server re-aligns LBY
    --    to the eye yaw once every ~1.1s. If the player has been standing
    --    longer than that without any LBY change and the LBY still sits far
    --    from the eye yaw, the server-side LBY updates are being suppressed.
    --    Impossible legitimately, so this is a hard breaker signature.
    if speed_2d < 5 then
        if br.last_standing_lby ~= nil and
           math.abs(chlebb_angle_delta(lby, br.last_standing_lby)) > 1 then
            br.lby_change_tick = current_tick
        end
        br.last_standing_lby = lby
        local interval = globals.tickinterval()
        if not chlebb_is_finite(interval) or interval <= 0 then interval = 1 / 64 end
        local update_ticks = math.ceil(1.2 / interval)
        local standing_ticks = br.last_move_tick ~= nil and
            (current_tick - br.last_move_tick) or 0
        local since_change = current_tick - (br.lby_change_tick or br.last_move_tick or 0)
        if standing_ticks > update_ticks and since_change > update_ticks then
            local eye_lby_delta = math.abs(chlebb_angle_delta(lby, eye_yaw))
            if eye_lby_delta > LBYBREAKER_LBY_DELTA_SOFT then
                event_score = event_score + 0.60
                if reason == "none" then reason = "lby-suppressed" end
            end
        end
    end

    -- 3) Animlayer 3 (adjust) weight/cycle. The canonical breaker signature
    --    from the public reversing work: when the balance-adjust layer fires,
    --    weight jumps to ~1 and cycle resets. If weight == 1 or cycle jumped
    --    while the player is standing, the breaker fired.
    local adjust = layers and layers[ANIMLAYER_ADJUST + 1]
    if adjust ~= nil then
        local weight = chlebb_clamp(tonumber(adjust.m_flWeight) or 0, 0, 1)
        local cycle = chlebb_clamp(tonumber(adjust.m_flCycle) or 0, 0, 1)
        local prev = br.last_adjust
        if prev ~= nil then
            local weight_jump = math.abs(weight - prev.weight)
            local cycle_jump = math.abs(cycle - prev.cycle)
            -- weight near 1 with a cycle change => balance adjust fired
            if weight >= LBYBREAKER_ADJUST_WEIGHT_THRESHOLD and
               (cycle_jump > 0.05 or prev.weight < 0.5) and speed_2d < 80 then
                event_score = event_score + 0.45
                if reason == "none" then reason = "adjust-weight" end
            -- cycle > 0.92 with weight 0 => breaker recovery (Llama-style)
            elseif weight <= 0.02 and cycle > LBYBREAKER_ADJUST_CYCLE_THRESHOLD and
                   prev.cycle > LBYBREAKER_ADJUST_CYCLE_THRESHOLD then
                event_score = event_score + 0.25
                if reason == "none" then reason = "adjust-recovery" end
            -- sudden weight drop while moving => defensive / breaker cancel
            elseif weight_jump > 0.5 and prev.weight > 0.5 and speed_2d > 30 then
                event_score = event_score + 0.20
                if reason == "none" then reason = "adjust-drop" end
            end
        end
        br.last_adjust = {weight = weight, cycle = cycle}
    end

    -- 3) Feet yaw rate magnitude. A real LBY update produces a brief feet
    --    rotation; a breaker produces a large instantaneous rate.
    if animstate ~= nil then
        local feet_rate = math.abs(tonumber(animstate.m_flFeetYawRate) or 0)
        if feet_rate > LBYBREAKER_BALANCE_RATE_THRESHOLD * 240 and speed_2d < 80 then
            event_score = event_score + 0.20
            if reason == "none" then reason = "feet-rate" end
        end
    end

    -- 4) (removed) Standing-update timing measured from the last movement
    --    tick can never be correct: the 1.1s LBY cadence is anchored to the
    --    previous LBY update, not to when the player stopped, so the first
    --    standing update legitimately fires anywhere within [0, 1.1s]. It
    --    produced constant false confirmations on normal players.
    if speed_2d >= 5 then
        -- While moving (any speed > 5), LBY == real yaw. Cache it as the
        -- "last moving LBY" so we can compare the first standing update
        -- against it. Also update last_move_tick for timing checks.
        br.last_moving_lby = lby
        br.last_move_tick = current_tick
        br.last_lby = lby
    end

    -- Accumulate events with decay on clean updates.
    if event_score > 0.15 then
        br.events = (br.events or 0) + 1
        br.last_event_tick = current_tick
        br.last_reason = reason
        if br.events >= LBYBREAKER_CONFIRM_EVENTS then
            br.confirmed = true
            br.confirm_tick = current_tick
        end
    elseif previous_lby ~= nil and math.abs(chlebb_angle_delta(lby, previous_lby)) < 1 then
        br.events = math.max(0, (br.events or 0) - 0.25)
    end

    -- Expiry: drop confirmation once decay window elapses without new events.
    if br.confirmed and current_tick - br.last_event_tick > LBYBREAKER_HOLD_TICKS then
        if current_tick - br.confirm_tick > LBYBREAKER_DECAY_TICKS then
            br.confirmed = false
            br.events = 0
        end
    end

    state.lby_breaker = br

    if not br.confirmed then return false, 0, "none" end
    local age = current_tick - br.last_event_tick
    local confidence = 1 - chlebb_clamp(age / LBYBREAKER_DECAY_TICKS, 0, 1)
    return true, chlebb_clamp(confidence, 0, 1), br.last_reason or reason
end

local function chlebb_pose_body_yaw(entindex)
    local value = chlebb_get_prop(entindex, "m_flPoseParameter", 11)
    value = tonumber(value)
    if value == nil or value < -0.05 or value > 1.05 then return nil end
    return chlebb_clamp(value * 120 - 60, -60, 60)
end

local function chlebb_smooth_yaw_rate(old_rate, current, previous, delta_time)
    if previous == nil or delta_time <= 0 then return old_rate or 0 end
    local raw_rate = chlebb_angle_delta(current, previous) / delta_time
    raw_rate = chlebb_clamp(raw_rate, -720, 720)
    return (old_rate or 0) * 0.60 + raw_rate * 0.40
end

local function chlebb_defensive_offset(prediction, state, goal_feet_yaw, lby,
                                       pose, layer_side, base_offset, max_desync)
    local candidates = {}
    local function add_candidate(label, value, score)
        value = tonumber(value)
        if value == nil or not chlebb_is_finite(value) then return end
        candidates[#candidates + 1] = {
            label = label,
            value = chlebb_clamp(value, -max_desync, max_desync),
            score = score or 0
        }
    end

    local anchor_yaw = tonumber(prediction.defensive_anchor_yaw)
    local anchor_lby = tonumber(prediction.defensive_anchor_lby)

    -- While the defensive window is open the server writes no records and
    -- the enemy's live orientation is desynced noise. The only trustworthy
    -- anchor is the pre-defensive yaw: the enemy must return to it when the
    -- window ends and they realign to fire. Hard override, no guessing.
    if anchor_yaw ~= nil and (prediction.defensive_ticks_left or 0) > 0 then
        return chlebb_clamp(chlebb_angle_delta(anchor_yaw, goal_feet_yaw), -max_desync, max_desync),
            "def-window-anchor"
    end

    local flick_enabled = chlebb_defensive_mode("Anti-Defensive Flick")
    if flick_enabled and prediction.defensive_flick and anchor_yaw ~= nil then
        add_candidate("flick-goal", chlebb_angle_delta(anchor_yaw, goal_feet_yaw), 8)
        add_candidate("flick-lby", chlebb_angle_delta(anchor_yaw, anchor_lby or lby), 7)
        if state.last_normal_offset ~= nil then
            add_candidate("pre-flick", state.last_normal_offset, 9)
        end
    end

    if pose ~= nil and math.abs(pose) >= 5 then
        add_candidate("def-pose", pose, 6)
    end
    if anchor_yaw ~= nil then
        add_candidate("anchor-lby", chlebb_angle_delta(anchor_yaw, lby), 5)
    end
    if state.defensive_learned_offset ~= nil then
        add_candidate("def-learned", state.defensive_learned_offset, 8)
    end
    if state.last_defensive_hit_offset ~= nil then
        add_candidate("def-hit", state.last_defensive_hit_offset, 9)
    end
    if state.last_normal_offset ~= nil then
        add_candidate("last-normal", state.last_normal_offset,
            prediction.tickbase_exploit and 7 or 4)
    end
    if not prediction.defensive_flick then
        add_candidate("current", base_offset, 3)
    end

    local side = layer_side
    if side == 0 and pose ~= nil then side = chlebb_sign(pose) end
    if side == 0 and state.last_normal_offset ~= nil then
        side = chlebb_sign(state.last_normal_offset)
    end
    if side == 0 then side = state.side or chlebb_sign(base_offset) end
    if side == 0 then side = 1 end
    local severity = chlebb_clamp(prediction.defensive_score or 0.65, 0, 1)
    local magnitude = max_desync * (0.72 + severity * 0.23)
    add_candidate("severity-side", side * magnitude, 3)
    add_candidate("severity-opposite", -side * magnitude, 2)

    local pose_side = pose ~= nil and math.abs(pose) >= 5 and chlebb_sign(pose) or 0
    local learned = tonumber(state.defensive_learned_offset)
    local best
    for index = 1, #candidates do
        local candidate = candidates[index]
        local candidate_side = chlebb_sign(candidate.value)
        if pose_side ~= 0 then
            candidate.score = candidate.score + (candidate_side == pose_side and 2 or -1)
        end
        if layer_side ~= 0 and candidate_side == layer_side then
            candidate.score = candidate.score + 1
        end
        if learned ~= nil then
            local learned_delta = math.abs(candidate.value - learned)
            candidate.score = candidate.score + (learned_delta <= 8 and 3 or
                (candidate_side == chlebb_sign(learned) and 1 or 0))
        end
        if prediction.defensive_flick and candidate.label:find("flick", 1, true) then
            candidate.score = candidate.score + 3
        end
        if prediction.sim_regression and candidate.label == "last-normal" then
            candidate.score = candidate.score + 3
        end
        if math.abs(candidate.value) < 5 then candidate.score = candidate.score - 1 end
        if best == nil or candidate.score > best.score then best = candidate end
    end

    if best == nil then
        return chlebb_clamp(base_offset, -max_desync, max_desync), "def-fallback"
    end
    return best.value, best.label
end

-- main resolver function. Computes desync directly from FFI animstate,
-- animlayers, velocity vectors, pose parameters and entity flags.
-- Normal and defensive feedback are learned independently.

local function i_resolver(entindex, prediction)
    if prediction == nil then return nil end

    local state = resolver_state[entindex] or {
        eye_rate = 0,
        goal_rate = 0,
        lby_rate = 0,
        side = 1,
        lby_break_until = 0,
        lby_last_update = 0,
        lby_update_interval = 0.22
    }

    local eye_pitch, eye_yaw = chlebb_get_prop(entindex, "m_angEyeAngles")
    eye_pitch = tonumber(eye_pitch) or 0
    eye_yaw = tonumber(eye_yaw)
    if eye_yaw == nil then
        eye_yaw = tonumber((chlebb_get_prop(entindex, "m_angEyeAngles[1]"))) or 0
    end
    local lby = tonumber((chlebb_get_prop(entindex, "m_flLowerBodyYawTarget"))) or eye_yaw

    local animstate = chlebb_resolver_ffi.read_animstate(entindex)

    local goal_feet_yaw = animstate and tonumber(animstate.m_flGoalFeetYaw) or nil
    local current_feet_yaw = animstate and tonumber(animstate.m_flCurrentFeetYaw) or nil
    local animstate_eye_yaw = animstate and tonumber(animstate.m_flEyeYaw) or nil
    local torso_yaw = animstate and tonumber(animstate.m_flCurrentTorsoYaw) or nil
    local feet_yaw_rate = animstate and tonumber(animstate.m_flFeetYawRate) or 0
    local speed_2d = animstate and tonumber(animstate.m_flSpeed2D) or 0
    local speed_normalized = animstate and tonumber(animstate.m_flSpeedNormalized) or 0
    local duck_amount = animstate and tonumber(animstate.m_fDuckAmount) or 0
    local animstate_on_ground = true
    if animstate ~= nil then
        animstate_on_ground = not not animstate.m_bOnGround
    end

    if not chlebb_is_finite(goal_feet_yaw) then goal_feet_yaw = lby end
    if not chlebb_is_finite(current_feet_yaw) then current_feet_yaw = goal_feet_yaw end
    if not chlebb_is_finite(animstate_eye_yaw) then animstate_eye_yaw = eye_yaw end
    if not chlebb_is_finite(torso_yaw) then torso_yaw = goal_feet_yaw end

    -- Max desync from the actual CCSGOPlayerAnimState::UpdateVelocity math:
    -- yaw_modifier = ((stop_to_full_running_fraction * -0.3) - 0.2) *
    -- running_fraction + 1, blended towards 0.5 while ducking. Standing gives
    -- the full m_flMaxBodyYaw (58), full run gives ~0.5x (29). Replaces the
    -- old ad-hoc air/duck/speed percentage scalings.
    local max_yaw = animstate and math.abs(tonumber(animstate.m_flMaxYaw) or 0) or 0
    if max_yaw < 10 or max_yaw > 60 then max_yaw = MAX_DESYNC end
    local max_desync = max_yaw
    if animstate ~= nil then
        local stop_fraction = chlebb_clamp(tonumber(animstate.m_flStopToFullRunningFraction) or 0, 0, 1)
        local running_fraction = chlebb_clamp((speed_2d or 0) / (260 * 0.52), 0, 1)
        local yaw_modifier = ((stop_fraction * -0.3) - 0.2) * running_fraction + 1.0
        if duck_amount > 0 then
            local ducking_fraction = chlebb_clamp((speed_2d or 0) / (260 * 0.34), 0, 1)
            yaw_modifier = yaw_modifier + (duck_amount * ducking_fraction) * (0.5 - yaw_modifier)
        end
        max_desync = max_yaw * chlebb_clamp(yaw_modifier, 0, 1)
    end

    local in_air = not animstate_on_ground

    local vel_x, vel_y = chlebb_get_velocity(entindex)

    local vel_speed = math.sqrt(vel_x * vel_x + vel_y * vel_y)
    local velocity_yaw = nil
    if vel_speed > 5 then
        velocity_yaw = math.deg(math.atan2(vel_y, vel_x))
    end

    local simtime = prediction.simtime or 0
    local yaw_delta_time = state.yaw_simtime and (simtime - state.yaw_simtime) or 0
    local new_yaw_record = state.yaw_simtime == nil or math.abs(yaw_delta_time) > 0.00001
    local trusted_yaw_record = new_yaw_record and not prediction.defensive and
        not prediction.quarantined
    if trusted_yaw_record and yaw_delta_time > 0 and yaw_delta_time <= 0.5 then
        state.eye_rate = chlebb_smooth_yaw_rate(state.eye_rate, eye_yaw, state.eye_yaw, yaw_delta_time)
        state.goal_rate = chlebb_smooth_yaw_rate(state.goal_rate, goal_feet_yaw, state.goal_feet_yaw, yaw_delta_time)
        state.lby_rate = chlebb_smooth_yaw_rate(state.lby_rate, lby, state.lby, yaw_delta_time)
    end

    if trusted_yaw_record and state.lby ~= nil then
        local lby_snap = chlebb_angle_delta(lby, state.lby)
        if math.abs(lby_snap) >= 35 and (speed_2d or prediction.speed or 0) < 80 then
            state.lby_break_until = globals.tickcount() + 32
            state.lby_break_side = chlebb_sign(chlebb_angle_delta(eye_yaw, lby))
            if state.lby_break_side == 0 then state.lby_break_side = chlebb_sign(lby_snap) end
            local time_since_last = simtime - (state.lby_last_update or 0)
            if time_since_last > 0.5 and time_since_last < 1.6 then
                -- The real standing LBY cadence is ~1.1s; only learn from
                -- intervals in that regime.
                local prior = state.lby_update_interval or time_since_last
                state.lby_update_interval = prior * 0.5 + time_since_last * 0.5
            end
            state.lby_last_update = simtime
        end
    end

    local lby_break_predicted = false
    if not in_air and (speed_2d or 0) < 5 then
        local time_since_lby = simtime - (state.lby_last_update or 0)
        local interval = state.lby_update_interval or 1.1
        if time_since_lby > interval * 0.85 and time_since_lby < interval * 1.15 then
            lby_break_predicted = true
        end
    end

    if trusted_yaw_record then
        state.eye_yaw = eye_yaw
        state.goal_feet_yaw = goal_feet_yaw
        state.current_feet_yaw = current_feet_yaw
        state.lby = lby
        state.yaw_simtime = simtime
    end

    local horizon = (final_ticks[entindex] or 0) * globals.tickinterval()
    -- Anti-backtrack: anchor on the newest server record. Do not extrapolate
    -- eye/goal/lby yaw rates into the lag-comp window; use the live values.
    if prediction.anti_backtrack then
        horizon = 0
    end
    local predicted_eye_yaw = chlebb_normalize_yaw(
        eye_yaw + chlebb_clamp(state.eye_rate * horizon, -18, 18)
    )
    local predicted_goal_feet_yaw = chlebb_normalize_yaw(
        goal_feet_yaw + chlebb_clamp(state.goal_rate * horizon, -18, 18)
    )
    local predicted_lby = chlebb_normalize_yaw(
        lby + chlebb_clamp(state.lby_rate * horizon, -18, 18)
    )

    if vel_speed > 80 then
        local movement_delta = chlebb_angle_delta(velocity_yaw, predicted_goal_feet_yaw)
        if math.abs(movement_delta) < 120 then
            local movement_blend = chlebb_clamp(vel_speed / 260, 0, 1) * 0.18
            predicted_goal_feet_yaw = chlebb_normalize_yaw(
                predicted_goal_feet_yaw + movement_delta * movement_blend
            )
        end
    end

    local method = ui.get(resolver_type) or "Animstate"
    local source
    local offset

    -- Read animation layers early so the LBY-breaker detector and the
    -- movement/adjust activity analysis can share the same fetch.
    local layers = chlebb_resolver_ffi.read_animation_layers(entindex, ANIMLAYER_MOVEMENT + 1)
    local movement_layer = layers and layers[ANIMLAYER_MOVEMENT + 1]
    local adjust_layer = layers and layers[ANIMLAYER_ADJUST + 1]

    -- LBY-breaker detection. Runs in all modes so the hybrid mode can switch
    -- and the LBY mode can fall back to animstate when the breaker is active.
    local lby_breaker_active, lby_breaker_confidence, lby_breaker_reason =
        chlebb_detect_lby_breaker(
            entindex, state, lby, state.lby, eye_yaw,
            speed_2d or 0, animstate, layers
        )
    state.lby_breaker_active = lby_breaker_active
    state.lby_breaker_confidence = lby_breaker_confidence
    state.lby_breaker_reason = lby_breaker_reason

    -- Method selection grounded in how the server actually animates:
    -- * While moving, the server continuously re-aligns LBY to the eye yaw,
    --   so LBY carries NO desync information. Only the animstate feet yaw
    --   does. LBY/hybrid modes must use the animstate on the move.
    -- * While standing, LBY is the server's real body yaw (unless broken).
    local moving = (speed_2d or 0) > 5 or in_air
    local effective_method = method
    if method == "Lby+Animstate" then
        if lby_breaker_active or moving then
            effective_method = "Animstate"
            source = moving and "hybrid:animstate-moving" or "hybrid:animstate"
        else
            effective_method = "Lby"
            source = "hybrid:lby"
        end
    elseif effective_method == "Lby" and moving then
        effective_method = "Animstate"
        source = "lby:moving-animstate"
    end

    if effective_method == "Lby" then
        offset = chlebb_angle_delta(predicted_eye_yaw, predicted_lby)
        if source == nil then source = "lby" end
    else
        -- The server animates hitboxes at m_flCurrentFeetYaw, which
        -- approaches m_flGoalFeetYaw at m_flFeetYawRate. Predict the current
        -- feet yaw forward over the extrapolation window and clamp it at the
        -- goal -- never overshoot the server's desync target and never flip
        -- to the opposite side of it.
        local goal_offset = chlebb_angle_delta(animstate_eye_yaw, goal_feet_yaw)
        local predicted_feet = chlebb_normalize_yaw(
            current_feet_yaw + (tonumber(feet_yaw_rate) or 0) * horizon
        )
        local current_offset = chlebb_angle_delta(animstate_eye_yaw, predicted_feet)
        if chlebb_sign(current_offset) ~= chlebb_sign(goal_offset) or
           math.abs(current_offset) > math.abs(goal_offset) then
            current_offset = goal_offset
        else
            source = (source or (animstate ~= nil and "animstate" or "animstate:lby-fallback")) .. "+feet-rate"
        end
        offset = current_offset
        if source == nil then
            source = animstate ~= nil and "animstate" or "animstate:lby-fallback"
        end
    end

    -- Moving targets: CCSGOPlayerAnimState::SetupVelocity drives the goal
    -- feet yaw towards the movement direction while clamping it to
    -- [eye - max_desync, eye + max_desync]. The clamped velocity direction is
    -- therefore the minimax estimate for the body yaw -- it beats any noisy
    -- interpolated feet yaw sample.
    local moving_fast = velocity_yaw ~= nil and vel_speed > 80 and not in_air
    if moving_fast and not prediction.defensive then
        offset = chlebb_clamp(chlebb_angle_delta(animstate_eye_yaw, velocity_yaw),
            -max_desync, max_desync)
        source = source .. "+velocity-bound"
    end

    -- When the LBY breaker is active, bias the offset toward the LBY break
    -- side detected by the resolver (the breaker reveals the real desync side
    -- via the snap direction).
    if not moving_fast and lby_breaker_active and state.lby_break_side ~= nil and state.lby_break_side ~= 0 then
        local breaker_side = state.lby_break_side
        if chlebb_sign(offset) ~= breaker_side and math.abs(offset) < max_desync * 0.6 then
            offset = breaker_side * max_desync * 0.85
            source = source .. "+breaker-side"
        end
    end

    local pose = chlebb_pose_body_yaw(entindex)
    if not moving_fast and pose ~= nil and math.abs(offset) < 4 then
        offset = pose
        source = source .. "+pose"
    end

    -- Playback rate, layer cycle and normalized feet speed are magnitudes, not
    -- reliable left/right signals. Use layers only as activity evidence and
    -- derive the side from signed pose/velocity data.
    local movement_activity = 0
    if movement_layer ~= nil then
        local weight = chlebb_clamp(tonumber(movement_layer.m_flWeight) or 0, 0, 1)
        local playback = math.abs(tonumber(movement_layer.m_flPlaybackRate) or 0)
        if playback > 0.001 then movement_activity = weight end
    end

    local adjust_activity = 0
    if adjust_layer ~= nil then
        adjust_activity = chlebb_clamp(tonumber(adjust_layer.m_flWeight) or 0, 0, 1)
    end

    local layer_side = 0
    if pose ~= nil and math.abs(pose) > 5 then
        layer_side = chlebb_sign(pose)
    end

    if velocity_yaw ~= nil then
        local vel_delta = chlebb_angle_delta(velocity_yaw, eye_yaw)
        if math.abs(vel_delta) > 20 and math.abs(vel_delta) < 160 then
            local vel_side = chlebb_sign(vel_delta)
            if layer_side == 0 then
                layer_side = vel_side
            end
        end
    end

    -- Layer/pose side forcing is a fallback for standing targets only. On a
    -- moving enemy the velocity-bound offset is authoritative: forcing a
    -- side there flips correct offsets (e.g. an enemy running straight at us
    -- has a ~0 offset and must stay that way).
    if not moving_fast and math.abs(offset) < 4 and layer_side ~= 0 then
        local layer_scale = 0.50 + math.max(movement_activity, adjust_activity) * 0.10
        offset = layer_side * max_desync * layer_scale
        source = source .. "+layer"
    end

    if not moving_fast and layer_side ~= 0 and chlebb_sign(offset) ~= 0 and chlebb_sign(offset) ~= layer_side then
        offset = layer_side * math.abs(offset)
        source = source .. "+layer-correct"
    end

    if not moving_fast and i_modes("Handle LBY Breaks (beta)") then
        local lby_active = (state.lby_break_until or 0) > globals.tickcount()
        if lby_active or lby_break_predicted then
            local side = state.lby_break_side or layer_side
            if side == 0 then side = chlebb_sign(offset) end
            if side == 0 then side = state.side or 1 end
            offset = side * max_desync * (lby_break_predicted and 0.85 or 0.90)
            source = source .. (lby_break_predicted and "+lby-predict" or "+lby-break")
        end
    end

    local defensive_resolver_active = prediction.defensive and (
        chlebb_defensive_mode("Anti-Defensive AA") or
        (prediction.defensive_flick and chlebb_defensive_mode("Anti-Defensive Flick"))
    )
    if defensive_resolver_active then
        local defensive_source
        offset, defensive_source = chlebb_defensive_offset(
            prediction,
            state,
            predicted_goal_feet_yaw,
            predicted_lby,
            pose,
            layer_side,
            offset,
            max_desync
        )
        source = source .. "+" .. defensive_source
        if prediction.tickbase_exploit then source = source .. "+anti-tickbase" end
        if prediction.defensive_flick then source = source .. "+anti-flick" end
    end

    -- Anti-backtrack: the enemy is manipulating simtime to keep a stale
    -- hitbox valid. Anchor the resolver on the newest animstate/pose signal
    -- and bias the desync toward the side inferred from pose/layers so the
    -- ragebot fires at the head record rather than a backtracked one.
    if prediction.anti_backtrack then
        source = source .. "+anti-backtrack"
        if math.abs(offset) < max_desync * 0.5 and layer_side ~= 0 then
            offset = layer_side * max_desync * 0.85
            source = source .. "+side-anchor"
        end
    end

    local learning_prefix = defensive_resolver_active and "defensive" or "normal"
    local learned_offset = state[learning_prefix .. "_learned_offset"]
    local learned_confidence = state[learning_prefix .. "_learning_confidence"] or 0
    if ui.get(learning) and learned_offset ~= nil then
        local learning_weight = chlebb_clamp(learned_confidence, 0, 1)
        offset = offset * (1 - learning_weight) + learned_offset * learning_weight
        source = source .. (defensive_resolver_active and "+def-learned" or "+learned")
    elseif not ui.get(learning) then
        local prefixes = {"normal", "defensive"}
        for index = 1, #prefixes do
            local prefix = prefixes[index]
            state[prefix .. "_learned_offset"] = nil
            state[prefix .. "_learning_confidence"] = 0
            state[prefix .. "_learning_miss_streak"] = 0
            state[prefix .. "_learning_base_side"] = nil
        end
    end

    offset = chlebb_clamp(offset, -max_desync, max_desync)
    if chlebb_sign(offset) ~= 0 then state.side = chlebb_sign(offset) end
    if not prediction.defensive then state.last_normal_offset = offset end
    state.offset = offset
    state.source = source
    state.method = method
    state.eye_pitch = eye_pitch
    state.predicted_eye_yaw = predicted_eye_yaw
    state.predicted_goal_feet_yaw = predicted_goal_feet_yaw
    state.predicted_lby = predicted_lby
    state.max_desync = max_desync
    state.layer_side = layer_side
    state.defensive_active = defensive_resolver_active
    state.defensive_reason = prediction.defensive_reason
    state.defensive_score = prediction.defensive_score or 0
    state.final_ticks = final_ticks[entindex] or 0
    resolver_state[entindex] = state
    return state
end

local plist_fields = {
    force = {"Force body yaw", "Force Body Yaw"},
    value = {"Force body yaw value", "Force Body Yaw Value"},
    correction = {"Correction active", "Correction Active"},
    high_priority = {"High priority", "High Priority"},
    prefer_baim = {"Prefer body aim", "Prefer Body Aim"},
    prefer_safepoint = {"Prefer safe point", "Prefer Safe Point"},
    force_safepoint = {"Force safe point", "Force Safe Point"},
    -- Anti-backtrack: field names vary across cheat builds; the plist helper
    -- falls back gracefully and caches "false" if none are accepted.
    disable_backtrack = {"Disable backtracking", "Disable Backtracking"}
}
local plist_field_cache = {}
local plist_field_log = {}

local function chlebb_plist_set(entindex, field_key, value)
    if type(plist) ~= "table" or type(plist.set) ~= "function" then return false end
    local cached = plist_field_cache[field_key]
    if cached == false then return false end
    if type(cached) == "string" then
        local ok, result = pcall(plist.set, entindex, cached, value)
        if ok and result ~= false then return true end
        plist_field_cache[field_key] = nil
    end

    local fields = plist_fields[field_key] or {}
    for index = 1, #fields do
        local ok, result = pcall(plist.set, entindex, fields[index], value)
        if ok and result ~= false then
            plist_field_cache[field_key] = fields[index]
            if plist_field_log[field_key] ~= "ok" then
                plist_field_log[field_key] = "ok"
                if ui.get(console_logs) then
                    client.color_log(140, 230, 140,
                        "Chlebb Resolver > plist '" .. fields[index] .. "' accepted")
                end
            end
            return true
        end
    end
    plist_field_cache[field_key] = false
    if plist_field_log[field_key] ~= "fail" then
        plist_field_log[field_key] = "fail"
        if ui.get(console_logs) then
            client.color_log(255, 120, 60,
                "Chlebb Resolver > plist field '" .. field_key ..
                "' NOT accepted - resolver output will NOT reach the ragebot")
        end
    end
    return false
end

-- plist apply resolver
local function i_plist_resolver(entindex, resolved)
    if resolved == nil then return false end
    local ok_force = chlebb_plist_set(entindex, "force", true)
    local ok_value = chlebb_plist_set(entindex, "value", resolved.offset)
    local correction = i_modes("Anti-Aim Correction")
    local ok_correction = chlebb_plist_set(entindex, "correction", correction)
    local prediction = prediction_state[entindex]
    local anti_bt = prediction ~= nil and prediction.anti_backtrack == true
    chlebb_plist_set(
        entindex,
        "high_priority",
        prediction ~= nil and (
            (final_ticks[entindex] or 0) > 0 or
            prediction.defensive or
            prediction.tickbase_exploit or
            prediction.anti_lc_active or
            anti_bt
        )
    )
    -- Anti-backtrack: try to force the ragebot onto the newest record by
    -- disabling the per-player backtrack override. No-ops gracefully if the
    -- cheat build does not expose the field.
    if anti_bt then
        chlebb_plist_set(entindex, "disable_backtrack", true)
    end
    -- Jitter AA reality: the desync side is not networked, so once the
    -- resolver has missed twice on this player the only mechanically sound
    -- answer is to stop chasing the head -- force body aim + safe point
    -- until we land a shot again.
    local resolver_st = resolver_state[entindex]
    local miss_streak = resolver_st ~= nil and math.max(
        tonumber(resolver_st.normal_learning_miss_streak) or 0,
        tonumber(resolver_st.defensive_learning_miss_streak) or 0
    ) or 0
    chlebb_plist_set(entindex, "prefer_baim", miss_streak >= 2)
    chlebb_plist_set(entindex, "prefer_safepoint", miss_streak >= 2)
    chlebb_plist_set(entindex, "force_safepoint", miss_streak >= 3)
    resolved.plist_ok = ok_force and ok_value and (not correction or ok_correction)
    return resolved.plist_ok
end

-- New extrapolation pipeline. It deliberately relies on the most recent
-- network records only; the old extrapolator above is no longer called.
local function chlebb_extrapolation_latency_ticks(interval)
    local latency = 0
    if type(client.latency) == "function" then
        local ok, value = pcall(client.latency)
        if ok and chlebb_is_finite(value) then latency = value end
    end
    return chlebb_clamp(chlebb_round(math.max(0, latency) / interval), 0, 16)
end

local function chlebb_extrapolation_record(entindex)
    local x, y, z = chlebb_get_origin(entindex)
    if x == nil then return nil end

    local vx, vy, vz = chlebb_get_velocity(entindex)
    local base_vx, base_vy, base_vz = chlebb_get_base_velocity(entindex)
    local min_x, min_y, min_z, max_x, max_y, max_z = chlebb_get_hull(entindex)
    local flags = tonumber(chlebb_get_prop(entindex, "m_fFlags")) or 0
    local simtime = tonumber(chlebb_get_prop(entindex, "m_flSimulationTime")) or 0
    local eye_pitch, eye_yaw = chlebb_get_prop(entindex, "m_angEyeAngles")
    eye_pitch = tonumber(eye_pitch) or 0
    eye_yaw = tonumber(eye_yaw)
    if eye_yaw == nil then
        eye_yaw = tonumber(chlebb_get_prop(entindex, "m_angEyeAngles[1]")) or 0
    end
    local lby = tonumber(chlebb_get_prop(entindex, "m_flLowerBodyYawTarget")) or eye_yaw

    return {
        x = x, y = y, z = z,
        vx = vx, vy = vy, vz = vz,
        base_vx = base_vx, base_vy = base_vy, base_vz = base_vz,
        simtime = simtime,
        eye_pitch = eye_pitch,
        eye_yaw = chlebb_normalize_yaw(eye_yaw),
        lby = chlebb_normalize_yaw(lby),
        on_ground = bit.band(flags, FL_ONGROUND) ~= 0,
        duck_amount = tonumber(chlebb_get_prop(entindex, "m_flDuckAmount")) or 0,
        duck_target = bit.band(flags, 2) ~= 0 and 1 or 0,
        hull = {
            min_x = min_x, min_y = min_y, min_z = min_z,
            max_x = max_x, max_y = max_y, max_z = max_z
        }
    }
end

local function chlebb_analyze_motion_history(history, interval)
    if type(history) ~= "table" or #history < 2 then
        return nil
    end

    local total_weight = 0
    local velocity_x, velocity_y = 0, 0
    local acceleration_x, acceleration_y = 0, 0
    local turn_rate, model_error, velocity_jitter = 0, 0, 0
    local samples, acceleration_samples, acceleration_weight = 0, 0, 0
    local previous_observed_x, previous_observed_y

    for index = math.min(#history - 1, 5), 1, -1 do
        local newer = history[index]
        local older = history[index + 1]
        local delta_time = (newer.simtime or 0) - (older.simtime or 0)
        if delta_time > 0 and delta_time <= 0.25 and
           not newer.quarantined and not older.quarantined then
            local observed_x = (newer.x - older.x) / delta_time
            local observed_y = (newer.y - older.y) / delta_time
            local observed_speed = chlebb_length_2d(observed_x, observed_y)
            if observed_speed <= LC_ABSOLUTE_MAX_DERIVED_SPEED then
                local weight = 1 / index
                velocity_x = velocity_x + observed_x * weight
                velocity_y = velocity_y + observed_y * weight
                total_weight = total_weight + weight
                samples = samples + 1

                local expected_x = older.x + (older.vx or 0) * delta_time
                local expected_y = older.y + (older.vy or 0) * delta_time
                model_error = model_error + chlebb_length_2d(
                    newer.x - expected_x,
                    newer.y - expected_y
                ) * weight

                if previous_observed_x ~= nil then
                    velocity_jitter = velocity_jitter + chlebb_length_2d(
                        observed_x - previous_observed_x,
                        observed_y - previous_observed_y
                    ) * weight
                    acceleration_x = acceleration_x +
                        (observed_x - previous_observed_x) / delta_time * weight
                    acceleration_y = acceleration_y +
                        (observed_y - previous_observed_y) / delta_time * weight
                    acceleration_samples = acceleration_samples + 1
                    acceleration_weight = acceleration_weight + weight

                    local current_yaw = math.deg(math.atan2(observed_y, observed_x))
                    local previous_yaw = math.deg(math.atan2(
                        previous_observed_y,
                        previous_observed_x
                    ))
                    turn_rate = turn_rate + chlebb_clamp(
                        chlebb_angle_delta(current_yaw, previous_yaw) / delta_time,
                        -720,
                        720
                    ) * weight
                end
                previous_observed_x, previous_observed_y = observed_x, observed_y
            end
        end
    end

    if total_weight <= 0 or samples == 0 then return nil end
    return {
        vx = velocity_x / total_weight,
        vy = velocity_y / total_weight,
        ax = acceleration_samples > 0 and acceleration_x / acceleration_weight or 0,
        ay = acceleration_samples > 0 and acceleration_y / acceleration_weight or 0,
        turn_rate = acceleration_samples > 0 and turn_rate / acceleration_weight or 0,
        model_error = model_error / total_weight,
        velocity_jitter = velocity_jitter / total_weight,
        samples = samples
    }
end

local function chlebb_extrapolation_horizon(state, interval, maximum_ticks)
    local record = state.record
    if record == nil or state.teleport or state.quarantined or state.lc_candidate then
        return 0, 0
    end
    -- Defensive without AX: no server records exist, predicting a compensated
    -- shot is wasted. With AX the server raycasts current positions, so we
    -- still lead the newest origin by latency.
    if state.defensive and not i_modes("Anti-Exploit (AX)") and not chlebb_god.active then
        return 0, 0
    end

    local stale_ticks = chlebb_clamp(
        chlebb_round(math.max(0, globals.curtime() - record.simtime) / interval),
        0,
        32
    )
    if state.movement == "stationary" and not state.anti_lc_active and stale_ticks <= 0 then
        state.horizon_reason = "stationary"
        return 0, stale_ticks
    end

    -- Horizon is the time until our shot arrives: record age + outgoing ping
    -- + leftover choke. The slider is the hard cap. No confidence cocktail
    -- and no movement-class shrink -- those zeroed the lead on peekers.
    local latency_ticks = chlebb_extrapolation_latency_ticks(interval)
    local requested_ticks = chlebb_clamp(tonumber(maximum_ticks) or 1, 1, 16)
    local choke_lead = chlebb_clamp(tonumber(state.choke_ticks) or 0, 0, requested_ticks)
    local forward_ticks = math.max(1, stale_ticks + latency_ticks + choke_lead)
    local horizon = math.min(forward_ticks, requested_ticks)
    if horizon < 1 then horizon = 1 end
    state.horizon_reason = state.anti_lc_active and "anti-lc" or state.movement
    state.requested_horizon = forward_ticks
    return horizon, stale_ticks
end

local function chlebb_extrapolate_record(entindex, record, state, ticks, interval)
    local x, y, z = record.x, record.y, record.z
    local vx, vy, vz = record.vx, record.vy, record.vz
    local base_vx, base_vy, base_vz = record.base_vx, record.base_vy, record.base_vz
    local ax, ay = state.ax or 0, state.ay or 0
    local turn_rate = chlebb_clamp(
        tonumber(state.history_turn_rate or state.turn_rate) or 0,
        -720,
        720
    )
    local on_ground = record.on_ground
    local hull = {
        min_x = record.hull.min_x, min_y = record.hull.min_y, min_z = record.hull.min_z,
        max_x = record.hull.max_x, max_y = record.hull.max_y, max_z = record.hull.max_z
    }
    local gravity = chlebb_clamp(chlebb_cvar_number("sv_gravity", DEFAULT_GRAVITY), 100, 2000)
    local friction = chlebb_clamp(chlebb_cvar_number("sv_friction", EXTRAP_ACCEL_DEFAULT), 0, 20)
    local stop_speed = chlebb_clamp(chlebb_cvar_number("sv_stopspeed", AUTOSTOP_STOPSPEED_DEFAULT), 0, 250)
    local air_accel = chlebb_clamp(chlebb_cvar_number("sv_airaccelerate", EXTRAP_AIR_ACCEL_DEFAULT), 0, 100)
    local max_speed = chlebb_clamp(chlebb_cvar_number("sv_maxspeed", EXTRAP_MAX_SPEED_DEFAULT), 100, 1000)
    local speed_limit = math.max(MAX_PLAYER_SPEED, chlebb_length_2d(vx, vy)) * 1.10
    local collided = false
    local collision_count = 0
    local stepped = false
    local used_ticks = 0
    local duck_amount = chlebb_clamp(tonumber(record.duck_amount) or 0, 0, 1)
    local duck_target = chlebb_clamp(tonumber(record.duck_target) or duck_amount, 0, 1)

    if state.anti_lc_active and state.lc_velocity_x ~= nil then
        local lc_weight = chlebb_clamp(state.lc_confidence or 0, 0.35, 0.85)
        vx = vx * (1 - lc_weight) + state.lc_velocity_x * lc_weight
        vy = vy * (1 - lc_weight) + state.lc_velocity_y * lc_weight
        if not on_ground and state.lc_velocity_z ~= nil then
            vz = vz * (1 - lc_weight) + state.lc_velocity_z * lc_weight
        end
    end

    for tick = 1, ticks do
        if duck_amount ~= duck_target then
            local duck_step = math.min(0.12, math.abs(duck_target - duck_amount))
            duck_amount = duck_amount + chlebb_sign(duck_target - duck_amount) * duck_step
            hull.max_z = 72 - 18 * duck_amount
        end

        -- Surface speed factor: trace down to get the surface and apply the
        -- surfaceData.maxSpeedFactor. On default surfaces this is 1.0, but on
        -- ice/snow/mud it drops to 0.1-0.75, dramatically changing the stop
        -- horizon. We approximate by probing the ground and using a default
        -- of 1.0 when the surface data is not available (gamesense does not
        -- expose surfaceData directly, so we use the cvar fallback).
        local surface_factor = 1.0
        if on_ground then
            local _, _, _, ground_fraction, _, _, ground_normal_z =
                chlebb_trace_player_move(entindex, x, y, z + EXTRAP_SURFACETRACE_UP, x, y, z - EXTRAP_SURFACETRACE_DOWN, hull)
            if ground_fraction >= 0.999 then
                -- No ground found within the probe distance; treat as air.
                on_ground = false
            end
        end

        -- Turn rate rotation (applies to both ground and air).
        if chlebb_length_2d(vx, vy) > 20 and math.abs(turn_rate) > 8 then
            local turn = math.rad(chlebb_clamp(turn_rate * interval, -12, 12))
            local cos_turn, sin_turn = math.cos(turn), math.sin(turn)
            vx, vy = vx * cos_turn - vy * sin_turn,
                vx * sin_turn + vy * cos_turn
            ax, ay = ax * cos_turn - ay * sin_turn,
                ax * sin_turn + ay * cos_turn
            turn_rate = turn_rate * EXTRAP_TURN_RATE_DECAY
        end

        local before_x, before_y = vx, vy
        local speed_before = chlebb_length_2d(vx, vy)

        if on_ground then
            -- Engine friction model (PM_Friction): drop = max(speed, stopspeed)
            -- * friction * interval. Apply this BEFORE acceleration so the
            -- net velocity reflects the real engine order of operations.
            if speed_before > 0.1 then
                local control = math.max(speed_before, stop_speed)
                local drop = control * friction * interval * surface_factor
                local new_speed = math.max(0, speed_before - drop)
                local scale = new_speed / speed_before
                vx = vx * scale
                vy = vy * scale
            end
            -- Apply user acceleration (input wishdir) capped by sv_accelerate.
            vx = vx + ax * interval
            vy = vy + ay * interval
            vz = 0
        else
            -- Air strafe: acceleration is capped by sv_airaccelerate and the
            -- speed projection onto the wishdir. This prevents the extrapolator
            -- from inventing impossible air direction changes.
            local wish_x = ax
            local wish_y = ay
            local wish_speed = chlebb_length_2d(wish_x, wish_y)
            if wish_speed > 0.1 then
                local wishdir_x = wish_x / wish_speed
                local wishdir_y = wish_y / wish_speed
                local wishspeed_capped = math.min(wish_speed, air_accel * max_speed)
                local currentspeed = vx * wishdir_x + vy * wishdir_y
                local addspeed = wishspeed_capped - currentspeed
                if addspeed > 0 then
                    local accelspeed = math.min(addspeed, air_accel * wishspeed_capped * interval)
                    vx = vx + wishdir_x * accelspeed
                    vy = vy + wishdir_y * accelspeed
                end
            end
        end

        vx, vy = chlebb_limit_horizontal_velocity(vx, vy, speed_limit)

        -- A braking record may predict a stop, never a reversal based solely
        -- on old samples. Acceleration is also decayed every future tick.
        if state.movement == "braking" and before_x * vx + before_y * vy <= 0 then
            vx, vy, ax, ay = 0, 0, 0, 0
        else
            local acceleration_decay = state.movement == "accelerating" and 0.72 or 0.58
            ax, ay = ax * acceleration_decay, ay * acceleration_decay
        end

        local move_z
        if on_ground then
            vz = 0
            move_z = base_vz * interval
        else
            move_z = (vz + base_vz) * interval - 0.5 * gravity * interval * interval
            vz = vz - gravity * interval
        end

        local target_x = x + (vx + base_vx) * interval
        local target_y = y + (vy + base_vy) * interval
        local target_z = z + move_z
        local next_x, next_y, next_z, fraction, normal_x, normal_y, normal_z =
            chlebb_trace_player_move(entindex, x, y, z, target_x, target_y, target_z, hull)

        x, y, z = next_x, next_y, next_z
        used_ticks = tick
        if fraction < 0.999 then
            collided = true
            collision_count = collision_count + 1
            local resolved_collision = false

            -- Ground players commonly hit stairs or low ledges. Try an 18u
            -- step before treating the contact as a wall.
            if on_ground and (normal_z == nil or normal_z < 0.7) then
                local up_x, up_y, up_z, up_fraction = chlebb_trace_player_move(
                    entindex, x, y, z, x, y, z + 18, hull
                )
                if up_fraction > 0.999 then
                    local step_x, step_y, step_z, step_fraction = chlebb_trace_player_move(
                        entindex,
                        up_x, up_y, up_z,
                        up_x + (target_x - x), up_y + (target_y - y), up_z,
                        hull
                    )
                    if step_fraction > 0.999 then
                        local down_x, down_y, down_z, down_fraction, _, _, down_normal_z =
                            chlebb_trace_player_move(
                                entindex,
                                step_x, step_y, step_z,
                                step_x, step_y, step_z - 20,
                                hull
                            )
                        if down_fraction < 0.999 and
                           (down_normal_z == nil or down_normal_z > 0.55) then
                            x, y, z = down_x, down_y, down_z
                            on_ground = true
                            vz = 0
                            stepped = true
                            resolved_collision = true
                        end
                    end
                end
            end

            -- If a plane normal is available, preserve tangential movement and
            -- trace the remaining fraction once more.
            if not resolved_collision and normal_x ~= nil and normal_y ~= nil and normal_z ~= nil then
                -- Multi-step slide: reflect velocity off the plane normal and
                -- trace the remaining fraction, up to EXTRAP_MAX_SLIDE_BOUNCES
                -- times. This handles corner clipping where a single slide
                -- would hit a second wall.
                local remaining = 1 - fraction
                for bounce = 1, EXTRAP_MAX_SLIDE_BOUNCES do
                    local dot = vx * normal_x + vy * normal_y + vz * normal_z
                    if dot < 0 then
                        vx = vx - normal_x * dot
                        vy = vy - normal_y * dot
                        vz = vz - normal_z * dot
                    end
                    if normal_z > EXTRAP_WALL_NORMAL_Z and move_z <= 0 then
                        on_ground = true
                        vz = 0
                    end
                    local slide_x, slide_y, slide_z, slide_fraction, _, _, slide_normal_z =
                        chlebb_trace_player_move(
                            entindex,
                            x, y, z,
                            x + vx * interval * remaining,
                            y + vy * interval * remaining,
                            z + vz * interval * remaining,
                            hull
                        )
                    x, y, z = slide_x, slide_y, slide_z
                    if slide_fraction >= 0.999 then
                        resolved_collision = true
                        break
                    end
                    -- Update normal for the next bounce from the new contact.
                    remaining = remaining * (1 - slide_fraction)
                    if slide_fraction <= 0.05 then
                        vx, vy = 0, 0
                        resolved_collision = true
                        break
                    end
                end
            end

            if not resolved_collision then
                vx, vy, vz = 0, 0, 0
                break
            end
        end

        local ground_x, ground_y, ground_z, ground_fraction, _, _, ground_normal_z =
                chlebb_trace_player_move(entindex, x, y, z + 1, x, y, z - 4, hull)
        if ground_fraction < 0.999 and
           (ground_normal_z == nil or ground_normal_z > 0.55) and vz <= 0 then
            x, y, z = ground_x, ground_y, ground_z
            on_ground = true
            vz = 0
        elseif on_ground then
            on_ground = false
        end
    end

    return {
        x = x, y = y, z = z,
        vx = vx, vy = vy, vz = vz,
        on_ground = on_ground,
        collided = collided,
        collision_count = collision_count,
        stepped = stepped,
        duck_amount = duck_amount,
        used_ticks = used_ticks
    }
end

-- Anti-Backtrack detection. Analyses the per-player simtime / choke history
-- and returns a confidence in [0,1] plus the triggering reason. The caller
-- stores the result on the prediction state and gates extrapolation/early-shot
-- on it so the ragebot is forced onto the newest server-validated record
-- instead of a stale backtracked one.
local function chlebb_detect_backtrack(state, record, previous_raw, signed_simulation_ticks, current_tick)
    if state == nil or record == nil then return 0, "none" end

    local bt = state.backtrack or {
        history = {},
        events = 0,
        last_event_tick = -1024,
        last_reason = "none",
        confirmed = false,
        confirm_tick = -1024
    }

    -- Rolling simtime history tagged with the tick each sample arrived on.
    if previous_raw ~= nil then
        bt.history[#bt.history + 1] = {
            tick = current_tick,
            simtime = record.simtime,
            prev_simtime = previous_raw.simtime,
            sim_ticks = signed_simulation_ticks,
            origin_delta = chlebb_length_2d(
                record.x - previous_raw.x,
                record.y - previous_raw.y
            )
        }
        if #bt.history > ANTIBACKTRACK_HISTORY_SIZE then
            table.remove(bt.history, 1)
        end
    end

    local event_score = 0
    local reason = "none"

    -- 1) Simtime regression: simtime is server-authoritative and strictly
    --    monotonic for legitimate players (fakelag only delays it forward),
    --    so time going backwards is guaranteed tickbase manipulation. Hard
    --    confirmation, no scoring window and no false positives.
    if previous_raw ~= nil and signed_simulation_ticks < 0 then
        event_score = 1
        reason = "simtime-regression"
    end

    -- 2) Simtime oscillation: time goes back then forward (or forward then
    --    back) within a short window. The enemy is cycling simtime to keep a
    --    stale record alive in the lag-comp pool. Also impossible legitimately.
    if event_score == 0 and #bt.history >= 3 then
        local n = #bt.history
        local a, b, c = bt.history[n - 2], bt.history[n - 1], bt.history[n]
        local d1 = a.simtime - b.simtime
        local d2 = b.simtime - c.simtime
        if (d1 < -ANTIBACKTRACK_SIMTIME_JITTER and d2 > ANTIBACKTRACK_SIMTIME_JITTER) or
           (d1 > ANTIBACKTRACK_SIMTIME_JITTER and d2 < -ANTIBACKTRACK_SIMTIME_JITTER) then
            event_score = 1
            reason = "simtime-oscillation"
        end
    end

    -- Both signals are hard confirmations; clean forward updates only shorten
    -- the active window through the decay below.
    if event_score > 0 then
        bt.events = math.max((bt.events or 0) + 1, ANTIBACKTRACK_CONFIRM_EVENTS)
        bt.last_event_tick = current_tick
        bt.last_reason = reason
        bt.confirmed = true
        bt.confirm_tick = current_tick
    elseif previous_raw ~= nil and signed_simulation_ticks > 0 then
        bt.events = math.max(0, (bt.events or 0) - 0.34)
    end

    -- Time-based expiry. Drop confirmation once the decay window elapses.
    if bt.confirmed and current_tick - bt.last_event_tick > ANTIBACKTRACK_HOLD_TICKS then
        if current_tick - bt.confirm_tick > ANTIBACKTRACK_DECAY_TICKS then
            bt.confirmed = false
            bt.events = 0
        end
    end

    state.backtrack = bt

    if not bt.confirmed then return 0, "none" end
    local age = current_tick - bt.last_event_tick
    local confidence = 1 - chlebb_clamp(age / ANTIBACKTRACK_DECAY_TICKS, 0, 1)
    return chlebb_clamp(confidence, 0, 1), bt.last_reason or reason
end

-- Defensive exploit detector (improved). Combines the canonical tickbase
-- delta signature (m_nTickBase > tickcount => queued shift commands) with
-- animlayer weight inversion and velocity-vector rotation analysis. Returns
-- a confidence in [0,1] and the triggering reason set.
local function chlebb_detect_defensive_exploit(entindex, state, record, previous_raw, signed_simulation_ticks, current_tick, layers, animstate)
    if state == nil or record == nil then return 0, {} end

    local dx = state.defensive_exploit or {
        max_tickbase = 0,
        events = 0,
        last_event_tick = -1024,
        reasons = {}
    }

    local interval = globals.tickinterval()
    if not chlebb_is_finite(interval) or interval <= 0 then interval = 1 / 64 end

    local event_score = 0
    local reasons = {}

    -- 1) Tickbase delta: the canonical defensive signature. The enemy's
    --    m_nTickBase runs ahead of tickcount because they queued commands
    --    that the server will shift back. We track the max tickbase seen
    --    and flag when tickbase drops below it (shift consumed).
    local tickbase = tonumber(chlebb_get_prop(entindex, "m_nTickBase")) or 0
    if tickbase > 0 then
        if math.abs(tickbase - dx.max_tickbase) > DEFENSIVE_TICKBASE_RESET_GAP then
            dx.max_tickbase = tickbase
        end
        if tickbase > dx.max_tickbase then
            dx.max_tickbase = tickbase
        elseif dx.max_tickbase > tickbase + DEFENSIVE_TICKBASE_DELTA_TICKS then
            local shift = dx.max_tickbase - tickbase
            event_score = event_score + chlebb_clamp(shift / 14, 0.3, 0.7)
            reasons[#reasons + 1] = "tickbase-shift"
        end
        -- Canonical defensive window: while the consumed tickbase shift is
        -- replayed, simtime does not advance past the highest acknowledged
        -- simtime, so the server writes no lag-comp records for this player
        -- for exactly this many ticks. Hard signal, no heuristic scoring.
        state.defensive_ticks_left = chlebb_clamp(dx.max_tickbase - tickbase - 1, 0, 14)
        -- simtime ahead of curtime => defensive active right now
        local curtime = globals.curtime()
        if record.simtime > curtime + DEFENSIVE_SIMTIME_FUTURE_TICKS * interval then
            event_score = event_score + 0.35
            reasons[#reasons + 1] = "simtime-future"
        end
    end
    state.defensive_tickbase_max = dx.max_tickbase

    -- 2) Velocity-vector rotation: a defensive flick causes an instantaneous
    --    velocity yaw rotation that is physically impossible (no acceleration
    --    could produce it in one tick). Compare the velocity direction now
    --    vs the previous record.
    if previous_raw ~= nil then
        local prev_speed = chlebb_length_2d(previous_raw.vx, previous_raw.vy)
        local cur_speed = chlebb_length_2d(record.vx, record.vy)
        if prev_speed > DEFENSIVE_VELOCITY_ROTATION_SPEED and
           cur_speed > DEFENSIVE_VELOCITY_ROTATION_SPEED then
            local prev_dir = chlebb_vec_normalize_2d({x = previous_raw.vx, y = previous_raw.vy, z = 0})
            local cur_dir = chlebb_vec_normalize_2d({x = record.vx, y = record.vy, z = 0})
            local rotation = math.abs(chlebb_vec_angle_between_2d(prev_dir, cur_dir))
            if rotation >= DEFENSIVE_VELOCITY_ROTATION_DEG then
                event_score = event_score + 0.40
                reasons[#reasons + 1] = "vel-rotation"
            end
        end
    end

    -- 3) Animlayer weight inversion: defensive AA breaks the movement layer.
    --    While moving at speed, the movement layer weight should be ~1. If it
    --    drops to near-zero while the network speed is high, the enemy is
    --    using defensive AA to desync the animation state.
    local movement = layers and (layers[ANIMLAYER_MOVEMENT + 1] or
        chlebb_resolver_ffi.get_layer(entindex, ANIMLAYER_MOVEMENT + 1))
    if movement ~= nil then
        local weight = chlebb_clamp(tonumber(movement.m_flWeight) or 0, 0, 1)
        local playback = math.abs(tonumber(movement.m_flPlaybackRate) or 0)
        local network_speed = chlebb_length_2d(record.vx, record.vy)
        if network_speed > 80 and weight < DEFENSIVE_ANIMLAYER_INVERT_WEIGHT and
           playback <= DEFENSIVE_ANIMLAYER_INVERT_PLAYBACK + 0.01 then
            event_score = event_score + 0.35
            reasons[#reasons + 1] = "animlayer-invert"
        end
    end

    -- 4) Feet yaw rate spike while standing: defensive AA produces a large
    --    feet yaw rotation that is not a real LBY break.
    if animstate ~= nil then
        local feet_rate = math.abs(tonumber(animstate.m_flFeetYawRate) or 0)
        local speed_2d = tonumber(animstate.m_flSpeed2D) or 0
        if feet_rate > 180 and speed_2d < 30 then
            event_score = event_score + 0.25
            reasons[#reasons + 1] = "feet-spike"
        end
    end

    -- Accumulate with decay.
    if event_score > 0.15 then
        dx.events = (dx.events or 0) + 1
        dx.last_event_tick = current_tick
        dx.last_event_score = event_score
        dx.reasons = reasons
    elseif previous_raw ~= nil and signed_simulation_ticks > 0 then
        dx.events = math.max(0, (dx.events or 0) - 0.30)
    end

    state.defensive_exploit = dx

    if dx.events < 1 then return 0, {} end
    local age = current_tick - dx.last_event_tick
    local confidence = chlebb_clamp(dx.last_event_score or event_score, 0, 1) *
        (1 - chlebb_clamp(age / 64, 0, 1))
    return chlebb_clamp(confidence, 0, 1), dx.reasons or {}
end

local function chlebb_update_prediction(entindex)
    local record = chlebb_extrapolation_record(entindex)
    if record == nil then
        final_ticks[entindex] = 0
        prediction_state[entindex] = nil
        return nil
    end

    local interval = globals.tickinterval()
    if not chlebb_is_finite(interval) or interval <= 0 then interval = 1 / 64 end
    local state = prediction_state[entindex] or {
        history = {},
        confidence = 0,
        defensive_score = 0,
        defensive_clean_records = 0
    }
    local previous_trusted = state.record
    local previous_raw = state.raw_record or previous_trusted
    local received_update = previous_raw == nil or
        math.abs(record.simtime - previous_raw.simtime) > 0.00001
    local current_tick = globals.tickcount()
    local defensive_enabled = chlebb_any_defensive_mode() or i_modes("Anti-Exploit (AX)")
    local anti_tickbase_enabled = chlebb_defensive_mode("Anti-Tickbase Exploit")
    local anti_backtrack_enabled = i_modes("Anti-Backtrack")
    local backtrack_confidence, backtrack_reason = 0, "none"

    if received_update then
        local delta_time = previous_raw and (record.simtime - previous_raw.simtime) or 0
        local signed_simulation_ticks = previous_raw and chlebb_round(delta_time / interval) or 1
        local simulation_ticks = math.max(0, signed_simulation_ticks)
        local distance = previous_raw and
            chlebb_length_2d(record.x - previous_raw.x, record.y - previous_raw.y) or 0
        local previous_speed = previous_raw and
            chlebb_length_2d(previous_raw.vx, previous_raw.vy) or 0
        local network_speed = chlebb_length_2d(record.vx, record.vy)

        local sim_regression = previous_raw ~= nil and signed_simulation_ticks < 0
        local forward_shift = previous_raw ~= nil and
            signed_simulation_ticks > DEFENSIVE_FORWARD_SHIFT_TICKS
        local time_gap = previous_raw ~= nil and delta_time > 0.25
        local tickbase_anomaly = sim_regression or forward_shift
        local delta_x = previous_raw and record.x - previous_raw.x or 0
        local delta_y = previous_raw and record.y - previous_raw.y or 0
        local origin_delta_sqr = delta_x * delta_x + delta_y * delta_y
        local lagcomp_break = previous_raw ~= nil and
            origin_delta_sqr > LC_BREAK_DISTANCE * LC_BREAK_DISTANCE
        local displacement_velocity_x = previous_raw and delta_time > 0 and
            delta_x / delta_time or 0
        local displacement_velocity_y = previous_raw and delta_time > 0 and
            delta_y / delta_time or 0
        local displacement_velocity_z = previous_raw and delta_time > 0 and
            (record.z - previous_raw.z) / delta_time or 0
        local displacement_speed = chlebb_length_2d(
            displacement_velocity_x,
            displacement_velocity_y
        )
        local tick_window_valid = signed_simulation_ticks >= LC_MIN_SIM_TICKS and
            signed_simulation_ticks <= LC_MAX_SIM_TICKS and delta_time > 0
        local plausible_speed_cap = math.min(
            LC_ABSOLUTE_MAX_DERIVED_SPEED,
            math.max(MAX_PLAYER_SPEED, previous_speed, network_speed) * 1.35
        )
        local derived_speed_valid = displacement_speed <= plausible_speed_cap
        local network_speed_valid = network_speed <= LC_ABSOLUTE_MAX_DERIVED_SPEED
        local distance_valid = distance <= LC_MAX_RECONSTRUCT_DISTANCE and
            distance <= plausible_speed_cap * math.max(delta_time, interval) + 12
        local speed_agreement = 1 - chlebb_clamp(
            math.abs(displacement_speed - network_speed) /
                math.max(displacement_speed, network_speed, 1),
            0,
            1
        )
        local direction_cosine = 0
        if previous_speed > 10 and displacement_speed > 10 then
            direction_cosine = chlebb_clamp(
                (previous_raw.vx * displacement_velocity_x +
                 previous_raw.vy * displacement_velocity_y) /
                (previous_speed * displacement_speed),
                -1,
                1
            )
        elseif displacement_speed <= 10 then
            direction_cosine = 1
        end
        local expected_delta_x = previous_raw and
            ((previous_raw.vx or 0) + record.vx) * 0.5 * math.max(delta_time, 0) or 0
        local expected_delta_y = previous_raw and
            ((previous_raw.vy or 0) + record.vy) * 0.5 * math.max(delta_time, 0) or 0
        local path_residual = chlebb_length_2d(
            delta_x - expected_delta_x,
            delta_y - expected_delta_y
        )
        local residual_limit = math.max(12, distance * 0.35)
        local residual_agreement = 1 - chlebb_clamp(
            path_residual / math.max(residual_limit, 1),
            0,
            1
        )

        local lc_evidence = 0
        if lagcomp_break and not tickbase_anomaly then
            if tick_window_valid then lc_evidence = lc_evidence + 0.18 end
            if derived_speed_valid then lc_evidence = lc_evidence + 0.20 end
            if distance_valid then lc_evidence = lc_evidence + 0.22 end
            lc_evidence = lc_evidence + speed_agreement * 0.15
            lc_evidence = lc_evidence +
                chlebb_clamp(direction_cosine * 0.5 + 0.5, 0, 1) * 0.13
            lc_evidence = lc_evidence + residual_agreement * 0.12
        end
        lc_evidence = chlebb_clamp(lc_evidence, 0, 1)

        local lc_followup_confirmed = false
        local lc_source_velocity_x = displacement_velocity_x
        local lc_source_velocity_y = displacement_velocity_y
        local lc_source_velocity_z = displacement_velocity_z
        if not lagcomp_break and state.lc_phase == "candidate" and previous_raw ~= nil and
           current_tick - (state.lc_candidate_tick or current_tick) <= LC_HOLD_TICKS and
           signed_simulation_ticks >= 1 and signed_simulation_ticks <= 4 then
            local candidate_speed = chlebb_length_2d(
                state.lc_candidate_velocity_x or 0,
                state.lc_candidate_velocity_y or 0
            )
            local followup_speed = displacement_speed
            local followup_alignment = 0
            if candidate_speed > 10 and followup_speed > 10 then
                followup_alignment = chlebb_clamp(
                    ((state.lc_candidate_velocity_x or 0) * displacement_velocity_x +
                     (state.lc_candidate_velocity_y or 0) * displacement_velocity_y) /
                    (candidate_speed * followup_speed),
                    -1,
                    1
                )
            end
            local followup_speed_agreement = 1 - chlebb_clamp(
                math.abs(followup_speed - network_speed) /
                    math.max(followup_speed, network_speed, 1),
                0,
                1
            )
            lc_followup_confirmed = followup_alignment >= 0.45 and
                followup_speed_agreement >= 0.55 and
                network_speed <= LC_ABSOLUTE_MAX_DERIVED_SPEED
            if lc_followup_confirmed then
                lc_source_velocity_x = (state.lc_candidate_velocity_x or record.vx) * 0.35 +
                    record.vx * 0.65
                lc_source_velocity_y = (state.lc_candidate_velocity_y or record.vy) * 0.35 +
                    record.vy * 0.65
                lc_source_velocity_z = record.vz
                lc_evidence = math.max(state.lc_candidate_score or 0, LC_CONFIRM_SCORE)
            end
        end

        local motion_consistent = speed_agreement >= 0.45 and
            direction_cosine >= 0.25 and residual_agreement >= 0.30
        local lc_reconstructable = (HIDDEN_ANTI_LC_BREAK and i_modes("Anti-LagComp Break")) and (
            (lagcomp_break and lc_evidence >= LC_CONFIRM_SCORE and
             tick_window_valid and derived_speed_valid and network_speed_valid and
             distance_valid and motion_consistent) or
            lc_followup_confirmed
        )
        local lc_candidate = (HIDDEN_ANTI_LC_BREAK and i_modes("Anti-LagComp Break")) and lagcomp_break and
            not tickbase_anomaly and not lc_reconstructable and
            lc_evidence >= LC_CANDIDATE_SCORE
        local hard_teleport = lagcomp_break and not tickbase_anomaly and
            not lc_reconstructable and not lc_candidate
        local lc_confidence = lc_reconstructable and lc_evidence or 0

        if anti_backtrack_enabled then
            backtrack_confidence, backtrack_reason = chlebb_detect_backtrack(
                state, record, previous_raw, signed_simulation_ticks, current_tick
            )
        end

        -- Improved defensive exploit detection: tickbase delta + velocity
        -- rotation + animlayer inversion + feet yaw spike. Runs whenever any
        -- defensive mode is enabled and feeds into the anomaly_score below.
        local defensive_exploit_confidence = 0
        local defensive_exploit_reasons = {}
        if defensive_enabled then
            local exploit_layers = chlebb_resolver_ffi.read_animation_layers(
                entindex, ANIMLAYER_MOVEMENT + 1)
            defensive_exploit_confidence, defensive_exploit_reasons =
                chlebb_detect_defensive_exploit(
                    entindex, state, record, previous_raw,
                    signed_simulation_ticks, current_tick,
                    exploit_layers, chlebb_resolver_ffi.read_animstate(entindex)
                )
        end

        if lc_reconstructable then
            state.lc_phase = "confirmed"
            state.lc_recovery_records = 0
            state.lc_candidate = false
        elseif lc_candidate then
            state.lc_phase = "candidate"
            state.lc_candidate = true
            state.lc_candidate_score = lc_evidence
            state.lc_candidate_velocity_x = displacement_velocity_x
            state.lc_candidate_velocity_y = displacement_velocity_y
            state.lc_candidate_velocity_z = displacement_velocity_z
            state.lc_candidate_tick = current_tick
            state.lc_candidate_ticks = simulation_ticks
            state.lc_candidate_distance = distance
        elseif lagcomp_break and not tickbase_anomaly then
            state.lc_phase = "rejected"
            state.lc_candidate = false
            state.lc_candidate_score = nil
        elseif state.lc_phase == "confirmed" then
            state.lc_candidate = false
            state.lc_recovery_records = (state.lc_recovery_records or 0) + 1
            if state.lc_recovery_records >= LC_RECOVERY_RECORDS and
               current_tick > (state.lc_until_tick or 0) then
                state.lc_phase = "clean"
            end
        elseif state.lc_phase == "candidate" and not lc_followup_confirmed then
            state.lc_phase = "rejected"
            state.lc_candidate = false
            state.lc_candidate_score = nil
        elseif not lagcomp_break then
            state.lc_phase = "clean"
            state.lc_candidate = false
        end
        local high_choke = simulation_ticks >= 12

        local yaw_delta = previous_raw and
            chlebb_angle_delta(record.eye_yaw, previous_raw.eye_yaw) or 0
        local pitch_delta = previous_raw and
            math.abs((record.eye_pitch or 0) - (previous_raw.eye_pitch or 0)) or 0
        local lby_delta = previous_raw and
            math.abs(chlebb_angle_delta(record.lby, previous_raw.lby)) or 0
        local raw_flick = previous_raw ~= nil and math.abs(yaw_delta) >= DEFENSIVE_FLICK_DELTA
        local was_defensive = (state.defensive_until_tick or 0) >= current_tick and
            (state.defensive_score or 0) >= 0.40
        local defensive_flick = raw_flick and
            (tickbase_anomaly or was_defensive or (time_gap and high_choke))
        local defensive_pitch_flick = (pitch_delta >= 70 or math.abs(record.eye_pitch or 0) > 89) and
            (tickbase_anomaly or was_defensive or (time_gap and high_choke))
        local defensive_lby_snap = lby_delta >= 45 and
            (tickbase_anomaly or was_defensive)

        local flick_return = false
        if state.pending_flick_anchor_yaw ~= nil then
            flick_return = math.abs(chlebb_angle_delta(
                record.eye_yaw,
                state.pending_flick_anchor_yaw
            )) <= DEFENSIVE_FLICK_RETURN_DELTA
            if flick_return then
                state.defensive_flick_confirmed_until = current_tick + 16
                state.defensive_anchor_yaw = state.pending_flick_anchor_yaw
                state.defensive_anchor_lby = state.pending_flick_anchor_lby
            end
            state.pending_flick_anchor_yaw = nil
            state.pending_flick_anchor_lby = nil
        end

        if defensive_flick and not flick_return then
            state.pending_flick_anchor_yaw = previous_raw.eye_yaw
            state.pending_flick_anchor_lby = previous_raw.lby
            state.defensive_anchor_yaw = previous_raw.eye_yaw
            state.defensive_anchor_lby = previous_raw.lby
            state.defensive_flick_delta = yaw_delta
            state.defensive_flick_until = current_tick + 16
        end

        local reasons = {}
        local anomaly_score = (state.defensive_score or 0) * 0.35
        if sim_regression then anomaly_score = anomaly_score + 0.70 end
        if forward_shift then anomaly_score = anomaly_score + 0.60 end
        if time_gap then anomaly_score = anomaly_score + 0.30 end
        if hard_teleport then anomaly_score = anomaly_score + 0.20 end
        if high_choke then anomaly_score = anomaly_score + 0.08 end
        if defensive_flick then anomaly_score = anomaly_score + 0.40 end
        if defensive_pitch_flick then anomaly_score = anomaly_score + 0.25 end
        if defensive_lby_snap then anomaly_score = anomaly_score + 0.18 end
        if flick_return then anomaly_score = anomaly_score + 0.20 end
        -- Improved defensive exploit detector contribution. The tickbase /
        -- velocity-rotation / animlayer-inversion signals are independent of
        -- the simtime / flick signals above, so they stack additively.
        if defensive_exploit_confidence > 0 then
            anomaly_score = anomaly_score + defensive_exploit_confidence * 0.45
            for _, r in ipairs(defensive_exploit_reasons) do
                local already = false
                for _, existing in ipairs(reasons) do
                    if existing == r then already = true break end
                end
                if not already then reasons[#reasons + 1] = r end
            end
        end
        state.defensive_score = chlebb_clamp(anomaly_score, 0, 1)

        local defensive_event = tickbase_anomaly or defensive_flick or
            defensive_pitch_flick or defensive_lby_snap or flick_return or
            state.defensive_score >= 0.72 or
            (defensive_exploit_confidence > 0 and #defensive_exploit_reasons >= DEFENSIVE_MULTI_EVENT_THRESHOLD)
        if defensive_event then
            local hold_ticks = chlebb_clamp(
                math.abs(signed_simulation_ticks) + 8,
                DEFENSIVE_MIN_HOLD_TICKS,
                DEFENSIVE_MAX_HOLD_TICKS
            )
            state.defensive_until_tick = math.max(
                state.defensive_until_tick or 0,
                current_tick + hold_ticks
            )
            state.defensive_clean_records = 0
            if state.defensive_anchor_yaw == nil and previous_raw ~= nil then
                state.defensive_anchor_yaw = previous_raw.eye_yaw
                state.defensive_anchor_lby = previous_raw.lby
            end
        else
            state.defensive_clean_records = (state.defensive_clean_records or 0) + 1
            if state.defensive_clean_records >= DEFENSIVE_RECOVERY_RECORDS and
               current_tick > (state.defensive_until_tick or 0) then
                state.defensive_score = state.defensive_score * 0.35
                state.defensive_anchor_yaw = nil
                state.defensive_anchor_lby = nil
                state.defensive_flick_delta = nil
                state.quarantined_record = nil
            end
        end

        if sim_regression then reasons[#reasons + 1] = "sim-regression" end
        if forward_shift then reasons[#reasons + 1] = "forward-shift" end
        if time_gap then reasons[#reasons + 1] = "time-gap" end
        if hard_teleport then reasons[#reasons + 1] = "teleport" end
        if defensive_flick then reasons[#reasons + 1] = "yaw-flick" end
        if defensive_pitch_flick then reasons[#reasons + 1] = "pitch-flick" end
        if defensive_lby_snap then reasons[#reasons + 1] = "lby-snap" end
        if flick_return then reasons[#reasons + 1] = "flick-return" end
        if high_choke and #reasons > 0 then reasons[#reasons + 1] = "high-choke" end
        if lc_reconstructable then reasons[#reasons + 1] = "lc-break" end
        if #reasons > 0 then
            state.last_defensive_reason = table.concat(reasons, "+")
        end

        state.signed_simulation_ticks = signed_simulation_ticks
        state.choke_ticks = chlebb_clamp(math.max(0, simulation_ticks - 1), 0, 16)
        state.sim_regression = sim_regression
        state.forward_shift = forward_shift
        state.tickbase_anomaly = tickbase_anomaly
        state.defensive_pitch_flick = defensive_pitch_flick
        state.defensive_lby_snap = defensive_lby_snap
        state.raw_lagcomp_discontinuity = lagcomp_break
        state.lagcomp_break = lc_reconstructable
        state.teleport = hard_teleport
        state.lc_reconstructable = lc_reconstructable
        if lc_reconstructable then
            state.lc_confidence = lc_confidence
            state.lc_break_distance = lc_followup_confirmed and
                (state.lc_candidate_distance or distance) or distance
            state.lc_break_ticks = math.max(
                1,
                lc_followup_confirmed and
                    (state.lc_candidate_ticks or simulation_ticks) or simulation_ticks
            )
            state.lc_velocity_x = lc_source_velocity_x
            state.lc_velocity_y = lc_source_velocity_y
            state.lc_velocity_z = lc_source_velocity_z
            state.lc_until_tick = current_tick + LC_HOLD_TICKS
            state.lc_events = (state.lc_events or 0) + 1
            state.lc_candidate_score = nil
            state.lc_candidate_ticks = nil
            state.lc_candidate_distance = nil
        elseif hard_teleport then
            state.lc_confidence = 0
            state.lc_until_tick = 0
            state.lc_candidate_ticks = nil
            state.lc_candidate_distance = nil
        end
        state.quarantined = anti_tickbase_enabled and
            (tickbase_anomaly or (defensive_flick and was_defensive))
        if tickbase_anomaly then
            state.tickbase_events = (state.tickbase_events or 0) + 1
        end
        if defensive_flick or defensive_pitch_flick then
            state.defensive_flick_events = (state.defensive_flick_events or 0) + 1
        end
        if state.quarantined then
            state.quarantined_records = (state.quarantined_records or 0) + 1
        end

        record.defensive = defensive_event
        record.tickbase_anomaly = tickbase_anomaly
        record.defensive_flick = defensive_flick or flick_return
        record.defensive_pitch_flick = defensive_pitch_flick
        record.defensive_lby_snap = defensive_lby_snap
        record.raw_lagcomp_discontinuity = lagcomp_break
        record.lagcomp_break = lc_reconstructable
        record.anti_lc_reconstructed = lc_reconstructable
        record.lc_confidence = lc_confidence
        record.quarantined = state.quarantined
        record.yaw_delta = yaw_delta

        local can_derive_motion = previous_raw ~= nil and not state.quarantined and
            not defensive_event and not was_defensive and
            delta_time > 0 and delta_time <= 0.25 and
            not lagcomp_break
        if lc_reconstructable then
            local blend = chlebb_clamp(lc_confidence, 0.45, 0.85)
            record.vx = record.vx * (1 - blend) + lc_source_velocity_x * blend
            record.vy = record.vy * (1 - blend) + lc_source_velocity_y * blend
            if not record.on_ground then
                record.vz = record.vz * (1 - blend) + lc_source_velocity_z * blend
            end
            state.ax = chlebb_clamp(
                (record.vx - previous_raw.vx) / delta_time,
                -1600,
                1600
            )
            state.ay = chlebb_clamp(
                (record.vy - previous_raw.vy) / delta_time,
                -1600,
                1600
            )
            local lc_source_speed = chlebb_length_2d(
                lc_source_velocity_x,
                lc_source_velocity_y
            )
            if previous_speed > 15 and lc_source_speed > 15 then
                local current_yaw = math.deg(math.atan2(
                    lc_source_velocity_y,
                    lc_source_velocity_x
                ))
                local previous_yaw = math.deg(math.atan2(previous_raw.vy, previous_raw.vx))
                state.turn_rate = chlebb_clamp(
                    chlebb_angle_delta(current_yaw, previous_yaw) / delta_time,
                    -540,
                    540
                )
            else
                state.turn_rate = 0
            end
        elseif can_derive_motion then
            local derived_vx = (record.x - previous_raw.x) / delta_time
            local derived_vy = (record.y - previous_raw.y) / delta_time
            if chlebb_length_2d(derived_vx, derived_vy) < 600 then
                record.vx = record.vx * 0.65 + derived_vx * 0.35
                record.vy = record.vy * 0.65 + derived_vy * 0.35
            end
            state.ax = chlebb_clamp((record.vx - previous_raw.vx) / delta_time, -2000, 2000)
            state.ay = chlebb_clamp((record.vy - previous_raw.vy) / delta_time, -2000, 2000)
            if chlebb_length_2d(record.vx, record.vy) > 15 and
               chlebb_length_2d(previous_raw.vx, previous_raw.vy) > 15 then
                local current_yaw = math.deg(math.atan2(record.vy, record.vx))
                local previous_yaw = math.deg(math.atan2(previous_raw.vy, previous_raw.vx))
                state.turn_rate = chlebb_clamp(
                    chlebb_angle_delta(current_yaw, previous_yaw) / delta_time,
                    -720,
                    720
                )
            else
                state.turn_rate = 0
            end
        else
            state.ax, state.ay, state.turn_rate = 0, 0, 0
        end

        local history = state.history
        table.insert(history, 1, record)
        if #history > 12 then table.remove(history) end
        local accept_motion_record = previous_raw == nil or lc_reconstructable or (
            not state.quarantined and not defensive_event and not was_defensive and
            not hard_teleport and not lc_candidate and not lagcomp_break
        )
        if accept_motion_record then
            state.motion_history = state.motion_history or {}
            table.insert(state.motion_history, 1, record)
            if #state.motion_history > 8 then table.remove(state.motion_history) end
        end
        state.raw_record = record
        if not state.quarantined or state.record == nil then
            state.record = record
            state.last_valid_record = record
        else
            state.quarantined_record = record
        end
    end

    -- Anti-backtrack state must persist across no-update ticks. The detector
    -- only runs on real updates, so on idle ticks recompute confidence from
    -- the stored confirmation window so the active flag does not flicker.
    if anti_backtrack_enabled then
        local bt_state = state.backtrack
        if bt_state ~= nil and bt_state.confirmed and backtrack_confidence <= 0 then
            local age = current_tick - (bt_state.last_event_tick or current_tick)
            if age <= ANTIBACKTRACK_DECAY_TICKS then
                backtrack_confidence = 1 - chlebb_clamp(age / ANTIBACKTRACK_DECAY_TICKS, 0, 1)
                backtrack_reason = bt_state.last_reason or "hold"
            end
        end
        state.anti_backtrack = backtrack_confidence > 0
        state.anti_backtrack_confidence = backtrack_confidence
        state.anti_backtrack_reason = backtrack_reason
    else
        state.anti_backtrack = false
        state.anti_backtrack_confidence = 0
        state.anti_backtrack_reason = "none"
    end

    if state.lc_candidate and
       current_tick - (state.lc_candidate_tick or current_tick) > LC_HOLD_TICKS then
        -- An unconfirmed record must never silently become trusted just because
        -- it got old. Keep prediction stopped until a fresh record replaces it.
        state.lc_candidate = false
        state.lc_phase = "rejected"
        state.lc_candidate_score = nil
        state.lc_candidate_ticks = nil
        state.lc_candidate_distance = nil
        state.lc_reconstructable = false
        state.lagcomp_break = false
        state.teleport = true
    end

    record = state.record
    if record == nil then return nil end
    state.defensive = defensive_enabled and (
        (state.defensive_until_tick or 0) >= current_tick or
        (state.defensive_score or 0) >= 0.65 or
        (state.defensive_ticks_left or 0) > 0
    )
    state.defensive_flick = chlebb_defensive_mode("Anti-Defensive Flick") and (
        (state.defensive_flick_until or 0) >= current_tick or
        (state.defensive_flick_confirmed_until or 0) >= current_tick
    )
    state.tickbase_exploit = anti_tickbase_enabled and state.defensive and
        (state.tickbase_anomaly or state.sim_regression or state.forward_shift)
    state.defensive_reason = state.defensive and
        (state.last_defensive_reason or "score") or "none"
    state.anti_lc_active = (HIDDEN_ANTI_LC_BREAK and i_modes("Anti-LagComp Break")) and ui.get(extrapolation) and
        not state.defensive and not state.quarantined and not state.teleport and
        state.lc_phase == "confirmed" and not state.lc_candidate and
        (state.lc_until_tick or 0) >= current_tick and
        (state.lc_confidence or 0) >= 0.30

    local motion_model = chlebb_analyze_motion_history(state.motion_history, interval)
    if motion_model ~= nil then
        state.model_error = motion_model.model_error
        state.velocity_jitter = motion_model.velocity_jitter
        state.history_turn_rate = state.turn_rate * 0.55 + motion_model.turn_rate * 0.45
        if received_update and not state.defensive and not state.teleport and
           motion_model.samples >= 2 then
            local history_weight = state.anti_lc_active and 0.50 or 0.32
            record.vx = record.vx * (1 - history_weight) + motion_model.vx * history_weight
            record.vy = record.vy * (1 - history_weight) + motion_model.vy * history_weight
            state.ax = state.ax * 0.65 +
                chlebb_clamp(motion_model.ax, -1600, 1600) * 0.35
            state.ay = state.ay * 0.65 +
                chlebb_clamp(motion_model.ay, -1600, 1600) * 0.35
        end
    else
        state.model_error = state.model_error or 0
        state.velocity_jitter = state.velocity_jitter or 0
        state.history_turn_rate = state.turn_rate or 0
    end

    local speed = chlebb_length_2d(record.vx, record.vy)
    local acceleration = chlebb_length_2d(state.ax or 0, state.ay or 0)
    local direction_change = 0
    if previous_trusted ~= nil and record ~= previous_trusted and
       speed > 15 and chlebb_length_2d(previous_trusted.vx, previous_trusted.vy) > 15 then
        local current_yaw = math.deg(math.atan2(record.vy, record.vx))
        local previous_yaw = math.deg(math.atan2(previous_trusted.vy, previous_trusted.vx))
        direction_change = math.abs(chlebb_angle_delta(current_yaw, previous_yaw))
    end

    if speed < 4 and math.abs(record.vz) < 5 then
        state.movement = "stationary"
    elseif not record.on_ground then
        state.movement = "air"
    elseif direction_change > 18 then
        state.movement = "turning"
    elseif (record.vx * (state.ax or 0) + record.vy * (state.ay or 0)) < -150 then
        state.movement = "braking"
    elseif acceleration > 120 then
        state.movement = "accelerating"
    else
        state.movement = "stable"
    end

    local confidence = previous_trusted == nil and 0 or 0.96
    confidence = confidence - chlebb_clamp(acceleration / 1800, 0, 1) * 0.28
    confidence = confidence - chlebb_clamp(direction_change / 90, 0, 1) * 0.45
    confidence = confidence - chlebb_clamp((state.choke_ticks or 0) / 16, 0, 1) * 0.25
    confidence = confidence - chlebb_clamp((state.model_error or 0) / 32, 0, 1) * 0.30
    confidence = confidence - chlebb_clamp((state.velocity_jitter or 0) / 300, 0, 1) * 0.18
    if state.movement == "air" then confidence = confidence - 0.12 end
    if state.teleport or state.defensive or state.quarantined then confidence = 0 end
    if state.anti_lc_active then
        confidence = confidence * 0.55 + (state.lc_confidence or 0) * 0.45
    end
    state.confidence = chlebb_clamp(confidence, 0, 1)

    local maximum_ticks = tonumber(ui.get(extrapolation_ticks)) or 0
    local ticks, stale_ticks = 0, 0
    if ui.get(extrapolation) then
        ticks, stale_ticks = chlebb_extrapolation_horizon(state, interval, maximum_ticks)
    end
    local predicted = chlebb_extrapolate_record(entindex, record, state, ticks, interval)
    final_ticks[entindex] = predicted.used_ticks

    state.x, state.y, state.z = record.x, record.y, record.z
    state.vx, state.vy, state.vz = record.vx, record.vy, record.vz
    state.speed = speed
    state.simtime = record.simtime
    state.stale_ticks = stale_ticks
    state.final_ticks = predicted.used_ticks
    state.predicted = predicted
    state.displacement = chlebb_length_2d(predicted.x - record.x, predicted.y - record.y)
    state.prediction_collisions = predicted.collision_count or 0
    state.prediction_stepped = predicted.stepped == true
    prediction_state[entindex] = state
    return state
end

local function chlebb_clear_player(entindex)
    chlebb_extrap.restore(entindex, true)
    chlebb_plist_set(entindex, "force", false)
    chlebb_plist_set(entindex, "correction", false)
    chlebb_plist_set(entindex, "high_priority", false)
    chlebb_plist_set(entindex, "disable_backtrack", false)
    final_ticks[entindex] = nil
    prediction_state[entindex] = nil
    resolver_state[entindex] = nil
    hold_shot_state[entindex] = nil
end

local function chlebb_clear_runtime()
    local cleared = {}
    local resolver_players = {}
    for entindex in pairs(resolver_state) do
        resolver_players[#resolver_players + 1] = entindex
    end
    for index = 1, #resolver_players do
        local entindex = resolver_players[index]
        chlebb_clear_player(entindex)
        cleared[entindex] = true
    end
    local players = entity.get_players(true) or {}
    for index = 1, #players do
        local entindex = players[index]
        if not cleared[entindex] then chlebb_clear_player(entindex) end
    end
    for shot_id in pairs(shot_data) do shot_data[shot_id] = nil end
    for ent in pairs(hold_shot_state) do hold_shot_state[ent] = nil end
    runtime_active = false
end

local function chlebb_update_players()
    -- Engine already wrote the newest networked origin/bones. Do not put the
    -- previous frame's origin back on top of that update.
    chlebb_extrap.discard()
    if not ui.get(enable) then
        if runtime_active then chlebb_clear_runtime() end
        return
    end
    runtime_active = true

    local seen = {}
    local players = entity.get_players(true) or {}
    for index = 1, #players do
        local entindex = players[index]
        if entity.is_alive(entindex) and not entity.is_dormant(entindex) then
            seen[entindex] = true
            local prediction = chlebb_update_prediction(entindex)
            local resolved = i_resolver(entindex, prediction)
            i_plist_resolver(entindex, resolved)
        else
            chlebb_clear_player(entindex)
        end
    end

    local stale_players = {}
    for entindex in pairs(final_ticks) do
        if not seen[entindex] then stale_players[#stale_players + 1] = entindex end
    end
    for index = 1, #stale_players do
        chlebb_clear_player(stale_players[index])
    end

    local current_tick = globals.tickcount()
    for shot_id, shot in pairs(shot_data) do
        if current_tick - (shot.tick or current_tick) > 128 then
            shot_data[shot_id] = nil
        end
    end

    -- Push predicted origin/bones before the ragebot samples this frame.
    chlebb_extrap.apply_all()
end

local function chlebb_ragebot_active(cmd)
    if rage_enabled_ref ~= nil and not chlebb_safe_ui_get(rage_enabled_ref, false) then
        return false
    end
    if rage_enabled_hotkey_ref ~= nil and not chlebb_safe_ui_get(rage_enabled_hotkey_ref, false) then
        return false
    end
    if automatic_fire_ref ~= nil and not chlebb_safe_ui_get(automatic_fire_ref, false) then
        return cmd.in_attack == 1
    end
    return true
end

local function chlebb_weapon_can_fire(local_player, weapon)
    if weapon == nil then return false end
    local classname = string.lower(entity.get_classname(weapon) or "")
    if classname:find("knife", 1, true) or classname:find("grenade", 1, true) or
       classname:find("c4", 1, true) or classname:find("taser", 1, true) or
       classname:find("molotov", 1, true) or classname:find("decoy", 1, true) or
       classname:find("flashbang", 1, true) then
        return false
    end

    local clip = tonumber((chlebb_get_prop(weapon, "m_iClip1")))
    if clip ~= nil and clip <= 0 then return false end
    if tonumber((chlebb_get_prop(weapon, "m_bInReload"))) == 1 then return false end

    local current_time = globals.curtime()
    local next_attack = tonumber((chlebb_get_prop(local_player, "m_flNextAttack"))) or 0
    local next_primary = tonumber((chlebb_get_prop(weapon, "m_flNextPrimaryAttack"))) or 0
    return current_time + 0.0001 >= next_attack and current_time + 0.0001 >= next_primary
end

local function chlebb_minimum_damage(target)
    local configured = tonumber(chlebb_safe_ui_get(minimum_damage_ref, 1)) or 1
    if damage_override_value_ref ~= nil and
       chlebb_safe_ui_get(damage_override_ref, false) and
       chlebb_safe_ui_get(damage_override_hotkey_ref, false) then
        configured = tonumber(chlebb_safe_ui_get(damage_override_value_ref, configured)) or configured
    end

    local health = tonumber((chlebb_get_prop(target, "m_iHealth"))) or 100
    if configured > 100 then
        return health + configured - 100
    end
    return math.min(configured, health)
end

local function chlebb_scale_point_damage(target, hitgroup, damage)
    if type(client.scale_damage) == "function" then
        local ok, scaled = pcall(client.scale_damage, target, hitgroup, damage)
        if ok and chlebb_is_finite(scaled) then return scaled end
    end
    if hitgroup == 1 then return damage * 4 end
    if hitgroup == 3 then return damage * 1.25 end
    if hitgroup == 6 or hitgroup == 7 then return damage * 0.75 end
    return damage
end

local function chlebb_predicted_aim_point(local_player, target, prediction)
    local eye_x, eye_y, eye_z = client.eye_position()
    if not chlebb_is_finite(eye_x) or not chlebb_is_finite(eye_y) or not chlebb_is_finite(eye_z) then
        return nil
    end

    local applied = chlebb_extrap.applied[target]
    local delta_x = prediction.predicted.x - prediction.x
    local delta_y = prediction.predicted.y - prediction.y
    local delta_z = prediction.predicted.z - prediction.z
    if applied ~= nil then
        -- Origin/bones already include the applied lead. Only add leftover.
        delta_x = delta_x - applied.dx
        delta_y = delta_y - applied.dy
        delta_z = delta_z - applied.dz
    end
    local required_damage = chlebb_minimum_damage(target)
    local points = {
        {hitbox = 0,  hitgroup = 1},
        {hitbox = 1,  hitgroup = 1},
        {hitbox = 2,  hitgroup = 3},
        {hitbox = 3,  hitgroup = 2},
        {hitbox = 4,  hitgroup = 2},
        {hitbox = 5,  hitgroup = 2},
        {hitbox = 6,  hitgroup = 4},
        {hitbox = 7,  hitgroup = 5},
        {hitbox = 8,  hitgroup = 5},
        {hitbox = 9,  hitgroup = 6},
        {hitbox = 10, hitgroup = 6},
        {hitbox = 11, hitgroup = 7},
        {hitbox = 12, hitgroup = 7},
        {hitbox = 13, hitgroup = 0},
        {hitbox = 14, hitgroup = 0},
        {hitbox = 15, hitgroup = 0},
        {hitbox = 16, hitgroup = 0},
        {hitbox = 17, hitgroup = 0},
        {hitbox = 18, hitgroup = 0}
    }
    local best

    for index = 1, #points do
        local point = points[index]
        local ok_position, hitbox_x, hitbox_y, hitbox_z = pcall(
            entity.hitbox_position,
            target,
            point.hitbox
        )
        if ok_position and chlebb_is_finite(hitbox_x) and
           chlebb_is_finite(hitbox_y) and chlebb_is_finite(hitbox_z) then
            local predicted_x = hitbox_x + delta_x
            local predicted_y = hitbox_y + delta_y
            local predicted_z = hitbox_z + delta_z
            local ok_trace, _, damage = pcall(
                client.trace_bullet,
                local_player,
                eye_x,
                eye_y,
                eye_z,
                predicted_x,
                predicted_y,
                predicted_z,
                true
            )
            damage = tonumber(damage) or 0
            if ok_trace and damage > 0 then
                local ok_verify, verify_entindex, verify_damage = pcall(
                    client.trace_bullet,
                    local_player,
                    eye_x,
                    eye_y,
                    eye_z,
                    predicted_x,
                    predicted_y,
                    predicted_z,
                    false
                )
                if not ok_verify or tonumber(verify_entindex) ~= target then
                    goto continue
                end
                damage = chlebb_scale_point_damage(target, point.hitgroup, damage)
                if damage >= required_damage and (best == nil or damage > best.damage) then
                    best = {
                        x = predicted_x, y = predicted_y, z = predicted_z,
                        damage = damage,
                        hitbox = point.hitbox,
                        hitgroup = point.hitgroup
                    }
                end
            end
        end
        ::continue::
    end

    if best == nil then return nil end
    local difference_x = best.x - eye_x
    local difference_y = best.y - eye_y
    local difference_z = best.z - eye_z
    local horizontal = math.sqrt(difference_x * difference_x + difference_y * difference_y)
    best.pitch = -math.deg(math.atan2(difference_z, horizontal))
    best.yaw = math.deg(math.atan2(difference_y, difference_x))
    return best
end

--[=[
Legacy early-shot implementation retained for reference only and excluded from
compilation. Runtime uses the record-based command path below.
local function chlebb_early_shot_legacy(cmd)
    if not ui.get(enable) or not ui.get(extrapolation) or not chlebb_ragebot_active(cmd) then return end
    if (tonumber(cmd.chokedcommands) or 0) > 0 then return end

    local target = type(client.current_threat) == "function" and client.current_threat() or nil
    if not target or not entity.is_enemy(target) or not entity.is_alive(target) or entity.is_dormant(target) then
        return
    end

    local prediction = prediction_state[target]
    if prediction == nil then return end
    if prediction.teleport or prediction.defensive then return end

    local tick_interval = globals.tickinterval()
    if not chlebb_is_finite(tick_interval) or tick_interval <= 0 then
        tick_interval = 1 / 64
    end
    local fresh_stale = chlebb_clamp(
        chlebb_round(math.max(0, globals.curtime() - (prediction.simtime or 0)) / tick_interval),
        0, 32
    )
    local maximum_ticks = ui.get(extrapolation_ticks) or 0
    local tick_count = chlebb_extrapolation_tick_count(
        prediction.choke_ticks,
        fresh_stale,
        prediction.confidence,
        maximum_ticks
    )
    if tick_count <= 0 then return end

    local fresh_prediction = prediction
    local fresh_record, fresh_x, fresh_y, fresh_z = chlebb_build_fresh_record(target, prediction)
    if fresh_record == nil then return end

    if tick_count ~= (prediction.final_ticks or 0) then
        local fresh_predicted = chlebb_simulate_movement(target, fresh_record, tick_count)
        fresh_prediction = {
            x = fresh_x, y = fresh_y, z = fresh_z,
            predicted = fresh_predicted,
            simtime = prediction.simtime,
            displacement = chlebb_length_2d(fresh_predicted.x - fresh_x, fresh_predicted.y - fresh_y)
        }
    end

    if fresh_prediction.predicted == nil then return end
    if fresh_prediction.predicted.collided then
        local safe_ticks = math.min(tick_count, math.max(1, chlebb_round(tick_count * 0.5)))
        if safe_ticks ~= tick_count then
            tick_count = safe_ticks
            local fresh_predicted = chlebb_simulate_movement(target, fresh_record, tick_count)
            -- Do not mutate prediction_state here: it may be used by the
            -- resolver in the same frame with its original tick horizon.
            fresh_prediction = {
                x = fresh_x, y = fresh_y, z = fresh_z,
                predicted = fresh_predicted,
                simtime = prediction.simtime,
                displacement = chlebb_length_2d(fresh_predicted.x - fresh_x, fresh_predicted.y - fresh_y)
            }
        end
    end

    final_ticks[target] = tick_count
    prediction.final_ticks = tick_count

    local displacement = fresh_prediction.displacement or prediction.displacement or 0
    if displacement < 0.1 or displacement > 128 then return end

    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then return end
    local weapon = entity.get_player_weapon(local_player)
    if not chlebb_weapon_can_fire(local_player, weapon) then return end

    local aim_point = chlebb_predicted_aim_point(local_player, target, fresh_prediction)
    if aim_point == nil then return end

    i_autostop(cmd)

    local current_tick = globals.tickcount()
    if current_tick == last_early_shot_tick then
        return
    end

    cmd.pitch = chlebb_clamp(aim_point.pitch, -89, 89)
    cmd.yaw = chlebb_normalize_yaw(aim_point.yaw)
    cmd.in_attack = 1
    last_early_shot_tick = current_tick
    prediction.early_shot_tick = current_tick
    prediction.early_damage = aim_point.damage
    prediction.early_hitbox = aim_point.hitbox
    prediction.early_command = cmd.command_number
end
]=]

local function chlebb_snapshot_shot(e)
    if not ui.get(enable) or e.target == nil then return end
    local prediction = prediction_state[e.target]
    local resolved = resolver_state[e.target]
    local shot_id = e.id or ("target:" .. tostring(e.target) .. ":" .. tostring(globals.tickcount()))
    shot_data[shot_id] = {
        id = shot_id,
        target = e.target,
        final_ticks = final_ticks[e.target] or 0,
        hit_chance = tonumber(e.hit_chance or e.hitchance) or 0,
        damage = tonumber(e.damage) or 0,
        backtrack = tonumber(e.backtrack) or 0,
        native_extrapolated = e.extrapolated == true,
        early = prediction ~= nil and
            globals.tickcount() - (prediction.early_shot_tick or -1024) <= 2,
        resolver_offset = resolved and resolved.offset or 0,
        resolver_source = resolved and resolved.source or "none",
        defensive = prediction ~= nil and prediction.defensive == true,
        defensive_flick = prediction ~= nil and prediction.defensive_flick == true,
        tickbase_exploit = prediction ~= nil and prediction.tickbase_exploit == true,
        defensive_reason = prediction and prediction.defensive_reason or "none",
        defensive_score = prediction and prediction.defensive_score or 0,
        anti_lc = prediction ~= nil and prediction.anti_lc_active == true,
        lc_confidence = prediction and prediction.lc_confidence or 0,
        lc_break_distance = prediction and prediction.lc_break_distance or 0,
        anti_backtrack = prediction ~= nil and prediction.anti_backtrack == true,
        anti_backtrack_confidence = prediction and prediction.anti_backtrack_confidence or 0,
        anti_backtrack_reason = prediction and prediction.anti_backtrack_reason or "none",
        lby_breaker = resolved ~= nil and resolved.lby_breaker_active == true,
        lby_breaker_confidence = resolved and resolved.lby_breaker_confidence or 0,
        lby_breaker_reason = resolved and resolved.lby_breaker_reason or "none",
        hold_shot = prediction ~= nil and prediction.hold_shot_active == true,
        hold_shot_reason = prediction and prediction.hold_shot_reason or "none",
        tick = globals.tickcount()
    }
end

local function chlebb_take_shot(e)
    local shot
    if e.id ~= nil then
        shot = shot_data[e.id]
        shot_data[e.id] = nil
    end
    if shot == nil and e.target ~= nil then
        local newest_id, newest_tick = nil, -math.huge
        for shot_id, candidate in pairs(shot_data) do
            if candidate.target == e.target and (candidate.tick or 0) > newest_tick then
                newest_id = shot_id
                newest_tick = candidate.tick or 0
                shot = candidate
            end
        end
        if newest_id ~= nil then shot_data[newest_id] = nil end
    end
    return shot
end

local function chlebb_learn_shot(target, hit, reason, shot)
    if target == nil then return end
    local state = resolver_state[target]
    if state == nil then return end

    if not ui.get(learning) then
        local prefixes = {"normal", "defensive"}
        for index = 1, #prefixes do
            local prefix = prefixes[index]
            state[prefix .. "_learned_offset"] = nil
            state[prefix .. "_learning_confidence"] = 0
            state[prefix .. "_learning_miss_streak"] = 0
            state[prefix .. "_learning_base_side"] = nil
        end
        return
    end

    local defensive_shot = shot ~= nil and shot.defensive == true
    local prefix = defensive_shot and "defensive" or "normal"
    local offset_key = prefix .. "_learned_offset"
    local confidence_key = prefix .. "_learning_confidence"
    local streak_key = prefix .. "_learning_miss_streak"
    local side_key = prefix .. "_learning_base_side"
    local shot_offset = tonumber(shot and shot.resolver_offset) or tonumber(state.offset) or 0
    if hit then
        state.last_hit_tick = globals.tickcount()
        state.last_hit_offset = shot_offset
        state[offset_key] = shot_offset
        state[confidence_key] = 1
        state[streak_key] = 0
        state[side_key] = chlebb_sign(shot_offset)
        if state[side_key] == 0 then state[side_key] = state.side or 1 end
        if defensive_shot then state.last_defensive_hit_offset = shot_offset end
        return
    end

    reason = string.lower(tostring(reason or "unknown"))
    local resolver_miss = reason == "resolver" or reason == "?" or reason == "unknown"
    if not resolver_miss then
        -- Spread, prediction and death misses do not contain resolver feedback.
        state[confidence_key] = math.max(0, (state[confidence_key] or 0) - 0.10)
        return
    end

    state[streak_key] = (state[streak_key] or 0) + 1
    if state[side_key] == nil or state[side_key] == 0 then
        state[side_key] = chlebb_sign(shot_offset)
        if state[side_key] == 0 then state[side_key] = state.side or 1 end
    end

    -- No brute-force fraction cycling: a resolver miss carries one bit of
    -- trustworthy information (the side was wrong). Flip the side and keep
    -- the magnitude of the offset that missed; the computed resolver takes
    -- over again from there.
    local max_desync = chlebb_clamp(tonumber(state.max_desync) or MAX_DESYNC, 10, MAX_DESYNC)
    state[side_key] = -state[side_key]
    local magnitude = chlebb_clamp(math.abs(shot_offset), max_desync * 0.45, max_desync)
    state[offset_key] = state[side_key] * magnitude
    state[confidence_key] = 1
    if defensive_shot then state.last_defensive_hit_offset = nil end
end

-- Hold Shot evaluator. Looks ahead HOLD_SHOT_MAX_WAIT_TICKS into the
-- predicted future of the target and decides whether waiting yields a
-- materially better shot (higher damage, higher hitchance, or a clean
-- post-defensive window). Returns true when the current shot should be
-- suppressed (held) in favour of the predicted opportunity.
local function chlebb_evaluate_hold_shot(target, state, current_damage, current_hitchance, current_tick)
    if not ui.get(hold_shot) then return false end
    if target == nil or state == nil or state.record == nil then return false end

    -- Cooldown: do not re-evaluate every command tick; the prediction does
    -- not change fast enough to justify it and we want the ragebot to act on
    -- the last decision.
    if current_tick - last_hold_eval_tick < HOLD_SHOT_COOLDOWN_TICKS then
        local hs = hold_shot_state[target]
        return hs ~= nil and (hs.hold_until_tick or 0) >= current_tick
    end
    last_hold_eval_tick = current_tick

    local interval = globals.tickinterval()
    if not chlebb_is_finite(interval) or interval <= 0 then interval = 1 / 64 end
    local maximum_ticks = tonumber(ui.get(extrapolation_ticks)) or 0
    if maximum_ticks <= 0 then return false end

    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then return false end
    local weapon = entity.get_player_weapon(local_player)
    if not chlebb_weapon_can_fire(local_player, weapon) then return false end

    -- Case 1: defensive recovery. If the target is currently defensive but
    -- the defensive window ends within HOLD_SHOT_DEFENSIVE_RECOVER_TICKS,
    -- hold the shot so we fire at the clean post-defensive record.
    if state.defensive and (state.defensive_until_tick or 0) > current_tick then
        local ticks_until_clean = (state.defensive_until_tick or 0) - current_tick
        if ticks_until_clean > 0 and ticks_until_clean <= HOLD_SHOT_DEFENSIVE_RECOVER_TICKS then
            hold_shot_state[target] = {
                hold_until_tick = current_tick + ticks_until_clean,
                reason = "defensive-recover",
                predicted_damage = current_damage,
                predicted_hitchance = current_hitchance
            }
            return true
        end
    end

    -- Case 2: predicted higher-damage opportunity. Simulate the target's
    -- movement over the next HOLD_SHOT_MAX_WAIT_TICKS and check whether a
    -- future position yields a materially better shot.
    if current_damage <= 0 then
        hold_shot_state[target] = nil
        return false
    end

    local best_future_damage = current_damage
    local best_future_tick = 0

    local look_ticks = math.min(HOLD_SHOT_MAX_WAIT_TICKS, maximum_ticks)
    for future_tick = 1, look_ticks do
        local predicted = chlebb_extrapolate_record(target, state.record, state, future_tick, interval)
        if predicted == nil or predicted.used_ticks < future_tick then break end
        local future_prediction = {
            x = state.record.x, y = state.record.y, z = state.record.z,
            predicted = predicted,
            displacement = chlebb_length_2d(predicted.x - state.record.x, predicted.y - state.record.y)
        }
        local aim_point = chlebb_predicted_aim_point(local_player, target, future_prediction)
        if aim_point ~= nil then
            local future_damage = tonumber(aim_point.damage) or 0
            local damage_gain = future_damage - current_damage
            local damage_ratio = future_damage / math.max(current_damage, 1)
            if damage_gain >= HOLD_SHOT_MIN_DAMAGE_GAIN and
               damage_ratio >= HOLD_SHOT_MIN_DAMAGE_RATIO then
                if future_damage > best_future_damage then
                    best_future_damage = future_damage
                    best_future_tick = future_tick
                end
            end
        end
    end

    if best_future_tick > 0 then
        hold_shot_state[target] = {
            hold_until_tick = current_tick + best_future_tick,
            reason = "damage-gain",
            predicted_damage = best_future_damage
        }
        return true
    end

    -- No better opportunity: clear any existing hold and let the shot fire.
    hold_shot_state[target] = nil
    return false
end

-- Autosniper God Mode: while a sniper rifle is equipped, route every
-- defensive target through the AX lag-compensation bypass. Do not create a
-- second local table -- horizon/AX already close over the early chlebb_god.
chlebb_god.saved_dt = nil
chlebb_god.saved_autofire = nil
chlebb_god.dt_ref = select(1, safe_ui_reference("RAGE", "Other", "Double tap"))
chlebb_god.dt_hc_ref = select(1, safe_ui_reference("RAGE", "Other", "Double tap hit chance"))

function chlebb_god.is_active()
    if not ui.get(enable) or not ui.get(god_mode) then return false end
    local local_player = entity.get_local_player()
    if local_player == nil or not entity.is_alive(local_player) then return false end
    local weapon = entity.get_player_weapon(local_player)
    if weapon == nil then return false end
    local classname = string.lower(entity.get_classname(weapon) or "")
    return classname:find("ssg08", 1, true) ~= nil or
        classname:find("awp", 1, true) ~= nil or
        classname:find("g3sg1", 1, true) ~= nil or
        classname:find("scar20", 1, true) ~= nil
end

function chlebb_god.apply(active)
    chlebb_god.active = active == true
end

-- Anti-Exploit (AX). Real bypass instead of heuristics: while an enemy sits
-- in the defensive/tickbase window the server stores no lag-compensation
-- records for them, so compensated shots can never hit. AX tells the server
-- to skip lag compensation for our shots (cl_lagcompensation is
-- FCVAR_USERINFO and the server mirrors it into m_bLagCompensation) and then
-- aims at the newest networked record led by our own latency, because the
-- server raycasts current positions when compensation is off.
local chlebb_ax = {
    max_lead_ticks = 16,
    max_displacement = 96,
    lagcomp_disabled = false
}

function chlebb_ax.set_lagcomp(disabled)
    if disabled == chlebb_ax.lagcomp_disabled then return end
    chlebb_ax.lagcomp_disabled = disabled

    -- cvar object first (gamesense-style), client.set_cvar as fallback.
    local applied = false
    if cvar ~= nil and cvar.cl_lagcompensation ~= nil then
        applied = pcall(function()
            cvar.cl_lagcompensation:set_int(disabled and 0 or 1)
        end)
    end
    if not applied and type(client.set_cvar) == "function" then
        applied = pcall(client.set_cvar, "cl_lagcompensation", disabled and "0" or "1")
    end

    local readback = chlebb_cvar_number("cl_lagcompensation", -1)
    local expected = disabled and 0 or 1
    local verified = applied and math.abs(readback - expected) < 0.01
    if ui.get(console_logs) then
        client.color_log(
            verified and 140 or 255, verified and 230 or 60, verified and 140 or 60,
            "Chlebb Resolver > AX: cl_lagcompensation " .. expected ..
            (verified and " [OK]" or " [FAILED - cheat does not expose this cvar]")
        )
    end
end

function chlebb_ax.latency_ticks(interval)
    local latency = 0
    if type(client.latency) == "function" then
        local ok, value = pcall(client.latency)
        if ok and chlebb_is_finite(value) then latency = math.max(0, value) end
    end
    return chlebb_clamp(chlebb_round(latency / interval) + 1, 1, chlebb_ax.max_lead_ticks)
end

function chlebb_ax.threat_needs_bypass()
    if not i_modes("Anti-Exploit (AX)") and not chlebb_god.active then return false end
    local players = entity.get_players(true) or {}
    for index = 1, #players do
        local player = players[index]
        if entity.is_alive(player) and not entity.is_dormant(player) then
            local threat_state = prediction_state[player]
            if threat_state ~= nil and (
                threat_state.defensive or
                threat_state.tickbase_exploit or
                (threat_state.defensive_ticks_left or 0) > 0
            ) then
                return true
            end
        end
    end
    return false
end

function chlebb_ax.setup_command(cmd)
    chlebb_god.apply(chlebb_god.is_active())
    if not ui.get(enable) then
        chlebb_ax.set_lagcomp(false)
        chlebb_extrap.restore_all(true)
        return
    end
    chlebb_ax.set_lagcomp(chlebb_ax.threat_needs_bypass())
    chlebb_extrap.apply_all()
end

-- Command-time prediction uses the same record/history model as the net-update
-- pass. It never reuses the legacy early-shot extrapolator.
local function chlebb_early_shot(cmd)
    if not ui.get(enable) or not ui.get(extrapolation) or not chlebb_ragebot_active(cmd) then return end
    if (tonumber(cmd.chokedcommands) or 0) > 0 then return end

    local target = type(client.current_threat) == "function" and client.current_threat() or nil
    if not target or not entity.is_enemy(target) or not entity.is_alive(target) or entity.is_dormant(target) then
        return
    end

    local state = prediction_state[target]
    if state == nil or state.record == nil then return end

    -- Defensive targets have no server lag-comp records, so the normal
    -- compensated path can never hit them. Only proceed when the AX bypass
    -- (lag compensation disabled) covers this shot. AX takes precedence over
    -- anti-backtrack: both react to simtime regression, but with lag
    -- compensation off the newest led record is exactly what we want to hit.
    local ax_shot = (state.defensive or chlebb_god.active) and
        (i_modes("Anti-Exploit (AX)") or chlebb_god.active) or false
    if state.teleport or (state.defensive and not ax_shot) then
        return
    end

    -- Do not fire from a prediction whose network record changed after the
    -- net-update pass. The next pass will rebuild history/anti-LC state.
    local fresh_record = chlebb_extrapolation_record(target)
    if fresh_record == nil then return end
    local newest_record = state.raw_record or state.record
    if math.abs(fresh_record.simtime - (newest_record.simtime or 0)) > 0.00001 or
       chlebb_length_2d(
           fresh_record.x - (newest_record.x or fresh_record.x),
           fresh_record.y - (newest_record.y or fresh_record.y)
       ) > 1 then
        return
    end

    local current_tick = globals.tickcount()
    if current_tick == last_early_shot_tick then return end

    local interval = globals.tickinterval()
    if not chlebb_is_finite(interval) or interval <= 0 then interval = 1 / 64 end
    local base_record = state.record
    local ticks
    if ax_shot then
        -- Lag compensation is off: the server sees the enemy where they are
        -- when our command arrives, so lead the newest raw record by the
        -- outgoing latency instead of using the choke-based horizon.
        base_record = state.raw_record or state.record
        ticks = chlebb_ax.latency_ticks(interval)
    else
        local maximum_ticks = tonumber(ui.get(extrapolation_ticks)) or 0
        ticks = chlebb_extrapolation_horizon(state, interval, maximum_ticks)
    end
    if ticks <= 0 then return end

    local predicted = chlebb_extrapolate_record(target, base_record, state, ticks, interval)
    if predicted.used_ticks <= 0 then return end
    local command_prediction = {
        x = base_record.x, y = base_record.y, z = base_record.z,
        predicted = predicted,
        displacement = chlebb_length_2d(predicted.x - base_record.x, predicted.y - base_record.y)
    }
    local maximum_displacement = ax_shot and chlebb_ax.max_displacement or
        (state.anti_lc_active and 48 or 64)
    if command_prediction.displacement < 0.1 or
       command_prediction.displacement > maximum_displacement or
       (predicted.collision_count or 0) > 1 then
        return
    end

    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then return end
    local weapon = entity.get_player_weapon(local_player)
    if not chlebb_weapon_can_fire(local_player, weapon) then return end

    -- Counter-strafe when we can, but do not drop a predicted shot just
    -- because we are peeking. The previous ground/speed gate made
    -- extrapolation a no-op in every real fight.
    i_autostop(cmd)

    local aim_point = chlebb_predicted_aim_point(local_player, target, command_prediction)
    if aim_point == nil then return end

    -- Hold Shot: evaluate whether waiting yields a materially better shot.
    -- If so, suppress the fire and let the ragebot pick up the better
    -- opportunity when it arrives. We still run autostop so the local
    -- player is ready to fire the moment the hold releases.
    local current_damage = tonumber(aim_point.damage) or 0
    local current_hitchance = 1.0
    -- God mode fires at the first usable opportunity; never hold for a
    -- better one. A defensive scout peek is only exposed for a few ticks.
    if not chlebb_god.active and
       chlebb_evaluate_hold_shot(target, state, current_damage, current_hitchance, current_tick) then
        state.hold_shot_active = true
        state.hold_shot_reason = (hold_shot_state[target] or {}).reason or "hold"
        return
    end
    state.hold_shot_active = false
    state.hold_shot_reason = "none"

    final_ticks[target] = predicted.used_ticks
    state.final_ticks = predicted.used_ticks
    local punch_pitch, punch_yaw = chlebb_get_prop(local_player, "m_aimPunchAngle")
    local recoil_scale = chlebb_clamp(chlebb_cvar_number("weapon_recoil_scale", 2), 0, 4)
    cmd.pitch = chlebb_clamp(aim_point.pitch - (tonumber(punch_pitch) or 0) * recoil_scale, -89, 89)
    cmd.yaw = chlebb_normalize_yaw(aim_point.yaw - (tonumber(punch_yaw) or 0) * recoil_scale)
    cmd.in_attack = 1
    last_early_shot_tick = current_tick
    state.early_shot_tick = current_tick
    state.early_damage = aim_point.damage
    state.early_hitbox = aim_point.hitbox
    state.early_command = cmd.command_number
end

client.set_event_callback("net_update_end", chlebb_update_players)
client.set_event_callback("setup_command", chlebb_early_shot)
client.set_event_callback("setup_command", chlebb_ax.setup_command)
client.set_event_callback("aim_fire", chlebb_snapshot_shot)

-- misc / trashtalk , clantag , callbacks , load msg, end of file
local trashtalk_msg = {
    "1",
    "ez",
    "bot",
    "quit",
    "chlebb resolver best",
    "P1 AIM EZZZ",
    "XDDDDDDDDDD BRO QUIT NGA",
    "u dogshit",
    "bro delete this game",
    "even defensive cant save you",
    "walkbot",
    "fix iq",
    "fix cfg",
    "fix antiaim",
    "fix your life",
    "im raping your mother",
    "jebac wrone cwela",
    "ddos me: 83.5.116.112",
    "start bodyaiming me bot",
    "exploits cant save you",
    "uninstall and rethink",
    "get resolved",
    "warmup is over right?"
}
local function trashtalk(e)
    if not ui.get(trash) or not ui.get(enable) then
        return
    end

    local victim_entindex = client.userid_to_entindex(e.userid)
    local attacker_entindex = client.userid_to_entindex(e.attacker)
    local local_player = entity.get_local_player()

    if attacker_entindex == local_player and victim_entindex ~= local_player and entity.is_enemy(victim_entindex) then
        client.exec("say " .. trashtalk_msg[math.random(1, #trashtalk_msg)])
    end
end

client.set_event_callback("player_death", trashtalk)

local applied_clantag = nil
client.set_event_callback("paint", function()
    local desired_clantag = ui.get(enable) and ui.get(clantag) and "CHLEBB RE$OLVER" or ""
    if desired_clantag ~= applied_clantag then
        client.set_clan_tag(desired_clantag)
        applied_clantag = desired_clantag
    end
end)

client.set_event_callback("shut_down", function()
    chlebb_god.apply(false)
    chlebb_ax.set_lagcomp(false)
    pcall(chlebb_extrap.restore_all)
    pcall(chlebb_clear_runtime)
    client.set_clan_tag("")
    applied_clantag = ""
    client.color_log(255, 0, 0, "Chlebb Resolver > Goodbye...")
end)

client.set_event_callback("round_start", function()
    if runtime_active then pcall(chlebb_clear_runtime) end
end)


local function chlebb_console_segments(segments)
    for i = 1, #segments do
        local seg = segments[i]
        local text = tostring(seg[4] or "")
        if i < #segments then
            text = text .. "\0"
        end
        client.color_log(seg[1], seg[2], seg[3], text)
    end
end

local hitgroup_names = {'generic', 'head', 'chest', 'stomach', 'left arm', 'right arm', 'left leg', 'right leg', 'neck', '?', 'gear'}

local function chlebb_get_hitgroup(hitgroup)
    return hitgroup_names[(tonumber(hitgroup) or -1) + 1] or "unknown"
end

client.set_event_callback("aim_miss", function(e)
    if not ui.get(enable) then return end

    local reason = e.reason or "unknown"
    local target = e.target
    local shot = chlebb_take_shot(e)
    chlebb_learn_shot(target, false, reason, shot)
    if not ui.get(console_logs) then return end

    local group = chlebb_get_hitgroup(e.hitgroup)
    local hit_chance = shot and shot.hit_chance or tonumber(e.hit_chance or e.hitchance) or 0
    local e_ticks = shot and shot.final_ticks or final_ticks[target] or 0
    local early_suffix = shot and shot.early and "t early" or "t"
    local defensive_text = shot and shot.defensive and string.format(
        "%s %.0f%%%s",
        shot.defensive_reason or "defensive",
        (tonumber(shot.defensive_score) or 0) * 100,
        shot.defensive_flick and " flick" or ""
    ) or "normal"
    local anti_bt_text = shot and shot.anti_backtrack and string.format(
        "%s %.0f%%",
        shot.anti_backtrack_reason or "active",
        (tonumber(shot.anti_backtrack_confidence) or 0) * 100
    ) or "off"
    local lby_breaker_text = shot and shot.lby_breaker and string.format(
        "%s %.0f%%",
        shot.lby_breaker_reason or "active",
        (tonumber(shot.lby_breaker_confidence) or 0) * 100
    ) or "off"
    local hold_shot_text = shot and shot.hold_shot and (shot.hold_shot_reason or "hold") or "off"
    local name = "unknown"
    if type(target) == "number" then
        local ok, n = pcall(entity.get_player_name, target)
        if ok and type(n) == "string" then name = n end
    elseif type(target) == "string" then
        name = target
    end
    if reason == "unknown" or reason == "?" then
        reason = "resolver (?)"
    end

    local ar, ag, ab = 255, 80, 80
    local tr, tg, tb = 255, 200, 200
    chlebb_console_segments({
        { ar, ag, ab, "Chlebb Resolver > " },
        { tr, tg, tb, "Missed " },
        { ar, ag, ab, name },
        { tr, tg, tb, " on " },
        { ar, ag, ab, group },
        { tr, tg, tb, " due to " },
        { ar, ag, ab, reason },
        { tr, tg, tb, " [HC: " },
        { ar, ag, ab, tostring(hit_chance) .. "%" },
        { tr, tg, tb, " | Extrap: " },
        { ar, ag, ab, tostring(e_ticks) .. early_suffix },
        { tr, tg, tb, " | Def: " },
        { ar, ag, ab, defensive_text },
        { tr, tg, tb, " | Anti-BT: " },
        { ar, ag, ab, anti_bt_text },
        { tr, tg, tb, " | LBY-Brk: " },
        { ar, ag, ab, lby_breaker_text },
        { tr, tg, tb, " | Hold: " },
        { ar, ag, ab, hold_shot_text },
        { tr, tg, tb, "]" },
    })
end)

client.set_event_callback("aim_hit", function(e)
    if not ui.get(enable) then return end

    local target = e.target
    local shot = chlebb_take_shot(e)
    chlebb_learn_shot(target, true, nil, shot)
    if not ui.get(console_logs) then return end

    local damage = e.damage or (shot and shot.damage) or 0
    local group = chlebb_get_hitgroup(e.hitgroup)
    local hit_chance = shot and shot.hit_chance or tonumber(e.hit_chance or e.hitchance) or 0
    local e_ticks = shot and shot.final_ticks or final_ticks[target] or 0
    local early_suffix = shot and shot.early and "t early" or "t"
    local defensive_text = shot and shot.defensive and string.format(
        "%s %.0f%%%s",
        shot.defensive_reason or "defensive",
        (tonumber(shot.defensive_score) or 0) * 100,
        shot.defensive_flick and " flick" or ""
    ) or "normal"
    local anti_bt_text = shot and shot.anti_backtrack and string.format(
        "%s %.0f%%",
        shot.anti_backtrack_reason or "active",
        (tonumber(shot.anti_backtrack_confidence) or 0) * 100
    ) or "off"
    local lby_breaker_text = shot and shot.lby_breaker and string.format(
        "%s %.0f%%",
        shot.lby_breaker_reason or "active",
        (tonumber(shot.lby_breaker_confidence) or 0) * 100
    ) or "off"
    local hold_shot_text = shot and shot.hold_shot and (shot.hold_shot_reason or "hold") or "off"
    local name = "unknown"
    if type(target) == "number" then
        local ok, n = pcall(entity.get_player_name, target)
        if ok and type(n) == "string" then name = n end
    elseif type(target) == "string" then
        name = target
    end
    local hp_str = "?"
    if type(target) == "number" then
        local ok_hp, hp = pcall(entity.get_prop, target, "m_iHealth")
        if ok_hp and hp ~= nil then hp_str = tostring(hp) end
    end

    local ar, ag, ab = 76, 255, 118
    local tr, tg, tb = 214, 255, 222
    chlebb_console_segments({
        { ar, ag, ab, "Chlebb Resolver > " },
        { tr, tg, tb, "Shot " },
        { ar, ag, ab, name },
        { tr, tg, tb, " on " },
        { ar, ag, ab, group },
        { tr, tg, tb, " for " },
        { ar, ag, ab, tostring(damage) },
        { tr, tg, tb, " [HC: " },
        { ar, ag, ab, tostring(hit_chance) .. "%" },
        { tr, tg, tb, " | HP Left: " },
        { ar, ag, ab, hp_str },
        { tr, tg, tb, " | Extrap: " },
        { ar, ag, ab, tostring(e_ticks) .. early_suffix },
        { tr, tg, tb, " | Def: " },
        { ar, ag, ab, defensive_text },
        { tr, tg, tb, " | Anti-BT: " },
        { ar, ag, ab, anti_bt_text },
        { tr, tg, tb, " | LBY-Brk: " },
        { ar, ag, ab, lby_breaker_text },
        { tr, tg, tb, " | Hold: " },
        { ar, ag, ab, hold_shot_text },
        { tr, tg, tb, "]" },
    })
end)

print("Chlebb Resolver > loading...")
client.color_log(255, 0, 0, "Chlebb Resolver loaded.")
-- end of file
