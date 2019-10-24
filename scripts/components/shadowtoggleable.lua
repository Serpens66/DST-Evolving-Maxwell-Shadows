local Shadowtoggleable = Class(function(self, inst)
    self.inst = inst
	self.inst:AddTag("_shadowtoggleable")
    self.inst:AddTag("shadowtoggle_active")
end,
nil,
{
})

function Shadowtoggleable:OnSave()
	return { active = self.inst:HasTag("shadowtoggle_active"),
            BM_stayatposition = self.inst.BM_stayatposition, -- save this here, although it does not really belong here
            BM_stayworldprefab = TheWorld.prefab,
            BM_staywalkableplattform = self.inst.BM_staywalkableplattform~=nil and self.inst.BM_staywalkableplattform:IsValid() and self.inst.BM_staywalkableplattform.GUID or nil,
          }
end

function Shadowtoggleable:LoadPostPass(newents, savedata)
    if savedata ~= nil and savedata.BM_staywalkableplattform ~= nil then
        local targ = newents[savedata.BM_staywalkableplattform]
        if targ ~= nil and targ.IsValid() and targ.components~=nil and targ.components.walkableplattoform~=nil then
            self.inst.BM_staywalkableplattform = targ
        end
    end
end

function Shadowtoggleable:OnLoad(data)
	if data~=nil then
        if data.active==false then self.inst:RemoveTag("shadowtoggle_active") end
        self.inst:DoTaskInTime(0, function()
            if data.active==false then self.inst:RemoveTag("shadowtoggle_active") end
        end)
        if data.BM_stayworldprefab == TheWorld.prefab then
            self.inst.BM_stayatposition = data.BM_stayatposition~=nil and Point(data.BM_stayatposition.x,data.BM_stayatposition.y,data.BM_stayatposition.z) or nil
        else
            self.inst.BM_stayatposition = nil
            self.inst.BM_staywalkableplattform = nil
        end
    end
end

function Shadowtoggleable:OnRemoveFromEntity()
    self.inst:RemoveTag("_shadowtoggleable")
    self.inst:RemoveTag("shadowtoggle_active")
end

function Shadowtoggleable:ToggleActive()
    if self.inst:HasTag("shadowtoggle_active") then
		self.inst:RemoveTag("shadowtoggle_active")
		self.inst.components.locomotor:Stop()
		if self.inst.components.combat~=nil then self.inst.components.combat:DropTarget(true) end
        self.inst.brain.bt:Reset() -- otherwise it might get stuck
	else
		self.inst:AddTag("shadowtoggle_active")
        self.inst.brain.bt:Reset() -- otherwise it might get stuck
	end
end

function Shadowtoggleable:IsActive()
    return self.inst:HasTag("shadowtoggle_active")
end

return Shadowtoggleable