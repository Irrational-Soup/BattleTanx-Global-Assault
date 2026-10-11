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

int func_800AAEA0(s16 a, s16 b, s16 c, s16 d, int p, int *x0, float *d0, int *x1, float *d1);
int func_800ABF38(int x0, float d0, int x1, float d1, int layer, int p);

/* Body of the matched func_800AC0F4 (same original translation unit). */
static inline int path_clear(s16 a, s16 b, s16 c, s16 d, int layer, int p) {
    int x0;
    float d0;
    int x1;
    float d1;

    if (func_800AAEA0(a, b, c, d, p, &x0, &d0, &x1, &d1) != 0) {
        return func_800ABF38(x0, d0, x1, d1, layer, p);
    }
    return 0;
}

int func_800AC198(s16 x0, s16 y0, s16 x1, s16 y1, int layer, int view) {
    View *v = &D_80219498.views[view];
    int vx = v->x;
    int vy = v->y;

    if (vx < x0) {
        if (vy < y0) {
            if (path_clear(x0, y0, x1, y0, layer, view)) {
                return 1;
            }
            return path_clear(x0, y0, x0, y1, layer, view);
        }
        if (y1 < vy) {
            if (path_clear(x0, y0, x0, y1, layer, view)) {
                return 1;
            }
            return path_clear(x0, y1, x1, y1, layer, view);
        }
        return path_clear(x0, y0, x0, y1, layer, view);
    }
    if (x1 < vx) {
        if (vy < y0) {
            if (path_clear(x0, y0, x1, y0, layer, view)) {
                return 1;
            }
            return path_clear(x1, y0, x1, y1, layer, view);
        }
        if (y1 < vy) {
            if (path_clear(x1, y0, x1, y1, layer, view)) {
                return 1;
            }
            return path_clear(x1, y1, x0, y1, layer, view);
        }
        return path_clear(x1, y0, x1, y1, layer, view);
    }
    if (vy < y0) {
        return path_clear(x0, y0, x1, y0, layer, view);
    }
    if (y1 < vy) {
        return path_clear(x0, y1, x1, y1, layer, view);
    }
    return 1;
}

int func_800AC538(s16 x0, s16 y0, s16 x1, s16 y1, int layer, int view,
                  int maxEdge, int maxDist2) {
    View *v = &D_80219498.views[view];
    int vx = v->x;
    int vy = v->y;

    if (vx < x0) {
        if (vy < y0) {
            if (maxDist2 < (vx - x0) * (vx - x0) + (vy - y0) * (vy - y0)) {
                return 0;
            }
            if (path_clear(x0, y0, x1, y0, layer, view)) {
                return 1;
            }
            return path_clear(x0, y0, x0, y1, layer, view);
        }
        if (y1 < vy) {
            if (maxDist2 < (vx - x0) * (vx - x0) + (vy - y1) * (vy - y1)) {
                return 0;
            }
            if (path_clear(x0, y0, x0, y1, layer, view)) {
                return 1;
            }
            return path_clear(x0, y1, x1, y1, layer, view);
        }
        if (maxEdge < x0 - vx) {
            return 0;
        }
        return path_clear(x0, y0, x0, y1, layer, view);
    }
    if (x1 < vx) {
        if (vy < y0) {
            if (maxDist2 < (vx - x1) * (vx - x1) + (vy - y0) * (vy - y0)) {
                return 0;
            }
            if (path_clear(x0, y0, x1, y0, layer, view)) {
                return 1;
            }
            return path_clear(x1, y0, x1, y1, layer, view);
        }
        if (y1 < vy) {
            if (maxDist2 < (vx - x1) * (vx - x1) + (vy - y1) * (vy - y1)) {
                return 0;
            }
            if (path_clear(x1, y0, x1, y1, layer, view)) {
                return 1;
            }
            return path_clear(x1, y1, x0, y1, layer, view);
        }
        if (maxEdge < vx - x1) {
            return 0;
        }
        return path_clear(x1, y0, x1, y1, layer, view);
    }
    if (vy < y0) {
        if (maxEdge < y0 - vy) {
            return 0;
        }
        return path_clear(x0, y0, x1, y0, layer, view);
    }
    if (y1 < vy) {
        if (maxEdge < vy - y1) {
            return 0;
        }
        return path_clear(x0, y1, x1, y1, layer, view);
    }
    return 1;
}
