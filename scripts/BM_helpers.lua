
local helpers = {}


-- #################################################
------------------ Technical Helpers --------------------
-- #################################################

--  custom listenforevent, puts our function at the beginning of the list of fns to execute (instead of at the end)
local function AddListener(t, event, inst, fn)
    local listeners = t[event]
    if not listeners then
        listeners = {}
        t[event] = listeners
    end
    local listener_fns = listeners[inst]
    if not listener_fns then
        listener_fns = {}
        listeners[inst] = listener_fns
    end
    table.insert(listener_fns, 1, fn) -- put it on the first position
end
local function MyListenForEventPutinFirst(self, event, fn, source)
    source = source or self
    if not source.event_listeners then
        source.event_listeners = {}
    end
    AddListener(source.event_listeners, event, self, fn)
    if not self.event_listening then
        self.event_listening = {}
    end
    AddListener(self.event_listening, event, source, fn)
end
helpers["MyListenForEventPutinFirst"] = MyListenForEventPutinFirst


local function removetablekey(t, lookup_key)
    for k, v in pairs(t) do
        if k == lookup_key then
            t[k] = nil
            return v
        end
    end
end
helpers["removetablekey"] = removetablekey


local function nroot(num,root)
  return num^(1/root)
end
helpers["nroot"] = nroot


-- #################################################
------------------ Game Helpers Get Info --------------------
-- #################################################

local _T = TUNING


local function GetMyEquippedItem(inst,equipslot)
    local item = nil
    if inst~=nil and inst.components~=nil and inst.components.inventory~=nil then
        item = inst.components.inventory:GetEquippedItem(equipslot)
    end
    return item
end
helpers["GetMyEquippedItem"] = GetMyEquippedItem

local function GetLeader(inst,frombrain)
    if frombrain==true and helpers.GetLeashPosition(inst)~=nil then
        -- if _T.BM_dodebugprints then print("no leader to follow") end
        return nil -- no leader to follow or face
    end
    return inst.components.follower.leader
end
helpers["GetLeader"] = GetLeader
local function IsNearLeader(inst, dist,frombrain,target)
    local BM_stayatposition = helpers.GetLeashPosition(inst) -- checks inst.BM_staywalkableplattform and inst.BM_stayatposition
    if frombrain==true and BM_stayatposition~=nil then -- check if near to stay position instead
        if target~=nil then -- check if target is near
            return target:GetDistanceSqToPoint(BM_stayatposition) < dist * dist
        else -- check if shadow is near
            return inst:GetDistanceSqToPoint(BM_stayatposition) < dist * dist
        end
    end
    local leader = GetLeader(inst)
    if target~=nil then -- check if target is near leader
        return leader ~= nil and target:IsNear(leader, dist)
    else -- check if shadow is near leader
        return leader ~= nil and inst:IsNear(leader, dist)
    end
end
helpers["IsNearLeader"] = IsNearLeader

local function GetLeashPosition(inst)
    if inst.BM_staywalkableplattform~=nil and inst.BM_staywalkableplattform:IsValid() then
        return inst.BM_staywalkableplattform:GetPosition()
    else
        return inst.BM_stayatposition
    end
end
helpers["GetLeashPosition"] = GetLeashPosition

local function isshadowworker(prefab,_builder) -- dont want to add a new prefab for this, so lumber is changed to worker instead
    return not _builder and prefab=="shadowlumber" or (_builder==true and prefab=="shadowlumber_builder") -- 
end
helpers["isshadowworker"] = isshadowworker

local function CanAllrounderDoThis(inst,job) -- if allrounder worker is currently a lumber, miner, digger oder collector
    if inst~=nil and inst.components.shadowtoggleable~=nil and inst.components.shadowtoggleable:IsActive() and inst.components.health~=nil and not inst.components.health:IsDead() and inst.willdespawn~=true then
        if inst~=nil and isshadowworker(inst.prefab) then
            local item = helpers.GetMyEquippedItem(inst,EQUIPSLOTS.HANDS)
            if item~=nil then -- pitchfork for picking stuff
                return (item.components~=nil and item.components.tool~=nil and item.components.tool:CanDoAction(job)) or (job==ACTIONS.PICK and item:CanDoAction(ACTIONS.TERRAFORM))
            end
        end
    end
    return false
