local files = {
    jig3D = "a6r27vA3",
    jigAR = "ycjH7MNB",
    engine = "FwfMY8Qr"
}

for k, v in pairs(files) do
    if fs.exists(k..".lua") then fs.delete(k..".lua") end
    print(k..": "..v)
    shell.run("pastebin get ", v, k..".lua")
end

print("Code download complete")