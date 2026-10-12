/* Patch display-list commands across both model lists in each group.
 * Gfx's 8-byte union alignment is significant to KMC's aggregate copy.
 * The pointer-to-int scan bound preserves N64 o32 behavior; this is not
 * a host/Vita portability claim.
 */
/* SPAN 0x80096250 */
typedef unsigned char u8;
typedef unsigned int u32;

typedef struct {
    u32 w0;
    u32 w1;
} Gwords;

typedef union {
    Gwords words;
    long long int force_structure_alignment;
} Gfx;

typedef struct {
    int unk0;
    Gfx *dl;
    int unk8;
} Mesh;

typedef struct {
    Mesh *meshes;
    u8 count;
} Model;

extern Gfx D_801146E8[1];
extern Gfx D_801146F0[1];

static inline void func_80095E7C(Gfx *dl, Gfx *srcb, Gfx *repb, u32 term) {
    Gfx *end = dl + 1000;
    Gfx *src, *rep, *g;
    int k;

    do {
        if (dl->words.w0 == term) return;
        k = 0;
        g = dl;
        rep = repb;
        src = srcb;
        do {
            if (src->words.w0 == g->words.w0 && src->words.w1 == g->words.w1) {
                *g = *rep;
            }
            rep++;
            k++;
            src++;
        } while (k <= 0);
        dl++;
    } while ((int)dl < (int)end);
}
typedef struct {
    int unk0;
    int index;
} ModelRef;

typedef struct {
    int nA;
    ModelRef *a;
    int nB;
    ModelRef *b;
    u8 pad10[0xD0 - 0x10];
} ModelGroup;

extern ModelGroup D_80122E28[15];
extern Model **D_803A53A0[];

static inline void patch_model(Model *m, Gfx *srcb, Gfx *repb, u32 term) {
    int k;

    for (k = 0; k < m->count; k++) {
        Mesh *mesh = &m->meshes[k];

        if (mesh->dl != 0) {
            func_80095E7C(mesh->dl, srcb, repb, term);
        }
    }
}
void func_80095FE0(void) {
    u32 term;
    Gfx *srcb;
    Gfx *repb;
    Model ***tab;
    Model **mp;
    unsigned int g;
    int i;

    for (g = 0; g < 15; g++) {
        tab = D_803A53A0;
        term = 0xDF000000;
        srcb = D_801146E8;
        repb = D_801146F0;
        for (i = 0; i < D_80122E28[g].nA; i++) {
            mp = tab[D_80122E28[g].a[i].index];
            if (mp != 0) {
                patch_model(*mp, srcb, repb, term);
            }
        }
        for (i = 0; i < D_80122E28[g].nB; i++) {
            mp = tab[D_80122E28[g].b[i].index];
            if (mp != 0) {
                patch_model(*mp, srcb, repb, term);
            }
        }
    }
}
