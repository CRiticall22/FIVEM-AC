Config = {}

Config.Debug = false

Config.Branding = {
    Name = "ElectronAC",
    Version = "2.0.0",
}

Config.Discord = {
    BanWebhook       = "",
    KickWebhook      = "",
    WarnWebhook      = "",
    DetectionWebhook = "",
    BotName          = "ElectronAC",
    BotAvatar        = "",
    Color = {
        Ban  = 16711680,
        Kick = 16776960,
        Warn = 15039247,
        Info = 3066993,
    },
}

Config.Messages = {
    Kick = "[ElectronAC] You have been kicked.",
    Ban  = "[ElectronAC] You have been permanently banned.\nBan ID: %s\nReason: %s",
}

Config.Whitelist = {
    AcePerm          = "electronac.bypass",
    WhitelistTxAdmin = true,
}

Config.Modules = {
    antiAimbot          = { enabled = true,  punishment = "BAN" },
    antiAimAssist       = { enabled = true,  punishment = "WARN" },
    antiAmmo            = { enabled = true,  punishment = "BAN",  maxClip = 499, maxTotal = 499 },
    antiAnims           = { enabled = true,  punishment = "KICK" },
    antiArmor           = { enabled = true,  punishment = "BAN",  max = 100 },
    antiBlacklistName   = { enabled = true,  punishment = "KICK", blacklist = {} },
    antiBlacklistWords  = { enabled = false, punishment = "KICK", blacklist = {} },
    antiCommands        = { enabled = true,  punishment = "BAN" },
    antiCrasher         = { enabled = true,  punishment = "BAN" },
    antiDamageChanger   = { enabled = true,  punishment = "BAN" },
    antiDevTools        = { enabled = true,  punishment = "KICK" },
    antiExplosion       = { enabled = true,  punishment = "BAN",  max = 10 },
    antiExplosiveWeapon = { enabled = true,  punishment = "BAN" },
    antiFolder          = { enabled = true,  punishment = "BAN" },
    antiGodmode         = { enabled = true,  punishment = "BAN" },
    antiHealth          = { enabled = true,  punishment = "BAN",  max = 200 },
    antiHornBoost       = { enabled = true,  punishment = "BAN" },
    antiInjector        = { enabled = true,  punishment = "BAN" },
    antiInvisible       = { enabled = true,  punishment = "BAN" },
    antiLicenseClear    = { enabled = true,  punishment = "BAN" },
    antiMenu            = { enabled = true,  punishment = "BAN" },
    antiNetworkedSounds = { enabled = true },
    antiNightVision     = { enabled = true,  punishment = "KICK" },
    antiNoclip          = { enabled = true,  punishment = "BAN" },
    antiNoHeadshot      = { enabled = true,  punishment = "BAN" },
    antiNuiBlocker      = { enabled = true,  punishment = "BAN" },
    antiObject          = { enabled = true,  punishment = "WARN", max = 30, whitelist = {} },
    antiParticles       = { enabled = true,  punishment = "WARN", max = 50 },
    antiPed             = { enabled = true,  punishment = "BAN",  max = 15, whitelist = {
        "mp_m_freemode_01", "mp_f_freemode_01",
        "a_m_m_skidrow_01", "a_f_m_beach_01", "a_m_y_mexthug_01",
        "u_m_y_rsranger_01", "s_m_y_cop_01", "s_f_y_cop_01",
        "s_m_y_hwaycop_01", "s_m_y_sheriff_01", "s_f_y_sheriff_01",
        "s_m_m_paramedic_01", "s_m_y_fireman_01",
        "csb_trafficwarden", "s_m_y_garbage",
    } },
    antiPedTasks        = { enabled = true,  punishment = "BAN",  max = 15 },
    antiPhoneExplosions = { enabled = true },
    antiPickup          = { enabled = true,  punishment = "WARN" },
    antiPlate           = { enabled = true,  punishment = "BAN" },
    antiPlaySound       = { enabled = true,  punishment = "BAN" },
    antiRemoveWeapon    = { enabled = true,  punishment = "BAN" },
    antiAddWeapon       = { enabled = true,  punishment = "BAN" },
    antiSilentAim       = { enabled = true,  punishment = "BAN" },
    antiSoftAim         = { enabled = true,  punishment = "WARN" },
    antiSpectate        = { enabled = true,  punishment = "BAN" },
    antiSpeedChanger    = { enabled = true,  punishment = "BAN" },
    antiStamina         = { enabled = true,  punishment = "BAN" },
    antiSuperJump       = { enabled = true,  punishment = "BAN" },
    antiTaze            = { enabled = true,  punishment = "KICK", max = 10 },
    antiTeleport        = { enabled = true,  punishment = "BAN" },
    antiThermalVision   = { enabled = true,  punishment = "KICK" },
    antiTrigger         = { enabled = true,  punishment = "BAN",  blacklist = {} },
    antiUnderMap        = { enabled = true,  punishment = "WARN" },
    antiVDM             = { enabled = true },
    antiVehicle         = { enabled = true,  punishment = "BAN",  max = 10, blacklist = {} },
    antiVehicleWeapons  = { enabled = true,  punishment = "BAN" },
    antiVariable        = { enabled = true,  punishment = "BAN" },
    antiWallHack        = { enabled = true,  punishment = "BAN" },
    antiWeapon          = { enabled = true,  punishment = "BAN",  blacklist = {} },
    antiWeaponSpoofer   = { enabled = true,  punishment = "BAN" },
    antiEntityTakeover  = { enabled = true },
    antiResourceStop    = { enabled = true,  blacklist = {} },
    antiEventSpam       = { enabled = true,  max = 50, window = 10 },
}

