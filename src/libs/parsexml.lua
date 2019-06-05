-- I just copied this over from lovesvg xD

--- Parses XML file.
-- http://lua-users.org/wiki/LuaXml (20.6.2017)
-- @param s string contents of XML file
-- @return a lua table
local function _parseXML(s)
    local insert = table.insert
    local remove = table.remove
    local find = string.find
    local gsub = string.gsub
    local sub = string.sub

    local parseargs = function (s)
      local arg = {}
      gsub(s, "([%-%w]+)=([\"'])(.-)%2", function (w, _, a)
        arg[w] = a
      end)
      return arg
    end
    local stack = {}
    local top = {}
    insert(stack, top)
    local ni,c,label,xarg, empty
    local i, j = 1, 1
    while true do
        ni,j,c,label,xarg, empty = find(s, "<(%/?)([%w:_-]+)(.-)(%/?)>", i)
        if not ni then break end
        local text = sub(s, i, ni-1)
        if not find(text, "^%s*$") then
            insert(top, text)
        end
        if empty == "/" then  -- empty element tag
            insert(top, {label=label, xarg=parseargs(xarg), empty=1})
        elseif c == "" then   -- start tag
            top = {label=label, xarg=parseargs(xarg)}
            insert(stack, top)   -- new level
        else  -- end tag
            local toclose = remove(stack)  -- remove top
            top = stack[#stack]
            if #stack < 1 then
                error("nothing to close with "..label)
            end
            if toclose.label ~= label then
                error("trying to close "..toclose.label.." with "..label)
            end
            insert(top, toclose)
        end
        i = j+1
    end
    local text = sub(s, i)
    if not find(text, "^%s*$") then
        insert(stack[#stack], text)
    end
    if #stack > 1 then
        error("unclosed "..stack[#stack].label)
    end
    return stack[1]
end

return _parseXML