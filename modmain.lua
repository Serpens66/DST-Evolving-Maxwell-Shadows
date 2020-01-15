
PrefabFiles = {
    "journalpage",
}

local _T = GLOBAL.TUNING

_T.BM_dodebugprints = true

local helpers = GLOBAL.require("BM_helpers") 


-- TODO:
-- mehr decay je höher das level 
-- decay vllt auf hunger basierend machen? dann gäbe es automatisch auch entsprechende animationen. und blassheit dann an lebenspunkte oderso knüpfen (regeneration bei 0 hunger deaktivieren)

-- neues lvl system:
-- container größe ans level anpassen (wenn möglich auch mit entsprechender UI, aber falls es nicht geht, einfach die slots blocken)

-- noch überlegen ob ich auf zb 5 oder 10 lvl insg. runtergehen will, sodass ein lvl anstieg tatsächlich viel bewirkt, oder ob ich bei 100 lvl bleibe und man eben
-- um von 20 auf 21 zu kommen, dann bestimmte items braucht und bis 40 ists dann wieder nur fuel.
-- vermutlich am besten auf 10 lvl maximal gehen und eben pro lvl zb 10 nightmarefuel + spezielles item.
-- un einstellbare lebenszeit upgrade: also für alle x Tage lebenszeit kann ein upgrade gemacht werden (Sofern items vorhanden)


-- lebensregeneration nicht während des kampfes, sondern nur x minuten nach dem letzten angriff vom shadow oder gegen den shadow.

-- edible fuel: sicherstellen, dass foodtype von denen nicht überschriebe wird, falls ein anderer mod es bereits edible gemacht hat.
-- in dem fall den foodytpe auslesen und diesen dann den shadows geben.


-- store aus compoentaction für fuel bei shadows removen
-- -> bei fuel gibts dann nur feed action.

-- damit man den shadows dennoch einen vorrat an futter geben kann
-- wir mahunger sehr hoch gesetzt, zb auf 1500, während der starthunger
-- nach bauen zb bei 150 liegt.

-- die hungerrate soll mit dem level ansteigen (vllt auch der maxhunger).

-- die hurtrate ist mit doppelter regeneration nicht so gut. (vorallem auch wenn 0 gesetzt)
-- stattdessen als hurtrate die regenartion plus X nehmen (so ist hurt immer konstant)
-- bzw einfach die reneration auschalten wenn hungrig?

-- das unsichtbar werden der shadows kann an ihre lebenspunkte gekoppelt werden... oder ganz weglassen?

-- feeding nicht erlauben solange shadow combat target hat

-- evlt talker zufügen, damit shadows ein auf " *starving * " sprehcen können




modimport("BM_AllowedItemActions")
_T.BM_stayitemprefab = "journalpage"
table.insert(_T.BM_AllowedItemsInContainer.workerNoequip.prefabs,_T.BM_stayitemprefab)
table.insert(_T.BM_AllowedItemsInContainer.duelistNoequip.prefabs,_T.BM_stayitemprefab)

local SaveTheTrees = GetModConfigData("shadow_savethetrees")
if SaveTheTrees then -- no trees that wont have any pinecones
    table.insert(_T.BM_AllowedAction.never[GLOBAL.ACTIONS.CHOP].prefabs,"mushtree")
    table.insert(_T.BM_AllowedAction.never[GLOBAL.ACTIONS.CHOP].prefabs,"evergreen_sparse")
    table.insert(_T.BM_AllowedAction.never[GLOBAL.ACTIONS.CHOP].prefabs,"marsh_tree")
    table.insert(_T.BM_AllowedAction.never[GLOBAL.ACTIONS.CHOP].prefabs,"cave_banana_tree")
end
_T.MAXIMUM_SANITY_PENALTY = 0.905 -- instead of 0.9, to prevent rounding issues when reaching exaclty 10% (or 9.99999%).
_T.SHADOWWAXWELL_SANITY_PENALTY =
{
    SHADOWWORKER = GetModConfigData("shadow_worker_sanity") or 0.2,
    SHADOWLUMBER = GetModConfigData("shadow_worker_sanity") or _T.SHADOWWAXWELL_SANITY_PENALTY.SHADOWLUMBER,
    SHADOWMINER = GetModConfigData("shadow_worker_sanity") or _T.SHADOWWAXWELL_SANITY_PENALTY.SHADOWMINER,
    SHADOWDIGGER = GetModConfigData("shadow_worker_sanity") or _T.SHADOWWAXWELL_SANITY_PENALTY.SHADOWDIGGER,
    SHADOWDUELIST = GetModConfigData("shadow_duelist_sanity") or _T.SHADOWWAXWELL_SANITY_PENALTY.SHADOWDUELIST,
}
local duelistdamage_setting = string.split(GetModConfigData("maxwell_shadow_damage"),"-") -- -> {0.75,5}
_T.BM_SHADOW_MIN_DAMAGE_MULT = GLOBAL.tonumber(duelistdamage_setting[1])
_T.BM_SHADOW_MAX_DAMAGE_MULT = GLOBAL.tonumber(duelistdamage_setting[2])
local duelisthealth_setting = string.split(GetModConfigData("maxwell_shadow_health"),"-") -- -> {100,100}
_T.SHADOWWAXWELL_LIFE = GLOBAL.tonumber(duelisthealth_setting[1]) -- at level 0 directly after summoning it
_T.BM_SHADOWDUELIST_MAX_HEALTH = GLOBAL.tonumber(duelisthealth_setting[2]) -- at level 100, so after 100 nightmarefuel given
_T.SHADOWWAXWELL_ATTACK_PERIOD = GetModConfigData("maxwell_shadow_attackperiod") or _T.SHADOWWAXWELL_ATTACK_PERIOD
_T.SHADOWWAXWELL_HEALTH_REGEN = GetModConfigData("maxwell_shadow_healthregen") or _T.SHADOWWAXWELL_HEALTH_REGEN
-- _T.SHADOWWAXWELL_SPEED = _T.SHADOWWAXWELL_SPEED * GetModConfigData("shadow_maxwell_slowness") -- is now automatically speed of maxwell
local workerhealth_setting = string.split(GetModConfigData("maxwell_workers_health"),"-") -- -> {100,100}
_T.BM_SHADOWWORKER_MIN_HEALTH = GLOBAL.tonumber(workerhealth_setting[1])
_T.BM_SHADOWWORKER_MAX_HEALTH = GLOBAL.tonumber(workerhealth_setting[2])
_T.SHADOWWAXWELL_WORKERS_HEALTH_REGEN = GetModConfigData("maxwell_workers_health_regen")
local SanityList = {-_T.DAPPERNESS_SMALL,-_T.DAPPERNESS_TINY,0,_T.DAPPERNESS_TINY,_T.DAPPERNESS_SMALL,_T.DAPPERNESS_MED,_T.DAPPERNESS_MED_LARGE,_T.DAPPERNESS_LARGE,_T.DAPPERNESS_HUGE,_T.DAPPERNESS_SUPERHUGE}

local SHADOWPUPPET_AMOUNT = GetModConfigData("maxwell_shadow_amount")
-- local LUCKCHANCE = GetModConfigData("luck_chance")
_T.BM_SWITCHOPTION_FIGHTER = GetModConfigData("switch_option_fighter")
local LEVEL_ENABLED = GetModConfigData("level_enabled")

local WAXWELL_HEALTH = GetModConfigData("maxwell_health")
local WAXWELL_SANITY = GetModConfigData("maxwell_sanity")
local WAXWELL_SANITY_REGEN = SanityList[GetModConfigData("maxwell_sanity_regen")]
local SHADOW_DRAIN = -SanityList[GetModConfigData("shadow_sanity_drain")]
local NIGHTMAREFUEL_START = GetModConfigData("nightmarefuel_start")
local DIGUP_SETTING = GetModConfigData("whendigup")
local PREFERRED_TREESTAGE = GetModConfigData("shadow_preferable_tree")
local KEEP_UPGRADE_FUEL = GetModConfigData("keep_upgrade_fuel")
local SHADOW_UPGRADE_VISUALS = GetModConfigData("upgrade_visuals")
_T.SM_MAX_LEVEL = 100 -- up to x nightmarefuel=levels. duelist no setting for this one, since it is enough to define the bonus per level..
_T.SM_MAXLEVEL_WORKER = _T.SM_MAX_LEVEL/5 -- since the workerpseed increase is not unlimted possible, a setting to set this value might be good... will make it _T for now, so mods can change it
if not LEVEL_ENABLED then -- no levels allowed, so max level 1
    _T.SM_MAX_LEVEL = 1 -- if we would set it to 0, I would have to code exceptions in the code to prevent mathematics not valid with 0... so set it 1 instead
    _T.SM_MAXLEVEL_WORKER = 1
end
local SHADOW_DECAY_RATE = GetModConfigData("shadow_decay_rate")
_T.BM_HUNGER_PER_FUEL = 100
_T.BM_HEALTH_PER_FUEL = 50
_T.BM_HUNGER_PER_DAY = _T.BM_HUNGER_PER_FUEL / GetModConfigData("shadow_decay_rate")

local MAX_DECAY = 5 -- after this times without fuel, they will disappear
_T.BM_UNLIMETED_DUR = GetModConfigData("durability_shadows_equipment")
local UNLOCK_RECIPE = GetModConfigData("unlock_recipe")
local upgrade_workingspeed = string.split(GetModConfigData("upgrade_workingspeed"),"-")
local TOOL_E_MINVALUE = GLOBAL.tonumber(upgrade_workingspeed[1])
local TOOL_E_MAXVALUE = GLOBAL.tonumber(upgrade_workingspeed[2])