Config.Logs = {
    Console = true,
    ShowIPs = false,
}

Config.Preferences = {
    GlobalBans    = false,
    DiscordInvite = "",
}

Config.Screenshot = {
    Enabled  = true,
    Quality  = 0.92,
    Encoding = "webp",
}

Config.OCR = {
    Enabled      = true,
    ScanInterval = 3000,
    Blacklist    = {
        "hydro menu", "lynx menu", "brutan menu", "dopamine menu",
        "maestro menu", "fallout menu", "wave menu", "reaper menu",
        "alien menu", "ham menu", "oblivious menu", "skid menu",
    },
}

Config.LiveView = {
    Enabled = true,
}

Config.BlacklistedPlates = {
    "Desudo", "LynxMenu", "AKTeam", "Ancient", "BRUTAN", "Brutan#7799",
    "AlikhanMenu", "GEJ", "LYNX", "CK GANG", "Tiago", "Swag Menu",
    "HamHaxia", "eulencheats", "EulenMenu", "Falcon", "Shadow", "AlphaV",
    "Luminous", "Lux Menu", "Malossi Menu V3", "Malossi", "obl2", "S1MLLER",
    "iSeekFR", "Skaza", "TITOModz", "ZajacMenu",
}

Config.BlacklistedCommands = {
    "killmenu", "chocolate", "pk", "haha", "lol", "panickey",
    "panik", "lynx", "brutan", "panic", "purgemenu",
}

Config.BlacklistedVariables = {
    "nexus", "WarMenu", "AlikhanCheats", "gaybuild", "Plane", "LynxEvo",
    "FendinX", "LR", "Lynx8", "MIOddhwuie", "ililililil", "esxdestroyv2",
    "LiLLL", "obl2", "HamMafia", "Absolute", "Absolute_function",
    "TiagoMenu", "SkazaMenu", "BrutanPremium", "b00mMenu", "Cience",
    "MaestroMenu", "Crusader", "NertigelFunc", "dreanhsMod", "nukeserver",
    "SDefwsWr", "FlexSkazaMenu", "DynnoFamily", "FrostedMenu",
    "frosted_config", "FXMenu", "CKgang", "HoaxMenu", "alkomenu", "xseira",
    "KoGuSzEk", "LynxSeven", "lynxunknowncheats", "MaestroEra", "foriv",
    "ariesMenu", "Ham", "Outcasts666", "b00mek", "redMENU", "rootMenu",
    "xnsadifnias", "LDOWJDWDdddwdwdad", "moneymany", "VOITUREMenu",
    "fESX", "dexMenu", "zzzt", "AKTeam", "SwagMenu", "Gatekeeper",
    "Dopameme", "Lux", "Swag", "SwagUI", "Nisi", "nigmenu0001", "Motion",
    "MMenu", "FantaMenuEvo", "GRubyMenu", "InSec", "AlphaVeta",
    "ShaniuMenu", "HamHaxia", "FendinXMenu", "AlphaV", "Deer",
    "NyPremium", "lIlIllIlI", "OnionUI", "qJtbGTz5y8ZmqcAg", "LuxUI",
    "JokerMenu", "IlIlIlIlIlIlI", "SidMenu", "GheMenu", "INFINITY",
    "klVZJu56hiZnIjg88ekXcEgegjfDvuMv83grKxQiUJJFvN8SHENeK2WaRgTTuafpGe",
    "jailServerLoop", "carSpamServer", "Dopamine", "nofuckinglol",
}

