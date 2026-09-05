-- Code by LSPLASH :scream:
-- Use _G.OnShop = false if you are using Delta

local FPS = _G.FPS or 0.033444816053511704

if _G.OnShop then
    local CustomShop = loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/Utilities/main/Doors/Custom%20Shop%20Items/Source.lua"))()
	
    CustomShop.CreateItem("", {
        Title = "Scanner",
        Desc = _G.Description or "",
        Image = "https://static.wikia.nocookie.net/doors-game/images/4/4e/Scanner_Icon.png/revision/latest/scale-to-width-down/350?cb=20230203191128",
        Price = _G.Price or 1000,
        Stack = 1,
    })
end

local Scanner = game:GetObjects("rbxassetid://12594482248")[1]
Scanner.Parent = game.Players.LocalPlayer.Backpack
local Storage = Scanner:WaitForChild("Storage")
local l__ScreenUI__1 = Storage.ScreenUI;
local v3 = Instance.new("Camera");
v3.Parent = l__ScreenUI__1;
v3.FieldOfView = 50;
l__ScreenUI__1.ViewNormal.CurrentCamera = v3;
l__ScreenUI__1.ViewSpecial.CurrentCamera = v3;
local v4 = {
	anim = {}
};
local l__TweenService__1 = game:GetService("TweenService");
local u2 = {};
local l__LocalPlayer__3 = game.Players.LocalPlayer;
local u4 = -1;
local u5 = -1;
local function u6(p1)
	local v5 = Instance.new("Model");
	v5.Name = p1.Name;
	v5.Parent = l__ScreenUI__1.ViewNormal;
	for _, v10 in pairs(p1:GetDescendants()) do
		if v10:IsA("BasePart") and v10.Transparency ~= 1 and v10.Size.Magnitude > 0.2 then
			local v11 = v10:Clone();
			v11.CanQuery = false;
			v11.Parent = v5;
			
			if v10.Anchored == false then
				task.spawn(function()
					while true do
						wait(0.5);
						if not v10 then
							break;
						end;
						if not v10.Parent then
							break;
						end;
						v11.Position = v10.Position;					
					end;
					v11:Destroy();
				end);
			end;
		end
		if v10:IsA("Model") and (v10.Name == "KeyObtain" or v10.Name == "LeverForGate" or v10.Name == "LiveBreakerPolePickup" or v10.Name == "LiveHintBook") then
			local v12 = Storage.Star:Clone();
			v12.CFrame = v10.PrimaryPart.CFrame;
			v12.Parent = l__ScreenUI__1.ViewSpecial;
		end;
	end
	local u7 = p1.DescendantAdded:Connect(function(p2)
		if p2:IsA("BasePart") and p2.Transparency ~= 1 and p2.Anchored == true and p2.Size.Magnitude > 0.2 then
			local v13 = p2:Clone();
			v13.CanQuery = false;
			v13.Parent = v5;
			if p2.Anchored == false then
				task.spawn(function()
					while true do
						wait(0.5);
						if not p2 then
							break;
						end;
						if not p2.Parent then
							break;
						end;
						v13.Position = p2.Position;					
					end;
					v13:Destroy();
				end);
			end;
		end;
	end);
	v5.AncestryChanged:Connect(function()
		u7:Disconnect();
	end);
end;
local u8 = true;
local u9 = true;
local function u10()
	l__ScreenUI__1.OffScreen.Visible = false;
	l__ScreenUI__1.Static1.ImageTransparency = 0;
	l__ScreenUI__1.Static2.ImageTransparency = 0;
	l__TweenService__1:Create(l__ScreenUI__1.Static1, TweenInfo.new(3, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
		ImageTransparency = 0.9
	}):Play();
	l__TweenService__1:Create(l__ScreenUI__1.Static2, TweenInfo.new(3, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
		ImageTransparency = 1
	}):Play();
	l__ScreenUI__1.ViewSpecial.ImageColor3 = Color3.fromRGB(217, 255, 206);
	l__TweenService__1:Create(l__ScreenUI__1.ViewSpecial, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut, 10, true), {
		ImageColor3 = Color3.fromRGB(53, 93, 52)
	}):Play();
	v3.FieldOfView = 1;
	l__TweenService__1:Create(v3, TweenInfo.new(3, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
		FieldOfView = 30
	}):Play();
	Scanner.Handle.Use:Play();
	Scanner.Handle.Idle:Play();
