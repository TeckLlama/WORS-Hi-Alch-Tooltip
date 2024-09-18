-- Function to get the Hi Alch price from the HiAlchData table using itemID or itemName
local function GetHiAlchPrice(itemID, itemName)
    for name, data in pairs(HiAlchData) do
        local regularID, notedID, price = unpack(data)
        -- Check if itemID matches or itemName matches (ignoring case)
        if itemID == regularID or itemID == notedID or name:lower() == itemName:lower() then
            return price, name -- Return both price and the matched item name
        end
    end
    return 0, nil -- Default if not found
end

-- Function to get stack count of an item from player's bags
local function GetItemStackCount(itemID)
    local stackCount = 0
    for bagID = 0, 4 do -- Iterate through all bags
        for slotID = 1, GetContainerNumSlots(bagID) do
            local link = GetContainerItemLink(bagID, slotID)
            if link then
                local id = tonumber(link:match("item:(%d+)"))
                local count = select(2, GetContainerItemInfo(bagID, slotID))
                if id == itemID then
                    stackCount = count
                    return stackCount
                end
            end
        end
    end
    return stackCount
end

-- Function to add Hi Alch price to the tooltip
local function AddHiAlchPrice(tooltip, itemLink)
    if not itemLink then return end

    local itemID = tonumber(itemLink:match("item:(%d+)"))
    local itemName = GetItemInfo(itemLink) -- Retrieve the item name
    local priceInGold, matchedName = GetHiAlchPrice(itemID, itemName) -- Retrieve Hi Alch price using itemID or itemName

    local stackCount = 1 -- Default to 1 if not in bags
    if IsShiftKeyDown() then
        stackCount = GetItemStackCount(itemID)
        if stackCount == 0 then
            stackCount = 1 -- If item not found in bags, fallback to 1
        end
    end

    local totalValue = priceInGold * stackCount
    local totalValueStr = string.format("%d", totalValue)

    -- Define a fixed width for the tooltip line and calculate padding
    local fixedWidth = 40 -- Adjust width as necessary for alignment
    local label = IsShiftKeyDown() and string.format("Hi Alch x%d:", stackCount) or "Hi Alch:"
    local labelWidth = #label
    local valueWidth = #totalValueStr
    local padding = fixedWidth - labelWidth - valueWidth

    -- Ensure padding is not negative
    if padding < 0 then
        padding = 0
    end

    -- Create the padded text with alignment
    local paddedText = string.format("%s%s%s|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t", label, string.rep(" ", padding), totalValueStr)

    -- Clear previous Hi Alch lines if Shift is not held
    for i = 1, tooltip:NumLines() do
        local line = _G["GameTooltipTextLeft" .. i]
        if line and line:GetText() and line:GetText():match("Hi Alch") then
            line:SetText("") -- Clear existing Hi Alch Price line
        end
    end

    -- Add the padded text to the tooltip
    tooltip:AddLine(paddedText, 1, 1, 1)
    tooltip:Show() -- Update the tooltip to show the new line
end

-- Hook to add Hi Alch price when the tooltip is set for an item
GameTooltip:HookScript("OnTooltipSetItem", function(self)
    local _, itemLink = self:GetItem()
    AddHiAlchPrice(self, itemLink)
end)

ItemRefTooltip:HookScript("OnTooltipSetItem", function(self)
    local _, itemLink = self:GetItem()
    AddHiAlchPrice(self, itemLink)
end)
