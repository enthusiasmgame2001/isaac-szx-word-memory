local szxJson = require("szx_json")
local mod = RegisterMod("szx_beidanci_2995627879", 1)
local bsprite = Sprite()
bsprite:Load("gfx/wenda.anm2", true)

local game = Game()
local font = Font()
local function loadFont()
    local _, err = pcall(require, "")
    local _, basePathStart = string.find(err, "no file '", 1)
    local _, modPathStart = string.find(err, "no file '", basePathStart)
    local modPathEnd, _ = string.find(err, ".lua", modPathStart)
    local path = string.sub(err, modPathStart + 1, modPathEnd - 1)
    path = string.gsub(path, "\\", "/")
    path = string.gsub(path, "//", "/")
    path = string.gsub(path, ":/", ":\\")
    font:Load(path .. "resources/font/eid9/eid9_9px.fnt")
end
loadFont()

local configPosTable = {90, 20}
local menuPos = Vector(410, 165)
local menuScale = 0.06
local menuOffset = Vector(0, 0)
local menuRotation = 0
local menuDegree = 5
local radius = 500 * menuScale / math.sqrt(2)
local moveVector = Vector(2, 1.5)
local ifStuck = 0

local holdStart = false
local holdSeconds = 0
local lastFrameHoldType = 0

local strPosX = 80
local strPosY = 50
local strOffsetX = 0
local strOffsetY = 210

local instructionPosX = 265
local instructionPosY = 75
local instructionLineGap = 20

local restKeyboard = {
    32, 39, 44, 45, 46, 47, -- KEY_SPACE, KEY_APOSTROPHE, KEY_COMMA, KEY_MINUS, KEY_PERIOD, KEY_SLASH,
    48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 59, 61, -- from KEY_0 to KEY_9, KEY_SEMICOLON, KEY_EQUAL,
    91, 92, 93, 96, 161, 162, -- KEY_LEFT_BRACKET, KEY_BACKSLASH, KEY_RIGHT_BRACKET, KEY_GRAVE_ACCENT, KEY_WORLD_1, KEY_WORLD_2,
    256, 258, 260, 261, -- KEY_ESCAPE, KEY_TAB, KEY_INSERT, KEY_DELETE,
    262, 263, 264, 265, -- KEY_RIGHT, KEY_LEFT, KEY_DOWN, KEY_UP,
    266, 267, 268, 269, -- KEY_PAGE_UP, KEY_PAGE_DOWN, KEY_HOME, KEY_END,
    280, 281, 282, 283, 284, -- KEY_CAPS_LOCK, KEY_SCROLL_LOCK, KEY_NUM_LOCK, KEY_PRINT_SCREEN, KEY_PAUSE,
    290, 291, 292, 293, 294, 295, 296, 297, 298, 299, 300, 301, 302, 303, 304, 305, 306, 307, 308, 309, 310, 311, 312, 313, 314, -- from KEY_F1 to KEY_F25,
    320, 321, 322, 323, 324, 325, 326, 327, 328, 329, -- from KEY_KP_0 to KEY_KP_9,
    330, 331, 332, 333, 334, 335, 336, -- KEY_KP_DECIMAL, KEY_KP_DIVIDE, KEY_KP_MULTIPLY, KEY_KP_SUBTRACT, KEY_KP_ADD, KEY_KP_ENTER, KEY_KP_EQUAL,
    340, 341, 342, 343, -- KEY_LEFT_SHIFT, KEY_LEFT_CONTROL, KEY_LEFT_ALT, KEY_LEFT_SUPER,
    344, 345, 346, 347, 348 -- KEY_RIGHT_SHIFT, KEY_RIGHT_CONTROL, KEY_RIGHT_ALT, KEY_RIGHT_SUPER, KEY_MENU
}

local keyboardTable = {
    ["a"] = {65, false}, -- A
    ["b"] = {66, false}, -- B
    ["c"] = {67, false}, -- C
    ["d"] = {68, false}, -- D
    ["e"] = {69, false}, -- E
    ["f"] = {70, false}, -- F
    ["g"] = {71, false}, -- G
    ["h"] = {72, false}, -- H
    ["i"] = {73, false}, -- I
    ["j"] = {74, false}, -- J
    ["k"] = {75, false}, -- K
    ["l"] = {76, false}, -- L
    ["m"] = {77, false}, -- M
    ["n"] = {78, false}, -- N
    ["o"] = {79, false}, -- O
    ["p"] = {80, false}, -- P
    ["q"] = {81, false}, -- Q
    ["r"] = {82, false}, -- R
    ["s"] = {83, false}, -- S
    ["t"] = {84, false}, -- T
    ["u"] = {85, false}, -- U
    ["v"] = {86, false}, -- V
    ["w"] = {87, false}, -- W
    ["x"] = {88, false}, -- X
    ["y"] = {89, false}, -- Y
    ["z"] = {90, false}, -- Z
    ["start"] = {259}, -- backspace
    ["end"] = {257}, -- enter
    ["rest"] = restKeyboard -- the rest
}

local chuzhong = require('./szx_beidanci_constants/chuzhong')
local gaozhong = require('./szx_beidanci_constants/gaozhong')
local yasi = require('./szx_beidanci_constants/yasi')
local kaoyan = require('./szx_beidanci_constants/kaoyan')
local siji = require('./szx_beidanci_constants/siji')
local liuji = require('./szx_beidanci_constants/liuji')
local zhuanba = require('./szx_beidanci_constants/zhuanba')

local modVersion = "三只熊背单词v1.9"
local optionTitle = "选择您的答题词库："
local optionList = {"初中词库", "高中词库", "雅思词库", "考研词库", "四级词库", "六级词库", "专八词库"}
local optionNum = #optionList
local selectOption = 1
local selectedOption = 0

