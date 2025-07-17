local M = {}

local ffi = require("ffi")
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

local function find_strptime()
  if ffi.C.strptime then return ffi.C.strptime end

  local libs = {}
  if ffi.os == "OSX" then
    libs = { "libc.dylib", "libSystem.dylib" }
  elseif ffi.os == "Linux" then
    libs = { "libc.so.6", "libc.so" }
  end
  for _, libname in ipairs(libs) do
    local ok, lib = pcall(ffi.load, libname)
    if ok and lib.strptime then
      return lib.strptime
    end
  end

  return nil
end

local function get_strptime()
  local strptime = find_strptime()
  if type(strptime) == "function" then
    return strptime
  end

  if type(strptime) == "cdata" then
    return ffi.cast("char *(*)(const char *, const char *, struct tm *)", strptime)
  end

  return nil
end

local strptime = get_strptime()

function M.parse(date_str, format)
  if not strptime then
    return nil, "Could not find strptime implementation"
  end

  local tm = ffi.new("struct tm")
  local ret = strptime(date_str, format, tm)
  if ret == nil then
    return nil, "Failed to parse date string"
  end

  return {
    year = tm.tm_year + 1900,
    month = tm.tm_mon + 1,
    day = tm.tm_mday > 0 and tm.tm_mday or 1,
    hour = tm.tm_hour or 0,
    min = tm.tm_min or 0,
    sec = tm.tm_sec or 0
  }
end

return M
