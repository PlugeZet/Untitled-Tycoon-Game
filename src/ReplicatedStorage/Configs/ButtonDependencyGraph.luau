local ButtonConfig = {
    ["BtnDropper1"] = {
        Name = "First Dropper",
        Target = "BasicDropper",
        Type = "Droppers",
        Price = 0,
        Dependency = nil
    },
    ["BtnDropper2"] = {
        Name = "Basic Dropper",
        Target = "BasicDropper",
        Type = "Droppers",
        Price = 100,
        Dependency = "BtnDropper1"
    },
    ["BtnDropper3"] = {
        Name = "Basic Dropper",
        Target = "BasicDropper",
        Type = "Droppers",
        Price = 200,
        Dependency = "BtnDropper2"
    },
}
return ButtonConfig