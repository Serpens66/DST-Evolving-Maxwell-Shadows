
local actionhandlerpick = GLOBAL.ActionHandler(GLOBAL.ACTIONS.PICK,
    function(inst, action)
        return action.target ~= nil
            and action.target.components.pickable ~= nil
            and (   (action.target.components.pickable.jostlepick and "dojostleaction") or
                    (action.target.components.pickable.quickpick and "doshortaction") or
                    (inst:HasTag("fastpicker") and "doshortaction") or
                    (inst:HasTag("quagmire_fasthands") and "domediumaction") or
                    "dolongaction"  )
            or nil
    end)
local statedoshortaction = GLOBAL.State
    {
        name = "doshortaction",
        tags = { "doing", "busy" },
        onenter = function(inst, silent)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("pickup")
            inst.AnimState:PushAnimation("pickup_pst", false)
            inst.sg.statemem.action = inst.bufferedaction
            inst.sg.statemem.silent = silent
            inst.sg:SetTimeout(10 * GLOBAL.FRAMES)
        end,
        timeline =
        {
            GLOBAL.TimeEvent(4 * GLOBAL.FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),
            GLOBAL.TimeEvent(6 * GLOBAL.FRAMES, function(inst)
                if inst.sg.statemem.silent then
                    inst.components.talker:IgnoreAll("silentpickup")
                    inst:PerformBufferedAction()
                    inst.components.talker:StopIgnoringAll("silentpickup")
                else
                    inst:PerformBufferedAction()
                end
            end),
        },
        ontimeout = function(inst)
            --pickup_pst should still be playing
            inst.sg:GoToState("idle", true)
        end,

        onexit = function(inst)
            if inst.bufferedaction == inst.sg.statemem.action then
                inst:ClearBufferedAction()
            end
        end,
    }
