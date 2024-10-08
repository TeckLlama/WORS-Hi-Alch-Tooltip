-- Set the nature rune cost
local natureRuneCost = 180

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

-- Function to get stack count of an item from player's bags and guild bank
local function GetItemStackCount(itemID)
    local stackCount = 0

    -- Check bags (bagID 0 to 4)
    for bagID = 0, 4 do
        for slotID = 1, GetContainerNumSlots(bagID) do
            local link = GetContainerItemLink(bagID, slotID)
            if link then
                local id = tonumber(link:match("item:(%d+)"))
                local count = select(2, GetContainerItemInfo(bagID, slotID))
                if id == itemID then
                    stackCount = stackCount + count
                end
            end
        end
    end

    -- Check guild bank (tab 1 to 6, adjust if more tabs exist on your server)
    if IsInGuild() then
        for tab = 1, 6 do -- Iterate through all guild bank tabs
            for slotID = 1, 98 do -- Guild bank slots are typically 98 per tab
                local link = GetGuildBankItemLink(tab, slotID)
                if link then
                    local id = tonumber(link:match("item:(%d+)"))
                    local count = select(2, GetGuildBankItemInfo(tab, slotID))
                    if id == itemID then
                        stackCount = stackCount + count
                    end
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

    -- Set the color based on whether the total value is less than the nature rune cost
    local r, g, b = 1, 1, 1 -- Default white color
    if priceInGold < natureRuneCost then
		r, g, b = 1, 0, 0 -- Red color if below the nature rune cost
	else
		r, g, b = 0, 1, 0 -- Green color if equal to or above the nature rune cost
	end


    -- Add the padded text to the tooltip with the chosen color
    tooltip:AddLine(paddedText, r, g, b)
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
