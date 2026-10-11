/* SPAN 0x800B6F40 */
typedef short s16;
typedef unsigned short u16;

typedef struct { float x, y; } Vec2;

typedef struct {
    int unk0;
    int unk4;
    u16 link[4];
    s16 x, z, y;
    s16 dx0, dx1;
    s16 dz0, dz1;
    u16 unk1E, unk20;
    s16 radius;
    u16 unk24;
    u16 grid;
} GridNode;

extern GridNode D_803978E0[];

void func_800B2BE4(GridNode *n, Vec2 *q);

static inline void corners(GridNode *n, Vec2 *out) {
    func_800B2BE4(n, out);
}

u16 func_800B3B60(Vec2 *a, Vec2 *b, s16 id, Vec2 *pt, Vec2 *nrm);

float func_800B6CC4(int unused, u16 a, u16 b, Vec2 *dir, Vec2 *out) {
    Vec2 o;
    Vec2 q;
    Vec2 hit;
    Vec2 nrm;
    Vec2 c[4];
    Vec2 *p;
    float best;
    float dx;
    float dy;
    float d;
    int off;
    GridNode *na;
    GridNode *nb;

    na = &D_803978E0[a];
    off = na->radius + (nb = &D_803978E0[b])->radius + 10;
    o.x = off * -dir->x;
    o.y = off * -dir->y;
    best = 0.0f;
    corners(na, c);
    for (p = c; p < &c[4]; p++) {
        q.x = p->x - o.x;
        q.y = p->y - o.y;
        if (func_800B3B60(&q, p, b, &hit, &nrm)) {
            dx = p->x - hit.x;
            dy = p->y - hit.y;
            d = dx * dx + dy * dy;
            if (best < d) {
                out->x = p->x;
                out->y = p->y;
                best = d;
            }
        }
    }
    corners(&D_803978E0[b], c);
    for (p = c; p < &c[4]; p++) {
        q.x = p->x + o.x;
        q.y = p->y + o.y;
        if (func_800B3B60(&q, p, a, &hit, &nrm)) {
            dx = p->x - hit.x;
            dy = p->y - hit.y;
            d = dx * dx + dy * dy;
            if (best < d) {
                out->x = p->x;
                out->y = p->y;
                best = d;
            }
        }
    }
    return best;
}
