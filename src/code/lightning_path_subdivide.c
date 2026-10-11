/* SPAN 0x800E603C */
/* RODATA_VRAM 0x80075EA8 */
/* Insert a smooth midpoint between consecutive lightning-path vertices.
 * The caller refines 4, 7, 13 and 25 points in successive passes. */
typedef struct {
    float x, y, z;
} ArcPoint;

typedef struct {
    ArcPoint point;
    ArcPoint midpoint;
} ArcSegment;

/* Inferred scratch layout, not a claim about the original declarations.
 * The flat view permits endpoint address arithmetic within one array;
 * forming distances - 2 would instead point outside that member array.
 * All overlaid elements are floats, with no pointer tokens or byte swaps. */
typedef union {
    struct {
        ArcPoint points[49];
        float distances[51];
    } typed;
    float raw[198];
} ArcScratch;

typedef char ArcPointSize[(sizeof(ArcPoint) == 12) ? 1 : -1];
typedef char ArcScratchSize[(sizeof(ArcScratch) == 792) ? 1 : -1];

extern int D_80123DF0[];
extern void _bcopy(void *, void *, int);
extern float sqrtf(float);

static inline void arc_extend(ArcPoint *prev, ArcPoint *cur,
                              float amount, ArcPoint *result) {
    result->x = cur->x + (cur->x - prev->x) * amount;
    result->z = cur->z + (cur->z - prev->z) * amount;
    result->y = cur->y + (cur->y - prev->y) * amount;
}

static inline void arc_third(ArcPoint *a, ArcPoint *b, ArcPoint *result) {
    result->x = ((a->x + a->x) + b->x) / 3.0f;
    result->z = ((a->z + a->z) + b->z) / 3.0f;
    result->y = ((a->y + a->y) + b->y) / 3.0f;
}

static inline void arc_midpoint(ArcPoint *a, ArcPoint *b, ArcPoint *result) {
    result->x = (a->x + b->x) / 2.0f;
    result->z = (a->z + b->z) / 2.0f;
    result->y = (a->y + b->y) / 2.0f;
}

static inline void arc_smooth(ArcPoint *points, ArcScratch *scratch, int index,
                              ArcPoint *result, ArcPoint *a, ArcPoint *b) {
    float f;
    float g;
    float *distances = scratch->typed.distances;
    distances += index;
    f = (distances[1] / distances[0]) / 3.0f;
    g = (distances[1] / distances[2]) / 3.0f;
    arc_extend(&points[0], &points[1], f, a);
    arc_extend(&points[3], &points[2], g, b);
    arc_midpoint(a, b, result);
}

static inline void arc_smooth_end(ArcPoint *points, float *distances,
                                  ArcPoint *result, ArcPoint *a, ArcPoint *b) {
    float f;
    f = (distances[1] / distances[0]) / 3.0f;
    arc_extend(&points[0], &points[1], f, a);
    b->x = (points[1].x + (points[2].x + points[2].x)) / 3.0f;
    b->z = (points[1].z + (points[2].z + points[2].z)) / 3.0f;
    b->y = (points[1].y + (points[2].y + points[2].y)) / 3.0f;
    arc_midpoint(a, b, result);
}

void func_800E5BB8(ArcSegment *out, int pass) {
    ArcScratch scratch;
    ArcScratch *source;
    ArcScratch *walk;
    float *distances;
    ArcPoint a;
    ArcPoint b;
    int count = D_80123DF0[pass];
    int i;
    float g;

    source = &scratch;
    _bcopy(out, source->typed.points, count * sizeof(ArcPoint));
    i = 0;
    /* Keep the copy inside the entry guard: it crosses a block boundary
     * and is globally, rather than locally, allocated by GCC 2.7.2. */
    if (i < count - 1) {
        walk = source;
        for (; i < count - 1; i++) {
            float dx = walk->typed.points[i].x - walk->typed.points[i + 1].x;
            float dz = walk->typed.points[i].z - walk->typed.points[i + 1].z;
            float dy = walk->typed.points[i].y - walk->typed.points[i + 1].y;
            *((i + 1) + walk->typed.distances) =
                sqrtf((dx * dx + dz * dz) + dy * dy);
        }
    }

    for (i = 1; i < count - 2; i++) {
        arc_smooth(&scratch.typed.points[i - 1], &scratch, i,
                   &out[i].midpoint, &a, &b);
    }

    g = (scratch.typed.distances[1] / scratch.typed.distances[2]) / 3.0f;
    arc_third(&scratch.typed.points[0], &scratch.typed.points[1], &a);
    arc_extend(&scratch.typed.points[2], &scratch.typed.points[1], g, &b);
    arc_midpoint(&a, &b, &out[0].midpoint);

    /* This is distances[count - 2]. Advancing the local in place keeps
     * GCC's single-set scheduling priority from shortening its lifetime. */
    distances = &scratch.raw[sizeof(scratch.typed.points) / sizeof(float) - 2];
    distances += count;
    arc_smooth_end(&scratch.typed.points[count - 3], distances,
                  &out[count - 2].midpoint, &a, &b);
    for (i = 0; i < count; i++) {
        out[i].point = scratch.typed.points[i];
    }
}
