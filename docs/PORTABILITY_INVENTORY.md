# Native-port blocker inventory

This file is generated from `config/portability.toml` by
`tools/portability_report.py`. Do not edit it by hand.

Normalizer-assisted C is deliberately absent unless it also contains a
detected target-specific construct. Normalizer rules belong only to the
N64 byte-matching pipeline and are not runtime dependencies.

Files requiring review or target work: **259**.

## Categories

| Category | Files |
|---|---:|
| `libultra-audio-service` | 17 |
| `libultra-platform-service` | 83 |
| `mips-bootstrap-assembly` | 7 |
| `mips-libultra-assembly` | 18 |
| `mips-register-pinning` | 71 |
| `n64-display-list-construction` | 15 |
| `n64-memory-mapped-io` | 15 |
| `rsp-microcode` | 1 |
| `target-inline-assembly` | 118 |

## Required actions

| Action | Files |
|---|---:|
| `platform-adapter` | 133 |
| `replace-or-emulate` | 8 |
| `rewrite-portable` | 118 |

## Findings

| Source | Role | Categories | Actions |
|---|---|---|---|
| `src/code/unknown/800998E8.c` | recovered-game-and-audio | `n64-display-list-construction` | `platform-adapter` |
| `src/code/unknown/800A2FBC.c` | recovered-game-and-audio | `n64-display-list-construction` | `platform-adapter` |
| `src/code/unknown/800A3758.c` | recovered-game-and-audio | `n64-display-list-construction` | `platform-adapter` |
| `src/code/unknown/800A477C.c` | recovered-game-and-audio | `n64-display-list-construction` | `platform-adapter` |
| `src/code/unknown/800A5BD8.c` | recovered-game-and-audio | `n64-display-list-construction` | `platform-adapter` |
| `src/code/unknown/800A9F10.c` | recovered-game-and-audio | `n64-display-list-construction` | `platform-adapter` |
| `src/code/unknown/800BBDC0.c` | recovered-game-and-audio | `n64-display-list-construction` | `platform-adapter` |
| `src/code/weapons/800DB1B0_projectile_segment_spawn.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/script/800DF89C_entry_helpers.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/gameplay/80078E34_os_get_sr.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/math/8009D578_angle_fold.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/render/800AA058_area_lighting_build.c` | recovered-game-and-audio | `n64-display-list-construction` | `platform-adapter` |
| `src/code/render/8007A720_display_slot.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/effects/800F6C70_effect_billboard_draw.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/effects/800A40CC_effect_sprite_key_draw.c` | recovered-game-and-audio | `n64-display-list-construction` | `platform-adapter` |
| `src/code/effects/800A42C8_effect_sprite_ring_draw.c` | recovered-game-and-audio | `n64-display-list-construction` | `platform-adapter` |
| `src/code/unknown/80077FD0.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/80078DFC.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/unknown/80078E18.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/unknown/80078E40.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/unknown/8007A75C.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/8007AB64.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/8007AD40.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/unknown/8007AF84.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/unknown/8007B0E4.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/8007B190.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/8007D39C.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/8007D628.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/8007D998.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/8007DB84.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/8007DE3C.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/8007DFA0.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/unknown/8007E024.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/8007E170.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/8007E210.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/8007E268.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/8007E7A8.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/80080AF4.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/80080B58.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/unknown/80080BC0.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/80080C04.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/80082B68.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/unknown/80082D10.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/80082F1C.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/80083028.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/unknown/800830F8.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/unknown/80083DF0.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/80083EBC.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/80083F74.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/80085C30.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/80085DA8.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/800866B0.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/80086700.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/80086BEC.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/unknown/80087F2C.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/unknown/8008875C.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/unknown/80088ABC.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/80089610.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/unknown/80089E28.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/80089E84.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/8008A3A0.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/unknown/8008A5E4.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/unknown/8008AD80.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/unknown/8008B788.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/unknown/8008E620.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/unknown/8008E6BC.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/8008EC40.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/8008F3FC.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/8008F7E8.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/80090218.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/8009025C.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/unknown/80094744.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/80095B68.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/80095B90.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/80095E7C.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/80097C1C.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/80097EE4.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/unknown/80098250.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/8009836C.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/80098534.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/unknown/80098B58.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/unknown/80098F24.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/80098FBC.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/80099028.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/80099160.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/8009B35C.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/unknown/8009B3C8.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/unknown/8009D4B0.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/unknown/8009D510.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/8009D75C.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/unknown/8009E19C.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/unknown/8009E948.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/unknown/8009EB68.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/8009EC0C.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/unknown/8009F334.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/8009F444.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/unknown/8009F5AC.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/800A140C.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/800A18D0.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/800A1B44.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/800A2B9C.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/800A2E5C.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/unknown/800A2F0C.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/unknown/800A8E84.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/unknown/800A8F34.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/800A977C.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/800A98B8.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/unknown/800A9B64.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/800A9CCC.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/800ACEB4.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/800ACEFC.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/800ACF20.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/800ACFE0.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/800AD088.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/800B0268.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/unknown/800B6934.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/unknown/800B99AC.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/unknown/800BF798.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/800C0C38.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/unknown/800C21AC.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/800C2218.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/unknown/800E82AC.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/render/8007A0A0_graphics_frame_build.c` | recovered-game-and-audio | `n64-display-list-construction` | `platform-adapter` |
| `src/code/frontend/800D56FC_hud_draw_list.c` | recovered-game-and-audio | `n64-display-list-construction` | `platform-adapter` |
| `src/libmus/func_800FBDC8.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/libmus/func_800FD4CC.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/gameplay/800F3F78_mesh_rings_draw.c` | recovered-game-and-audio | `n64-display-list-construction` | `platform-adapter` |
| `src/code/gameplay/8009D144_mode_range.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/gameplay/800E80F4_multiplayer_actor_spawn.c` | recovered-game-and-audio | `target-inline-assembly` | `rewrite-portable` |
| `src/code/entities/800A2B74_object_range.c` | recovered-game-and-audio | `target-inline-assembly`, `mips-register-pinning` | `rewrite-portable` |
| `src/code/frontend/800C7C10_race_map_draw.c` | recovered-game-and-audio | `n64-display-list-construction` | `platform-adapter` |
| `src/code/frontend/800C9A3C_race_results_hud_draw.c` | recovered-game-and-audio | `n64-display-list-construction` | `platform-adapter` |
| `src/code/rsp_microcode_text.s` | recovered-game-and-audio | `rsp-microcode` | `replace-or-emulate` |
| `src/libultra/al_aux_bus.c` | n64-platform | `libultra-audio-service` | `platform-adapter` |
| `src/libultra/al_copy.c` | n64-platform | `libultra-audio-service` | `platform-adapter` |
| `src/libultra/al_drvrnew.c` | n64-platform | `libultra-audio-service` | `platform-adapter` |
| `src/libultra/al_env.c` | n64-platform | `libultra-audio-service` | `platform-adapter` |
| `src/libultra/al_filter_new.c` | n64-platform | `libultra-audio-service` | `platform-adapter` |
| `src/libultra/al_heap_alloc.c` | n64-platform | `libultra-audio-service` | `platform-adapter` |
| `src/libultra/al_heap_init.c` | n64-platform | `libultra-audio-service` | `platform-adapter` |
| `src/libultra/al_load.c` | n64-platform | `libultra-audio-service` | `platform-adapter` |
| `src/libultra/al_main.c` | n64-platform | `libultra-audio-service` | `platform-adapter` |
| `src/libultra/al_main_bus.c` | n64-platform | `libultra-audio-service` | `platform-adapter` |
| `src/libultra/al_resample.c` | n64-platform | `libultra-audio-service` | `platform-adapter` |
| `src/libultra/al_reverb.c` | n64-platform | `libultra-audio-service` | `platform-adapter` |
| `src/libultra/al_save_param.c` | n64-platform | `libultra-audio-service` | `platform-adapter` |
| `src/libultra/al_save_pull.c` | n64-platform | `libultra-audio-service` | `platform-adapter` |
| `src/libultra/al_syn_alloc_fx.c` | n64-platform | `libultra-audio-service` | `platform-adapter` |
| `src/libultra/al_syn_delete.c` | n64-platform | `libultra-audio-service` | `platform-adapter` |
| `src/libultra/al_synthesizer.c` | n64-platform | `libultra-audio-service` | `platform-adapter` |
| `src/libultra/bcopy.s` | n64-platform | `mips-libultra-assembly` | `platform-adapter` |
| `src/libultra/bzero.s` | n64-platform | `mips-libultra-assembly` | `platform-adapter` |
| `src/libultra/exceptasm.s` | n64-platform | `mips-libultra-assembly` | `platform-adapter` |
| `src/libultra/getcount.s` | n64-platform | `mips-libultra-assembly` | `platform-adapter` |
| `src/libultra/getsr.s` | n64-platform | `mips-libultra-assembly` | `platform-adapter` |
| `src/libultra/interrupt.s` | n64-platform | `mips-libultra-assembly` | `platform-adapter` |
| `src/libultra/invaldcache.s` | n64-platform | `mips-libultra-assembly` | `platform-adapter` |
| `src/libultra/invalicache.s` | n64-platform | `mips-libultra-assembly` | `platform-adapter` |
| `src/libultra/libm_vals.s` | n64-platform | `mips-libultra-assembly` | `platform-adapter` |
| `src/libultra/maptlbrdb.s` | n64-platform | `mips-libultra-assembly` | `platform-adapter` |
| `src/libultra/os_ai_device_busy.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_ai_get_length.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_ai_get_status.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_ai_set_frequency.c` | n64-platform | `libultra-platform-service`, `n64-memory-mapped-io` | `platform-adapter` |
| `src/libultra/os_ai_set_next_buffer.c` | n64-platform | `libultra-platform-service`, `n64-memory-mapped-io` | `platform-adapter` |
| `src/libultra/os_cart_rom_init.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_cont_crc.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_cont_pfs.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_cont_query.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_cont_ram_read.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_cont_ram_write.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_cont_read_data.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_controller.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_create_mesg_queue.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_create_thread.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_dequeue_thread.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_destroy_thread.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_dev_mgr.c` | n64-platform | `libultra-platform-service`, `n64-memory-mapped-io` | `platform-adapter` |
| `src/libultra/os_dp_device_busy.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_dp_set_next_buffer.c` | n64-platform | `libultra-platform-service`, `n64-memory-mapped-io` | `platform-adapter` |
| `src/libultra/os_epi_raw_read_io.c` | n64-platform | `libultra-platform-service`, `n64-memory-mapped-io` | `platform-adapter` |
| `src/libultra/os_epi_raw_start_dma.c` | n64-platform | `libultra-platform-service`, `n64-memory-mapped-io` | `platform-adapter` |
| `src/libultra/os_epi_raw_write_io.c` | n64-platform | `libultra-platform-service`, `n64-memory-mapped-io` | `platform-adapter` |
| `src/libultra/os_epi_start_dma.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_get_thread_pri.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_get_time.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_initialize.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_jam_mesg.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_leo_disk_init.c` | n64-platform | `libultra-platform-service`, `n64-memory-mapped-io` | `platform-adapter` |
| `src/libultra/os_leo_interrupt.c` | n64-platform | `libultra-platform-service`, `n64-memory-mapped-io` | `platform-adapter` |
| `src/libultra/os_motor.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_pfs_allocate_file.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_pfs_checker.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_pfs_delete_file.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_pfs_file_state.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_pfs_find_file.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_pfs_free_blocks.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_pfs_get_id_copy.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_pfs_get_status.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_pfs_init_pak.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_pfs_is_plug.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_pfs_read_write_file.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_pi_access.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_pi_get_cmd_queue.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_pi_manager.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_pi_raw_read_io.c` | n64-platform | `libultra-platform-service`, `n64-memory-mapped-io` | `platform-adapter` |
| `src/libultra/os_pi_raw_start_dma.c` | n64-platform | `libultra-platform-service`, `n64-memory-mapped-io` | `platform-adapter` |
| `src/libultra/os_pi_start_dma.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_recv_mesg.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_reset_global_int_mask.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_send_mesg.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_set_event_mesg.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_set_global_int_mask.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_set_thread_pri.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_set_timer.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_si_access_queue.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_si_device_busy.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_si_raw_read_io.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_si_raw_start_dma.c` | n64-platform | `libultra-platform-service`, `n64-memory-mapped-io` | `platform-adapter` |
| `src/libultra/os_si_raw_write_io.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_sp_device_busy.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_sp_get_status.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_sp_raw_start_dma.c` | n64-platform | `libultra-platform-service`, `n64-memory-mapped-io` | `platform-adapter` |
| `src/libultra/os_sp_set_pc.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_sp_set_status.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_sp_task.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_sp_task_yield.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_sp_task_yielded.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_start_thread.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_timer.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_vi_black.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_vi_get_current_context.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_vi_get_current_framebuffer.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_vi_get_next_framebuffer.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_vi_init.c` | n64-platform | `libultra-platform-service`, `n64-memory-mapped-io` | `platform-adapter` |
| `src/libultra/os_vi_manager.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_vi_set_event.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_vi_set_mode.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_vi_set_special_features.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_vi_swap_buffer.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_vi_swap_context.c` | n64-platform | `libultra-platform-service`, `n64-memory-mapped-io` | `platform-adapter` |
| `src/libultra/os_virtual_to_physical.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/os_yield_thread.c` | n64-platform | `libultra-platform-service` | `platform-adapter` |
| `src/libultra/probetlb.s` | n64-platform | `mips-libultra-assembly` | `platform-adapter` |
| `src/libultra/setcompare.s` | n64-platform | `mips-libultra-assembly` | `platform-adapter` |
| `src/libultra/setfpccsr.s` | n64-platform | `mips-libultra-assembly` | `platform-adapter` |
| `src/libultra/setintmask.s` | n64-platform | `mips-libultra-assembly` | `platform-adapter` |
| `src/libultra/setsr.s` | n64-platform | `mips-libultra-assembly` | `platform-adapter` |
| `src/libultra/sqrtf.s` | n64-platform | `mips-libultra-assembly` | `platform-adapter` |
| `src/libultra/writebackdcache.s` | n64-platform | `mips-libultra-assembly` | `platform-adapter` |
| `src/libultra/writebackdcacheall.s` | n64-platform | `mips-libultra-assembly` | `platform-adapter` |
| `src/libgcc/udivmoddi4.c` | compiler-runtime | `target-inline-assembly` | `rewrite-portable` |
| `src/boot/entry.s` | n64-bootstrap | `mips-bootstrap-assembly` | `replace-or-emulate` |
| `src/boot/exception_context_save.s` | n64-bootstrap | `mips-bootstrap-assembly` | `replace-or-emulate` |
| `src/boot/exception_handler.s` | n64-bootstrap | `mips-bootstrap-assembly` | `replace-or-emulate` |
| `src/boot/exception_preamble.s` | n64-bootstrap | `mips-bootstrap-assembly` | `replace-or-emulate` |
| `src/boot/exception_vector_install.s` | n64-bootstrap | `mips-bootstrap-assembly` | `replace-or-emulate` |
| `src/boot/host_break.s` | n64-bootstrap | `mips-bootstrap-assembly` | `replace-or-emulate` |
| `src/boot/rmon_panic_stub.s` | n64-bootstrap | `mips-bootstrap-assembly` | `replace-or-emulate` |

## Interpretation

- `portable-review` means the C can enter a host build after width, endian,
  layout, and dependency review; it does not promise correctness on a host.
- `platform-adapter` means the behavior belongs behind a host/Vita service
  interface rather than being compiled as N64 hardware access.
- `rewrite-portable` means target-specific C or inline assembly needs a
  behaviorally tested portable implementation.
- `replace-or-emulate` applies to native MIPS/RSP source that cannot execute
  in a Windows or Vita process.
