fx_version 'cerulean'
game 'gta5'

author '2F4R'
description 'Advanced FiveM Anticheat — self-hosted, modular, no external API required.'
version '2.0.0'
lua54 'yes'

files {
    "html/**/*",
}

ui_page "html/index.html"

shared_scripts {
    "config.lua",
    "src/shared/enums.lua",
    "src/shared/utils.lua",
}

client_scripts {
    "src/client/main.lua",
    "src/client/heartbeat.lua",
    "src/client/nui_bridge.lua",
    "src/client/modules/anti_aimbot.lua",
    "src/client/modules/anti_noclip.lua",
    "src/client/modules/anti_godmode.lua",
    "src/client/modules/anti_speedhack.lua",
    "src/client/modules/anti_teleport.lua",
    "src/client/modules/anti_weapons.lua",
    "src/client/modules/anti_vehicle.lua",
    "src/client/modules/anti_spectate.lua",
    "src/client/modules/anti_invisible.lua",
    "src/client/modules/anti_freecam.lua",
    "src/client/modules/anti_resources.lua",
    "src/client/modules/anti_blacklist.lua",
    "src/client/modules/anti_injection.lua",
    "src/client/modules/anti_menu.lua",
    "src/client/modules/anti_thermal.lua",
    "src/client/modules/anti_superjump.lua",
    "src/client/modules/anti_ragdoll.lua",
    "src/client/modules/anti_explosions.lua",
    "src/client/modules/anti_field_of_view.lua",
    "src/client/modules/anti_chat_spam.lua",
    "src/client/modules/anti_honeypot.lua",
    "src/client/modules/anti_canary.lua",
    "src/client/modules/anti_integrity.lua",
    "src/client/modules/replay_buffer.lua",
    "src/client/modules/mouse_forensics.lua",
    "src/client/modules/combat_log.lua",
    "src/client/modules/physics_validator.lua",
}

server_scripts {
    "src/server/punishment.lua",
    "src/server/permissions.lua",
    "src/server/main.lua",
    "src/server/heartbeat.lua",
    "src/server/api.lua",
    "src/server/modules/entity_monitor.lua",
    "src/server/modules/explosion_monitor.lua",
    "src/server/modules/event_validation.lua",
    "src/server/modules/convar_hardening.lua",
    "src/server/modules/resource_monitor.lua",
    "src/server/modules/damage_validation.lua",
    "src/server/modules/player_state.lua",
    "src/server/modules/admin_commands.lua",
    "src/server/modules/threat_score.lua",
    "src/server/modules/shadow_mode.lua",
    "src/server/modules/cascading_ban.lua",
    "src/server/modules/vpn_detection.lua",
    "src/server/modules/account_age.lua",
    "src/server/modules/statebag_firewall.lua",
    "src/server/modules/combat_log_server.lua",
    "src/server/modules/antikick.lua",
    "src/server/modules/resource_tamper.lua",
    "src/server/modules/report_system.lua",
    "src/server/modules/auto_screenshot.lua",
    "src/server/modules/ban_sync.lua",
    "src/server/modules/webhook_enhanced.lua",
    "src/server/modules/module_hotreload.lua",
}