end
helpers["CanAllrounderDoThis"] = CanAllrounderDoThis

local function IsAllowedItem(inst,item,containerORequip,slot) -- hardcoded no slot 1 for worker container
    if inst.prefab=="shadowduelist" then
        if containerORequip=="container" then -- slot does not matter for duelist, since he does not pick things
            if table.contains(_T.BM_AllowedItemsInContainer.duelistNoequip.prefabs,item.prefab) then  -- eg codex umbra
                return true
            end           
            for _,tag in ipairs(_T.BM_AllowedItemsInContainer.duelistNoequip.tags) do
                if item:HasTag(tag) then
                    return true
                end
            end
        end
        if containerORequip=="container" or containerORequip=="equip" then -- is executed for both, container and equip
            if table.contains(_T.BM_AllowedItemsInContainer.duelistequip.prefabs,item.prefab) then
                return true
            end           
            for _,tag in ipairs(_T.BM_AllowedItemsInContainer.duelistequip.tags) do
                if item:HasTag(tag) then
                    return true
                end
            end
        end
    elseif helpers.isshadowworker(inst.prefab) then
        if containerORequip=="container" and slot~=1 then -- things the sowkrer should not equip, should not be put into slot 1. it is reserved for the worker tool (otehrwise worker will have problems picking items) then
            if table.contains(_T.BM_AllowedItemsInContainer.workerNoequip.prefabs,item.prefab) then -- eg codex umbra
                return true
            end           
            for _,tag in ipairs(_T.BM_AllowedItemsInContainer.workerNoequip.tags) do
                if item:HasTag(tag) then
                    return true
                end
            end
        end
        if containerORequip=="container" or containerORequip=="equip" then -- is executed for both, container and equip
            if table.contains(_T.BM_AllowedItemsInContainer.workerequip.prefabs,item.prefab) then -- eg umbrella
                return true
            end           
            for _,tag in ipairs(_T.BM_AllowedItemsInContainer.workerequip.tags) do -- eg lightsources like lantern or torch, to help the player see in the night
                if item:HasTag(tag) then
                    return true
                end
            end
        end
    end
    return false
end

local function ContainerShouldAcceptItem(self,item, slot) -- has to work for server and client
    if self.inst~=nil and ((self.inst.components.health~=nil and not self.inst.components.health:IsDead()) or (self.inst.replica.health~=nil and not self.inst.replica.health:IsDead())) and self.inst.willdespawn~=true then
        local prefab = self.inst.prefab
        if item~=nil then
            if prefab=="shadowduelist" then
                if ((item.components~=nil and item.components.equippable~=nil) or (item.replica~=nil and item.replica.equippable~=nil)) and (item:HasTag("weapon") or item:HasTag("armor")) then -- only armor (also hats with armor) and weapons
                    return true
                end
                if IsAllowedItem(self.inst,item,"container",slot) then
                    return true
                end
            elseif helpers.isshadowworker(prefab) then
                if slot~=1 and item:HasTag("shadowincontainer") then -- picked stuff has this tag temporarily
                    return true
                end
                if ((item.components~=nil and item.components.equippable~=nil) or (item.replica~=nil and item.replica.equippable~=nil)) then
                    for _,job in ipairs(_T.BM_SHADOW_JOBS) do
                        if item:HasTag(job.id.."_tool") or (job==ACTIONS.PICK and item.prefab=="pitchfork") then -- CanDoAction does not work well on client, at least not for pitchforks inherent action, so avaid it here
                            return true
                        end
                    end
                end  
                if IsAllowedItem(self.inst,item,"container",slot) then
                    return true
                end
            end
        end
    end
    return false
end
helpers["ContainerShouldAcceptItem"] = ContainerShouldAcceptItem

local function ShouldKite(target, inst)
    -- if _T.BM_dodebugprints then print("shouldkite "..tostring(target).." , "..tostring(inst)) end 
    if _T.BM_SWITCHOPTION_FIGHTER ~= nil then
        if _T.BM_SWITCHOPTION_FIGHTER == "tank" then
            return false
        end
        if _T.BM_SWITCHOPTION_FIGHTER == "tactic" and (inst.components.inventory and inst.components.inventory:IsWearingArmor()==true) then
            return false
        end
    end
    if target=="ignore" then -- if we dont have a target (eg we only check if we chould change attack speed)
        return true
    else
        return inst.components.combat:TargetIs(target) -- orignal code
            and target.components.health ~= nil
            and not target.components.health:IsDead()
    end
