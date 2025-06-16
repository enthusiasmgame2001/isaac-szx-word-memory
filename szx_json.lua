---------------------------------------------------------------------------------------------
-- JSON4Lua: JSON encoding / decoding support for the Lua language.
-- Original Author: Craig Mason-Jones
-- Original Homepage: http://github.com/craigmj/json4lua/
-- Original License: MIT License (MIT)
--
-- Modified Version:
-- Author: enthusiasmgame2001
-- Project: isaac-szx-word-memory
-- Homepage: https://github.com/enthusiasmgame2001/isaac-szx-word-memory/
--
-- This file has been heavily modified by enthusiasmgame2001 for use in isaac-szx-word-memory.
-- This modified version is still distributed under the terms of the MIT License.
-- See LICENSE.txt for full license text.
---------------------------------------------------------------------------------------------

-- 引入模块
local math = require('math')
local string = require("string")
local table = require("table")

-- 局部变量
local json = {}
local json_state = { -- 记录任务信息
    taskIdList = {}
}
-- 建立增加第一个 \ 的映射表
local escapeList = {
    ['"'] = '\\"',
    ['\\'] = '\\\\',
    ['/'] = '\\/',
    ['\b'] = '\\b',
    ['\f'] = '\\f',
    ['\n'] = '\\n',
    ['\r'] = '\\r',
    ['\t'] = '\\t'
}
-- 建立所有去除第一个 \ 的映射表
local escapeSequences = {
    ["\\t"] = "\t",
    ["\\f"] = "\f",
    ["\\r"] = "\r",
    ["\\n"] = "\n",
    ["\\b"] = "\b"
}
setmetatable(escapeSequences, {
    __index = function(t, k)
        return k:sub(2)
    end
})
local consts = {
    ["true"] = true,
    ["false"] = false,
    ["null"] = nil
}
local constNames = {"true", "false", "null"}

-- 局部函数实现
local startDecode -- 局部函数预先声明

-- 从字符串 s 的 startPos 开始跳过所有的空白字符（空格、换行、回车、制表符），返回第一个非空白字符的位置
local function decode_scanWhitespace(s, startPos)
    local whitespace = " \n\r\t"
    local strLength = #s
    while whitespace:find(s:sub(startPos, startPos), 1, true) and startPos <= strLength do
        startPos = startPos + 1
    end
    return startPos
end