Config.MenuTextures = {
    { txd = "HydroMenu",   txt = "HydroMenuHeader",  name = "HydroMenu" },
    { txd = "John",        txt = "John2",             name = "SugarMenu" },
    { txd = "darkside",    txt = "logo",              name = "Darkside" },
    { txd = "ISMMENU",     txt = "ISMMENUHeader",     name = "ISMMENU" },
    { txd = "dopatest",    txt = "duiTex",            name = "Copypaste Menu" },
    { txd = "fm",          txt = "menu_bg",           name = "Fallout Menu" },
    { txd = "wave",        txt = "logo",              name = "Wave" },
    { txd = "wave1",       txt = "logo1",             name = "Wave (alt.)" },
    { txd = "meow2",       txt = "woof2",             name = "Alokas66", x = 1000, y = 1000 },
    { txd = "MM",          txt = "menu_bg",           name = "Metrix Methods" },
    { txd = "wm",          txt = "wm2",               name = "WM Menu" },
    { txd = "NeekerMan",   txt = "NeekerMan1",        name = "Lumia Menu" },
    { txd = "Blood-X",     txt = "Blood-X",           name = "Blood-X Menu" },
    { txd = "Dopamine",    txt = "Dopameme",          name = "Dopamine Menu" },
    { txd = "Fallout",     txt = "FalloutMenu",       name = "Fallout Menu" },
    { txd = "Luxmenu",     txt = "Lux meme",          name = "LuxMenu" },
    { txd = "Reaper",      txt = "reaper",            name = "Reaper Menu" },
    { txd = "absoluteeulen", txt = "Absolut",         name = "Absolut Menu" },
    { txd = "KekHack",     txt = "kekhack",           name = "KekHack Menu" },
    { txd = "Maestro",     txt = "maestro",           name = "Maestro Menu" },
    { txd = "SkidMenu",    txt = "skidmenu",          name = "Skid Menu" },
    { txd = "Brutan",      txt = "brutan",            name = "Brutan Menu" },
    { txd = "FiveSense",   txt = "fivesense",         name = "Fivesense Menu" },
    { txd = "Auttaja",     txt = "auttaja",           name = "Auttaja Menu" },
    { txd = "BartowMenu",  txt = "bartowmenu",        name = "Bartow Menu" },
    { txd = "Hoax",        txt = "hoaxmenu",          name = "Hoax Menu" },
    { txd = "FendinX",     txt = "fendin",            name = "Fendinx Menu" },
    { txd = "Hammenu",     txt = "Ham",               name = "Ham Menu" },
    { txd = "Lynxmenu",    txt = "Lynx",              name = "Lynx Menu" },
    { txd = "Oblivious",   txt = "oblivious",         name = "Oblivious Menu" },
    { txd = "dopamine",    txt = "Swagamine",         name = "Dopamine" },
    { txd = "test",        txt = "Terror Menu",       name = "Terror Menu" },
    { txd = "lynxmenu",    txt = "lynxmenu",          name = "Lynx Menu" },
    { txd = "Maestro 2.3", txt = "Maestro 2.3",       name = "Maestro Menu" },
    { txd = "ALIEN MENU",  txt = "ALIEN MENU",        name = "Alien Menu" },
}

Config.BlacklistedTextureDicts = {
    "fm", "rampage_tr_main", "MenyooExtras",
    "shopui_title_graphics_franklin", "deadline", "cockmenuu",
}

Config.BlacklistedAnims = {
    { "rcmpaparazzi_2", "shag_loop_poppy" },
}

Config.BlacklistedTasks = { 100, 101, 151, 221, 222 }

Config.ExplosionTypes = {
    [0]  = { name = "Grenade",              ban = false },
    [1]  = { name = "GrenadeLauncher",      ban = true  },
    [2]  = { name = "StickBomb",            ban = false },
    [3]  = { name = "Molotov",              ban = true  },
    [4]  = { name = "Rocket",               ban = true  },
    [5]  = { name = "TankShell",            ban = true  },
    [6]  = { name = "HiOctane",             ban = false },
    [7]  = { name = "Car",                  ban = false },
    [8]  = { name = "Plane",                ban = false },
    [9]  = { name = "PetrolPump",           ban = false },
    [10] = { name = "Bike",                 ban = false },
    [11] = { name = "DirSteam",             ban = false },
    [12] = { name = "DirFlame",             ban = false },
    [13] = { name = "DirWaterHydrant",      ban = false },
    [14] = { name = "DirGasCanister",       ban = false },
    [15] = { name = "Boat",                 ban = false },
    [16] = { name = "ShipDestroy",          ban = false },
    [17] = { name = "Truck",                ban = false },
    [18] = { name = "Bullet",               ban = true  },
    [19] = { name = "SmokeGrenadeLauncher", ban = true  },
    [20] = { name = "SmokeGrenade",         ban = false },
    [21] = { name = "BZGAS",                ban = false },
    [22] = { name = "Flare",                ban = false },
    [23] = { name = "GasCanister",          ban = false },
    [24] = { name = "Extinguisher",         ban = false },
    [25] = { name = "Programmable",         ban = false },
    [26] = { name = "Train",                ban = false },
    [27] = { name = "Barrel",               ban = false },
    [28] = { name = "Propane",              ban = false },
    [29] = { name = "Blimp",                ban = true  },
    [30] = { name = "DirFlameExplode",      ban = false },
    [31] = { name = "Tanker",               ban = false },
    [32] = { name = "PlaneRocket",          ban = true  },
    [33] = { name = "VehicleBullet",        ban = false },
    [34] = { name = "GasTank",              ban = false },
    [35] = { name = "Firework",             ban = false },
    [36] = { name = "Snowball",             ban = false },
    [37] = { name = "ValkyrieCannon",       ban = true  },
}

