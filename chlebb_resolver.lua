--[[ 
Chlebb Resolver.lua
branch: debug
writted by chlebb and osk4rrv. 
]]

local ffi = require("ffi")
local bit = require("bit")
local vector = require("vector")

local enable = ui.new_checkbox("RAGE", "Other", "Enable Chlebb Resolver")
local type = ui.new_combobox("RAGE", "Other", "Resolver Type", {"Animstate", "Lby"})
local learning = ui.new_checkbox("RAGE", "Other", "Learning")
local extrapolation = ui.new_checkbox("RAGE", "Other", "Extrapolation")
local extrapolation_ticks = ui.new_slider("RAGE", "Other", "Extrapolation Ticks", 1, 12, 6, true, "t")
local clantag = ui.new_checkbox("RAGE", "Other", "Clantag")
local trash = ui.new_checkbox("RAGE", "Other", "Trashtalk")

local function update_ui_visibility()
    local enabled = ui.get(enable)
    ui.set_visible(type, enabled)
    ui.set_visible(learning, enabled)
    ui.set_visible(extrapolation, enabled)
    ui.set_visible(extrapolation_ticks, enabled and ui.get(extrapolation))
end

ui.set_callback(enable, update_ui_visibility)
ui.set_callback(type, update_ui_visibility)
ui.set_callback(learning, update_ui_visibility)
ui.set_callback(extrapolation, update_ui_visibility)
ui.set_callback(extrapolation_ticks, update_ui_visibility)

local animstate_offset   = 0x9960
local animlayer_offset   = 0x2980
local poseparam_offset   = 0x2764
local max_layers         = 15

ffi.cdef[[
    typedef struct {
        float x;
        float y;
        float z;
    } vec3_t;

    typedef struct {
        float m[3][4];
    } matrix3x4_t;

    typedef struct {
        unsigned char r, g, b, a;
    } color_t;

    typedef struct {
        void* vtable;
        char pad_0x0004[0x18];
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
        char pad_0x003C[0x4];
        float m_flFeetCycle;
        float m_flFeetYawRate;
        char pad_0x004C[0x4];
        float m_fDuckAmount;
        float m_fLandingDuckAdditiveSomething;
        char pad_0x005C[0x4];
        float m_vOriginX;
        float m_vOriginY;
        float m_vOriginZ;
        float m_vLastOriginX;
        float m_vLastOriginY;
        float m_vLastOriginZ;
        float m_vVelocityX;
        float m_vVelocityY;
        char pad_0x0084[0x4];
        float m_flUnknownFloat1;
        char pad_0x0090[0x8];
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
        char pad_0x00CC[0x2];
        float m_flJumpToFall;
        float m_flTimeSinceInAir;
        float m_flLastOriginZ;
        float m_flHeadHeightOrOffsetFromHittingGroundAnimation;
        float m_flStopToFullRunningFraction;
        char pad_0x00E8[0x4];
        float m_flMagicFraction;
        char pad_0x00F0[0x3C];
        float m_flWorldForce;
        char pad_0x0130[0x1CE];
        float m_flMaxYaw;
    } ccsgo_player_animstate_t;

    typedef struct {
        void* vtable;
        char pad_0x0004[0x18];
        float m_flSimulationTime;
        float m_flOldSimulationTime;
        float m_flAnimTime;
        float m_flOldAnimTime;
        int m_fEffects;
        int m_nRenderMode;
        int m_nRenderFX;
        color_t m_RenderColor;
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
        float m_flFadeScale;
        int m_nHitboxSet;
        void* m_pRenderable;
        void* m_pNetworkable;
        char pad_0x0084[0x4];
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
        int m_nHitboxSet;
        float m_flCycle;
        float m_flAnimTime;
        int m_nSequence;
        float m_flPlaybackRate;
        float m_flPoseParameter[24];
        int m_nNewSequenceParity;
        int m_nResetEventsParity;
        int m_nMuzzleFlashParity;
        int m_hLightingOrigin;
        float m_flWeight;
        int m_nOrder;
    } c_csplayer_t;

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
        char pad_0038[4];
    } c_animationlayer_t;
]]

local resolver_ffi = {}

resolver_ffi.get_entity_address = function(idx)
    local ptr = entity.get_prop(idx, "m_hOwnerEntity")
    if not ptr or ptr == 0 then return nil end
    return ptr
end

resolver_ffi.read_animstate = function(idx)
    local ent = resolver_ffi.get_entity_address(idx)
    if not ent then return nil end

    local state_ptr = memory.read_uint32(ent + animstate_offset)
    if not state_ptr or state_ptr == 0 then return nil end

    local state = ffi.new("ccsgo_player_animstate_t[1]")
    local ok = pcall(function()
        ffi.copy(state, ffi.cast("char*", state_ptr), ffi.sizeof("ccsgo_player_animstate_t"))
    end)

    return ok and state[0] or nil
