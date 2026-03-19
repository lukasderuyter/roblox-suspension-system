
--------------------------------------Suspension Physics and Frictional Forces
local SuccessfulRaycast = false

local function Suspension()
	--Calculate spring constant
	local RobloxWeight = (AssemblyMass*workspace.Gravity)/4 --RMU Weight or the Force applied to the spring as a result of gravity 
	--Divide by 4 since there's 4 wheels and assuming even distribution
	local SpringFreeLengthRatio = ClientProperties["SpringFreeLengthRatio"]
	local SpringFreeLength = ClientProperties["SpringFreeLength"] --Length of Spring at equilibrium

	local CarWeight = (PrivateProperties["Weight_kg"] * 9.81)/4

	local Force = CarWeight --Force in newtons gravity exerts on the car
	local TireDeflection = PrivateProperties["TireDeflection"]

	local WeightRatio = RobloxWeight/CarWeight

	local SpringConstant = PrivateProperties["SpringConstant"] --Spring Constant K
	--SpringConstant*= WeightRatio --Account for differences in mass between the theoretical calculations and the ROBLOX part mass

	SpringConstant = (SpringConstant/4)*WeightRatio





	--Calculating damping coefficient from ratio
	local TotalSpringConstantForce = SpringConstant * 4
	local DampingRatio = PrivateProperties["DampingRatio"]
	local DampingCoefficient = (DampingRatio * (2*math.sqrt(TotalSpringConstantForce*AssemblyMass))) / 4


	local TotalDampening = 4*DampingCoefficient

	local MaxSpringLength = SpringFreeLength*SpringFreeLengthRatio

	local wheelOffset = Vector3.new(0,0,0)




	local SpringVectorForceDictionary = ClientProperties["SpringVectorForceDictionary"]

	local RaycastParameters = RaycastParams.new()
	RaycastParameters.FilterDescendantsInstances = {CarModel}

	if ClientProperties["FilterObjects"] then

		RaycastParameters.FilterDescendantsInstances = {CarModel,ClientProperties["FilterObjects"]}

	end




	for Wheel_Name, VectorForce : VectorForce in pairs(SpringVectorForceDictionary) do
		local Attachment = VectorForce.Attachment0 :: Attachment


		local WheelAttachmentPosition = Attachment.WorldPosition



		local RayDirection = -Attachment.CFrame.UpVector*MaxSpringLength 
		local RayOrigin = Attachment.WorldCFrame*wheelOffset
		local RayCastResult = workspace:Raycast(RayOrigin, RayDirection, RaycastParameters)


		local VelocityVector = PrimaryPart:GetVelocityAtPosition(RayOrigin) 


		local Velocity:number = -RayDirection.Unit:Dot(VelocityVector) 




		Wheel_Vels[Wheel_Name] = VelocityVector



		if RayCastResult then
			SuccessfulRaycast = true





			local RayCast_Distance = (WheelAttachmentPosition - RayCastResult.Position).Magnitude
			local Spring_Length = math.clamp(RayCast_Distance, 0, MaxSpringLength)

			local Spring_Displacement = MaxSpringLength - RayCast_Distance --Distance from Equilibrium



			local SpringDirection = PrimaryPart.CFrame.UpVector

			local SpringForceMagnitude = Spring_Displacement*SpringConstant


			local Dampening = -Velocity*DampingCoefficient 

			local Radius = (RayOrigin - PrimaryPart.AssemblyCenterOfMass)


			local NetForce:Vector3 = (SpringForceMagnitude+Dampening)*SpringDirection


			VectorForce.Force = NetForce

