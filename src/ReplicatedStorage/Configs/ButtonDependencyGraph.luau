local ButtonConfig = {
    -- Droppers
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
        Price = 200,
        Dependency = "BtnDropper1"
    },
    ["BtnDropper3"] = {
        Name = "Basic Dropper",
        Target = "BasicDropper",
        Type = "Droppers",
        Price = 500,
        Dependency = "BtnDropper2"
    },
    
    -- Upgraders
    ["BtnUpgrader1"] = {
        Name = "Upgrader 1",
        Target = "Upgrader1",
        Type = "Upgraders",
        Price = 300,
        Dependency = "BtnDropper1"
    },
    
    -- Walls
    ["BtnWall1"] = {
        Name = "Wall 1",
        Target = "Wall1",
        Type = "Building",
        Price = 400,
        Dependency = "BtnDropper1"
    },
    ["BtnWall2"] = {
        Name = "Wall 2",
        Target = "Wall2",
        Type = "Building",
        Price = 600,
        Dependency = "BtnWall1"
    },
    ["BtnWall3"] = {
        Name = "Wall 3",
        Target = "Wall3",
        Type = "Building",
        Price = 800,
        Dependency = "BtnWall2"
    },
    ["BtnWall4"] = {
        Name = "Wall 4",
        Target = "Wall4",
        Type = "Building",
        Price = 1000,
        Dependency = "BtnWall3"
    },
    ["BtnWall5"] = {
        Name = "Wall 5",
        Target = "Wall5",
        Type = "Building",
        Price = 1500,
        Dependency = "BtnWall4"
    },
    
    -- Ceiling
    ["BtnCeiling1"] = {
        Name = "Ceiling 1",
        Target = "Ceiling1",
        Type = "Building",
        Price = 2500,
        Dependency = "BtnWall5"
    },

    -- OwnerDoor
    ["BtnOwnerDoor"] = {
        Name = "Owner Door",
        Target = "OwnerDoor",
        Type = "Building",
        Price = 1000,
        Dependency = "BtnWall3"
    },
}
return ButtonConfig