local SHADOW_EXAMINEINFO = GetModConfigData("examine")
_T.BM_KEEP_WORKING_DIST = GetModConfigData("working_distance") or 14
local SEE_WORK_DIST = GetModConfigData("see_working_distance") or 10
_T.BM_STOP_KITING_DIST = GetModConfigData("stop_kiting_distance") or 5
local KITING_DIST = _T.BM_STOP_KITING_DIST - 2 -- If enemy is that close or closer and there is time left for kiting, start kiting. Should be lower than stop kiting distance!  There is no need to change this, because of my automatic attack speed adjustment
_T.BM_SHADOW_JOBS = {GLOBAL.ACTIONS.CHOP,GLOBAL.ACTIONS.MINE,GLOBAL.ACTIONS.DIG,GLOBAL.ACTIONS.PICK}--,ACTIONS.HAMMER} -- test hammer

local hitstuntimeout_setting = string.split(GetModConfigData("maxwell_shadow_hitstuntimeout"),"-") -- -> {0-10}
_T.BM_SHADOW_MIN_HITSTUNTIMEOUT = GLOBAL.tonumber(hitstuntimeout_setting[1])
_T.BM_SHADOW_MAX_HITSTUNTIMEOUT = GLOBAL.tonumber(hitstuntimeout_setting[2])
local ATTACKSHADOWCREATURES = GetModConfigData("shadow_attackshadow") -- dont know where to change that...

helpers.removetablekey(GLOBAL.AllRecipes, "shadowdigger_builder")
helpers.removetablekey(GLOBAL.AllRecipes, "shadowminer_builder")    

GLOBAL.FOODTYPE.SHADOWFOOD = "SHADOWFOOD"

AddRecipe("journalpage1", { GLOBAL.Ingredient(GLOBAL.CHARACTER_INGREDIENT.HEALTH, 5)}, GLOBAL.CUSTOM_RECIPETABS.SHADOW, GLOBAL.TECH.SHADOW_TWO,nil,nil,true,1,"shadowmagic",nil,"papyrus.tex",nil,"journalpage")

local i_index = nil
for k,v in pairs(GLOBAL.AllRecipes) do -- adjust the sanity amount picture for the recipes without overwriting the recipe
    if v.name=="shadowlumber_builder" or v.name=="shadowdigger_builder" or v.name=="shadowminer_builder" or v.name=="shadowduelist_builder" then
        if UNLOCK_RECIPE then
            v.nounlock = false
        end
        if v.character_ingredients~=nil then
            for i,ingredient in ipairs(v.character_ingredients) do
                -- for k, v in pairs(ingredient) do
                    -- print(tostring(k).." : "..tostring(v))
                -- end
                if ingredient.type=="half_sanity" then -- GLOBAL.CHARACTER_INGREDIENT.SANITY does not work for some reason
                    if v.name=="shadowlumber_builder" then
                        ingredient.amount = _T.SHADOWWAXWELL_SANITY_PENALTY.SHADOWWORKER
                    elseif v.name=="shadowduelist_builder" then
                        ingredient.amount = _T.SHADOWWAXWELL_SANITY_PENALTY.SHADOWDUELIST
                    end
                end
            end
        end
        i_index = nil
        if v.ingredients~=nil then
            if v.name=="shadowduelist_builder" then
                for i,ingredient in ipairs(v.ingredients) do
                    if ingredient.type=="spear" then -- remove spear as ingredient fo duelist (digger/miner were already removed)
                        i_index = i -- remember this index to remove it      
                    end
                end
                if i_index~=nil then
                    table.remove(v.ingredients,i_index)
                end
            elseif helpers.isshadowworker(v.name,true) then -- remove the axe from lumber to make it worker
                for i,ingredient in ipairs(v.ingredients) do
                    if ingredient.type=="axe" then -- remove spear as ingredient fo duelist (digger/lumber/miner were already removed)
                        i_index = i -- remember this index to remove it      
                    end
                end
                if i_index~=nil then
                    table.remove(v.ingredients,i_index)
                end
            end
        
        end
    -- elseif v.name=="shadowworker_builder" then 
        -- if UNLOCK_RECIPE then
            -- v.nounlock = false
        -- end
    end
end



------------------------------------------------------------------------
-- #### make shadows able to pick sth... add stategraphs from sgwilson ##########
------------------------------------------------------------------------
modimport("scripts/stategraphadditions")

AddComponentPostInit("armor",function(self) -- execute this for server and client
    -- print("AddTag armor")
    self.inst:AddTag("armor") -- so client can work with it... although I'm not sure if AddComponentPostInit is even executed for clients, but it seems to work?!
end)


local function GetEffectivnessMultiplier(inst) -- calc a multiplier for tools according to level of shadow
    return TOOL_E_MINVALUE * (helpers.nroot(TOOL_E_MAXVALUE/TOOL_E_MINVALUE,_T.SM_MAXLEVEL_WORKER))^inst.level -- this exponential is needed to deal with multipliers
end
local function ShadowApplyUpgrades(inst) -- health and damage multipliers based on level
    if _T.BM_dodebugprints then
        print("ShadowApplyUpgrades "..tostring(inst))
    end
    
    if inst~=nil and inst:IsValid() and inst.willdespawn~=true then
        local prefab = inst.prefab
        local health_percent = inst.components.health:GetPercent()
        local maxlevel = helpers.isshadowworker(prefab) and _T.SM_MAXLEVEL_WORKER or _T.SM_MAX_LEVEL
        if prefab=="shadowduelist" then
            
            local healthstep_per_level = (_T.BM_SHADOWDUELIST_MAX_HEALTH - _T.SHADOWWAXWELL_LIFE)/maxlevel -- calcualte the steps here, in case anything changes the min/max health or maxlevel from outside
            if healthstep_per_level>0 then -- who knows...
                inst.components.health:SetMaxHealth(_T.SHADOWWAXWELL_LIFE + inst.level*healthstep_per_level)
                inst.components.health:SetPercent(health_percent)
            end
            if SHADOW_DECAY_RATE>0 then
                inst.components.hunger:SetKillRate(inst.components.health.maxhealth/_T.TOTAL_DAY_TIME*2) -- will loose all its max HP within half day
            end
            local newdamagemult = _T.BM_SHADOW_MIN_DAMAGE_MULT * (helpers.nroot(_T.BM_SHADOW_MAX_DAMAGE_MULT/_T.BM_SHADOW_MIN_DAMAGE_MULT,maxlevel))^inst.level  -- this exponential is needed to deal with multipliers
            if _T.BM_dodebugprints then
                print("ShadowApplyUpgrades newdamagemult "..tostring(newdamagemult))
            end
            inst.components.combat.externaldamagemultipliers:SetModifier("shadowfuelupgrade", newdamagemult)
            local regenstepperlevel = (_T.SHADOWWAXWELL_HEALTH_REGEN*2 - _T.SHADOWWAXWELL_HEALTH_REGEN)/maxlevel -- doubles at maxlevel
            inst.components.health:StartRegen(_T.SHADOWWAXWELL_HEALTH_REGEN + inst.level*regenstepperlevel, _T.SHADOWWAXWELL_HEALTH_REGEN_PERIOD) --- also a bit health regen increase 
        elseif helpers.isshadowworker(prefab) then
            local healthstep_per_level = (_T.BM_SHADOWWORKER_MAX_HEALTH - _T.BM_SHADOWWORKER_MIN_HEALTH)/maxlevel -- calcualte the steps here, in case anything changes the min/max health or maxlevel from outside
            if healthstep_per_level>0 then -- who knows...
                inst.components.health:SetMaxHealth(_T.BM_SHADOWWORKER_MIN_HEALTH + inst.level*healthstep_per_level)
                inst.components.health:SetPercent(health_percent)
            end
            if SHADOW_DECAY_RATE>0 then
                inst.components.hunger:SetKillRate(inst.components.health.maxhealth/_T.TOTAL_DAY_TIME*2) -- will loose all its max HP within half day
            end
            local regenstepperlevel = (_T.SHADOWWAXWELL_WORKERS_HEALTH_REGEN*2 - _T.SHADOWWAXWELL_WORKERS_HEALTH_REGEN)/maxlevel -- doubles at maxlevel
            inst.components.health:StartRegen(_T.SHADOWWAXWELL_WORKERS_HEALTH_REGEN + inst.level*regenstepperlevel, _T.SHADOWWAXWELL_HEALTH_REGEN_PERIOD) --- also a bit health regen increase 
            if (TOOL_E_MINVALUE~=1 and TOOL_E_MAXVALUE~=1) then
                local m = GetEffectivnessMultiplier(inst)
                if _T.BM_dodebugprints then
                    print("set worker workmultiplier to "..tostring(m))
                end
                for _,job in ipairs(_T.BM_SHADOW_JOBS) do
                    inst.components.workmultiplier:AddMultiplier(job, m, "shadowfuelupgrade") -- only tool work, so PICK is not changed by this, but it also does not hurt
                end
                if m<2 then -- change pick
                    local equipped = helpers.GetMyEquippedItem(inst)
                    if inst:HasTag("fastpicker") and (equipped==nil or not string.find(equipped.prefab,"scythe")) then -- if scythe equipped, do not remove fastpicker
                        inst:RemoveTag("fastpicker")
                    end
                    if inst:HasTag("quagmire_fasthands") then
                        inst:RemoveTag("quagmire_fasthands")
                    end
                elseif m>2 and m<4 and not inst:HasTag("quagmire_fasthands") then -- speed up PICK action
                    inst:AddTag("quagmire_fasthands")
                    local equipped = helpers.GetMyEquippedItem(inst)
                    if inst:HasTag("fastpicker") and (equipped==nil or not string.find(equipped.prefab,"scythe")) then -- if scythe equipped, do not remove fastpicker
                        inst:RemoveTag("fastpicker")
                    end
                elseif m>4 and not inst:HasTag("fastpicker") then
                    inst:AddTag("fastpicker")
                    if inst:HasTag("quagmire_fasthands") then
                        inst:RemoveTag("quagmire_fasthands")
                    end
                end
            end
        end
        local hungerstepperlevel = ((_T.BM_HUNGER_PER_DAY/_T.TOTAL_DAY_TIME)*2 - (_T.BM_HUNGER_PER_DAY/_T.TOTAL_DAY_TIME))/maxlevel -- doubles at maxlevel
        inst.components.hunger:SetRate((_T.BM_HUNGER_PER_DAY/_T.TOTAL_DAY_TIME) + inst.level*hungerstepperlevel)        
        
        local hitstuntimeout_per_level = (_T.BM_SHADOW_MAX_HITSTUNTIMEOUT - _T.BM_SHADOW_MIN_HITSTUNTIMEOUT)/maxlevel
        if hitstuntimeout_per_level>0 then
            if helpers.isshadowworker(inst.prefab) then
                hitstuntimeout_per_level = hitstuntimeout_per_level/2 -- worker will get half the value
            end
            inst.hitstuntimeout = _T.BM_SHADOW_MIN_HITSTUNTIMEOUT + inst.level*hitstuntimeout_per_level
        end
        
        local decayintensity = 0.6-(0.6/MAX_DECAY)*inst.decay -- the more decay, the less visible
        if SHADOW_UPGRADE_VISUALS then
            if SHADOW_UPGRADE_VISUALS=="size" then -- removed from modsettings, makes too much problems with speed and also blocks clicking
                inst.Transform:SetScale(1+inst.level/(maxlevel/3), 1+inst.level/(maxlevel/3), 1+inst.level/(maxlevel/3)) -- make them bigger, 3 times as big after reaching final level
                inst.components.locomotor:SetExternalSpeedMultiplier(inst, "shadowfuelupgrade", math.min(1/math.sqrt(1+inst.level/10,2),1))--  make it slower, cause setscale also makes them kind of faster .. is acceptable aproximation to make them ~ the same speed ingame, but still looking for a btter function...
            elseif SHADOW_UPGRADE_VISUALS=="red" then
                inst.AnimState:SetMultColour((255/maxlevel*inst.level)/255, 0, 0, decayintensity)
            elseif SHADOW_UPGRADE_VISUALS=="green" then
                inst.AnimState:SetMultColour(0, (255/maxlevel*inst.level)/255, 0, decayintensity) -- equipment is affected by colour and intensity, shadow only by intensity.
            elseif SHADOW_UPGRADE_VISUALS=="blue" then
                inst.AnimState:SetMultColour(0, 0, (255/maxlevel*inst.level)/255, decayintensity)
            elseif SHADOW_UPGRADE_VISUALS=="yellow" then
                inst.AnimState:SetMultColour((255/maxlevel*inst.level)/255, (255/maxlevel*inst.level)/255, 0, decayintensity)
            elseif SHADOW_UPGRADE_VISUALS=="purple" then
                inst.AnimState:SetMultColour((255/maxlevel*inst.level)/255, 0, (255/maxlevel*inst.level)/255, decayintensity)
            elseif SHADOW_UPGRADE_VISUALS=="turquoise" then
                inst.AnimState:SetMultColour(0, (255/maxlevel*inst.level)/255, (255/maxlevel*inst.level)/255, decayintensity)
            end
        elseif SHADOW_DECAY_RATE>0 then -- still show decay
            inst.AnimState:SetMultColour(0, 0, 0, decayintensity)
        end
    end
