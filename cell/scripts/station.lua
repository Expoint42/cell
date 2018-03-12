--[[ 该脚本由 station.sh 脚本调用。

「用户建立连接事件」判断方法：
1. 每次设备断开连接，记录下设备断开连接的时间戳和 MAC 到缓存列表中；
2. 每次设备建立连接时，查看缓存列表中是否有该设备上次断开连接的记录；
3. 如果没有，将该次建立连接视为为「用户建立连接事件」；
4. 如果有，比较当前建立的连接和上次断开的连接的时间戳，如果时间差小于
    interval(sec) 则视为「设备建立连接事件」，否则视为「用户断开连接事件」。

「用户断开连接事件」判断方法：
1. 每次设备建立连接，记录下设备建立连接的时间戳和 MAC 到缓存列表中；
2. 每次设备断开连接时，查看缓存列表中该设备上次建立连接的记录（必须先
   先建立才能断开，因此缓存列表中肯定有建立连接记录），比较断开时间戳
   和连接时间戳的时间差，如果时间差小于 interval(sec) ? 则当做「设备断开连接
   事件」，否则将其当做「用户断开连接事件」。
]]

local posix = require("posix")
local iwinfo = require("iwinfo")
local socket = require("socket")
local http = require("socket.http")
local ltn12 = require("ltn12")

function GetNode()
  -- Get LAN IP from /etc/config/network file
  local f = io.popen("uci get system.@system[0].node")
  local temp = f:read("*a")
  f:close()
  local node =  string.gsub(temp, "\n", "")
  return node
end

function GetAPI()
  -- Get Station realted api
  local f = io.popen("uci get system.@system[0].cellhub")
  local temp = f:read("*a")
  f:close()
  local cellhub =  string.gsub(temp, "\n", "")
  return "http://"..cellhub.."/cell/station"
end

function Log(msg)
  local file = io.open("/tmp/log/station.log", "a")
  io.output(file)
  io.write(msg .. "\n")
  io.close(file)
end

-- How many stations on this router.
function CountStations()
  local f = assert(io.popen("ifconfig | grep wlan | awk '{print $1}'"))

  local count = 0

  for line in f:lines() do
    local t = iwinfo.type(line)
    local clients = iwinfo[t].assoclist(line)
    for k,v in pairs(clients) do count = count + 1 end
  end

  f:close()

  return count
end -- function

-- Get station MAC by line read from iw event
----------------------------------------------
-- @param line e.g. 1511339850.107615: wlan0: new station dc:a4:ca:1d:b5:b9
function GetStationMAC(line)
  words = {}
  for w in line:gmatch("%S+") do table.insert(words, w) end
  if #words == 5 then
    return words[5]
  else
    return nil
  end -- if
end -- function

-- upload to web server
function post(ts, action, rid, station_mac, total_station) 
  local reqbody = string.format('{"data": [%.0f, "%s", "%s", "%s", %d]}', ts, action, rid, station_mac, total_station)
  local respbody = {} -- for the response body
  
  -- log it
  Log(reqbody)

  local result, respcode, respheaders, respstatus = http.request {
    method = "POST",
    url = GetAPI(),
    source = ltn12.source.string(reqbody),
    headers = {
      ["content-type"] = "application/json",
      ["content-length"] = tostring(#reqbody)
    },
    sink = ltn12.sink.table(respbody)
  }
  -- get body as string by concatenating table filled by sink
  local respbody = table.concat(respbody)
  Log(respbody)
end -- function

-- Main loop function
function loop()
  Log("-----  Station Handler Started ------ ")
  local f = assert(io.popen("iw event -t -f"))

  for line in f:lines() do
    if string.find(line, "station") then
      
      node = GetNode()
      station_mac = GetStationMAC(line)  
      total_station = CountStations()
      ts = socket.gettime() * 1000 -- timestamp

      if string.find(line, "new") ~= nil then
        post(ts, 'new', node, station_mac, total_station)
      elseif string.find(line, "del") ~= nil then
        post(ts, 'del', node, station_mac, total_station)
      end  
    end -- if string
  end -- for lines

  f:close()
end -- function


pid = posix.fork()
if pid == 0 then
  loop()
else
  os.exit()
end