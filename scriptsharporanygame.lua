-- ==========================================
-- TỐI ƯU HÓA BIẾN MÔI TRƯỜNG
-- ==========================================
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer

-- Xác định nơi chứa ESP an toàn, ưu tiên gethui() của Delta để tránh anti-cheat
local targetParent = (gethui and gethui()) or CoreGui:FindFirstChild("RobloxGui") or CoreGui

-- Tạo một thư mục riêng để dễ dàng quản lý và xóa ESP nếu chạy lại script
local espFolderName = "DeltaMobile_ESP_Folder"
if targetParent:FindFirstChild(espFolderName) then
    targetParent[espFolderName]:Destroy()
end

local espFolder = Instance.new("Folder")
espFolder.Name = espFolderName
espFolder.Parent = targetParent

-- ==========================================
-- LOGIC TẠO ESP
-- ==========================================
local function createESP(player)
    -- Bỏ qua việc tạo ESP cho chính bản thân mình
    if player == localPlayer then return end

    local function onCharacterAdded(character)
        -- Chờ nhân vật load đủ các bộ phận quan trọng
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
        if not humanoidRootPart then return end -- Nếu load quá lâu (lag) thì bỏ qua để tránh lỗi

        -- Xóa ESP cũ của người này (nếu có) để tránh bị đè lên nhau
        if espFolder:FindFirstChild(player.Name .. "_Highlight") then
            espFolder[player.Name .. "_Highlight"]:Destroy()
        end
        if espFolder:FindFirstChild(player.Name .. "_Name") then
            espFolder[player.Name .. "_Name"]:Destroy()
        end

        -- 1. TẠO HIGHLIGHT (Làm sáng thân người xuyên tường)
        local highlight = Instance.new("Highlight")
        highlight.Name = player.Name .. "_Highlight"
        highlight.Adornee = character
        highlight.FillColor = Color3.fromRGB(255, 50, 50) -- Màu đỏ nhạt bên trong
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255) -- Viền trắng
        highlight.FillTransparency = 0.5 -- Độ trong suốt của thân (0 là đặc, 1 là tàng hình)
        highlight.OutlineTransparency = 0 -- Viền rõ nét
        highlight.Parent = espFolder

        -- 2. TẠO TÊN (Hiển thị tên trên đầu xuyên tường)
        local billboard = Instance.new("BillboardGui")
        billboard.Name = player.Name .. "_Name"
        billboard.Adornee = humanoidRootPart
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3.5, 0) -- Đẩy chữ nổi lên trên đầu 3.5 block
        billboard.AlwaysOnTop = true -- Bắt buộc hiện xuyên tường
        billboard.Parent = espFolder

        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = player.DisplayName .. "\n(@" .. player.Name .. ")"
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        textLabel.TextStrokeTransparency = 0 -- Thêm viền đen cho chữ để dễ nhìn ở mọi khung cảnh
        textLabel.TextSize = 12
        textLabel.Font = Enum.Font.GothamBold
        textLabel.Parent = billboard
    end

    -- Nếu người chơi đã có nhân vật sẵn trong game (lúc bạn vừa bật script)
    if player.Character then
        task.spawn(onCharacterAdded, player.Character)
    end

    -- Lắng nghe sự kiện mỗi khi người chơi này chết và hồi sinh lại
    player.CharacterAdded:Connect(function(character)
        task.spawn(onCharacterAdded, character)
    end)
end

-- ==========================================
-- KÍCH HOẠT SỰ KIỆN
-- ==========================================

-- 1. Quét toàn bộ người chơi đang có mặt trong server
for _, player in pairs(Players:GetPlayers()) do
    createESP(player)
end

-- 2. Tự động áp dụng ESP cho những người chơi mới tham gia sau này
Players.PlayerAdded:Connect(function(player)
    createESP(player)
end)

-- 3. Dọn rác: Xóa ESP của người chơi khi họ thoát khỏi server
Players.PlayerRemoving:Connect(function(player)
    if espFolder:FindFirstChild(player.Name .. "_Highlight") then
        espFolder[player.Name .. "_Highlight"]:Destroy()
    end
    if espFolder:FindFirstChild(player.Name .. "_Name") then
        espFolder[player.Name .. "_Name"]:Destroy()
    end
end)

-- Gửi thông báo góc màn hình để biết script đã chạy thành công
game.StarterGui:SetCore("SendNotification", {
    Title = "ESP Loaded";
    Text = "Đã kích hoạt ESP cho Delta Mobile thành công!";
    Duration = 5;
})
