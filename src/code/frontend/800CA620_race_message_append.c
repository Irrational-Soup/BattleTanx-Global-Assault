/* SPAN 0x800CAA0C */
/* RODATA_VRAM 0x80073F50 */
/* Appends a '<'-separated message to a player's race message log and opens
 * the matching popup. Owns jtbl_80073F50 (7 entries, 0x1C bytes). All
 * func_800CA6AC..func_800CA9FC labels are interior labels. */
#include "types.h"

typedef struct {
    u16 count;
    u8 pad2[2];
    f32 times[4];
    u8 text[0x84];
} RaceMessageLog;

typedef struct {
    u8 pad0[0x1C];
    void** icon;
} RacePopupSub;

typedef struct {
    u8 pad0[4];
    RacePopupSub* sub;
} RacePopup;

extern u8 D_802194A5;
extern s8 D_80117EB0;
extern RaceMessageLog D_803A5D90[];
extern u8* D_8011E6B8;
extern u8* D_8011E6C0;
extern u8* D_8011E6C8;
extern u8* D_8011E6D0;
extern u8* D_8011E6D8;
extern u8* D_8011E6E0;
extern RacePopup D_8011E75C;
extern RacePopup D_8011E79C;
extern RacePopup D_8011E7DC;
extern RacePopup D_8011E81C;
extern RacePopup D_8011E85C;
extern RacePopup D_8011E89C;
extern RacePopup D_8011E8DC;
extern u8 D_8011E678[];
extern u8 D_8011E688[];
extern u8 D_8011E698[];
extern u8 D_8011E6A8[];
extern void func_800BEBA8(void* arg0, s32 arg1, s32 arg2);

void func_800CA620(u16 player, u8* msg, u16 time) {
    u8* p;
    u16 len;
    u16 i;
    s32 style;
    u8* logptr;
    u8** slot;
    RacePopup* popup;
    RacePopupSub* sub;

    if (player >= D_802194A5 || D_803A5D90[player].count >= 4) {
        return;
    }
    len = 0;
    p = D_803A5D90[player].text;
    for (i = 0; i < D_803A5D90[player].count; i++) {
        p += (*p == '<');
        while (*p != '<' && len < 0x80) {
            p++;
            len++;
        }
        if (len >= 0x80) {
            *p = 0;
            return;
        }
    }
    if (len != 0) {
        *p++ = '<';
        len++;
    }
    while (*msg != 0 && len < 0x80) {
        *p++ = *msg++;
        len++;
    }
    p[0] = '<';
    p[1] = 0;
    D_803A5D90[player].times[D_803A5D90[player].count] = time;
    D_803A5D90[player].count++;
    switch (player) {
    case 1:
        if (D_80117EB0 == 3) { style = 5; goto style_done; }
        if (D_80117EB0 < 4) { style = 2; goto style_done; }
        if (D_80117EB0 == 4) { style = 4; goto style_done; }
        style = player; goto style_done;
    case 2:
        if (D_80117EB0 == 2) { style = 6; goto style_done; }
        if (D_80117EB0 == 4) { style = 5; goto style_done; }
        style = player; goto style_done;
    case 3:
        style = 6; goto style_done;
    case 0:
    default:
        if (D_80117EB0 < 4) {
            if (D_80117EB0 < 2) style = 0;
            else style = 1;
        } else if (D_80117EB0 == 4) style = 3;
        else style = 0;
    }
style_done:
    if (D_803A5D90[player].count != 1) {
        return;
    }
    msg = (u8*)&D_803A5D90[player];
    switch (style) {
    case 1:
        slot = &D_8011E6B8;
        popup = &D_8011E79C;
        break;
    case 2:
        slot = &D_8011E6C0;
        popup = &D_8011E7DC;
        break;
    case 3:
        slot = &D_8011E6C8;
        popup = &D_8011E81C;
        break;
    case 4:
        slot = &D_8011E6D0;
        popup = &D_8011E85C;
        break;
    case 5:
        slot = &D_8011E6D8;
        popup = &D_8011E89C;
        break;
    case 6:
        slot = &D_8011E6E0;
        popup = &D_8011E8DC;
        break;
    case 0:
    default:
        slot = &D_8011E6B8;
        popup = &D_8011E75C;
        break;
    }
    *slot = msg + 20;
    sub = popup->sub;
    switch (player) {
    case 0:
        *sub->icon = D_8011E678;
        break;
    case 1:
        *sub->icon = D_8011E688;
        break;
    case 2:
        *sub->icon = D_8011E698;
        break;
    case 3:
        *sub->icon = D_8011E6A8;
        break;
    }
    func_800BEBA8(popup, 0, 1);
}