end;
function equip(p3)
	print("scanner module: tool equipped!");
	for v14, v15 in pairs(Scanner:WaitForChild("Animations"):GetChildren()) do
		u2[v15.Name] = l__LocalPlayer__3.Character.Humanoid:LoadAnimation(v15);
	end;
	u2.equip:Play();
	u2.idle:Play();
	l__ScreenUI__1.Parent = l__LocalPlayer__3.PlayerGui;
	l__ScreenUI__1.Enabled = true;
	l__ScreenUI__1.Adornee = Scanner:WaitForChild("Handle"):WaitForChild("Screen");
	u4 = l__LocalPlayer__3:GetAttribute("CurrentRoom");
	u5 = u4;
	for v16 = u4, u4 do
		local v17 = workspace.CurrentRooms:FindFirstChild(v16);
		if v17 and l__ScreenUI__1.ViewNormal:FindFirstChild(v16) == nil then
			u6(v17);
		end;
	end;
	wait(0.2);
	u8 = true;
	u9 = true;
	u10();
	while u8 do
		if u9 == true then
			local v18, v19 = pcall(function()
				v3.CFrame = Scanner.Handle.Screen.CFrame * CFrame.Angles(0, 3.141592653589793, 0);
				l__ScreenUI__1.ViewNormal.LightDirection = v3.CFrame.LookVector - Vector3.new(0, 1, 0);
				l__ScreenUI__1.Static1.Position = UDim2.new(0.5, math.random(-28, 28) * 6, 0.5, math.random(-18, 18) * 6);
				l__ScreenUI__1.Static2.Position = UDim2.new(0.5, math.random(-28, 28) * 6, 0.5, math.random(-18, 18) * 6);
				if math.random(1, 2) == 2 then
					v20 = "rbxassetid://8681113666";
				else
					v20 = "rbxassetid://8681113503";
				end;
				l__ScreenUI__1.Static1.Image = v20;
				u4 = l__LocalPlayer__3:GetAttribute("CurrentRoom");
				for v21, v22 in pairs(l__ScreenUI__1.ViewSpecial:GetChildren()) do
					if v22:IsA("BasePart") then
						v22.CFrame = CFrame.new(v22.Position, v3.CFrame.p);
					end;
				end;
				if u4 ~= u5 then
					u5 = u4;
					u10();
					for v23, v24 in pairs(l__ScreenUI__1.ViewNormal:GetChildren()) do
						if v24:IsA("Model") then
							v24:Destroy();
						end;
					end;
					for v25, v26 in pairs(l__ScreenUI__1.ViewSpecial:GetChildren()) do
						if v26:IsA("BasePart") then
							v26:Destroy();
						end;
					end;
					for v27 = u4, u4 do
						local v28 = workspace.CurrentRooms:FindFirstChild(v27);
						if v28 and l__ScreenUI__1.ViewNormal:FindFirstChild(v27) == nil then
							u6(v28);
						end;
					end;
				end;
			end);
			if v19 then
				warn(v19);
			end;
		end;
		if u8 == false then
			break;
		end;
		task.wait(FPS);	
	end;
end;
local u11 = tick();
local function u12()
	l__ScreenUI__1.OffScreen.Visible = true;
	l__ScreenUI__1.OffScreen.Frame.Size = UDim2.new(1, 0, 1, 0);
	l__TweenService__1:Create(l__ScreenUI__1.OffScreen.Frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(1, 0, 0.1, 0)
	}):Play();
	delay(0.31, function()
		l__TweenService__1:Create(l__ScreenUI__1.OffScreen.Frame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0), {
			Size = UDim2.new(0, 0, 0.1, 0)
		}):Play();
	end);
	l__ScreenUI__1.OffScreen.BackgroundColor3 = Color3.fromRGB(39, 59, 33);
	l__TweenService__1:Create(l__ScreenUI__1.OffScreen, TweenInfo.new(2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, 0), {
		BackgroundColor3 = Color3.fromRGB(3, 6, 2)
	}):Play();
	Scanner.Handle.Disable:Play();
	Scanner.Handle.Idle:Stop();
end;
function fire()
	if u11 <= tick() then
		u11 = tick() + 0.5;
		u2.fire:Play(0.05, 1, 1);
		wait(0.2);
		u9 = not u9;
		if u9 ~= true then
			u12();
			return;
		end;
	else
		return;
	end;
	u10();
end;
local l__Handle__13 = Scanner:WaitForChild("Handle", 1);
function unequip(p4)
	print("scanner module: tool unequipped!");
	l__ScreenUI__1.Parent = script;
	l__ScreenUI__1.Enabled = false;
	u8 = false;
	for v29, v30 in pairs(l__Handle__13:GetChildren()) do
		if v30:IsA("Sound") then
			v30:Stop();
		end;
	end;
	Scanner.Handle.Disable:Play();
	for v31, v32 in pairs(l__ScreenUI__1.ViewNormal:GetChildren()) do
		if v32:IsA("Model") then
			v32:Destroy();
		end;
	end;
	u2.equip:Stop();
	u2.idle:Stop();
end;
Scanner.Activated:Connect(fire);
Scanner.Equipped:Connect(equip);
Scanner.Unequipped:Connect(unequip);