end

resolver_ffi.read_player = function(idx)
    local ent = resolver_ffi.get_entity_address(idx)
    if not ent then return nil end

    local player = ffi.new("c_csplayer_t[1]")
    local ok = pcall(function()
        ffi.copy(player, ffi.cast("char*", ent), ffi.sizeof("c_csplayer_t"))
    end)

    return ok and player[0] or nil
end

resolver_ffi.read_layers = function(idx, count)
    count = count or max_layers
    local ent = resolver_ffi.get_entity_address(idx)
    if not ent then return {} end

    local overlays_ptr = memory.read_uint32(ent + animlayer_offset)
    if not overlays_ptr or overlays_ptr == 0 then return {} end

    local layers = {}
    for i = 0, count - 1 do
        local layer_ptr = overlays_ptr + (i * ffi.sizeof("c_animationlayer_t"))
        local layer = ffi.new("c_animationlayer_t[1]")
        local ok = pcall(function()
            ffi.copy(layer, ffi.cast("char*", layer_ptr), ffi.sizeof("c_animationlayer_t"))
        end)
        if ok then
            layers[i + 1] = layer[0]
        end
    end
    return layers
end

resolver_ffi.get_desync_delta = function(idx)
    local state = resolver_ffi.read_animstate(idx)
    if not state then return 0 end

    local function norm(y)
        while y > 180 do y = y - 360 end
        while y < -180 do y = y + 360 end
        return y
    end

    local eye_yaw = state.m_flEyeYaw
    local goal_feet_yaw = state.m_flGoalFeetYaw
    local current_feet_yaw = state.m_flCurrentFeetYaw

    local d1 = math.abs(norm(eye_yaw - goal_feet_yaw))
    local d2 = math.abs(norm(eye_yaw - current_feet_yaw))
    local d3 = math.abs(norm(goal_feet_yaw - current_feet_yaw))

    return math.max(d1, d2, d3)
end

resolver_ffi.get_velocity_2d = function(idx)
    local player = resolver_ffi.read_player(idx)
    if not player then return 0 end
    local vx = player.m_vecVelocity[0]
    local vy = player.m_vecVelocity[1]
    return math.sqrt(vx * vx + vy * vy)
end

local trashtalk_msg = {"1", "ez", "bot", "quit", "chlebb resolver best", "P1 AIM EZZZ", "XDDDDDDDDDD BRO QUIT NGA"}
local function trashtalk()
    if ui.get(trash) then
        client.exec(tostring(trashtalk_msg[math.random(1, #trashtalk_msg)]))
    end
end

client.set_callback("paint", function()
    if ui.get(enable) and ui.get(clantag) then
        client.set_clan_tag("CHLEBB RE$OLVER")
    else 
        client.set_clan_tag("")
    end
end)

client.set_callback("shut_down", function()
    client.set_clan_tag("")
end)

client.set_callback("aim_miss", function(e)
    local hitgroup_names = {'generic', 'head', 'chest', 'stomach', 'left arm', 'right arm', 'left leg', 'right leg', 'neck', '?', "gear"}
    local hit_chance = e.hit_chance or 0
    local reason = e.reason or "unknown"
    local enemy = e.target or "unknown"
    local e_ticks = ui.get(extrapolation) and ui.get(extrapolation_ticks) or 0

    if reason == "unknown" or reason == "?" then
        reason = "resolver (?)"
    end
    client.color_log("Chlebb Resolver > Missed shot at " .. enemy .. " due to " .. reason .. " [hit chance:" .. hit_chance .. "%, Extrapolation: " ..  e_ticks .. "]", {255, 0, 0})
end)

client.set_callback("aim_hit", function(e)
    local hitgroup_names = {'generic', 'head', 'chest', 'stomach', 'left arm', 'right arm', 'left leg', 'right leg', 'neck', '?', "gear"}
    local hit_chance = e.hit_chance or 0
    local enemy = e.target or "unknown"
    local damage = e.damage or 0
    local hitgroup = e.hitgroup
    if not hitgroup then 
        hitgroup = 0
    end
    local e_ticks = ui.get(extrapolation) and ui.get(extrapolation_ticks) or 0

    client.color_log("Chlebb Resolver > Shot at " .. enemy .. " for " .. damage .. " damage in " .. hitgroup_names[hitgroup + 1] .. " [hit chance:" .. hit_chance .. "%, Extrapolation: " ..  e_ticks .. "]", {255, 0, 0})
end)

print("Chlebb Resolver > loading...")
client.color_log("Chlebb Resolver loaded", {255, 0, 0})
-- end of file