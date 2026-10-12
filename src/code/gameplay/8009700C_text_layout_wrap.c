/* SPAN 0x800973E0 */
#include "types.h"

typedef struct { u8 pad[4]; u16 advance; } GlyphMetric;
typedef struct {
    u16 line_height, pad2, space_advance, pad6;
    u32 pad8;
    GlyphMetric *glyphs;
} FontMetric;

extern FontMetric D_801B4450[];
extern u16 func_80096928(u8);
extern s16 func_80096A54(void *, u8, u16, s16, s16, f32, f32);

u16 func_8009700C(void *gdl, u8 *text, u16 font_id, s16 x, s16 y,
                  f32 scale_x, f32 scale_y, u16 line_width, u16 align,
                  s32 limit) {
    FontMetric *font = &D_801B4450[font_id];
    u8 *scan = text;
    u8 *draw = text;
    s16 consumed = 0;
    u16 cur_y = y;

    u16 max_width = line_width;
    s16 end = limit;
    while (*scan != 0) {
        {
            s16 count = 0;
            s16 width = 0;
            s16 last_advance = 0;
            s16 break_width = 0;
            s16 break_count = 0;
            u16 escaped;

            while (*scan == ' ') {
                    scan++;
                    draw++;
                    consumed++;
            }

            escaped = 0;
            while (width < max_width) {
                if (*scan == 0 || (end >= 0 && consumed + count >= end)) {
                    break_count = count;
                    break_width = width;
                    break;
                }
                if (*scan == ' ') {
                    break_count = count;
                    break_width = width;
                    last_advance = (s16)((f32)font->space_advance * scale_x);
                    width += last_advance;
                } else if ((*scan == '\n') | (*scan == '<')) {
                    break_count = count;
                    break_width = width;
                    escaped = 1;
                    break;
                } else {
                    u16 glyph = func_80096928(*scan);
                    if (glyph != 0xFFFF) {
                        u16 advance = font->glyphs[glyph].advance;
                        if (advance != 0) {
                            last_advance = (s16)((f32)advance * scale_x);
                            width += last_advance;
                        }
                    }
                }
                scan++;
                count++;
            }

            {
                s16 draw_count = break_count;
                s16 cur_x;
                u16 i;
                if (draw_count == 0) {
                    draw_count = count - 1;
                    if (draw_count < 0) {
                        scan++;
                        if (escaped) {
                            draw++;
                            cur_y += (s16)((f32)font->line_height * scale_y);
                            continue;
                        }
                        return 0;
                    }
                    break_width = width - last_advance;
                }
                switch (align) {
                case 0: cur_x = x; break;
                case 1: cur_x = x + (line_width - break_width); break;
                case 2:
                default: cur_x = x + ((max_width - break_width) >> 1); break;
                }
                for (i = 0; i < draw_count; i++) {
                    u8 c = *draw++;
                    cur_x += func_80096A54(gdl, c, font_id, cur_x, cur_y,
                                           scale_x, scale_y);
                }
                consumed += draw_count;
                if (*scan == 0 && width < max_width) return 1;
                if (break_count != 0) {
                    draw++;
                    consumed++;
                }
                scan = draw;
                if ((end >= 0) & (end < consumed)) return 0;
                cur_y += (s16)((f32)font->line_height * scale_y);

            }
        }
    }
    return 1;
}