end
helpers["ShouldKite"] = ShouldKite


local function CalcDamage(self, weapon) -- copy of the combat function, without the need of an target
    local basedamage
    local basemultiplier = self.damagemultiplier
    local externaldamagemultipliers = self.externaldamagemultipliers
    local bonus = self.damagebonus --not affected by multipliers
    local playermultiplier = 1
    if weapon ~= nil then
        --No playermultiplier when using weapons
        basedamage = weapon.components.weapon.damage or 0
        playermultiplier = 1
    else
        basedamage = self.defaultdamage
        playermultiplier = playermultiplier and self.playerdamagepercent or 1
    end
    return basedamage
        * (basemultiplier or 1)
        * self.externaldamagemultipliers:Get()
        * playermultiplier
        + (bonus or 0)
end
helpers["CalcDamage"] = CalcDamage



-- #################################################
------------------ Game Helpers Set Info --------------------
-- #################################################

-- container widgets
local containerparams = {}
containerparams.shadowBMduelist = {widget ={slotpos = {},animbank = "ui_chester_shadow_3x4",animbuild = "ui_chester_shadow_3x4",pos = Vector3(0, 220, 0),side_align_tip = 160,numslots = 12,},type = "chest",}
for y = 2.5, -0.5, -1 do for x = 0, 2 do table.insert(containerparams.shadowBMduelist.widget.slotpos, Vector3(75 * x - 75 * 2 + 75, 75 * y - 75 * 2 + 75, 0))end end
function containerparams.shadowBMduelist.itemtestfn(self, item, slot)
    return helpers.ContainerShouldAcceptItem(self,item,slot)
end
containerparams.shadowBMworker = {widget ={slotpos = {},animbank = "ui_chest_3x3",animbuild = "ui_chest_3x3",pos = Vector3(0, 200, 0),side_align_tip = 160,numslots = 9,},usespecificslotsforitems=true,type = "chest",}
for y = 2, 0, -1 do for x = 0, 2 do table.insert(containerparams.shadowBMworker.widget.slotpos, Vector3(80 * x - 80 * 2 + 80, 80 * y - 80 * 2 + 80, 0)) end end
function containerparams.shadowBMworker.itemtestfn(self, item, slot)
    return helpers.ContainerShouldAcceptItem(self,item,slot)
end
helpers["containerparams"] = containerparams


local function Findandconsume_prefab(inst,amount,prefab,onlyfind) -- tries to consume amount prefab from his container and returns the actual amount consumed
    local fuelconsumed = 0
    local item = nil
    if amount>0 then
        for i = 1, inst.components.container:GetNumSlots() do
            item = inst.components.container:GetItemInSlot(i)
            if item~=nil and item:IsValid() and item.prefab==prefab then                
                if onlyfind=="onlyfind" then
                    return item
                end
                if item.components.stackable~=nil and item.components.stackable:IsStack() then -- is a stack
                    if onlyfind==nil then
                        while fuelconsumed<amount and item.components.stackable:StackSize() >= 1 and item:IsValid() do
                            fuelconsumed = fuelconsumed + 1
                            if item.components.stackable:StackSize()==1 then
                                inst.components.container:RemoveItem(item):Remove() -- remove the last one
                            else
                                item.components.stackable:SetStackSize(item.components.stackable:StackSize() - 1) -- reduce the stacksize
                            end
                        end
                    elseif onlyfind=="findstackspace" and not item.components.stackable:IsFull() then
                        return item -- find a stack that is not full already
                    end
                elseif onlyfind==nil then -- is no stack 
                    fuelconsumed = fuelconsumed + 1
                    inst.components.container:RemoveItem(item):Remove()
                elseif item.components.stackable~=nil and onlyfind=="findstackspace" and not item.components.stackable:IsFull() then -- without "IsStack" because 1 cutgrass is no stack, but stackable
                    return item -- find a stack that is not full already
                end
            end
        end
    end
    if onlyfind==nil then
        return fuelconsumed
    else
        return false
    end
