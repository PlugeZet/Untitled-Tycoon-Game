local ButtonConfig = {
    ["FirstButton"] = {
        Id = 1,
        Name = "First Dropper",
        Target = "FirstDropper",
        Type = "Economy",
        Price = 0,
        Dependency = nil
    },
    ["Btn_Dropper2"] = {
        Id = 2,
        Name = "Basic Dropper",
        Target = "BasicDropper",
        Type = "Economy",
        Price = 100,
        Dependency = 1
    }
}
return ButtonConfig