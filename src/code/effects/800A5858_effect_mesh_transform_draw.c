/* RODATA_VRAM 0x80072AA0 */
/* SPAN 0x800A5BD8 */
typedef unsigned char u8;
typedef unsigned short u16;
typedef unsigned int u32;

typedef struct {
    float x;
    float y;
    float z;
} Vec3;

typedef struct {
    char bytes[0xC];
} EffectHeader;

typedef struct {
    u32 w0;
    u32 w1;
} Gfx;

typedef struct {
    float m[4][4];
    int flag;
} Matrix;

typedef struct {
    int operation;
    u8 primitiveStart[4];
    u8 environmentStart[4];
    u8 primitiveEnd[4];
    u8 environmentEnd[4];
    float scaleStart;
    float scaleEnd;
    float heightStart;
    float heightEnd;
    int duration;
    u16 spin;
    int model;
    int secondaryModel;
} MeshEffectDefinition;

typedef struct {
    EffectHeader header;
    MeshEffectDefinition *definition;
    int startTime;
    Vec3 position;
    float scale;
    u16 angle;
    u8 kind;
    char pad27;
    u8 direction;
} MeshEffect;

extern int D_8021945C;
extern void *D_803A53A0[];

u8 func_800AD14C(float x, float y, float radius, u8 kind);
void func_8009EFD4(Matrix *matrix, float x, float z, float y, u16 angle);
void func_8009F824(Matrix *matrix, float x, float y, float z);
void func_800AD9A8(void *model, int arg1, Matrix *matrix, int arg3,
                   int arg4, u8 visible, Gfx *commands, int count);

void func_800A5858(MeshEffect *effect) {
    MeshEffectDefinition *definition = effect->definition;
    u8 environment[4];
    u8 primitive[4];
    Gfx commands[2];
    Matrix matrix = {{{1.0f, 0.0f, 0.0f, 0.0f},
                      {0.0f, 1.0f, 0.0f, 0.0f},
                      {0.0f, 0.0f, 1.0f, 0.0f},
                      {0.0f, 0.0f, 0.0f, 1.0f}}, 0};
    float progress = ((float)(D_8021945C - effect->startTime)) /
                     definition->duration;
    float scaleX = effect->scale *
                   ((progress * (definition->scaleEnd - definition->scaleStart)) +
                    definition->scaleStart);
    float scaleY = effect->scale *
                   ((progress * (definition->heightEnd - definition->heightStart)) +
                    definition->heightStart);
    u8 visible = func_800AD14C(effect->position.x, effect->position.y,
                               scaleX, effect->kind);
    Gfx *command;
    u8 *start;
    u8 *end;
    u16 angle;
    int i;
    Matrix *matrixPointer;

    if (visible == 0) {
        return;
    }
    matrixPointer = &matrix;
    angle = effect->angle +
            (((D_8021945C - effect->startTime) * effect->direction) *
             definition->spin);
    start = definition->environmentStart;
    end = definition->environmentEnd;
    for (i = 0; i < 4; i++) {
        environment[i] = start[i] + ((end[i] - start[i]) * progress);
    }

    start = definition->primitiveStart;
    end = definition->primitiveEnd;
    for (i = 0; i < 4; i++) {
        primitive[i] = start[i] + ((end[i] - start[i]) * progress);
    }

    command = commands;
    {
        Gfx *packet = command++;
        packet->w0 = 0xFA000000;
        packet->w1 = ((u32)primitive[0] << 24) |
                     ((u32)primitive[1] << 16) |
                     ((u32)primitive[2] << 8) | primitive[3];
    }
    {
        Gfx *packet = command++;
        packet->w0 = 0xFB000000;
        packet->w1 = ((u32)environment[0] << 24) |
                     ((u32)environment[1] << 16) |
                     ((u32)environment[2] << 8) | environment[3];
    }

    func_8009EFD4(matrixPointer, effect->position.x, effect->position.z,
                   effect->position.y, angle);
    func_8009F824(matrixPointer, scaleX, scaleY, scaleX);
    func_800AD9A8(D_803A53A0[definition->model], 0, matrixPointer, 1, 0,
                   visible, commands, 2);
    if (definition->secondaryModel != 263) {
        func_800AD9A8(D_803A53A0[definition->secondaryModel], 0,
                       matrixPointer, 5, 0, visible, commands, 2);
    }
}
