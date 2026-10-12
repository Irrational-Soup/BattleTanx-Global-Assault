typedef unsigned char u8;
typedef short s16;

typedef struct {
    float x, y;
    char pad08[0x28 - 8];
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
} GameState;

extern GameState D_80219498;

int func_800AAEA0(s16 a, s16 b, s16 c, s16 d, int p, int *x0, float *d0,
                  int *x1, float *d1);
void func_800AAC14(int x0, float d0, int x1, float d1, int layer,
                   int index, int p);

static inline void edge_register(s16 a, s16 b, s16 c, s16 d, int layer,
                                 int index, int p) {
    int x0;
    float d0;
    int x1;
    float d1;

    if (func_800AAEA0(a, b, c, d, p, &x0, &d0, &x1, &d1) != 0) {
        func_800AAC14(x0, d0, x1, d1, layer, index, p);
    }
}

void func_800AB980(s16 x0, s16 y0, s16 x1, s16 y1, int layer, int index,
                   int view, int maxEdge, int maxDist2) {
    View *v = &D_80219498.views[view];
    int vx = v->x;
    int vy = v->y;

    if (vx < x0) {
        if (vy < y0) {
            if (maxDist2 < (vx - x0) * (vx - x0) + (vy - y0) * (vy - y0)) {
                return;
            }
            edge_register(x0, y0, x1, y0, layer, index, view);
            edge_register(x0, y0, x0, y1, layer, index, view);
            return;
        }
        if (y1 < vy) {
            if (maxDist2 < (vx - x0) * (vx - x0) + (vy - y1) * (vy - y1)) {
                return;
            }
            edge_register(x0, y0, x0, y1, layer, index, view);
            edge_register(x0, y1, x1, y1, layer, index, view);
            return;
        }
        if (maxEdge < x0 - vx) {
            return;
        }
        edge_register(x0, y0, x0, y1, layer, index, view);
        return;
    }
    if (x1 < vx) {
        if (vy < y0) {
            if (maxDist2 < (vx - x1) * (vx - x1) + (vy - y0) * (vy - y0)) {
                return;
            }
            edge_register(x0, y0, x1, y0, layer, index, view);
            edge_register(x1, y0, x1, y1, layer, index, view);
            return;
        }
        if (y1 < vy) {
            if (maxDist2 < (vx - x1) * (vx - x1) + (vy - y1) * (vy - y1)) {
                return;
            }
            edge_register(x1, y0, x1, y1, layer, index, view);
            edge_register(x1, y1, x0, y1, layer, index, view);
            return;
        }
        if (maxEdge < vx - x1) {
            return;
        }
        edge_register(x1, y0, x1, y1, layer, index, view);
        return;
    }
    if (vy < y0) {
        if (maxEdge < y0 - vy) {
            return;
        }
        edge_register(x0, y0, x1, y0, layer, index, view);
        return;
    }
    if (y1 < vy) {
        if (maxEdge < vy - y1) {
            return;
        }
        edge_register(x0, y1, x1, y1, layer, index, view);
        return;
    }
}