local statedolongaction = GLOBAL.State
    {
        name = "dolongaction",
        tags = { "doing", "busy", "nodangle" },

        onenter = function(inst, timeout)
            if timeout == nil then
                timeout = 1
            elseif timeout > 1 then
                inst.sg:AddStateTag("slowaction")
            end
            inst.sg:SetTimeout(timeout)
            inst.components.locomotor:Stop()
            inst.SoundEmitter:PlaySound("dontstarve/wilson/make_trap", "make")
            inst.AnimState:PlayAnimation("build_pre")
            inst.AnimState:PushAnimation("build_loop", true)
            if inst.bufferedaction ~= nil then
                inst.sg.statemem.action = inst.bufferedaction
                if inst.bufferedaction.action.actionmeter then
                    inst.sg.statemem.actionmeter = true
                    GLOBAL.StartActionMeter(inst, timeout)
                end
                if inst.bufferedaction.target ~= nil and inst.bufferedaction.target:IsValid() then
                    inst.bufferedaction.target:PushEvent("startlongaction")
                end
            end
        end,

        timeline =
        {
            GLOBAL.TimeEvent(4 * GLOBAL.FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),
        },

        ontimeout = function(inst)
            inst.SoundEmitter:KillSound("make")
            inst.AnimState:PlayAnimation("build_pst")
            if inst.sg.statemem.actionmeter then
                inst.sg.statemem.actionmeter = nil
                GLOBAL.StopActionMeter(inst, true)
            end
            inst:PerformBufferedAction()
        end,

        events =
        {
            GLOBAL.EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            inst.SoundEmitter:KillSound("make")
            if inst.sg.statemem.actionmeter then
                GLOBAL.StopActionMeter(inst, false)
            end
            if inst.bufferedaction == inst.sg.statemem.action then
                inst:ClearBufferedAction()
            end
        end,
    }

local statedomediumaction = GLOBAL.State
    {
        name = "domediumaction",

        onenter = function(inst)
            inst.sg:GoToState("dolongaction", .5)
        end,
    }
local statedojostleaction = GLOBAL.State{
    --Alternative to doshortaction but animated with your held tool
    --Animation mirrors attack action, but are not "auto" predicted
    --by clients (also no sound prediction)
    name = "dojostleaction",
    tags = { "doing", "busy" },

    onenter = function(inst)
        local buffaction = inst:GetBufferedAction()
        local target = buffaction ~= nil and buffaction.target or nil
        local equip = inst.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS)
        inst.components.locomotor:Stop()
        local cooldown
        if equip ~= nil and equip:HasTag("whip") then
            inst.AnimState:PlayAnimation("whip_pre")
            inst.AnimState:PushAnimation("whip", false)
            inst.sg.statemem.iswhip = true
            inst.SoundEmitter:PlaySound("dontstarve/common/whip_pre")
            cooldown = 17 * GLOBAL.FRAMES
        elseif equip ~= nil and equip.components.weapon ~= nil and not equip:HasTag("punch") then
            inst.AnimState:PlayAnimation("atk_pre")
            inst.AnimState:PushAnimation("atk", false)
            inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon")
            cooldown = 13 * GLOBAL.FRAMES
        elseif equip ~= nil and (equip:HasTag("light") or equip:HasTag("nopunch")) then
            inst.AnimState:PlayAnimation("atk_pre")
            inst.AnimState:PushAnimation("atk", false)
            inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon")
            cooldown = 13 * GLOBAL.FRAMES
        elseif inst:HasTag("beaver") then
            inst.sg.statemem.isbeaver = true
            inst.AnimState:PlayAnimation("atk_pre")
            inst.AnimState:PushAnimation("atk", false)
            inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
            cooldown = 13 * GLOBAL.FRAMES
        else
            inst.AnimState:PlayAnimation("punch")
            inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
            cooldown = 24 * GLOBAL.FRAMES
        end

        if target ~= nil and target:IsValid() then
            inst:FacePoint(target:GetPosition())
        end

        inst.sg.statemem.action = buffaction
        inst.sg:SetTimeout(cooldown)
    end,

    timeline =
    {
        --beaver: frame 4 remove busy, frame 6 action
        --whip: frame 8 remove busy, frame 10 action
        --other: frame 6 remove busy, frame 8 action
        GLOBAL.TimeEvent(4 * GLOBAL.FRAMES, function(inst)
            if inst.sg.statemem.isbeaver then
                inst.sg:RemoveStateTag("busy")
            end
        end),
        GLOBAL.TimeEvent(6 * GLOBAL.FRAMES, function(inst)
            if inst.sg.statemem.isbeaver then
                inst:PerformBufferedAction()
            elseif not inst.sg.statemem.iswhip then
                inst.sg:RemoveStateTag("busy")
            end
        end),
        GLOBAL.TimeEvent(8 * GLOBAL.FRAMES, function(inst)
            if inst.sg.statemem.iswhip then
                inst.sg:RemoveStateTag("busy")
            elseif not inst.sg.statemem.isbeaver then
                inst:PerformBufferedAction()
            end
        end),
        GLOBAL.TimeEvent(10 * GLOBAL.FRAMES, function(inst)
            if inst.sg.statemem.iswhip then
                inst:PerformBufferedAction()
            end
        end),
    },

    ontimeout = function(inst)
        --anim pst should still be playing
        inst.sg:GoToState("idle", true)
    end,

    events =
    {
        GLOBAL.EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
        GLOBAL.EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
    },

    onexit = function(inst)
        if inst.bufferedaction == inst.sg.statemem.action then
            inst:ClearBufferedAction()
        end
    end,
}

