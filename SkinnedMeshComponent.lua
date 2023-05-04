local SkinnedMeshComponent = _G.gclass("SkinnedMeshComponent", _G.Component)

function SkinnedMeshComponent:onAwake()
    SkinnedMeshComponent.__csuper.onAwake(self)
    self.obj = nil
    self.animator = nil
    self.isFreeze = nil
    self.lastAnimationInfo = {}
    self:on("onLoadPrefab", handler(self, "onLoadPrefab"))
    self:on("onGetPrefab", handler(self, "onGetPrefab"))
    self:on("onGetAnima", handler(self, "onGetAnima"))
    self:on("onPlayAnima", handler(self, "onPlayAnima"))
    self:on("onPlayResetTrigger", handler(self, "onPlayResetTrigger"))
    self:on("onSetAnimatorSpeed", handler(self, "onSetAnimatorSpeed"))
    self:on("onGetAnimatorSpeed", handler(self, "onGetAnimatorSpeed"))
    self:on("onGetCurPlayAnimatorIsLoop", handler(self, "onGetCurPlayAnimatorIsLoop"))
    self:on("onGetCurPlayAnimationOriLength", handler(self, "onGetCurPlayAnimationOriLength"))
    self:on("onPlayAnimaByStatus", handler(self, "onPlayAnimaByStatus"))
    self:on("onSetLayer", handler(self, "onSetLayer"))
    self:on("forceIdle", handler(self, "forceIdle"))
    self:on("SetFreeze", handler(self, "onSetFreeze"))
    self:on("setVisible", handler(self, "setVisible"))
    self:on("checkInFreeze", handler(self, "checkInFreeze"))
    self:on("setAnimatorFloatParam", handler(self, "setAnimatorFloatParam"))
    self:on("addAnimatorExitEventCallBack", handler(self, "addAnimatorExitEventCallBack"))
    self:on("addAnimatorEnterEventCallBack", handler(self, "addAnimatorEnterEventCallBack"))
    self:on("setLocalScale", handler(self, "setLocalScale"))
end

function SkinnedMeshComponent:onLoadPrefab(data)
    if self.obj then
        GameObject.Destroy(self.obj)
    end
    self.obj = CSPrefabLoader.LoadAndInstantiatePrefab(data.assetbundleName, data.assetName)
    self.layer = self.obj.layer
    self.animator = CSAnimatorEventManager.GetAnimator(self.obj)
    if data.acAssetBundleName and data.acAssetName then
        CSAnimatorEventManager.SetRuntimeAnimatorController(self.animator, data.acAssetBundleName, data.acAssetName)
    end
    self:event("onSetTransform", self.obj.transform)
    self:event("onAddPrefab", self.obj)
end

function SkinnedMeshComponent:onSetLayer(layer)
    self.layer = layer
    if self.obj.layer ~=  _G.UnityLayers.Hidden then
        CSLuaStaticFunctions.SetGameObjectLayer(self.obj, layer)
    end
end

function SkinnedMeshComponent:setVisible(flg)
    if flg then
        CSLuaStaticFunctions.SetGameObjectLayer(self.obj, self.layer)
    else
        CSLuaStaticFunctions.SetGameObjectLayer(self.obj, _G.UnityLayers.Hidden)
    end
    self:eventDown("setVisible", flg)
end

function SkinnedMeshComponent:onGetPrefab()
    return self.obj
end

function SkinnedMeshComponent:onGetAnima()
    return self.animator
end

function SkinnedMeshComponent:onPlayAnima(data)
    if not data then
        return
    end
    local name, value, durtime, starttime = data.name, data.value, data.durtime, data.starttime -- dur/start 小数
    if durtime then
        CSAnimatorEventManager.PlayCrossFade(self.animator, name, durtime, data.layer or 0, data.offset or 0, starttime)
    else
        local lastAnimationValue = self.lastAnimationInfo.value
        if type(value) == "boolean" and not lastAnimationValue then
            lastAnimationValue = false
        end
        CSAnimatorEventManager.PlayParameter(self.animator, name, value, self.lastAnimationInfo.name, lastAnimationValue)
        self.lastAnimationInfo.name = name
        self.lastAnimationInfo.value = value
        if type(value) == "boolean" then
            if value then
                self.lastAnimationInfo.value = true
            else
                self.lastAnimationInfo.value = false
            end
        end

        -- else
        -- CSAnimatorEventManager.Play(self.animator, name)
    end
end
--- 这只状态机中的某个状态中的参数值
---@param data table 设置的参数值
function SkinnedMeshComponent:setAnimatorFloatParam(data)
    if not data then
        return
    end
    if not data.name or not data.value then
        return
    end
    CSAnimatorEventManager.PlayParameterFloat(self.animator, data.name, data.value)
end

function SkinnedMeshComponent:onPlayAnimaByStatus(data)
end

function SkinnedMeshComponent:onPlayResetTrigger(data)
    CSAnimatorEventManager.PlayResetTrigger(self.animator, data.name, data.lastanima)
end

function SkinnedMeshComponent:onSetAnimatorSpeed(speed) --在这里更改优先级，读表储存
    if self.isFreeze then
        return
    end
    self:setAnimatorSpeed(speed)
end
function SkinnedMeshComponent:setAnimatorSpeed(speed)
    if not self.animator then
        return
    end
    CSAnimatorEventManager.SetAniamtorSpeed(self.animator, speed or 0)
end

function SkinnedMeshComponent:onGetAnimatorSpeed()
    local speed = CSAnimatorEventManager.GetAnimatorSpeed(self.animator)
    return speed
end

function SkinnedMeshComponent:onGetCurPlayAnimatorIsLoop()
    local isLoop = CSAnimatorEventManager.GetCurPlayAnimatorIsLoop(self.animator)
    return isLoop
end

function SkinnedMeshComponent:onGetCurPlayAnimationOriLength() --cs端获取的数据是秒，这边将其转化成毫秒
    local oriAniLength = CSAnimatorEventManager.GetCurPlayAnimationOriLength(self.animator) * 1000
    return oriAniLength
end

function SkinnedMeshComponent:forceIdle()
    CSAnimatorEventManager.Play(self.animator, "IdleWorld")
end

function SkinnedMeshComponent:onDestroy()
    SkinnedMeshComponent.__csuper.onDestroy(self)
    if self.obj then
        GameObject.Destroy(self.obj)
        self.obj = nil
        self.animator = nil
    end
end

function SkinnedMeshComponent:onSetFreeze(value)
    if value == self.isFreeze then
        return
    end
    local speed = 0
    if value then
        -- 记录一下暂停时的播放速度
        self.stopSpeed = self:event("onGetAnimatorSpeed")
    else
        if self.stopSpeed and self.stopSpeed > 0 then
            speed = self.stopSpeed
        else
            speed = 1
        end
    end
    --self:event("onSetAnimatorSpeed", value and 0 or 1)
    self.isFreeze = value
    self:setAnimatorSpeed(speed)
end
function SkinnedMeshComponent:checkInFreeze()
    return self.isFreeze
end

function SkinnedMeshComponent:addAnimatorExitEventCallBack(callback)
    CSAnimatorEventManager.AddAnimatorExitEventCallBack(self.animator, callback)
end

function SkinnedMeshComponent:addAnimatorEnterEventCallBack(callback)
    CSAnimatorEventManager.AddAnimatorEnterEventCallBack(self.animator, callback)
end

function SkinnedMeshComponent:setLocalScale(scale)
    CSTransformStaticFunctions.SetLocalScale(self.obj, scale, scale, scale)
end