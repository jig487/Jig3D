local files = {
    matrix_lib = "Sx4QBHu5",
    engine =     "mLRAJ14E",
    loader =     "RhKEDWEe",
    refresh =    "3bxeiW4A"
}

for k, v in pairs(files) do
    fs.delete(k..".lua")
    print(k..": "..v)
    shell.run("pastebin get ", v, k..".lua")
end

print("Code download complete")

print("Downloading Shrek...")
local shrekURL = "PhbNHWNe"
shell.run("pastebin get ", shrekURL, " model.obj")

print("Shrek download complete")