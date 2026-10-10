/* SPAN 0x800D67F0 */
typedef struct Vec3 {
  float x;
  float y;
  float z;
} Vec3;
typedef struct Mtx68 {
  int words[17];
} Mtx68;

extern Mtx68 D_80074F94;
extern int D_8021945C;
extern float D_80074FD8;
extern float D_80074FDC;
extern float D_80074FE0;
extern void *D_803A56BC;
extern void *D_803A57A0;
extern void *D_803A57B0;
extern void *D_803A57B4;
extern void *D_803A57B8;
extern void func_8009EF30(Mtx68 *, Vec3 *);
extern void func_8009F090(Mtx68 *, int, int, int);
extern void func_8009F824(Mtx68 *, float, float, float);
extern void func_800AD9A8(void *, int, Mtx68 *, int, int, unsigned short,
                          unsigned int *, int);

inline static int byte_value(unsigned char value) {
  return value;
}

void func_800D6508(Vec3 *position, unsigned short rotation,
                   unsigned char unused, float scale, unsigned char alpha,
                   unsigned char intensity, float distance) {
  unsigned int commands[4];
  Mtx68 matrix;
  void *model;
  unsigned int *command_pointer;
  unsigned short intensity_value;
  unsigned int primitive_command;
  int command_count;
  Mtx68 *matrix_pointer;

  primitive_command = 0xFA000000;
  matrix = D_80074F94;
  matrix_pointer = &matrix;
  intensity_value = byte_value(intensity);
  commands[1] = alpha | 0xCA2C0800;
  commands[0] = primitive_command;
  commands[2] = 0xFB000000;
  func_8009EF30(matrix_pointer, position);
  commands[3] = 0xFFF36500;
  command_pointer = commands;
  command_count = 2;
  func_8009F090(matrix_pointer, 0, (unsigned short)(rotation + 0x4000),
                 (unsigned short)((D_8021945C * 1820) + (alpha * 5462)));
  func_8009F824(matrix_pointer, scale, scale, scale);
  func_800AD9A8(D_803A56BC, 0, matrix_pointer, 1, 0,
                intensity_value & 0xff, command_pointer, command_count);
  matrix_pointer->words[16] = 0;
  commands[0] = primitive_command;
  commands[1] = alpha | 0x2E2E2E00;
  commands[2] = 0xFB000000;
  commands[3] = 0xBFBFBF00;
  func_8009EF30(matrix_pointer, position);
  func_8009F090(matrix_pointer, 0, (unsigned short)(rotation + 0x4000),
                 (unsigned short)((D_8021945C * 64625) + (alpha * 5462)));
  func_8009F824(matrix_pointer, scale, scale, scale);
  if ((scale * D_80074FD8) < distance) {
    model = D_803A57A0;
  } else if ((scale * D_80074FDC) < distance) {
    model = D_803A57B0;
  } else if ((scale * D_80074FE0) < distance) {
    model = D_803A57B4;
  } else {
    model = D_803A57B8;
  }
  func_800AD9A8(model, 0, matrix_pointer, 1, 0, intensity_value & 0xff,
                command_pointer, command_count);
}