end

local function ContainerOnOpen(inst,opener)
    local item = nil
    for _,eslot in ipairs({GLOBAL.EQUIPSLOTS.HANDS,GLOBAL.EQUIPSLOTS.BODY,GLOBAL.EQUIPSLOTS.HEAD}) do
        item = inst.components.inventory:Unequip(eslot) -- unequip all and equip new on close
        inst.components.container:GiveItem(item)
    end
end

local function ContainerOnClose(inst, opener, makenewequip_on_equipslot) -- do upgrade,restore decay and equip equipment
    local item = nil
    local oneitem = nil
    local foundhat = nil
    local foundarmor = nil
    local foundweapon = nil
    local foundtool = nil
    local equipslot = nil
    if inst~=nil and inst.willdespawn~=true and inst.components~=nil and inst.components.container~=nil then
        local maxlevel = helpers.isshadowworker(inst.prefab) and _T.SM_MAXLEVEL_WORKER or _T.SM_MAX_LEVEL
        local amount = maxlevel-inst.level + inst.decay -- the max amount we would like to consume, if possible
        local fuelconsumed = helpers.Findandconsume_prefab(inst,amount,"nightmarefuel") -- returns the acutally consumed fuel
        while fuelconsumed > 0 and inst.decay > 0 do -- first reduce decay 
            fuelconsumed = fuelconsumed-1
            inst.decay = inst.decay - 1 
        end
        while fuelconsumed > 0 do -- then increase level 
            fuelconsumed = fuelconsumed-1
            inst.level = inst.level + 1 
        end
        ShadowApplyUpgrades(inst)
        helpers.EquipNewEquip(inst)
    end
end

-- save/load the level of shadows
local function onsave(inst,data)
    data.level = inst.level > 0 and inst.level or nil
    data.decay = inst.decay > 0 and inst.decay or nil
end
local function onpreload(inst, data)
    if data ~= nil then
        if data.decay~=nil then
            inst.decay = data.decay
        end
        if data.level~=nil then
            inst.level = data.level
            ShadowApplyUpgrades(inst) -- health and damage multipliers based on level
            --re-set these from the save data, because of load-order clipping issues
            if data.health ~= nil and data.health.health ~= nil then
                inst.components.health:SetCurrentHealth(data.health.health) -- not sure if this is needed for shadows..
            end
            inst.components.health:DoDelta(0)
        end
    end
end

local function newkeeptargetfn(inst, target)
    --Is your leader nearby and your target not dead? Stay on it. Match _T.BM_KEEP_WORKING_DIST in brain
    return inst.components.follower:IsNearLeader(_T.BM_KEEP_WORKING_DIST,true)
        and inst.components.combat:CanTarget(target)
		and target.components.minigame_participator == nil
end

local function ShadowDoDecay(inst)
    if _T.BM_dodebugprints then
        print("DoDecay..."..tostring(inst))
    end
    local fuelconsumed = helpers.Findandconsume_prefab(inst,1,"nightmarefuel")
    if fuelconsumed~=1 then -- were not able to consume fuel from container, so reduce level or increase decay
        if inst.level>0 then
            inst.level = inst.level - 1
        else
            inst.decay = inst.decay + 1
            local leader = helpers.GetLeader(inst)
            if leader~=nil and leader.components~=nil and leader.components.petleash~=nil and leader.components.petleash:IsPet(inst) then
                if inst.decay >= MAX_DECAY then
                    inst.willdespawn = true -- the despan will close container and this will trigger alot of other stuff, that might crash the game, cause pet was already removed. 
                    if inst.components.lootdropper == nil then  -- do the same like when we are hit by our leader (onattack)
                        inst:AddComponent("lootdropper")
                    end
                    if inst.components.inventory~=nil then
                        inst.components.inventory:DropEverything() -- simply drop everything in inventory (same happens when they die within regular functions)
                    end
                    if inst.components.container~=nil then
                        inst.components.container:DropEverything() -- simply drop everything in container (same happens when they die within regular functions)
                    end
                    inst.components.lootdropper:SpawnLootPrefab("nightmarefuel", inst:GetPosition())
                    leader.components.petleash:DespawnPet(inst)
                    leader.components.talker:Say(_T.STRING_SHADOW_DECAYED)
                else
                    leader.components.talker:Say(_T.STRING_SHADOW_DECAYS)
                end
            end
        end
        ShadowApplyUpgrades(inst)
    end
end


