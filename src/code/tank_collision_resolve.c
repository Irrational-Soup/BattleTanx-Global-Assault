#include "types.h"
typedef s32 M2C_UNK;
#define M2C_FIELD(expr, type_ptr, offset) (*(type_ptr)((s8 *)(expr) + (offset)))
typedef struct { f32 x, y; } Vec2;
typedef struct { Vec2 point; s32 zero; u16 angle; u16 unknown0E; s32 zero10; s32 owner; s32 flags; u16 feature; u16 unknown1E; f32 *mover; s32 unknown24; } ContactEvent;
typedef struct { s32 code; unsigned char payload[28]; } ContactResponse;
typedef struct { void (*fn)(void *, s32 *, s32, ContactEvent *, ContactResponse *); s32 other[2]; } CallbackEntry;
typedef struct { void *object; u16 id; char rest[26]; u16 side; char pad[2]; } Contact;
typedef struct {
    float velocityX;
    float velocityY;
    float speed;
    float acceleration;
    float drag;
    float scale;
    u16 unk18;
    float unk1C;
    short unk20;
    float unk24;
    float unk28;
    float unk2C;
    float unk30;
    int unk34;
    float multiplier;
    unsigned char unknown3C[0x28];
    u16 flags64;
} Mover;


/* SPAN 0x800B8100 */

M2C_UNK func_8008BD5C(void *, M2C_UNK, M2C_UNK, M2C_UNK); /* extern */
M2C_UNK func_8009060C(s32, ContactResponse *);                  /* extern */
M2C_UNK func_8009660C(void *, f32, void *);         /* extern */
M2C_UNK func_80098B58(u8, M2C_UNK, s16, s32);       /* extern */
f32 func_8009D4B0(u16);                             /* extern */
f32 func_8009D510(u16);                             /* extern */
f32 func_8009E948(f32 *v);                                 /* extern */
M2C_UNK func_800B129C(u16, s16, s16);               /* extern */
s32 func_800B3748(u16, M2C_UNK, Contact *, M2C_UNK, s32); /* extern */
M2C_UNK func_800B66E0(f32 *, f32 *);                /* extern */
s32 func_800B6F40(f32 *, u16, f32 *, void *, Contact *, u32, void **, f32 *, u16 *); /* extern */
void *func_800EFC28(void *);                          /* extern */
extern f32 D_8007312C;
extern f32 D_80073130;
extern f32 D_80073134;
extern f64 D_80073138;
/* Compiler-emitted conversion threshold owns 0x80073140..0x80073148. */
/* RODATA_VRAM 0x80073140 */
extern f32 D_80073148;
extern u16 D_80116700;
extern u16 D_80116704;
extern f32 D_80219488;
extern CallbackEntry D_80224B5C[];
extern s16 D_80397650;
typedef struct { u32 kind; s32 unknown4; u16 links[4]; s16 x,z,y,dx0,dx1,dz0,dz1,height0,height1,radius; u16 angle,grid; } GridNode;
extern GridNode D_803978E0[];

static inline s32 scan_expected(Contact *list, u16 count) {
    Contact *c = list;
    void *body;
    u16 i;
    s32 expected;
    u16 side;
    s32 result = 0;
    for (i = 0; i < count; c++, i++) {
        GridNode *g = &D_803978E0[c->id];
        if (g->kind == 0x200000) {
            body = M2C_FIELD(c->object, void **, 0x10);
            if (func_800EFC28(body) == c->object) {
                expected = 1;
                if (M2C_FIELD(body, s16 *, 0x3E) < 0) { side = c->side; expected = 2; }
                else { side = c->side; }
                if (side == expected) result = 1;
            }
        }
    }
    return result;
}
static inline s32 scan_nested(Contact *list, u16 count) {
    Contact *c = list;
    void *body;
    u16 i;
    s32 result = 0;
    for (i = 0; i < count; c++, i++) {
        GridNode *g = &D_803978E0[c->id];
        if (g->kind == 0x200000) {
            body = M2C_FIELD(c->object, void **, 0x10);
            if (func_800EFC28(body) == c->object) {
                if (M2C_FIELD(body, s16 *, 0x3E) < 0) {
                    if (c->side == 2) result = 1;
                } else if (c->side == 1) result = 1;
            }
        }
    }
    return result;
}