-- 解析字典：startPos指向'{'
local function decode_scanObject(s, mode, attr, attr2, startPos, taskId)
    local task = nil
    if mode == 2 or mode == 4 then
        task = json_state[taskId]
        task.objectStackLength = task.objectStackLength + 1
        task.objectStackType[task.objectStackLength] = {0}
        task.objectStack[task.objectStackLength] = {}
    end
    if mode < 0 or mode >= 11 then
        task = json_state[taskId]
    end
    local object = {} -- 创建空字典用于收集元素
    local strLength = #s
    local key, value, isEnd, jumpParam -- 准备好变量：键和值，是否提前结束，穿透参数
    if mode >= 0 and mode <= 4 then
        assert(s:sub(startPos, startPos) == '{', '断言失败：断言startPos位置的字符为 {')
    else
        local level
        if mode < 0 then
            level = - mode
        else
            level = mode - 10
        end
        object = task.objectStack[level] -- 向内穿透
        assert(s:sub(startPos, startPos) == ',', '断言失败：断言startPos位置的字符为 ,')
        if task.objectStackLength == level then
            if mode < 0 then
                jumpParam = 1 -- 最内层
            else
                jumpParam = 3 -- 最内层
            end
        else
            if mode < 0 then
                jumpParam = 2 -- 非最内层
            else
                jumpParam = 4 -- 非最内层
            end
        end
    end
    if jumpParam == nil then
        startPos = startPos + 1 -- 跳过起始的 {，准备开始解析字典内部
    end
    -- 进入无限循环，直到遇到 } 才结束
    repeat
        local curChar
        if jumpParam == nil then
            startPos = decode_scanWhitespace(s, startPos)
            assert(startPos <= strLength, '断言失败：断言下一个非空白字符的位置在字符串内(length overflow)')
            curChar = s:sub(startPos, startPos)
            if curChar == '}' then
                if mode == 2 or mode == 4 then
                    task.objectStackType[task.objectStackLength] = nil
                    task.objectStackLength = task.objectStackLength - 1
                end
                if (mode == 2 or mode == 4) and task.objectStackLength == 0 then
                    task = nil
                    -- 从 taskIdList 中移除对应的 id
                    for i = 1, #json_state.taskIdList do
                        if json_state.taskIdList[i] == taskId then
                            table.remove(json_state.taskIdList, i)
                            break
                        end
                    end
                    return object, 100, true
                else
                    return object, startPos + 1
                end
            end
        end
        if curChar == ',' or (jumpParam == 1 or jumpParam == 3) then
            if mode == 2 and startPos - attr2 > attr then -- 从最内部离开
                task.attr2 = startPos - 1
                task.pos = startPos
                return taskId, startPos / #s, false
            end
            if mode == 4 and Isaac.GetTime() - attr2 > attr then -- 从最内部离开
                task.pos = startPos
                return taskId, startPos / #s, false
            end
            if jumpParam == 1 then
                jumpParam = nil
                task.mode = 2
                mode = 2
            elseif jumpParam == 3 then
                jumpParam = nil
                task.mode = 4
                mode = 4
            end
            startPos = decode_scanWhitespace(s, startPos + 1)
        end
        if jumpParam == nil then
            assert(startPos <= strLength, '断言失败：断言下一个非空白字符的位置在字符串内(length overflow)')
            key, startPos = startDecode(s, mode, attr, attr2, startPos, taskId) -- 拿到键
            if mode == 2 or mode == 4 then
                task.objectStackType[task.objectStackLength][2] = key
            end
            assert(startPos <= strLength, '断言失败：断言下一个非空白字符的位置在字符串内(length overflow)')
            startPos = decode_scanWhitespace(s, startPos)
            assert(startPos <= strLength, '断言失败：断言下一个非空白字符的位置在字符串内(length overflow)')
            assert(s:sub(startPos, startPos) == ':', '断言失败：断言key后面是一个:')
            startPos = decode_scanWhitespace(s, startPos + 1)
            assert(startPos <= strLength, '断言失败：断言下一个非空白字符的位置在字符串内(length overflow)')
        end
        if jumpParam == 2 then
            key = task.objectStackType[- mode][2]
            mode = mode - 1
        elseif jumpParam == 4 then
            key = task.objectStackType[mode - 10][2]
            mode = mode + 1
        end
        value, startPos, isEnd = startDecode(s, mode, attr, attr2, startPos, taskId) -- 拿到值
        if jumpParam == 2 then
            jumpParam = nil
            task.mode = 2
            mode = 2
        elseif jumpParam == 4 then
            jumpParam = nil
            task.mode = 4
            mode = 4
        end
        if isEnd == false then -- 一层一层往外离开
            return value, startPos, false -- taskId, startPos / #s
        end
        object[key] = value -- 将键值对加入字典
        if mode == 2 or mode == 4 then
            task.objectStack[task.objectStackLength] = object
        end
    until false
end

