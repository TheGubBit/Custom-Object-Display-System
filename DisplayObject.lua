--[[
DisplayObject.lua by TheGreenBit
Uploaded to Github 18/02/2026

Example script requires this module from a specific location.
ReplicatedStorage -> Modules -> DisplayObject
]]

--[[ Types ]]
type TransparencyClass = Part|WedgePart|MeshPart|TrussPart|Decal|Texture
type VisibleClass = SurfaceGui
type ReplicationClass = TransparencyClass|VisibleClass|Accessory|Humanoid|BodyColors|SpecialMesh|Shirt|Pants
type DrawClass = Part|WedgePart|MeshPart|TrussPart

type ObjectInfo = {
	Base : ReplicationClass?,
	Replica : ReplicationClass
}

type Screen = {
	SurfaceGui : SurfaceGui,
	DisplayPart : BasePart,
	Viewport : ViewportFrame
}

type DisplayObject = {
	DisplayObjectFolder : Folder,
	Camera : Camera,
	Screen : Screen,
	BaseObject : BasePart,
	OnDestroy : () -> nil
}

--[[ Services ]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--[[ Objects ]]
local Storage = ReplicatedStorage:WaitForChild("Storage")

local Camera = workspace.CurrentCamera

--[[ Information ]]
local TRANSPARENCY_CLASS = {
	["Part"] = true,
	["WedgePart"] = true,
	["MeshPart"] = true,
	["TrussPart"] = true,
	["Decal"] = true,
	["Texture"] = true
}

local VISIBLE_CLASS = {
	["SurfaceGui"] = true
}

local REPLICATION_CLASS = {
	["Part"] = true,
	["Model"] = true,
	["Folder"] = true,
	["WedgePart"] = true,
	["MeshPart"] = true,
	["TrussPart"] = true,
	["Decal"] = true,
	["Texture"] = true,
	["SurfaceGui"] = true,
	["Accessory"] = true,
	["Humanoid"] = true,
	["BodyColors"] = true,
	["SpecialMesh"] = true,
	["Shirt"] = true,
	["Pants"] = true
}

local DRAW_CLASS = {
	["Part"] = true,
	["WedgePart"] = true,
	["MeshPart"] = true,
	["TrussPart"] = true
}

local DisplayObject = {}
DisplayObject.__index = DisplayObject

--[[ Functions ]]
function DisplayObject:GetCamera():Camera
	if self.Camera then return self.Camera end
	
	local Camera = Instance.new("Camera", workspace)
	Camera.Name = "ObjectRenderCamera"
	Camera.Focus = CFrame.new()
	Camera.CFrame = CFrame.new(0,0,-200) * CFrame.Angles(0,math.rad(180),0)
	Camera.FieldOfView = 4.4
	Camera.FieldOfViewMode = Enum.FieldOfViewMode.Vertical
	
	rawset(DisplayObject, "Camera", Camera)
	return Camera
end

function DisplayObject:GetDisplayObjectStorageFolder():Folder
	if self.DisplayObjectStorage then return self.DisplayObjectStorage end
	
	self.DisplayObjectStorage = Storage:FindFirstChild("DisplayObjectStorage")
	if not self.DisplayObjectStorage then
		self.DisplayObjectStorage = Instance.new("Folder", Storage)
		self.DisplayObjectStorage.Name = "DisplayObjectStorage"
	end
	
	if self.DisplayObjectStorage then
		rawset(DisplayObject, "DisplayObjectStorage", self.DisplayObjectStorage)
	end
	
	return self.DisplayObjectStorage
end

function DisplayObject:GetDisplayObjectFolder():Folder
	if self.DisplayObjectFolder then return self.DisplayObjectFolder end
	
	self.DisplayObjectFolder = workspace:FindFirstChild("DisplayObject")
	if not self.DisplayObjectFolder then
		self.DisplayObjectFolder = Instance.new("Folder", workspace)
		self.DisplayObjectFolder.Name = "DisplayObject"
	end
	
	if self.DisplayObjectFolder then
		rawset(DisplayObject, "DisplayObjectFolder", self.DisplayObjectFolder)
	end
	
	return self.DisplayObjectFolder
end

function DisplayObject:CreateSurfaceGui(Parent:Instance):SurfaceGui
	local SurfaceGui:SurfaceGui = Instance.new("SurfaceGui", Parent)
	SurfaceGui.Name = self.BaseObject.Name
	SurfaceGui.Face	= Enum.NormalId.Front
	SurfaceGui.LightInfluence = 0
	SurfaceGui.Brightness = 1
	SurfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	SurfaceGui.PixelsPerStud = 50
	SurfaceGui.ZOffset = 1
	
	return SurfaceGui
end

function DisplayObject:CreateViewport(Parent:Instance):ViewportFrame
	local Viewport = Instance.new("ViewportFrame", Parent)
	Viewport.BackgroundTransparency = 1
	Viewport.Size = UDim2.fromScale(1, 1)
	Viewport.CurrentCamera = self.Camera
	Viewport.BackgroundColor3 = Color3.new()
	
	return Viewport
end

function DisplayObject:CreateDisplayPart():BasePart
	local DisplayPart = Instance.new("Part", self.DisplayObjectFolder)
	DisplayPart.Name = self.BaseObject.Name
	DisplayPart.Anchored = true
	DisplayPart.CastShadow = false
	DisplayPart.CanCollide = false
	DisplayPart.CanQuery = false
	DisplayPart.Transparency = 1
	DisplayPart.Size = Vector3.new(15, 15, 0.001)
	
	return DisplayPart
end

function DisplayObject:GetScreen(Parent:Instance):{SurfaceGui:SurfaceGui, Viewport:ViewportFrame, DisplayPart:BasePart}
	if not self.SurfaceGui then self.SurfaceGui = self:CreateSurfaceGui(Parent) end
	if not self.Viewport then self.Viewport = self:CreateViewport(self.SurfaceGui) end
	if not self.DisplayPart then self.DisplayPart = self:CreateDisplayPart() end
	
	self.SurfaceGui.Adornee = self.DisplayPart
	
	return {
		SurfaceGui = self.SurfaceGui,
		Viewport = self.Viewport,
		DisplayPart = self.DisplayPart
	}
end

function DisplayObject:CanReplicate(Object:Instance):boolean
	if not (Object and REPLICATION_CLASS[Object.ClassName]) then return false end
	
	return true
end

function DisplayObject:Replicate(Object:Instance, Parent:Instance, Hide:boolean, IncludeChildren:boolean):ReplicationClass
	if not self.Objects then self.Objects = {} end
	
	if Hide == nil then Hide = true end
	if IncludeChildren == nil then IncludeChildren = true end
	
	if not self:CanReplicate(Object) then
		return
	end
	
	if not self.Objects[Object] then
		self.Objects[Object] = {}
	end
	
	local ObjectTable = self.Objects[Object]
	if not ObjectTable.Base then ObjectTable.Base = Object end
		
	if not ObjectTable.Replica then
		local Replica = Object:Clone()
		Replica.Parent = Parent
		
		ObjectTable.Replica = Replica
	end
	
	local OriginalTransparency = Object:GetAttribute("OriginalTransparency")

	if OriginalTransparency then
		ObjectTable.Replica.Transparency = OriginalTransparency
	end

	if ObjectTable.Replica:IsA("BasePart") or ObjectTable.Replica:IsA("Model") then
		ObjectTable.Replica:PivotTo(CFrame.new())
	end

	if VISIBLE_CLASS[Object.ClassName] then
		ObjectTable.Replica.Visible = true
	end

	local Children = ObjectTable.Replica:GetChildren()
	if #Children > 0 then
		for _, Child:Instance in ipairs(Children) do
			Child:Destroy()
		end

		if IncludeChildren then
			for _, Child:Instance in ipairs(Object:GetChildren()) do
				self:Replicate(Child, ObjectTable.Replica, Hide, IncludeChildren)
			end
		end
	end
	
	if not ObjectTable.Parent then
		ObjectTable.Parent = Parent
	end
	
	if not ObjectTable.Offset then
		ObjectTable.Offset = CFrame.new()
	end
	
	if ObjectTable.Base:IsA("BasePart") then
		ObjectTable.Offset = ObjectTable.Offset * ObjectTable.Base.PivotOffset:Inverse()
	end
	
	if ObjectTable.Replica:IsA("BasePart") then
		ObjectTable.Offset = ObjectTable.Offset * ObjectTable.Replica.PivotOffset
	end
	
	if Hide then
		if TRANSPARENCY_CLASS[Object.ClassName] then
			if not Object:GetAttribute("OriginalTransparency") then
				Object:SetAttribute("OriginalTransparency", Object.Transparency)
			end
			Object.Transparency = 1
		end
		
		if VISIBLE_CLASS[Object.ClassName] then
			Object.Visible = false
		end
	end
	
	return ObjectTable
end

function DisplayObject:AddAccessoryObject(Object:Instance, Parent:Instance, Offset:CFrame)
	self:AddToDrawList({
		Base = Parent,
		Replica = Object,
		Offset = Offset
	})
end

function DisplayObject:AddToDrawList(ObjectInfo:ObjectInfo)
	if not ObjectInfo then return end
	
	if not self.DrawList then self.DrawList = {} end

	if ObjectInfo.Base and ObjectInfo.Replica and DRAW_CLASS[ObjectInfo.Base.ClassName] then
		if not table.find(self.DrawList, DisplayObject) then
			table.insert(self.DrawList, ObjectInfo)
		end
	end
end

function DisplayObject:UpdateDrawList()
	assert(self.Objects, "[!] Objects list does not exist!")
	
	if not self.DrawList then self.DrawList = {} end
	
	for _, ObjectInfo:ObjectInfo in pairs(self.Objects) do
		if ObjectInfo.Replica == self.BaseReplica then continue end
		self:AddToDrawList(ObjectInfo)
	end
end

function DisplayObject:Destroy()
	if self.OnDestroy then
		self.OnDestroy()
	end
	
	if self.DisplayPart then self.DisplayPart.Parent = nil end
	if self.SurfaceGui then self.SurfaceGui.Parent = nil end
	
	for _, ObjectInfo:ObjectInfo in pairs(self.Objects) do
		if ObjectInfo.Replica then
			ObjectInfo.Replica:Destroy()
		end
	end
	
	self.Objects = {}
end

function DisplayObject:RoundRotation(X:number, Y:number, Z:number)
	local RadianSnapPoint = self.SnapPoints / (math.pi * 2)
	
	return math.round(X * RadianSnapPoint) / RadianSnapPoint, math.round(Y * RadianSnapPoint) / RadianSnapPoint, math.round(Z * RadianSnapPoint) / RadianSnapPoint
end

function DisplayObject:SnapRotation(X:number, Y:number, Z:number)
	local RadianSnapPoint = self.SnapPoints / (math.pi * 2)

	return X % RadianSnapPoint, Y % RadianSnapPoint, Z % RadianSnapPoint
end

function DisplayObject:UpdateTransparency()
	for _, ObjectInfo in pairs(self.Objects) do
		if TRANSPARENCY_CLASS[ObjectInfo.Base.ClassName] then
			ObjectInfo.Base.Transparency = 1
		end

		if VISIBLE_CLASS[ObjectInfo.Base.ClassName] then
			ObjectInfo.Base.Visible = false
		end
	end
end

function DisplayObject:SetOcclusion(State:boolean)
	if self.Occluded ~= State then
		self.Occluded = State
		if self.SurfaceGui then
			self.SurfaceGui.Enabled = not State
		end
		
		self:UpdateTransparency()
	end
end

function DisplayObject:UpdateScreen()
	if not self.BaseObject then return end
	
	if not self.DisplayPart then return end
	
	if self.Viewport then
		self.Viewport.ImageTransparency = self.Transparency
	end
	
	if self.Transparency >= 1 then return end
	
	local Position = self.BaseObject:GetPivot().Position
	
	local Direction = Position - Camera.CFrame.Position
	
	if Direction.Magnitude > self.RenderDistance then
		self:SetOcclusion(true)
		return
	end
	
	if Camera.CFrame.LookVector:Dot(Direction.Unit) < math.cos(math.rad(Camera.FieldOfView)) then
		self:SetOcclusion(true)
		return
	end

	self:SetOcclusion(false)
	
	self.DisplayPart.CFrame = CFrame.lookAt(Position, Camera.CFrame.Position * Vector3.new(1, 0, 1) + Vector3.new(0, Position.Y, 0))
end

function DisplayObject:UpdateObjects(UpdateTransparency:boolean)
	if self.Transparency >= 1 then return end
	
	if self.Occluded then return end
	
	if not self.DrawList then return end
	
	local DisplayPartPivot:CFrame = self.DisplayPart:GetPivot()
	
	local BasePartPivot:CFrame = self.BaseObjectInfo.Base:GetPivot() * self.BaseObjectInfo.Offset
	local BaseOrigin:CFrame = CFrame.new(DisplayPartPivot.Position) * BasePartPivot.Rotation * CFrame.Angles(self:RoundRotation(BasePartPivot:ToEulerAnglesXYZ())):Inverse() * CFrame.Angles(self:RoundRotation(DisplayPartPivot:ToEulerAnglesXYZ()))
	
	for _, ObjectInfo:ObjectInfo in ipairs(self.DrawList) do
		if not (ObjectInfo.Base and ObjectInfo.Replica) then warn(ObjectInfo.Base, ObjectInfo.Replica,"Missing!") continue end
		
		if not ObjectInfo.Base:IsDescendantOf(self.BaseObject) then
			ObjectInfo.Replica.Parent = self.DisplayObjectStorage
			continue
		end
		
		if ObjectInfo.Replica:IsDescendantOf(self.DisplayObjectStorage) then
			ObjectInfo.Replica.Parent = ObjectInfo.Parent or self.SurfaceGui
		end
		
		ObjectInfo.Replica:PivotTo(BaseOrigin:ToObjectSpace(ObjectInfo.Base:GetPivot()) * (ObjectInfo.Offset or CFrame.new(0, 0, 0)))
	end
	
	if UpdateTransparency then
		self:UpdateTransparency()
	end
end

function DisplayObject:ReplicaToOriginal(Replica:Instance)
	if not Replica then return end
	
	for _, ObjectInfo:ObjectInfo in pairs(self.Objects) do
		if ObjectInfo.Replica == Replica then
			return ObjectInfo.Base
		end
	end
end

--Render Object : BasePart | SurfaceGui's Parent : Instance
function DisplayObject.new(Object:BasePart, Parent:Instance):DisplayObject
	assert(Parent, "[!] Parent not found!")
	if not (Object and (Object:IsA("BasePart") or Object:IsA("Model"))) then return end
	
	warn("[+] Rendering "..Object.Name)
	
	local self = setmetatable({}, DisplayObject)
	self.Camera = self:GetCamera()
	self.DisplayObjectFolder = self:GetDisplayObjectFolder()
	self.DisplayObjectStorage = self:GetDisplayObjectStorageFolder()
	
	self.Transparency = 0
	self.RenderDistance = 256
	self.SnapPoints = 16
	self.BaseObject = Object
	
	self.Occluded = false
	self.Screen = self:GetScreen(Parent)
	
	self.BaseObjectInfo = self:Replicate(Object, self.Viewport)
	self.BaseReplica = self.BaseObjectInfo.Replica
	
	Object.Destroying:Once(function()
		self:Destroy()
	end)
	
	self:UpdateDrawList()
	
	return self
end

return DisplayObject