end
helpers["Findandconsume_prefab"] = Findandconsume_prefab


local function check_attackspeed_kite(inst,force)
    if inst.prefab=="shadowduelist" and (_T.BM_SWITCHOPTION_FIGHTER == "tactic" or force==true) then -- we may got an armor, so check should kite again and adjust attackperiod
        if helpers.ShouldKite("ignore",inst) then -- change attack speed to match the set stop_kiting_distance, so it actually can switch from tank to kite when loosig his armor, without low attack speed on tank
            local speed = inst.components.locomotor:GetRunSpeed() -- is distance per second
            local new_Attack_period = _T.BM_STOP_KITING_DIST / speed + 1.2
            inst.components.combat:SetAttackPeriod(new_Attack_period)
            if _T.BM_dodebugprints then
                print("shouldkite, change attack speed now to "..tostring(new_Attack_period))
            end
        else -- when tanking, use the in modsetting set value
            inst.components.combat:SetAttackPeriod(_T.SHADOWWAXWELL_ATTACK_PERIOD)
            if _T.BM_dodebugprints then
                print("should tank, change attack speed back to "..tostring(_T.SHADOWWAXWELL_ATTACK_PERIOD))
            end
        end
    end
end
helpers["check_attackspeed_kite"] = check_attackspeed_kite

local function EquipNewEquip(inst,searchequipslot)
    if inst~=nil and inst.components.health~=nil and not inst.components.health:IsDead() and inst.willdespawn~=true then
        local foundhat = nil
        local foundarmor = nil
        local foundweapon = nil
        local foundtool = nil
        local equipslot = nil
        for i = 1, inst.components.container:GetNumSlots() do
            local item = inst.components.container:GetItemInSlot(i)
            if item~=nil and item:IsValid() and item.components~=nil and item.components.equippable~=nil then
                equipslot = item.components.equippable.equipslot    
                if searchequipslot==nil then
                    if inst.prefab=="shadowduelist" then
                        if IsAllowedItem(inst,item,"equip") or item.components.weapon~=nil or item.components.armor~=nil then -- only armor (also hats with armor) and weapons
                            if equipslot==EQUIPSLOTS.HANDS and foundweapon==nil then
                                inst.components.inventory:Equip(item)
                                foundweapon = true
                            elseif equipslot==EQUIPSLOTS.BODY and foundarmor==nil then
                                inst.components.inventory:Equip(item)
                                foundarmor = true
                            elseif equipslot==EQUIPSLOTS.HEAD and foundhat==nil then
                                inst.components.inventory:Equip(item)
                                foundhat = true
                            end
                        end
                    elseif helpers.isshadowworker(inst.prefab) then
                        if equipslot==EQUIPSLOTS.HANDS and foundtool==nil then -- worker only equips the one at slot 1
                            for _,job in ipairs(_T.BM_SHADOW_JOBS) do
                                if IsAllowedItem(inst,item,"equip") or (item.components~=nil and item.components.tool~=nil and item.components.tool:CanDoAction(job)) or item:CanDoAction(job) or (job==ACTIONS.PICK and item:CanDoAction(ACTIONS.TERRAFORM)) then
                                    if i~=1 then -- if we did not found it in slot 1, then put it there
                                        inst.components.container:RemoveItemBySlot(i) -- do this before equipping it!
                                        inst.components.container:GiveItem(item,1)
                                    end
                                    inst.components.inventory:Equip(item)
                                    foundtool = true
                                    break
                                end
                            end
                        end
                    end
                elseif searchequipslot==equipslot then
                    if helpers.isshadowworker(inst.prefab) then
                        for _,job in ipairs(_T.BM_SHADOW_JOBS) do -- although we already checked this on ContainerShouldAcceptItem, we will check it here again. only equip specific tools
                            if IsAllowedItem(inst,item,"equip") or (item.components~=nil and item.components.tool~=nil and item.components.tool:CanDoAction(job)) or item:CanDoAction(job) or (job==ACTIONS.PICK and item:CanDoAction(ACTIONS.TERRAFORM)) then
                                if i~=1 then -- if we did not found it in slot 1, then put it there
                                    inst.components.container:RemoveItemBySlot(i)
                                    inst.components.container:GiveItem(item,1)
                                end
                                inst.components.inventory:Equip(item)
                                searchequipslot = "found"
                                break
                            end
                        end
                    elseif inst.prefab=="shadowduelist" then
                        if IsAllowedItem(inst,item,"equip") or item.components.weapon~=nil or item.components.armor~=nil then -- only armor (also hats with armor) and weapons
                            inst.components.inventory:Equip(item)
                            searchequipslot = "found"
                        end
                    end
                end   
                if searchequipslot=="found" then -- we only searched for this specific one and found it already
                    break
                end
            end
        end
        inst:DoTaskInTime(1,helpers.check_attackspeed_kite) -- right now, the broken armor is still equipped, so check it in 1 second again
    end
