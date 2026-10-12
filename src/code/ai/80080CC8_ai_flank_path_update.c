/* SPAN 0x800817E4 */
/* RODATA_VRAM 0x800711C0 */
/* LDSYM Steps_InitStep_Free=0x8007DA5C */
#include "types.h"

typedef struct { f32 x, y; } Vec2;
typedef struct Node { u8 type; u8 p1; u16 link; f32 x; f32 y; u8 pad0C[8]; u8 kind; u8 p15; u16 next; } Node;
typedef struct { Node *head; u16 first; u16 count; } Path;
typedef struct { void *obj; char pad04[0x24]; } Hit;
typedef struct Player {
    u8 pad000[0x10];
    s32 team;
    s32 mask;
    u8 pad018[0x238];
} Player;
typedef struct Obj {
    void *node;
    u8 pad004[0x4];
    Vec2 pos;
    u8 pad010[0x10];
    u16 angle;
    u8 pad022[0x2];
    u16 turn;
    u8 pad026[0x6E];
    u8 color;
    u8 pad095[0x3];
    s32 type;
    u8 pad09C[0x29];
    u8 aiMode;
    u8 pad0C6[0x2];
    struct Obj *target;
    u8 pad0CC[0x24];
    Path path;
    u8 pad0F8[0x74];
    u8 aiFlags;
    u8 pad16D[0x63];
    Player *owner;
    u8 pad1D4[0xC];
    u32 flags;
    u8 pad1E4[0x2E8];
} Obj;
typedef struct TypeInfo {
    u8 pad000[0x7C];
    u32 flags;
    u8 pad080[0x26];
    u16 radius;
    u8 pad0A8[0x28];
} TypeInfo;

extern TypeInfo D_80122E3C[];
extern s16 D_80397650;

Node *Steps_InitStep_Free(int);
void func_8009DAB0(Vec2 *, f32, u16);
void func_8009E044(Vec2 *, Vec2 *);
u16 func_800B49E0(Vec2 *, Vec2 *, int, int, int, void *, Hit *);
void func_8007E988(Obj *);
u16 func_8007D884(Node **, int);
void func_8008268C(Obj *);

#define ABS(x) ((x) > 0.0f ? (x) : -(x))
#define MAX(a, b) ((a) > (b) ? (a) : (b))
#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define DIST(dx, dy) (MAX(ABS(dx), ABS(dy)) + MIN(ABS(dx), ABS(dy)) * 3.0f / 8.0f)

static inline u16 visibilityTest(Vec2 *from, Vec2 *to, int mask, int color,
                                 int radius, void *owner, Hit *hit) {
    D_80397650 = 0;
    return func_800B49E0(from, to, mask, color, radius, owner, hit);
}

s32 func_80080CC8(Obj *self) {
    Obj *t;
    s32 mask;
    u16 ang;
    Vec2 a, b, c;
    Vec2 *pts[2];
    Hit hit;
    Node *n, *m;
    u16 i;
    s32 near;
    s32 ret = 0;
    Hit *hp;
    Path *path;

    if (self->aiFlags & 2) {
        if (self->aiMode == 1 && !(D_80122E3C[self->type].flags & 0x100) &&
            (t = self->target) != 0 && (t->flags & 1) &&
            t->color == self->color && t->owner->team != self->owner->team) {
            mask = self->owner->mask | 0x2C700F;
            ang = t->angle + t->turn;
            func_8009DAB0(&a, 400.0f, ang - 0x4B60);
            func_8009DAB0(&b, 400.0f, ang + 0x4B60);
            func_8009E044(&a, &t->pos);
            func_8009E044(&b, &t->pos);
            path = &self->path;
            func_8009DAB0(&c,
                          DIST(self->pos.x - t->pos.x,
                               self->pos.y - t->pos.y) / 2.0f,
                          self->angle);
            func_8009E044(&c, &self->pos);
            if (DIST(c.x - a.x, c.y - a.y) <
                DIST(c.x - b.x, c.y - b.y)) {
                pts[0] = &a;
                pts[1] = &b;
            } else {
                pts[0] = &b;
                pts[1] = &a;
            }
            for (i = 0; i < 2; i++) {
                if (visibilityTest(&self->pos, pts[i], mask, self->color,
                                   D_80122E3C[self->type].radius, self->node,
                                   hp = &hit) != 0) {
                    continue;
                }
                near = 0;
                if (path->head != 0) {
                    n = Steps_InitStep_Free(path->head->link);
                    if (DIST(n->x - pts[i]->x, n->y - pts[i]->y) < 100.0f) {
                        near = 1;
                    }
                }
                if (!near) {
                    func_8007E988(self);
                    path->first = func_8007D884(&n, 3);
                    n->next = func_8007D884(&m, 4);
                    n->link = 0;
                    n->x = pts[i]->x;
                    n->y = pts[i]->y;
                    n->kind = 3;
                    m->link = path->first;
                    m->x = DIST(self->pos.x - pts[i]->x,
                                self->pos.y - pts[i]->y);
                    *(s32 *)&m->y = 0;
                    path->count = 2;
                    path->head = m;
                    func_8008268C(self);
                }
                ret = 1;
                break;
            }
        }
    }
    return ret;
}