local stateeat = GLOBAL.State{
    name = "eat",
    tags = { "busy", "nodangle" },

    onenter = function(inst, foodinfo)
        inst.components.locomotor:Stop()

        local feed = foodinfo and foodinfo.feed
        if feed ~= nil then
            inst.components.locomotor:Clear()
            inst:ClearBufferedAction()
            inst.sg.statemem.feed = foodinfo.feed
            inst.sg.statemem.feeder = foodinfo.feeder
            inst.sg:AddStateTag("pausepredict")
            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:RemotePausePrediction()
            end
        elseif inst:GetBufferedAction() then
            feed = inst:GetBufferedAction().invobject
        end

        if feed == nil or
            feed.components.edible == nil or
            feed.components.edible.foodtype ~= GLOBAL.FOODTYPE.GEARS then
            inst.SoundEmitter:PlaySound("dontstarve/wilson/eat", "eating")
        end

        if feed ~= nil and feed.components.soul ~= nil then
            inst.sg.statemem.soulfx = SpawnPrefab("wortox_eat_soul_fx")
            inst.sg.statemem.soulfx.Transform:SetRotation(inst.Transform:GetRotation())
            inst.sg.statemem.soulfx.entity:SetParent(inst.entity)
            if inst.components.rider:IsRiding() then
                inst.sg.statemem.soulfx:MakeMounted()
            end
        end

        if inst.components.inventory:IsHeavyLifting() and
            not inst.components.rider:IsRiding() then
            inst.AnimState:PlayAnimation("heavy_eat")
        else
            inst.AnimState:PlayAnimation("eat_pre")
            inst.AnimState:PushAnimation("eat", false)
        end

        inst.components.hunger:Pause()
    end,

    timeline =
    {
        GLOBAL.TimeEvent(28 * GLOBAL.FRAMES, function(inst)
            if inst.sg.statemem.feed == nil then
                inst:PerformBufferedAction()
            elseif inst.sg.statemem.feed.components.soul == nil then
                inst.components.eater:Eat(inst.sg.statemem.feed, inst.sg.statemem.feeder)
            elseif inst.components.souleater ~= nil then
                inst.components.souleater:EatSoul(inst.sg.statemem.feed)
            end
        end),

        GLOBAL.TimeEvent(30 * GLOBAL.FRAMES, function(inst)
            inst.sg:RemoveStateTag("busy")
            inst.sg:RemoveStateTag("pausepredict")
        end),

        GLOBAL.TimeEvent(70 * GLOBAL.FRAMES, function(inst)
            inst.SoundEmitter:KillSound("eating")
        end),
    },

    events =
    {
        GLOBAL.EventHandler("animqueueover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("idle")
            end
        end),
    },

    onexit = function(inst)
        inst.SoundEmitter:KillSound("eating")
        if not GLOBAL.GetGameModeProperty("no_hunger") then
            inst.components.hunger:Resume()
        end
        if inst.sg.statemem.feed ~= nil and inst.sg.statemem.feed:IsValid() then
            inst.sg.statemem.feed:Remove()
        end
        if inst.sg.statemem.soulfx ~= nil then
            inst.sg.statemem.soulfx:Remove()
        end
    end,
}

AddStategraphActionHandler("shadowmaxwell",actionhandlerpick)
AddStategraphState("shadowmaxwell",statedojostleaction)
AddStategraphState("shadowmaxwell",statedoshortaction)
AddStategraphState("shadowmaxwell",statedolongaction)
AddStategraphState("shadowmaxwell",statedomediumaction)
AddStategraphState("shadowmaxwell",stateeat)



AddStategraphPostInit("shadowmaxwell",function(sg)
    if sg.states.death~=nil then
        local old_onenter = sg.states.death.onenter
        local function new_onenter(inst,...)
            if inst.components~=nil and inst.components.container~=nil then
                inst.components.container:Close()
                inst.components.container:DropEverything()
                inst.components.container.canbeopened = false
            end
            return old_onenter(inst,...)
        end
        sg.states.death.onenter = new_onenter
    end
    
    if sg.states.hit~=nil then
        local old_onenter = sg.states.hit.onenter
        local function new_onenter(inst,...)
            inst.last_hittime = inst.maybe_hittime -- save the time when we do the hit state
            return old_onenter(inst,...)
        end
        sg.states.hit.onenter = new_onenter
    end
    
    local old_onattacked = sg.events.attacked.fn
    local function onattacked(inst, data)
        local hittime = GLOBAL.GetTime()
        if inst.hitstuntimeout~=nil and inst.last_hittime~=nil and hittime - inst.last_hittime < inst.hitstuntimeout then
            return
        end
        inst.maybe_hittime = hittime -- we dont know for sure if the hit animation will be done
        return old_onattacked(inst,data) -- might trigger the hit state
    end
    sg.events.attacked.fn = onattacked -- hook into this commonstate to prevent the hit state if hitstuntimeout
    
    
end)

-- blowdart/throw is too difficult to add cause we can not simply copy from wilson/walrus. we have to understand the code, but that is too much work, so we will leave it like it is.

-- AddStategraphPostInit("wilson", function(sg)
    -- we could search for the pick wislon stategraphs and add extactly these ones to shadowmaxwell instead of copy pasting them here...
    -- but these stategraphs can include sth like inst.components.rider and other compoenns the sahdows dont have, which will ead to crash.
    -- so I think it is safer to use the copy pasted variant, although game updates wont apply to them... shadows can do everything they need to
-- end)