static inline s32 scan_expected_from(Contact *list, u16 start, u16 count) {
    Contact *c = list; void *body; u16 i; s32 expected; u16 side; s32 result = 0;
    for (i = start; i < count; c++, i++) { GridNode *g = &D_803978E0[c->id]; if (g->kind == 0x200000) { body = M2C_FIELD(c->object, void **, 0x10); if (func_800EFC28(body) == c->object) { expected = 1; if (M2C_FIELD(body, s16 *, 0x3E) < 0) { side = c->side; expected = 2; } else side = c->side; if (side == expected) result = 1; } } } return result;
}
static inline s32 scan_nested_from(Contact *list, u16 start, u16 count) {
    Contact *c = list; void *body; u16 i; s32 result = 0;
    for (i = start; i < count; c++, i++) { GridNode *g = &D_803978E0[c->id]; if (g->kind == 0x200000) { body = M2C_FIELD(c->object, void **, 0x10); if (func_800EFC28(body) == c->object) { if (M2C_FIELD(body, s16 *, 0x3E) < 0) { if (c->side == 2) result = 1; } else if (c->side == 1) result = 1; } } } return result;
}

static inline s32 scan_expected_guard(Contact *list, u16 start, u16 count) { Contact *c = list; void *body; u16 i; s32 expected; u16 side; s32 result = 0; if (start < count) { i = 0; do { GridNode *g = &D_803978E0[c->id]; if (g->kind == 0x200000) { body = M2C_FIELD(c->object, void **, 0x10); if (func_800EFC28(body) == c->object) { expected = 1; if (M2C_FIELD(body, s16 *, 0x3E) < 0) { side = c->side; expected = 2; } else side = c->side; if (side == expected) result = 1; } } c++; i++; } while (i < count); } return result; }
static inline s32 scan_guard1(Contact *list, u16 start, u32 count) { Contact *c = list; void *body; u16 i; s32 expected; u16 side; s32 result = 0; if (start < count) { u32 limit = count; i = 0; do { GridNode *g = &D_803978E0[c->id]; if (g->kind == 0x200000) { body = M2C_FIELD(c->object, void **, 0x10); if (func_800EFC28(body) == c->object) { expected = 1; if (M2C_FIELD(body, s16 *, 0x3E) < 0) { side = c->side; expected = 2; } else side = c->side; if (side == expected) result = 1; } } c++; i++; } while (i < limit); } return result; }
static inline s32 scan_nested_guard(Contact *list, u16 start, u16 count) { Contact *c; void *body; u16 i; u16 limit = count; s32 result = 0; c = list; i = 0; if (start < limit) { do { GridNode *g = &D_803978E0[c->id]; if (g->kind == 0x200000) { body = M2C_FIELD(c->object, void **, 0x10); if (func_800EFC28(body) == c->object) { if (M2C_FIELD(body, s16 *, 0x3E) < 0) { if (c->side == 2) result = 1; } else if (c->side == 1) result = 1; } } c++; i++; } while (i < limit); } return result; }
static inline s32 scan_nested_guard_w(Contact *list, u32 start, u16 count) { Contact *c; void *body; u16 i; u16 limit = count; s32 result = 0; c = list; i = 0; if (start < limit) { do { GridNode *g = &D_803978E0[c->id]; if (g->kind == 0x200000) { body = M2C_FIELD(c->object, void **, 0x10); if (func_800EFC28(body) == c->object) { if (M2C_FIELD(body, s16 *, 0x3E) < 0) { if (c->side == 2) result = 1; } else if (c->side == 1) result = 1; } } c++; i++; } while (i < limit); } return result; }

static inline void mover_reduce_speed(Mover *mover, float amount) {
    float reduction;

    if (mover->speed <= 0.0) {
        return;
    }
    reduction = (mover->scale + amount) * D_80219488;
    if (reduction <= 0.0f) {
        return;
    }
    mover->speed -= reduction;
    if (mover->speed < 0.0) {
        mover->speed = 0.0f;
    }
}

static inline void mover_apply_force(Mover *mover, float amount, u16 angle, Vec2 *delta, Vec2 *direction) {
    float limit;
    float oldSpeed;
    float magnitude;

    if (mover->multiplier == D_8007312C) {
        limit = mover->acceleration * amount;
    } else {
        limit = mover->acceleration * mover->multiplier * amount;
    }
    if (limit == 0.0) {
        return;
    }
    oldSpeed = mover->speed;
    direction->x = func_8009D4B0(angle);
    direction->y = func_8009D510(angle);
    if (limit < 0.0f) {
        limit = -limit;
        direction->y = -direction->y;
        direction->x = -direction->x;
    }
    magnitude = mover->drag * D_80219488;
    delta->x = magnitude * direction->x;
    delta->y = magnitude * direction->y;
    mover->velocityX *= mover->speed;
    mover->velocityY *= mover->speed;
    mover->velocityX += delta->x;
    mover->velocityY += delta->y;
    mover->speed = func_8009E948(&mover->velocityX);
    if (oldSpeed <= limit && limit < mover->speed) {
        mover->speed = limit;
    } else if (limit < oldSpeed && oldSpeed < mover->speed) {
        mover->speed = oldSpeed;
    }
}

