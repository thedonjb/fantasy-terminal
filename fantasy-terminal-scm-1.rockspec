package = "fantasy-terminal"
version = "scm-1"

source = {
   url = "git+https://github.com/thedonjb/fantasy-terminal"
}

description = {
   summary = "A virtual terminal game with package manager",
   license = "MIT",
   homepage = "https://github.com/thedonjb/fantasy-terminal"
}

dependencies = {
   "lua >= 5.1, < 5.2",
   "luasocket",
   "luasec",
   "dkjson >= 2.5"
}

build = {
   type = "builtin",
   modules = {
      ["src.utils"] = "src/utils.lua"
   }
}