local taskInfo = {0, 100}
local isAnswering = false
local gameStateTbl = {
    ["INIT"] = 0,
    ["WAIT_FOR_LOADING_DATA"] = 1,
    ["RUNNING"] = 2,
    ["STATS"] = 3,
    ["END"] = 4
}
local gameState = gameStateTbl.INIT
local statsOrderMap = {
    "题库",
    "总题数 =",
    "总题数",
    "一遍独立正确作答",
    "非一遍独立正确作答",
    "使用显示答案正确作答",
    "未正确作答最终选择跳过",
    "未作答直接选择跳过"
}
local secondStatsOrderMap = {
    "使用显示答案正确作答占比",
    "(独立正确作答部分)单题平均错误次数",
    "(使用显示答案正确作答或未正确作答最终选择跳过部分)单题平均错误次数"
}
local statsTable = {
    ["题库"] = "",
    ["总题数 ="] = "一遍独立正确作答 + 非一遍独立正确作答 + 使用显示答案正确作答",
    ["总题数"] = 0,
    ["一遍独立正确作答"] = 0,
    ["非一遍独立正确作答"] = 0,
    ["使用显示答案正确作答"] = 0,
    ["未正确作答最终选择跳过"] = 0,
    ["未作答直接选择跳过"] = 0
}
local secondStatsTable = {
    ["使用显示答案正确作答占比"] = "",
    ["(独立正确作答部分)单题平均错误次数"] = "",
    ["(使用显示答案正确作答或未正确作答最终选择跳过部分)单题平均错误次数"] = ""
}
local dataMap = {
    [1] = "一遍独立正确作答",
    [2] = "非一遍独立正确作答",
    [3] = "使用显示答案正确作答",
    [4] = "未正确作答最终选择跳过",
    [5] = "未作答直接选择跳过",
    ["一遍独立正确作答"] = 1,
    ["非一遍独立正确作答"] = 2,
    ["使用显示答案正确作答"] = 3,
    ["未正确作答最终选择跳过"] = 0,
    ["未作答直接选择跳过"] = 0
}
local needDoStats = true

local shuffledIndexes = 0
local qAndA = {}
local taskTotalNum = 0 -- 总题数
local taskattemptNum = 0 -- 正确作答的题数
local taskAloneAttemptNum = 0 -- 独立正确作答的题数
local taskSkipNum = 0 -- 最终跳过的题数
local taskWrongSkipNum = 0 -- 存在回答错误的最终跳过的题数
local taskrevealAttemptNum = 0 -- 使用了显示答案的正确作答的题数
local wrongTotalNum = 0 -- 回答错误总次数
local wrongTotalAloneAttemptNum = 0 -- 在独立正确作答的题中回答错误总次数
local inputSequenceTbl = {}
--[[taskStateTbl[curTaskIndex] = {进行到哪一步，是否完成过该题，完成该题的方式，是否使用了显示答案，进行的错误尝试的次数}
	[1]:进行到哪一步 0:初始状态 1:初始化完成 2:正在答题 3:正确作答
	[2]:是否完成过该题 true:完成过该题 false:没有完成过该题
	[3]:完成该题的方式 0:没有完成过该题 1:一遍独立正确作答 2:非一遍独立正确作答 3:使用显示答案正确作答 4:未正确作答最终选择跳过 5:未作答直接选择跳过
	[4]:是否使用了显示答案 true:使用了显示答案 false:没有使用显示答案
	[5]:进行的错误尝试的次数 0:初始次数 [1, 2, 3, 4, 5 ...)
]] --
local taskStateTbl = {}
local remainTaskNum = 0
local curTaskIndex = 1
local curTaskQuestionStr = ""
local curTaskAnswerStr = ""
local curTaskAnswerLength = 0
local curTaskAnswerSequenceTbl = {}
local inputStr = ""
local needContinueGetInputStrOnlyForDisplay = false
local isRevealAnswer = false
local correctNum = 0
local authorsLove = false

local function initKeyboardTableState(answer)
    for key, value in pairs(keyboardTable) do
        if (key >= "a" and key <= "z" and value[2] ~= nil and key ~= "rest") then
            value[2] = (answer:find(key, 1, true) ~= nil)
        end
    end
end

local function setPunishment()
    Isaac.GetPlayer(0):AnimateSad()
end

local function interact(answerLength, answerCharTbl, questionIndex)
    -- 处理答案字符
    local answerIndex = inputSequenceTbl[questionIndex] + 1
    for i = 1, answerLength do
        if Input.IsButtonTriggered(keyboardTable[answerCharTbl[i]][1], 0) then
            inputStr = inputStr .. answerCharTbl[i]
            if answerCharTbl[i] == answerCharTbl[answerIndex] then
                inputSequenceTbl[questionIndex] = inputSequenceTbl[questionIndex] + 1
            else
                inputSequenceTbl[questionIndex] = 0
                taskStateTbl[curTaskIndex][1] = 1
                needContinueGetInputStrOnlyForDisplay = true
            end
            return
        end
    end

    -- 处理非答案字符
    for key, value in pairs(keyboardTable) do
        if (key >= "a" and key <= "z" and value[2] ~= nil and not value[2]) then
            if Input.IsButtonTriggered(value[1], 0) then
                inputStr = inputStr .. key
                inputSequenceTbl[questionIndex] = 0
                taskStateTbl[curTaskIndex][1] = 1
                needContinueGetInputStrOnlyForDisplay = true
                return
            end
        end
    end

    -- 处理start部分
    if Input.IsButtonTriggered(keyboardTable["start"][1], 0) then
        inputStr = ""
        inputSequenceTbl[questionIndex] = 0
        needContinueGetInputStrOnlyForDisplay = false
        Isaac.GetPlayer(0).ControlsEnabled = false
        isAnswering = true
        return
    end

    -- 处理end部分
    if Input.IsButtonTriggered(keyboardTable["end"][1], 0) then
        if inputStr == "ilovesanzhixiong" then
            Isaac.ExecuteCommand("spawn 5.350.32913")
            Isaac.GetPlayer(0):AnimateHappy()
            authorsLove = true
        end
        inputStr = ""
        if inputSequenceTbl[questionIndex] == answerLength then
            taskStateTbl[curTaskIndex][1] = 3
        else
            if not authorsLove then
                setPunishment()
            end
            inputSequenceTbl[questionIndex] = 0
            taskStateTbl[curTaskIndex][1] = 1
        end
        needContinueGetInputStrOnlyForDisplay = false
        Isaac.GetPlayer(0).ControlsEnabled = true
        isAnswering = false
        authorsLove = false
        return
    end

    -- 处理rest部分
    for _, restKey in ipairs(keyboardTable["rest"]) do
        if Input.IsButtonTriggered(restKey, 0) then
            inputStr = ""
            inputSequenceTbl[questionIndex] = 0
            taskStateTbl[curTaskIndex][1] = 1
            needContinueGetInputStrOnlyForDisplay = false
            Isaac.GetPlayer(0).ControlsEnabled = true
            isAnswering = false
            return
        end
    end