static inline s16 extent_s16_early(s32 a, s16 b) { if(a-b>0) return a-b; return b-a; }
#define EXT(a,b) ((a)-(b)>0 ? (a)-(b) : (b)-(a))

static inline void place_node(u16 id, u16 angle, s16 x, s16 z) {
    GridNode *node = &D_803978E0[id];
    node->angle = angle;
    func_800B129C(id, x, z);
}

s32 func_800B74B4(f32 *arg0, f32 arg1, u16 arg2, void *arg3, void *arg4, u16 arg5, s32 *arg6, s16 *arg7) {
    Vec2 position;
    Vec2 sample;
    Vec2 step;
    Vec2 hit;
    ContactEvent event;
    ContactResponse response;
    Contact contacts[32];
    Vec2 force;
    Vec2 direction;
    struct { s16 dimensions[2]; void *selected; u16 feature; } contact_result;
    u16 sp536;
    u16 sp53E;
    s32 sp544;
    Contact *var_s1_330;
    Contact *var_s1_428;
    Contact *var_s1_507;
    Contact *var_s1_619;
    f32 temp_f0_104;
    f32 temp_f0_144;
    f32 temp_f0_474;
    f32 temp_f0_62;
    f32 temp_f0_758;
    f32 temp_f22_100;
    f32 temp_f24_237;
    f32 temp_f2_225;
    f32 temp_f2_477;
    f32 temp_f2_67;
    f32 temp_f2_75;
    f32 temp_f2_824;
    f32 temp_f4_121;
    f32 temp_f4_227;
    f32 temp_f6_50;
    f32 var_f0_675;
    f32 var_f20_256;
    f32 var_f20_83;
    f32 var_f22_243;
    f32 var_f2_274;
    f64 temp_f2_769;
    s16 temp_v0_190;
    s16 temp_v0_201;
    s16 temp_v1_191;
    s16 temp_v1_202;
    s16 var_a0_197;
    s16 var_a0_209;
    s16 var_a1_219;
    s32 temp_a0_738;
    s32 temp_v0_787;
    s32 temp_v1_715;
    s32 var_a2_789;
    s32 var_s3_328;
    s32 var_s3_425;
    s32 var_s3_505;
    s32 var_s3_615;
    s32 var_s4_612;
    s32 var_s5_324;
    s32 var_s5_421;
    s32 var_s5_501;
    s32 var_t0_352;
    s32 var_t0_529;
    s32 var_v0_677;
    s32 var_v0_779;
    s32 var_v1_311;
    u16 var_v1_777;
    u32 shared_status;
    u32 temp_a0_307;
    u16 temp_s7_309;
    u32 temp_v1_315;
    u32 temp_v1_419;
    u32 temp_v1_498;
    u16 temp_v1_609;
    Contact *var_s2_325;
    Contact *var_s2_422;
    Contact *var_s2_502;
    Contact *var_s2_611;
    void *temp_a0_552;
    void *temp_a0_665;
    void *temp_a0_686;
    void *temp_a0_749;
    void *temp_a0_810;
    void *temp_a2_188;
    void *temp_s0_344;
    void *temp_s0_442;
    void *temp_s0_521;
    void *temp_s0_633;

    sp53E = arg5;
    sp536 = arg2;
    sp544 = M2C_FIELD(arg6, s32 *, 0);
    if (arg7 != 0) {
        *arg7 = 0;
    }
    if ((D_80116704 != 0) || (((Mover *)arg0)->flags64 & 0xF)) {
        mover_reduce_speed((Mover *)arg0, 0.0f);
        mover_apply_force((Mover *)arg0, arg1, sp536, &force, &direction);
    }
    position.x = ((Vec2 *)arg3)->x;
    position.y = ((Vec2 *)arg3)->y;
    func_800B66E0(arg0, &position.x);
    if (D_80116700 == 0) {
        sample.x = ((Vec2 *)arg4)->x;
        temp_a2_188 = &D_803978E0[sp53E];
        sample.y = ((Vec2 *)arg4)->y;
        { s16 e;
        e = EXT(((GridNode *)temp_a2_188)->dx1, ((GridNode *)temp_a2_188)->dx0);
        contact_result.dimensions[0] = e;
        e = EXT(((GridNode *)temp_a2_188)->dz1, ((GridNode *)temp_a2_188)->dz0);
        contact_result.dimensions[1] = e; }
        var_a0_209 = contact_result.dimensions[1];
        var_a1_219 = contact_result.dimensions[0];
        if (var_a0_209 < contact_result.dimensions[0]) {
            var_a1_219 = var_a0_209;
        }
        temp_f2_225 = position.x - sample.x;
        temp_f4_227 = position.y - sample.y;
        step.x = temp_f2_225;
        temp_f24_237 = (f32) ((s32) (var_a1_219 << 0x10) >> 0x11) - D_80073130;
        step.y = temp_f4_227;
        if (step.x != 0.0f || step.y != 0.0f) var_f22_243 = func_8009E948(&step.x);
        else var_f22_243 = 0.0f;
        var_f20_256 = 0.0f;
        step.x *= temp_f24_237;
        step.y *= temp_f24_237;
        do {
            var_f20_256 += temp_f24_237;
            if (var_f20_256 < var_f22_243) {
                sample.x += step.x;
                sample.y += step.y;
            } else {
                sample.x = position.x;
                sample.y = position.y;
            }
            place_node(sp53E, sp536, (s16) (s32) sample.x, (s16) (s32) sample.y);
            D_80397650 = 1;
            temp_a0_307 = func_800B3748(sp53E, 0xE4540F, contacts, 0, 0) & 0xFFFF;
            temp_s7_309 = temp_a0_307;
            var_v1_311 = 1;
            if (!(var_f20_256 < var_f22_243)) {
                var_v1_311 = 0;
            }
            temp_v1_315 = temp_a0_307 < 1;
            temp_v1_315 = var_v1_311 & temp_v1_315;
        } while (temp_v1_315 != 0);
        if (temp_a0_307 != 0) {
            if (arg7 != 0) {
                *arg7 = 0x10;
            }
            var_s5_324 = scan_guard1(contacts, var_v1_311, temp_a0_307);
            if (!(var_s5_324 & 0xFFFF)) {
                shared_status = func_800B6F40(arg0, sp53E, &sample.x, arg4, contacts, temp_s7_309, &contact_result.selected, &hit.x, &contact_result.feature) & 0xFFFF;
                if (shared_status != 0) {
                    ((Vec2 *)arg3)->x = (f32) ((Vec2 *)arg4)->x;
                    ((Vec2 *)arg3)->y = (f32) ((Vec2 *)arg4)->y;
                    return 1;
                }
                func_800B129C(sp53E, (s16) (s32) sample.x, (s16) (s32) sample.y);
                D_80397650 = 1;
                temp_v1_419 = func_800B3748(sp53E, 0xE4540F, contacts, 0, 0) & 0xFFFF;
                var_s5_421 = 0;
                if (temp_v1_419 != 0) {
                    var_s5_421 = scan_nested_guard(contacts, shared_status, temp_v1_419);
                    shared_status = var_s5_421 & 0xFFFF;
                    if (shared_status == 0) {
                        temp_f0_474 = ((Vec2 *)arg3)->x;
                        sample.x = temp_f0_474;
                        temp_f2_477 = ((Vec2 *)arg3)->y;
                        sample.y = temp_f2_477;
                        func_800B129C(sp53E, (s16) (s32) temp_f0_474, (s16) (s32) temp_f2_477);
                        D_80397650 = 1;
                        temp_v1_498 = func_800B3748(sp53E, 0xE4540F, contacts, 0, 0) & 0xFFFF;
                        if (temp_v1_498 != 0) {
                            var_s5_501 = scan_expected_guard(contacts, shared_status, temp_v1_498);
                            if (var_s5_501 & 0xFFFF) {
block_79:
                                temp_a0_552 = M2C_FIELD(arg6, void **, 0xC);
                                if (temp_a0_552 != 0) {
                                    func_8008BD5C(temp_a0_552, 0x7530, 0, 1);
                                }
                                return 1;
                            }
                            ((Mover *)arg0)->speed = 0.0f;
                            shared_status = func_800B6F40(arg0, sp53E, &sample.x, arg4, contacts, temp_v1_498, &contact_result.selected, &hit.x, &contact_result.feature) & 0xFFFF;
                            { u16 status_test = shared_status;
                            if (status_test != 0) {
                                f32 success_y = ((Vec2 *)arg4)->y;
                                ((Vec2 *)arg3)->x = ((Vec2 *)arg4)->x;
                                ((Vec2 *)arg3)->y = success_y;
                                return 1;
                            }
                            func_800B129C(sp53E, (s16) (s32) sample.x, (s16) (s32) sample.y);
                            D_80397650 = 1;
                            temp_v1_609 = func_800B3748(sp53E, 0xE4540F, contacts, 0, 0);
                            if (temp_v1_609 != 0) {
                                var_s4_612 = scan_nested_guard_w(contacts, shared_status, temp_v1_609);
                                if (var_s4_612 & 0xFFFF) {
                                    temp_a0_665 = M2C_FIELD(arg6, void **, 0xC);
                                    if (temp_a0_665 != 0) {
                                        func_8008BD5C(temp_a0_665, 0x7530, 0, 1);
                                    }
                                }
                                ((Vec2 *)arg3)->x = (f32) ((Vec2 *)arg4)->x;
                                var_f0_675 = ((Vec2 *)arg4)->y;
                                var_v0_677 = 1;
                                goto block_130;
                            }
                            goto block_99;
                            }
                        }
                        goto block_99;
                    }
                    goto block_79;
                }
                goto block_99;
block_99:
                ((Vec2 *)arg3)->x = sample.x;
                ((Vec2 *)arg3)->y = sample.y;
                if (contact_result.selected != 0) {
                    temp_a0_686 = M2C_FIELD(arg6, void **, 0xC);
                    response.code = 2;
                    event.zero = 0;
                    event.mover = arg0;
                    event.zero10 = 0;
                    event.angle = sp536;
                    event.point.x = hit.x;
                    event.point.y = hit.y;
                    event.feature = contact_result.feature;
                    if (temp_a0_686 != 0) {
                        event.owner = M2C_FIELD(temp_a0_686, s32 *, 0x1D0);
                        event.flags = M2C_FIELD(temp_a0_686, s32 *, 0x1E0) & 2;
                    } else {
                        event.owner = 0;
                        event.flags = 0;
                    }
                    temp_v1_715 = M2C_FIELD(contact_result.selected, s32 *, 4);
                    if (D_80224B5C[temp_v1_715].fn != 0) {
                        D_80224B5C[temp_v1_715].fn(contact_result.selected, arg6, 0, &event, &response);
                    }
                } else {
                    response.code = 9;
                }
                temp_a0_738 = M2C_FIELD(arg6, s32 *, 0xC);
                if (temp_a0_738 != 0) {
                    func_8009060C(temp_a0_738, &response);
                }
                if (M2C_FIELD(arg6, s32 *, 4) == 4) {
                    temp_a0_749 = M2C_FIELD(arg6, void **, 0xC);
                    if ((temp_a0_749 != 0) && (M2C_FIELD(temp_a0_749, s32 *, 0x1E0) & 2)) {
                        temp_f0_758 = ((Mover *)arg0)->speed / ((Mover *)arg0)->acceleration;
                        if (D_80073134 < temp_f0_758) {
                            temp_f2_769 = (f64) (temp_f0_758 - D_80073134) * D_80073138;
                            var_v1_777 = (u16)temp_f2_769;
                            temp_v0_787 = (s16)var_v1_777;
                            var_a2_789 = var_v1_777;
                            if (temp_v0_787 != 0) {
                                if (temp_v0_787 >= 0xB) {
                                    var_a2_789 = 0xA;
                                }
                                func_80098B58(M2C_FIELD(M2C_FIELD(temp_a0_749, void **, 0x1D0), u8 *, 0xB), 0xA, (s16) var_a2_789, 0xA - (s16) var_a2_789);
                            }
                        }
                    }
                }
                if (sp544 == M2C_FIELD(arg6, s32 *, 0)) {
                    temp_a0_810 = M2C_FIELD(arg6, void **, 0xC);
                    if (temp_a0_810 != 0) {
                        func_8009660C(temp_a0_810, ((Mover *)arg0)->speed / ((Mover *)arg0)->acceleration, contact_result.selected);
                    }
                }
                temp_f2_824 = D_80073148 * ((Mover *)arg0)->speed;
                ((Mover *)arg0)->speed = temp_f2_824;
                if (temp_f2_824 < 0.0f) {
                    ((Mover *)arg0)->velocityX = -((Mover *)arg0)->velocityX;
                    ((Mover *)arg0)->velocityY = (f32) -((Mover *)arg0)->velocityY;
                    ((Mover *)arg0)->speed = (f32) -((Mover *)arg0)->speed;
                }
                return 0;
            }
            goto block_79;
        }
        goto block_129;
    }
block_129:
    ((Vec2 *)arg3)->x = position.x;
    var_f0_675 = position.y;
    var_v0_677 = 0;
block_130:
    ((Vec2 *)arg3)->y = var_f0_675;
    return var_v0_677;
}
