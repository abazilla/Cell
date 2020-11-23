local _, Cell = ...
local L = Cell.L
local F = Cell.funcs
local LPP = LibStub:GetLibrary("LibPixelPerfect")

local layoutsTab = Cell:CreateFrame("CellOptionsFrame_LayoutsTab", Cell.frames.optionsFrame, nil, nil, true)
Cell.frames.layoutsTab = layoutsTab
layoutsTab:SetAllPoints(Cell.frames.optionsFrame)
layoutsTab:Hide()

local selectedLayout, selectedLayoutTable
-------------------------------------------------
-- preview frame
-------------------------------------------------
local previewButton = CreateFrame("Button", "LayoutsPreviewButton", layoutsTab, "CellUnitButtonTemplate")
previewButton:SetPoint("TOPRIGHT", layoutsTab, "TOPLEFT", -5, -20)
previewButton:UnregisterAllEvents()
previewButton:SetScript("OnEnter", nil)
previewButton:SetScript("OnLeave", nil)
previewButton:SetScript("OnShow", nil)
previewButton:SetScript("OnHide", nil)
previewButton:SetScript("OnUpdate", nil)
previewButton:Show()

local previewButtonBG = Cell:CreateFrame("LayoutsPreviewButtonBG", layoutsTab)
previewButtonBG:SetPoint("TOPLEFT", previewButton, 0, 20)
previewButtonBG:SetPoint("BOTTOMRIGHT", previewButton, "TOPRIGHT")
previewButtonBG:SetFrameStrata("BACKGROUND")
Cell:StylizeFrame(previewButtonBG, {.1, .1, .1, .77}, {0, 0, 0, 0})
previewButtonBG:Show()

local previewText = previewButtonBG:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET_TITLE")
previewText:SetPoint("TOP", 0, -3)
previewText:SetText(Cell:GetPlayerClassColorString()..L["Preview"])

local function UpdatePreviewButton(which, value)
    if not previewButton.loaded then
        previewButton.loaded = true
        
        -- bar
        previewButton.widget.healthBar:SetStatusBarColor(F:GetClassColor(Cell.vars.playerClass))
        local r, g, b = F:GetPowerColor("player")
        previewButton.widget.powerBar:SetStatusBarColor(r, g, b)
        
        -- text
        local name, vehicleName, status = UnitName("player"), L["vehicle name"], L["DEAD"]
        
        previewButton.widget.nameText:SetText(name)
        previewButton.widget.vehicleText:SetText(vehicleName)
        previewButton.widget.statusText:SetText(status)
        previewButton.widget.statusTextFrame:Show()

        previewButton.widget.nameText:SetFont(CELL_FONT_NAME:GetFont(), selectedLayoutTable["font"]["name"])
        previewButton.widget.vehicleText:SetFont(CELL_FONT_STATUS:GetFont(), selectedLayoutTable["font"]["status"])
        previewButton.widget.statusText:SetFont(CELL_FONT_STATUS:GetFont(), selectedLayoutTable["font"]["status"])

        previewButton:SetScript("OnSizeChanged", function(self)
            F:UpdateTextWidth(self.widget.nameText, name)
			F:UpdateTextWidth(self.widget.vehicleText, vehicleName)
        end)
    end

    if not which or which == "texture" then
        previewButton.widget.healthBar:SetStatusBarTexture(Cell.vars.texture)
        previewButton.widget.powerBar:SetStatusBarTexture(Cell.vars.texture)
    end
    
    if not which or which == "size" then
        previewButton:SetSize(unpack(selectedLayoutTable["size"]))
    end

    if not which or which == "power" then
        previewButton.func.SetPowerHeight(selectedLayoutTable["powerHeight"])
    end

    local flags
    if CellDB["appearance"]["outline"] == "Outline" then
        flags = "OUTLINE"
    elseif CellDB["appearance"]["outline"] == "Monochrome Outline" then
        flags = "OUTLINE, MONOCHROME"
    end    

    if not which or which == "font" or which == "nameFont" then
        previewButton.widget.nameText:SetFont(CELL_FONT_NAME:GetFont(), value or selectedLayoutTable["font"]["name"], flags)
        previewButton:GetScript("OnSizeChanged")(previewButton)
    end
    
    if not which or which == "font" or which == "statusFont" then
        previewButton.widget.vehicleText:SetFont(CELL_FONT_NAME:GetFont(), value or selectedLayoutTable["font"]["status"], flags)
        previewButton.widget.statusText:SetFont(CELL_FONT_NAME:GetFont(), value or selectedLayoutTable["font"]["status"], flags)
        previewButton:GetScript("OnSizeChanged")(previewButton)
    end

    if not which or which == "textWidth" then
        previewButton:GetScript("OnSizeChanged")(previewButton)
    end
end

-------------------------------------------------
-- layout preview
-------------------------------------------------
local previewMode = 0
local layoutPreview = Cell:CreateFrame("CellLayoutPreviewFrame", Cell.frames.mainFrame, nil, nil, true)
layoutPreview:EnableMouse(false)
layoutPreview:SetFrameStrata("MEDIUM")
layoutPreview:SetToplevel(true)
layoutPreview:Hide()

local layoutPreviewAnchor = CreateFrame("Frame", "CellLayoutPreviewAnchorFrame", layoutPreview, "BackdropTemplate")
-- layoutPreviewAnchor:SetPoint("TOPLEFT", UIParent, "CENTER")
layoutPreviewAnchor:SetSize(20, 10)
layoutPreviewAnchor:SetMovable(true)
layoutPreviewAnchor:EnableMouse(true)
layoutPreviewAnchor:RegisterForDrag("LeftButton")
layoutPreviewAnchor:SetClampedToScreen(true)
Cell:StylizeFrame(layoutPreviewAnchor, {0, 1, 0, .4})
layoutPreviewAnchor:Hide()
layoutPreviewAnchor:SetScript("OnDragStart", function()
    layoutPreviewAnchor:StartMoving()
    layoutPreviewAnchor:SetUserPlaced(false)
end)
layoutPreviewAnchor:SetScript("OnDragStop", function()
    layoutPreviewAnchor:StopMovingOrSizing()
    LPP:SavePixelPerfectPosition(layoutPreviewAnchor, selectedLayoutTable["position"])
end)

local layoutPreviewName = layoutPreviewAnchor:CreateFontString(nil, "OVERLAY")
layoutPreviewName:SetFont(GameFontNormal:GetFont(), 14, "OUTLINE")
layoutPreviewName:SetShadowOffset(0, 0)
Cell:ColorFontStringByPlayerClass(layoutPreviewName)