end

local function spawnRewards()
    Isaac.GetPlayer(0):AnimateHappy()
    if not taskStateTbl[curTaskIndex][2] and not taskStateTbl[curTaskIndex][4] then
        correctNum = correctNum + 1
        if correctNum % 50 == 0 then
            Isaac.ExecuteCommand("spawn 5.100.628")
        elseif correctNum % 10 == 0 then
            Isaac.ExecuteCommand("spawn 5.100")

        elseif correctNum % 5 == 0 then
            local rnum = 1 + Random() % 18
            Isaac.ExecuteCommand("spawn 6." .. rnum)
            return
        else
            Isaac.ExecuteCommand("spawn 5")
        end
    end
end

local function stateValueUpdate()
    remainTaskNum = remainTaskNum - 1
    if remainTaskNum == 0 then
        gameState = gameStateTbl.STATS
    end
    if remainTaskNum ~= 0 then
        curTaskIndex = curTaskIndex + 1
        curTaskQuestionStr = qAndA[curTaskIndex][1]
        curTaskAnswerStr = qAndA[curTaskIndex][2]
        curTaskAnswerLength = #curTaskAnswerStr
        curTaskAnswerSequenceTbl = {}
        for i = 1, curTaskAnswerLength do
            local singleChar = curTaskAnswerStr:sub(i, i)
            table.insert(curTaskAnswerSequenceTbl, singleChar)
        end
    end
    inputSequenceTbl[curTaskIndex] = 0
    taskStateTbl[curTaskIndex][1] = 0
end

local function stateValueUpdateReverse()
    if curTaskIndex ~= 1 then
        remainTaskNum = remainTaskNum + 1
        curTaskIndex = curTaskIndex - 1
        curTaskQuestionStr = qAndA[curTaskIndex][1]
        curTaskAnswerStr = qAndA[curTaskIndex][2]
        curTaskAnswerLength = #curTaskAnswerStr
        curTaskAnswerSequenceTbl = {}
        for i = 1, curTaskAnswerLength do
            local singleChar = curTaskAnswerStr:sub(i, i)
            table.insert(curTaskAnswerSequenceTbl, singleChar)
        end
    end
    inputSequenceTbl[curTaskIndex] = 0
    taskStateTbl[curTaskIndex][1] = 0
end

local function rotateSprite()
    bsprite:Play("Keys")
    bsprite:SetLayerFrame(0, 0)
    bsprite.Rotation = menuRotation
    menuRotation = menuRotation + menuDegree
    radius = 500 * menuScale / math.sqrt(2)
    local constant = radius / math.sqrt(2)
    local radian = math.rad(menuRotation)
    menuOffset = Vector(constant * (math.sin(radian) - math.cos(radian) + 1),
        constant * (1 - math.cos(radian) - math.sin(radian)))
    if (menuRotation >= 360 or menuRotation <= -360) then
        menuRotation = 0
    end
    bsprite:Render(menuPos + menuOffset, Vector(0, 0), Vector(0, 0))
end

local function divideSmart(a, b, c)
    if b == 0 then
        return "NaN"
    end
    local s = string.format("%.2f", a / b)
    if c == 100 then
        s = string.format("%.2f", a * 100 / b)
    end
    if s:sub(-3) == ".00" then
        s = s:sub(1, -4)
    elseif s:sub(-1) == "0" then
        s = s:sub(1, -2)
    end
    if c == 100 then
        s = s .. "%"
    end
    return s
end

local function doStats()
    for i = 1, taskTotalNum do
        if taskStateTbl[i][3] == 1 then
            statsTable["一遍独立正确作答"] = statsTable["一遍独立正确作答"] + 1
        elseif taskStateTbl[i][3] == 2 then
            statsTable["非一遍独立正确作答"] = statsTable["非一遍独立正确作答"] + 1
        elseif taskStateTbl[i][3] == 3 then
            statsTable["使用显示答案正确作答"] = statsTable["使用显示答案正确作答"] + 1
        elseif taskStateTbl[i][3] == 0 then
            if taskStateTbl[i][5] == 0 then
                statsTable["未作答直接选择跳过"] = statsTable["未作答直接选择跳过"] + 1
                taskStateTbl[i][3] = 5
            else
                statsTable["未正确作答最终选择跳过"] = statsTable["未正确作答最终选择跳过"] + 1
                taskStateTbl[i][3] = 4
            end
        else
            print("stats error:", taskStateTbl[i][3])
        end
        if taskStateTbl[i][3] == 1 or taskStateTbl[i][3] == 2 or taskStateTbl[i][3] == 3 then
            taskattemptNum = taskattemptNum + 1
            if taskStateTbl[i][3] == 1 or taskStateTbl[i][3] == 2 then
                taskAloneAttemptNum = taskAloneAttemptNum + 1
                wrongTotalAloneAttemptNum = wrongTotalAloneAttemptNum + taskStateTbl[i][5]
            end
            if taskStateTbl[i][4] then
                taskrevealAttemptNum = taskrevealAttemptNum + 1
            end
        elseif taskStateTbl[i][3] == 4 or taskStateTbl[i][3] == 5 then
            taskSkipNum = taskSkipNum + 1
            if taskStateTbl[i][5] ~= 0 then
                taskWrongSkipNum = taskWrongSkipNum + 1
            end
        else
            print("stats error2:", taskStateTbl[i][3])
        end
        wrongTotalNum = wrongTotalNum + taskStateTbl[i][5]
    end
    if taskattemptNum ~= 0 then
        secondStatsTable["使用显示答案正确作答占比"] =
            tostring(taskrevealAttemptNum) .. " / " .. tostring(taskattemptNum) .. " = " ..
                divideSmart(taskrevealAttemptNum, taskattemptNum, 100)
    end
    secondStatsTable["(独立正确作答部分)单题平均错误次数"] =
        divideSmart(wrongTotalAloneAttemptNum, taskAloneAttemptNum)
    secondStatsTable["(使用显示答案正确作答或未正确作答最终选择跳过部分)单题平均错误次数"] =
        divideSmart(wrongTotalNum - wrongTotalAloneAttemptNum, taskattemptNum - taskAloneAttemptNum + taskWrongSkipNum)