end
helpers["EquipNewEquip"] = EquipNewEquip


local function EquipNewArmor(inst,data)
    if inst~=nil and inst.components.health~=nil and not inst.components.health:IsDead() and inst.willdespawn~=true then
        if data~=nil then
            local oldarmor = data.armor
            if inst~=nil and inst.willdespawn~=true and inst.components~=nil and inst.components.container~=nil then
                helpers.EquipNewEquip(inst,oldarmor.components.equippable.equipslot)
            end
        end
    end
end
helpers["EquipNewArmor"] = EquipNewArmor



local function Leader_Has_ActionEquipment(leader,action) -- has a shovel to allow digging, or has a pitchfork to allow to pick everything
    local handitem = leader.components~=nil and leader.components.inventory~=nil and helpers.GetMyEquippedItem(leader,EQUIPSLOTS.HANDS) or nil
    if action~=ACTIONS.PICK then
        return handitem~=nil and handitem.components~=nil and handitem.components.tool~=nil and handitem.components.tool:CanDoAction(action) -- eg only allw digging grass when maxwell has shovel equipped
    else -- for picking we will use the pitchfork (not scythe, cause this is the check to allow pick EVERYTHING, and we dont want this if player has scythe equipped)
        return handitem~=nil and handitem:CanDoAction(ACTIONS.TERRAFORM)
    end
end
helpers["Leader_Has_ActionEquipment"] = Leader_Has_ActionEquipment

local function MoveInstAtLandPlotNearInst(inst,loc,x,y,z,xmin,zmin) -- xmin and zmin are the mind distance it should have to the given position
    -- print("Spawn "..tostring(inst).." near "..tostring(loc).." times: "..tostring(times))
    if inst==nil or loc==nil or not inst:IsValid() then
        print("Teleportato: inst is "..tostring(inst).." ? or loc is nil: "..tostring(loc).."... error")
        return nil 
    end
    local pos = nil
    if loc.prefab then    
        pos = loc:GetPosition()
    else -- loc can also be a position already
        pos = loc
    end
    x = x or 5
    y = y or 0 -- should be 0 most of the time, it is the height
    z = z or 5
    xmin = xmin or 3
    zmin = zmin or 3
    local xn = 0
    local zn = 0
    local found = false
    local tp_pos
    local attempts = 100
    local spawn = nil
    while attempts > 0 do
        xn = GetRandomWithVariance(0,x)
        zn = GetRandomWithVariance(0,z)
        xn = (xn>=0 and xn<=xmin and xn+xmin) or (xn<0 and xn>=-xmin and xn-xmin) or xn -- dont be between -1 and 1, because this is too near
        zn = (zn>=0 and zn<=zmin and zn+zmin) or (zn<0 and zn>=-zmin and zn-zmin) or zn
        tp_pos = pos + Vector3(xn ,GetRandomWithVariance(0,y) ,zn  )
        if TheWorld.Map:IsAboveGroundAtPoint(tp_pos:Get()) then
            found = true
            break
        end
        attempts = attempts - 1
    end
    if found then
        inst.Transform:SetPosition(tp_pos:Get())
    else
        print("MoveInstAtLandPlotNearInst: failed to move "..tostring(inst).." to valid location..")
    end
    return found
end
helpers["MoveInstAtLandPlotNearInst"] = MoveInstAtLandPlotNearInst


