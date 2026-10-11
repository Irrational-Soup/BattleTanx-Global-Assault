typedef short s16;
typedef unsigned short u16;

typedef struct {
    float x;
    float y;
} Vec2;

typedef struct {
    int unk0;
    int unk4;
    u16 link[4];
    s16 x;
    s16 z;
    s16 y;
    s16 dx0;
    s16 dx1;
    s16 dz0;
    s16 dz1;
    u16 unk1E;
    u16 unk20;
    s16 radius;
    u16 unk24;
    u16 grid;
} GridNode;

typedef struct {
    int data;
    u16 id;
    float x;
    float z;
    float y;
    Vec2 push;
    float unk1C;
    s16 side;
} Contact;

extern GridNode D_803978E0[];
extern u16 D_801166F0;
extern u16 D_80397658[];

u16 func_800B2890(s16 x, s16 z, u16 id);

extern inline void func_800B0B8C(u16 id) {
    GridNode *n = &D_803978E0[id];

    n->grid |= 0x1000;
    *(u16 *)((char *)D_80397658 + (D_801166F0 << 1)) = id;
    D_801166F0++;
}

u16 func_800B4F38(Vec2 *p, int layer, u16 head, u16 dir, int mask,
                  Contact *out, u16 base, u16 single) {
    GridNode *n;
    Contact *c;
    u16 count = 0;
    u16 i;
    u16 current = head;
    int targetLayer;

    if (current != 0xFFFF) {
        do {
            n = &D_803978E0[current];
            targetLayer = layer & 0xFFFF;
            if (targetLayer == n->grid && (n->unk0 & mask)) {
                if (func_800B2890((s16)p->x, (s16)p->y, current)) {
                    c = out;
                    for (i = 0; i < base + count; i++, c++) {
                        if (current == c->id) {
                            break;
                        }
                    }
                    if (i >= base + count) {
                        c->data = n->unk4;
                        c->id = current;
                        count++;
                        if (single) {
                            break;
                        }
                        if (base + count >= 32) {
                            break;
                        }
                    }
                }
                if (dir != 3) {
                    func_800B0B8C(current);
                }
            }
            current = n->link[dir];
            if (current == 0xFFFF) {
                break;
            }
        } while (1);
    }
    return count;
}