local function OnAttacked(pet,data) -- when maxwell owner attacked them, they will despawn, but we have to do sth before
    if data.attacker ~= nil then
        if data.attacker.components.petleash ~= nil and data.attacker.components.petleash:IsPet(pet) then
            local spawn = nil
            -- if math.random() < LUCKCHANCE then
                -- spawn = GLOBAL.SpawnPrefab("nightmarefuel")
                -- if spawn~=nil then
                    -- spawn.Transform:SetPosition(pet.Transform:GetWorldPosition())
                -- end
            -- end
            pet.willdespawn = true -- the despan will close container and this will trigger alot of other stuff, that might crash the game, cause pet was already removed. 
            if pet.components.inventory~=nil then
                pet.components.inventory:DropEverything() -- simply drop everything in inventory (same happens when they die within regular functions)
            end
            if pet.components.container~=nil then
                pet.components.container:DropEverything() -- simply drop everything in container (same happens when they die within regular functions)
            end
            if KEEP_UPGRADE_FUEL then
                local previousspawn = nil
                local newstack = nil
                local pos = nil
                if KEEP_UPGRADE_FUEL=="half" then
                    pet.level = pet.level/2
                end
                while pet.level>0 do
                    spawn = GLOBAL.SpawnPrefab("nightmarefuel")
                    if spawn~=nil then
                        if previousspawn~=nil and previousspawn.components~=nil and previousspawn.components.stackable~=nil and spawn.components~=nil and spawn.components.stackable~=nil then
                            pos = previousspawn:GetPosition()
                            newstack = previousspawn.components.stackable:Put(spawn,pos)
                        elseif previousspawn==nil then
                            spawn.Transform:SetPosition(pet.Transform:GetWorldPosition())
                            previousspawn = spawn
                        else
                        end
                        if newstack~=nil then
                            newstack.Transform:SetPosition(pet.Transform:GetWorldPosition())
                            previousspawn = newstack -- otherwise previousspawn is still our stack
                        end
                    end
                    pet.level = pet.level -1
                end
            end
        end
    end
end

local round2=function(num, idp)
	return GLOBAL.tonumber(string.format("%." .. (idp or 0) .. "f", num))
end


AddComponentPostInit("teleporter",function(comp) -- no teleport of shadows when maxwell enters wormhole and they are bound to positon
    local old_Teleport = comp.Teleport
    local function new_Teleport(self,obj,...)
        if obj~=nil and (obj.prefab=="shadowduelist" or helpers.isshadowworker(obj.prefab)) then
            if helpers.GetLeashPosition(obj)~=nil then-- checks obj.BM_staywalkableplattform and obj.BM_stayatposition
                return false -- dont teleport them when they are bound to a position
            end
        end    
        if old_Teleport~=nil then
            return old_Teleport(self,obj,...)
        end
    end
    comp.Teleport = new_Teleport
end)


if SHADOW_DECAY_RATE>0 then
    AddPrefabPostInit("nightmarefuel",function(inst)
        inst:AddComponent("edible")
        inst.components.edible.foodtype = GLOBAL.FOODTYPE.SHADOWFOOD
        inst.components.edible.healthvalue = _T.BM_HEALTH_PER_FUEL
        inst.components.edible.hungervalue = _T.BM_HUNGER_PER_FUEL
    end)
end

AddPrefabPostInit("shadowduelist",function(inst)
    
    inst.entity:AddDynamicShadow() -- add shadow, otherwise umbrella will crash
    inst.DynamicShadow:Enable(false) -- but make it invisible
    
    
    if ATTACKSHADOWCREATURES then
        inst:AddTag("crazy") -- to also be able to attack shadowcreatures and such
    end
        
    
    inst.AnimState:Hide("ARM_carry") -- show hands as default weapon, so it is good idea to give better one
    inst.AnimState:Show("ARM_normal")

    if not GLOBAL.TheWorld.ismastersim then
        inst:DoTaskInTime(0, function(inst)  
            inst.replica.container:WidgetSetup("shadowBMduelist",helpers.containerparams.shadowBMduelist)             
        end)
        return inst
    end
    
    helpers.AddOtherInitStuff(inst)
    
    if _T.BM_KEEP_WORKING_DIST~=14 then -- if we changed it from games default
        inst.components.combat:SetKeepTargetFunction(newkeeptargetfn) --Keep attacking while leader is near. set our new _T.BM_KEEP_WORKING_DIST value
    end
           
    helpers.MyListenForEventPutinFirst(inst,"attacked",OnAttacked)
    inst:ListenForEvent("armorbroke",helpers.EquipNewArmor)

    
    if SHADOW_DECAY_RATE>0 then
        helpers.AddHungerStuff(inst)
    end
    
    inst:DoTaskInTime(1,helpers.check_attackspeed_kite)

    inst.OnSave = onsave
    inst.OnPreLoad = onpreload
    inst.decaytask = nil
    if SHADOW_DECAY_RATE>0 then
        inst.decaytask = inst:DoPeriodicTask(_T.TOTAL_DAY_TIME*SHADOW_DECAY_RATE, ShadowDoDecay, nil)
    end
    inst:AddComponent("container")
    inst.components.container.acceptsstacks = true
    inst.components.container.onopenfn = ContainerOnOpen
    inst.components.container.onclosefn = ContainerOnClose
    inst.components.container:WidgetSetup("shadowBMduelist",helpers.containerparams.shadowBMduelist) -- 12 slots so you can give him many armor and weapons before fight
    
    local old_Open = inst.components.container.Open
    local function new_Open(self,doer)
        if doer==helpers.GetLeader(self.inst) and old_Open~=nil then -- only the leader can open it
            return old_Open(self,doer)
        end
    end
    inst.components.container.Open = new_Open
    
    if SHADOW_EXAMINEINFO then
        local _GetDescription = inst.components.inspectable.GetDescription
        inst.components.inspectable.GetDescription = function(self, viewer,...)
            local desc = _GetDescription(self,viewer,...)
            if desc== nil then
                desc = ""
            end
            local weapon = helpers.GetMyEquippedItem(inst,GLOBAL.EQUIPSLOTS.HANDS)
            if weapon==nil or weapon.components==nil or weapon.components.weapon==nil then
                weapon = nil
            end
            local str = "\nLevel: "..tostring(self.inst.level).."\nDecay: "..tostring(self.inst.decay).."\nHealth: "..tostring(math.ceil(self.inst.components.health.currenthealth)).."/"..tostring(self.inst.components.health.maxhealth).."\nDamage: "..tostring(round2(helpers.CalcDamage(self.inst.components.combat,weapon),1)).."\nStunTimeout: "..tostring(self.inst.hitstuntimeout).." sec"
            desc = GLOBAL.tostring(desc)..str
            return desc
        end
   end
   ShadowApplyUpgrades(inst) -- health and damage multipliers based on level
end)

AddPrefabPostInit("shadowlumber",function(inst) -- lumber is the new worker
    
    inst.entity:AddDynamicShadow() -- add shadow, otherwise umbrella will crash
    inst.DynamicShadow:Enable(false) -- but make it invisible
    
    inst.AnimState:Hide("ARM_carry") -- show hands as default weapon, so it is good idea to give better one
    inst.AnimState:Show("ARM_normal")
    inst.AnimState:OverrideSymbol("swap_hat", "hat_straw", "swap_hat") -- show straw hat
    inst.AnimState:Hide("HAIR_NOHAT")
    inst.AnimState:Hide("HAIR")
    inst.AnimState:Show("HAT")
    inst.AnimState:Show("HAIR_HAT")
    
    if not GLOBAL.TheWorld.ismastersim then
        inst:DoTaskInTime(0, function(inst)  
           inst.replica.container:WidgetSetup("shadowBMworker",helpers.containerparams.shadowBMworker)
        end)
        return inst
    end
    
    helpers.AddOtherInitStuff(inst)
    
    inst:ListenForEvent("picksomething",function(inst,data)
        if data~=nil and data.loot~=nil and data.object~=nil then
            data.loot:AddTag("shadowincontainer") -- allow the picked item to be put into the container
            data.object:ListenForEvent("picked",function(inst,data2)
                if data2~=nil and data2.loot~=nil then
                    data2.loot:RemoveTag("shadowincontainer") -- meanwhile it was put into container, so we can remove the tag again. that way players also cant store their stuff in workers
                end
            end)
        end
    end)
    
    if SHADOW_DECAY_RATE>0 then
        helpers.AddHungerStuff(inst)
    end
    
    inst:AddComponent("workmultiplier") -- to level up working speed with tools
    
    helpers.MyListenForEventPutinFirst(inst,"attacked",OnAttacked)
    
    inst.components.health:SetMaxHealth(_T.BM_SHADOWWORKER_MIN_HEALTH)
    inst.components.health:StartRegen(_T.SHADOWWAXWELL_WORKERS_HEALTH_REGEN, _T.SHADOWWAXWELL_HEALTH_REGEN_PERIOD)
    
    inst.OnSave = onsave
    inst.OnPreLoad = onpreload
    inst.decaytask = nil
    if SHADOW_DECAY_RATE>0 then
        inst.decaytask = inst:DoPeriodicTask(_T.TOTAL_DAY_TIME*SHADOW_DECAY_RATE, ShadowDoDecay, nil)
    end
    inst:AddComponent("container")
    inst.components.container.acceptsstacks = true
    inst.components.container.onopenfn = ContainerOnOpen
    inst.components.container.onclosefn = ContainerOnClose
    inst.components.container:WidgetSetup("shadowBMworker",helpers.containerparams.shadowBMworker) -- 9 slots
    
    local old_Open = inst.components.container.Open
    local function new_Open(self,doer)
        if doer==helpers.GetLeader(self.inst) and old_Open~=nil then -- only the leader can open it
            return old_Open(self,doer)
        end
    end
    inst.components.container.Open = new_Open
    
    inst.components.container.GetSpecificSlotForItem = function(self,item,...) -- make it able to see occupied stacks and if sth can be stacked
        if item~=nil and self.usespecificslotsforitems and self.itemtestfn ~= nil then
            local iteminslot = nil
            for i = 1, self:GetNumSlots() do
                iteminslot = self:GetItemInSlot(i)
                if iteminslot==nil or (iteminslot.prefab == item.prefab and iteminslot.skinname == item.skinname and self.acceptsstacks and iteminslot.components~=nil and iteminslot.components.stackable~=nil and not iteminslot.components.stackable:IsFull()) then
                    if self:itemtestfn(item, i) then
                        return i
                    end
                end
            end
        end
    end
    
    local old_GiveItem = inst.components.container.GiveItem
    local function new_GiveItem(self, item, slot, src_pos, drop_on_fail,fromfunction) -- overwrite onload for container, to allow every item in this container that was in container before
        if fromfunction=="fromonload" and item~=nil and item:IsValid() then
            item:AddTag("shadowincontainer")
        end
        -- if item~=nil and item:IsValid() then
            -- item:AddTag("nosteal")
        -- end
        local result = false
        if old_GiveItem~=nil then 
            result = old_GiveItem(self, item, slot, src_pos, drop_on_fail,fromfunction)
            if item~=nil and item:IsValid() then
                item:RemoveTag("shadowincontainer")
            end
        end
        return result
    end
    inst.components.container.GiveItem = new_GiveItem
    
    local function new_OnLoad(self,data,...) -- overwrite onload for shadow container, to allow every item in this container, that was in container before
        if data.items then
            for k,v in pairs(data.items) do
                local inst = GLOBAL.SpawnSaveRecord(v, newents)
                if inst then
                    self:GiveItem(inst, k,nil,nil,"fromonload") -- make the GiveItem function know that it came from onload
                end
            end
        end
    end
    inst.components.container.OnLoad = new_OnLoad
    
    if SHADOW_EXAMINEINFO then
        local _GetDescription = inst.components.inspectable.GetDescription
        inst.components.inspectable.GetDescription = function(self, viewer,...)
            local desc = _GetDescription(self,viewer,...)
            if desc== nil then
                desc = ""
            end
            local weapon = helpers.GetMyEquippedItem(inst,GLOBAL.EQUIPSLOTS.HANDS)
            if weapon==nil or weapon.components==nil or weapon.components.weapon==nil then
                weapon = nil
            end
            str = "\nLevel: "..tostring(self.inst.level).."\nDecay: "..tostring(self.inst.decay).."\nHealth: "..tostring(math.ceil(self.inst.components.health.currenthealth)).."/"..tostring(self.inst.components.health.maxhealth).."\nWorkmultiplier: "..tostring(round2(GetEffectivnessMultiplier(self.inst),2)).."\nStunTimeout: "..tostring(self.inst.hitstuntimeout).." sec"
            desc = GLOBAL.tostring(desc)..str
            return desc
        end
   end
   ShadowApplyUpgrades(inst) -- health and damage multipliers based on level
end)