end

local function saveData()
    if selectedOption < 0 then
        local saveDataTable = {}
        local taskTable = {}
        for i = 1, taskTotalNum do
            local tempTbl = {}
            tempTbl["单词"] = qAndA[i][2]
            tempTbl["题目"] = qAndA[i][1]
            tempTbl["如何完成的"] = dataMap[taskStateTbl[i][3]]
            tempTbl["是否查看过答案"] = taskStateTbl[i][4]
            tempTbl["回答错误的次数"] = taskStateTbl[i][5]
            taskTable[i] = tempTbl
        end
        saveDataTable["题目数据"] = taskTable
        saveDataTable["当前问题序号"] = curTaskIndex
        saveDataTable["词库名称"] = optionList[-selectedOption]
        saveDataTable["答对数"] = correctNum
        mod:SaveData(szxJson.encode(saveDataTable))
    end
end

local function onRender(_)
    if selectedOption == 0 then
        if not game:IsPaused() then
            if (Input.IsActionTriggered(ButtonAction.ACTION_UP, 0) or
                Input.IsActionTriggered(ButtonAction.ACTION_SHOOTUP, 0)) then
                selectOption = selectOption - 1
                if selectOption < 1 then
                    selectOption = optionNum
                end
            elseif (Input.IsActionTriggered(ButtonAction.ACTION_DOWN, 0) or
                Input.IsActionTriggered(ButtonAction.ACTION_SHOOTDOWN, 0)) then
                selectOption = selectOption + 1
                if selectOption > optionNum then
                    selectOption = 1
                end
            elseif (Input.IsActionTriggered(ButtonAction.ACTION_ITEM, 0) or
                Input.IsButtonTriggered(Keyboard.KEY_ENTER, 0)) then
                Isaac.GetPlayer(0).ControlsEnabled = true
                isAnswering = false
                if Isaac.GetPlayer(1) ~= nil then
                    Isaac.GetPlayer(1).ControlsEnabled = true
                end
                selectedOption = selectOption
            end
        end

        local px = 145
        local py = 90
        font:DrawStringUTF8(modVersion, px - 20, py - 32, KColor(1, 1, 1, 1), 0, false)
        font:DrawStringUTF8(optionTitle, px - 20, py - 12, KColor(1, 1, 1, 1), 0, false)
        for i = 1, optionNum do
            if selectOption == i then
                font:DrawStringUTF8("|• " .. optionList[i] .. " •|", px - 10, py + 2, KColor(1, 1, 1, 1), 0, false)
                py = py + 16
            else
                font:DrawStringUTF8("||  " .. optionList[i] .. "  ||", px - 10, py, KColor(0.5, 0.5, 0.5, 1), 0, false)
                py = py + 12
            end
        end
    end
    if gameState == gameStateTbl.WAIT_FOR_LOADING_DATA then
        font:DrawStringScaledUTF8("正在同步该局游戏的答题数据，当前进度：" .. string.format("%.2f%%", taskInfo[2] * 100), strPosX, strPosY, 1, 1, KColor(1, 1, 1, 1), 0, false)
    elseif gameState == gameStateTbl.RUNNING then
        -- init keyboardTable
        if taskStateTbl[curTaskIndex][1] == 0 then
            initKeyboardTableState(curTaskAnswerStr)
            taskStateTbl[curTaskIndex][1] = 1
        end

        -- determine whether keyboard input starts
        if taskStateTbl[curTaskIndex][1] == 1 then
            if Input.IsButtonTriggered(keyboardTable["start"][1], 0) then
                taskStateTbl[curTaskIndex][1] = 2
            end
        end

        -- skip to the next question
        if Input.IsButtonTriggered(51, 0) then -- hit [num3]
            inputStr = ""
            needContinueGetInputStrOnlyForDisplay = false
            Isaac.GetPlayer(0).ControlsEnabled = true
            isAnswering = false
            stateValueUpdate()
        end

        -- skip to the last question
        if Input.IsButtonTriggered(49, 0) then -- hit [num1]
            inputStr = ""
            needContinueGetInputStrOnlyForDisplay = false
            Isaac.GetPlayer(0).ControlsEnabled = true
            isAnswering = false
            stateValueUpdateReverse()
        end

        local currentHoldType = 0
        if Input.IsButtonPressed(51, 0) then -- hit [num3]
            if not holdStart then
                holdStart = true
            else
                if lastFrameHoldType ~= 3 then
                    holdStart = false
                    holdSeconds = 0
                else
                    if holdSeconds >= 30 then
                        inputStr = ""
                        needContinueGetInputStrOnlyForDisplay = false
                        Isaac.GetPlayer(0).ControlsEnabled = true
                        isAnswering = false
                        stateValueUpdate()
                    end
                    if holdSeconds < 30 then
                        holdSeconds = holdSeconds + 1
                    end
                end
            end
            currentHoldType = 3
        end
        if Input.IsButtonPressed(49, 0) then -- hit [num1]
            if not holdStart then
                holdStart = true
            else
                if lastFrameHoldType ~= 1 then
                    holdStart = false
                    holdSeconds = 0
                else
                    if holdSeconds >= 30 then
                        inputStr = ""
                        needContinueGetInputStrOnlyForDisplay = false
                        Isaac.GetPlayer(0).ControlsEnabled = true
                        isAnswering = false
                        stateValueUpdateReverse()
                    end
                    if holdSeconds < 30 then
                        holdSeconds = holdSeconds + 1
                    end
                end
            end
            currentHoldType = 1
        end
        lastFrameHoldType = currentHoldType

        -- reveal the answer
        if Input.IsButtonTriggered(50, 0) then -- hit [num2]
            inputStr = curTaskAnswerStr
            needContinueGetInputStrOnlyForDisplay = false
            Isaac.GetPlayer(0).ControlsEnabled = false
            isAnswering = true
            taskStateTbl[curTaskIndex][1] = 2
            inputSequenceTbl[curTaskIndex] = curTaskAnswerLength
            isRevealAnswer = true
            -- 统计部分----------------------------------------------
            taskStateTbl[curTaskIndex][4] = true
            -------------------------------------------------------
        end

        -- collect extra keyboard input for font display
        if needContinueGetInputStrOnlyForDisplay then
            -- a到z部分
            for key, value in pairs(keyboardTable) do
                if (key >= "a" and key <= "z" and value[2] ~= nil and key ~= "rest") then
                    if Input.IsButtonTriggered(value[1], 0) then
                        inputStr = inputStr .. key
                        break
                    end
                end
            end
            -- start部分不需要，因为会进到里面清屏
            -- end部分
            if Input.IsButtonTriggered(keyboardTable["end"][1], 0) then
                if inputStr == "ilovesanzhixiong" then
                    Isaac.ExecuteCommand("spawn 5.350.32913")
                    Isaac.GetPlayer(0):AnimateHappy()
                    authorsLove = true
                end
                if not authorsLove then
                    -- 统计部分----------------------------------------------
                    if not taskStateTbl[curTaskIndex][2] then
                        taskStateTbl[curTaskIndex][5] = taskStateTbl[curTaskIndex][5] + 1
                    end
                    -------------------------------------------------------
                    setPunishment()
                end
                inputStr = ""
                needContinueGetInputStrOnlyForDisplay = false
                Isaac.GetPlayer(0).ControlsEnabled = true
                isAnswering = false
                authorsLove = false
            end
            -- rest部分
            for _, restKey in ipairs(keyboardTable["rest"]) do
                if Input.IsButtonTriggered(restKey, 0) then
                    inputStr = ""
                    needContinueGetInputStrOnlyForDisplay = false
                    Isaac.GetPlayer(0).ControlsEnabled = true
                    isAnswering = false
                    break
                end
            end
        end

        -- main loop (check keyboard input)
        if taskStateTbl[curTaskIndex][1] == 2 then
            if isRevealAnswer then
                isRevealAnswer = false
            else
                interact(curTaskAnswerLength, curTaskAnswerSequenceTbl, curTaskIndex)
            end
        end

        -- the answer is found
        if taskStateTbl[curTaskIndex][1] == 3 then
            spawnRewards()
            -- 统计部分----------------------------------------------
            if not taskStateTbl[curTaskIndex][2] then
                if taskStateTbl[curTaskIndex][4] then
                    taskStateTbl[curTaskIndex][3] = 3
                else
                    if taskStateTbl[curTaskIndex][5] == 0 then
                        taskStateTbl[curTaskIndex][3] = 1
                    else
                        taskStateTbl[curTaskIndex][3] = 2
                    end
                end
            end
            taskStateTbl[curTaskIndex][2] = true
            -------------------------------------------------------
            stateValueUpdate()
        end
        
        -- display font string
        local fullStr = curTaskQuestionStr .. inputStr
        local maxWidth = 320
        if font:GetStringWidthUTF8(fullStr) < maxWidth then
            font:DrawStringScaledUTF8(fullStr, strPosX, strPosY, 1, 1, KColor(1, 1, 1, 1), 0, false)
        else
            -- 查找最后一个空格或分号，确保截断后前一部分不超过maxWidth
            local splitIndex = nil
            for i = #fullStr, 1, -1 do
                local ch = fullStr:sub(i, i)
                if ch == ' ' or ch == ';' or ch == ',' then
                    local firstLine = fullStr:sub(1, i)
                    if font:GetStringWidthUTF8(firstLine) < maxWidth then
                        splitIndex = i
                        break
                    end
                end
            end

            -- 如果找到了合适的断点
            if splitIndex then
                local firstLine = fullStr:sub(1, splitIndex)
                font:DrawStringScaledUTF8(firstLine, strPosX, strPosY, 1, 1, KColor(1, 1, 1, 1), 0, false)
                local secondLine = fullStr:sub(splitIndex + 1):gsub("^%s+", "") -- 去掉前导空格
                if font:GetStringWidthUTF8(secondLine) < maxWidth then
                    font:DrawStringScaledUTF8(secondLine, strPosX, strPosY + instructionLineGap, 1, 1, KColor(1, 1, 1, 1), 0, false)
                else
                    -- 查找最后一个空格或分号，确保截断后前一部分不超过maxWidth
                    local splitIndex = nil
                    for i = #secondLine, 1, -1 do
                        local ch = secondLine:sub(i, i)
                        if ch == ' ' or ch == ';' or ch == ',' then
                            local firstSecondLine = secondLine:sub(1, i)
                            if font:GetStringWidthUTF8(firstSecondLine) < maxWidth then
                                splitIndex = i
                                break
                            end
                        end
                    end

                    -- 如果找到了合适的断点
                    if splitIndex then
                        local firstSecondLine = secondLine:sub(1, splitIndex)
                        font:DrawStringScaledUTF8(firstSecondLine, strPosX, strPosY + instructionLineGap, 1, 1, KColor(1, 1, 1, 1), 0, false)
                        local thirdLine = secondLine:sub(splitIndex + 1):gsub("^%s+", "") -- 去掉前导空格
                        font:DrawStringScaledUTF8(thirdLine, strPosX, strPosY + 2 * instructionLineGap, 1, 1, KColor(1, 1, 1, 1), 0, false)
                    else
                        -- 没找到断点
                        font:DrawStringScaledUTF8(secondLine, strPosX, strPosY + instructionLineGap, 1, 1, KColor(1, 1, 1, 1), 0, false)
                    end 
                end
            else
                -- 没找到断点
                font:DrawStringScaledUTF8(fullStr, strPosX, strPosY, 1, 1, KColor(1, 1, 1, 1), 0, false)
            end
        end

        font:DrawStringScaledUTF8("当前问题：" .. curTaskIndex .. "/" .. taskTotalNum, 270, 230, 1, 1, KColor(1, 1, 1, 1), 0, false)
        font:DrawStringScaledUTF8("答对数：" .. correctNum, 160, 230, 1, 1, KColor(1, 1, 1, 1), 0, false)
        font:DrawStringScaledUTF8(optionList[-selectedOption], 375, 230, 1, 1, KColor(1, 1, 1, 1), 0, false)
        if curTaskIndex == 1 then
            font:DrawStringScaledUTF8("按[Backspace]开始作答", instructionPosX, instructionPosY, 1, 1, KColor(1, 1, 1, 1), 0, false)
            font:DrawStringScaledUTF8("按[Enter]提交答案", instructionPosX, instructionPosY + instructionLineGap, 1, 1, KColor(1, 1, 1, 1), 0, false)
            font:DrawStringScaledUTF8("按[Num1]进入上一题", instructionPosX, instructionPosY + 2 * instructionLineGap, 1, 1, KColor(1, 1, 1, 1), 0, false)
            font:DrawStringScaledUTF8("按[Num2]显示当前答案", instructionPosX, instructionPosY + 3 * instructionLineGap, 1, 1, KColor(1, 1, 1, 1), 0, false)
            font:DrawStringScaledUTF8("按[Num3]进入下一题", instructionPosX, instructionPosY + 4 * instructionLineGap, 1, 1, KColor(1, 1, 1, 1), 0, false)
            font:DrawStringScaledUTF8("答案仅由26个小写英文字母组成", instructionPosX, instructionPosY + 5 * instructionLineGap, 1, 1, KColor(1, 1, 1, 1), 0, false)
        elseif curTaskIndex == 2 then
            font:DrawStringScaledUTF8("答对有奖励，答错无惩罚！", instructionPosX, instructionPosY, 1, 1, KColor(1, 1, 1, 1), 0, false)
            font:DrawStringScaledUTF8("成功答对奖励随机掉落物", instructionPosX, instructionPosY + instructionLineGap, 1, 1, KColor(1, 1, 1, 1), 0, false)
            font:DrawStringScaledUTF8("每答对5道奖励可互动实体", instructionPosX, instructionPosY + 2 * instructionLineGap, 1, 1, KColor(1, 1, 1, 1), 0, false)
            font:DrawStringScaledUTF8("每答对10道奖励一个道具", instructionPosX, instructionPosY + 3 * instructionLineGap, 1, 1, KColor(1, 1, 1, 1), 0, false)
            font:DrawStringScaledUTF8("每答对50道奖励死亡证明", instructionPosX, instructionPosY + 4 * instructionLineGap, 1, 1, KColor(1, 1, 1, 1), 0, false)
            font:DrawStringScaledUTF8("依靠'显示答案'答对的题目无奖励", instructionPosX, instructionPosY + 5 * instructionLineGap, 1, 1, KColor(1, 1, 1, 1), 0, false)
        elseif curTaskIndex == 3 then
            font:DrawStringScaledUTF8("答错了不要急着看答案", instructionPosX, instructionPosY, 1, 1, KColor(1, 1, 1, 1), 0, false)
            font:DrawStringScaledUTF8("努力努力再想一想试一试", instructionPosX, instructionPosY + instructionLineGap, 1, 1, KColor(1, 1, 1, 1), 0, false)
            font:DrawStringScaledUTF8("只要最终题目是你靠自己答对的", instructionPosX, instructionPosY + 2 * instructionLineGap, 1, 1, KColor(1, 1, 1, 1), 0, false)
            font:DrawStringScaledUTF8("依然会得到应有的奖励", instructionPosX, instructionPosY + 3 * instructionLineGap, 1, 1, KColor(1, 1, 1, 1), 0, false)
            font:DrawStringScaledUTF8("每道题的奖励只能获得一次", instructionPosX, instructionPosY + 4 * instructionLineGap, 1, 1, KColor(1, 1, 1, 1), 0, false)
            font:DrawStringScaledUTF8("输入'ilovesanzhixiong'领取金色传说", instructionPosX, instructionPosY + 5 * instructionLineGap, 1, 1, KColor(1, 1, 1, 1), 0, false)
        end
    elseif gameState == gameStateTbl.STATS then
        if needDoStats then
            doStats()
            needDoStats = false
            saveData()
        end
        -- 显示通关面板
        local textTbl = {}
        for i, key in ipairs(statsOrderMap) do
            textTbl[i] = key .. " " .. statsTable[key]
        end
        for i, key in ipairs(secondStatsOrderMap) do
            table.insert(textTbl, key .. " " .. secondStatsTable[key])
        end
        for i = 1, #textTbl do
            if i == 1 then
                font:DrawStringScaledUTF8(textTbl[i], configPosTable[1] - 20, configPosTable[2] + 20 + (i - 1) * 17, 1, 1, KColor(1, 0.75, 0, 1), 0, false)
            else
                font:DrawStringScaledUTF8(textTbl[i], configPosTable[1] - 20, configPosTable[2] + 15 * i + 12, 1, 1, KColor(1, 1, 1, 1), 0, false)
            end
        end
        font:DrawStringScaledUTF8("详细报告已保存在：", configPosTable[1] + 155, configPosTable[2] + 85, 1, 1, KColor(0.1, 0.8, 0.1, 1), 0, false)
        font:DrawStringScaledUTF8("The Binding of Isaac Rebirth\\data\\szx_beidanci", configPosTable[1] + 105, configPosTable[2] + 100, 1, 1, KColor(0.1, 0.8, 0.1, 1), 0, false)
        font:DrawStringScaledUTF8("如有需要请及时备份", configPosTable[1] + 155, configPosTable[2] + 115, 1, 1, KColor(0.1, 0.8, 0.1, 1), 0, false)
        font:DrawStringScaledUTF8("按[H]打开/关闭本界面", configPosTable[1] + 150, configPosTable[2] + 135, 1, 1, KColor(0.1, 0.8, 0.1, 1), 0, false)
        if Input.IsButtonTriggered(Keyboard.KEY_H, 0) then
            gameState = gameStateTbl.END
        end
    elseif gameState == gameStateTbl.END then
        if Input.IsButtonTriggered(Keyboard.KEY_H, 0) then
            gameState = gameStateTbl.STATS
        end
    end
    -- sanzhixiong center rotation
    local maxBoundX = 445 + 500 * 1.2 * (0.06 - menuScale)
    local maxBoundY = 235 + 500 * 1.2 * (0.06 - menuScale)
    local tempPos = menuPos + moveVector
    local tempPosX = tempPos.X
    local tempPosY = tempPos.Y
    local eitherStuck = 0
    if tempPosX < 5 or tempPosX > maxBoundX then
        moveVector.X = -moveVector.X
        eitherStuck = 1
    end
    if tempPosY < 5 or tempPosY > maxBoundY then
        moveVector.Y = -moveVector.Y
        eitherStuck = 1
    end
    if eitherStuck == 1 then
        ifStuck = ifStuck + 1
    else
        ifStuck = 0
    end
    if ifStuck == 60 then
        ifStuck = 0
        menuPos = Vector(20, 90)
        moveVector = Vector(2, 1.5)
    end
    menuPos = menuPos + moveVector
    menuDegree = 5
    rotateSprite()