Config.WeaponDamageTable = {
    [-1357824103] = { damage = 34,  name = "AdvancedRifle" },
    [453432689]   = { damage = 26,  name = "Pistol" },
    [1593441988]  = { damage = 27,  name = "CombatPistol" },
    [584646201]   = { damage = 25,  name = "APPistol" },
    [-1716589765] = { damage = 51,  name = "Pistol50" },
    [-1045183535] = { damage = 160, name = "Revolver" },
    [-1076751822] = { damage = 28,  name = "SNSPistol" },
    [-771403250]  = { damage = 40,  name = "HeavyPistol" },
    [137902532]   = { damage = 34,  name = "VintagePistol" },
    [324215364]   = { damage = 21,  name = "MicroSMG" },
    [736523883]   = { damage = 22,  name = "SMG" },
    [-270015777]  = { damage = 23,  name = "AssaultSMG" },
    [-1121678507] = { damage = 22,  name = "MiniSMG" },
    [-619010992]  = { damage = 27,  name = "MachinePistol" },
    [171789620]   = { damage = 28,  name = "CombatPDW" },
    [487013001]   = { damage = 58,  name = "PumpShotgun" },
    [2017895192]  = { damage = 40,  name = "SawnoffShotgun" },
    [-494615257]  = { damage = 32,  name = "AssaultShotgun" },
    [-1654528753] = { damage = 14,  name = "BullpupShotgun" },
    [984333226]   = { damage = 117, name = "HeavyShotgun" },
    [-1074790547] = { damage = 30,  name = "AssaultRifle" },
    [-2084633992] = { damage = 32,  name = "CarbineRifle" },
    [-1063057011] = { damage = 32,  name = "SpecialCarbine" },
    [2132975508]  = { damage = 32,  name = "BullpupRifle" },
    [1649403952]  = { damage = 44,  name = "CompactRifle" },
    [-1660422300] = { damage = 40,  name = "MG" },
    [2144741730]  = { damage = 45,  name = "CombatMG" },
    [1627465347]  = { damage = 34,  name = "Gusenberg" },
    [100416529]   = { damage = 101, name = "SniperRifle" },
    [205991906]   = { damage = 216, name = "HeavySniper" },
    [-952879014]  = { damage = 65,  name = "MarksmanRifle" },
    [1119849093]  = { damage = 30,  name = "Minigun" },
    [-1466123874] = { damage = 165, name = "Musket" },
    [911657153]   = { damage = 1,   name = "StunGun" },
    [1198879012]  = { damage = 10,  name = "FlareGun" },
    [-598887786]  = { damage = 220, name = "MarksmanPistol" },
    [1834241177]  = { damage = 30,  name = "Railgun" },
    [-275439685]  = { damage = 30,  name = "DoubleBarrelShotgun" },
    [-1746263880] = { damage = 81,  name = "DoubleActionRevolver" },
    [-2009644972] = { damage = 30,  name = "SNSPistolMk2" },
    [-879347409]  = { damage = 200, name = "HeavyRevolverMk2" },
    [-1768145561] = { damage = 32,  name = "SpecialCarbineMk2" },
    [-2066285827] = { damage = 33,  name = "BullpupRifleMk2" },
    [1432025498]  = { damage = 32,  name = "PumpShotgunMk2" },
    [1785463520]  = { damage = 75,  name = "MarksmanRifleMk2" },
    [961495388]   = { damage = 40,  name = "AssaultRifleMk2" },
    [-86904375]   = { damage = 33,  name = "CarbineRifleMk2" },
    [-608341376]  = { damage = 47,  name = "CombatMGMk2" },
    [177293209]   = { damage = 230, name = "HeavySniperMk2" },
    [-1075685676] = { damage = 32,  name = "PistolMk2" },
    [2024373456]  = { damage = 25,  name = "SMGMk2" },
}