--------------
--########################################
--------------- Enable/Disable shadows (taken from rezecib balance mod) --------------
--########################################
--------------

local BM_SHADOWTOGGLE = AddAction("BM_SHADOWTOGGLE", "Disengage", function(act)
	if act.target and act.target:HasTag("_shadowtoggleable") --we're targeting a minion
	and act.doer and act.doer.components.petleash and act.doer.components.petleash:IsPet(act.target) then --it's our own minion
		act.target.components.shadowtoggleable:ToggleActive()
		return true
	end
end)
BM_SHADOWTOGGLE.strfn = function(act)
	return act.target and (act.target:HasTag("shadowtoggle_active") and "STOPWORKING" or "STARTWORKING")
end
BM_SHADOWTOGGLE.distance = 15
BM_SHADOWTOGGLE.mount_valid = true
AddComponentAction("SCENE", "shadowtoggleable", function(inst, doer, actions, right)
	if right and inst.replica.follower:GetLeader() and inst.replica.follower:GetLeader() == doer then
		table.insert(actions, BM_SHADOWTOGGLE)
	end
end)
AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(BM_SHADOWTOGGLE, "give"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(BM_SHADOWTOGGLE, "give"))

local ACTIONS_STORE_fn = GLOBAL.ACTIONS.STORE.fn -- change the store action, to only allow maxwell to store his stuff in shadows
GLOBAL.ACTIONS.STORE.fn = function(action)
    local target = action.target
    local doer = action.doer
    if (target.prefab=="shadowduelist" or helpers.isshadowworker(target.prefab)) and GLOBAL.TheWorld.ismastersim and doer~=helpers.GetLeader(target) then -- GLOBAL.TheWorld.ismastersim
        return false, "NOTALLOWED"
    else
        return ACTIONS_STORE_fn(action)
    end
end

local BM_SHADOWCALL = AddAction("BM_SHADOWCALL", "Shadowcall", function(act)
    if act.doer~=nil and act.doer.prefab=="waxwell" and act.doer.components.leader~=nil then
        for k,v in pairs(act.doer.components.leader.followers) do
            if k.prefab=="shadowduelist" or helpers.isshadowworker(k.prefab) then
                helpers.MoveInstAtLandPlotNearInst(k,act.doer,1,0,1)
                GLOBAL.SpawnPrefab("collapse_small").Transform:SetPosition(k.Transform:GetWorldPosition()) -- a small effect
                if k.components.container~=nil then
                    local stayitems = {}
                    local item = nil
                    for i = 1, k.components.container:GetNumSlots() do
                        item = k.components.container:GetItemInSlot(i)
                        if item~=nil and item:IsValid() and item.prefab==_T.BM_stayitemprefab then
                            table.insert(stayitems,item)
                        end
                    end
                    for _,stayitem in ipairs(stayitems) do
                        k.components.container:DropEverythingWithTag("journalpage")
                    end
                    helpers.MatchSpeedAndBoundPosition(k) -- update 
                end
            end
        end
        act.doer.sg:GoToState("idle")
        return true
    end
end)
BM_SHADOWCALL.priority = 2 -- so it is shown together with the pickup action
AddComponentAction("SCENE", "prototyper", function(inst, doer, actions, right)
    if right and inst.prefab=="waxwelljournal" and doer.prefab=="waxwell" then
        table.insert(actions, BM_SHADOWCALL)
	end
end)
AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(BM_SHADOWCALL, "dochannelaction")) -- book -- castspell
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(BM_SHADOWCALL, "dochannelaction"))

if SHADOW_DECAY_RATE>0 then
    --eat and feed
    local ACTIONS_FEEDPLAYER_fn = GLOBAL.ACTIONS.FEEDPLAYER.fn
    GLOBAL.ACTIONS.FEEDPLAYER.fn = function(act)
        if act.target ~= nil and act.target:IsValid() and (act.target.prefab=="shadowduelist" or helpers.isshadowworker(act.target.prefab)) then
            if act.target.sg:HasStateTag("idle") and not (act.target.sg:HasStateTag("busy") or act.target.sg:HasStateTag("attacking")) and
                (act.target.components.combat == nil or act.target.components.combat:HasTarget()==nil) and -- not while fighting
                act.target.components.eater ~= nil and act.invobject.components.edible ~= nil and act.target.components.eater:CanEat(act.invobject) then
                local food = act.invobject.components.inventoryitem:RemoveFromOwner()
                if food ~= nil then
                    act.target:AddChild(food)
                    food:RemoveFromScene()
                    food.components.inventoryitem:HibernateLivingItem()
                    food.persists = false
                    act.target.sg:GoToState("eat",{ feed = food, feeder = act.doer })
                    return true
                end
            end    
        else
            return ACTIONS_FEEDPLAYER_fn(act)
        end
    end

    AddComponentAction("USEITEM", "edible", function(inst, doer, target, actions, right)
        if target.prefab=="shadowduelist" or helpers.isshadowworker(target.prefab) then
            for k, v in pairs(GLOBAL.FOODTYPE) do
                if inst:HasTag("edible_"..v) and target:HasTag(v.."_eater") then
                    table.insert(actions, GLOBAL.ACTIONS.FEEDPLAYER)
                end
            end
        end
    end)
    AddComponentAction("USEITEM", "inventoryitem", function(inst, doer, target, actions, right)
        if target.prefab=="shadowduelist" or helpers.isshadowworker(target.prefab) then
            for k, v in pairs(GLOBAL.FOODTYPE) do
                if inst:HasTag("edible_"..v) and target:HasTag(v.."_eater") then
                    GLOBAL.RemoveByValue(actions, GLOBAL.ACTIONS.STORE) -- the items that are edible, will not be stored in container!
                end
            end
        end
    end)
end

-- ##########################################
-- ##########################################
modimport("BM_strings")

if not (GLOBAL.TheNet:GetIsServer() or GLOBAL.TheNet:IsDedicated()) then  -- what is the difference between checking GetIsSwerver or mastersim ? basically the same, but in modmain theworld is nil, so we have to use thenet
	return
end

AddPrefabPostInit("batbat", function(inst) -- fix the sanity crash if shadow is using a batbat
    if inst.components.weapon~=nil then
        local old_onattack = inst.components.weapon.onattack
        local function new_onattack(inst, owner, target,...)
            if owner~=nil and owner.components~=nil and owner.prefab=="shadowduelist" then
                local skin_fx = GLOBAL.SKIN_FX_PREFAB[inst:GetSkinName()]
                if skin_fx ~= nil and skin_fx[1] ~= nil and target ~= nil and target.components.combat ~= nil and target:IsValid() then
                    local fx = GLOBAL.SpawnPrefab(skin_fx[1])
                    if fx ~= nil then
                        fx.entity:SetParent(target.entity)
                        fx.entity:AddFollower():FollowSymbol(target.GUID, target.components.combat.hiteffectsymbol, 0, 0, 0)
                        if fx.OnBatFXSpawned ~= nil then
                            fx:OnBatFXSpawned(inst)
                        end
                    end
                end
                if owner.components.health ~= nil and owner.components.health:GetPercent() < 1 and not (target:HasTag("wall") or target:HasTag("engineering")) then
                    owner.components.health:DoDelta(_T.BATBAT_DRAIN, false, "batbat")  -- no sanity drain for shadows
                end
            elseif old_onattack~=nil then 
                return old_onattack(inst, owner, target,...)
            end
        end
        inst.components.weapon.onattack = new_onattack
    end
end)

