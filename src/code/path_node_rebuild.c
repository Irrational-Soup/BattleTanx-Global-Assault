/* RODATA_VRAM 0x8007120C */
typedef unsigned char u8; typedef unsigned short u16;
typedef struct { float x, y; } Pt;
typedef struct { int id; } Obj;
typedef struct { Obj *obj; char p4[0x1C]; u16 id; char p22[6]; } Hit;
typedef struct Node { u16 p0; u16 id; float x; union { float y; struct Node *next; } u; char pc[8]; u8 kind; char p15; u16 link; } Node;
typedef struct { Node *head; u16 p4; u16 count; char p8[0x30 - 8]; int tgt; } Path;
typedef struct { u8 type; } Way;
typedef struct { char p0[0xB8]; u16 radius; char pba[0xD0 - 0xBA]; } Zone;
typedef struct {
    int b0; char p4[4]; float pos[2]; char p10[0x94 - 0x10]; u8 color; char p95[3]; int zone; char p9c[0xC5 - 0x9C]; u8 mode;
    char pc6[0xF0 - 0xC6]; Path path; char p124[4]; struct { char p[0xA]; u16 cur; } goal; char p134[0x16C - 0x134]; u8 flags;
    char p16d[0x1D0 - 0x16D]; struct { char p[0x14]; int base; } *owner;
} Ent;
extern short D_80397650;
extern Zone D_80122E28[];
unsigned short func_800B49E0(float *, void *, int, int, int, int, Hit *);
void func_8007E988(Ent *);
Node *func_8007DA5C(int);
Node *func_8007E784(Ent *);
Node *func_8007DACC(Node *, u16 *);
Way *func_8007DA5C_w(int);
Pt *func_8008865C(Ent *);
Pt *func_8007E210(Ent *, Node *);
u16 func_8007D69C(Ent *, int);
u16 func_8007D884(Node **, int);
void func_8008268C(Ent *);
void func_8007E7A8(Ent *);
#define ABS(x) ((x) > 0.0f ? (x) : -(x))
#define MAX(a, b) ((a) > (b) ? (a) : (b))
#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define DIST(dx, dy) (MAX(ABS(dx), ABS(dy)) + MIN(ABS(dx), ABS(dy)) * 3.0f / 8.0f)

int func_80081834(Ent *e) {
    Hit hit;
    Path *p = &e->path;
    int mask = 0x2C700F | e->owner->base;
    u16 id = 0;
    struct { char p[0xA]; u16 cur; } *g = (void *)&e->goal;
    int r = 0;

    if (e->flags & 8) {
        int k = e->color;
        int rad = D_80122E28[e->zone].radius;
        int b0 = e->b0;
        D_80397650 = 0;
        if (func_800B49E0(e->pos, e->pos, mask, k, rad, b0, &hit) == 0) {
            func_8007E988(e);
            e->flags &= ~8;
        }
    } else {
        Pt *dst = 0;
        Node *n;

        e->goal.cur = 0;
        {
            Node *m = func_8007DA5C(0);
            if (m == 0) m = func_8007E784(e);
            n = func_8007DACC(m, &id);
        }
        if (n != 0) {
            Way *w = (Way *)func_8007DA5C(n->link);
            if (w != 0 && w->type == 4) {
                switch (e->mode) {
                case 1:
                case 3:
                    dst = func_8008865C(e);
                    goto have;
                }
            }
            dst = func_8007E210(e, n);
        have:;
        }
        if (dst != 0) {
            Hit hit2;
            int k = e->color;
            u16 t = func_8007D69C(e, 1);
            int b0 = e->b0;
            D_80397650 = 0;
            if (func_800B49E0(e->pos, dst, mask, k, t, b0, &hit2) != 0) {
                if (p->tgt != 0 && hit2.obj != 0 && p->tgt == hit2.obj->id) {
                Pt c;
                Node *n1;
                Node *n2;
                Node *tail;
                c.x = dst->x;
                c.y = dst->y;
                func_8007E988(e);
                p->p4 = func_8007D884(&n1, 3);
                n1->link = func_8007D884(&n2, 4);
                n1->id = 0;
                n1->x = c.x;
                n1->u.y = c.y;
                n1->kind = 3;
                n2->id = p->p4;
                tail = n2;
                tail->x = DIST(e->pos[0] - c.x, e->pos[1] - c.y);
                n2->u.next = 0;
                p->count = 2;
                p->head = n2;
                func_8008268C(e);
                }
            } else {
                while (p->p4 != id) func_8007E7A8(e);
                func_8008268C(e);
                r = 1;
            }
        }
    }
    g->cur = id;
    return r;
}
