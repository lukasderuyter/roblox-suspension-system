--Clutch works off of Delta time which is ran Pre-Simulation using RunService
--Every time step it increases the clutch engagement, this code simulates the friction between the clutch and how it applies force
--The NetForce it changes at the end is used by the rest of the code to apply the force to the wheels
--The code also has some checks to prevent the engine from reaching below a target RPM

local ClutchCalculations = function()
	local Engine_Inertia = PrivateProperties["Engine_Inertia"]
	local DrivelineInertiaConst = PrivateProperties["DriveLineInertiaConst"]
	local InertiaGear_Base = PrivateProperties["InertiaGear_Base"]
	local Clutch_Cap = PrivateProperties["Clutch_Capacity"]
	local SlipStiffness = PrivateProperties["Slip_Stiffness"]
	local Engine_DragCoefficient = PrivateProperties["Engine_DragCoefficient"]
	local ClutchEngagement = ClientProperties["ClutchEngagement"]
	local BaseGearRatio = PrivateProperties["GearRatios"][PrivateProperties["BaseGear"]]
	local ScaleFactor = ((1/(1+GearRatio))^2) / ((1/(1+BaseGearRatio))^2)
	local ClutchEngagementRate = PrivateProperties["Clutch_Engagement_Rate"]
	local ClutchConnected = ClientProperties["ClutchConnected"]
	local ClutchState = ClientProperties["ClutchState"] -- False means theyre not pressing the clutch, true means they are.
	local DriveTrainInefficiency = PrivateProperties["DriveTrainLoss"]


	if ClientProperties["ReplicatedProperties"]["DrivingMode"] == 0 then --In my vehicle system, theres multiple driving modes "Sport, Normal, etc"

		ClutchState = false --If Driving mode is normal, player doesnt have to worry about the clutch

	end

	local AxleSpeed = (((ClientProperties["WheelSpeeds"]["RR"]) + (ClientProperties["WheelSpeeds"]["RL"])) / 2)

	AxleSpeed *= PrivateProperties["Final_Drive"]
	local InputShaftSpeed = AxleSpeed * GearRatio 

	local EngineSpeed = EngineRPM/9.549297

	local DeltaVelocity = math.abs(EngineSpeed) - math.abs(InputShaftSpeed) --Difference in velocity between engine and "input shaft"
	

	
	local IdleSpeed = IdleRPM/9.549297



	local ClutchTarget = 0



	if EngineRPM < IdleRPM and ThrottleFloat ~= 1 and math.abs(Meters_Second) < 5 then 

		ClutchState = true --Prevent car from stalling

	end


	if ThrottleFloat == 1 and EngineRPM < AccelerationRPM and ClutchState == false and HandBrake == false then 

		ClutchEngagement = 0 --Reduce clutch to help engine if its below target RPM


	end

	if ClutchState == false then ClutchTarget = 1 end
	--if HandBrake == true then ClutchTarget = 0 end


	local ClutchEngagement_Derivative = (ClutchTarget-ClutchEngagement) * ClutchEngagementRate * Delta



	ClientProperties["ClutchEngagement"] = ClutchEngagement + ClutchEngagement_Derivative




	local Clutch_Demanded_Torque = SlipStiffness * DeltaVelocity
	local MaxTorque = ClutchEngagement * Clutch_Cap

	ClutchTorque = math.clamp(Clutch_Demanded_Torque,-MaxTorque,MaxTorque)

	local EngineFriction = Engine_DragCoefficient * EngineSpeed
	local NetTorqueEngine = EngineTorque - ClutchTorque - EngineFriction
	local EngineAcceleration = NetTorqueEngine/Engine_Inertia
	EngineSpeed = EngineSpeed + (EngineAcceleration * Delta)




	NetTorque = ClutchTorque * (1-DriveTrainInefficiency) * GearRatio_Overall
	NetForce = NetTorque/WheelRadius --Force applied to the wheels

	if EngineRPM >= Redline then 


		NetForce -= ClientProperties["BrakingForce"]

	end

	EngineRPM = EngineSpeed * 9.549297


end