if _T.BM_UNLIMETED_DUR then
    AddComponentPostInit("finiteuses",function(self) -- unlimited weapons/tools
        local OldUse = self.Use
        self.Use = function(self,val,...)
            if self.inst~=nil and self.inst.components~=nil and self.inst.components.inventoryitem~=nil and 
             self.inst.components.inventoryitem.owner~=nil and (self.inst.components.inventoryitem.owner.prefab=="shadowduelist" or 
             helpers.isshadowworker(self.inst.components.inventoryitem.owner.prefab)) then
                if _T.BM_UNLIMETED_DUR==true then
                    val = 0
                else
                    val = val/_T.BM_UNLIMETED_DUR
                end
            end
            return OldUse(self,val,...)
        end
    end)
    AddComponentPostInit("armor",function(self) -- unlimited weapons/tools
        local OldTakeDamage = self.TakeDamage
        self.TakeDamage = function(self,damage_amount,...)
            if self.inst~=nil and self.inst.components~=nil and self.inst.components.inventoryitem~=nil and 
             self.inst.components.inventoryitem.owner~=nil and (self.inst.components.inventoryitem.owner.prefab=="shadowduelist" or 
             helpers.isshadowworker(self.inst.components.inventoryitem.owner.prefab)) then
                if _T.BM_UNLIMETED_DUR==true then
                    damage_amount = 0
                else
                    damage_amount = damage_amount/_T.BM_UNLIMETED_DUR
                end
            end
            return OldTakeDamage(self,damage_amount,...)
        end
    end)
end


AddPrefabPostInitAny(function(inst)
    if inst~=nil and inst.components~=nil then
        if inst.components.equippable~=nil then
            local oldonequip = inst.components.equippable.onequipfn -- add new damage to it
            inst.components.equippable.onequipfn = function(item, owner, ...)
                -- print("onequip item: "..tostring(item).." owner: "..tostring(owner))
                if item~=nil and item:IsValid() and owner~=nil and owner.components~=nil and (owner.prefab=="shadowduelist" or helpers.isshadowworker(owner.prefab)) then
                    if item:HasTag("lighter") or item:HasTag("light") then
                        item:DoTaskInTime(0.01,function(item,owner) -- at moment of equipping it has no light yet
                            if item._light~=nil then -- adjust the colour of lightsource depending on the shadow colour. will reset to deault automatically on unequip
                                local maxlevel = helpers.isshadowworker(owner.prefab) and _T.SM_MAXLEVEL_WORKER or _T.SM_MAX_LEVEL
                                if SHADOW_UPGRADE_VISUALS=="red" then
                                    item._light.Light:SetColour(1, 1-(255/maxlevel*owner.level)/255, 1-(255/maxlevel*owner.level)/255)
                                elseif SHADOW_UPGRADE_VISUALS=="green" then
                                    item._light.Light:SetColour(1-(255/maxlevel*owner.level)/255, 1, 1-(255/maxlevel*owner.level)/255)
                                elseif SHADOW_UPGRADE_VISUALS=="blue" then
                                    item._light.Light:SetColour(1-(255/maxlevel*owner.level)/255, 1-(255/maxlevel*owner.level)/255, 1)
                                elseif SHADOW_UPGRADE_VISUALS=="yellow" then
                                    item._light.Light:SetColour(1, 1, 1-(255/maxlevel*owner.level)/255)
                                elseif SHADOW_UPGRADE_VISUALS=="purple" then
                                    item._light.Light:SetColour(1, 1-(255/maxlevel*owner.level)/255, 1)
                                elseif SHADOW_UPGRADE_VISUALS=="turquoise" then
                                    item._light.Light:SetColour(1-(255/maxlevel*owner.level)/255, 1, 1)
                                end
                            else
                                if _T.BM_dodebugprints then print(tostring(item).." hat kein light") end
                            end
                        end,owner)
                    end
                    if (item.prefab=="umbrella" or item.prefab=="grass_umbrella") then
                        if not owner:HasTag("shelter") then
                            owner.addedshelter = true
                            owner:AddTag("shelter")
                        end
                    end
                    item:AddTag("nosteal")
                end
                return oldonequip(item, owner,  ...)
            end
            local oldonunequip = inst.components.equippable.onunequipfn -- add restore of damage to it
            inst.components.equippable.onunequipfn = function(item, owner, ...)
                if item~=nil and item:IsValid() and owner~=nil and owner.components~=nil and (owner.prefab=="shadowduelist" or helpers.isshadowworker(owner.prefab)) then
                    -- light is automatically removed on unquip, so no need to change it again
                    if (item.prefab=="umbrella" or item.prefab=="grass_umbrella") then
                        if owner.addedshelter==true and owner:HasTag("shelter") then
                            owner.addedshelter = nil
                            owner:RemoveTag("shelter")
                        end
                    end
                end
                item:RemoveTag("nosteal")
                return oldonunequip(item, owner,  ...)
            end
            
            if inst.components.finiteuses~=nil then -- auto equip next weapon in container , onfinished
                local oldonfinished = inst.components.finiteuses.onfinished
                inst.components.finiteuses.onfinished = function(inst1,...)
                    if inst1~=nil and inst1.components and inst1.components.inventoryitem~=nil and inst1.components.inventoryitem.owner~=nil and (inst1.components.inventoryitem.owner.prefab=="shadowduelist" or helpers.isshadowworker(inst1.components.inventoryitem.owner.prefab)) then
                        helpers.EquipNewEquip(inst1.components.inventoryitem.owner,inst1.components.equippable.equipslot)
                    end
                    if oldonfinished then
                        return oldonfinished(inst1,...)
                    end
                end
            elseif inst.components.armor~=nil then -- PushEvent("armorbroke", { armor = inst })
                -- is done via PushEvent("armorbroke", { armor = inst }) within shadows postinit
            elseif inst.components.fueled~=nil then -- within depleted fn, owner is already nil , so we use sectionfn instead
                local oldsectionfn = inst.components.fueled.sectionfn
                inst.components.fueled.sectionfn = function(newsection, oldsection, inst1, doer,...)
                    if newsection==0 and inst1~=nil and inst1.components and inst1.components.inventoryitem~=nil and inst1.components.inventoryitem.owner~=nil and (inst1.components.inventoryitem.owner.prefab=="shadowduelist" or helpers.isshadowworker(inst1.components.inventoryitem.owner.prefab)) then
                        helpers.EquipNewEquip(inst1.components.inventoryitem.owner,inst1.components.equippable.equipslot)
                    end
                    if oldsectionfn then
                        return oldsectionfn(newsection, oldsection, inst1, doer,...)
                    end
                end
            elseif inst.components.perishable~=nil then
                local oldperishfn = inst.components.perishable.perishfn
                inst.components.perishable.perishfn = function(inst1,...)
                    if inst1~=nil and inst1.components and inst1.components.inventoryitem~=nil and inst1.components.inventoryitem.owner~=nil and (inst1.components.inventoryitem.owner.prefab=="shadowduelist" or helpers.isshadowworker(inst1.components.inventoryitem.owner.prefab)) then
                        helpers.EquipNewEquip(inst1.components.inventoryitem.owner,inst1.components.equippable.equipslot)
                    end
                    if oldperishfn then
                        return oldperishfn(inst1,...)
                    end
                end
            end
        end
    end
end)


-- when max shadow number reached, give ingredients back. And if new shadow build, give him a tool
for _,prefab in ipairs({"shadowduelist","shadowdigger","shadowlumber","shadowminer"}) do  
    AddPrefabPostInit(prefab.."_builder",function(self)
        oldonbuild = self.OnBuiltFn
        self.OnBuiltFn = function(inst,builder)
            local spawn = nil
            if builder.components.petleash:IsFull() then -- if it wont work, since we have reached max amount, give back ingredients
                spawn = GLOBAL.SpawnPrefab("nightmarefuel")
                if spawn~= nil then
                    spawn.Transform:SetPosition(inst.Transform:GetWorldPosition())
                end
                spawn = GLOBAL.SpawnPrefab("nightmarefuel")
                if spawn~= nil then
                    spawn.Transform:SetPosition(inst.Transform:GetWorldPosition())
                end
            end
            return oldonbuild(inst,builder) --  does not return pet unfortunately and we do not want to overwrite it...
        end
    end)
end




local function custom_sanityfn(inst) -- sanity drain for every active shadow
	local petcount = 0
	for k, v in pairs(inst.components.petleash:GetPets()) do
		if v.prefab=="shadowduelist" or helpers.isshadowworker(v.prefab) then
			petcount = petcount + 1
		end
	end
    -- print("custom drain "..tostring(SHADOW_DRAIN * petcount))
    return SHADOW_DRAIN * petcount
end

