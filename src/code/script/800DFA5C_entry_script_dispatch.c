/* CFLAGS -O2 -G0 -mips3 -mgp32 -mfp32 -mcpu=r8000 */
/* func_800DFA5C (0x800DFA5C-0x800E1540, 0x1AE4) - entry-script opcode dispatcher.
 * EXACT whole-unit match: text 0x1AE4 + owned rodata 0x80075950 +0xDC (46-entry jump table,
 * 262.5 x2, 5-entry inner table) under the production pipeline and raw cc1 + ASN64.
 * Requires per-unit -mcpu=r8000 (BRANCH_COST 1 with r4000 scheduling); see HANDOFF.md.
 */
/* SPAN 0x800E1540 */
/* RODATA_VRAM 0x80075950 */
typedef unsigned char u8; typedef signed char s8; typedef unsigned short u16; typedef short s16;
typedef int s32; typedef unsigned int u32; typedef float f32; typedef double f64;

typedef struct { s16 u0, u2, u4, u6, u8_, uA; s16 uC; s16 uE; } Ent;  /* 16 bytes */
typedef struct { u8 pad[0x10]; u8 *u10; Ent *u14; s32 u18; s32 u1C; u8 pad2[0x38-0x20]; } Rec;
typedef struct { u8 pad[0x18]; u8 *u18; u8 pad2[4]; } Slot;
typedef struct { u8 pad[4]; Rec *recs; u8 pad2[0x9B7C-8]; s32 cnt[10]; Slot *slots; s32 *tbl; } Ctx;
typedef struct { u8 type; u8 u1; u16 u2; u16 u4; u16 u6; u8 u8_; u8 pad[3]; u16 uC; u16 uE; } Obj;

typedef struct { u8 p0[0xC]; s16 x0, z0, x1, z1; u8 p14[0xC]; } WLane;
typedef struct { f32 x, y; } V2w;
typedef struct { V2w p0, p1; f32 f; u8 c; } E18w;
typedef struct { WLane lanes[15]; u8 p1E0[0x14]; E18w e18[4]; } World;
typedef struct { World *world; } GameState;
extern GameState D_80219498;
typedef struct { f32 x, y; } V2;
extern u8 D_802194A4, D_802194A6;
extern u8 D_80219582[];

void func_800DF0D0(void *, void *, f32, f32, f32, u16, void *);
void _bzero(void *, s32);
f32 func_8009D4B0(s32); f32 func_8009D510(s32);
void func_800B03F4(); void func_800B05F4(); void func_800B06A8(); void func_800B1898();
void func_800B9AB0(); void func_800D8C60(); void func_800DD3A0(); void func_800DE930();
void func_800E1540(); void func_800E2308(); void func_800E2AEC(); void func_800E56D0();
void func_800E6E5C(); s32 func_800E8090(u16); void func_800E80F4(); void func_800E9990();
void func_800E9B50(); void func_800E9E80(); void func_800EAC30(); void func_800ED320();
void func_800ED990(); void func_800EF770(); void func_800F1B30(); void func_800F2BC0();
void func_800F33C0(); void func_800F5298(); void func_800F757C(); void func_800F7C30();
void func_800F7EC0(); void func_800F85F0(); void __dummy(); s32 func_8009D144(void); void func_800D7DE0();
extern struct { u8 pad[0x58]; u32 u58; } *D_8021958C; extern u8 D_80235F00[];

#define LVCHAIN(h, lv) { lv = 1; if (!(h < 0x6A)) { lv = 2; if (!(h < 0xD3)) lv = 3; } }
#define LOOK(idx) look(ctx, arg5, idx)
#define ENT(idx) (&ctx->recs[arg5].u14[idx])

#define B13(e0, fl) { Ent *e = (e0); func_800B1898(0, (s16)v[0], (s16)v[1], 0, (e)->u4, (e)->uA, (e)->u8_, (e)->uE, \
    (s16)((e)->u6 + (s32)v[2]), (s16)((e)->uC + (s32)v[2]), arg3, fl, arg4); }
