/* RODATA_VRAM 0x80072A10 */
/* SPAN 0x800A477C */
typedef unsigned char u8;
typedef unsigned short u16;
typedef int s32;
typedef unsigned int u32;
typedef float f32;

typedef struct { f32 x, y, z; } Vec3;
typedef struct { u32 w0, w1; } Gfx;
typedef struct { f32 t; char pad04[0x24]; } SpriteKey;
typedef struct {
    f32 start;
    f32 grow_end;
    f32 shrink_start;
    f32 end;
    u16 spin;
    u8 environment[3];
    u8 primitive[3];
    s32 model;
} SpritePhase;
typedef struct {
    char pad00[4];
    s32 duration;
    f32 scale;
    SpritePhase *phases;
    SpriteKey *keys;
} SpriteDefinition;
typedef struct {
    char pad00[0xC];
    SpriteDefinition *definition;
    s32 start_time;
    Vec3 position;
    u8 kind;
    u8 reverse;
    char pad22[2];
    f32 scale;
} SpriteEffect;

extern s32 D_8021945C;
extern void *D_803A53A0[];
u8 func_800AD14C(f32 x, f32 z, f32 radius, u8 kind);
void func_800A40CC(SpriteKey *key, f32 time, f32 scale, Vec3 *position,
                   s32 kind, u8 flag);
void func_800AD6A8(void *model, Vec3 *position, f32 sx, f32 sy, f32 sz,
                   u16 angle, s32 arg6, s32 arg7, u8 flag, Gfx *commands,
                   s32 command_count, s32 arg11);

void func_800A4468(SpriteEffect *effect) {
    SpriteDefinition *definition = effect->definition;
    u8 flag = func_800AD14C(effect->position.x, effect->position.y,
                           definition->scale, effect->kind);
    f32 time;
    s32 offset;

    if (flag == 0) {
        return;
    }
    time = (f32)(D_8021945C - effect->start_time) / (f32)definition->duration;
    if (effect->reverse) {
        time = 1.0f - time;
    }
    if (definition->keys != 0) {
        for (offset = 0; definition->keys[offset].t >= 0.0f; offset++) {
            func_800A40CC(&definition->keys[offset], time,
                          effect->scale * definition->scale,
                          &effect->position, effect->kind, flag);
        }
    }
    if (definition->phases != 0) {
        for (offset = 0;
             ((SpritePhase *)((unsigned long)offset +
                              (unsigned long)definition->phases))->start >= 0.0f;
             offset += sizeof(SpritePhase)) {
            SpritePhase *phase = (SpritePhase *)((unsigned long)offset +
                                                  (unsigned long)definition->phases);
            f32 base = effect->scale * definition->scale;
            f32 factor;
            f32 scale;
            Gfx commands[2];
            u16 angle;

            if ((phase->end < time) || (time < phase->start)) {
                continue;
            }
            angle = time * phase->spin;
            if (time < phase->grow_end) {
                factor = (time - phase->start) /
                         (phase->grow_end - phase->start);
                scale = base * factor;
            } else if (time < phase->shrink_start) {
                scale = base;
            } else {
                factor = 1.0f - ((time - phase->shrink_start) /
                                 (phase->end - phase->shrink_start));
                scale = base * factor;
            }
            {
                Gfx *command = &commands[0];
                command->w0 = 0xFA000000;
                command->w1 = ((phase->primitive[0] << 24) |
                               (phase->primitive[1] << 16) |
                               (phase->primitive[2] << 8)) | 0xFF;
            }
            {
                Gfx *command = &commands[1];
                command->w0 = 0xFB000000;
                command->w1 = (phase->environment[0] << 24) |
                              (phase->environment[1] << 16) |
                              (phase->environment[2] << 8);
            }
            func_800AD6A8(D_803A53A0[phase->model], &effect->position,
                           scale, scale, 0, angle, 0, 0, flag, commands, 2, 0);
        }
    }
}
