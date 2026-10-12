typedef unsigned char u8;
typedef unsigned short u16;
typedef unsigned int u32;

typedef struct Gfx {
    u32 w0;
    u32 w1;
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
void func_8007C364(Gfx **, TextureGrid *, short, short, int, int, int, int,
                   float, float);

#define EMIT(packet, word0, word1) { \
    Gfx *_g = (packet); \
    _g->w0 = (word0); \
    _g->w1 = (word1); \
}

static inline void setup_texture(Gfx **display_list, TextureGrid *texture) {
    Gfx *gfx = *display_list;

    if (texture->type == 2) {
        if (texture->flag == 0) {
            EMIT(gfx++, 0xFD100000, (u32)texture->base);
            EMIT(gfx++, 0xE8000000, 0);
            EMIT(gfx++, 0xF5000100 | ((texture->palette & 0xF) << 4),
                 0x07000000);
            EMIT(gfx++, 0xE6000000, 0);
            EMIT(gfx++, 0xF0000000, 0x0703C000);
            EMIT(gfx++, 0xE7000000, 0);
        } else {
            EMIT(gfx++, 0xFD100000, (u32)texture->base);
            EMIT(gfx++, 0xE8000000, 0);
            EMIT(gfx++, 0xF5000100, 0x07000000);
            EMIT(gfx++, 0xE6000000, 0);
            EMIT(gfx++, 0xF0000000, 0x073FC000);
            EMIT(gfx++, 0xE7000000, 0);
        }
        EMIT(gfx++, 0xE3001001, 0x8000);
    } else {
        EMIT(gfx++, 0xE3001001, 0);
    }
    *display_list = gfx;
}

static inline void walk_grid(Gfx **display_list, TextureGrid *grid,
                             short origin_x, short origin_y,
                             float scale_x, float scale_y,
                             u16 first_column, short first_row,
                             short end_column, short end_row) {
    Gfx *gfx = *display_list;
    u16 row;
    u16 next_row;
    u16 column;
    u16 next_column;

    row = first_row;
    while ((short)row < grid->height && (short)row < end_row) {
        column = first_column;
        if (grid->step_y == 0) {
            TextureGrid *copy = grid;
            next_row = grid->height < end_row ? copy->height : end_row;
        } else {
            next_row = row + grid->step_y;
            if ((short)next_row >= end_row) {
                next_row = end_row;
            } else if (grid->height < (short)next_row) {
                next_row = grid->height;
            }
        }
        for (; (short)column < grid->width &&
               (short)column < end_column; column = next_column) {
            if (grid->step_x == 0) {
                short copy = end_row;
                next_column = grid->height < copy ? grid->width : end_column;
            } else {
                next_column = column + grid->step_x;
                if ((short)next_column >= end_column) {
                    next_column = end_column;
                } else if (grid->width < (short)next_column) {
                    next_column = grid->width;
                }
            }
            func_8007C364(&gfx, grid,
                          origin_x + scale_x * (short)column,
                          origin_y + scale_y * (short)row,
                          column, row, next_column, next_row,
                          scale_x, scale_y);
        }
        row = next_row;
    }
    *display_list = gfx;
}

void func_8007C9B8(Gfx **display_list, TextureGrid *grid, short origin_x,
                   short origin_y, float scale_x, float scale_y) {
    u16 unavailable;

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
        setup_texture(display_list, grid);
        if (scale_x < 0.0f) {
            origin_x -= (int)(grid->width * scale_x);
        }
        if (scale_y < 0.0f) {
            origin_y -= (int)(grid->height * scale_y);
        }
        walk_grid(display_list, grid, origin_x, origin_y, scale_x, scale_y,
                  0, 0, grid->width, grid->height);
    }
}

void func_8007CE64(Gfx **display_list, TextureGrid *grid, short origin_x,
                   short origin_y, float scale_x, float scale_y,
                   u16 first_column, u16 first_row, u16 end_column,
                   u16 end_row) {
    u16 unavailable;

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
        setup_texture(display_list, grid);
        if (scale_x < 0.0f) {
            origin_x -= (int)(((short)end_column - (short)first_column) *
                              scale_x);
        }
        if (scale_y < 0.0f) {
            origin_y -= (int)(((short)end_row - (short)first_row) * scale_y);
        }
        walk_grid(display_list, grid, origin_x, origin_y, scale_x, scale_y,
                  first_column, first_row, end_column, end_row);
    }
}
