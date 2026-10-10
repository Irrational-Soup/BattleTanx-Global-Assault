typedef unsigned char u8;
typedef unsigned int u32;

typedef struct {
    u32 word0;
    u32 word1;
} DisplayCommand;

typedef struct {
    char pad00[4];
    DisplayCommand *display_list;
    char pad08[4];
    int unk0C;
    int unk10;
} Mesh;

typedef struct {
    Mesh *mesh;
    u8 kind;
} ModelObject;

extern u8 D_80219590[][3];
extern int D_802195A0[];
extern DisplayCommand D_80116710[17];
extern DisplayCommand D_80116798[17];

void func_800F80E8(int id, int *a, int *b, u8 *color);

static inline void apply_color(DisplayCommand *command, u8 *color) {
    int count = 0;
    u32 end_opcode = 0xDF000000;
    u32 color_opcode = 0xFB000000;
    DisplayCommand *current = command;

    do {
        u32 opcode = current->word0;

        if (opcode == end_opcode) {
            break;
        }
        if (opcode == color_opcode) {
            current->word0 = opcode;
            current->word1 =
                (color[0] << 24) | (color[1] << 16) |
                (color[2] << 8) | 0xFF;
        }
        count++;
        current++;
    } while (count < 1000);
}

void func_800B9AB0(ModelObject **object_ptr, int player) {
    unsigned long color = player * 3;
    ModelObject *object = *object_ptr;
    Mesh *mesh;
    int a;
    int b;

    color += (unsigned long)D_80219590;
    apply_color(object->mesh->display_list, (u8 *)color);
    if (object->kind == 2) {
        mesh = object->mesh;
        func_800F80E8(D_802195A0[player], &a, &b, (u8 *)color);
        if (a != 0) {
            mesh->unk10 = a;
            mesh->unk0C = b;
        }
    }
}

/*
 * Source shape adapted from the CC0 BattleTanx func_80085330 implementation.
 * Global Assault adds the geometry-mode repair and expands the tables to 17.
 */
void func_800B9B8C(void *arg0, int arg1) {
    int *source;
    int *replacement;
    int end;
    int index;
    DisplayCommand *command;
    DisplayCommand *current;
    DisplayCommand *source_base;
    DisplayCommand *replacement_base;
    int end_opcode;
    int opcode_mask;
    int geometry_opcode;
    int set_bits;
    int clear_bits;
    int fallback_bits;
    int replacement0;
    int replacement4;

    command = arg0;
    if (arg1 > 0) {
        end_opcode = 0xDF000000;
        opcode_mask = 0xFF000000;
        geometry_opcode = 0xD9000000;
        set_bits = 0x10400;
        clear_bits = ~0x200;
        fallback_bits = 0xFFFBFF;
        source_base = D_80116710;
        replacement_base = D_80116798;
        end = (int)((arg1 << 3) + (u32)command);
loop:
        if (command->word0 != end_opcode) {
            index = 0;
            if ((command->word0 & opcode_mask) == geometry_opcode) {
                if (command->word1 != 0) {
                    command->word1 = (command->word1 | set_bits) & clear_bits;
                } else {
                    command->word0 |= fallback_bits;
                    index = 0;
                }
            }
            index = 0;
            current = command;
            replacement = (int *)replacement_base;
            source = (int *)source_base;
            do {
                if ((((DisplayCommand *)source)->word0 == current->word0) &&
                    (((DisplayCommand *)source)->word1 == current->word1)) {
                    replacement0 = ((DisplayCommand *)replacement)->word0;
                    replacement4 = ((DisplayCommand *)replacement)->word1;
                    current->word0 = replacement0;
                    current->word1 = replacement4;
                }
                replacement = (int *)((DisplayCommand *)replacement + 1);
                index += 1;
                source = (int *)((DisplayCommand *)source + 1);
            } while (index < 17);
            command++;
            if ((int)command < end) {
                goto loop;
            }
        }
    }
}
