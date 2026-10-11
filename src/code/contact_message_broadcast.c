typedef unsigned char u8;
typedef short s16;
typedef unsigned short u16;

typedef struct {
    float x;
    float y;
    float z;
} Vec3;

typedef struct {
    float x;
    float z;
} Vec2;

typedef struct {
    int active;
    int type;
} Task;

typedef struct {
    void (*update)(Task *task, int *result);
    void (*message)(Task *task, int arg1, int kind, void *data, int arg4);
    void (*draw)(Task *task);
} TaskClass;

typedef struct {
    Task *task;
    u16 id;
    float x;
    float z;
    float y;
    Vec2 push;
    float unk1C;
    s16 side;
} Contact;

typedef struct {
    Vec3 position;
    int arg0;
    int arg1;
} ContactMessage;

extern TaskClass D_80224B58[];
extern s16 D_80397650;

u16 func_800B205C(int data, s16 x, s16 z, s16 y, s16 dx0, s16 dx1,
                  s16 dz0, s16 dz1, s16 a8, s16 a9, u16 a10, int kind,
                  u16 grid);
u16 func_800B3748(u16 id, int mask, Contact *out, u16 grow, u16 single);

void func_800A2C6C(u8 grid, Vec3 *position, s16 radius, int arg0, int arg1,
                   int mask) {
    Contact contacts[32];
    ContactMessage message;
    u16 id;
    u16 count;
    int i;
    Contact *list = contacts;

    id = func_800B205C(0, position->x, position->y, position->z,
                       -radius, radius, -radius, radius, -radius, radius,
                       0, 0, grid);
    if (id != 0xFFFF) {
        D_80397650 = 0;
        count = func_800B3748(id, mask, list, 0, 0);
        if (count != 0) {
            message.position = *position;
            message.arg0 = arg0;
            message.arg1 = arg1;
            for (i = 0; i < count; i++) {
                if (list[i].task != 0) {
                    if (D_80224B58[list[i].task->type].message != 0) {
                        D_80224B58[list[i].task->type].message(
                            list[i].task, 0, 3, &message, 0);
                    }
                }
            }
        }
    }
}