-- 解析数组：startPos指向'['
local function decode_scanArray(s, mode, attr, attr2, startPos, taskId)
    local task = nil
    if mode == 2 or mode == 4 then
        task = json_state[taskId]
        task.objectStackLength = task.objectStackLength + 1
        task.objectStackType[task.objectStackLength] = {1}
        task.objectStack[task.objectStackLength] = {}
    end
    if mode < 0 or mode >= 11 then
        task = json_state[taskId]
    end
    local array = {} -- 创建空数组用于收集元素
	local strLength = #s
    local element, isEnd, jumpParam -- 准备好变量：数组元素，是否提前结束，穿透参数
    if mode >= 0 and mode <= 4 then
        assert(s:sub(startPos, startPos) == '[', '断言失败：断言startPos位置的字符为 [')
    else
        local level
        if mode < 0 then
            level = - mode
        else
            level = mode - 10
        end
        array = task.objectStack[level] -- 向内穿透
        assert(s:sub(startPos, startPos) == ',', '断言失败：断言startPos位置的字符为 ,')
        if task.objectStackLength == level then
            if mode < 0 then
                jumpParam = 1 -- 最内层
            else
                jumpParam = 3 -- 最内层
            end
        else
            if mode < 0 then
                jumpParam = 2 -- 非最内层
            else
                jumpParam = 4 -- 非最内层
            end
        end
    end
    if jumpParam == nil then
        startPos = startPos + 1 -- 跳过起始的 [，准备开始解析数组内部
    end
    -- 进入无限循环，直到遇到 ] 才结束
    repeat
        local curChar
        if jumpParam == nil then
            startPos = decode_scanWhitespace(s, startPos)
            assert(startPos <= strLength, '断言失败：断言下一个非空白字符的位置在字符串内(length overflow)')
            curChar = s:sub(startPos, startPos)
            if curChar == ']' then
                if mode == 2 or mode == 4 then
                    task.objectStackType[task.objectStackLength] = nil
                    task.objectStackLength = task.objectStackLength - 1
                end
                if (mode == 2 or mode == 4) and task.objectStackLength == 0 then
                    task = nil
                    -- 从 taskIdList 中移除对应的 id
                    for i = 1, #json_state.taskIdList do
                        if json_state.taskIdList[i] == taskId then
                            table.remove(json_state.taskIdList, i)
                            break
                        end
                    end
                    return array, 100, true
                else
                    return array, startPos + 1
                end
            end
        end
        if curChar == ',' or (jumpParam == 1 or jumpParam == 3) then
            if mode == 2 and startPos - attr2 > attr then -- 从最内部离开
                task.attr2 = startPos - 1
                task.pos = startPos
                return taskId, startPos / #s, false
            end
            if mode == 4 and Isaac.GetTime() - attr2 > attr then -- 从最内部离开
                task.pos = startPos
                return taskId, startPos / #s, false
            end
            if jumpParam == 1 then
                jumpParam = nil
                task.mode = 2
                mode = 2
            elseif jumpParam == 3 then
                jumpParam = nil
                task.mode = 4
                mode = 4
            end
            startPos = decode_scanWhitespace(s, startPos + 1)
        end
        if jumpParam == nil then
            assert(startPos <= strLength, '断言失败：断言下一个非空白字符的位置在字符串内(length overflow)')
        end
        if jumpParam == 2 then
            mode = mode - 1
        elseif jumpParam == 4 then
            mode = mode + 1
        end
        element, startPos, isEnd = startDecode(s, mode, attr, attr2, startPos, taskId) -- 拿到元素
        if jumpParam == 2 then
            jumpParam = nil
            task.mode = 2
            mode = 2
        elseif jumpParam == 4 then
            jumpParam = nil
            task.mode = 4
            mode = 4
        end
        if isEnd == false then -- 一层一层往外离开
            return element, startPos, false -- taskId, startPos / #s
        end
        table.insert(array, element)
        if mode == 2 or mode == 4 then
            task.objectStack[task.objectStackLength] = array
        end
    until false
end

-- 解析数值：startPos指向数值的第一个字母
local function decode_scanNumber(s, startPos)
    local endPos = startPos + 1 -- endPos 是当前数字扫描的末尾位置（非包含）
    local strLength = #s -- 缓存字符串长度（提升效率）
    local acceptableChars = "+-0123456789.e" -- 可接受的数值字符
    while acceptableChars:find(s:sub(endPos, endPos), 1, true) and endPos <= strLength do
        endPos = endPos + 1
    end
    local numStr = s:sub(startPos, endPos - 1)
    local number = tonumber(numStr)
    assert(number ~= nil, '断言失败：断言' .. numStr .. '为数字')
    return number, endPos
end

