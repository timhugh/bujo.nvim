local M = {}

local ffi = require("ffi")
if not _G.__FFI_STRPTIME_CDEF then
  ffi.cdef[[
  typedef struct tm {
    int tm_sec;
    int tm_min;
    int tm_hour;
    int tm_mday;
    int tm_mon;
    int tm_year;
    int tm_wday;
    int tm_yday;
    int tm_isdst;
  };
  char *strptime(const char *buf, const char *fmt, struct tm *tm);
  ]]
  _G.__FFI_STRPTIME_CDEF = true
end

function M.parse(date_str, format)
  local tm = ffi.new("struct tm")
  local ret = ffi.C.strptime(date_str, format, tm)
  if ret == nil then
    return nil, "parse failed"
  end
  return {
    year = tm.tm_year + 1900,
    month = tm.tm_mon + 1,
    day = tm.tm_mday,
    hour = tm.tm_hour,
    min = tm.tm_min,
    sec = tm.tm_sec
  }
end

return M
