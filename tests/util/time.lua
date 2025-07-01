local M = {}

M.os_date_unstubbed = os.date
M.os_time_unstubbed = os.time

M.stubbed_time = {
  year = 2025,
  month = 6,
  day = 23,
  yday = 174,
  wday = 2,
  hour = 12,
  min = 30,
  sec = 0,
  isdst = true,
}

function M.os_date_stub(format, time)
  if not time then
    time = M.os_time_unstubbed(M.stubbed_time)
  end

  if not format then
    format = "%a %b %d %H:%M:%S %Y"
  end

  return M.os_date_unstubbed(format, time)
end

function M.os_time_stub(t)
  if t then
    return M.os_time_unstubbed(t)
  else
    return M.os_time_unstubbed(M.stubbed_time)
  end
end

return M