-- 解析字符串：startPos指向引号[[']]或[[']]
local function decode_scanString(s, startPos)
    local startChar = s:sub(startPos, startPos)
    assert(startChar == [["]] or startChar == [[']], '断言失败：断言startPos位置的字符为两种引号')
    local t = {} -- 最终字符片段构成表（用于 table.concat 拼接字符串）
    local i, j = startPos, startPos -- 开始位置和结束位置（均指向引号）
    assert(s:find(startChar, j + 1), '断言失败：断言存在引号结束(no closing quote)')
    while s:find(startChar, j + 1) ~= j + 1 do -- 非空字符串''或""
        local oldj = j
        i, j = s:find("\\.", j + 1) -- 搜索转义字符'\'的位置
        local x, y = s:find(startChar, oldj + 1) -- 搜索下一个引号的位置
        if not i or x < i then -- 如果不存在转义字符'\'或下一个引号相较于转义字符'\'先出现
            i, j = x, y - 1 -- 开始位置和结束位置指向结束的引号
        end
        table.insert(t, s:sub(oldj + 1, i - 1)) -- 转义字符前或结束引号前的字符串存进table
        if s:sub(i, j) == "\\u" then
            local a = s:sub(j + 1, j + 4) -- 提取 \u 后的 4 个字符
            j = j + 4 -- 更新结束位置到最后一个字符
            local n = tonumber(a, 16) -- 将16进制的字符串转为十进制数字
            assert(n, '断言失败：断言n为有效十进制数字(bad Unicode escape)')
            local x -- 存储转义后的字符
            if n < 0x80 then -- 单字节 [0xxxxxxx]
                x = string.char(n % 0x80)
            elseif n < 0x800 then -- 双字节 [110x xxxx] [10xx xxxx]
                x = string.char(0xC0 + (math.floor(n / 64) % 0x20), 0x80 + (n % 0x40))
            else -- 三字节 [1110 xxxx] [10xx xxxx] [10xx xxxx]
                x = string.char(0xE0 + (math.floor(n / 4096) % 0x10), 0x80 + (math.floor(n / 64) % 0x40), 0x80 + (n % 0x40))
            end
            table.insert(t, x) -- 把解析出来的字符串x存进table
        else
            table.insert(t, escapeSequences[s:sub(i, j)]) -- 双转义字符去掉第一个转义字符后的字符串存进table
        end
    end
    return table.concat(t, ""), j + 2
end

-- 解析常量：startPos指向true/false/null的第一个字母
local function decode_scanConstant(s, startPos)
    for _, k in pairs(constNames) do
        if s:sub(startPos, startPos + #k - 1) == k then
            return consts[k], startPos + #k
        end
    end
    assert(false, '断言失败：断言常量必为true/false/null')
end

local function initDecodeTask(s, mode, attr, attr2, startPos)
    local taskId = (json_state.taskIdList[#json_state.taskIdList] or 0) + 1
    local task = {}
    task.s = s -- 需要解析的原始字符串
    task.mode = mode + 1 -- 解析模式
    task.attr = attr -- 解析参数（间隔）
    task.attr2 = attr2 -- 解析参数（起始点）
    task.pos = startPos -- 当前正在解析的字符位置
    task.objectStack = {} -- 当前已经解析的表
    task.objectStackType = {} -- 当前已经解析表的层级类型
    task.objectStackLength = 0 -- 当前已经解析的表的层级深度
    json_state[taskId] = task
    return taskId
end

function startDecode(s, mode, attr, attr2, startPos, taskId)
    if mode < 0 or mode >= 11 then -- 分类然后向内穿透
        local task = json_state[taskId]
        assert(task.objectStackLength > 0, '断言失败：断言栈length大于0')
        local level
        if mode < 0 then
            level = - mode
        else
            level = mode - 10
        end
        local stackType = task.objectStackType[level][1]
        if stackType == 0 then
            return decode_scanObject(s, mode, attr, attr2, startPos, taskId)
        elseif stackType == 1 then
            return decode_scanArray(s, mode, attr, attr2, startPos, taskId)
        end
    end
    startPos = decode_scanWhitespace(s, startPos)
    assert(startPos <= #s, '断言失败：断言下一个非空白字符的位置在字符串内(length overflow)')
    -- 读取当前位置的字符
    local curChar = s:sub(startPos, startPos)
    -- 分支判断结构类型
    -- 字典
    if curChar == '{' then
        return decode_scanObject(s, mode, attr, attr2, startPos, taskId)
    end
    -- 数组
    if curChar == '[' then
        return decode_scanArray(s, mode, attr, attr2, startPos, taskId)
    end
    -- 数值
    if string.find("+-0123456789.e", curChar, 1, true) then
        return decode_scanNumber(s, startPos)
    end
    -- 字符串
    if curChar == [["]] or curChar == [[']] then
        return decode_scanString(s, startPos)
    end
    -- 常量
    return decode_scanConstant(s, startPos)
end

local function encodeString(s)
    local s = tostring(s)
    return s:gsub(".", function(c)
        return escapeList[c]
    end)
end

local function isTableArray(t)
    if next(t) == nil then
        return true, 0
    end
    local count = 0
    for k, _ in pairs(t) do
        if type(k) ~= "number" or k ~= math.floor(k) or k < 1 then
            return false  -- 非正整数索引
        end
        count = count + 1
    end
    for i = 1, count do -- 检查是否连续：[1..count] 每一个都存在
        if t[i] == nil then
            return false  -- 有中断
        end
    end
    return true, count
end

local function isEncodable(o)
    local t = type(o)
    return t == 'string' or t == 'boolean' or t == 'number' or t == 'nil' or t == 'table'
end

-- 全局函数（公开接口）
-- 编码函数
function json.encode(v)
    -- nil
    if v == nil then
        return "null"
    end
    local vtype = type(v)
    -- string
    if vtype == 'string' then
        return '"' .. encodeString(v) .. '"'
    end
    -- number or boolean
    if vtype == 'number' or vtype == 'boolean' then
        return tostring(v)
    end
    -- table
    if vtype == 'table' then
        local rval = {}
        local isArray, maxCount = isTableArray(v)
        if isArray then
            for i = 1, maxCount do
                table.insert(rval, json.encode(v[i]))
            end
        else
            for i, j in pairs(v) do
                if isEncodable(i) and isEncodable(j) then
                    if type(i) == 'number' then
                        table.insert(rval, encodeString(i) .. ':' .. json.encode(j))
                    elseif type(i) == 'string' then
                        table.insert(rval, '"' .. encodeString(i) .. '":' .. json.encode(j))
                    else
                        assert(false, "table key type unsupported! Type:" .. type(i) .. 'Key:' .. tostring(i))
                    end
                end
            end
        end
        if isArray then
            return '[' .. table.concat(rval, ',') .. ']'
        else
            return '{' .. table.concat(rval, ',') .. '}'
        end
    end
    assert(false, 'encode type unsupported! Type:' .. vtype .. 'Value:' .. tostring(v))
end

-- 枚举变量
json.DECODE_MODE = {
    ["STANDARD"] = 0,
    ["CHAR_INIT"] = 1,
    ["CHAR_CONTINUE"] = 2,
    ["TIME_INIT"] = 3,
    ["TIME_CONTINUE"] = 4
}

-- 解析函数
function json.decode(s, mode, attr)
    local attr2, startPos, taskId
	mode = mode or json.DECODE_MODE.STANDARD
    if mode == json.DECODE_MODE.STANDARD then
        attr = nil
        attr2 = nil
        taskId = nil
        startPos = 1
        return startDecode(s, mode, attr, attr2, startPos, taskId)
    elseif mode == json.DECODE_MODE.CHAR_INIT then
        attr = attr or 10000
        attr2 = 0
        startPos = 1
        taskId = initDecodeTask(s, mode, attr, attr2, startPos)
        mode = json.DECODE_MODE.CHAR_CONTINUE
        return startDecode(s, mode, attr, attr2, startPos, taskId)
    elseif mode == json.DECODE_MODE.CHAR_CONTINUE then
        taskId = s -- s 是 taskId -- attr 是 新参数
        assert(type(taskId) == "number", '传入的taskId必须是数字')
        assert(json_state[taskId], '传入的taskId不存在或已完成')
        local task = json_state[taskId]
        if task.mode == json.DECODE_MODE.CHAR_CONTINUE then
            task.attr = attr or task.attr
        else
            task.attr = attr or 10000
            task.attr2 = task.pos - 1
        end
        -- 从最外侧向内穿透
        return startDecode(task.s, - 1, task.attr, task.attr2, task.pos, taskId)
    elseif mode == json.DECODE_MODE.TIME_INIT then
        attr = attr or 10
        attr2 = Isaac.GetTime()
        startPos = 1
        taskId = initDecodeTask(s, mode, attr, attr2, startPos)
        mode = json.DECODE_MODE.TIME_CONTINUE
        return startDecode(s, mode, attr, attr2, startPos, taskId)
    elseif mode == json.DECODE_MODE.TIME_CONTINUE then
        taskId = s -- s 是 taskId -- attr 是 新参数
        assert(type(taskId) == "number", '传入的taskId必须是数字')
        assert(json_state[taskId], '传入的taskId不存在或已完成')
        local task = json_state[taskId]
        if task.mode == json.DECODE_MODE.TIME_CONTINUE then
            task.attr = attr or task.attr
        else
            task.attr = attr or 10
        end
        -- 从最外侧向内穿透
        return startDecode(task.s, 11, task.attr, Isaac.GetTime(), task.pos, taskId)
    end
    assert(false, 'decode模式不存在')
end

return json