local function AddHungerStuff(inst)
    -- hunger for nightmarefuel, replaces the old decay mechanic
    inst:AddComponent("hunger")
    inst.components.hunger:SetMax(1000)
    inst.components.hunger.current = 150
    inst.components.hunger:SetRate(_T.BM_HUNGER_PER_DAY/_T.TOTAL_DAY_TIME)
    inst.components.hunger:SetKillRate(inst.components.health.maxhealth/_T.TOTAL_DAY_TIME*2) -- will loose all its max HP within half day
    inst:AddComponent("eater")
    inst.components.eater:SetDiet({ FOODTYPE.SHADOWFOOD })
    inst:ListenForEvent("hungerdelta", function(inst, data)
        if (data.newpercent <= 0.1 and data.oldpercent > 0.1) then
            if inst.starvingtask~=nil then
                inst.starvingtask:Cancel()
                inst.starvingtask = nil
            end
            inst.starvingtask = inst:DoPeriodicTask(45,function(inst)
                inst.AnimState:PlayAnimation("hungry")
                inst.SoundEmitter:PlaySound("dontstarve/wilson/hungry")
            end,0)
        elseif (data.newpercent > 0.1 and data.oldpercent <= 0.1) then
            if inst.starvingtask~=nil then
                inst.starvingtask:Cancel()
                inst.starvingtask = nil
            end
        end
        if data.newpercent == 0 then
            inst.components.health:StopRegen() -- stopstarving will enable it again, but we have to stop it here every delta, cause upgrade of shadow will also start it.
        end
    end)
    inst:ListenForEvent("startstarving", function(inst)
        if inst.starvingtask~=nil then
            inst.starvingtask:Cancel()
            inst.starvingtask = nil
        end
        inst.starvingtask = inst:DoPeriodicTask(20,function(inst)
            inst.AnimState:PlayAnimation("hungry")
            inst.SoundEmitter:PlaySound("dontstarve/wilson/hungry")
            -- talker "*starving*"
        end,0)
    end)
    inst:ListenForEvent("stopstarving", function(inst)
        if inst.starvingtask~=nil then
            inst.starvingtask:Cancel()
            inst.starvingtask = nil
        end
        local maxlevel = helpers.isshadowworker(inst.prefab) and _T.SM_MAXLEVEL_WORKER or _T.SM_MAX_LEVEL
        if helpers.isshadowworker(inst.prefab) then
            local regenstepperlevel = (_T.SHADOWWAXWELL_WORKERS_HEALTH_REGEN*2 - _T.SHADOWWAXWELL_WORKERS_HEALTH_REGEN)/maxlevel -- doubles at maxlevel
            inst.components.health:StartRegen(_T.SHADOWWAXWELL_WORKERS_HEALTH_REGEN + inst.level*regenstepperlevel, _T.SHADOWWAXWELL_HEALTH_REGEN_PERIOD)
        elseif inst.prefab=="shadowduelist" then
            local regenstepperlevel = (_T.SHADOWWAXWELL_HEALTH_REGEN*2 - _T.SHADOWWAXWELL_HEALTH_REGEN)/maxlevel -- doubles at maxlevel
            inst.components.health:StartRegen(_T.SHADOWWAXWELL_HEALTH_REGEN + inst.level*regenstepperlevel, _T.SHADOWWAXWELL_HEALTH_REGEN_PERIOD) --- also a bit health regen increase 
        end
    end)
end
helpers["AddHungerStuff"] = AddHungerStuff

