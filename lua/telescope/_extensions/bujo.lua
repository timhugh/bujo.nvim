return require("telescope").register_extension({
  exports = {
    bujo = require("bujo.find").find,
    bujo_insert_link = require("bujo.find").insert_link,
  }
})