-- init raid preview
do
    layoutPreview.fadeIn = layoutPreview:CreateAnimationGroup()
    local fadeIn = layoutPreview.fadeIn:CreateAnimation("alpha")
    fadeIn:SetFromAlpha(0)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(.5)
    fadeIn:SetSmoothing("OUT")
    fadeIn:SetScript("OnPlay", function()
        layoutPreview:Show()
    end)
    
    layoutPreview.fadeOut = layoutPreview:CreateAnimationGroup()
    local fadeOut = layoutPreview.fadeOut:CreateAnimation("alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(0.5)
    fadeOut:SetSmoothing("IN")
    fadeOut:SetScript("OnFinished", function()
        layoutPreview:Hide()
    end)

    local desaturation = {
        [1] = 1,
        [2] = .9,
        [3] = .8,
        [4] = .7,
        [5] = .6,
    }

    for i = 1, 40 do
        layoutPreview[i] = layoutPreview:CreateTexture(nil, "ARTWORK")
        layoutPreview[i]:SetTexture("Interface\\Buttons\\WHITE8x8")

        layoutPreview[i].bg = layoutPreview:CreateTexture(nil, "BACKGROUND")
        layoutPreview[i].bg:SetColorTexture(0, 0, 0)
        layoutPreview[i].bg:SetAlpha(.555)
        layoutPreview[i].bg:SetSize(30, 20)
        
        layoutPreview[i]:SetPoint("TOPLEFT", layoutPreview[i].bg, 1, -1)
        layoutPreview[i]:SetPoint("BOTTOMRIGHT", layoutPreview[i].bg, -1, 1)
        
        if i <= 5 then
            layoutPreview[i]:SetVertexColor(F:ConvertRGB(255, 0, 0, 1, desaturation[i])) -- Red
        elseif i <= 10 then
            layoutPreview[i]:SetVertexColor(F:ConvertRGB(255, 127, 0, 1, desaturation[i-5])) -- Orange
        elseif i <= 15 then
            layoutPreview[i]:SetVertexColor(F:ConvertRGB(255, 255, 0, 1, desaturation[i-10])) -- Yellow
        elseif i <= 20 then
            layoutPreview[i]:SetVertexColor(F:ConvertRGB(0, 255, 0, 1, desaturation[i-15])) -- Green
        elseif i <= 25 then
            layoutPreview[i]:SetVertexColor(F:ConvertRGB(0, 127, 255, 1, desaturation[i-20])) -- Blue
        elseif i <= 30 then
            layoutPreview[i]:SetVertexColor(F:ConvertRGB(127, 0, 255, 1, desaturation[i-25])) -- Indigo
        elseif i <= 35 then
            layoutPreview[i]:SetVertexColor(F:ConvertRGB(238, 130, 238, 1, desaturation[i-30])) -- Violet
        else
            layoutPreview[i]:SetVertexColor(F:ConvertRGB(255, 255, 255, 1, desaturation[i-35])) -- White
        end
        layoutPreview[i]:SetAlpha(.555)
    end
end

layoutsTab:SetScript("OnHide", function()
    if layoutPreview.timer then
        layoutPreview.timer:Cancel()
        layoutPreview.timer = nil
    end
    if layoutPreview.fadeIn:IsPlaying() then
        layoutPreview.fadeIn:Stop()
    end
    if not layoutPreview.fadeOut:IsPlaying() then
        layoutPreview.fadeOut:Play()
    end
end)

local function UpdateLayoutPreview()
    local n
    if previewMode == 1 then
        n = 5
    else
        n = 40
    end

    -- update layoutPreview point
    layoutPreview:SetSize(unpack(selectedLayoutTable["size"]))
    layoutPreview:ClearAllPoints()
    layoutPreviewName:ClearAllPoints()
    if selectedLayoutTable["anchor"] == "BOTTOMLEFT" then
        layoutPreview:SetPoint("BOTTOMLEFT", layoutPreviewAnchor, "TOPLEFT", 0, 4)
        layoutPreviewName:SetPoint("LEFT", layoutPreviewAnchor, "RIGHT", 5, 0)
    elseif selectedLayoutTable["anchor"] == "BOTTOMRIGHT" then
        layoutPreview:SetPoint("BOTTOMRIGHT", layoutPreviewAnchor, "TOPRIGHT", 0, 4)
        layoutPreviewName:SetPoint("RIGHT", layoutPreviewAnchor, "LEFT", -5, 0)
    elseif selectedLayoutTable["anchor"] == "TOPLEFT" then
        layoutPreview:SetPoint("TOPLEFT", layoutPreviewAnchor, "BOTTOMLEFT", 0, -4)
        layoutPreviewName:SetPoint("LEFT", layoutPreviewAnchor, "RIGHT", 5, 0)
    elseif selectedLayoutTable["anchor"] == "TOPRIGHT" then
        layoutPreview:SetPoint("TOPRIGHT", layoutPreviewAnchor, "BOTTOMRIGHT", 0, -4)
        layoutPreviewName:SetPoint("RIGHT", layoutPreviewAnchor, "LEFT", -5, 0)
    end

    -- update layoutPreviewAnchor point
    if selectedLayout == Cell.vars.currentLayout then
        layoutPreviewAnchor:SetAllPoints(Cell.frames.anchorFrame)
        layoutPreviewAnchor:Hide()
        layoutPreviewName:Hide()
    else
        if #selectedLayoutTable["position"] == 2 then
            LPP:LoadPixelPerfectPosition(layoutPreviewAnchor, selectedLayoutTable["position"])
        else
            layoutPreviewAnchor:ClearAllPoints()
            layoutPreviewAnchor:SetPoint("TOPLEFT", UIParent, "CENTER")
        end
        layoutPreviewAnchor:Show()
        layoutPreviewName:SetText(L["Layout"]..": "..selectedLayout)
        layoutPreviewName:Show()
    end

    -- re-arrange
    for i = 1, n do
        layoutPreview[i].bg:SetSize(unpack(selectedLayoutTable["size"]))
        layoutPreview[i].bg:ClearAllPoints()

        local spacing = selectedLayoutTable["spacing"]
        
        if selectedLayoutTable["orientation"] == "vertical" then
            -- anchor
            local point, anchorPoint, groupAnchorPoint, unitSpacing, groupSpacing, verticalSpacing
            if selectedLayoutTable["anchor"] == "BOTTOMLEFT" then
                point, anchorPoint, groupAnchorPoint = "BOTTOMLEFT", "TOPLEFT", "BOTTOMRIGHT"
                unitSpacing = spacing
                groupSpacing = spacing
                verticalSpacing = spacing+selectedLayoutTable["groupSpacing"]
            elseif selectedLayoutTable["anchor"] == "BOTTOMRIGHT" then
                point, anchorPoint, groupAnchorPoint = "BOTTOMRIGHT", "TOPRIGHT", "BOTTOMLEFT"
                unitSpacing = spacing
                groupSpacing = -spacing
                verticalSpacing = spacing+selectedLayoutTable["groupSpacing"]
            elseif selectedLayoutTable["anchor"] == "TOPLEFT" then
                point, anchorPoint, groupAnchorPoint = "TOPLEFT", "BOTTOMLEFT", "TOPRIGHT"
                unitSpacing = -spacing
                groupSpacing = spacing
                verticalSpacing = -spacing-selectedLayoutTable["groupSpacing"]
            elseif selectedLayoutTable["anchor"] == "TOPRIGHT" then
                point, anchorPoint, groupAnchorPoint = "TOPRIGHT", "BOTTOMRIGHT", "TOPLEFT"
                unitSpacing = -spacing
                groupSpacing = -spacing
                verticalSpacing = -spacing-selectedLayoutTable["groupSpacing"]
            end

            if i == 1 then
                layoutPreview[i].bg:SetPoint(point)
            elseif i % 5 == 1 then -- another party
                local lastColumn = math.modf(i / 5)
                local currentColumn = lastColumn + 1
                if lastColumn % selectedLayoutTable["columns"] == 0 then
                    local index = (currentColumn - selectedLayoutTable["columns"]) * 5 -- find anchor
                    layoutPreview[i].bg:SetPoint(point, layoutPreview[index].bg, anchorPoint, 0, verticalSpacing)
                else
                    layoutPreview[i].bg:SetPoint(point, layoutPreview[i-5].bg, groupAnchorPoint, groupSpacing, 0)
                end
            else
                layoutPreview[i].bg:SetPoint(point, layoutPreview[i-1].bg, anchorPoint, 0, unitSpacing)
            end
        else
            -- anchor
            local point, anchorPoint, groupAnchorPoint, unitSpacing, groupSpacing, horizontalSpacing
            if selectedLayoutTable["anchor"] == "BOTTOMLEFT" then
                point, anchorPoint, groupAnchorPoint = "BOTTOMLEFT", "BOTTOMRIGHT", "TOPLEFT"
                unitSpacing = spacing
                groupSpacing = spacing
                horizontalSpacing = spacing+selectedLayoutTable["groupSpacing"]
            elseif selectedLayoutTable["anchor"] == "BOTTOMRIGHT" then
                point, anchorPoint, groupAnchorPoint = "BOTTOMRIGHT", "BOTTOMLEFT", "TOPRIGHT"
                unitSpacing = -spacing
                groupSpacing = spacing
                horizontalSpacing = -spacing-selectedLayoutTable["groupSpacing"]
            elseif selectedLayoutTable["anchor"] == "TOPLEFT" then
                point, anchorPoint, groupAnchorPoint = "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT"
                unitSpacing = spacing
                groupSpacing = -spacing
                horizontalSpacing = spacing+selectedLayoutTable["groupSpacing"]
            elseif selectedLayoutTable["anchor"] == "TOPRIGHT" then
                point, anchorPoint, groupAnchorPoint = "TOPRIGHT", "TOPLEFT", "BOTTOMRIGHT"
                unitSpacing = -spacing
                groupSpacing = -spacing
                horizontalSpacing = -spacing-selectedLayoutTable["groupSpacing"]
            end

            if i == 1 then
                layoutPreview[i].bg:SetPoint(point)
            elseif i % 5 == 1 then -- another party
                local lastRow = math.modf(i / 5)
                local currentRow = lastRow + 1
                if lastRow % selectedLayoutTable["rows"] == 0 then
                    local index = (currentRow - selectedLayoutTable["rows"]) * 5 -- find anchor
                    layoutPreview[i].bg:SetPoint(point, layoutPreview[index].bg, anchorPoint, horizontalSpacing, 0)
                else
                    layoutPreview[i].bg:SetPoint(point, layoutPreview[i-5].bg, groupAnchorPoint, 0, groupSpacing)
                end
            else
                layoutPreview[i].bg:SetPoint(point, layoutPreview[i-1].bg, anchorPoint, unitSpacing, 0)
            end
        end

        layoutPreview[i]:Show()
        layoutPreview[i].bg:Show()
    end

    -- update group filter
    if previewMode ~= 1 then
        for i = 1, 40 do
            if i / 5 <= 1 then -- party1
                if not selectedLayoutTable["groupFilter"][1] then
                    layoutPreview[i]:Hide()
                    layoutPreview[i].bg:Hide()
                end
            elseif i / 5 <= 2 then -- party2
                if not selectedLayoutTable["groupFilter"][2] then
                    layoutPreview[i]:Hide()
                    layoutPreview[i].bg:Hide()
                end
            elseif i / 5 <= 3 then -- party3
                if not selectedLayoutTable["groupFilter"][3] then
                    layoutPreview[i]:Hide()
                    layoutPreview[i].bg:Hide()
                end
            elseif i / 5 <= 4 then -- party4
                if not selectedLayoutTable["groupFilter"][4] then
                    layoutPreview[i]:Hide()
                    layoutPreview[i].bg:Hide()
                end
            elseif i / 5 <= 5 then -- party5
                if not selectedLayoutTable["groupFilter"][5] then
                    layoutPreview[i]:Hide()
                    layoutPreview[i].bg:Hide()
                end
            elseif i / 5 <= 6 then -- party6
                if not selectedLayoutTable["groupFilter"][6] then
                    layoutPreview[i]:Hide()
                    layoutPreview[i].bg:Hide()
                end
            elseif i / 5 <= 7 then -- party7
                if not selectedLayoutTable["groupFilter"][7] then
                    layoutPreview[i]:Hide()
                    layoutPreview[i].bg:Hide()
                end
            else -- party8
                if not selectedLayoutTable["groupFilter"][8] then
                    layoutPreview[i]:Hide()
                    layoutPreview[i].bg:Hide()
                end
            end
        end
    else -- party preview
        for i = 6, 40 do
            layoutPreview[i]:Hide()
            layoutPreview[i].bg:Hide()
        end
    end

    if layoutPreview.fadeIn:IsPlaying() then
        layoutPreview.fadeIn:Restart()
    else
        layoutPreview.fadeIn:Play()
    end
    
    if layoutPreview.fadeOut:IsPlaying() then
        layoutPreview.fadeOut:Stop()
    end

    if layoutPreview.timer then
        layoutPreview.timer:Cancel()
    end

    if previewMode == 0 then
        layoutPreview.timer = C_Timer.NewTimer(1, function()
            layoutPreview.fadeOut:Play()
            layoutPreview.timer = nil
        end)
    else

    end
end

-------------------------------------------------
-- layout
-------------------------------------------------
local layoutDropdown, partyDropdown, raidDropdown, bg15Dropdown, bg40Dropdown
local LoadLayoutDropdown, LoadAutoSwitchDropdowns
local LoadLayoutDB, UpdateButtonStates

local layoutText = Cell:CreateSeparator(L["Layout"], layoutsTab, 387)
layoutText:SetPoint("TOPLEFT", 5, -5)

local enabledLayoutText = layoutsTab:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET_TITLE")
enabledLayoutText:SetPoint("LEFT", layoutText, "RIGHT", 5, 0)
enabledLayoutText:SetJustifyH("LEFT")

local function UpdateEnabledLayoutText()
    enabledLayoutText:SetText("|cFF777777"..L["Currently Enabled"]..": "..(Cell.vars.currentLayout == "default" and _G.DEFAULT or Cell.vars.currentLayout))
end

-- drop down
layoutDropdown = Cell:CreateDropdown(layoutsTab, 160)
layoutDropdown:SetPoint("TOPLEFT", layoutText, "BOTTOMLEFT", 5, -12)

LoadLayoutDropdown = function()
    local indices = {}
    for name, _ in pairs(CellDB["layouts"]) do
        if name ~= "default" then
            tinsert(indices, name)
        end
    end
    table.sort(indices)
    tinsert(indices, 1, "default") -- make default first

    local items = {}
    for _, value in pairs(indices) do
        table.insert(items, {
            ["text"] = value == "default" and _G.DEFAULT or value,
            ["onClick"] = function()
                LoadLayoutDB(value)
                UpdateButtonStates()
            end,
        })
    end
    layoutDropdown:SetItems(items)
end

-- mask
Cell:CreateMask(layoutsTab, nil, {1, -1, -1, 1})
layoutsTab.mask:Hide()

-- applyToAll
-- local applyToAllBtn = Cell:CreateButton(layoutsTab, L["Apply to All"], "class-hover", {70, 20})
-- applyToAllBtn:SetPoint("LEFT", layoutDropdown, "RIGHT", 10, 0)
-- applyToAllBtn:SetScript("OnClick", function()
--     -- update db
--     CellCharacterDB["party"] = selectedLayout
--     CellCharacterDB["raid"] = selectedLayout
--     CellCharacterDB["battleground15"] = selectedLayout
--     CellCharacterDB["battleground40"] = selectedLayout

--     -- update dropdown
--     partyDropdown:SetSelected(selectedLayout)
--     raidDropdown:SetSelected(selectedLayout)
--     bg15Dropdown:SetSelected(selectedLayout)
--     bg40Dropdown:SetSelected(selectedLayout)

--     -- apply
--     F:UpdateLayout("party")
--     Cell:Fire("UpdateAppearance", "font") -- update text size
--     Cell:Fire("UpdateIndicators")
--     UpdateButtonStates()
--     UpdateEnabledLayoutText()
-- end)
-- Cell:RegisterForCloseDropdown(applyToAllBtn)

-- new
local newBtn = Cell:CreateButton(layoutsTab, L["New"], "class-hover", {55, 20})
newBtn:SetPoint("LEFT", layoutDropdown, "RIGHT", 10, 0)
newBtn:SetScript("OnClick", function()
    local popup = Cell:CreateConfirmPopup(layoutsTab, 200, L["Create new layout"].."\n"..L["(based on current)"], function(self)
        local name = strtrim(self.editBox:GetText())
        if name ~= "" and not CellDB["layouts"][name] then
            -- update db copy current layout
            CellDB["layouts"][name] = F:Copy(CellDB["layouts"][Cell.vars.currentLayout])
            -- update dropdown
            layoutDropdown:AddItem({
                ["text"] = name,
                ["onClick"] = function()
                    LoadLayoutDB(name)
                    UpdateButtonStates()
                end,
            })
            layoutDropdown:SetSelected(name)
            LoadAutoSwitchDropdowns()
            LoadLayoutDB(name)
            UpdateButtonStates()
            F:Print(L["Layout added: "]..name..".")
        else
            F:Print(L["Invalid layout name."])
        end
    end, true, true)
    popup:SetPoint("TOPLEFT", 100, -70)
end)
Cell:RegisterForCloseDropdown(newBtn)

-- rename
local renameBtn = Cell:CreateButton(layoutsTab, L["Rename"], "class-hover", {55, 20})
renameBtn:SetPoint("LEFT", newBtn, "RIGHT", -1, 0)
renameBtn:SetScript("OnClick", function()
    local popup = Cell:CreateConfirmPopup(layoutsTab, 200, L["Rename layout"].." "..selectedLayout, function(self)
        local name = strtrim(self.editBox:GetText())
        if name ~= "" and not CellDB["layouts"][name] then
            -- update db
            CellDB["layouts"][name] = F:Copy(CellDB["layouts"][selectedLayout])
            CellDB["layouts"][selectedLayout] = nil
            -- check auto switch related
            if CellCharacterDB["party"] == selectedLayout then CellCharacterDB["party"] = name end
            if CellCharacterDB["raid"] == selectedLayout then CellCharacterDB["raid"] = name end
            if CellCharacterDB["battleground15"] == selectedLayout then CellCharacterDB["battleground15"] = name end
            if CellCharacterDB["battleground40"] == selectedLayout then CellCharacterDB["battleground40"] = name end
            
            -- check current
            if selectedLayout == Cell.vars.currentLayout then
                -- update vars
                Cell.vars.currentLayout = name
                Cell.vars.currentLayoutTable = CellDB["layouts"][name]
                -- update text
                UpdateEnabledLayoutText()
            end

            -- update dropdown
            layoutDropdown:SetCurrentItem({
                ["text"] = name,
                ["onClick"] = function()
                    LoadLayoutDB(name)
                    UpdateButtonStates()
                end,
            })
            layoutDropdown:SetSelected(name)
            
            F:Print(L["Layout renamed: "].." "..selectedLayout.." "..L["to"].." "..name..".")

            -- reload
            LoadAutoSwitchDropdowns()
            LoadLayoutDB(name)
        else
            F:Print(L["Invalid layout name."])
        end
    end, true, true)
    popup:SetPoint("TOPLEFT", 100, -185)
end)
Cell:RegisterForCloseDropdown(renameBtn)

-- delete
local deleteBtn = Cell:CreateButton(layoutsTab, L["Delete"], "class-hover", {55, 20})
deleteBtn:SetPoint("LEFT", renameBtn, "RIGHT", -1, 0)
deleteBtn:SetScript("OnClick", function()
    local popup = Cell:CreateConfirmPopup(layoutsTab, 200, L["Delete layout"].." "..selectedLayout.."?", function(self)
        -- update db
        CellDB["layouts"][selectedLayout] = nil
        F:Print(L["Layout deleted: "]..selectedLayout..".")
        -- check auto switch related
        if CellCharacterDB["party"] == selectedLayout then CellCharacterDB["party"] = "default" end
        if CellCharacterDB["raid"] == selectedLayout then CellCharacterDB["raid"] = "default" end
        if CellCharacterDB["battleground15"] == selectedLayout then CellCharacterDB["battleground15"] = "default" end
        if CellCharacterDB["battleground40"] == selectedLayout then CellCharacterDB["battleground40"] = "default" end

        -- set current to default
        if selectedLayout == Cell.vars.currentLayout then
            -- update vars
            Cell.vars.currentLayout = "default"
            Cell.vars.currentLayoutTable = CellDB["layouts"]["default"]
            Cell:Fire("UpdateLayout", "default")
            -- update text
            UpdateEnabledLayoutText()
        end

        -- update dropdown
        layoutDropdown:RemoveCurrentItem()
        layoutDropdown:SetSelected(_G.DEFAULT)

        -- reload
        LoadAutoSwitchDropdowns()
        LoadLayoutDB("default")
        UpdateButtonStates()
    end, true)
    popup:SetPoint("TOPLEFT", 100, -185)
end)
Cell:RegisterForCloseDropdown(deleteBtn)

UpdateButtonStates = function()
    -- if selectedLayout == CellCharacterDB["party"]
    -- and selectedLayout == CellCharacterDB["raid"]
    -- and selectedLayout == CellCharacterDB["battleground15"]
    -- and selectedLayout == CellCharacterDB["battleground40"] then
    --     applyToAllBtn:SetEnabled(false)
    -- else
    --     applyToAllBtn:SetEnabled(true)
    -- end

    if selectedLayout == "default" then
        deleteBtn:SetEnabled(false)
        renameBtn:SetEnabled(false)
    else
        deleteBtn:SetEnabled(true)
        renameBtn:SetEnabled(true)
    end
end

-------------------------------------------------
-- layout auto switch
-------------------------------------------------
-- local autoSwitchText = Cell:CreateSeparator(L["Layout Auto Switch"], layoutsTab, 387)
-- autoSwitchText:SetPoint("TOPLEFT", 5, -65)

-- party
partyDropdown = Cell:CreateDropdown(layoutsTab, 85)
partyDropdown:SetPoint("TOPLEFT", layoutDropdown, "BOTTOMLEFT", 0, -27)

local partyText = layoutsTab:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
partyText:SetPoint("BOTTOMLEFT", partyDropdown, "TOPLEFT", 0, 1)
partyText:SetText(L["Solo/Party"])

-- raid
raidDropdown = Cell:CreateDropdown(layoutsTab, 85)
raidDropdown:SetPoint("LEFT", partyDropdown, "RIGHT", 10, 0)

local raidText = layoutsTab:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
raidText:SetPoint("BOTTOMLEFT", raidDropdown, "TOPLEFT", 0, 1)
raidText:SetText(L["Raid"])

-- battleground 15
bg15Dropdown = Cell:CreateDropdown(layoutsTab, 85)
bg15Dropdown:SetPoint("LEFT", raidDropdown, "RIGHT", 10, 0)

local bg15Text = layoutsTab:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
bg15Text:SetPoint("BOTTOMLEFT", bg15Dropdown, "TOPLEFT", 0, 1)
bg15Text:SetText(L["BG 1-15"])

-- battleground 40
bg40Dropdown = Cell:CreateDropdown(layoutsTab, 85)
bg40Dropdown:SetPoint("LEFT", bg15Dropdown, "RIGHT", 10, 0)

local bg40Text = layoutsTab:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
bg40Text:SetPoint("BOTTOMLEFT", bg40Dropdown, "TOPLEFT", 0, 1)
bg40Text:SetText(L["BG 16-40"])

LoadAutoSwitchDropdowns = function()
    local indices = {}
    for name, _ in pairs(CellDB["layouts"]) do
        if name ~= "default" then
            tinsert(indices, name)
        end
    end
    table.sort(indices)
    tinsert(indices, 1, "default") -- make default first

    -- partyDropdown
    local partyItems = {}
    for _, value in pairs(indices) do
        table.insert(partyItems, {
            ["text"] = value == "default" and _G.DEFAULT or value,
            ["onClick"] = function()
                CellCharacterDB["party"] = value
                if not Cell.vars.inBattleground and Cell.vars.groupType == "solo" or Cell.vars.groupType == "party" then
                    F:UpdateLayout("party")
                    Cell:Fire("UpdateAppearance", "font") -- update text size
                    Cell:Fire("UpdateIndicators")
                    LoadLayoutDB(Cell.vars.currentLayout)
                    UpdateButtonStates()
                    UpdateEnabledLayoutText()
                end
            end,
        })
    end
    partyDropdown:SetItems(partyItems)

    -- raidDropdown
    local raidItems = {}
    for _, value in pairs(indices) do
        table.insert(raidItems, {
            ["text"] = value == "default" and _G.DEFAULT or value,
            ["onClick"] = function()
                CellCharacterDB["raid"] = value
                if not Cell.vars.inBattleground and Cell.vars.groupType == "raid" then
                    F:UpdateLayout("raid")
                    Cell:Fire("UpdateAppearance", "font") -- update text size
                    Cell:Fire("UpdateIndicators")
                    LoadLayoutDB(Cell.vars.currentLayout)
                    UpdateButtonStates()
                    UpdateEnabledLayoutText()
                end
            end,
        })
    end
    raidDropdown:SetItems(raidItems)

    -- bg15Dropdown
    local bg15Items = {}
    for _, value in pairs(indices) do
        table.insert(bg15Items, {
            ["text"] = value == "default" and _G.DEFAULT or value,
            ["onClick"] = function()
                CellCharacterDB["battleground15"] = value
                if Cell.vars.inBattleground == 15 then
                    F:UpdateLayout("battleground15")
                    Cell:Fire("UpdateAppearance", "font") -- update text size
                    Cell:Fire("UpdateIndicators")
                    LoadLayoutDB(Cell.vars.currentLayout)
                    UpdateButtonStates()
                    UpdateEnabledLayoutText()
                end
            end,
        })
    end
    bg15Dropdown:SetItems(bg15Items)

    -- bg40Dropdown
    local bg40Items = {}
    for _, value in pairs(indices) do
        table.insert(bg40Items, {
            ["text"] = value == "default" and _G.DEFAULT or value,
            ["onClick"] = function()
                CellCharacterDB["battleground40"] = value
                if Cell.vars.inBattleground == 40 then
                    F:UpdateLayout("battleground40")
                    Cell:Fire("UpdateAppearance", "font") -- update text size
                    Cell:Fire("UpdateIndicators")
                    LoadLayoutDB(Cell.vars.currentLayout)
                    UpdateButtonStates()
                    UpdateEnabledLayoutText()
                end
            end,
        })
    end
    bg40Dropdown:SetItems(bg40Items)
end

-------------------------------------------------
-- group filter
-------------------------------------------------
local groupFilterText = Cell:CreateSeparator(L["Group Filter"], layoutsTab, 122)
groupFilterText:SetPoint("TOPLEFT", 5, -120)

local function UpdateButtonBorderColor(flag, b)
    local borderColor 
    if flag then
        borderColor = {b.hoverColor[1], b.hoverColor[2], b.hoverColor[3], 1}
    else
        borderColor = {0, 0, 0, 1}
    end
    b:SetBackdropBorderColor(unpack(borderColor))
end

local groupButtons = {}
for i = 1, 8 do
    groupButtons[i] = Cell:CreateButton(layoutsTab, i, "class-hover", {20, 20})
    groupButtons[i]:SetScript("OnClick", function()
        selectedLayoutTable["groupFilter"][i] = not selectedLayoutTable["groupFilter"][i]
        UpdateButtonBorderColor(selectedLayoutTable["groupFilter"][i], groupButtons[i])

        if selectedLayout == Cell.vars.currentLayout then
            Cell:Fire("UpdateLayout", selectedLayout, "groupFilter")
        end
        UpdateLayoutPreview()
    end)
    
    if i == 1 then
        groupButtons[i]:SetPoint("TOPLEFT", groupFilterText, "BOTTOMLEFT", 10, -12)
    elseif i == 5 then
        groupButtons[i]:SetPoint("TOPLEFT", groupButtons[1], "BOTTOMLEFT", 0, -3)
    else
        groupButtons[i]:SetPoint("LEFT", groupButtons[i-1], "RIGHT", 3, 0)
    end
end

local function UpdateGroupFilter()
    for i = 1, 8 do
        UpdateButtonBorderColor(selectedLayoutTable["groupFilter"][i], groupButtons[i])
    end
end

-------------------------------------------------
-- group arrangement
-------------------------------------------------
local arrangementText = Cell:CreateSeparator(L["Group Arrangement"], layoutsTab, 254)
arrangementText:SetPoint("TOPLEFT", 137, -120)

-- orientation
local rcSlider, groupSpacingSlider
local orientationDropdown = Cell:CreateDropdown(layoutsTab, 80)
orientationDropdown:SetPoint("TOPLEFT", arrangementText, "BOTTOMLEFT", 5, -25)
orientationDropdown:SetItems({
    {
        ["text"] = L["Vertical"],
        ["value"] = "vertical",
        ["onClick"] = function()
            selectedLayoutTable["orientation"] = "vertical"
            if selectedLayout == Cell.vars.currentLayout then
                Cell:Fire("UpdateLayout", selectedLayout, "orientation")
            end
            rcSlider:SetName(L["Group Columns"])
            rcSlider:SetValue(selectedLayoutTable["columns"])
            if selectedLayoutTable["columns"] == 8 then
                groupSpacingSlider:SetEnabled(false)
            else
                groupSpacingSlider:SetEnabled(true)
            end
            UpdateLayoutPreview()
        end,
    },
    {
        ["text"] = L["Horizontal"],
        ["value"] = "horizontal",
        ["onClick"] = function()
            selectedLayoutTable["orientation"] = "horizontal"
            if selectedLayout == Cell.vars.currentLayout then
                Cell:Fire("UpdateLayout", selectedLayout, "orientation")
            end
            rcSlider:SetName(L["Group Rows"])
            rcSlider:SetValue(selectedLayoutTable["rows"])
            if selectedLayoutTable["rows"] == 8 then
                groupSpacingSlider:SetEnabled(false)
            else
                groupSpacingSlider:SetEnabled(true)
            end
            UpdateLayoutPreview()
        end,
    },
})

local orientationText = layoutsTab:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
orientationText:SetPoint("BOTTOMLEFT", orientationDropdown, "TOPLEFT", 0, 1)
orientationText:SetText(L["Orientation"])

-- anchor
local anchorDropdown = Cell:CreateDropdown(layoutsTab, 90)
anchorDropdown:SetPoint("LEFT", orientationDropdown, "RIGHT", 10, 0)
anchorDropdown:SetItems({
    {
        ["text"] = L["BOTTOMLEFT"],
        ["value"] = "BOTTOMLEFT",
        ["onClick"] = function()
            selectedLayoutTable["anchor"] = "BOTTOMLEFT"
            if selectedLayout == Cell.vars.currentLayout then
                Cell:Fire("UpdateLayout", selectedLayout, "anchor")
            end
            UpdateLayoutPreview()
        end,
    },
    {
        ["text"] = L["BOTTOMRIGHT"],
        ["value"] = "BOTTOMRIGHT",
        ["onClick"] = function()
            selectedLayoutTable["anchor"] = "BOTTOMRIGHT"
            if selectedLayout == Cell.vars.currentLayout then
                Cell:Fire("UpdateLayout", selectedLayout, "anchor")
            end
            UpdateLayoutPreview()
        end,
    },
    {
        ["text"] = L["TOPLEFT"],
        ["value"] = "TOPLEFT",
        ["onClick"] = function()
            selectedLayoutTable["anchor"] = "TOPLEFT"
            if selectedLayout == Cell.vars.currentLayout then
                Cell:Fire("UpdateLayout", selectedLayout, "anchor")
            end
            UpdateLayoutPreview()
        end,
    },
    {
        ["text"] = L["TOPRIGHT"],
        ["value"] = "TOPRIGHT",
        ["onClick"] = function()
            selectedLayoutTable["anchor"] = "TOPRIGHT"
            if selectedLayout == Cell.vars.currentLayout then
                Cell:Fire("UpdateLayout", selectedLayout, "anchor")
            end
            UpdateLayoutPreview()
        end,
    },
})

local anchorText = layoutsTab:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
anchorText:SetPoint("BOTTOMLEFT", anchorDropdown, "TOPLEFT", 0, 1)
anchorText:SetText(L["Anchor Point"])

-- preview mode
local previewModeBtn = Cell:CreateButton(layoutsTab, "|cff777777"..L["OFF"], "class-hover", {50, 20})
previewModeBtn:SetPoint("LEFT", anchorDropdown, "RIGHT", 10, 0)
previewModeBtn:SetScript("OnClick", function()
    previewMode = (previewMode == 2) and 0 or (previewMode + 1)

    if previewMode == 0 then
        previewModeBtn:SetText("|cff777777"..L["OFF"])
        layoutPreview.fadeOut:Play()
    elseif previewMode == 1 then
        previewModeBtn:SetText(L["Party"])
        UpdateLayoutPreview()
    else
        previewModeBtn:SetText(L["Raid"])
        UpdateLayoutPreview()
    end
end)
previewModeBtn:SetScript("OnHide", function()
    previewMode = 0
    previewModeBtn:SetText("|cff777777"..L["OFF"])
end)

local previewModeText = layoutsTab:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
previewModeText:SetPoint("BOTTOMLEFT", previewModeBtn, "TOPLEFT", 0, 1)
previewModeText:SetText(L["Preview"])

-------------------------------------------------
-- button size
-------------------------------------------------
local buttonSizeText = Cell:CreateSeparator(L["Unit Button Size"], layoutsTab, 122)
buttonSizeText:SetPoint("TOPLEFT", 5, -210)

-- width
local widthSlider = Cell:CreateSlider(L["Width"], layoutsTab, 40, 300, 100, 2, function(value)
    selectedLayoutTable["size"][1] = value
    if selectedLayout == Cell.vars.currentLayout then
        Cell:Fire("UpdateLayout", selectedLayout, "size")
    end
    UpdatePreviewButton("size")
end)
widthSlider:SetPoint("TOPLEFT", buttonSizeText, "BOTTOMLEFT", 5, -25)

-- height
local heightSlider = Cell:CreateSlider(L["Height"], layoutsTab, 20, 300, 100, 2, function(value)
    selectedLayoutTable["size"][2] = value
    if selectedLayout == Cell.vars.currentLayout then
        Cell:Fire("UpdateLayout", selectedLayout, "size")
    end
    UpdatePreviewButton("size")
end)
heightSlider:SetPoint("TOP", widthSlider, "BOTTOM", 0, -40)

-- power height
local powerHeightSlider = Cell:CreateSlider(L["Power Height"], layoutsTab, 0, 20, 100, 1, function(value)
    selectedLayoutTable["powerHeight"] = value
    if selectedLayout == Cell.vars.currentLayout then
        Cell:Fire("UpdateLayout", selectedLayout, "power")
    end
    UpdatePreviewButton("power")
end)
powerHeightSlider:SetPoint("TOP", heightSlider, "BOTTOM", 0, -40)

-------------------------------------------------
-- font size
-------------------------------------------------
local fontSizeText = Cell:CreateSeparator(L["Font Size"], layoutsTab, 122)
fontSizeText:SetPoint("TOPLEFT", 137, -210)

-- name text
local nameFontSlider = Cell:CreateSlider(L["Name"], layoutsTab, 5, 25, 100, 1, function(value)
    selectedLayoutTable["font"]["name"] = value
    if selectedLayout == Cell.vars.currentLayout then
        Cell:Fire("UpdateAppearance", "font")
    end
    UpdatePreviewButton("nameFont", value)
end)
nameFontSlider:SetPoint("TOPLEFT", fontSizeText, "BOTTOMLEFT", 5, -25)

-- status text
local statusFontSlider = Cell:CreateSlider(L["Status"], layoutsTab, 5, 25, 100, 1, function(value)
    selectedLayoutTable["font"]["status"] = value
    if selectedLayout == Cell.vars.currentLayout then
        Cell:Fire("UpdateAppearance", "font")
    end
    UpdatePreviewButton("statusFont", value)
end)
statusFontSlider:SetPoint("TOP", nameFontSlider, "BOTTOM", 0, -40)

-- textWidth
local textWidthDropdown = Cell:CreateDropdown(layoutsTab, 100)
textWidthDropdown:SetPoint("TOPLEFT", statusFontSlider, "BOTTOMLEFT", 0, -40)
textWidthDropdown:SetItems({
    {
        ["text"] = L["Unlimited"],
        ["onClick"] = function()
            selectedLayoutTable["textWidth"] = 0
            if selectedLayout == Cell.vars.currentLayout then
                Cell:Fire("UpdateLayout", selectedLayout, "textWidth")
            end
            UpdatePreviewButton("textWidth")
        end,
    },
    {
        ["text"] = "100%",
        ["onClick"] = function()
            selectedLayoutTable["textWidth"] = 1
            if selectedLayout == Cell.vars.currentLayout then
                Cell:Fire("UpdateLayout", selectedLayout, "textWidth")
            end
            UpdatePreviewButton("textWidth")
        end,
    },
    {
        ["text"] = "75%",
        ["onClick"] = function()
            selectedLayoutTable["textWidth"] = .75
            if selectedLayout == Cell.vars.currentLayout then
                Cell:Fire("UpdateLayout", selectedLayout, "textWidth")
            end
            UpdatePreviewButton("textWidth")
        end,
    },
    {
        ["text"] = "50%",
        ["onClick"] = function()
            selectedLayoutTable["textWidth"] = .5
            if selectedLayout == Cell.vars.currentLayout then
                Cell:Fire("UpdateLayout", selectedLayout, "textWidth")
            end
            UpdatePreviewButton("textWidth")
        end,
    },
})
textWidthDropdown:HookScript("OnEnter", function()
    CellTooltip:SetOwner(textWidthDropdown, "ANCHOR_NONE")
    CellTooltip:SetPoint("LEFT", textWidthDropdown, "RIGHT", 1, 0)
    CellTooltip:AddLine(L["Set Text Width\n|cffffffffCompare with unitbutton's width"])
    CellTooltip:Show()
end)
textWidthDropdown:HookScript("OnLeave", function()
    CellTooltip:Hide()
end)

local widthText = textWidthDropdown:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
widthText:SetText(L["Text Width"])
widthText:SetPoint("BOTTOM", textWidthDropdown, "TOP", 0, 2)

-------------------------------------------------
-- misc
-------------------------------------------------
local miscText = Cell:CreateSeparator(L["Misc"], layoutsTab, 122)
miscText:SetPoint("TOPLEFT", 269, -210)

-- spacing
local spacingSlider = Cell:CreateSlider(L["Unit Spacing"], layoutsTab, 0, 10, 100, 1, function(value)
    selectedLayoutTable["spacing"] = value
    if selectedLayout == Cell.vars.currentLayout then
        Cell:Fire("UpdateLayout", selectedLayout, "spacing")
    end
    -- preview
    UpdateLayoutPreview()
end)
spacingSlider:SetPoint("TOPLEFT", miscText, "BOTTOMLEFT", 5, -25)

-- rows/columns
rcSlider = Cell:CreateSlider("", layoutsTab, 1, 8, 100, 1, function(value)
    if selectedLayoutTable["orientation"] == "vertical" then
        selectedLayoutTable["columns"] = value
    else -- horizontal
        selectedLayoutTable["rows"] = value
    end
    if value == 8 then
        groupSpacingSlider:SetEnabled(false)
    else
        groupSpacingSlider:SetEnabled(true)
    end
    if selectedLayout == Cell.vars.currentLayout then
        Cell:Fire("UpdateLayout", selectedLayout, "rows_columns")
    end
    -- preview
    UpdateLayoutPreview()
end)
rcSlider:SetPoint("TOPLEFT", spacingSlider, "BOTTOMLEFT", 0, -40)

-- group spacing
groupSpacingSlider = Cell:CreateSlider(L["Group Spacing"], layoutsTab, 0, 10, 100, 1, function(value)
    selectedLayoutTable["groupSpacing"] = value
    if selectedLayout == Cell.vars.currentLayout then
        Cell:Fire("UpdateLayout", selectedLayout, "groupSpacing")
    end
    -- preview
    UpdateLayoutPreview()
end)
groupSpacingSlider:SetPoint("TOPLEFT", rcSlider, "BOTTOMLEFT", 0, -40)

-------------------------------------------------
-- tips
-------------------------------------------------
local tipsText = layoutsTab:CreateFontString(nil, "OVERLAY", "CELL_FONT_WIDGET")
tipsText:SetPoint("BOTTOMLEFT", 5, 5)
tipsText:SetText("|cff777777"..L["Tip: Every layout has its own position setting."])

-------------------------------------------------
-- functions
-------------------------------------------------
LoadLayoutDB = function(layout)
    F:Debug("LoadLayoutDB: "..layout)

    selectedLayout = layout
    selectedLayoutTable = CellDB["layouts"][layout]

    layoutDropdown:SetSelected(selectedLayout == "default" and _G.DEFAULT or selectedLayout)
    partyDropdown:SetSelected(CellCharacterDB["party"] == "default" and _G.DEFAULT or CellCharacterDB["party"])
    raidDropdown:SetSelected(CellCharacterDB["raid"] == "default" and _G.DEFAULT or CellCharacterDB["raid"])
    bg15Dropdown:SetSelected(CellCharacterDB["battleground15"] == "default" and _G.DEFAULT or CellCharacterDB["battleground15"])
    bg40Dropdown:SetSelected(CellCharacterDB["battleground40"] == "default" and _G.DEFAULT or CellCharacterDB["battleground40"])

    widthSlider:SetValue(selectedLayoutTable["size"][1])
    heightSlider:SetValue(selectedLayoutTable["size"][2])
    powerHeightSlider:SetValue(selectedLayoutTable["powerHeight"])

    nameFontSlider:SetValue(selectedLayoutTable["font"]["name"])
    statusFontSlider:SetValue(selectedLayoutTable["font"]["status"])
    if selectedLayoutTable["textWidth"] == 0 then
        textWidthDropdown:SetSelectedItem(1)
    elseif selectedLayoutTable["textWidth"] == 1 then
        textWidthDropdown:SetSelectedItem(2)
    elseif selectedLayoutTable["textWidth"] == .75 then
        textWidthDropdown:SetSelectedItem(3)
    elseif selectedLayoutTable["textWidth"] == .50 then
        textWidthDropdown:SetSelectedItem(4)
    end
    
    spacingSlider:SetValue(selectedLayoutTable["spacing"])
    
    if selectedLayoutTable["orientation"] == "vertical" then
        rcSlider:SetName(L["Group Columns"])
        rcSlider:SetValue(selectedLayoutTable["columns"])
        if selectedLayoutTable["columns"] == 8 then
            groupSpacingSlider:SetEnabled(false)
        else
            groupSpacingSlider:SetEnabled(true)
        end
    else
        rcSlider:SetName(L["Group Rows"])
        rcSlider:SetValue(selectedLayoutTable["rows"])
        if selectedLayoutTable["rows"] == 8 then
            groupSpacingSlider:SetEnabled(false)
        else
            groupSpacingSlider:SetEnabled(true)
        end
    end
    groupSpacingSlider:SetValue(selectedLayoutTable["groupSpacing"])

    -- group arrangement
    orientationDropdown:SetSelectedValue(selectedLayoutTable["orientation"])
    anchorDropdown:SetSelectedValue(selectedLayoutTable["anchor"])

    UpdateGroupFilter()
    UpdatePreviewButton()
    UpdateLayoutPreview()
end

local loaded
local function ShowTab(tab)
    if tab == "layouts" then
        layoutsTab:Show()
        
        if not loaded then
            LoadLayoutDropdown()
            LoadAutoSwitchDropdowns()
        end
        
        UpdateEnabledLayoutText()

        if selectedLayout ~= Cell.vars.currentLayout then
            LoadLayoutDB(Cell.vars.currentLayout)
        end
        UpdateButtonStates()
    else
        layoutsTab:Hide()
    end
end
Cell:RegisterCallback("ShowOptionsTab", "LayoutsTab_ShowTab", ShowTab)

local function UpdateLayout()
    if Cell.vars.inBattleground then
        if Cell.vars.inBattleground == 15 then
            partyText:SetText(L["Solo/Party"])
            raidText:SetText(L["Raid"])
            bg15Text:SetText(Cell:GetPlayerClassColorString()..L["BG 1-15"].."*")
            bg40Text:SetText(L["BG 16-40"])
        else -- 40
            partyText:SetText(L["Solo/Party"])
            raidText:SetText(L["Raid"])
            bg15Text:SetText(L["BG 1-15"])
            bg40Text:SetText(Cell:GetPlayerClassColorString()..L["BG 16-40"].."*")
        end
    else
        if Cell.vars.groupType == "solo" or Cell.vars.groupType == "party" then
            partyText:SetText(Cell:GetPlayerClassColorString()..L["Solo/Party"].."*")
            raidText:SetText(L["Raid"])
            bg15Text:SetText(L["BG 1-15"])
            bg40Text:SetText(L["BG 16-40"])
        else
            partyText:SetText(L["Solo/Party"])
            raidText:SetText(Cell:GetPlayerClassColorString()..L["Raid"].."*")
            bg15Text:SetText(L["BG 1-15"])
            bg40Text:SetText(L["BG 16-40"])
        end
    end
end
Cell:RegisterCallback("UpdateLayout", "LayoutsTab_UpdateLayout", UpdateLayout)