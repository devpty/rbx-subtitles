-- server-triggered subtitles
game:GetService("ReplicatedStorage"):WaitForChild("Subtitles").OnClientEvent:Connect(require(script.Parent).play);
