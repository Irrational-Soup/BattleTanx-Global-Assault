/* SPAN 0x80081EA4 */
typedef unsigned char u8;
typedef unsigned short u16;

typedef struct { char bytes[0x28]; } Hit;
typedef struct { int a, b; } Buf;
typedef struct { float x, y; } Pt;
typedef struct {
    char p0[4];
    float x;
    float y;
    char pc[8];
    u8 kind;
} Node;
typedef struct { void *head; u16 list; u16 count; } Path;
typedef struct {
    int b0;
    char p4[4];
    float pos[3];
    char p14[0x94 - 0x14];
    u8 b94;
    char p95[0xF0 - 0x95];
    Path path;
    char pf8[0x124 - 0xF8];
    int b124;
    char p128[0x1D0 - 0x128];
    struct { char p[0x14]; int base; } *res;
} Ent;

extern short D_80397650;
extern char *D_80114680;

void func_8007D500(Buf *, int, Buf *);
void func_8007D5B0(Buf *, int, Pt *, Pt *);
int func_8007D628(float *, Pt *, Pt *);
u16 func_8007D69C(Ent *, int);
u16 func_800B49E0(float *, Pt *, int, int, int, int, Hit *);
u16 func_8007D884(Node **, int);
void func_8007D4A0(Buf *, char *);
void func_8007E8C8(Ent *);
int func_8007E024(int, u16 *, int);
int func_8007DFA0(u16 *, int);
void func_8008268C(Ent *);

static inline u16 collision_probe(float *pos, Pt *point, int base, int kind,
                                  int type, int owner, Hit *hit) {
    return func_800B49E0(pos, point, base + 0x2C700F, kind, type, owner, hit);
}

int func_80081C78(Ent *e, Buf *in) {
    Path *path = &e->path;
    float *pos = e->pos;
    Pt *selected = 0;
    int base = e->res->base;
    int result = 0;
    Buf transformed;
    Pt first;
    Pt second;
    Hit hit;
    int kind;
    u16 type;

    func_8007D500(in, 2, &transformed);
    func_8007D5B0(&transformed, e->b124, &second, &first);
    if (func_8007D628(pos, &first, &second) != 1 &&
        (kind = e->b94, type = func_8007D69C(e, 1), D_80397650 = 0,
         collision_probe(pos, &second, base, kind, type, e->b0, &hit) == 0)) {
        selected = &second;
    } else {
        kind = e->b94;
        type = func_8007D69C(e, 1);
        D_80397650 = 0;
        if (collision_probe(e->pos, &first, base, kind, type, e->b0, &hit) == 0) {
            selected = &first;
        }
    }

    if (selected != 0) {
        Node *node;
        u16 id = func_8007D884(&node, 3);
        u16 *list;
        u16 limit;

        func_8007D4A0(in, (char *)node + 0xC);
        node->x = first.x;
        node->y = first.y;
        node->kind = 2;
        func_8007E8C8(e);
        list = &path->list;
        path->count += func_8007E024(0, list, id);
        limit = *(u16 *)(D_80114680 + 0xC008);
        if (path->count >= limit) {
            path->count -= func_8007DFA0(list, limit);
        }
        func_8008268C(e);
        result = 1;
    }
    return result;
}
