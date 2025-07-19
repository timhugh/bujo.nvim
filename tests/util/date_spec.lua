local date = require("bujo.util.date")

describe("date parsing", function()
  it("parses date strings", function()
    local date_str = "2025-07-05 14:30:45"
    local format = "%Y-%m-%d %H:%M:%S"
    local parsed_date, err = date.parse(date_str, format)
    assert.is_nil(err)
    assert.are.same(parsed_date, {
      year = 2025,
      month = 7,
      day = 5,
      hour = 14,
      min = 30,
      sec = 45,
    })
  end)

  it("parses weekly timestamps", function()
    local date_str = "2025-W40"
    local format = "%Y-W%V"
    local parsed_date, err = date.parse(date_str, format)
    assert.is_nil(err)
    assert.are.same(parsed_date, {
      year = 2025,
      month = 9,
      day = 29,
      hour = 0,
      min = 0,
      sec = 0
    })
  end)

  it("parses weekly timestamps that start and end in different months", function()
    -- week 27 of 2025 starts on Monday June 30, and ends in July
    local date_str = "2025-W27"
    local format = "%Y-W%V"
    local parsed_date, err = date.parse(date_str, format)
    assert.is_nil(err)
    assert.are.same(parsed_date, {
      year = 2025,
      month = 6,
      day = 30,
      hour = 0,
      min = 0,
      sec = 0
    })
  end)

  it("parses correct month on edge dates", function()
    local date_str = "2025-08"
    local format = "%Y-%m"
    local parsed_date, err = date.parse(date_str, format)
    assert.is_nil(err)
    assert.are.same(parsed_date, {
      year = 2025,
      month = 8,
      day = 1,
      hour = 0,
      min = 0,
      sec = 0
    })
  end)
end)
