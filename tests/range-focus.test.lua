-- Execute the real AddSlider implementation with a small Roblox UI/input mock.
local f = assert(io.open('KiraUI.lua', 'r'))
local source = f:read('*a'); f:close()
local slider = assert(source:match('(function section:AddSlider%(options%).-)\n            function section:AddInput'))
local function signal()
    local s = {listeners = {}}
    function s:Connect(fn) table.insert(self.listeners, fn); return {Disconnect=function() end} end
    function s:Fire(...) for _, fn in ipairs(self.listeners) do fn(...) end end
    return s
end
local function node(class, props, parent)
    local data = {ClassName=class, children={}, AbsolutePosition={X=100,Y=200}, AbsoluteSize={X=400,Y=6}, Enabled=true}
    local object = setmetatable({}, {__index=data})
    getmetatable(object).__newindex=function(_,k,v)
        data[k]=v
        if k=='Parent' and v then table.insert(v.children, object) end
    end
    data.InputBegan=signal(); data.Destroying=signal()
    function data:GetChildren() return self.children end
    function data:IsA(kind) return kind=='GuiObject' and (class=='Frame' or class=='TextButton' or class=='TextLabel') or kind==class end
    function data:Destroy() self.Destroying:Fire(); self.destroyed=true end
    function data:Clone()
        local c=node(class)
        for k,v in pairs(data) do
            if type(v)~='function' and k~='children' and k~='Parent' and k~='InputBegan' and k~='Destroying' then c[k]=v end
        end
        for _, child in ipairs(self.children) do child:Clone().Parent=c end
        return c
    end
    for k,v in pairs(props or {}) do object[k]=v end
    object.Parent=parent
    return object
end
local env=setmetatable({}, {__index=_G})
env.section={}; env.gui=node('ScreenGui',{DisplayOrder=10},node('Folder'))
env.window={}
function env.window:_connect(s,fn) return s:Connect(fn) end
function env.window:_maybeRegisterConfig(o) return o end
local input={InputChanged=signal(),InputEnded=signal(),WindowFocusReleased=signal()}
env.UserInputService=input
local lastRow
env.controlFrame=function() lastRow=node('Frame'); return lastRow end
env.new=node; env.corner=function() end; env.stroke=function() end
env.attachVisibility=function() end
env.clamp=function(x,a,b) return math.max(a,math.min(b,x)) end
env.roundToStep=function(x,a,step) return a+math.floor((x-a)/step+0.5)*step end
env.safeCall=function(fn,...) if fn then fn(...) end end
env.formatNumber=function(x) return string.format('%.2f',x) end
env.makeValueObject=function(value,cb) return {Value=value,_emit=function(_,v) if cb then cb(v) end end} end
env.theme={}; env.Enum={Font={GothamMedium=1},TextXAlignment={Left=1},TextTruncate={AtEnd=1},ZIndexBehavior={Sibling=1},UserInputType={MouseButton1='mouse',MouseMovement='move',Touch='touch'}}
env.Vector2={new=function(x,y) return {X=x,Y=y} end,zero={X=0,Y=0}}
env.UDim2={new=function(...) return {...} end,fromOffset=function(...) return {...} end,fromScale=function(...) return {...} end}
assert(load(slider,'AddSlider','t',env))()
local starts,ends,changes=0,0,0
local obj=env.section:AddSlider({Min=0,Max=100,Step=0.01,RangeFocus=true,
 OnDragStarted=function() starts=starts+1 end,OnDragEnded=function() ends=ends+1 end,
 Callback=function() changes=changes+1 end})
lastRow.BackgroundTransparency=0.2
lastRow.TextTransparency=0
lastRow.Visible=true
local originalRow=lastRow
local hit=lastRow.children[3]
local mouse={UserInputType='mouse',Position={X=180}}
hit.InputBegan:Fire(mouse)
assert(not env.gui.Enabled and obj.Value==20 and starts==1)
local overlay=env.gui.Parent.children[2]
for x=200,420,20 do input.InputChanged:Fire({UserInputType='move',Position={X=x}}) end
assert(obj.Value==80 and starts==1 and ends==0 and not overlay.destroyed)
assert(overlay.children[2].Text=='80.00', 'focused numeric value updates during drag')
input.InputEnded:Fire({UserInputType='touch'})
assert(not env.gui.Enabled, 'unrelated touch cannot release mouse')
input.InputEnded:Fire(mouse)
assert(env.gui.Enabled and ends==1 and overlay.destroyed)
assert(originalRow.BackgroundTransparency==0.2 and originalRow.TextTransparency==0 and originalRow.Visible==true)
input.InputEnded:Fire(mouse); assert(ends==1)
local touch={UserInputType='touch',Position={X=240}}
hit.InputBegan:Fire(touch)
input.InputChanged:Fire({UserInputType='touch',Position={X=500}})
assert(obj.Value==35, 'second finger ignored')
touch.Position.X=300; input.InputChanged:Fire(touch); assert(obj.Value==50)
input.InputEnded:Fire(touch); assert(env.gui.Enabled and ends==2)
hit.InputBegan:Fire(mouse); input.WindowFocusReleased:Fire(); assert(env.gui.Enabled and ends==3)
hit.InputBegan:Fire(mouse); lastRow:Destroy(); assert(env.gui.Enabled and ends==4)
env.gui.Enabled=false; hit.InputBegan:Fire(mouse); input.InputEnded:Fire(mouse)
assert(env.gui.Enabled==false, 'restore exact Enabled snapshot')
env.gui.Enabled=true
local normal=env.section:AddSlider({Min=0,Max=100})
lastRow.children[3].InputBegan:Fire(mouse); assert(env.gui.Enabled, 'opt-in only')
input.InputEnded:Fire(mouse)
assert(changes>5)
print('PASS: realtime value, single focus entry/exit, mouse/touch ownership, cancel, destruction, exact restore, opt-in')
