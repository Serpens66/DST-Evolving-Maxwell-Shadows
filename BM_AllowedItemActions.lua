-- ######################################################################################
-- ###  for customization
-- ###  dont forget to backup this file also outside of the mod folder
-- ###  because every mod-update will resett this file!
-- ######################################################################################
_T = GLOBAL.TUNING

-- for dig and pick, everthing that is not within the never/always list, will only be target if both, maxwell and shadow have the tool equipped.
_T.BM_AllowedAction = {
    never = {
        [GLOBAL.ACTIONS.MINE] = {prefabs={"cave_entrance"},tags={}},
        [GLOBAL.ACTIONS.CHOP] = {prefabs={},tags={}},
        [GLOBAL.ACTIONS.DIG] = {prefabs={"rabbithole"},tags={"mushroom","sign"}}, -- never ever dig these up. Barren/Withered/Diseased or just planted things are already excluded in modcode
        [GLOBAL.ACTIONS.PICK] = {prefabs={"mandrake_planted","atrium_gate","moonbase","sculptingtable","statueglommer","telebase_gemsocket"},tags={"flower"}},   
    },
    always = { -- everything chopable/mineable is automatically in this list (so will be always worked on if the shadow has the equipment, at least as long here is no entry for these actions)
        [GLOBAL.ACTIONS.DIG] = {prefabs={"molehill"},tags={"stump","grave"}}, -- always dig these if shadow has a shovel.  Everything else which is not in this or NoDig list, will be dig up if also maxwell has a shovel
        [GLOBAL.ACTIONS.PICK] = {prefabs={"sapling","sapling_moon","grass","reeds","tumbleweed","bullkelp_plant","rock_avocado_bush","tallbirdnest"},tags={}}, -- everything which product can spoil is not in this list
    }
}


 -- some specific items that are not hardcoded (like tools+pickables for worker and weapon/armor for duelist)
_T.BM_AllowedItemsInContainer = {
    workerequip = {prefabs={"grass_umbrella","umbrella"},tags={"light","lighter"}}, -- allowed in container and will be equipped
    duelistequip = {prefabs={},tags={}},
    workerNoequip = {prefabs={"nightmarefuel"},tags={}}, -- allowed in contaier, but wont be equipped
    duelistNoequip = {prefabs={"nightmarefuel"},tags={}},
}


_T.SHADOWWAXWELL_DAMAGE = 20 -- duelist damage without any weapon
