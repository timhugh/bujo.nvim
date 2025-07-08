local date = require("bujo.util.date")

describe("date parsing", function()
  it("parses date strings", function()
    local date_str = "2023-10-05 14:30:00"
    local format = "%Y-%m-%d %H:%M:%S"
    local parsed_date, err = date.parse(date_str, format)
    assert.is_nil(err)
    assert.are.same(parsed_date, {
      year = 2023,
      month = 10,
      day = 5,
      hour = 14,
      min = 30,
      sec = 0
    })
  end)

  it("parses weekly timestamps", function()
    local date_str = "2025-W27"
    local format = "%Y-W%V"
    local parsed_date, err = date.parse(date_str, format)
    assert.is_nil(err)
    assert.are.same(parsed_date, {
      year = 2025,
      month = 6,  -- July is the 7th month
      day = 30,    -- The first day of the week
      hour = 0,
      min = 0,
      sec = 0
    })
  end)
end)
