/* RODATA_VRAM 0x80073150 */

typedef short s16;
typedef unsigned short u16;

typedef struct {
    float x, y;
} Vec2;

typedef struct {
    int unk0;
    int unk4;
    u16 link[4];
    s16 x, z, y;
    s16 dx0, dx1;
    s16 dz0, dz1;
    s16 h0, h1;
    s16 radius;
    u16 unk24;
    u16 grid;
} GridNode;

extern GridNode D_803978E0[];
void func_800B2364(Vec2 *in, u16 ang, Vec2 *out);

#define ABSF(x) ((x) >= 0 ? (x) : -(x))

float func_800B83A8(u16 id, Vec2 *p) {
    GridNode *n = &D_803978E0[id];
    Vec2 d;
    Vec2 r;
    float top;
    u16 w;
    u16 dd;
    u16 bevel;
    s16 x0;
    s16 x1;
    s16 z0;
    s16 z1;
    u16 flags;
    s16 h0;
    s16 h1;

    d.x = p->x - n->x;
    d.y = p->y - n->z;
    func_800B2364(&d, n->unk24, &r);
    h0 = n->h0;
    h1 = n->h1;
    if (ABSF(h0) > ABSF(h1)) {
        top = h0 + n->y;
    } else {
        top = h1 + n->y;
    }
    w = n->dx1 - n->dx0;
    dd = n->dz1 - n->dz0;
    if (dd > w) {
        w = dd;
    }
    bevel = (w >> 1) * 0.5f;
    flags = 0;
    x0 = n->dx0 + bevel;
    z0 = n->dz0 + bevel;
    z1 = n->dz1 - bevel;
    x1 = n->dx1 - bevel;
    if (r.x < x0) {
        flags = 1;
    } else if (x1 < r.x) {
        flags = 2;
    }
    if (r.y < z0) {
        flags |= 4;
    } else if (z1 < r.y) {
        flags |= 8;
    }
    switch (flags) {
    case 5:
        flags = (r.x - n->dx0 < r.y - n->dz0) ? 1 : 4;
        break;
    case 10:
        flags = (n->dx1 - r.x < n->dz1 - r.y) ? 2 : 8;
        break;
    case 9:
        flags = (r.x - n->dx0 < n->dz1 - r.y) ? 1 : 8;
        break;
    case 6:
        flags = (n->dx1 - r.x < r.y - n->dz0) ? 2 : 4;
        break;
    }
    switch (flags) {
    case 0:
        return top;
    case 1:
        return top * (r.x - n->dx0) / (x0 - n->dx0);
    case 2:
        return top * (n->dx1 - r.x) / (n->dx1 - x1);
    case 4:
        return top * (r.y - n->dz0) / (z0 - n->dz0);
    case 8:
        return top * (n->dz1 - r.y) / (n->dz1 - z1);
    }
    return 0.0f;
}
