/* RODATA_VRAM 0x80072C8C */
typedef unsigned char u8;
typedef signed int s32;
typedef float f32;
typedef double f64;

typedef struct Camera {
    u8 pad00[0xA];
    u8 flags;
    u8 kind;
    u8 pad0C[0x108];
    s32 unk114;
    void *display_list;
    void *texture;
    s32 persp_norm;
    f32 projection[16];
    u8 pad164[4];
    f32 scale;
} Camera;

s32 func_800B0444(void);
void guPerspectiveF(f32 *, s32 *, f32, f32, f32, f32, f32);
extern u8 D_802194A5;
extern s32 D_8023A060;
extern char D_803B17B0[];
extern char D_1000000[], D_1000010[], D_1000020[], D_1000030[];
extern char D_1000040[], D_1000050[], D_1000060[];
extern char D_1000138[], D_1000150[], D_1000168[], D_1000180[];
extern char D_1000198[], D_10001B0[], D_10001C8[];

#define TEX(x) ((void *)(D_803B17B0 + ((s32)(x) & 0xFFFFFF)))

void func_800A72C0(Camera *cam) {
    f32 aspect;
    f32 far;
    f32 fovy;
    s32 two = 2;

    switch (D_802194A5) {
    case 1:
        if (cam->kind == 0) {
            cam->display_list = D_1000138;
            cam->texture = TEX(D_1000000);
            cam->scale = 2.29f;
        } else {
            cam->display_list = 0;
            cam->texture = 0;
        }
        break;
    case 2:
        switch (cam->kind) {
        case 0:
            cam->display_list = D_1000150;
            cam->texture = TEX(D_1000010);
            cam->scale = 1.12f;
            break;
        case 1:
            cam->display_list = D_1000168;
            cam->texture = TEX(D_1000020);
            cam->scale = 1.12f;
            break;
        default:
            cam->display_list = 0;
            cam->texture = 0;
            break;
        }
        break;
    case 3:
        switch (cam->kind) {
        case 0:
            cam->display_list = D_1000150;
            cam->texture = TEX(D_1000010);
            cam->scale = 1.12f;
            break;
        case 1:
            cam->display_list = D_10001B0;
            cam->texture = TEX(D_1000050);
            cam->scale = 2.2f;
            break;
        case 2:
            cam->display_list = D_10001C8;
            cam->texture = TEX(D_1000060);
            cam->scale = 2.2f;
            break;
        default:
            cam->display_list = 0;
            cam->texture = 0;
            break;
        }
        break;
    case 4:
        switch (cam->kind) {
        case 0:
            cam->display_list = D_1000180;
            cam->texture = TEX(D_1000030);
            cam->scale = 2.2f;
            break;
        case 1:
            cam->texture = TEX(D_1000040);
            cam->scale = 2.2f;
            cam->display_list = D_1000198;
            break;
        case 2:
            cam->texture = TEX(D_1000050);
            cam->scale = 2.2f;
            cam->display_list = D_10001B0;
            break;
        case 3:
            cam->texture = TEX(D_1000060);
            cam->scale = 2.2f;
            cam->display_list = D_10001C8;
            break;
        default:
            cam->texture = 0;
            cam->display_list = 0;
            break;
        }
        break;
    default:
        break;
    }

    if (cam->display_list == D_1000150 || cam->display_list == D_1000168)
        aspect = 2.6666667f;
    else
        aspect = 1.3333334f;

    if (func_800B0444())
        far = (f32)(f64)D_8023A060;
    else
        far = 4096.0f;

    {
        f32 *projection = cam->projection;
        s32 *persp_norm = &cam->persp_norm;
        fovy = 37.0f;
        if (cam->flags & 0x10)
            fovy = 30.0f;
        guPerspectiveF(projection, persp_norm, fovy, aspect,
                       16.0f, far, 1.0f);
    }
    cam->unk114 = 0;
}
