-- subtitle module
local module = {};

-- TODO: these things, in order from most important to least
--- sequence builder
--- function to change font size
--- i don't know where to place this in the code, but a limit on number of subtitles would be cool, see how other games do this
--- event-based system rather than poll-loops, not really needed but would be nice
--- API Docs

local overlap_params = OverlapParams.new();

local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");
local player = game:GetService("Players").LocalPlayer;

local panel = player:WaitForChild("PlayerGui"):WaitForChild("Subtitles"):WaitForChild("Frame");
-- extra height of panel
local panel_padding = 9/16;
-- offset for text inside
local panel_text_offset = -5/16;
local panel_trans = 0.3;
local font_size = 32;
local tween_speed = 0.1;
local tween_max_dist = 5;
local tween_debounce = 0.2;
local text_default_colour = Color3.fromRGB(255, 253, 172);
local panel_size = 0;
local panel_old_size = 0;
local text_offset = 0;
local panel_handler_running = false;
local active_subtitles = {};
local active_subtitles_alloc = 1;
local max_tick_subtitles = 20;
local subtitle_queue = {};
local reserved = 0;
local fade_tween = TweenInfo.new(tween_speed, Enum.EasingStyle.Linear);
local function panel_handler()
	if panel_handler_running then
		return;
	end
	panel_handler_running = true;
	local ops = 0;
	local can_add_text = true;
	local function done()
		ops = ops - 1;
		if ops <= 0 then
			done = function() end;
			panel_handler_running = false;
			RunService.Heartbeat:Once(panel_handler);
		end
	end
	if text_offset ~= 0 then
		ops = ops + 1;
		can_add_text = false;
		local old = text_offset;
		text_offset = 0;
		panel_size = panel_size - old;
		local delete = {};
		local tween, tween_timer = nil, math.min(math.abs(old), tween_max_dist) * tween_speed;
		local info = TweenInfo.new(tween_timer, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0);
		for i = 1, #active_subtitles do
			local sub = active_subtitles[i];
			if sub ~= nil then
				local obj = sub[1];
				sub[2] = sub[2] - old;
				local del = sub[2] < 0;
				if del then
					delete[#delete + 1] = i;
				end
				tween = TweenService:Create(sub[1], info, {
					Position = UDim2.new(0.5, 0, 0, sub[1].Position.Y.Offset - old * font_size);
					TextTransparency = (panel_size <= 0 or del) and 1 or 0;
				});
				tween:Play();
			end
		end
		local function inner_done()
			for i = 1, #delete do
				local idx = delete[i];
				--delay(tween_max_dist * tween_speed, function()
				active_subtitles[idx][1]:Destroy();
				active_subtitles[idx] = nil;
				--end);
			end
			if #delete > 0 and delete[1] < active_subtitles_alloc then
				active_subtitles_alloc = delete[1];
			end
			return done();
		end
		if tween ~= nil then
			tween.Completed:Connect(inner_done);
		else
		delay(tween_timer, inner_done);
		end
	end
	if panel_size ~= panel_old_size then
		ops = ops + 1;
		local old = panel_old_size;
		panel_old_size = panel_size;
		local tween = TweenService:Create(panel, TweenInfo.new(math.min(math.abs(panel_size - old), tween_max_dist) * tween_speed, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), {
			Size = UDim2.new(0.5, 0, 0, (panel_padding + panel_size) * font_size);
			BackgroundTransparency = panel_size > 0 and panel_trans or 1;
		});
		tween:Play();
		tween.Completed:Connect(function()
			return done();
		end);
	end
	if ops == 0 then
		panel_handler_running = false;
	end
	if can_add_text then
		local ran = 0;
		local has_sub = false;
		while subtitle_queue[1] ~= nil do
			has_sub = true;
			-- TODO: more time-efficient subtitle queue
			local sub = table.remove(subtitle_queue, 1);
			local text, fade, col = sub[1], sub[2], sub[3];
			while active_subtitles[active_subtitles_alloc] ~= nil do
				active_subtitles_alloc = active_subtitles_alloc + 1;
			end;
			local inst = Instance.new("TextLabel");
			local idx = active_subtitles_alloc;
			active_subtitles_alloc = active_subtitles_alloc + 1;
			active_subtitles[idx] = {inst, panel_size};
			inst.TextTransparency = 1;
			inst.Parent = panel;
			inst.Name = "Subtitle:" .. idx;
			inst.AnchorPoint = Vector2.new(0.5, 0);
			inst.BackgroundTransparency = 1;
			inst.BorderSizePixel = 0;
			inst.Size = UDim2.new(0.95, 0, 0, font_size);
			inst.Font = Enum.Font.Oswald;
			inst.RichText = true;
			inst.Text = text;
			inst.TextColor3 = col or text_default_colour;
			inst.TextSize = font_size;
			inst.TextWrapped = true;
			inst.TextXAlignment = Enum.TextXAlignment.Left;
			local lines = math.ceil(inst.TextBounds.Y / font_size);
			inst.Position = UDim2.new(0.5, 0, 0, (panel_size + lines / 2 + panel_text_offset) * font_size);
			TweenService:Create(inst, fade_tween, {
				TextTransparency = 0;
			}):Play();
			panel_size = panel_size + lines;
			delay(fade, function()
				text_offset = text_offset + lines;
				delay(tween_debounce, panel_handler);
			end);
			ran = ran + 1;
			if ran > max_tick_subtitles then
				ran = 0;
				RunService.Heartbeat:Wait();
				--break;
			end
		end
		if has_sub then
			return panel_handler();
		end
	end
end

function module.play(area, audio, seq)
	local character = player.Character and player.Character:FindFirstChild("HumanoidRootPart");
	if character == nil then
		return;
	end
	local touching = workspace:GetPartsInPart(character, overlap_params);
	local touch = false;
	for i = 1, #touching do
		if touching[i] == area then
			touch = true;
			break;
		end
	end
	if not touch then
		return;
	end
	local time = tick();
	for i = 1, #audio do
		audio[i]:Play();
	end
	for i = 1, #seq do
		local cmd = seq[i];
		local cmd_ty = cmd[1];
		if cmd_ty == "p" then
			local fade, col, text = cmd[2], cmd[3], cmd[4];
			if fade == nil then
				if #seq == 1 and #audio > 0 then
					fade = audio[1].TimeLength;
				else
					fade = 0;
				end
			end
			local end_time = time + fade;
			if end_time < reserved then
				fade = reserved - time;
			else
				reserved = end_time;
			end
			subtitle_queue[#subtitle_queue + 1] = {text, fade, col};
			RunService.Heartbeat:Once(panel_handler);
		elseif cmd_ty == "d" then
			time = time + cmd[2];
			while tick() < time do
				RunService.Heartbeat:Wait();
			end
		end
	end
end


return module;