end

local function shuffleIndexes(tbl)
    local indexes = {}
    for index in pairs(tbl) do
        table.insert(indexes, index)
    end
    for i = #indexes, 2, -1 do
        local j = math.random(i)
        indexes[i], indexes[j] = indexes[j], indexes[i]
    end
    return indexes
end

local function loadUserData(jsonTable)
    local taskTable = {}
    taskTable = jsonTable["题目数据"]
    correctNum = jsonTable["答对数"]
    curTaskIndex = jsonTable["当前问题序号"]
    taskTotalNum = #taskTable
    remainTaskNum = taskTotalNum - curTaskIndex
    statsTable["总题数"] = taskTotalNum .. "                             + 未正确作答最终选择跳过 + 未作答直接选择跳过"
    if jsonTable["词库名称"] == "初中词库" then
        selectedOption = -1
    elseif jsonTable["词库名称"] == "高中词库" then
        selectedOption = -2
    elseif jsonTable["词库名称"] == "雅思词库" then
        selectedOption = -3
    elseif jsonTable["词库名称"] == "考研词库" then
        selectedOption = -4
    elseif jsonTable["词库名称"] == "四级词库" then
        selectedOption = -5
    elseif jsonTable["词库名称"] == "六级词库" then
        selectedOption = -6
    elseif jsonTable["词库名称"] == "专八词库" then
        selectedOption = -7
    else
        print("ciku does not exist")
    end
    statsTable["题库"] = jsonTable["词库名称"]
    if remainTaskNum == 0 then
        gameState = gameStateTbl.END
    else
        gameState = gameStateTbl.RUNNING
    end
    for i = 1, taskTotalNum do
        qAndA[i][1] = taskTable[i]["题目"]
        qAndA[i][2] = taskTable[i]["单词"]
        taskStateTbl[i][3] = dataMap[taskTable[i]["如何完成的"]]
        if taskStateTbl[i][3] == 1 or taskStateTbl[i][3] == 2 or taskStateTbl[i][3] == 3 then
            taskStateTbl[i][2] = true
        else
            taskStateTbl[i][2] = false
        end
        taskStateTbl[i][4] = taskTable[i]["是否查看过答案"]
        taskStateTbl[i][5] = taskTable[i]["回答错误的次数"]
    end
    curTaskQuestionStr = qAndA[curTaskIndex][1]
    curTaskAnswerStr = qAndA[curTaskIndex][2]
    curTaskAnswerLength = #curTaskAnswerStr
    curTaskAnswerSequenceTbl = {}
    for i = 1, curTaskAnswerLength do
        local singleChar = curTaskAnswerStr:sub(i, i)
        table.insert(curTaskAnswerSequenceTbl, singleChar)
    end
    taskattemptNum = 0 -- 正确作答的题数
    taskAloneAttemptNum = 0 -- 独立正确作答的题数
    taskSkipNum = 0 -- 最终跳过的题数
    taskWrongSkipNum = 0 -- 存在回答错误的最终跳过的题数
    taskrevealAttemptNum = 0 -- 使用了显示答案的正确作答的题数
    wrongTotalNum = 0 -- 回答错误总次数
    wrongTotalAloneAttemptNum = 0 -- 在独立正确作答的题中回答错误总次数