#define EMIT(t, s, a, b, c) { s = emitf(ctx, t, v, arg3, arg4, b, c, a); }
static inline u8 *emitf(Ctx *ctx, s32 *t, f32 *v, u16 arg3, u8 arg4, s32 b, u8 c, u8 a) {
    Slot *sl = &ctx->slots[arg4];
    u8 *s = sl->u18 + ctx->cnt[arg4]++ * 0x50;
    *(s32 **)(s + 0x48) = t;
    if (t != 0) { func_800DF0D0((u8 *)t + 4, s + 0x40, v[0], v[2], v[1], arg3, s);
        s[0x4E] = a; s[0x4C] = b; s[0x4D] = c; } else _bzero(s, 0x50);
    return s;
}

static inline s32 *look(Ctx *ctx, s32 i, u16 idx) {
    Rec *r = &ctx->recs[i];
    if (idx == 0xFFFF) return 0;
    return (s32 *)((u8 *)ctx->tbl + (r->u1C + idx) * 16);
}

/* Height band for an entry-script object: 1 below 0x6A, 3 at/above 0xD3, else 2. */
static inline u8 height_band(s32 h) {
    if (h < 0x6A) return 1;
    if (h >= 0xD3) return 3;
    return 2;
}

void func_800DFA5C(void *p, Ctx *ctx, f32 *v, u16 arg3, u8 arg4, s32 arg5) {
    Obj *obj = p;
    s32 ok;

    if (D_802194A4 < 2) {
        ok = 1;
    } else {
        switch (obj->type) {
        case 4: case 10: case 24: ok = 0; break;
        case 15: ok = (obj->u8_ == 1) | (obj->u8_ == 6); break;
        default: ok = 1; break;
        }
    }
    if (!ok) return;

    switch (obj->type) {
    case 0: {
        Obj *o = obj;
        s32 *t; u8 *s; s32 h; u8 lv;
        t = LOOK(o->u2);
        h = (s32)v[2] + ENT(o->u2)->uC;
        LVCHAIN(h, lv);
        EMIT(t, s, lv, 0, 0xF0);
        return;
    }
    case 2: {
        Obj *o = obj;
        s32 *t; u8 *s; s32 h; u8 lv;
        t = LOOK(o->u2);
        EMIT(t, s, 1, 1, 0xF0);
        if (o->u2 != 0xFFFF) {
            Ent *e2 = ENT(o->u2);
            if (e2->uC >= 2) B13(e2, 0x20);
        }
        return;
    }
    case 44: {
        Obj *o = obj;
        s32 *t; u8 *s; s32 h; u8 lv;
        t = LOOK(o->u2);
        EMIT(t, s, 1, 4, 0xF0);
        return;
    }
    case 34: {
        Obj *o = obj;
        s32 *t; u8 *s; s32 h; u8 lv;
        t = LOOK(o->u2);
        EMIT(t, s, 1, 1, 0xF0);
        if (t != 0) func_800F757C(*(s32 *)*t);
        return;
    }
    case 22: {
        Obj *o = obj;
        s32 *t; u8 *s; s32 h; u8 lv;
        t = LOOK(o->u2);
        EMIT(t, s, 1, 1, 0xF0);
        B13(ENT(o->u2), 0x80);
        return;
    }
    case 11: {
        Obj *o = obj;
        s32 *t; u8 *s; s32 h; u8 lv;
        t = LOOK(o->u2);
        EMIT(t, s, 1, 1, 0xF0);
        B13(ENT(o->u2), 0x40);
        return;
    }
    case 42:
        B13(ENT(obj->u2), 1);
        return;
    case 1:
    case 14: {
        Obj *o = obj;
        s32 *t; u8 *s; s32 h; u8 lv;
        t = LOOK(o->u2);
        h = (s32)v[2] + ENT(o->u2)->uC;
        if (((u8 *)o)[4]) {
            if ((h - 0x69 > 0 ? h - 0x69 : 0x69 - h) < 10) lv = 0x81;
            else if ((arg4 == 1 && (h - 0x90 > 0 ? h - 0x90 : 0x90 - h) < 10) ||
                     (h - 0xD2 > 0 ? h - 0xD2 : 0xD2 - h) < 10) lv = 0x82;
            else if (262.5 < h) lv = 0x83;
            else goto plain1;
        } else {
        plain1:
            lv = height_band(h);
        }
        EMIT(t, s, lv, 0, 0xF0);
        { s32 fl = 1; if (obj->type == 14) fl = 0x4000;
        B13(ENT(o->u2), fl); }
        return;
    }
    case 43: {
        Obj *o = obj;
        s32 *t; u8 *s; s32 h; u8 lv;
        t = LOOK(o->u2);
        h = (s32)v[2] + ENT(o->u2)->uC;
        if (((u8 *)o)[4]) {
            if ((h - 0x69 > 0 ? h - 0x69 : 0x69 - h) < 10) lv = 0x81;
            else if ((arg4 == 1 && (h - 0x90 > 0 ? h - 0x90 : 0x90 - h) < 10) ||
                     (h - 0xD2 > 0 ? h - 0xD2 : 0xD2 - h) < 10) lv = 0x82;
            else if (262.5 < h) lv = 0x83;
            else goto plain2;
        } else {
        plain2:
            lv = height_band(h);
        }
        EMIT(t, s, lv, 0, 0xF0);
        {
            s32 fl = 1; Ent *e;
            if (((u8 *)o)[5]) fl = 0x4000;
            e = ENT(o->u2);
            func_800B1898(0, (s16)v[0], (s16)v[1], 0, e->u4, e->uA, e->u8_, e->uE,
                          (s16)(e->u6 + (s32)v[2]), 5000, arg3, fl, arg4);
        }
        return;
    }
    case 35: {
        Obj *o = obj;
        u8 c = D_80219582[((u8 *)o)[5]];
        s32 k; s32 *t; u8 *s; s32 h; u8 lv;
        t = LOOK(o->u2);
        k = -((*(u8 **)t)[4] == 2) & 3;
        h = (s32)v[2] + ENT(o->u2)->uC;
        do { lv = 1; if (h < 0x6A) break; lv = 2; if (h < 0xD3) break; lv = 3; } while (0);
        EMIT(t, s, lv, k, 0xF0);
        {
            s32 fl = 1; Ent *e;
            if (((u8 *)o)[6]) fl = 0x20;
            e = ENT(o->u2);
            func_800B1898(0, (s16)v[0], (s16)v[1], 0, e->u4, e->uA, e->u8_, e->uE,
                          (s16)(e->u6 + (s32)v[2]), (s16)(e->uC + (s32)v[2]), arg3, fl, arg4);
        }
        func_800B9AB0(*(s32 **)(s + 0x48), c);
        return;
    }
    case 6:
        func_800B03F4(obj, v, arg3, arg4);
        return;
    case 5: func_800E1540(obj, ctx, v, arg3, arg4, arg5); return;
    case 4: func_800E2308(obj, ctx, v, arg3, arg4, arg5); return;
    case 7: func_800D8C60(v, arg4, obj->u1, 0, 0, ((u8 *)obj)[2]); return;
    case 12: {
        Obj *o = obj;
        s32 c = D_80219582[((u8 *)obj)[2]];
        if (c < D_802194A6) {
            if (obj->u4 != 0xFFFF) {
                s32 *t; u8 *s;
                t = LOOK(obj->u4);
                EMIT(t, s, 1, 0, 0xF0);
            }
            func_800E2AEC(o->u1, v, arg3, 0, arg4, c, 0);
        }
        return;
    }
    case 3: func_800DD3A0(obj, ctx, v, arg3, arg4, arg5); return;
    case 8: func_800E56D0(obj, ctx, v, arg3, arg4, arg5); return;
    case 45: {
        Obj *o = obj;
        if (func_8009D144() == 0 || (D_8021958C->u58 & (1 << obj->u1))) {
            u8 c = D_80219582[((u8 *)o)[2]];
            u8 *pp;
            if (c == 0x7F) pp = 0; else pp = (u8 *)D_80235F00 + c * 0x250;
            func_800D7DE0(o->u1, v, arg4, arg3, pp, 0xFFFF, 0);
        }
        return;
    }
    case 13: {
        Obj *o = obj;
        s32 *t = LOOK(obj->uC);
        func_800DE930(v, arg3, arg4, D_80219582[((u8 *)o)[3]], o->u4, o->u6, *(s32 *)((u8 *)o + 8),
                      o->u1, ((u8 *)o)[2], obj, t, 0, ((u8 *)o)[0xE], 0);
        return;
    }
    case 17: {
        V2w a, b;
        a.x = v[0]; a.y = v[1];
        b.x = func_8009D4B0(arg3);
        b.y = func_8009D510(arg3);
        D_80219498.world->e18[obj->u1].p0 = a;
        D_80219498.world->e18[obj->u1].p1 = b;
        D_80219498.world->e18[obj->u1].f = obj->u2;
        D_80219498.world->e18[obj->u1].c = arg4;
        return;
    }
    case 31: func_800E80F4(obj, ctx, v, arg3, arg4, arg5); return;
    case 10: func_800ED320(obj, ctx, v, arg3, arg4, arg5); return;
    case 36: func_800F7C30(obj, ctx, v, arg3, arg4, arg5); return;
    case 24: func_800ED990(obj, ctx, v, arg3, arg4, arg5); return;
    case 20: func_800E6E5C(obj, ctx, v, arg3, arg4, arg5); return;
    case 15: func_800EAC30(obj, ctx, v, arg3, arg4, arg5); return;
    case 26: func_800EF770(obj, ctx, v, arg3, arg4, arg5); return;
    case 28: func_800F2BC0(obj, ctx, v, arg3, arg4, arg5); return;
    case 29: func_800F33C0(obj, ctx, v, arg3, arg4, arg5); return;
    case 23: __dummy(obj, ctx, v, arg3, arg4, arg5); return;
    case 21: func_800E9E80(obj, ctx, v, arg3, arg4, arg5); return;
    case 32: func_800F5298(obj, ctx, v, arg3, arg4, arg5); return;
    case 41: func_800F85F0(obj, ctx, v, arg3, arg4, arg5); return;
    case 37: func_800B05F4(obj); return;
    case 38: func_800B06A8(obj, arg4); return;
    case 27: func_800F1B30(v, arg4, obj->u1 != 0, 0x7F); return;
    case 16: func_800E9B50(obj, ctx, v, arg3, arg4, arg5); return;
    case 30: {
        s16 *p = (s16 *)obj;
        switch (obj->u1) {
        case 0:
            D_80219498.world->lanes[arg4].x0 = v[0] + p[1];
            D_80219498.world->lanes[arg4].x1 = v[0] + p[4];
            D_80219498.world->lanes[arg4].z0 = v[1] + p[3];
            D_80219498.world->lanes[arg4].z1 = v[1] + p[6];
            return;
        case 1:
            func_800B1898(0, (s16)v[0], (s16)v[1], (s16)v[2], p[1], p[4], p[3], p[6], p[2], p[5], arg3, 0x01000000, arg4);
            return;
        case 2:
            func_800B1898(0, (s16)v[0], (s16)v[1], (s16)v[2], p[1], p[4], p[3], p[6], p[2], p[5], arg3, 0x80000, arg4);
            return;
        case 3: case 4:
            func_800E9990((s16)v[0], (s16)v[2], (s16)v[1], p[1], p[4], p[2], p[5], p[3], p[6], arg3, arg4, ((u8 *)p)[1] == 4);
            return;
        }
        return;
    }
    case 39:
        switch (obj->u1) {
        case 0: if (func_800E8090(obj->u2) == 0) return; break;
        case 1: if (func_800E8090(obj->u2) != 0) return; break;
        default: return;
        }
        func_800DFA5C((Obj *)(ctx->recs[arg5].u10 + ((s32 *)obj)[1]), ctx, v, arg3, arg4, arg5);
        return;
    case 40: func_800F7EC0(obj, ctx, v, arg3, arg4, arg5); return;
    }
}
