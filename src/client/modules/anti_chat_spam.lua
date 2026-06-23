local chatHistory = {}
local MAX_MESSAGES = 5
local WINDOW_MS = 3000
local spamDetections = 0

AddEventHandler("chatMessage", function(author, color, text)
    if not EAC.active or not EAC.config then return end

    local now = GetGameTimer()
    chatHistory[#chatHistory + 1] = { time = now, text = text }

    local newHistory = {}
    for _, entry in ipairs(chatHistory) do
        if now - entry.time < WINDOW_MS then
            newHistory[#newHistory + 1] = entry
        end
    end
    chatHistory = newHistory

    if #chatHistory >= MAX_MESSAGES then
        local dupes = 0
        for i = 2, #chatHistory do
            if chatHistory[i].text == chatHistory[1].text then
                dupes = dupes + 1
            end
        end
        if dupes >= MAX_MESSAGES - 1 then
            spamDetections = spamDetections + 1
            if spamDetections >= 2 then
                spamDetections = 0
                EAC.punish(DetectionType.MENU, "Chat spam detected")
            end
        end
    end
end)
