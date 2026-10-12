/* SPAN 0x80080110 */
/* RODATA_VRAM 0x8007119C */
/* LDSYM Steps_InitStep_Free=0x8007DA5C */
typedef unsigned char u8;
typedef unsigned short u16;

typedef struct Node {
    u8 type;
    char pad1;
    u16 link;
    float x;
    float y;
} Node;

typedef struct {
    char pad0[0x110];
    float start[2];
    float goal[2];
} Ent;

Node *Steps_InitStep_Free(int);

#define ABS(x) ((x) > 0.0f ? (x) : -(x))
#define MAX(a, b) ((a) > (b) ? (a) : (b))
#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define DIST(dx, dy) \
    (MAX(ABS(dx), ABS(dy)) + MIN(ABS(dx), ABS(dy)) * 3.0f / 8.0f)

static inline float *node_pos(Ent *e, Node *n) {
    for (;;) {
        if (n == 0) {
            return e->start;
        }
        if (n->type == 3) {
            return &n->x;
        }
        n = Steps_InitStep_Free(n->link);
    }
}

float func_8007F774(Ent *e, float *cur) {
    float *prev = node_pos(e, (Node *)cur);
    Node *n = Steps_InitStep_Free(((Node *)cur)->link);
    float sum = 0.0f;

    for (;;) {
        if (n == 0) {
            sum += DIST(e->start[0] - prev[0], e->start[1] - prev[1]);
            break;
        }
        if (n->type == 3) {
            cur = &n->x;
            sum += DIST(cur[0] - prev[0], cur[1] - prev[1]);
            prev = cur;
            n = Steps_InitStep_Free(n->link);
        } else {
            sum += DIST(node_pos(e, n)[0] - prev[0],
                        node_pos(e, n)[1] - prev[1]);
            sum += n->x;
            break;
        }
    }
    return sum;
}
