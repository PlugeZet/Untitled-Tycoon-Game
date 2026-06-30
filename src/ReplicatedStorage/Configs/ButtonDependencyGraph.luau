local ButtonConfig = {
    ["BtnDropper1"] = {
        Id = 1,
        Name = "First Dropper",
        Target = "BasicDropper",
        Type = "Droppers",
        Price = 0,
        Dependency = nil
    },
    ["BtnDropper2"] = {
        Id = 2,
        Name = "Basic Dropper",
        Target = "BasicDropper",
        Type = "Droppers",
        Price = 100,
        Dependency = "BtnDropper1"
    }
}
return ButtonConfig