AddPrefabPostInit("waxwell",function(inst) 
    if WAXWELL_HEALTH then
        inst.components.health:SetMaxHealth(WAXWELL_HEALTH)
    end
    if WAXWELL_SANITY_REGEN then
        inst.components.sanity.dapperness = WAXWELL_SANITY_REGEN
    end
    if WAXWELL_SANITY then
        inst.components.sanity:SetMax(WAXWELL_SANITY)
    end
    if SHADOWPUPPET_AMOUNT then
        if inst.components.petleash ~= nil then
            inst.components.petleash:SetMaxPets(inst.components.petleash:GetMaxPets() + SHADOWPUPPET_AMOUNT)
        else
            inst.components.petleash:SetMaxPets(SHADOWPUPPET_AMOUNT)
        end
    end
    
    helpers.MyListenForEventPutinFirst(inst,"ms_playerreroll",function(inst)
        for k, v in pairs(inst.components.petleash:GetPets()) do
            if v:HasTag("shadowminion") then
                v.willdespawn = true -- the despan will close container and this will trigger alot of other stuff, that might crash the game, cause pet was already removed. 
                if v.components.inventory~=nil then
                    v.components.inventory:DropEverything() -- simply drop everything in inventory (same happens when they die within regular functions)
                end
                if v.components.container~=nil then
                    v.components.container:DropEverything() -- simply drop everything in container (same happens when they die within regular functions)
                end
            end
        end
    end)
    
    olddespawn = inst.components.petleash.ondespawnfn -- info: the petleash onspawn and ondespawn functions are called for every enter/leaving the game -> so useless for releasing of shadows.
    inst.components.petleash.ondespawnfn = function(inst1,pet,...) 
        if pet.prefab=="shadowduelist" or pet.prefab=="shadowdigger" or pet.prefab=="shadowlumber" or pet.prefab=="shadowminer" or helpers.isshadowworker(pet.prefab) then
           pet.willdespawn = true -- the despan will close container and this will trigger alot of other stuff, that might crash the game, cause pet was already removed. 
        end
        return olddespawn(inst1,pet,...)
    end
    if NIGHTMAREFUEL_START > 0 then
        local item = nil
        while NIGHTMAREFUEL_START>0 do
            table.insert(inst.starting_inventory,"nightmarefuel")
            NIGHTMAREFUEL_START = NIGHTMAREFUEL_START - 1
        end
    elseif NIGHTMAREFUEL_START < 0 then
        local item = nil
        while NIGHTMAREFUEL_START<0 do
            GLOBAL.table.removearrayvalue(inst.starting_inventory,"nightmarefuel")
            NIGHTMAREFUEL_START = NIGHTMAREFUEL_START + 1
        end
    end
    if SHADOW_DRAIN then
        if inst.components.sanity.custom_rate_fn==nil then
            inst.components.sanity.custom_rate_fn = custom_sanityfn
        else
            print("Better Maxweel mod: There is alreay a custom sanity drain function, will not override it, so sanity drain from this mod is deactivated")
        end
    end
end)



--------------
--########################################
--------------- BRAIN Stuff --------------
--########################################
--------------


local function IsValidShadowTarget(inst,target,leader,action)
    -- print("IsValidShadowTarget? "..tostring(target))
    local expectedstagenames = {"small","normal","tall","old"} -- if it is not one of these, we will look for the stage number instead...
    if _T.BM_AllowedAction.never[action]~=nil and GLOBAL.table.contains(_T.BM_AllowedAction.never[action].prefabs,target.prefab) then
        return false
    end
    if _T.BM_AllowedAction.always[action]~=nil then -- if we have an always list and if the list does not contain this, then it is only allwoed if shovel equipped by maxwell 
        if not GLOBAL.table.contains(_T.BM_AllowedAction.always[action].prefabs,target.prefab) then
            local alwaystag = false
            for _,tag in ipairs(_T.BM_AllowedAction.always[action].tags) do
                if target:HasTag(tag) then
                    alwaystag = true
                end
            end
            if not alwaystag then 
                if action==GLOBAL.ACTIONS.DIG then
                    if DIGUP_SETTING=="shovel" then
                        if not helpers.Leader_Has_ActionEquipment(leader,action) then -- if it is true, move on and do next checks
                            return false
                        end
                    elseif DIGUP_SETTING=="never" then -- if always, we will return true at end of this function
                        return false
                    end
                else
                    if not helpers.Leader_Has_ActionEquipment(leader,action) then -- if it is true, move on and do next checks
                        return false
                    end
                end
            end
        end
    end
    if action==GLOBAL.ACTIONS.CHOP and (inst.prefab == "shadowlumber" or helpers.CanAllrounderDoThis(inst,action)) then
        if target.components and target.components.growable then
            local stagedata = target.components.growable:GetCurrentStageData()
            if PREFERRED_TREESTAGE then
                if GLOBAL.table.contains(expectedstagenames,stagedata.name) then -- if the name looks like we expect, look for the PREFERRED_TREESTAGE
                    if stagedata.name ~= PREFERRED_TREESTAGE then
                        return false
                    end
                elseif expectedstagenames[target.components.growable.stage] ~= PREFERRED_TREESTAGE then -- otherwise use the stage number and hope 3 is always the tall so desireed status
                    return false
                end
            end
        end
        if SaveTheTrees and target.leaf_state~=nil and target.leaf_state=="barren" then
            return false
        end
    elseif action==GLOBAL.ACTIONS.MINE and (inst.prefab == "shadowminer" or helpers.CanAllrounderDoThis(inst,action)) then
        if target.components and target.components.growable then
            local stagedata = target.components.growable:GetCurrentStageData()
            if PREFERRED_TREESTAGE then
                if GLOBAL.table.contains(expectedstagenames,stagedata.name) then -- if the name looks like we expect, look for the PREFERRED_TREESTAGE
                    if stagedata.name ~= PREFERRED_TREESTAGE then
                        return false
                    end
                elseif expectedstagenames[target.components.growable.stage] ~= PREFERRED_TREESTAGE then -- otherwise use the stage number and hope 3 is always the tall so desireed status
                    return false
                end
            end
        end
    elseif action==GLOBAL.ACTIONS.DIG and (inst.prefab == "shadowdigger" or helpers.CanAllrounderDoThis(inst,action)) then
        if target.components~=nil then
            if target.components.pickable~=nil and target.components.pickable:IsBarren() then  -- do not dig up withered/diseased/barren things
                return false
            end
            if target.components.witherable~=nil and target.components.witherable:IsWithered() then
                return false
            end
            if target.components.diseaseable~=nil and target.components.diseaseable:IsDiseased() then
                return false
            end
            if target.components.timer~=nil and target.components.timer:TimerExists("grow") then -- for just planted plants
                return false
            end
        end
    elseif action==GLOBAL.ACTIONS.PICK and helpers.CanAllrounderDoThis(inst,action) then
        if target.components and target.components.growable then
            local stagedata = target.components.growable:GetCurrentStageData()
            if PREFERRED_TREESTAGE then
                if GLOBAL.table.contains(expectedstagenames,stagedata.name) then -- if the name looks like we expect, look for the PREFERRED_TREESTAGE
                    if stagedata.name ~= PREFERRED_TREESTAGE then
                        return false
                    end
                elseif expectedstagenames[target.components.growable.stage] ~= PREFERRED_TREESTAGE then -- otherwise use the stage number and hope 3 is always the tall so desireed status
                    return false
                end
            end
        end
        local items = 1 -- start at 1 because slot 1 is occupied and reserved for tool
        for k, v in pairs(inst.components.container.slots) do
            items = items + 1
        end
        local IsFull = items >= inst.components.container.numslots
        if IsFull then -- then still check if there might be another stack we can add it to.
            if target.components.pickable.product~=nil then
                local found = helpers.Findandconsume_prefab(inst,1,target.components.pickable.product,"findstackspace")
                if not found then
                    return false -- full and no stack to add, then do not pick this 
                end
            else
                return false
            end
        end
    end
    -- print("valid target "..tostring(target))
    return true
end


