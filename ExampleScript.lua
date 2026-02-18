--[[
Example script using the DisplayObject module.

NOTE! Location of the DisplayObject module has to be in a folder titled Modules in ReplicatedStorage
ReplicatedStorage -> Modules -> DisplayObject
]]

--[[ Services ]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--[[ Objects ]]
local Camera = workspace.CurrentCamera

local RenderObjectFolder do
	RenderObjectFolder = workspace:FindFirstChild("RenderObject")
	if not RenderObjectFolder then
		RenderObjectFolder = Instance.new("Folder", workspace)
		RenderObjectFolder.Name = "RenderObject"
	end
end

local ObjectViewports do
	ObjectViewports = script.Parent:FindFirstChild("ObjectViewports")
	if not ObjectViewports then
		ObjectViewports = Instance.new("Folder", script.Parent)
		ObjectViewports.Name = "ObjectViewports"
	end
end

local Modules = ReplicatedStorage:WaitForChild("Modules")

--[[ Modules ]]
local _DisplayObject = require(Modules:WaitForChild("DisplayObject"))

--[[ Information ]]
local Framerate = 1 / 24
local FramerateDebounce = 0

local LocalPlayerDisplayObject

--[[ Functions ]]
local Render = {}

local function RenderObject(Object:BasePart)
	local DisplayObject = _DisplayObject.new(Object, ObjectViewports)
	
	if DisplayObject then
		Object.DescendantAdded:Connect(function(Object:BasePart)
			if DisplayObject.Objects[Object] then return end

			local ParentObjectInfo = DisplayObject.Objects[Object.Parent]
			DisplayObject:AddToDrawList(DisplayObject:Replicate(Object, ParentObjectInfo and ParentObjectInfo.Replica or DisplayObject.BaseReplica))
		end)

		DisplayObject.OnDestroy = function()
			table.remove(Render, table.find(Render, DisplayObject))
		end

		table.insert(Render, DisplayObject)
	end

	return DisplayObject
end

local function CharacterAdded(Character:Model, Player:Player)
	task.spawn(function()
		local Humanoid:Humanoid = Character:WaitForChild("Humanoid")
		if not Player:HasAppearanceLoaded() then
			Humanoid.ApplyDescriptionFinished:Wait()
		end

		local PlayerRenderObject = RenderObject(Character)

		if Player == Players.LocalPlayer then
			LocalPlayerDisplayObject = PlayerRenderObject
		end

		if Humanoid.Health <= 0 then
			PlayerRenderObject:Destroy()
			return
		end

		Humanoid.Died:Once(function()
			PlayerRenderObject:Destroy()
		end)

		assert(PlayerRenderObject.BaseReplica, "[!] No Base Replica!")
	end)
end

RenderObjectFolder.ChildAdded:Connect(function(Child:Instance)
	RenderObject(Child)
end)

for _, Child:Instance in pairs(RenderObjectFolder:GetChildren()) do
	RenderObject(Child)
end

Players.PlayerAdded:Connect(function(Player:Player)
	Player.CharacterAdded:Connect(function(Character:Model)
		CharacterAdded(Character, Player)
	end)
end)

for _, Player:Player in ipairs(Players:GetChildren()) do
	if Player.Character then CharacterAdded(Player.Character, Player) end

	Player.CharacterAdded:Connect(function(Character:Model)
		CharacterAdded(Character, Player)
	end)
end

local RenderCountUpdateTransparency = 4
local RenderCount = 0

RunService:BindToRenderStep("objectDisplayUpdate", 250, function(dt)
	local UpdateObjects = false
	local UpdateTransparency = false

	FramerateDebounce = FramerateDebounce + dt
	if FramerateDebounce > Framerate then
		FramerateDebounce = FramerateDebounce % Framerate

		RenderCount = RenderCount + 1
		if RenderCount >= RenderCountUpdateTransparency then
			RenderCount = 0
			UpdateTransparency = true
		end
		UpdateObjects = true
	end

	for _, ObjectInfo in ipairs(Render) do
		ObjectInfo:UpdateScreen()

		if UpdateObjects then
			ObjectInfo:UpdateObjects(UpdateTransparency)
		end
	end

	if LocalPlayerDisplayObject then
		local PlaneDirection = (Camera.CFrame.Position - LocalPlayerDisplayObject.DisplayPart.Position) * Vector3.new(1,0,1)
		LocalPlayerDisplayObject.Transparency = math.clamp(1.5 - PlaneDirection.Magnitude / 2, 0, 1)
	end
end)
