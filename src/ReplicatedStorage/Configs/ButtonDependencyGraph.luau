local ButtonConfig = {
    -- ==========================================
    -- DROPPERS (ID: 100 - 199)
    -- ==========================================
    ["BtnDropper1"] = {
        Id = 101,
        Name = "First Dropper",
        Target = "BasicDropper",
        Type = "Droppers",
        Price = 0,
        Dependency = nil
    },
    ["BtnDropper2"] = {
        Id = 102,
        Name = "Basic Dropper",
        Target = "BasicDropper",
        Type = "Droppers",
        Price = 150,
        Dependency = "BtnDropper1"
    },
    ["BtnDropper3"] = {
        Id = 103,
        Name = "Basic Dropper",
        Target = "BasicDropper",
        Type = "Droppers",
        Price = 500,
        Dependency = "BtnDropper2"
    },
    ["BtnDropper4"] = {
        Id = 104,
        Name = "Advanced Dropper",
        Target = "AdvancedDropper",
        Type = "Droppers",
        Price = 2500,
        Dependency = "BtnDropper3"
    },
    ["BtnDropper5"] = {
        Id = 105,
        Name = "Advanced Dropper",
        Target = "AdvancedDropper",
        Type = "Droppers",
        Price = 6000,
        Dependency = "BtnDropper4"
    },
    ["BtnDropper6"] = {
        Id = 106,
        Name = "Advanced Dropper",
        Target = "AdvancedDropper",
        Type = "Droppers",
        Price = 15000, 
        Dependency = "BtnDropper5"
    },
    
    -- ==========================================
    -- UPGRADERS (ID: 200 - 299)
    -- ==========================================
    ["BtnUpgrader1"] = {
        Id = 201,
        Name = "Basic Upgrader",
        Target = "BasicUpgrader",
        Type = "Upgraders",
        Price = 1200,
        Dependency = "BtnDropper3"
    },
    ["BtnUpgrader2"] = {
        Id = 202,
        Name = "Advanced Upgrader",
        Target = "AdvancedUpgrader",
        Type = "Upgraders",
        Price = 25000,
        Dependency = "BtnDropper6"
    },
    
    -- ==========================================
    -- BUILDINGS & COSMETICS (ID: 300 - 399)
    -- ==========================================
    ["BtnWall1"] = {
        Id = 301,
        Name = "Wall",
        Target = "Wall1",
        Type = "Building",
        Price = 100,
        Dependency = "BtnDropper1"
    },
    ["BtnWall2"] = {
        Id = 302,
        Name = "Wall",
        Target = "Wall2",
        Type = "Building",
        Price = 250,
        Dependency = "BtnWall1"
    },
    ["BtnWall3"] = {
        Id = 303,
        Name = "Wall",
        Target = "Wall3",
        Type = "Building",
        Price = 800,
        Dependency = "BtnWall2"
    },
    ["BtnWall4"] = {
        Id = 304,
        Name = "Wall 4",
        Target = "Wall4",
        Type = "Building",
        Price = 1800,
        Dependency = "BtnWall3"
    },
    ["BtnWall5"] = {
        Id = 305,
        Name = "Wall",
        Target = "Wall5",
        Type = "Building",
        Price = 3500,
        Dependency = "BtnWall4"
    },
    ["BtnCeiling1"] = {
        Id = 306,
        Name = "Ceiling",
        Target = "Ceiling1",
        Type = "Building",
        Price = 5000,
        Dependency = "BtnWall5"
    },
    ["BtnRailing1"] = {
        Id = 307,
        Name = "Railing",
        Target = "Railing1",
        Type = "Building",
        Price = 1000,
        Dependency = "BtnDropper3"
    },
    ["BtnPath1"] = {
        Id = 308,
        Name = "Path",
        Target = "Path1",
        Type = "Building",
        Price = 500,
        Dependency = "BtnWall1"
    },
    ["BtnOwnerDoor"] = {
        Id = 309,
        Name = "Owner Door",
        Target = "OwnerDoor",
        Type = "Building",
        Price = 1500,
        Dependency = "BtnWall3"
    },

["BtnWeapon1"] = {
        Id = 401,
        Name = "Wooden Sword",
        Target = "Weapon1",
        Type = "Building",
        Price = 1500,
        Dependency = "BtnWall1"
    },
    ["BtnWeapon2"] = {
        Id = 402,
        Name = "Iron Sword",
        Target = "Weapon2",
        Type = "Building",
        Price = 4500,
        Dependency = "BtnWeapon1"
    },
    ["BtnWeapon3"] = {
        Id = 403,
        Name = "Katana",
        Target = "Weapon3",
        Type = "Building",
        Price = 12000,
        Dependency = "BtnWeapon2"
    },
    ["BtnWeapon4"] = {
        Id = 404,
        Name = "Energy Sword",
        Target = "Weapon4",
        Type = "Building",
        Price = 30000,
        Dependency = "BtnWeapon3"
    },
}

return ButtonConfig