typedef struct {
    char pad[0x58];
    unsigned int enabled;
} Rules;

extern void *D_803A53A0[];
extern char D_8023A070[];
extern char *D_8023A068;
extern int D_8023A064;
extern char D_803DA800[];
extern Rules *D_8021958C;
extern int D_80117EB4;
extern unsigned char D_80125AB3;
extern int D_8021949C;

void _bzero(void *, int);
int func_8009D144(void);
void func_80096424(int);
int func_8007B020(void);
int func_8007B030(void);
int func_800BB53C(char *, int, char *, int, int, int);
unsigned int func_8009D914(void);
void func_80095FE0(void);
void func_800F8208(void);
int func_800E8380(int, int, void *, void *);
int func_800BA6C0(void *, void *, int, char *, int, char *, int, int, int);
void func_800D9AE0(void *);

static inline void shuffle_object_table(void) {
    void *temporary;
    unsigned int random_index;
    int index;

    for (index = 0; index < 263; index++) {
        if (index != 21 && D_803A53A0[index] != 0) {
            do {
                random_index = func_8009D914() % 263;
            } while (random_index == 21 || D_803A53A0[random_index] == 0);
            temporary = D_803A53A0[index];
            D_803A53A0[index] = D_803A53A0[random_index];
            D_803A53A0[random_index] = temporary;
        }
    }
}

void func_800AF43C(void) {
    char level_data_a[32];
    char level_data_b[32];
    void *empty_entry;
    int index;
    int last_registration;
    int loaded_size;
    int level;

    D_8023A068 = D_8023A070;
    D_8023A064 = 0x15D5D8;
    _bzero(D_8023A070, 0x15D5D8);
    empty_entry = (void *)-1;
    for (index = 0x107; index >= 0; index--) {
        D_803A53A0[index] = empty_entry;
    }
    D_803A53A0[4] = 0;
    D_803A53A0[14] = 0;
    D_803A53A0[21] = 0;
    D_803A53A0[34] = 0;
    D_803A53A0[35] = 0;
    D_803A53A0[36] = 0;
    D_803A53A0[37] = 0;
    D_803A53A0[38] = 0;
    D_803A53A0[39] = 0;
    D_803A53A0[40] = 0;
    D_803A53A0[41] = 0;
    D_803A53A0[106] = 0;
    D_803A53A0[107] = 0;
    D_803A53A0[108] = 0;
    D_803A53A0[109] = 0;
    D_803A53A0[110] = 0;
    D_803A53A0[111] = 0;
    D_803A53A0[112] = 0;
    D_803A53A0[155] = 0;
    D_803A53A0[182] = 0;
    D_803A53A0[181] = 0;
    D_803A53A0[113] = 0;
    D_803A53A0[114] = 0;
    D_803A53A0[115] = 0;
    D_803A53A0[152] = 0;
    D_803A53A0[153] = 0;
    D_803A53A0[154] = 0;
    D_803A53A0[156] = 0;
    D_803A53A0[157] = 0;
    D_803A53A0[158] = 0;
    D_803A53A0[159] = 0;
    D_803A53A0[160] = 0;
    D_803A53A0[161] = 0;
    D_803A53A0[162] = 0;
    D_803A53A0[163] = 0;
    D_803A53A0[164] = 0;
    D_803A53A0[165] = 0;
    D_803A53A0[166] = 0;
    D_803A53A0[167] = 0;
    D_803A53A0[168] = 0;
    D_803A53A0[169] = 0;
    D_803A53A0[170] = 0;
    D_803A53A0[171] = 0;
    D_803A53A0[174] = 0;
    D_803A53A0[183] = 0;
    D_803A53A0[184] = 0;
    D_803A53A0[185] = 0;
    D_803A53A0[186] = 0;
    D_803A53A0[187] = 0;
    D_803A53A0[189] = 0;
    D_803A53A0[190] = 0;
    D_803A53A0[199] = 0;
    D_803A53A0[262] = 0;
    D_803A53A0[261] = 0;
    D_803A53A0[260] = 0;
    D_803A53A0[200] = 0;
    D_803A53A0[179] = 0;
    D_803A53A0[180] = 0;
    D_803A53A0[205] = 0;
    D_803A53A0[202] = 0;
    D_803A53A0[203] = 0;
    D_803A53A0[206] = 0;
    D_803A53A0[251] = 0;
    D_803A53A0[252] = 0;
    D_803A53A0[253] = 0;
    D_803A53A0[254] = 0;
    D_803A53A0[255] = 0;
    D_803A53A0[256] = 0;
    D_803A53A0[257] = 0;
    D_803A53A0[258] = 0;
    D_803A53A0[259] = 0;
    if (func_8009D144()) {
        for (index = 0; index < 15; index++) {
            if (D_8021958C->enabled & (1 << index)) {
                func_80096424(index);
            }
        }
    } else {
        last_registration = D_80117EB4 == 10 ? 11 : 10;
        for (index = 0; index <= last_registration; index++) {
            func_80096424(index);
        }
    }
    loaded_size = func_800BB53C(D_8023A068, D_8023A064, D_803DA800,
                                0x25800, func_8007B020(), func_8007B030());
    if (loaded_size < 0) {
        return;
    }
    loaded_size = (loaded_size + 7) & ~7;
    D_8023A068 += loaded_size;
    D_8023A064 -= loaded_size;
    for (index = 0; index < 0x108; index++) {
        if (D_803A53A0[index] == (void *)-1) {
            D_803A53A0[index] = 0;
        }
    }
    func_80095FE0();
    func_800F8208();
    if (D_80125AB3) {
        shuffle_object_table();
    }
    level = func_800E8380(D_8021949C, func_8009D144(), level_data_a,
                          level_data_b);
    if (func_800BA6C0(level_data_a, level_data_b, level, D_8023A068,
                      D_8023A064, D_803DA800, 0x25800, func_8007B020(),
                      func_8007B030()) >= 0) {
        func_800D9AE0(D_803A53A0[21]);
    }
}