end

local function onUpdate(_)
    if selectedOption == 0 then
        local player = Isaac.GetPlayer(0)
        if player.ControlsEnabled then
            player.ControlsEnabled = false
        end
        local player2 = Isaac.GetPlayer(1)
        if player2 ~= nil then
            if player2.ControlsEnabled then
                player2.ControlsEnabled = false
            end
        end
    elseif selectedOption > 0 then
        -- init random question table
        local ciku = {}
        if selectedOption == 1 then
            ciku = chuzhong
        elseif selectedOption == 2 then
            ciku = gaozhong
        elseif selectedOption == 3 then
            ciku = yasi
        elseif selectedOption == 4 then
            ciku = kaoyan
        elseif selectedOption == 5 then
            ciku = siji
        elseif selectedOption == 6 then
            ciku = liuji
        elseif selectedOption == 7 then
            ciku = zhuanba
        else
            print("ciku overflow")
        end
        shuffledIndexes = shuffleIndexes(ciku)
        qAndA = {}
        for i, index in ipairs(shuffledIndexes) do
            qAndA[i] = ciku[index]
        end
        -- init state value
        statsTable = {
            ["题库"] = "",
            ["总题数 ="] = "一遍独立正确作答 + 非一遍独立正确作答 + 使用显示答案正确作答",
            ["总题数"] = 0,
            ["一遍独立正确作答"] = 0,
            ["非一遍独立正确作答"] = 0,
            ["使用显示答案正确作答"] = 0,
            ["未正确作答最终选择跳过"] = 0,
            ["未作答直接选择跳过"] = 0
        }
        secondStatsTable = {
            ["使用显示答案正确作答占比"] = "",
            ["(独立正确作答部分)单题平均错误次数"] = "",
            ["(使用显示答案正确作答或未正确作答最终选择跳过部分)单题平均错误次数"] = ""
        }
        taskInfo = {0, 100}
        isAnswering = false
        statsTable["题库"] = optionList[selectedOption]
        statsTable["总题数"] = #ciku ..
                                      "                             + 未正确作答最终选择跳过 + 未作答直接选择跳过"
        needDoStats = true
        taskTotalNum = #qAndA
        taskattemptNum = 0 -- 正确作答的题数
        taskAloneAttemptNum = 0 -- 独立正确作答的题数
        taskSkipNum = 0 -- 最终跳过的题数
        taskWrongSkipNum = 0 -- 存在回答错误的最终跳过的题数
        taskrevealAttemptNum = 0 -- 使用了显示答案的正确作答的题数
        wrongTotalNum = 0 -- 回答错误总次数
        wrongTotalAloneAttemptNum = 0 -- 在独立正确作答的题中回答错误总次数
        inputSequenceTbl = {}
        taskStateTbl = {}
        for i = 1, taskTotalNum do
            inputSequenceTbl[i] = 0
            taskStateTbl[i] = {0, false, 0, false, 0}
        end
        remainTaskNum = taskTotalNum
        curTaskIndex = 1
        curTaskQuestionStr = qAndA[curTaskIndex][1]
        curTaskAnswerStr = qAndA[curTaskIndex][2]
        curTaskAnswerLength = #curTaskAnswerStr
        curTaskAnswerSequenceTbl = {}
        for i = 1, curTaskAnswerLength do
            local singleChar = curTaskAnswerStr:sub(i, i)
            table.insert(curTaskAnswerSequenceTbl, singleChar)
        end
        inputStr = ""
        needContinueGetInputStrOnlyForDisplay = false
        isRevealAnswer = false
        selectedOption = -selectedOption
        correctNum = 0
        authorsLove = false
        gameState = gameStateTbl.RUNNING
    end
    if gameState == gameStateTbl.WAIT_FOR_LOADING_DATA then --todo
        local jsonTable = nil
        local id, progress, isEnd = szxJson.decode(taskInfo[1], szxJson.DECODE_MODE.TIME_CONTINUE, 25)
        if isEnd then
            taskInfo = {0, 100}
            jsonTable = id
            loadUserData(jsonTable)
        else
            taskInfo = {id, progress}
        end
    end
