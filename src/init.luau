local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local rag = {}
local overrides = {
	Neck = { 45, -70, 70 },
	Hip = { 60, -30, 30 },
	Shoulder = { 75, -60, 60 },
}
local colliderExclude = {
	"HumanoidRootPart",
}

local function _hum(Char: Model): Humanoid
	local humanoid = Char:FindFirstChildWhichIsA("Humanoid", true)
	if not humanoid then
		warn("Can't ragdoll: No humanoid!")
		return
	end
	return humanoid
end

local function CreateCollider(Part: BasePart)
	local ex = table.find(colliderExclude, Part.Name)
	if not ex and not Part.CanCollide then
		Part.CanCollide = true
		Part:AddTag("_RagdollCollider")
	end
end

function rag.IsRagdolled(Char: Model)
	for _, inst in Char:GetDescendants() do
		if inst:HasTag("_RagdollTrash") or inst:HasTag("_RagdollDisabled") then
			return true
		end
	end
	return false
end

--[[
    Ragdolls all Motor6Ds except those with "NoRagdoll" tag
    Safe to call when already ragdolled
]]
function rag.Ragdoll(Char: Model, NoCollide: boolean?)
	local humanoid = _hum(Char)
	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false
	if RunService:IsClient() then
		humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
	elseif RunService:IsServer() then
		Char.PrimaryPart:SetNetworkOwner(nil)
		humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
	end
	for _, motor: Motor6D in Char:GetDescendants() do
		local p0 = motor.Part0
		local p1 = motor.Part1
		if
			motor:IsA("Motor6D")
			and not motor:HasTag("NoRagdoll")
			and not motor:HasTag("_RagdollDisabled")
			and p0
			and p1
		then
			motor.Enabled = false
			motor:AddTag("_RagdollDisabled")
			local a0 = Instance.new("Attachment")
			a0:AddTag("_RagdollTrash")
			local a1 = Instance.new("Attachment")
			a1:AddTag("_RagdollTrash")
			a0.CFrame = motor.C0
			a1.CFrame = motor.C1
			local ball = Instance.new("BallSocketConstraint")
			ball:AddTag("_RagdollTrash")
			ball.Attachment0 = a0
			ball.Attachment1 = a1
			ball.Radius = 0.15
			ball.LimitsEnabled = true
			ball.TwistLimitsEnabled = true
			ball.MaxFrictionTorque = 0
			ball.Restitution = 0
			local o
			for i in overrides do
				if motor.Name:find(i) then
					o = i
					break
				end
			end
			ball.UpperAngle = o and overrides[o][1] or 90
			ball.TwistLowerAngle = o and overrides[o][2] or -45
			ball.TwistUpperAngle = o and overrides[o][3] or 45
			a0.Parent = p0
			a1.Parent = p1
			ball.Parent = motor.Parent
			if not NoCollide then
				CreateCollider(p1)
			end
		end
	end
end
--[[
    Re-enables all Motor6Ds
    Safe to call when not ragdolled
]]
function rag.Unragdoll(Char: Model)
	local humanoid = _hum(Char)
	if RunService:IsClient() then
		humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	elseif RunService:IsServer() then
		humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)

		local Player = Players:GetPlayerFromCharacter(Char)
		if Player then
			Char.PrimaryPart:SetNetworkOwner(Player)
		end
	end
	for _, inst in Char:GetDescendants() do
		if inst:HasTag("_RagdollTrash") then
			inst:Destroy()
		elseif inst:HasTag("_RagdollDisabled") then
			inst.Enabled = true
			inst:RemoveTag("_RagdollDisabled")
		elseif inst:HasTag("_RagdollCollider") then
			inst.CanCollide = false
			inst:RemoveTag("_RagdollCollider")
		end
	end
end

return rag
