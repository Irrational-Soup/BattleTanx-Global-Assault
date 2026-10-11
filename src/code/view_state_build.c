/* RODATA_VRAM 0x80072E84 */

typedef unsigned char u8;
typedef short s16;

typedef struct {
    float x, y;
    float axis0_x;      /* 0x08 */
    float axis0_y;      /* 0x0C */
    float axis1_x;      /* 0x10 */
    float axis1_y;      /* 0x14 */
    float offset_y;     /* 0x18 */
    float offset_x;     /* 0x1C */
    int player;         /* 0x20 */
    u8 active;          /* 0x24 */
    u8 kind;            /* 0x25 */
    u8 high;            /* 0x26 */
    u8 pad27;
} View;

typedef struct {
    void *world;
    int track;
    unsigned int mode;
    u8 nHuman;
    u8 nPlayers;
    u8 nTanks;
    u8 nSlots;
    u8 teams[5];
    char pad13[3];
    int time;
    View views[4];
    char padBC[0xE4 - 0xBC];
    u8 teamMask[6];     /* 0xE4 = D_8021957C */
} GameState;

typedef struct {
    u8 pad00[0x24];
    float tx;           /* 0x24 */
    float ty;           /* 0x28 */
    float tz;           /* 0x2C */
    float x;            /* 0x30 */
    float y;            /* 0x34 */
    float z;            /* 0x38 */
    u8 pad3C[0x8C - 0x3C];
    u8 team;            /* 0x8C */
} CameraObj;

typedef struct {
    u8 pad00[0x78];
    CameraObj obj;      /* 0x78 */
    u8 pad108[0x168 - 0x78 - sizeof(CameraObj)];
    float scale;        /* 0x168 */
    u8 pad16C[0x250 - 0x16C];
} Player;

extern GameState D_80219498;
extern Player D_80235F00[];
void _bzero(void *p, int n);
float sqrtf(float);

void func_800AC9E8(void) {
    int n = D_80219498.nPlayers;
    int i;
    Player *pl;
    CameraObj *o;
    float dx;
    float dz;
    float dy;
    float len;
    float ax;
    float ay;
    View *v;

    _bzero(D_80219498.teamMask, 6);
    v = D_80219498.views;
    for (i = 0; i < n; v++, i++) {
        pl = (i == 127) ? 0 : &D_80235F00[i];
        D_80219498.teamMask[pl->obj.team] |= 1 << i;
        D_80219498.views[i].x = pl->obj.x;
        D_80219498.views[i].y = pl->obj.y;
        dx = pl->obj.tx - pl->obj.x;
        dz = pl->obj.tz - pl->obj.z;
        dy = pl->obj.ty - pl->obj.y;
        o = &pl->obj;
        if (((dx == 0.0f) & (dz == 0.0f)) && dy == 0.0f) {
            pl->obj.tx += 1.0f;
            dx = pl->obj.tx - pl->obj.x;
        }
        len = sqrtf(dx * dx + dy * dy);
        D_80219498.views[i].high = o->z > 105.0f;
        if (len < ((0.0f < dz) ? dz : -dz)) {
            v->active = 1;
            continue;
        }
        ax = dy / len;
        ay = dx / len;
        D_80219498.views[i].axis0_x = ax;
        D_80219498.views[i].axis0_y = ay;
        D_80219498.views[i].axis1_x = ax * pl->scale;
        D_80219498.views[i].axis1_y = ay * pl->scale;
        D_80219498.views[i].offset_y = -o->x;
        D_80219498.views[i].offset_x = -o->y;
        D_80219498.views[i].player = i;
        D_80219498.views[i].kind = o->team;
        v->active = 0;
    }
}
