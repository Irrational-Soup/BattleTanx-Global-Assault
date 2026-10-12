/* RODATA_VRAM 0x80071090 */
typedef unsigned char u8;
typedef unsigned short u16;
typedef unsigned int u32;
typedef signed short s16;
typedef signed int s32;

typedef union Gfx {
    struct {
        u32 w0;
        u32 w1;
    } words;
    long long force_structure_alignment;
} Gfx;

typedef struct TextureGrid {
    u8 type;
    u8 flag;
    u16 width;
    u16 height;
    u16 step_x;
    u16 step_y;
    u16 palette;
    void *data;
    void *base;
    void *rom_start;
    void *rom_end;
} TextureGrid;

void func_8007BCF0(TextureGrid *, u16);
void func_8007BEF0(Gfx **, TextureGrid *, u16, u16, u16, u16);

#define SHIFTL(value, shift, width) \
    ((u32)(((u32)(value) & ((1U << (width)) - 1)) << (shift)))
#define MAX(a, b) ((a) > (b) ? (a) : (b))
#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define IMMP1(packet, command, parameter) { \
    Gfx *_g = (packet); \
    _g->words.w0 = SHIFTL((command), 24, 8); \
    _g->words.w1 = (u32)(parameter); \
}
#define SCISSOR_TEXTURE_RECTANGLE(packet, xl, yl, xh, yh, tile, s, t, \
                                  dsdx, dtdy) { \
    Gfx *_g = (packet); \
    _g->words.w0 = SHIFTL(0xE4, 24, 8) | \
                    SHIFTL(MAX((s16)(xh), 0), 12, 12) | \
                    SHIFTL(MAX((s16)(yh), 0), 0, 12); \
    _g->words.w1 = SHIFTL((tile), 24, 3) | \
                    SHIFTL(MAX((s16)(xl), 0), 12, 12) | \
                    SHIFTL(MAX((s16)(yl), 0), 0, 12); \
    IMMP1((packet), 0xE1, \
          SHIFTL((s) - (((s16)(xl) < 0) ? \
                 (((s16)(dsdx) < 0) ? \
                  MAX((((s16)(xl) * (s16)(dsdx)) >> 7), 0) : \
                  MIN((((s16)(xl) * (s16)(dsdx)) >> 7), 0)) : 0), 16, 16) | \
          SHIFTL((t) - (((s16)(yl) < 0) ? \
                 (((s16)(dtdy) < 0) ? \
                  MAX((((s16)(yl) * (s16)(dtdy)) >> 7), 0) : \
                  MIN((((s16)(yl) * (s16)(dtdy)) >> 7), 0)) : 0), 0, 16)); \
    IMMP1((packet), 0xF1, \
          SHIFTL((dsdx), 16, 16) | SHIFTL((dtdy), 0, 16)); \
}

void func_8007C364(Gfx **display_list, TextureGrid *grid,
                   int origin_x, int origin_y, u16 uls, u16 ult,
                   u16 lrs, u16 lrt, float scale_x, float scale_y) {
    Gfx *gfx;
    u16 unavailable;
    s16 xl;
    s16 yl;
    s16 xh;
    s16 yh;
    s16 s;
    s16 t;

    if (grid == 0) {
        return;
    }
    if (grid->data == 0) {
        if (grid->rom_start != 0) {
            func_8007BCF0(grid, 1);
            unavailable = 0;
        } else {
            unavailable = 1;
        }
    } else {
        unavailable = 0;
    }
    if ((unavailable & 0xFFFF) == 0) {
        gfx = *display_list;
        func_8007BEF0(&gfx, grid, uls, ult, lrs - 1, lrt - 1);

        if (scale_x >= 0.0f) {
            xl = origin_x * 4;
            s = uls << 5;
            xh = (origin_x + (s32)((lrs - uls) * scale_x)) * 4;
        } else {
            xh = origin_x * 4;
            s = (lrs << 5) - 32;
            xl = (origin_x + (s32)((lrs - uls) * scale_x)) * 4;
        }
        if (scale_y >= 0.0f) {
            yl = origin_y * 4;
            t = ult << 5;
            yh = (origin_y + (s32)((lrt - ult) * scale_y)) * 4;
        } else {
            yh = origin_y * 4;
            t = (lrt << 5) - 32;
            yl = (origin_y + (s32)((lrt - ult) * scale_y)) * 4;
        }

        SCISSOR_TEXTURE_RECTANGLE(gfx++, xl, yl, xh, yh, 0, s, t,
                                  (s32)(1024.0 / scale_x),
                                  (s32)(1024.0 / scale_y));
        *display_list = gfx;
    }
}
