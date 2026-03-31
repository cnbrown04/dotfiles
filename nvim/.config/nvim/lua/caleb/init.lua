vim.g.mapleader = " " -- Set leader key before Lazy
 
require("caleb.set")
require("caleb.remap")
require("caleb.transparent").setup()
require("caleb.lazy_init") 

-- not sure why insert mode isn't working  