local function FindEntityToWorkAction(inst, action, addtltags) -- this is our new function
    local leader = helpers.GetLeader(inst)
    local bufferedaction = nil
    local searchtags = { action.id.."_workable" }
    if action==GLOBAL.ACTIONS.PICK then
        searchtags = {"pickable"}
    end
    local nevertags = { "fire", "smolder", "event_trigger", "INLIMBO", "NOCLICK" }
    if _T.BM_AllowedAction.never[action]~=nil then
        nevertags = GLOBAL.ArrayUnion(nevertags,_T.BM_AllowedAction.never[action].tags)
    end
    -- action = GLOBAL.ACTIONS.PICK -- test
    if leader ~= nil then
        --Keep existing target?
        local target = inst.sg.statemem.target
        if target ~= nil and
            target:IsValid() and
            not (target:IsInLimbo() or
                target:HasTag("NOCLICK") or
                target:HasTag("event_trigger")) and
            ((action~=GLOBAL.ACTIONS.PICK and target.components.workable ~= nil and
            target:IsOnValidGround() and
            target.components.workable:CanBeWorked() and
            target.components.workable:GetWorkAction() == action) or (action==GLOBAL.ACTIONS.PICK and target.components.pickable~=nil and target.components.pickable:CanBePicked())) and
            not (target.components.burnable ~= nil
                and (target.components.burnable:IsBurning() or
                    target.components.burnable:IsSmoldering())) and
            target.entity:IsVisible() and
            helpers.IsNearLeader(inst,_T.BM_KEEP_WORKING_DIST,true,target) then
            local hassearchedtag = false
            if addtltags ~= nil then
                for i, v in ipairs(addtltags) do
                    if target:HasTag(v) then
                        hassearchedtag = true
                        break
                    end
                end
            else
                hassearchedtag = true
            end
            if hassearchedtag and IsValidShadowTarget(inst,target,leader,action) then
                bufferedaction = GLOBAL.BufferedAction(inst, target, action,helpers.GetMyEquippedItem(inst,GLOBAL.EQUIPSLOTS.HANDS))
                -- print("do action at old target: "..tostring(bufferedaction))
                return bufferedaction
            end
        end

        --Find new target
        local x, y, z = nil,nil,nil
        local BM_stayatposition = helpers.GetLeashPosition(inst)
        if BM_stayatposition==nil then
            x, y, z = leader.Transform:GetWorldPosition()
        else
            x, y, z = BM_stayatposition:Get()
        end
        local ents = GLOBAL.TheSim:FindEntities(x, y, z, SEE_WORK_DIST, searchtags, nevertags, addtltags) -- search for multiple targets and choose one valid one
        -- print("found "..tostring(#ents))
        for k,target in pairs(ents) do
            if target~=nil and IsValidShadowTarget(inst,target,leader,action) then
                bufferedaction = GLOBAL.BufferedAction(inst, target, action,helpers.GetMyEquippedItem(inst,GLOBAL.EQUIPSLOTS.HANDS))
                -- print("do action at new target: "..tostring(bufferedaction))
                return bufferedaction
            end
        end
        -- print("return nil")
        return nil 
    end
end

local function IsHunter(hunter,inst) -- is called for every ent in range, so only do few checks
    -- print("IsHunter "..tostring(hunter).." , "..tostring(inst))
    return not (hunter.components.health ~= nil and hunter.components.health:IsDead())
         and (hunter.components.combat ~= nil and hunter.components.combat:HasTarget())
end

local function WorkerShouldRunFn(inst,hunter) -- only run from an hunter, if he is going to attack us
    return (hunter.components.combat ~= nil and hunter.components.combat:TargetIs(inst))
end

local function DuelistShouldRunAfterFightFn(inst,hunter)
    if inst.components.shadowtoggleable~=nil and not inst.components.shadowtoggleable:IsActive() then -- if deactivated, then run away
        return (hunter.components.combat ~= nil and hunter.components.combat:TargetIs(inst))
    end
    return false
end

-- tutorial how to edit brains, see http://dontstarveapi.com/utility/modutil/ and search for AddBrainPostInit (or see this mod https://steamcommunity.com/sharedfiles/filedetails/?id=1376224676 )
AddBrainPostInit("shadowwaxwellbrain", function(brain)
    -- navigating through the nodes to find the ones we want to change
    local LeaderInRangeGroup = nil
	for i,node in ipairs(brain.bt.root.children) do
		if node.name == "Parallel" and node.children[1].name == "Leader In Range" then -- WhileNode is Parallel
			node.children[1].fn = function() return helpers.IsNearLeader(brain.inst, _T.BM_KEEP_WORKING_DIST,true) end -- replace this function to enable our new _T.BM_KEEP_WORKING_DIST
            LeaderInRangeGroup = node.children[2] -- children[2] is the priority node within
		elseif node.name == "Follow" then
            node.target = function() return helpers.GetLeader(brain.inst,true) end
        elseif node.name == "Parallel" and node.children[1].name == "Has Leader" then
            node.children[1].fn = function() return helpers.GetLeader(brain.inst,true) ~= nil end
        end
	end
    local LeashPosition = GLOBAL.Leash(brain.inst, helpers.GetLeashPosition, _T.BM_KEEP_WORKING_DIST, 1) -- same dist like IsNearLeader
    table.insert(brain.bt.root.children, LeashPosition)
	if LeaderInRangeGroup then
        if helpers.isshadowworker(brain.inst.prefab) then
            -- digpart
            local KeepDiggingsequence = nil
            local KeepChoppingsequence = nil
            local KeepMinigsequence = nil
            -- local KeepPickingsequence = nil
            for i,node in ipairs(LeaderInRangeGroup.children) do
                if node.name == "Sequence" and node.children[1].name == "Keep Digging" then -- IfNode is Sequence
                    KeepDiggingsequence = node
                    node.children[1].fn = function() return helpers.CanAllrounderDoThis(brain.inst,GLOBAL.ACTIONS.DIG) end
                elseif node.name == "Sequence" and node.children[1].name == "Keep Chopping" then
                    KeepChoppingsequence = node
                    node.children[1].fn = function() return helpers.CanAllrounderDoThis(brain.inst,GLOBAL.ACTIONS.CHOP) end
                elseif node.name == "Sequence" and node.children[1].name == "Keep Mining" then
                    KeepMinigsequence = node
                    node.children[1].fn = function() return helpers.CanAllrounderDoThis(brain.inst,GLOBAL.ACTIONS.MINE) end
                -- elseif node.name == "Sequence" and node.children[1].name == "Keep Picking" then
                    -- KeepPickingsequence = node
                    -- node.children[1].fn = function() return helpers.CanAllrounderDoThis(brain.inst,GLOBAL.ACTIONS.PICK) end
                elseif node.name == "RunAway" and GLOBAL.table.contains(node.hunteroneoftags,"monster") then -- find the runaway of monsters node
                    node.hunterfn = IsHunter
                    node.hunteroneoftags = { "_combat", "_health" } -- search for everything with combat component, instead of monster/hostile
                    node.shouldrunfn = function(hunter) return WorkerShouldRunFn(brain.inst, hunter) end
                end
            end
            local DiggingAction = nil
            if KeepDiggingsequence then
                for i,node in ipairs(KeepDiggingsequence.children) do
                    if node.name == "DoAction" then
                        DiggingAction = node
                        break
                    end
                end
            end
            -- chop part
            local ChoppingAction = nil
            if KeepChoppingsequence then
                for i,node in ipairs(KeepChoppingsequence.children) do
                    if node.name == "DoAction" then
                        ChoppingAction = node
                        break
                    end
                end
            end
            -- mine part
            local MiningAction = nil
            if KeepMinigsequence then
                for i,node in ipairs(KeepMinigsequence.children) do
                    if node.name == "DoAction" then
                        MiningAction = node
                        break
                    end
                end
            end
            if DiggingAction then
                DiggingAction.getactionfn = function() return FindEntityToWorkAction(brain.inst, GLOBAL.ACTIONS.DIG) end -- replace the old function with our new one
            end
            if ChoppingAction then
                ChoppingAction.getactionfn = function() return FindEntityToWorkAction(brain.inst, GLOBAL.ACTIONS.CHOP) end
            end
            if MiningAction then
                MiningAction.getactionfn = function() return FindEntityToWorkAction(brain.inst, GLOBAL.ACTIONS.MINE) end -- to use the tool
            end
            -- add our pick action
            local KeepPickingsequence = GLOBAL.IfNode(function() return helpers.CanAllrounderDoThis(brain.inst,GLOBAL.ACTIONS.PICK) end, "Keep Picking",
            GLOBAL.DoAction(brain.inst, function() return FindEntityToWorkAction(brain.inst, GLOBAL.ACTIONS.PICK) end))
            table.insert(LeaderInRangeGroup.children, KeepPickingsequence)
        end
        if brain.inst.prefab=="shadowduelist" then
            -- kiting/tank
            local IsDuelistsequence = nil
            local monsterrunawayindex = nil
            for i,node in ipairs(LeaderInRangeGroup.children) do
                if node.name == "Sequence" and node.children[1].name == "Is Duelist" then -- IfNode is Sequence
                    node.children[1].fn = function() return brain.inst.prefab == "shadowduelist" and brain.inst.components.shadowtoggleable~=nil and brain.inst.components.shadowtoggleable:IsActive() end
                    IsDuelistsequence = node.children[2] -- get the priority node
                elseif node.name == "RunAway" and GLOBAL.table.contains(node.hunteroneoftags,"monster") then -- find the runaway of monsters node and remove it for duelist
                    monsterrunawayindex = i
                    node.hunterfn = IsHunter
                    node.hunteroneoftags = { "_combat", "_health" } -- search for everything with combat component, instead of monster/hostile
                    node.shouldrunfn = function(hunter) return DuelistShouldRunAfterFightFn(brain.inst, hunter) end
                end
            end
            local IsDuelistRunaway = nil -- kiting
            local IsDuelistDodge = nil
            if IsDuelistsequence then
                for i,node in ipairs(IsDuelistsequence.children) do
                    if node.name=="Parallel" and node.children[1].name=="Dodge" then
                        IsDuelistDodge = node
                        break
                    end
                end
                if IsDuelistDodge then
                    for i,node in ipairs(IsDuelistDodge.children) do
                        if node.name == "RunAway" then
                            IsDuelistRunaway = node
                            break
                        end
                    end
                    IsDuelistDodge.children[1].fn = function() return brain.inst.components.combat:GetCooldown() > .5 and helpers.ShouldKite(brain.inst.components.combat.target, brain.inst) end 
                    if IsDuelistRunaway then
                        IsDuelistRunaway.hunterfn = helpers.ShouldKite
                        IsDuelistRunaway.safe_dist = _T.BM_STOP_KITING_DIST -- 5
                        IsDuelistRunaway.see_dist = KITING_DIST -- 3
                    end
                end
            end
            -- if monsterrunawayindex~= nil then -- dont remove it, we need it if shadow is toggled off with shadowtoggleable
                -- table.remove(LeaderInRangeGroup.children,monsterrunawayindex) -- remove runaway for duelist (cause this happens after every monster kill and sucks)
            -- end
        end
    end
end)



