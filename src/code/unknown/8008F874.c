/* RODATA_VRAM 0x80071DAC */
typedef struct { short v[6]; char pad[0xD0 - 12]; } VSpawn;
typedef struct { unsigned int flags; int owner; char pad[0x20]; } Slot40;
typedef struct { char pad[0xC]; short x0; short y0; short x1; short y1; } Bounds;
typedef struct { char pad[0xA]; unsigned char flagsA; char p0B[0x78 - 0xB]; char cam[0x90 - 0x78]; int target; char p94[0x114 - 0x94]; int mode; } Ctl;
typedef struct {
    int id; char p4[4]; float x; float y; float z; char p14[0x20 - 0x14]; unsigned short ang; char p22[6]; float vel[3];
    char p34[0x94 - 0x34]; unsigned char team; char p95[3]; int kind; char p9C[0x1D0 - 0x9C]; Ctl *ctl; char p1D4[0x1E0 - 0x1D4];
    int flags; char p1E4[0x1F4 - 0x1E4]; unsigned short slot; char p1F6[0x248 - 0x1F6]; int t248; int phase;
    char p250[0x4C0 - 0x250]; float scale; int t4C4;
} Obj;
extern int D_8021945C;
extern VSpawn D_80122E3C[];
extern Slot40 D_803978E0[];
extern Bounds *D_80219498;
extern unsigned char D_802194A5;
extern char D_80116030[];
extern char D_80122078[][0x30];
extern char D_80121DA8[][0x30];
extern void func_800A5BD8(float *, int, unsigned char, float, void *, int);
extern void func_80095B90(Obj *, int);
extern int func_8009D914(void);
extern int func_8008F4AC(int, short, short, unsigned short, unsigned char, unsigned char, unsigned char, int);
extern unsigned short func_800B1898(int, short, short, int, short, short, short, short, short, short, unsigned short, int, int);
extern void func_800B9094(float *, unsigned short);
extern void func_800A6ADC(void *, void *);

int func_8008F874(Obj *o) {
    float pos[3];
    int dt = D_8021945C - o->t248;
    int done;
    int tries;
    int x;
    int y;
    unsigned short a;

    if (o->phase == 0) if (dt >= 13) {
        o->phase = 1;
        pos[0] = o->x;
        pos[1] = o->y;
        pos[2] = o->z + o->scale * D_80122E3C[o->kind].v[5] / 2.0f;
        func_800A5BD8(pos, 0, o->team, o->scale, D_80116030, 0);
        func_80095B90(o, 0x30);
    }
    if (o->phase == 1) if (dt >= 51) {
        done = 0;
        tries = 0;
        do {
            if (tries < 50) {
                x = o->x + o->scale * (func_8009D914() % 3000 - 1500);
                y = o->y + o->scale * (func_8009D914() % 3000 - 1500);
            } else {
                x = (D_80219498->x1 - D_80219498->x0) / 2 + (func_8009D914() % 3000 - 1500);
                y = (D_80219498->y1 - D_80219498->y0) / 2 + (func_8009D914() % 3000 - 1500);
            }
            a = (unsigned int)func_8009D914() % 65535;
            if (func_8008F4AC(o->kind, x, y, a, 0, 0, 1, 0)) {
                o->x = (short)x;
                o->y = (short)y;
                o->ang = a;
                o->team = 0;
                o->slot = func_800B1898(0, o->x, o->y, 0,
                    (short)(D_80122E3C[o->kind].v[0] * o->scale), (short)(D_80122E3C[o->kind].v[1] * o->scale),
                    (short)(D_80122E3C[o->kind].v[2] * o->scale), (short)(D_80122E3C[o->kind].v[3] * o->scale),
                    (short)(D_80122E3C[o->kind].v[4] * o->scale), (short)(D_80122E3C[o->kind].v[5] * o->scale),
                    o->ang, 8, 0);
                (&D_803978E0[o->slot])->flags &= ~8;
                done = 1;
                (&D_803978E0[o->slot])->flags |= 0x4000;
                o->phase = 2;
            }
            tries++;
        } while (!done & (tries < 100));
        if (!done) {
            return -1;
        }
    }
    if (o->phase == 2 && o->t4C4 + 50 < dt) {
        o->phase = 3;
        func_80095B90(o, 0x1D);
        pos[0] = o->x;
        pos[1] = o->y;
        pos[2] = o->z + D_80122E3C[o->kind].v[5] / 2;
        func_800A5BD8(pos, 0, o->team, o->scale, D_80116030, 1);
        func_80095B90(o, 0x30);
    }
    if (o->phase == 3 && o->t4C4 + 100 < dt) {
        Slot40 *slots = D_803978E0;
        slots[o->slot].owner = o->id;
        slots[o->slot].flags &= 0x051A2280;
        slots[o->slot].flags |= 8;
        o->flags &= ~8;
        func_800B9094(o->vel, o->slot);
        if ((o->ctl->flagsA & 1) && o->ctl->mode == 1 && o->ctl->target == o->id) {
            func_800A6ADC(o->ctl->cam, (D_802194A5 >= 2 ? D_80122078 : D_80121DA8)[o->kind]);
        }
    }
    return 0;
}