end

local function onGameStart(_, IsContinued)
    local needRestart = true
    if IsContinued then
        if mod:HasData() then
            -- init state value
            statsTable = {
                ["题库"] = "",
                ["总题数 ="] = "一遍独立正确作答 + 非一遍独立正确作答 + 使用显示答案正确作答",
                ["总题数"] = 0,
                ["一遍独立正确作答"] = 0,
                ["非一遍独立正确作答"] = 0,
                ["使用显示答案正确作答"] = 0,
                ["未正确作答最终选择跳过"] = 0,
                ["未作答直接选择跳过"] = 0
            }
            secondStatsTable = {
                ["使用显示答案正确作答占比"] = "",
                ["(独立正确作答部分)单题平均错误次数"] = "",
                ["(使用显示答案正确作答或未正确作答最终选择跳过部分)单题平均错误次数"] = ""
            }
            isAnswering = false
            needDoStats = true
            inputSequenceTbl = {}
            for i = 1, taskTotalNum do
                inputSequenceTbl[i] = 0
                qAndA[i] = {0, false, 0, false, 0}
            end
            inputStr = ""
            needContinueGetInputStrOnlyForDisplay = false
            authorsLove = false
            local jsonTable = nil
            local id, progress, isEnd = szxJson.decode(mod:LoadData(), szxJson.DECODE_MODE.TIME_INIT) --todo
            if isEnd then
                taskInfo = {0, 100}
                jsonTable = id
                loadUserData(jsonTable)
            else
                taskInfo = {id, progress}
                gameState = gameStateTbl.WAIT_FOR_LOADING_DATA
            end
            needRestart = false
        end
    else
        gameState = gameStateTbl.INIT
    end
    if needRestart then
        menuPos = Vector(410, 165)
        selectOption = 1
        selectedOption = 0
    else
        menuPos = Vector(20, 90)
    end
    radius = 500 * menuScale / math.sqrt(2)
    menuRotation = 0
    menuOffset = Vector(0, 0)
    menuDegree = 5
    ifStuck = 0
    moveVector = Vector(2, 1.5)
    bsprite.Scale = Vector(menuScale, menuScale)
    isRevealAnswer = false
end

local function onInputAction(_, _, inputHook, button)
    if button == ButtonAction.ACTION_MUTE or button == ButtonAction.ACTION_FULLSCREEN or ButtonAction.ACTION_PAUSE then
        if inputHook == InputHook.IS_ACTION_TRIGGERED or inputHook == InputHook.IS_ACTION_PRESSED then
            if isAnswering then
                return false
            end
        end
    end
end

local function onGameExit(_)
    if gameState == gameStateTbl.RUNNING or gameState == gameStateTbl.STATS or gameState == gameStateTbl.END then
        if needDoStats then
            doStats()
        end
        saveData()
    end
end

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, onGameStart)
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, onUpdate)
mod:AddCallback(ModCallbacks.MC_POST_RENDER, onRender)
mod:AddCallback(ModCallbacks.MC_INPUT_ACTION, onInputAction)
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, onGameExit)