local function MatchSpeedAndBoundPosition(inst)
	local leader = inst.components.follower.leader
	if leader then
		inst.components.locomotor.runspeed = leader.components.locomotor:RunSpeed() -- only adjust the runspeed here. modifiers are automatically taken from GetSpeedMultiplier
	end
    local BM_stayatposition = helpers.GetLeashPosition(inst) -- checks inst.BM_staywalkableplattform and inst.BM_stayatposition
    if helpers.Findandconsume_prefab(inst,1,_T.BM_stayitemprefab,"onlyfind") then -- if we have a stayitem in container, bound to position instead of leader
        inst.components.follower:StopLeashing() -- stop teleporting to the leader (call it always in case something changed it)
        if BM_stayatposition==nil then
            inst.BM_staywalkableplattform = inst:GetCurrentPlatform()
            if inst.BM_staywalkableplattform==nil then
                inst.BM_stayatposition = inst:GetPosition() -- position is saved/loaded within shadowtoggleable component. we have to save/load it, cause otherwise the position might move a bit everytime loading the game
            end
            
        else -- BM_stayatposition~=nil -- check distance to position and teleport to it
            local init_pos = inst:GetPosition()
            local leader_pos = BM_stayatposition

            if distsq(leader_pos, init_pos) > (_T.BM_KEEP_WORKING_DIST*2)^2 then -- if more than double of the should distance away (for whatever reason), teleport him back to this position
                if inst.components.combat ~= nil then
                    inst.components.combat:SetTarget(nil)
                end
                inst:DoTaskInTime(0, function(inst,leader_pos) -- crash if without DoTaskInTime
                    if inst.Physics ~= nil then
                        inst.Physics:Teleport(leader_pos:Get())
                    else
                        inst.Transform:SetPosition(leader_pos:Get())
                    end
                end, leader_pos)
            end
        end
    else
        if BM_stayatposition~=nil then
            inst.components.follower:StartLeashing() -- start teleporting to leader again
            inst.BM_stayatposition = nil
            inst.BM_staywalkableplattform = nil
        end
    end
end
helpers["MatchSpeedAndBoundPosition"] = MatchSpeedAndBoundPosition

local function AddOtherInitStuff(inst)
    if inst.components.inventory==nil then
        inst:AddComponent("inventory")
    end
    
    inst:ListenForEvent("dropitem",function(dropper,data) -- to catch eg the dropitem from bearger
        if data~=nil and data.item~=nil then
            if dropper~=nil and dropper.components.health~=nil and not dropper.components.health:IsDead() and dropper.willdespawn~=true then
                if data.item~=nil and data.item.components~=nil and data.item.components.equippable~=nil and data.item.components.equippable.equipslot~=nil then
                    if helpers.GetMyEquippedItem(dropper,data.item.components.equippable.equipslot)==nil then -- only equip new one, if we now have none
                        helpers.EquipNewEquip(dropper,data.item.components.equippable.equipslot)
                    end
                end
            end
        end
    end)
    
    inst.match_speed_task = inst:DoPeriodicTask(2, helpers.MatchSpeedAndBoundPosition) -- taken from rezecibs balance mod. unfortunately there is no easy way to listen for speed changes on maxwell
    inst:ListenForEvent("death", function(inst) if inst.match_speed_task~=nil then inst.match_speed_task:Cancel() end end)
    inst:ListenForEvent("onremove", function(inst) if inst.match_speed_task~=nil then inst.match_speed_task:Cancel() end end)
    local old_GetSpeedMultiplier = inst.components.locomotor.GetSpeedMultiplier
    inst.components.locomotor.GetSpeedMultiplier = function(self) -- always have the same runspeed like the leader
        local leader = self.inst.components.follower.leader
        if leader then
            return leader.components.locomotor:GetSpeedMultiplier()
        end
        return old_GetSpeedMultiplier(self)
    end
    
    inst:AddComponent("shadowtoggleable")
    
    inst.components.inventory.GetOverflowContainer = function(self) return self.inst.components.container end -- go to container instead
    inst.components.inventory.maxslots = 0 -- inventory is only to equip things
    inst:AddComponent("inspectable")
    inst.level = 0
    inst.decay = 0
    
    
    -- local old_Teleport = inst.Physics.Teleport
    -- local function new_Teleport(obj,...)
        -- print("teleport")
        -- print(obj)
        -- print(obj.prefab)
        -- if obj~=nil and (obj.prefab=="shadowduelist" or helpers.isshadowworker(obj.prefab)) then
            -- if helpers.GetLeashPosition(obj)~=nil then-- checks obj.BM_staywalkableplattform and obj.BM_stayatposition
                -- return false -- dont teleport them when they are bound to a position
            -- end
        -- end    
        -- if old_Teleport~=nil then
            -- old_Teleport(obj,...)
        -- end
    -- end
    -- inst.Physics.Teleport = new_Teleport
    
end
helpers.AddOtherInitStuff = AddOtherInitStuff

return helpers