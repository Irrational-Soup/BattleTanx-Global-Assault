/* SPAN 0x8007C718 */
typedef unsigned short u16;

typedef struct {
    u16 unk0;
    u16 width;
    u16 height;
    u16 step_x;
    u16 step_y;
} Grid;

typedef struct {
    int w0;
    int w1;
} Gfx;

void func_8007C364(Gfx **, Grid *, short, short, int, int, int, int,
                   float, float);

void func_8007C718(Gfx **display_list, Grid *grid, short origin_x,
                   short origin_y, float scale_x, float scale_y,
                   u16 first_column, short first_row, short end_column,
                   short end_row) {
    Gfx *gfx = *display_list;
    u16 row;
    u16 next_row;
    u16 column;
    u16 next_column;

    row = first_row;
    while ((short)row < grid->height && (short)row < end_row) {
        column = first_column;
        if (grid->step_y == 0) {
            Grid *copy = grid;
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
