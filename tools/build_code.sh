#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root_dir"

if command -v mips-linux-gnu-as >/dev/null 2>&1; then
    tool_prefix="$(dirname "$(command -v mips-linux-gnu-as)")/mips-linux-gnu-"
else
    tools/bootstrap_mips_binutils.sh
    local_root="$root_dir/.toolchain/mips-binutils/usr"
    tool_prefix="$local_root/bin/mips-linux-gnu-"
    export LD_LIBRARY_PATH="$local_root/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
fi

mkdir -p build/us/asm/us build/us/asm/us/data build/us/assets/extracted/us

# These bytes spell ASCII "REMA" and are data, despite decoding as a branch.
# Emitting the word directly avoids a false cross-file branch relocation.
for asm_source in asm/us/*.s; do
    sed -i 's/beql       \$s2, \$a1, \.\?L80099664/.word      0x52454D41/' \
        "$asm_source"
    sed -i -E \
        's/^(glabel|dlabel|endlabel|enddlabel) (osViClock|__osShutdown|__OSGlobalIntMask|__osRcpImTable|osClockRate|D_80126F80|rspbootTextStart|gspF3DEX_fifoDataStart|n_aspMainTextStart|__libm_qnan_f|osViModeMpalLan1|osViModeNtscLan1|osViModePalLan1|xlitob_data_0000|xlitob_data_0014|n_alGlobals|alGlobals|__osContinitialized|__osHwIntTable|__osPiAccessQueueEnabled|D_80126EC0|alGlobals_80126ED0|__osThreadTail|__osRunQueue|__osActiveQueue|__osRunningThread|__osFaultedThread|__osTimerList|vi_data_0000|__osViCurr|__osViNext)$/\1 __retail_\2/' \
        "$asm_source"
done

# Typed standalone rodata objects replace labels that splat also emits inside
# the aggregate retail-data assembly.  Rename only the generated definitions;
# references keep their original names and therefore resolve to the typed C
# objects.  Deriving this list from the manifest sources avoids a second,
# hand-maintained symbol catalogue whenever another pool is recovered.
python3 tools/rename_retail_asm_labels.py \
    config/us/typed_rodata_units.tsv src/code asm/us

for boot_exception_source in asm/us/main_8007*.s; do
    [[ -f "$boot_exception_source" ]] || continue
    sed -i \
        -e 's/__osExceptionPreamble/__bootExceptionPreamble/g' \
        -e 's/__osException/__bootException/g' \
        -e 's/\.L80078CF4/D_80078CF4/g' \
        "$boot_exception_source"
done

"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/header.s.o asm/us/header.s
if false; then
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_before_80077C40.s.o asm/us/main_before_80077C40.s
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_80077FD0_to_80078048.s.o asm/us/main_80077FD0_to_80078048.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_80077FD0_to_80078048.s.o .text 0x78 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_80078274_to_80078908.s.o asm/us/main_80078274_to_80078908.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_80078274_to_80078908.s.o .text 0x694 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_80078ADC_to_80078C68.s.o asm/us/main_80078ADC_to_80078C68.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_80078ADC_to_80078C68.s.o .text 0x18c --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_80078CD8_to_8007A710.s.o asm/us/main_80078CD8_to_8007A710.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_80078CD8_to_8007A710.s.o .text 0x1a38 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_8007A75C_to_8007AC34.s.o asm/us/main_8007A75C_to_8007AC34.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_8007A75C_to_8007AC34.s.o .text 0x4d8 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_8007AD40_to_8007AD94.s.o asm/us/main_8007AD40_to_8007AD94.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_8007AD40_to_8007AD94.s.o .text 0x54 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_8007ADF0_to_8007B020.s.o asm/us/main_8007ADF0_to_8007B020.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_8007ADF0_to_8007B020.s.o .text 0x230 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_8007B0E4_to_8007B1F0.s.o asm/us/main_8007B0E4_to_8007B1F0.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_8007B0E4_to_8007B1F0.s.o .text 0x10c --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_8007B8EC_to_8007BCF0.s.o asm/us/main_8007B8EC_to_8007BCF0.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_8007B8EC_to_8007BCF0.s.o .text 0x404 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_8007D468_to_8007D470.s.o asm/us/main_8007D468_to_8007D470.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_8007D468_to_8007D470.s.o .text 0x8 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_8007D5B0_to_8007D694.s.o asm/us/main_8007D5B0_to_8007D694.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_8007D5B0_to_8007D694.s.o .text 0xe4 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_8007D69C_to_8007D710.s.o asm/us/main_8007D69C_to_8007D710.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_8007D69C_to_8007D710.s.o .text 0x74 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_8007D718_to_8007D720.s.o asm/us/main_8007D718_to_8007D720.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_8007D718_to_8007D720.s.o .text 0x8 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_8007D7C4_to_8007E1FC.s.o asm/us/main_8007D7C4_to_8007E1FC.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_8007D7C4_to_8007E1FC.s.o .text 0xa38 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_8007E210_to_8007E778.s.o asm/us/main_8007E210_to_8007E778.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_8007E210_to_8007E778.s.o .text 0x568 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_8007E7A8_to_80081FD8.s.o asm/us/main_8007E7A8_to_80081FD8.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_8007E7A8_to_80081FD8.s.o .text 0x3830 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_80082004_to_80082B40.s.o asm/us/main_80082004_to_80082B40.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_80082004_to_80082B40.s.o .text 0xb3c --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_80082B68_to_80082BD4.s.o asm/us/main_80082B68_to_80082BD4.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_80082B68_to_80082BD4.s.o .text 0x6c --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_80082C1C_to_80082D60.s.o asm/us/main_80082C1C_to_80082D60.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_80082C1C_to_80082D60.s.o .text 0x144 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_80083028_to_80083FCC.s.o asm/us/main_80083028_to_80083FCC.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_80083028_to_80083FCC.s.o .text 0xfa4 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_80083FF8_to_80084C50.s.o asm/us/main_80083FF8_to_80084C50.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_80083FF8_to_80084C50.s.o .text 0xc58 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800859E4_to_8009C284.s.o asm/us/main_800859E4_to_8009C284.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800859E4_to_8009C284.s.o .text 0xee9c --alignment 4
for spec in \
    main_80095F08_to_80096250:0x348 \
    main_8009700C_to_800973E0:0x3d4 \
    main_8009755C_to_80097560:0x4 \
    main_8009859C_to_800985A0:0x4 \
    main_80099824_to_80099830:0xc
do
    unit="${spec%%:*}"
    size="${spec##*:}"
    "${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
        -o "build/us/asm/us/${unit}.s.o" "asm/us/${unit}.s"
    python3 tools/trim_elf32_section.py \
        "build/us/asm/us/${unit}.s.o" .text "${size}" --alignment 4
done
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_8009C524_to_8009D144.s.o asm/us/main_8009C524_to_8009D144.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_8009C524_to_8009D144.s.o .text 0xc20 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_8009D168_to_8009D578.s.o asm/us/main_8009D168_to_8009D578.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_8009D168_to_8009D578.s.o .text 0x410 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_8009D6F8_to_8009D72C.s.o asm/us/main_8009D6F8_to_8009D72C.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_8009D6F8_to_8009D72C.s.o .text 0x34 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_8009D8A0_to_8009D914.s.o asm/us/main_8009D8A0_to_8009D914.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_8009D8A0_to_8009D914.s.o .text 0x74 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_8009D960_to_8009DA34.s.o asm/us/main_8009D960_to_8009DA34.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_8009D960_to_8009DA34.s.o .text 0xd4 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_8009DAB0_to_8009DB0C.s.o asm/us/main_8009DAB0_to_8009DB0C.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_8009DAB0_to_8009DB0C.s.o .text 0x5c --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800ACE6C_to_800ACE70.s.o asm/us/main_800ACE6C_to_800ACE70.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800ACE6C_to_800ACE70.s.o .text 0x4 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_8009E0E8_to_8009EEA0.s.o asm/us/main_8009E0E8_to_8009EEA0.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_8009E0E8_to_8009EEA0.s.o .text 0xdb8 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_8009EED8_to_8009EEE0.s.o asm/us/main_8009EED8_to_8009EEE0.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_8009EED8_to_8009EEE0.s.o .text 0x8 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_8009EF4C_to_8009F064.s.o asm/us/main_8009EF4C_to_8009F064.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_8009EF4C_to_8009F064.s.o .text 0x118 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_8009F5AC_to_8009F768.s.o asm/us/main_8009F5AC_to_8009F768.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_8009F5AC_to_8009F768.s.o .text 0x1bc --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_8009FCCC_to_8009FF1C.s.o asm/us/main_8009FCCC_to_8009FF1C.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_8009FCCC_to_8009FF1C.s.o .text 0x250 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800A0744_to_800A0750.s.o asm/us/main_800A0744_to_800A0750.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800A0744_to_800A0750.s.o .text 0xc --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_8009FFB8_to_800A1280.s.o asm/us/main_8009FFB8_to_800A1280.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_8009FFB8_to_800A1280.s.o .text 0x12c8 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800A1384_to_800A179C.s.o asm/us/main_800A1384_to_800A179C.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800A1384_to_800A179C.s.o .text 0x418 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800A18D0_to_800A1A28.s.o asm/us/main_800A18D0_to_800A1A28.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800A18D0_to_800A1A28.s.o .text 0x158 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800A1B44_to_800A2B74.s.o asm/us/main_800A1B44_to_800A2B74.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800A1B44_to_800A2B74.s.o .text 0x1030 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800A2B9C_to_800A2DFC.s.o asm/us/main_800A2B9C_to_800A2DFC.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800A2B9C_to_800A2DFC.s.o .text 0x260 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800A2E5C_to_800A4098.s.o asm/us/main_800A2E5C_to_800A4098.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800A2E5C_to_800A4098.s.o .text 0x123c --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800A40CC_to_800A6ABC.s.o asm/us/main_800A40CC_to_800A6ABC.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800A40CC_to_800A6ABC.s.o .text 0x29f0 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800A6B7C_to_800A7290.s.o asm/us/main_800A6B7C_to_800A7290.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800A6B7C_to_800A7290.s.o .text 0x714 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800A9080_to_800A974C.s.o asm/us/main_800A9080_to_800A974C.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800A9080_to_800A974C.s.o .text 0x6cc --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800A977C_to_800A9BF0.s.o asm/us/main_800A977C_to_800A9BF0.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800A977C_to_800A9BF0.s.o .text 0x474 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800A9C24_to_800A9D50.s.o asm/us/main_800A9C24_to_800A9D50.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800A9C24_to_800A9D50.s.o .text 0x12c --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800A9D78_to_800AA598.s.o asm/us/main_800A9D78_to_800AA598.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800A9D78_to_800AA598.s.o .text 0x820 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800AA5C4_to_800B0444.s.o asm/us/main_800AA5C4_to_800B0444.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800AA5C4_to_800B0444.s.o .text 0x5e80 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800B044C_to_800B06A8.s.o asm/us/main_800B044C_to_800B06A8.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800B044C_to_800B06A8.s.o .text 0x25c --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800B06D8_to_800B5F30.s.o asm/us/main_800B06D8_to_800B5F30.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800B06D8_to_800B5F30.s.o .text 0x5858 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800B5F70_to_800B99C0.s.o asm/us/main_800B5F70_to_800B99C0.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800B5F70_to_800B99C0.s.o .text 0x3a50 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800B99F8_to_800B9A4C.s.o asm/us/main_800B99F8_to_800B9A4C.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800B99F8_to_800B9A4C.s.o .text 0x54 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800B9AB0_to_800B9C68.s.o asm/us/main_800B9AB0_to_800B9C68.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800B9AB0_to_800B9C68.s.o .text 0x1b8 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800B9CAC_to_800B9D4C.s.o asm/us/main_800B9CAC_to_800B9D4C.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800B9CAC_to_800B9D4C.s.o .text 0xa0 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800B9E24_to_800BD880.s.o asm/us/main_800B9E24_to_800BD880.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800B9E24_to_800BD880.s.o .text 0x3a5c --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800BD93C_to_800BFD40.s.o asm/us/main_800BD93C_to_800BFD40.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800BD93C_to_800BFD40.s.o .text 0x2404 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800BFE94_to_800BFEA0.s.o asm/us/main_800BFE94_to_800BFEA0.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800BFE94_to_800BFEA0.s.o .text 0xc --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800C6914_to_800C6918.s.o asm/us/main_800C6914_to_800C6918.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800C6914_to_800C6918.s.o .text 0x4 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/data/main_800C6918_textbin.s.o asm/us/data/main_800C6918_textbin.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/data/main_800C6918_textbin.s.o .text 0x8 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800CB10C_to_800CB110.s.o asm/us/main_800CB10C_to_800CB110.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800CB10C_to_800CB110.s.o .text 0x4 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800CD96C_to_800CD970.s.o asm/us/main_800CD96C_to_800CD970.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800CD96C_to_800CD970.s.o .text 0x4 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800CDBDC_to_800CDBE0.s.o asm/us/main_800CDBDC_to_800CDBE0.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800CDBDC_to_800CDBE0.s.o .text 0x4 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800D05D8_to_800D05E0.s.o asm/us/main_800D05D8_to_800D05E0.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800D05D8_to_800D05E0.s.o .text 0x8 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800D3C64_to_800D404C.s.o asm/us/main_800D3C64_to_800D404C.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800D3C64_to_800D404C.s.o .text 0x3e8 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800D5C7C_to_800D5C80.s.o asm/us/main_800D5C7C_to_800D5C80.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800D5C7C_to_800D5C80.s.o .text 0x4 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800D5E2C_to_800D67F0.s.o asm/us/main_800D5E2C_to_800D67F0.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800D5E2C_to_800D67F0.s.o .text 0x9c4 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800D6E34_to_800D6E40.s.o asm/us/main_800D6E34_to_800D6E40.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800D6E34_to_800D6E40.s.o .text 0xc --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800D7DD4_to_800D7DE0.s.o asm/us/main_800D7DD4_to_800D7DE0.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800D7DD4_to_800D7DE0.s.o .text 0xc --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800D84D8_to_800D84DC.s.o asm/us/main_800D84D8_to_800D84DC.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800D84D8_to_800D84DC.s.o .text 0x4 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800D88E8_to_800D88F0.s.o asm/us/main_800D88E8_to_800D88F0.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800D88E8_to_800D88F0.s.o .text 0x8 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800D92D4_to_800D92E0.s.o asm/us/main_800D92D4_to_800D92E0.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800D92D4_to_800D92E0.s.o .text 0xc --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800D9B48_to_800D9B50.s.o asm/us/main_800D9B48_to_800D9B50.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800D9B48_to_800D9B50.s.o .text 0x8 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800D9D50_to_800DA340.s.o asm/us/main_800D9D50_to_800DA340.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800D9D50_to_800DA340.s.o .text 0x5f0 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800DA7D0_to_800DA984.s.o asm/us/main_800DA7D0_to_800DA984.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800DA7D0_to_800DA984.s.o .text 0x1b4 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800DAAE0_to_800DAC34.s.o asm/us/main_800DAAE0_to_800DAC34.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800DAAE0_to_800DAC34.s.o .text 0x154 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800DB4E8_to_800DB6F0.s.o asm/us/main_800DB4E8_to_800DB6F0.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800DB4E8_to_800DB6F0.s.o .text 0x208 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800DB850_to_800DC214.s.o asm/us/main_800DB850_to_800DC214.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800DB850_to_800DC214.s.o .text 0x9c4 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800DC7A4_to_800DC7B0.s.o asm/us/main_800DC7A4_to_800DC7B0.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800DC7A4_to_800DC7B0.s.o .text 0xc --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800DD28C_to_800DD290.s.o asm/us/main_800DD28C_to_800DD290.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800DD28C_to_800DD290.s.o .text 0x4 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800DD75C_to_800DDF04.s.o asm/us/main_800DD75C_to_800DDF04.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800DD75C_to_800DDF04.s.o .text 0x7a8 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800DF0C4_to_800DF0D0.s.o asm/us/main_800DF0C4_to_800DF0D0.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800DF0C4_to_800DF0D0.s.o .text 0xc --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800E16D8_to_800E18D8.s.o asm/us/main_800E16D8_to_800E18D8.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800E16D8_to_800E18D8.s.o .text 0x200 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800E1BA4_to_800E2018.s.o asm/us/main_800E1BA4_to_800E2018.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800E1BA4_to_800E2018.s.o .text 0x474 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800E2520_to_800E26A8.s.o asm/us/main_800E2520_to_800E26A8.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800E2520_to_800E26A8.s.o .text 0x188 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800E2F9C_to_800E3404.s.o asm/us/main_800E2F9C_to_800E3404.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800E2F9C_to_800E3404.s.o .text 0x468 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800E3460_to_800E3FDC.s.o asm/us/main_800E3460_to_800E3FDC.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800E3460_to_800E3FDC.s.o .text 0xb7c --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800E48A8_to_800E48E0.s.o asm/us/main_800E48A8_to_800E48E0.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800E48A8_to_800E48E0.s.o .text 0x38 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800E56C8_to_800E56D0.s.o asm/us/main_800E56C8_to_800E56D0.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800E56C8_to_800E56D0.s.o .text 0x8 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800E58C4_to_800E58D0.s.o asm/us/main_800E58C4_to_800E58D0.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800E58C4_to_800E58D0.s.o .text 0xc --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800E603C_to_800E6040.s.o asm/us/main_800E603C_to_800E6040.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800E603C_to_800E6040.s.o .text 0x4 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800E64EC_to_800E64F0.s.o asm/us/main_800E64EC_to_800E64F0.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800E64EC_to_800E64F0.s.o .text 0x4 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800E6B04_to_800E713C.s.o asm/us/main_800E6B04_to_800E713C.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800E6B04_to_800E713C.s.o .text 0x638 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800E73B0_to_800E759C.s.o asm/us/main_800E73B0_to_800E759C.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800E73B0_to_800E759C.s.o .text 0x1ec --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800E7768_to_800E7968.s.o asm/us/main_800E7768_to_800E7968.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800E7768_to_800E7968.s.o .text 0x200 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800E7A10_to_800E7DF8.s.o asm/us/main_800E7A10_to_800E7DF8.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800E7A10_to_800E7DF8.s.o .text 0x3e8 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800E7F5C_to_800E7F60.s.o asm/us/main_800E7F5C_to_800E7F60.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800E7F5C_to_800E7F60.s.o .text 0x4 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800E8378_to_800E8380.s.o asm/us/main_800E8378_to_800E8380.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800E8378_to_800E8380.s.o .text 0x8 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800E92E8_to_800E92F0.s.o asm/us/main_800E92E8_to_800E92F0.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800E92E8_to_800E92F0.s.o .text 0x8 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800E9E78_to_800E9E80.s.o asm/us/main_800E9E78_to_800E9E80.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800E9E78_to_800E9E80.s.o .text 0x8 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800EA224_to_800EA714.s.o asm/us/main_800EA224_to_800EA714.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800EA224_to_800EA714.s.o .text 0x4f0 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800EAC2C_to_800EAC30.s.o asm/us/main_800EAC2C_to_800EAC30.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800EAC2C_to_800EAC30.s.o .text 0x4 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800EB714_to_800EB720.s.o asm/us/main_800EB714_to_800EB720.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800EB714_to_800EB720.s.o .text 0xc --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800EBA98_to_800EBCA8.s.o asm/us/main_800EBA98_to_800EBCA8.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800EBA98_to_800EBCA8.s.o .text 0x210 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800EBDA0_to_800EBF80.s.o asm/us/main_800EBDA0_to_800EBF80.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800EBDA0_to_800EBF80.s.o .text 0x1e0 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800EC788_to_800EC790.s.o asm/us/main_800EC788_to_800EC790.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800EC788_to_800EC790.s.o .text 0x8 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800EC8E8_to_800ECEBC.s.o asm/us/main_800EC8E8_to_800ECEBC.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800EC8E8_to_800ECEBC.s.o .text 0x5d4 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800ED4F4_to_800ED63C.s.o asm/us/main_800ED4F4_to_800ED63C.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800ED4F4_to_800ED63C.s.o .text 0x148 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800ED694_to_800ED698.s.o asm/us/main_800ED694_to_800ED698.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800ED694_to_800ED698.s.o .text 0x4 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800EF770_to_800EFB30.s.o asm/us/main_800EF770_to_800EFB30.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800EF770_to_800EFB30.s.o .text 0x3c0 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800EFC68_to_800EFC70.s.o asm/us/main_800EFC68_to_800EFC70.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800EFC68_to_800EFC70.s.o .text 0x8 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800F1278_to_800F1770.s.o asm/us/main_800F1278_to_800F1770.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800F1278_to_800F1770.s.o .text 0x4f8 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800F17AC_to_800F17B0.s.o asm/us/main_800F17AC_to_800F17B0.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800F17AC_to_800F17B0.s.o .text 0x4 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800F1900_to_800F1B30.s.o asm/us/main_800F1900_to_800F1B30.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800F1900_to_800F1B30.s.o .text 0x230 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800F2184_to_800F2288.s.o asm/us/main_800F2184_to_800F2288.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800F2184_to_800F2288.s.o .text 0x104 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800F2BB8_to_800F2BC0.s.o asm/us/main_800F2BB8_to_800F2BC0.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800F2BB8_to_800F2BC0.s.o .text 0x8 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800F3208_to_800F32EC.s.o asm/us/main_800F3208_to_800F32EC.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800F3208_to_800F32EC.s.o .text 0xe4 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800F3B7C_to_800F3B80.s.o asm/us/main_800F3B7C_to_800F3B80.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800F3B7C_to_800F3B80.s.o .text 0x4 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800F4D74_to_800F4D80.s.o asm/us/main_800F4D74_to_800F4D80.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800F4D74_to_800F4D80.s.o .text 0xc --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800F5264_to_800F5270.s.o asm/us/main_800F5264_to_800F5270.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800F5264_to_800F5270.s.o .text 0xc --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800F6648_to_800F6650.s.o asm/us/main_800F6648_to_800F6650.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800F6648_to_800F6650.s.o .text 0x8 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800F67F0_to_800F6C70.s.o asm/us/main_800F67F0_to_800F6C70.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800F67F0_to_800F6C70.s.o .text 0x480 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800F7648_to_800F7650.s.o asm/us/main_800F7648_to_800F7650.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800F7648_to_800F7650.s.o .text 0x8 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800F7C24_to_800F7C30.s.o asm/us/main_800F7C24_to_800F7C30.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800F7C24_to_800F7C30.s.o .text 0xc --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800F7EB8_to_800F7EC0.s.o asm/us/main_800F7EB8_to_800F7EC0.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800F7EB8_to_800F7EC0.s.o .text 0x8 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800F809C_to_800F80A0.s.o asm/us/main_800F809C_to_800F80A0.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800F809C_to_800F80A0.s.o .text 0x4 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800F83B8_to_800F83C0.s.o asm/us/main_800F83B8_to_800F83C0.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800F83B8_to_800F83C0.s.o .text 0x8 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_800F865C_to_800F8660.s.o asm/us/main_800F865C_to_800F8660.s
python3 tools/trim_elf32_section.py \
    build/us/asm/us/main_800F865C_to_800F8660.s.o .text 0x4 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_801029F0_to_80103160.s.o asm/us/main_801029F0_to_80103160.s
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_80103190_to_801037B0.s.o asm/us/main_80103190_to_801037B0.s
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_801039B0_to_80104EC0.s.o asm/us/main_801039B0_to_80104EC0.s
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_80104FA0_to_801058B0.s.o asm/us/main_80104FA0_to_801058B0.s
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_80105A60_to_80105A70.s.o asm/us/main_80105A60_to_80105A70.s
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_80105B10_to_80105F20.s.o asm/us/main_80105B10_to_80105F20.s
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_80106070_to_801068F0.s.o asm/us/main_80106070_to_801068F0.s
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_80106EE0_to_80107A30.s.o asm/us/main_80106EE0_to_80107A30.s
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_80107D60_to_80108530.s.o asm/us/main_80107D60_to_80108530.s
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_80109030_to_80109090.s.o asm/us/main_80109030_to_80109090.s
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_80109490_to_8010A9A0.s.o asm/us/main_80109490_to_8010A9A0.s
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_8010CFA0_to_8010D660.s.o asm/us/main_8010CFA0_to_8010D660.s
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_8010D740_to_8010F3E0.s.o asm/us/main_8010D740_to_8010F3E0.s
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_8010F5F0_to_8010F6A0.s.o asm/us/main_8010F5F0_to_8010F6A0.s
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_8010F6D0_to_8010FE90.s.o asm/us/main_8010F6D0_to_8010FE90.s
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_801100E0_to_801103D0.s.o asm/us/main_801100E0_to_801103D0.s
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_80110400_to_80110490.s.o asm/us/main_80110400_to_80110490.s
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_801104C0_to_80110540.s.o asm/us/main_801104C0_to_80110540.s
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_80110550_to_801106B0.s.o asm/us/main_80110550_to_801106B0.s
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_80110760_to_801118C0.s.o asm/us/main_80110760_to_801118C0.s
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/main_after_801118C0.s.o asm/us/main_after_801118C0.s

fi

# Assemble the generated segment set rather than maintaining a second,
# hand-written copy of every split in splat.yaml.
while IFS= read -r -d '' asm_source; do
    asm_relative="${asm_source#asm/us/}"
    asm_name="$(basename "$asm_relative" .s)"
    asm_object="build/us/asm/us/${asm_relative}.o"
    mkdir -p "$(dirname "$asm_object")"
    "${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
        -o "$asm_object" "$asm_source"
    if [[ "$asm_name" =~ ^(main|data)_([0-9A-Fa-f]{8})_to_([0-9A-Fa-f]{8})$ ]]; then
        range_start=$((16#${BASH_REMATCH[2]}))
        range_end=$((16#${BASH_REMATCH[3]}))
        python3 tools/trim_elf32_section.py "$asm_object" .text \
            "$((range_end - range_start))" --alignment 4
    elif [[ "$asm_name" =~ _textbin$ ]]; then
        textbin_size="$(wc -c < "assets/extracted/us/${asm_name}.textbin.bin")"
        python3 tools/trim_elf32_section.py "$asm_object" .text \
            "$textbin_size" --alignment 4
    fi
done < <(find asm/us -path 'asm/us/nonmatchings' -prune -o \
    -type f -name '*.s' -print0)

tools/bootstrap_ido.sh
tools/bootstrap_kmc_gcc.sh
tools/bootstrap_armips.sh
tools/bootstrap_f3dex2.sh
mkdir -p build/us/src/code
# Mirror the organized source tree before any compiler or assembler writes a
# nested output. This keeps build paths isomorphic to source paths.
while IFS= read -r source_dir; do
    mkdir -p "build/us/${source_dir}"
done < <(find src/code -type d -print)
mkdir -p build/us/src/libmus build/us/src/n_audio
mkdir -p build/us/rsp

# Rebuild the standard boot microcode and this title's exact F3DEX FIFO 2.07
# instruction image from source. They are RSP programs stored inside the loaded
# main image, so the CPU linker carries them as initialized data.
.toolchain/armips/armips \
    -strequ CODE_FILE build/us/rsp/rspboot.bin rsp/rspboot.s
.toolchain/armips/armips \
    -strequ CODE_FILE build/us/rsp/n_aspMain.text.bin rsp/n_aspMain.s
make -s -C .toolchain/f3dex2 \
    ARMIPS="$root_dir/.toolchain/armips/armips" \
    BUILD_DIR="$root_dir/build/us/rsp/f3dex2" F3DEX2_2.07
echo "4cef7741852f0e20007636ef194545d6  build/us/rsp/rspboot.bin" \
    | md5sum --check --status
echo "1523b8e38a9eae698b48909a0c0c0279  build/us/rsp/f3dex2/F3DEX2_2.07/F3DEX2_2.07.code" \
    | md5sum --check --status
echo "9a2c951186b958b5dae6abf3deb48884  build/us/rsp/n_aspMain.text.bin" \
    | md5sum --check --status
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 \
    -o build/us/src/code/runtime/800F8DB0_rsp_microcode_text.c.o src/code/runtime/800F8DB0_rsp_microcode_text.s
python3 tools/trim_elf32_section.py \
    build/us/src/code/runtime/800F8DB0_rsp_microcode_text.c.o .data 0x20C0 --alignment 4

# Initialized-only gameplay units use the retail KMC pipeline too. Keep them in
# one manifest-like loop so adding recovered data does not duplicate build logic.
while read -r unit data_size; do
    case "$unit" in
        libmus/*|n_audio/*)
            source_path="src/${unit}.c"
            output_base="build/us/src/${unit}"
            ;;
        *)
            source_path="src/code/${unit}.c"
            output_base="build/us/src/code/${unit}"
            ;;
    esac
    .toolchain/kmc-gcc-2.7.2/gcc -B.toolchain/kmc-gcc-2.7.2/ -S \
        -O2 -G0 -mips3 -mgp32 -mfp32 -Iinclude -Isrc/code/include \
        -o "${output_base}.raw.s" "$source_path"
    python3 tools/normalize_kmc_gcc_asm.py \
        "${output_base}.raw.s" "${output_base}.s"
    .toolchain/kmc-gcc-2.7.2/as -mips3 -G0 \
        -o "${output_base}.c.o" "${output_base}.s"
    python3 tools/trim_elf32_section.py \
        "${output_base}.c.o" .data "$data_size" --alignment 4
done <<'EOF'
math/80114870_angle_sine_table 0x410
gameplay/80114520_render_state_presets 0x150
render/80114670_renderer_global_tables 0x90
runtime/80114710_resource_bank_table 0xD0
frontend/80114808_controller_pak_identity 0x58
math/80114C80_random_dispatch_tables 0x1B0
effects/80114E30_effect_axis_geometry 0x64
effects/80114E94_effect_event_table 0x1C
effects/80114EB0_effect_color_presets 0x60
effects/80114F10_effect_definition_bank 0x1670
effects/80116580_effect_runtime_tables 0x190
render/80116710_display_state_patches 0x110
frontend/80116820_hud_runtime_defaults 0x40
gameplay/80116860_image_asset_descriptors 0x1570
frontend/80117DD0_frontend_runtime_defaults 0x1E4
gameplay/80118054_main_menu_scene_graph 0x4F8
frontend/80121A00_cheat_code_data 0x2c0
gameplay/80121CC0_gameplay_camera_data 0x6C4
gameplay/80122384_gameplay_definition_data 0x1ABC
frontend/80123E40_campaign_mission_text 0xCF0
frontend/80124B30_campaign_mission_config 0x990
frontend/801254C0_mission_selection_data 0xC0
weapons/80125580_projectile_particle_data 0xD8
weapons/80125658_projectile_billboard_geometry 0x320
effects/80125978_effect_billboard_geometry 0x128
world/80125AA0_hazard_animation_data 0x190
render/80125C30_model_motion_render_data 0x270
render/80125EA0_model_variant_runtime_data 0x20
gameplay/80125EC0_f3dex2_fifo_data 0x420
libmus/audio_runtime_data 0x5B0
frontend/8011F298_controller_pak_text 0x3e4
frontend/8011FC4C_title_legal_text 0x120
frontend/80120000_pal_warning_text 0x50
frontend/8012012C_results_text 0xb4
frontend/801201E0_results_layout_data 0x15DC
frontend/801217BC_ending_text 0xa4
frontend/80121860_ending_results_layout 0x1a0
frontend/80117FB4_menu_help_text 0xa0
frontend/80119338_code_entry_help_text 0x8c
player/8011D9E8_team_setup_text 0x7c
frontend/8011FA90_controller_required_text 0x50
frontend/8011A3F0_controls_help_text 0xf0
frontend/8011A8D4_controller_binding_text 0xc4
frontend/8011A998_controller_binding_layout_data 0x940
frontend/8011B2D8_campaign_map_help_text 0x40
frontend/8011B318_hud_list_layout_data 0xEF0
gameplay/8011854C_main_menu_text 0x98
frontend/80118E6C_options_menu_text 0x70
frontend/80119C2C_code_entry_text 0xa4
frontend/8011C208_gang_selection_help_text 0x4c
frontend/8011C254_controller_layout_data 0x1050
player/8011D2A4_team_alignment_help_text 0x40
frontend/8011DDE8_mission_result_text 0x10
frontend/8011E578_pause_menu_text 0x1c
frontend/8011EA14_rumble_help_text 0x2c
vehicles/8011EB90_tank_selection_text 0x24
frontend/80118EDC_options_menu_layout 0x45C
frontend/8011A4E0_controls_menu_layout 0x3F4
player/8011DA64_team_setup_layout 0x384
frontend/8011EA40_rumble_menu_layout 0x150
frontend/8011F67C_controller_pak_layout 0x414
frontend/8011FAE0_controller_required_layout 0x16C
frontend/8011FD6C_title_legal_layout 0x294
frontend/80120050_pal_warning_layout 0xDC
frontend/80114700_hud_flip_state 0x10
audio/801147E0_audio_scheduler_data 0x20
runtime/80114800_game_state_counters 0x8
gameplay/80114860_frame_buffer_state 0x10
gameplay/801185E4_main_menu_layout_tail 0x888
frontend/801193C4_code_entry_help_layout 0x868
frontend/80119CD0_code_entry_layout 0x720
player/8011D2E4_team_alignment_layout 0x704
frontend/8011DDF8_race_hud_state 0xA4
frontend/8011DE9C_race_hud_layout_data 0x6DC
frontend/8011E594_pause_menu_layout 0x480
frontend/8011EBB4_race_widget_layout 0x640
frontend/8011F1F4_race_state_vars 0x3C
frontend/8011F230_controller_menu_state_data 0x68
runtime/801144A0_memory_region_table 0x48
render/801144F0_graphics_task_state 0xC
render/80114500_display_state_ptr 0x4
render/80114510_gfx_pool_state 0x4
EOF
# libmus was assembled with reorder enabled, so preserve KMC's raw assembly and
# its assembler-scheduled delay slots instead of applying the gameplay normalizer.
while read -r unit text_size; do
    .toolchain/kmc-gcc-2.7.2/gcc -B.toolchain/kmc-gcc-2.7.2/ -S \
        -O2 -G0 -mips3 -mgp32 -mfp32 -Iinclude -Isrc/code/include -Isrc/libmus \
        -o "build/us/src/libmus/${unit}.raw.s" \
        "src/libmus/${unit}.c"
    .toolchain/kmc-gcc-2.7.2/as -mips3 -G0 \
        -o "build/us/src/libmus/${unit}.c.o" \
        "build/us/src/libmus/${unit}.raw.s"
    if [[ "$unit" == 800FAE70_fenvelope ||
          "$unit" == 800FC864_player_voice ||
          "$unit" == 800FCBB0_player_effects ||
          "$unit" == 800FD10C_player_bank_math ]]; then
        "${tool_prefix}objcopy" --set-section-flags \
            .rodata=alloc,load,readonly,data \
            "build/us/src/libmus/${unit}.c.o"
    fi
    python3 tools/trim_elf32_section.py \
        "build/us/src/libmus/${unit}.c.o" .text "$text_size" --alignment 4
    case "$unit" in
        800FAE70_fenvelope)
            python3 tools/trim_elf32_section.py \
                "build/us/src/libmus/${unit}.c.o" .rodata 0x8 --alignment 8 ;;
        800FBF94_player_main)
            python3 tools/trim_elf32_section.py \
                "build/us/src/libmus/${unit}.c.o" .rodata 0x8 --alignment 8 ;;
        800FC864_player_voice)
            python3 tools/trim_elf32_section.py \
                "build/us/src/libmus/${unit}.c.o" .rodata 0x10 --alignment 4 ;;
        800FCBB0_player_effects)
            python3 tools/trim_elf32_section.py \
                "build/us/src/libmus/${unit}.c.o" .rodata 0x8 --alignment 4 ;;
        800FD10C_player_bank_math)
            python3 tools/trim_elf32_section.py \
                "build/us/src/libmus/${unit}.c.o" .rodata 0x70 --alignment 4 ;;
        800FD2A0_remap_ptr_bank)
            python3 tools/trim_elf32_section.py \
                "build/us/src/libmus/${unit}.c.o" .rodata 0x8 --alignment 8 ;;
        800FDD20_player_commands)
            python3 tools/trim_elf32_section.py \
                "build/us/src/libmus/${unit}.c.o" .rodata 0x40 --alignment 4 ;;
        800FE710_n_syn_custom_fx)
            python3 tools/trim_elf32_section.py \
                "build/us/src/libmus/${unit}.c.o" .rodata 0x10 --alignment 4 ;;
    esac
done <<'LIBMUS_UNITS'
800FAE70_fenvelope 0x14C
800FAFBC_mus_initialize 0x288
800FB244_master_volume 0x2C
800FB270_start_song 0x30
800FB2A0_start_song_marker 0x250
func_800FB4F0 0x80
800FB570_player_api 0x264
800FB7D4_player_api_handles 0x5AC
800FBD80_player_api_misc_pre 0x48
func_800FBDC8 0x64
800FBE2C_player_api_misc_post 0x168
800FBF94_player_main 0x8D0
800FC864_player_voice 0x34C
800FCBB0_player_effects 0x55C
800FD10C_player_bank_math 0x194
800FD2A0_remap_ptr_bank 0x198
800FD438_random_range 0x94
func_800FD4CC 0x13C
800FD608_player_start_pre 0x6C4
800FDCCC_channel_flags 0x54
800FDD20_player_commands 0x9F0
800FE710_n_syn_custom_fx 0x850
800FEF60_mus_dma_sched 0x600
800FF560_mus_audio_thread 0x2C0
800FF820_mus_frame_size 0x130
800FF950_mus_heap_mem 0x140
800FFA90_n_auxbus_pull 0xA0
LIBMUS_UNITS
mkdir -p build/us/src/n_audio
# The customized n_audio library uses the same raw KMC assembler scheduling as
# libmus. Keep this separate from gameplay's normalized assembly pipeline.
while read -r unit text_size; do
    .toolchain/kmc-gcc-2.7.2/gcc -B.toolchain/kmc-gcc-2.7.2/ -S \
        -O2 -G0 -mips3 -mgp32 -mfp32 -Iinclude -Isrc/code/include -Isrc/n_audio \
        -o "build/us/src/n_audio/${unit}.raw.s" \
        "src/n_audio/${unit}.c"
    .toolchain/kmc-gcc-2.7.2/as -mips3 -G0 \
        -o "build/us/src/n_audio/${unit}.c.o" \
        "build/us/src/n_audio/${unit}.raw.s"
    python3 tools/trim_elf32_section.py \
        "build/us/src/n_audio/${unit}.c.o" .text "$text_size" --alignment 4
    case "$unit" in
        800FFB30_n_drvrnew)
            python3 tools/trim_elf32_section.py \
                "build/us/src/n_audio/${unit}.c.o" .rodata 0x30 --alignment 16 ;;
        80100050_n_env)
            python3 tools/trim_elf32_section.py \
                "build/us/src/n_audio/${unit}.c.o" .rodata 0x70 --alignment 16 ;;
        80101140_n_resample)
            python3 tools/trim_elf32_section.py \
                "build/us/src/n_audio/${unit}.c.o" .rodata 0x10 --alignment 16 ;;
        80101320_n_reverb)
            python3 tools/trim_elf32_section.py \
                "build/us/src/n_audio/${unit}.c.o" .rodata 0x40 --alignment 16
            python3 tools/trim_elf32_section.py \
                "build/us/src/n_audio/${unit}.c.o" .data 0x10 --alignment 4 ;;
        80101D10_n_alinit)
            python3 tools/trim_elf32_section.py \
                "build/us/src/n_audio/${unit}.c.o" .data 0x10 --alignment 4 ;;
        80102350_n_synthesizer)
            python3 tools/trim_elf32_section.py \
                "build/us/src/n_audio/${unit}.c.o" .rodata 0x20 --alignment 16 ;;
    esac
done <<'N_AUDIO_UNITS'
800FFB30_n_drvrnew 0x520
80100050_n_env 0x9D0
80100A20_n_load 0x720
80101140_n_resample 0x1E0
80101320_n_reverb 0x9F0
80101D10_n_alinit 0x80
80101D90_n_synaddplayer 0x50
80101DE0_n_synallocvoice 0x1E0
80101FC0_n_syndelete 0x10
80101FD0_n_synsetfxmix 0xA0
80102070_n_synsetpan 0x90
80102100_n_synsetpitch 0x90
80102190_n_synsetvol 0xB0
80102240_n_synstartvoice 0x90
801022D0_n_synstopvoice 0x80
80102350_n_synthesizer 0x560
801028B0_n_save 0x50
80102900_n_mainbus 0x80
80102980_n_synallocfx 0x50
N_AUDIO_UNITS
.toolchain/ido5.3/cc -c -O2 -g3 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/code/unknown/8007A710.c.o src/code/unknown/8007A710.c
.toolchain/ido5.3/cc -c -O2 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/code/unknown/8007ADB0.c.o src/code/unknown/8007ADB0.c
.toolchain/ido5.3/cc -c -O2 -g3 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/code/unknown/8007B020.c.o src/code/unknown/8007B020.c
.toolchain/kmc-gcc-2.7.2/gcc -B.toolchain/kmc-gcc-2.7.2/ -S \
    -O2 -G0 -mips3 -mgp32 -mfp32 -Iinclude -Isrc/code/include \
    -o build/us/src/code/render/8007B030_gfx_pool.raw.s src/code/render/8007B030_gfx_pool.c
python3 tools/normalize_kmc_gcc_asm.py \
    build/us/src/code/render/8007B030_gfx_pool.raw.s build/us/src/code/render/8007B030_gfx_pool.s
.toolchain/kmc-gcc-2.7.2/as -mips3 -G0 \
    -o build/us/src/code/render/8007B030_gfx_pool.c.o build/us/src/code/render/8007B030_gfx_pool.s
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/8007B030_gfx_pool.c.o .text 0xb4 --alignment 4
.toolchain/kmc-gcc-2.7.2/gcc -B.toolchain/kmc-gcc-2.7.2/ -S \
    -O2 -G0 -mips3 -mgp32 -mfp32 -Iinclude -Isrc/code/include \
    -o build/us/src/code/gameplay/8007B1F0_render_queue.raw.s src/code/gameplay/8007B1F0_render_queue.c
python3 tools/normalize_kmc_gcc_asm.py \
    build/us/src/code/gameplay/8007B1F0_render_queue.raw.s build/us/src/code/gameplay/8007B1F0_render_queue.s
.toolchain/kmc-gcc-2.7.2/as -mips3 -G0 \
    -o build/us/src/code/gameplay/8007B1F0_render_queue.c.o build/us/src/code/gameplay/8007B1F0_render_queue.s
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/8007B1F0_render_queue.c.o .text 0x46c --alignment 4
for unit in debug/80077C40_early_hw debug/80077DA4_early_memory_read debug/80078048_early_memory_write debug/80078200_early_remote_copy \
            runtime/80082C1C_state_activate path/80082D98_path_sequence_init unknown/80082F1C unknown/80082F98 \
            debug/80078908_early_commands debug/80078C68_early_command_status render/8007A720_display_slot gameplay/8007D500_mapped_record render/8007AC34_display_buffer \
            render/8007AD94_display_buffer_select frontend/8007ADC0_controller_state gameplay/8009D144_mode_range math/8009D6DC_angle_subtract \
            math/8009D72C_angle_between math/8009D81C_angle_distance math/8009D578_angle_fold math/8009D850_angle_direction \
            gameplay/8007B65C_render_submit runtime/8007BCF0_asset_load gameplay/8007BDFC_video_mode gameplay/8007BEF0_texture_tile gameplay/8007D470_small_state \
            gameplay/8007D558_small_state_copy collision/8007D694_collision_noop runtime/8007D710_state_noop runtime/8007D720_state_modes \
            collision/8007E1FC_collision_fields entities/8007E778_object_query gameplay/80082D60_pair_queue \
            entities/80081FD8_object_defaults gameplay/80082B40_mode_owner gameplay/80082BD4_mode_transition entities/80082FE0_object_disable \
            entities/80083FCC_object_predicates entities/80084C50_object_direction entities/800859A8_object_action render/8009277C_matrix_scale_curve \
            unknown/80085148 unknown/8008518C unknown/80085250 unknown/8008543C world/800857F0_zone_spawn_query \
            unknown/80094880 unknown/80094F40 unknown/80094F78 unknown/80094FBC \
            unknown/80095B50 unknown/80095B68 unknown/80095B90 unknown/80095BE4 unknown/80095C50 \
            unknown/80095E7C unknown/80096250 unknown/80096294 unknown/8009660C unknown/800966D4 \
            vehicles/80090C4C_tank_contact_scan unknown/800967F0 unknown/80096810 \
            gameplay/80096A54_font_glyph_draw gameplay/80096E14_font_hex_draw unknown/800973E0 \
            unknown/80097508 unknown/80097530 unknown/80097560 \
            unknown/80097660 unknown/800976AC unknown/80097794 unknown/800977DC \
            unknown/80097844 unknown/8009790C unknown/800979A0 unknown/800979F4 \
            unknown/80097A6C unknown/80097B20 unknown/80097B44 unknown/80097B68 \
            unknown/80097BA4 unknown/80097BC4 unknown/80097C1C unknown/80097C84 \
            unknown/80097CB8 unknown/80097CC8 audio/80097D14_music_stream_queue \
            unknown/80097DF8 unknown/80097EE4 unknown/8009813C unknown/80098180 unknown/80098190 \
            unknown/800981E0 unknown/80098250 unknown/80098334 unknown/8009836C \
            unknown/80098430 unknown/80098534 unknown/800985A0 \
            unknown/80098AFC unknown/80098B2C unknown/80098B40 unknown/80098B58 unknown/80098BC8 \
            unknown/80098BF8 unknown/80098CC8 \
            unknown/80098F24 unknown/80098FBC unknown/80099028 unknown/80099080 \
            unknown/800992E0 unknown/800993B0 unknown/800996C4 unknown/80099758 \
            unknown/80099784 unknown/80099830 unknown/80099854 unknown/800998A8 \
            unknown/80099F74 unknown/8009A650 unknown/8009A6F0 unknown/8009AD7C \
            unknown/800991CC \
            unknown/80099464 unknown/800998E8 unknown/80099FE8 player/8009A4C8_player_order_shuffle unknown/8009A6F8 \
            unknown/8009AE38 player/8009B35C_player_state_modes unknown/8009B434 unknown/8009B62C unknown/8009C098 gameplay/8009C284_session_queries gameplay/8009C31C_progress_level_advance \
            math/8009D914_random_integer gameplay/8009DA34_vector2 gameplay/8009DB0C_vector2_scale gameplay/8009E044_vector2_motion runtime/8009EEA0_game_queue \
            render/8009EEE0_matrix_basic render/8009F064_matrix_state \
            render/8009F768_matrix_transform gameplay/8009FF1C_vector2_rotate render/8009F1F4_matrix_vector render/8009F4B4_matrix_multiply gameplay/800A0750_lzari_decode \
            runtime/800A1280_scheduler_context runtime/800A134C_scheduler_state runtime/800A179C_scheduler_events \
            runtime/800A1A28_scheduler_queue runtime/800A2DFC_scheduler_misc entities/800A2B74_object_range entities/800A4098_object_timing entities/800A6ABC_object_setters \
            entities/800A7290_object_init unknown/800A16F8 unknown/800A1BE0 runtime/800A2154_task_message_broadcast \
            unknown/800B044C unknown/800B04E0 unknown/800B05F4 unknown/800B06E0 collision/800B0F4C_grid_node_remove \
            unknown/800B109C unknown/800B14A8 unknown/800B1610 unknown/800B1668 unknown/800B1DA8 unknown/800B2364 \
            unknown/800B2890 unknown/800B3368 unknown/800B3504 collision/800B4684_collision_query unknown/800B5A10 \
            vehicles/800B5B8C_mover_reflect unknown/800B5D1C unknown/800B5DA8 \
            vehicles/800B5F70_mover_collision_response unknown/800B61B8 \
            collision/800B739C_contact_side_test math/800B8310_vector_angle_from_xy unknown/800B9E24 unknown/800B9EB4 \
            unknown/800B9FD4 world/800BA330_world_resource_aggregate world/800BA6C0_world_loader \
            world/800BB2A0_world_bundle_resource_aggregate render/800BB53C_common_model_loader unknown/800BBDC0 \
            unknown/800BD93C unknown/800BDAF8 unknown/800BEE0C unknown/800BF798 \
            unknown/800AA8A8 unknown/800AAAE0 unknown/800AAC14 unknown/800AB4DC unknown/800AC0F4 unknown/800ACE70 unknown/800ACEB4 \
            unknown/800ACEFC unknown/800AD14C unknown/800AE710 unknown/800AF364 unknown/800B0268 unknown/800B03F4 \
            unknown/800A8E3C unknown/800A9080 unknown/800A977C unknown/800A98B8 unknown/800A9B64 \
            unknown/800A9C24 unknown/800A9CCC gameplay/800A9D78_light_display_list_build unknown/800A9F10 \
            unknown/800A2E5C unknown/800A2FBC unknown/800A3758 \
            effects/800A40CC_effect_sprite_key_draw effects/800A42C8_effect_sprite_ring_draw unknown/800A477C \
            unknown/800A5BD8 unknown/800A61A0 gameplay/800A6320_camera_collision_resolve unknown/800A6588 \
            gameplay/800A6C20_spotter_update gameplay/800A6FD0_spotter_frame_setup unknown/800A702C \
            player/800A7664_player_perspective_update unknown/800A7794 unknown/800A8690 unknown/800A87BC unknown/800A89B0 \
            gameplay/800A8A78_camera_view_select gameplay/800A8B38_camera_mode_update entities/800A8B14_object_reset entities/800A9054_object_flags entities/800A974C_object_limit \
            unknown/800B87A0 collision/800B8870_grid_node_height collision/800B93A4_grid_height_query render/800B9AB0_model_player_color math/8009D5B4_angle_table_lookup math/800B02D4_bounds_pair \
            entities/800A9BF0_object_table_color entities/800A9D50_object_table_reset entities/800AA598_object_table_lookup \
            gameplay/800B0444_gameplay_stub gameplay/800B5F30_turn_adjust frontend/800BFD40_hud_state frontend/800BF204_hud_tree_update frontend/800C0800_hud_modes frontend/800C0A64_hud_stub \
            frontend/800BFEA0_race_assets_init frontend/800C7594_race_mode_query frontend/800C8350_race_hud_layout frontend/800C877C_race_marker_project frontend/800C7C10_race_map_draw frontend/800C74AC_race_state_init frontend/800CD57C_controller_menu_state \
            frontend/800C0D00_hud_volume_adjust frontend/800C30B4_hud_controls_page frontend/800C65B4_hud_page_next frontend/800CBE40_controller_save_slots \
            frontend/800CD970_results_menu_callbacks frontend/800CE610_results_panel_setup frontend/800CE9A0_results_split_setup entities/800D0858_spawn_color_lookup \
            frontend/800C12B4_hud_key_nav frontend/800C16B0_hud_slots_layout frontend/800C1938_controls_config frontend/800C1F08_controls_preset frontend/800C2284_hud_binding_select \
            frontend/800BF000_hud_tree_remove frontend/800BF484_hud_tree_draw frontend/800BF80C_hud_frame frontend/800C041C_hud_mode_table frontend/800C0608_hud_mode_cycle_full frontend/800C08E0_hud_exit_dispatch \
            frontend/800C1484_hud_menu_open frontend/800C2528_hud_option_select frontend/800C2924_hud_list_select_full frontend/800C4BB4_hud_player_page \
            frontend/800CAA48_race_popup_setup frontend/800CFA84_results_bar_step frontend/800CFD18_results_rank_label \
            frontend/800CDBE0_results_time_text frontend/800D0070_cheat_codes \
            frontend/800C1124_hud_secondary frontend/800C1190_hud_primary_modes frontend/800C1468_hud_transition gameplay/800C17C8_registry_lookup \
            frontend/800C247C_hud_ready frontend/800C24A4_hud_clear frontend/800C27EC_hud_navigation player/800B06A8_player_color world/800BA1BC_world_loader_ref_walkers script/800BD880_entry_scan \
            script/800BD8B8_entry_flags frontend/800C1138_hud_callbacks frontend/800C1578_hud_panel_callback frontend/800C24FC_hud_list_callback \
            frontend/800C03F0_hud_root_callback frontend/800C0C18_hud_layout frontend/800C15A4_hud_list_trigger \
            frontend/800C15B8_hud_entry_values frontend/800C1638_hud_list_reset frontend/800C290C_hud_selection_apply \
            frontend/800C30A0_hud_primary_trigger render/800B99C0_display_registry render/800B9A4C_display_color render/800B9C68_display_commands \
            frontend/800C0850_menu_state frontend/800C1094_menu_toggle frontend/800C1420_menu_countdown gameplay/800B9D4C_table_lookup \
            frontend/800C420C_hud_row_preset \
            frontend/800C425C_hud_row_defaults \
            frontend/800C42A0_hud_exit_request \
            frontend/800C42E4_hud_list_refresh \
            frontend/800C434C_hud_list_focus_cycle \
            frontend/800C47D4_hud_list_open \
            frontend/800C485C_hud_list_close \
            frontend/800C48C4_hud_alt_exit_request \
            frontend/800C4ABC_hud_page_select \
            frontend/800C4E24_hud_page_focus_cycle \
            runtime/800C4F50_game_mode8_toggled \
            frontend/800C6544_hud_page_focus \
            frontend/800C674C_hud_page_exit_request \
            frontend/800C6790_hud_page_show \
            frontend/800C67BC_hud_page_open \
            frontend/800C6844_hud_page_close \
            frontend/800C6920_race_assets_load \
            frontend/800C6D68_race_hud_init \
            frontend/800C726C_race_result_setup \
            frontend/800C73A8_race_object_timestamps \
            frontend/800C7514_race_state_reset \
            frontend/800C8238_race_event_push \
            frontend/800C8EDC_race_slot_clear \
            frontend/800C9130_race_player_panel \
            frontend/800C95A0_race_player_message \
            frontend/800C962C_race_player_pair_set \
            frontend/800C98D8_race_display_value_set \
            frontend/800CA1A8_race_player_reset frontend/800C98E8_race_bar_update \
            frontend/800CA3F0_race_timer_queries \
            frontend/800CAA0C_race_popup_show \
            frontend/800CAB44_race_flag_queries \
            frontend/800CABC0_race_player_widget \
            frontend/800CAD9C_race_widget_values \
            frontend/800CAED0_race_widget_clear \
            frontend/800CAFA8_race_widget_reset \
            frontend/800CB0C0_race_widget_flag_set \
            frontend/800CB110_results_assets_load \
            frontend/800CB1E4_controls_button_index_map \
            frontend/800CD85C_results_record_write \
            frontend/800CDD70_results_time_format \
            frontend/800CE188_results_time_compare \
            frontend/800CE814_results_screen_setup \
            frontend/800CF0CC_results_continue \
            frontend/800CF198_results_return \
            frontend/800CF218_results_option_codes \
            frontend/800CF3E0_results_ready_flags_a \
            frontend/800CF58C_results_ready_flags_b \
            frontend/800CF738_results_ready_flags_c \
            frontend/800CFA50_results_status_flags \
            frontend/800CFDD0_results_assets_reload \
            runtime/800D0058_game_state_clear \
            entities/800D0814_spawn_ctl_index \
            entities/800D0960_spawn_ctl_alloc \
            audio/800D250C_audio_listener_update \
            frontend/800D4D00_race_buffers_alloc \
            player/800D6E40_player_attach_effect_create \
            player/800D7CF4_player_attach_effect_matrix \
            player/800D7D60_player_attach_effect_matrix_cb \
            entities/800D8050_actor_collision_free \
            entities/800D8674_turret_message_handlers \
            gameplay/800D8F28_single_player_check \
            gameplay/800D91C0_trigger_zone_query \
            gameplay/800D97EC_minimap_layer_build \
            render/800D9A88_model_texture_find \
            render/800D9C38_model_bounds_center \
            effects/800DA340_debris_piece_draw \
            effects/800DA4F0_debris_burst_spawn \
            effects/800DA65C_debris_burst_spawn_tinted \
            effects/800DA984_debris_scatter_spawn \
            weapons/800DC214_projectile_model_draw \
            weapons/800DC3A8_projectile_model_create \
            weapons/800DC634_projectile_model_matrix \
            weapons/800DC6EC_projectile_model_matrix_cb \
            weapons/800DC804_projectile_trail_draw \
            weapons/800DD0D8_projectile_launch_delayed \
            weapons/800DD1C0_projectile_launch_delayed_tick \
            render/800DD290_model_mesh_partition \
            world/800DD3A0_structure_create \
            entities/800DE4DC_spawner_target_query \
            entities/800DE930_unit_spawner_create \
            entities/800DEAC0_unit_spawner_update \
            world/800DF33C_prop_multiplayer_filter \
            gameplay/800DF7A0_level_prop_points_find \
            world/800E1540_foliage_prop_create \
            world/800E1980_foliage_prop_handlers \
            entities/800E2018_turret_destroy \
            entities/800E21A0_turret_draw_create \
            entities/800E26A8_turret_message_handler \
            entities/800E2D74_turret_line_of_sight \
            entities/800E3404_wreck_timer_duration \
            world/800E462C_flag_capture_attempt \
            entities/800E4ECC_actor_kind16_link_clear \
            audio/800E5164_sound_emitter_delayed_spawn \
            audio/800E562C_ambient_sound_stop_first \
            world/800E56D0_bridge_create_handlers \
            effects/800E61E8_lightning_arc_update \
            world/800E64F0_crate_model_randomize \
            world/800E6540_crate_actor_attach \
            gameplay/800E759C_pending_list_flush \
            world/800E7968_powerup_flag_players \
            world/800E7DF8_powerup_count_refresh \
            gameplay/800E7EE0_pickup_actor_count \
            runtime/800E804C_game_mode_has_pickups \
            gameplay/800E8318_slist_remove_count \
            frontend/800E92F0_mission_select_init \
            frontend/800E9424_mission_entry_query \
            frontend/800E9990_mission_actor_spawn \
            frontend/800E98F8_mission_time_bonus \
            frontend/800E9E4C_mission_event_forward \
            world/800EA964_building_target_query \
            world/800EA9C0_building_destroy_on_hit \
            world/800EAA68_building_damage_apply \
            world/800EAC30_building_create \
            world/800EAE58_building_anim_frame_tick \
            unknown/800EAEB4 \
            world/800EAF6C_building_destroy \
            entities/800EB308_object_handlers \
            effects/800EB720_impact_flash_spawn \
            effects/800EB934_impact_flash_expire \
            player/800EBCA8_player_projectile_launch \
            unknown/800EBF80 \
            frontend/800EC1C0_mission_counter_release \
            unknown/800EC1F8 \
            gameplay/800EC72C_splash_damage_falloff \
            weapons/800EC790_projectile_spawn_typed \
            gameplay/800ED010_shockwave_ring_spawn \
            gameplay/800ED1B0_shockwave_ring_draw \
            world/800ED320_destructible_prop_create \
            world/800ED63C_destructible_anim_frame_tick \
            weapons/800ED730_projectile_target_query \
            world/800ED774_destructible_prop_on_hit \
            world/800ED7BC_destructible_prop_on_hit_alt \
            gameplay/800ED804_message_dispatch \
            world/800EDC00_prop_destroy_slot_release \
            unknown/800EDDCC \
            world/800EE0B0_prop_target_query \
            world/800EE0E8_prop_debris_burst_on_hit \
            world/800EE1B8_prop_debris_burst_on_hit_alt \
            entities/800EE288_entity_message \
            world/800EEADC_barrier_break_open \
            gameplay/800EED90_segment_update \
            effects/800EFBFC_particle_emitter_tail \
            effects/800EFC70_particle_emitter_create \
            effects/800EFE10_particle_pool_init \
            effects/800F0064_particle_emitter_update \
            effects/800F0618_particle_free_list \
            effects/800F0930_particle_node_list \
            render/800F1770_anim_list_register_global \
            world/800F1B30_hazard_actor_spawn \
            world/800F1CC8_hazard_actor_spawn_simple \
            world/800F2184_hazard_trigger \
            entities/800F24F8_object_state_query \
            gameplay/800F265C_mine_message_handlers \
            world/800F2BC0_powerup_pad_create \
            world/800F3098_powerup_pad_draw \
            world/800F3208_prop_handlers \
            world/800F32EC_barrel_handlers \
            gameplay/800F36D0_falling_crate_update \
            gameplay/800F38C0_decal_spawn_draw \
            render/800F3B80_color_interpolate \
            gameplay/800F3D04_mesh_vertex_transform \
            gameplay/800F4FF0_tracer_spawn \
            effects/800F5270_effect_table_reset \
            gameplay/800F5E18_generator_damage_apply \
            gameplay/800F5F10_generator_message_damage \
            gameplay/800F6100_generator_hit_query \
            gameplay/800F6144_generator_splash_damage \
            gameplay/800F6344_generator_damage_tick \
            gameplay/800F64B8_generator_dispatch_bonus \
            effects/800F67C8_effect_expire_100 \
            entities/800F6ED0_wreck_debris_spawn \
            entities/800F708C_wreck_debris_update \
            render/800F7150_anim_colors_set \
            render/800F71FC_anim_list_create \
            unknown/800F7230 \
            render/800F756C_anim_list_reset \
            render/800F757C_anim_list_register \
            gameplay/800F799C_spark_spawn \
            gameplay/800F7BA4_smoke_puff_spawn \
            effects/800F7C30_flicker_prop_create \
            effects/800F7D24_flicker_prop_draw \
            effects/800F7E14_flicker_prop_message \
            effects/800F7E64_flicker_prop_message_cb \
            gameplay/800F7EC0_static_prop_create \
            gameplay/800F7F6C_static_prop_expire \
            gameplay/800F7F84_static_prop_draw \
            render/800F80E8_model_variant_get \
            gameplay/800F67F0_sway_model_draw \
            render/800F8208_model_cache_globals \
            weapons/800F83C0_artillery_emplacement_update \
            weapons/800F85D8_artillery_emplacement_disable \
            weapons/800F85F0_artillery_emplacement_create \
            weapons/800F8660_artillery_projectile_create \
            frontend/800C4F98_hud_slot_icons_update \
            frontend/800C48F0_hud_menu_entries_apply_settings \
            frontend/800C4B24_hud_entry_set_label \
            frontend/800C8F00_race_player_set_vehicle_label \
            frontend/800C9010_race_type_name_lookup \
            frontend/800C924C_race_player_set_layout \
            frontend/800C9680_race_mode_icon_get \
            frontend/800C975C_race_player_set_mode_icon \
            frontend/800CA4A0_race_slot_set_digit \
            frontend/800CB334_controls_bindings_save \
            frontend/800CB934_controls_bindings_load \
            entities/800D0DF8_spawn_effect_by_type \
            script/800D12B0_script_command_decode \
            script/800D3554_seq_event_spawn_tick \
            script/800D4B58_seq_event_start \
            script/800D4DE0_seq_script_load \
            script/800D520C_seq_level_header_load \
            script/800D5508_seq_events_update \
            script/800D3C64_seq_point_track \
            script/800D5E2C_script_particle_update \
            effects/800D9D50_debris_spawn \
            effects/800DA1D8_debris_piece_update \
            effects/800DA7D0_debris_group_spawn \
            weapons/800DAAE0_projectile_spawn \
            weapons/800DB1B0_projectile_segment_spawn \
            gameplay/800DB6F0_track_angle_unit \
            world/800DD75C_structure_hit_dispatch \
            world/800DD82C_structure_debris_spawn \
            world/800DE374_structure_message \
            script/800DF89C_entry_helpers \
            vehicles/8008C5D8_tank_fire_weapon \
            world/800E16D8_foliage_prop_destroy \
            entities/800E1BB0_turret_sweep \
            entities/800E2520_turret_message_handlers \
            entities/800E2F9C_wreck_update \
            entities/800E3FDC_entity_model_draw \
            world/800E48A8_flag_position_query \
            world/800E4DA0_flag_message_dispatch \
            world/800E66A8_crate_particle_attach \
            world/800E6B04_crate_unit \
            world/800E73B0_crate_part_release \
            world/800E7768_crate_burst_spawn \
            world/800E7A10_powerup_flag_messages \
            frontend/800DF3B8_slot_condition_check \
            player/800E18D8_player_message_hit \
            player/800E1A4C_player_dispatch \
            entities/800E44C8_wreck_message_hit \
            frontend/800E8C88_slot_mode_name_get \
            frontend/800E8380_slot_asset_ranges \
            frontend/800E8E34_slot_mode_title_get \
            frontend/800E8F90_slot_mode_subtitle_get \
            frontend/800E9030_slot_mode_description_get \
            frontend/800E918C_slot_mode_value_get \
            render/800E9B50_model_pickup_create \
            render/800E9CAC_model_mode_objective_message \
            render/800EA8F4_model_message_damage_u8 \
            render/800EAA7C_model_turret_dispatch \
            render/800EB4FC_model_shielded_dispatch \
            render/800ED698_model_message_damage_destroy \
            world/800EDF14_prop_message_shatter \
            effects/800EF400_effect_segment_append \
            effects/800EF578_effect_segments_draw \
            effects/800EFB30_effect_message_damage \
            effects/800EFB90_effect_message_damage_guarded \
            frontend/800C402C_hud_player_slots_cycle \
            frontend/800C4594_hud_marker_update \
            frontend/800C5B3C_hud_mode_cycle \
            frontend/800C5D80_hud_panel_layout \
            frontend/800C5FB4_hud_panel_refresh \
            frontend/800C6280_hud_panel_select \
            frontend/800C68AC_hud_value_to_byte \
            frontend/800C7650_race_frame_border_draw \
            frontend/800C7AA0_race_start_check \
            frontend/800C8484_race_timer_update \
            frontend/800C8B74_race_player_icons_draw \
            frontend/800CA2BC_race_lap_times_clamp \
            frontend/800CC2F8_controller_slots_scan \
            frontend/800CC574_controller_menu_input \
            frontend/800CCA6C_controller_queue_push \
            frontend/800CCEC4_controller_slot_find \
            frontend/800CF258_results_kills_tick \
            frontend/800CF32C_results_deaths_tick \
            frontend/800CF41C_results_score_tick \
            frontend/800CF4E4_results_score_finish \
            frontend/800CF5C8_results_bonus_tick \
            frontend/800CF690_results_bonus_finish \
            frontend/800CF7A8_results_time_tick \
            frontend/800CFBD8_results_columns_draw \
            frontend/800D05E0_hud_element_unlink \
            frontend/800D09E0_hud_element_alloc \
            entities/800D0F58_spawn_nearest_type1 \
            entities/800D104C_spawn_nearest_type28 \
            entities/800D1140_spawn_nearest_type31 \
            entities/800D1234_spawn_counters \
            entities/800D1C90_spawn_object_command \
            script/800D25E0_seq_script_tick \
            script/800D2B44_seq_spawn_script_tick \
            script/800D31DC_seq_event_script_tick \
            script/800D404C_seq_spawn_events_update \
            script/800D441C_seq_command_dispatch \
            script/800D53D4_script_event_finish \
            frontend/800D56FC_hud_draw_list \
            script/800D5C80_script_particle_spawn \
            effects/800D67F0_effect_draw \
            effects/800D69E0_effect_code_table \
            effects/800D6B80_effect_code_parse \
            player/800D6EEC_player_menu_update \
            player/800D7544_player_cursor_anim \
            player/800D7638_player_menu_draw \
            effects/800D7DE0_effect_node_spawn \
            entities/800D8088_actor_model_draw \
            entities/800D8380_actor_timer_update \
            entities/800D84DC_actor_message_handler \
            entities/800D8758_turret_state_messages \
            entities/800D88F0_turret_weights_total \
            entities/800D8940_turret_weighted_pick \
            entities/800D89F8_turret_random_slot \
            entities/800D8A80_turret_model_draw \
            entities/800D8C60_turret_spawn_random \
            gameplay/800D8F48_single_spawn_timer_update \
            gameplay/800D92E0_trigger_particles_spawn \
            gameplay/800D942C_trigger_particles_update \
            gameplay/800D9900_minimap_blips_spawn \
            render/800D9B50_model_bounds_compute \
            weapons/800DAC34_projectile_bounce \
            weapons/800DC7B0_projectile_life_tick \
            weapons/800DC968_projectile_fire \
            world/800DD6F4_structure_flicker_roll \
            world/800DDF04_structure_model_draw \
            world/800DE2FC_structure_owner_award \
            entities/800DE52C_spawner_state_update \
            entities/800DE748_spawner_owner_score \
            entities/800DE7E8_spawner_message_handler \
            frontend/800DF0D0_slot_corners_build \
            frontend/800DF558_slot_entity_attach \
            frontend/800DF63C_slot_angle_classify \
            frontend/800DF758_slot_entry_lookup \
            gameplay/800E2810_target_search \
            entities/800E29A4_wreck_spawn \
            entities/800E2AEC_turret_spawn_at \
            entities/800E2E0C_wreck_ctl \
            entities/800E4530_object_damage \
            world/800E48E0_flag_owner_capture \
            world/800E4B84_flag_owner_score \
            entities/800E4F3C_actor_wreck_spawn_at \
            audio/800E51E8_sound_emitter_draw \
            world/800E58D0_bridge_segments_init \
            world/800E6040_bridge_piece_spawn \
            world/800E68BC_crate_owner_check \
            world/800E713C_crate_contents_spawn \
            gameplay/800E75F4_pending_spawns_flush \
            gameplay/800E7F60_pickup_find_by_id \
            runtime/800E8090_game_team_compare \
            gameplay/800E80F4_multiplayer_actor_spawn \
            frontend/800E944C_mission_code_parse \
            frontend/800E96B4_mission_flag_set \
            frontend/800E9E80_mission_props_spawn \
            frontend/800EA14C_mission_targets_query \
            frontend/800EA714_mission_marker_draw \
            effects/800EB7BC_impact_debris_spray \
            frontend/800EC4A8_mission_objectives_update \
            weapons/800ECEBC_projectile_shell_draw \
            gameplay/800ED0AC_shockwave_expand \
            world/800EE688_prop_spawn_child \
            gameplay/800EE490_motion_scale_curve \
            gameplay/800F0A20_rotated_texture_coords \
            effects/800F6C70_effect_billboard_draw \
            world/800EE7F8_prop_spawn_pickup \
            world/800EE8C0_prop_height_update \
            effects/800EFEC4_particle_emitter_free \
            effects/800F0658_particle_smoke_update \
            effects/800F0B08_particle_hit_spawn \
            effects/800F0ED0_particle_system_create \
            effects/800F11D0_particle_owner_message \
            render/800F17B0_anim_keyframes_apply \
            effects/800F7650_effect_motion_update \
            world/800F1D94_hazard_state_update \
            world/800F2050_hazard_model_draw \
            world/800F2288_hazard_message_handler \
            gameplay/800F2980_mine_trigger_update \
            world/800F2DB4_powerup_timer_update \
            world/800F352C_barrel_explode \
            gameplay/800F4D80_mesh_wave_update \
            gameplay/800F50B8_tracer_trail_update \
            effects/800F5298_effect_prop_spawn \
            effects/800F5470_effect_targets_query \
            effects/800F5548_effect_targets_damage \
            effects/800F577C_effect_burn_update \
            effects/800F5B3C_effect_beam_draw \
            gameplay/800F6650_generator_spawn \
            render/800F7870_anim_alpha_fade_draw \
            gameplay/800F7A80_spark_burst_update \
            gameplay/800F80A0_static_in_radius \
            render/800F8264_model_in_draw_range \
            weapons/800F872C_artillery_target_track \
            gameplay/800F3F78_mesh_rings_draw; do
    .toolchain/kmc-gcc-2.7.2/gcc -B.toolchain/kmc-gcc-2.7.2/ -S \
        -O2 -G0 -mips3 -mgp32 -mfp32 -Iinclude -Isrc/code/include \
        -o "build/us/src/code/${unit}.raw.s" "src/code/${unit}.c"
    python3 tools/normalize_kmc_gcc_asm.py \
        "build/us/src/code/${unit}.raw.s" "build/us/src/code/${unit}.s"
    .toolchain/kmc-gcc-2.7.2/as -mips3 -G0 \
        -o "build/us/src/code/${unit}.c.o" "build/us/src/code/${unit}.s"
done

# Whole translation units recovered from the early engine and AI region.
# Compile each unit once so inline copies and shared constant pools retain the
# retail allocation and layout.
for spec in \
        debug/80078ADC_early_remote_transfer:0x18C \
        path/800825A4_path_goal_update:0x290 \
        ai/80086208_ai_state_dispatch:0x49C \
        entities/80086840_unit_target_select:0x370 \
        ai/80088CA8_ai_target_refresh:0x2DC \
        vehicles/8008BD5C_tank_damage_motion:0x860 \
        weapons/8008E6E0_weapon_inventory:0xD1C \
        collision/8008F3FC_collision_query:0x390 \
        path/8007E64C_path_target_acquire:0x12C \
        collision/80081EA4_collision_hit_query:0x134 \
        ai/80083A80_ai_target_state_update:0x1F0 \
        world/800857F0_zone_spawn_query:0x1B8 \
        entities/8008723C_unit_command_state:0x18C \
        ai/800873FC_ai_weapon_fire_update:0x174 \
        gameplay/80089C90_visibility_mask_clear:0x108 \
        vehicles/80089F40_tank_mode_transition:0x264 \
        path/8008A62C_waypoint_stack_pop:0x138 \
        path/8008AA20_waypoint_stack_update:0x35C \
        path/80080920_path_list_update:0x1D4 \
        ai/8008474C_ai_object_state_update:0x120 \
        ai/80086034_ai_behavior_state_update:0x128 \
        vehicles/80087A80_vehicle_steering_update:0x1B0 \
        ai/80087C8C_ai_movement_dispatch:0x148 \
        gameplay/80087DF4_target_angle_check:0xFC \
        entities/80090040_spawn_point_retry:0x1D8 \
        debug/80078274_early_memory_dispatch:0x5BC \
        render/80079570_display_list_interpolate:0x58C; do
    unit="${spec%%:*}"
    text_size="${spec#*:}"
    .toolchain/kmc-gcc-2.7.2/gcc -B.toolchain/kmc-gcc-2.7.2/ -S \
        -O2 -G0 -mips3 -mgp32 -mfp32 -Iinclude -Isrc/code/include \
        -o "build/us/src/code/${unit}.raw.s" "src/code/${unit}.c"
    python3 tools/normalize_kmc_gcc_asm.py \
        "build/us/src/code/${unit}.raw.s" "build/us/src/code/${unit}.s"
    .toolchain/kmc-gcc-2.7.2/as -mips3 -G0 \
        -o "build/us/src/code/${unit}.c.o" "build/us/src/code/${unit}.s"
    python3 tools/trim_elf32_section.py \
        "build/us/src/code/${unit}.c.o" .text "$text_size" --alignment 4
done
python3 tools/trim_elf32_section.py \
    build/us/src/code/ai/80086208_ai_state_dispatch.c.o .rodata 0xFC --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/80086840_unit_target_select.c.o .rodata 0x58 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/ai/80088CA8_ai_target_refresh.c.o .rodata 0x38 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/vehicles/8008BD5C_tank_damage_motion.c.o .rodata 0x6C --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/weapons/8008E6E0_weapon_inventory.c.o .rodata 0x2AC --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/ai/80083A80_ai_target_state_update.c.o .rodata 0x4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800857F0_zone_spawn_query.c.o .rodata 0x4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/8008723C_unit_command_state.c.o .rodata 0x20 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/ai/800873FC_ai_weapon_fire_update.c.o .rodata 0x8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/vehicles/80089F40_tank_mode_transition.c.o .rodata 0x2C --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/ai/80086034_ai_behavior_state_update.c.o .rodata 0x14 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/vehicles/80087A80_vehicle_steering_update.c.o .rodata 0xC --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/ai/80087C8C_ai_movement_dispatch.c.o .rodata 0x48 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/80087DF4_target_angle_check.c.o .rodata 0x4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/80090040_spawn_point_retry.c.o .rodata 0x18 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/debug/80078274_early_memory_dispatch.c.o .rodata 0x28 --alignment 4

# The graphics task and frame-builder units were compiled without optimization,
# matching the adjacent retail graphics setup code.
for spec in render/80079C00_graphics_task_init:0x3F0 render/8007A0A0_graphics_frame_build:0x664; do
    unit="${spec%%:*}"
    text_size="${spec#*:}"
    .toolchain/kmc-gcc-2.7.2/gcc -B.toolchain/kmc-gcc-2.7.2/ -S \
        -O0 -G0 -mips3 -mgp32 -mfp32 -Iinclude -Isrc/code/include \
        -o "build/us/src/code/${unit}.raw.s" "src/code/${unit}.c"
    python3 tools/normalize_kmc_gcc_asm.py \
        "build/us/src/code/${unit}.raw.s" "build/us/src/code/${unit}.s"
    .toolchain/kmc-gcc-2.7.2/as -mips3 -G0 \
        -o "build/us/src/code/${unit}.c.o" "build/us/src/code/${unit}.s"
    python3 tools/trim_elf32_section.py \
        "build/us/src/code/${unit}.c.o" .text "$text_size" --alignment 4
done

python3 tools/trim_elf32_section.py \
    build/us/src/code/runtime/80082C1C_state_activate.c.o .text 0xec --alignment 4

# The compiler-runtime tail uses GCC 2.7.2's libgcc implementation. Its retail
# assembler retained the return-slot nops while keeping the compiler's other
# scheduling, so use the narrow libgcc postprocessor rather than the gameplay
# normalizer.
mkdir -p build/us/src/libgcc
.toolchain/kmc-gcc-2.7.2/gcc -B.toolchain/kmc-gcc-2.7.2/ -S \
    -O2 -G0 -mips3 -mgp32 -mfp32 \
    -o build/us/src/libgcc/cmpdi2.s src/libgcc/cmpdi2.c
.toolchain/kmc-gcc-2.7.2/as -mips3 -G0 \
    -o build/us/src/libgcc/cmpdi2.c.o build/us/src/libgcc/cmpdi2.s
python3 tools/trim_elf32_section.py \
    build/us/src/libgcc/cmpdi2.c.o .text 0x40 --alignment 4
.toolchain/kmc-gcc-2.7.2/gcc -B.toolchain/kmc-gcc-2.7.2/ -S \
    -O2 -G0 -mips3 -mgp32 -mfp32 \
    -o build/us/src/libgcc/floatdisf.raw.s src/libgcc/floatdisf.c
python3 tools/normalize_kmc_gcc_asm.py \
    build/us/src/libgcc/floatdisf.raw.s build/us/src/libgcc/floatdisf.base.s
python3 tools/normalize_libgcc_asm.py \
    build/us/src/libgcc/floatdisf.base.s build/us/src/libgcc/floatdisf.s
.toolchain/kmc-gcc-2.7.2/as -mips3 -G0 \
    -o build/us/src/libgcc/floatdisf.c.o build/us/src/libgcc/floatdisf.s
python3 tools/trim_elf32_section.py \
    build/us/src/libgcc/floatdisf.c.o .text 0xbc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/libgcc/floatdisf.c.o .rodata 0x18 --alignment 8
for spec in udivdi3:0x20 udivmoddi4:0x63c umoddi3:0x2c; do
    unit="${spec%%:*}"
    text_size="${spec#*:}"
    .toolchain/kmc-gcc-2.7.2/gcc -B.toolchain/kmc-gcc-2.7.2/ -S \
        -O2 -G0 -mips3 -mgp32 -mfp32 \
        -o "build/us/src/libgcc/${unit}.raw.s" "src/libgcc/${unit}.c"
    python3 tools/normalize_libgcc_asm.py \
        "build/us/src/libgcc/${unit}.raw.s" "build/us/src/libgcc/${unit}.s"
    .toolchain/kmc-gcc-2.7.2/as -mips3 -G0 \
        -o "build/us/src/libgcc/${unit}.c.o" "build/us/src/libgcc/${unit}.s"
    python3 tools/trim_elf32_section.py \
        "build/us/src/libgcc/${unit}.c.o" .text "$text_size" --alignment 4
done
python3 tools/trim_elf32_section.py \
    build/us/src/libgcc/udivmoddi4.c.o .rodata 0x100 --alignment 4

while IFS=$'\t' read -r function_name address size status; do
    case "$function_name" in
        \#*|function|'') continue ;;
    esac
    unit="code/${function_name}"
    mkdir -p "build/us/src/code"
    .toolchain/kmc-gcc-2.7.2/gcc -B.toolchain/kmc-gcc-2.7.2/ -S \
        -O2 -G0 -mips3 -mgp32 -mfp32 -Iinclude -Isrc/code/include \
        -o "build/us/src/${unit}.raw.s" "src/${unit}.c"
    python3 tools/normalize_kmc_gcc_asm.py \
        "build/us/src/${unit}.raw.s" "build/us/src/${unit}.s" --legacy
    .toolchain/kmc-gcc-2.7.2/as -mips3 -G0 \
        -o "build/us/src/${unit}.c.o" "build/us/src/${unit}.s"
    python3 tools/trim_elf32_section.py \
        "build/us/src/${unit}.c.o" .text "$size" --alignment 4
done < config/us/legacy_normalized_units.tsv
while IFS=$'\t' read -r function_name address size status; do
    case "$function_name" in
        \#*|function|'') continue ;;
    esac
    unit="code/${function_name}"
    mkdir -p "build/us/src/code"
    .toolchain/kmc-gcc-2.7.2/gcc -B.toolchain/kmc-gcc-2.7.2/ -S \
        -O2 -G0 -mips3 -mgp32 -mfp32 -Iinclude -Isrc/code/include \
        -o "build/us/src/${unit}.raw.s" "src/${unit}.c"
    python3 tools/normalize_kmc_gcc_asm.py \
        "build/us/src/${unit}.raw.s" "build/us/src/${unit}.s" --legacy
    .toolchain/kmc-gcc-2.7.2/as -mips3 -G0 \
        -o "build/us/src/${unit}.c.o" "build/us/src/${unit}.s"
    python3 tools/trim_elf32_section.py \
        "build/us/src/${unit}.c.o" .text "$size" --alignment 4
done < config/us/legacy_normalized_units_extra.tsv
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/80090218.c.o .rodata 0x4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/8009D510.c.o .rodata 0x4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800D67F0_effect_draw.c.o .rodata 0x4 --alignment 4

# Typed constants split from compiler-generated sequence-script pools. Keeping
# these in companion objects preserves the owning units' retail jump-table order.
for spec in \
        script/80074568_seq_script_tick_constants:0x20 \
        script/80074764_seq_event_spawn_constants:0x4 \
        script/800749A8_seq_target_search_constants:0x8 \
        script/80074A70_seq_point_track_constants:0x8 \
        script/80074D00_seq_script_load_constants:0x30 \
        entities/8007448C_spawn_object_command_constants:0x4; do
    unit="${spec%%:*}"
    rodata_size="${spec#*:}"
    .toolchain/kmc-gcc-2.7.2/gcc -B.toolchain/kmc-gcc-2.7.2/ -S \
        -O2 -G0 -mips3 -mgp32 -mfp32 -Iinclude -Isrc/code/include \
        -o "build/us/src/code/${unit}.raw.s" "src/code/${unit}.c"
    python3 tools/normalize_kmc_gcc_asm.py \
        "build/us/src/code/${unit}.raw.s" "build/us/src/code/${unit}.s"
    .toolchain/kmc-gcc-2.7.2/as -mips3 -G0 \
        -o "build/us/src/code/${unit}.c.o" "build/us/src/code/${unit}.s"
    python3 tools/trim_elf32_section.py \
        "build/us/src/code/${unit}.c.o" .rodata "$rodata_size" --alignment 4
done

# Whole gameplay translation units that match with the standard production
# normalizer. Keep these manifest-driven so new unit reconstructions do not
# expand the legacy per-function compile table below.
while IFS=$'\t' read -r unit address text_size status; do
    case "$unit" in
        \#*|unit|'') continue ;;
    esac
    extra_cflags=()
    case "$status" in
        matched-mcpu-r8000)
            # This original TU uses BRANCH_COST 1 while retaining R4000-style
            # scheduling; GCC 2.7.2's r8000 model is the exact combination.
            extra_cflags+=(-mcpu=r8000)
            ;;
    esac
    .toolchain/kmc-gcc-2.7.2/gcc -B.toolchain/kmc-gcc-2.7.2/ -S \
        -O2 -G0 -mips3 -mgp32 -mfp32 "${extra_cflags[@]}" -Iinclude -Isrc/code/include \
        -o "build/us/src/code/${unit}.raw.s" "src/code/${unit}.c"
    python3 tools/normalize_kmc_gcc_asm.py \
        "build/us/src/code/${unit}.raw.s" "build/us/src/code/${unit}.s"
    .toolchain/kmc-gcc-2.7.2/as -mips3 -G0 \
        -o "build/us/src/code/${unit}.c.o" "build/us/src/code/${unit}.s"
    python3 tools/trim_elf32_section.py \
        "build/us/src/code/${unit}.c.o" .text "$text_size" --alignment 4
    rodata_size="$(awk -v wanted="$unit" '$1 == wanted { print $3 }' \
        config/us/unit_rodata.tsv)"
    if [[ -n "$rodata_size" ]]; then
        python3 tools/trim_elf32_section.py \
            "build/us/src/code/${unit}.c.o" .rodata "$rodata_size" --alignment 4
    fi
done < config/us/clean_normalized_units.tsv

# Units whose raw KMC GCC output matches when assembled with the retail
# SN Systems ASN64 behavior.  The public-domain preprocessor is deliberately
# limited to this evidence-backed allowlist; compiler/register rewrites remain
# on the normalizer-assisted path below.
while IFS=$'\t' read -r unit address text_size status; do
    case "$unit" in
        \#*|unit|'') continue ;;
    esac
    .toolchain/kmc-gcc-2.7.2/gcc -B.toolchain/kmc-gcc-2.7.2/ -S \
        -O2 -G0 -mips3 -mgp32 -mfp32 -Iinclude -Isrc/code/include \
        -o "build/us/src/code/${unit}.raw.s" "src/code/${unit}.c"
    python3 tools/modern_asn64.py \
        "${tool_prefix}as" -march=vr4300 -mabi=32 -EB -G0 \
        --no-pad-sections "build/us/src/code/${unit}.raw.s" \
        -o "build/us/src/code/${unit}.c.o"
    "${tool_prefix}objcopy" \
        --rename-section .rdata=.rodata,alloc,load,readonly,data,contents \
        "build/us/src/code/${unit}.c.o"
    python3 tools/trim_elf32_section.py \
        "build/us/src/code/${unit}.c.o" .text "$text_size" --alignment 4
    rodata_size="$(awk -v wanted="$unit" '$1 == wanted { print $3 }' \
        config/us/unit_rodata.tsv)"
    if [[ -n "$rodata_size" ]]; then
        python3 tools/trim_elf32_section.py \
            "build/us/src/code/${unit}.c.o" .rodata "$rodata_size" --alignment 4
    fi
done < config/us/asn64_units.tsv

# Whole gameplay units whose C is exact apart from narrowly gated, documented
# retail-assembler behavior reproduced by the production normalizer.
while IFS=$'\t' read -r unit address text_size status; do
    case "$unit" in
        \#*|unit|'') continue ;;
    esac
    extra_cflags=()
    case "$status" in
        compiler-normalizer-assisted-no-cse-skip-blocks)
            extra_cflags+=(-fno-cse-skip-blocks)
            ;;
    esac
    .toolchain/kmc-gcc-2.7.2/gcc -B.toolchain/kmc-gcc-2.7.2/ -S \
        -O2 -G0 -mips3 -mgp32 -mfp32 "${extra_cflags[@]}" -Iinclude -Isrc/code/include \
        -o "build/us/src/code/${unit}.raw.s" "src/code/${unit}.c"
    python3 tools/normalize_kmc_gcc_asm.py \
        "build/us/src/code/${unit}.raw.s" "build/us/src/code/${unit}.s"
    .toolchain/kmc-gcc-2.7.2/as -mips3 -G0 \
        -o "build/us/src/code/${unit}.c.o" "build/us/src/code/${unit}.s"
    python3 tools/trim_elf32_section.py \
        "build/us/src/code/${unit}.c.o" .text "$text_size" --alignment 4
    rodata_size="$(awk -v wanted="$unit" '$1 == wanted { print $3 }' \
        config/us/unit_rodata.tsv)"
    if [[ -n "$rodata_size" ]]; then
        python3 tools/trim_elf32_section.py \
            "build/us/src/code/${unit}.c.o" .rodata "$rodata_size" --alignment 4
    fi
done < config/us/normalizer_assisted_units.tsv

# Typed rodata whose original text owners remain assembly.  Standalone objects
# make the recovered types explicit and can be merged into their original
# translation units as those functions close.
while IFS=$'\t' read -r unit address rodata_size; do
    case "$unit" in
        \#*|unit|'') continue ;;
    esac
    .toolchain/kmc-gcc-2.7.2/gcc -B.toolchain/kmc-gcc-2.7.2/ -S \
        -O2 -G0 -mips3 -mgp32 -mfp32 -Iinclude -Isrc/code/include \
        -o "build/us/src/code/${unit}.raw.s" "src/code/${unit}.c"
    python3 tools/normalize_kmc_gcc_asm.py \
        "build/us/src/code/${unit}.raw.s" "build/us/src/code/${unit}.s"
    .toolchain/kmc-gcc-2.7.2/as -mips3 -G0 \
        -o "build/us/src/code/${unit}.c.o" "build/us/src/code/${unit}.s"
    python3 tools/trim_elf32_section.py \
        "build/us/src/code/${unit}.c.o" .rodata "$rodata_size" --alignment 4
done < config/us/typed_rodata_units.tsv

for function_name in \
        unknown/8007A7B4 \
        unknown/8007A818 \
        unknown/8007A8F0 \
        unknown/8007A9EC \
        unknown/8007AAA8 \
        unknown/8007AB64 \
        unknown/8007ADF0 \
        unknown/8007B0E4 \
        unknown/8007D39C \
        unknown/8007D7C4 \
        unknown/8007D884 \
        unknown/8007D998 \
        unknown/8007DACC \
        unknown/8007DD54 \
        unknown/8007DE3C \
        unknown/8007E024 \
        unknown/8007E118 \
        unknown/8007E7A8 \
        unknown/8007E8C8 \
        unknown/80079FF0 \
        unknown/8007B8EC \
        unknown/8007AF84 \
        unknown/8007D33C \
        unknown/80080818 \
        unknown/80080C04 \
        unknown/80082A90 \
        unknown/80083CC0 \
        unknown/80083DF0 \
        unknown/80083EBC \
        unknown/8008518C \
        unknown/80085250 \
        unknown/80085DA8 \
        unknown/80085F7C \
        unknown/80086700 \
        unknown/80087F2C \
        unknown/8008865C \
        unknown/8008875C \
        unknown/80088ABC \
        unknown/80089E84 \
        unknown/80089DBC \
        unknown/8008A350 \
        unknown/8008A5E4 \
        unknown/8008B6D0 \
        unknown/8008B788 \
        unknown/8008BEC4 \
        unknown/8008E6E0 \
        unknown/8008E620 \
        unknown/8008F3FC \
        unknown/800947C4 \
        unknown/8009660C \
        unknown/80096F48 \
        unknown/800976AC \
        unknown/80097844 \
        unknown/800979F4 \
        unknown/80097BC4 \
        unknown/80097CC8 \
        unknown/80097EE4 \
        unknown/80098250 \
        unknown/80098334 \
        unknown/8009836C \
        unknown/80098454 \
        unknown/80098F24 \
        unknown/80098B58 \
        unknown/80098BF8 \
        unknown/80099028 \
        unknown/8009A650 \
        unknown/8009ACDC \
        unknown/8009AD7C \
        unknown/8009D4B0 \
        unknown/8009D75C \
        unknown/8009D960 \
        unknown/8009DAB0 \
        unknown/8009DFAC \
        unknown/8009E0E8 \
        unknown/8009E19C \
        unknown/8009E9C8 \
        unknown/8009EA70 \
        unknown/8009EC0C \
        unknown/8009ED00 \
        unknown/8009F090 \
        unknown/8009F334 \
        unknown/8009F5AC \
        unknown/8009F8A0 \
        unknown/800A1150 \
        unknown/800A1290 \
        unknown/800A140C \
        unknown/800A15F0 \
        unknown/800A18D0 \
        unknown/800A19DC \
        unknown/800A1B44 \
        unknown/800A2B9C \
        unknown/800A2EF0 \
        unknown/800A2F0C \
        unknown/800A60E0 \
        unknown/800A6B7C \
        unknown/800A8D54 \
        unknown/800A8E84 \
        unknown/800A8F34 \
        unknown/800A9660 \
        unknown/800A96B8 \
        unknown/800ACF20 \
        unknown/800A97FC \
        unknown/800A9A44 \
        unknown/800A9A98 \
        unknown/800ABE6C \
        unknown/800ACFE0 \
        unknown/800AD088 \
        unknown/800B0D70 \
        unknown/800B22F8 \
        unknown/800B6934 \
        unknown/800B9F44 \
        unknown/800BDA30 \
        unknown/800BF1A4 \
        unknown/800BF3EC \
        unknown/800BFCA4 \
        unknown/800BFE4C \
        unknown/800C04C8 \
        unknown/800C0564 \
        unknown/800C0A6C \
        unknown/800C0ADC \
        unknown/800C0B78 \
        unknown/800C0C38 \
        unknown/800C13BC \
        unknown/800C180C \
        unknown/800C1E48 \
        func_800EB838 \
        func_800ED4F4 \
        func_800E82AC; do
    function_key="$function_name"
    if [[ "$function_name" == unknown/* ]]; then
        function_key="func_${function_name##*/}"
    fi
    case "$function_name" in
        func_800EB838) unit="code/effects/800EB838_impact_debris_emit" ;;
        func_800ED4F4) unit="code/world/800ED4F4_destructible_prop_destroy" ;;
        func_800E82AC) unit="code/unknown/800E82AC" ;;
        func_80079FF0|func_8007A7B4|func_8007A818|func_8007A8F0|func_8007A9EC|func_8007AAA8|func_8007AB64|func_8007ADF0|func_8007AF84|func_8007B0E4|func_8007B8EC|func_8007D33C|func_8007D39C|func_8007D7C4|func_8007D884|func_8007D998|func_8007DACC|func_8007DD54|func_8007DE3C|func_8007E024|func_8007E118|func_8007E7A8|func_8007E8C8|\
        func_80080818|func_80080C04|func_80082A90|func_80083CC0|func_80083DF0|func_80083EBC|func_8008518C|func_80085250|func_80085DA8|func_80085F7C|func_80086700|func_80087F2C|func_8008865C|func_8008875C|func_80088ABC|func_80089E84|\
        func_8008A350|func_8008B6D0|func_8008B788|func_8008BEC4|func_8008E6E0|func_8008E620|func_8008F3FC|func_800947C4|func_8009660C|func_80096F48|func_800976AC|func_80097844|func_800979F4|func_80098F24|\
        func_80097CC8|func_80097EE4|func_80098250|func_80098334|func_8009836C|func_80098454|func_80098BF8|func_80099028|func_8009A650|func_8009ACDC|func_8009AD7C|func_8009D4B0|func_8009D75C|func_8009F090|func_8009F334|func_8009F5AC|func_8009F8A0|func_800A1150|func_800A1290|\
        func_8009D960|func_8009DAB0|func_8009DFAC|func_8009E0E8|func_8009E19C|func_8009EC0C|func_800A140C|func_800A15F0|func_800A18D0|func_800A19DC|\
        func_800A1B44|func_800A2B9C|func_800A2EF0|func_800A2F0C|func_800A60E0|func_800A6B7C|func_800A8D54|func_800A8E84|func_800A8F34|func_800A9660|func_800A96B8|func_800A9A98|func_800ACF20|func_800ACFE0|func_800AD088|func_800ABE6C|func_800B22F8|\
        func_800B0D70|func_800B6934|func_800B9F44|func_800BDA30|func_800C04C8|func_800C0564|\
        func_800C0ADC|func_800C0B78|func_800C0C38|func_800C13BC|\
        func_800C180C|func_800E82AC)
            unit="code/${function_name}" ;;
        *) unit="code/${function_name}" ;;
    esac
    optimization=-O2
    if [ "$function_name" = unknown/80079FF0 ]; then
        optimization=-O0
    fi
    .toolchain/kmc-gcc-2.7.2/gcc -B.toolchain/kmc-gcc-2.7.2/ -S \
        "$optimization" -G0 -mips3 -mgp32 -mfp32 -Iinclude -Isrc/code/include \
        -o "build/us/src/${unit}.raw.s" "src/${unit}.c"
    python3 tools/normalize_kmc_gcc_asm.py \
        "build/us/src/${unit}.raw.s" "build/us/src/${unit}.s"
    .toolchain/kmc-gcc-2.7.2/as -mips3 -G0 \
        -o "build/us/src/${unit}.c.o" "build/us/src/${unit}.s"
    case "$function_key" in
        func_80079FF0) size=0xB0 ;;
        func_8007A7B4) size=0x64 ;;
        func_8007A818) size=0xD8 ;;
        func_8007A8F0) size=0xFC ;;
        func_8007A9EC) size=0xBC ;;
        func_8007AAA8) size=0xBC ;;
        func_8007AB64) size=0xD0 ;;
        func_8007ADF0) size=0x194 ;;
        func_8007AF84) size=0x98 ;;
        func_8007B0E4) size=0xAC ;;
        func_8007B8EC) size=0x400 ;;
        func_8007D33C) size=0x60 ;;
        func_8007D39C) size=0xCC ;;
        func_8007D7C4) size=0xC0 ;;
        func_8007D884) size=0x114 ;;
        func_8007D998) size=0xC4 ;;
        func_8007DACC) size=0xB8 ;;
        func_8007DD54) size=0xE8 ;;
        func_8007DE3C) size=0x164 ;;
        func_8007E024) size=0xF4 ;;
        func_8007E118) size=0x4C ;;
        func_8007E7A8) size=0x120 ;;
        func_8007E8C8) size=0xC0 ;;
        func_80080818) size=0x9C ;;
        func_80080C04) size=0xC4 ;;
        func_80082A90) size=0xAC ;;
        func_80083CC0) size=0xE8 ;;
        func_80083DF0) size=0xCC ;;
        func_80083EBC) size=0xB8 ;;
        func_8008518C) size=0xC4 ;;
        func_80085250) size=0xA8 ;;
        func_80085DA8) size=0xA4 ;;
        func_80085F7C) size=0xB8 ;;
        func_80086700) size=0xC4 ;;
        func_80087F2C) size=0xD4 ;;
        func_8008865C) size=0xC4 ;;
        func_8008875C) size=0xF8 ;;
        func_80088ABC) size=0x5C ;;
        func_80089E84) size=0xB4 ;;
        func_80089DBC) size=0x64 ;;
        func_8008A350) size=0x50 ;;
        func_8008A5E4) size=0x48 ;;
        func_8008B6D0) size=0xB8 ;;
        func_8008B788) size=0xA4 ;;
        func_8008BEC4) size=0x98 ;;
        func_8008E6E0) size=0xA0 ;;
        func_8008E620) size=0x9C ;;
        func_8008F3FC) size=0xB0 ;;
        func_800947C4) size=0xBC ;;
        func_8009660C) size=0xC8 ;;
        func_80096F48) size=0xC4 ;;
        func_800976AC) size=0xE8 ;;
        func_80097844) size=0xC8 ;;
        func_800979F4) size=0x78 ;;
        func_80097BC4) size=0x58 ;;
        func_80097CC8) size=0x4C ;;
        func_80097EE4) size=0xD0 ;;
        func_80098250) size=0xE4 ;;
        func_80098334) size=0x38 ;;
        func_8009836C) size=0xC4 ;;
        func_80098454) size=0xE0 ;;
        func_80098F24) size=0x98 ;;
        func_80098B58) size=0x70 ;;
        func_80098BF8) size=0xD0 ;;
        func_80099028) size=0x58 ;;
        func_8009A650) size=0xA0 ;;
        func_8009ACDC) size=0xA0 ;;
        func_8009AD7C) size=0xBC ;;
        func_800A60E0) size=0xBC ;;
        func_800A8D54) size=0xE8 ;;
        func_8009D4B0) size=0x60 ;;
        func_8009D75C) size=0xC0 ;;
        func_8009D960) size=0xD4 ;;
        func_8009DAB0) size=0x5C ;;
        func_8009DFAC) size=0x98 ;;
        func_8009E0E8) size=0xB4 ;;
        func_8009E19C) size=0xB4 ;;
        func_8009E9C8) size=0xA8 ;;
        func_8009EA70) size=0xF8 ;;
        func_8009EC0C) size=0xE8 ;;
        func_8009ED00) size=0x9C ;;
        func_8009F090) size=0x164 ;;
        func_8009F334) size=0x110 ;;
        func_8009F5AC) size=0x1BC ;;
        func_8009F8A0) size=0x42C ;;
        func_800A1150) size=0x130 ;;
        func_800A1290) size=0xBC ;;
        func_800A140C) size=0x1E4 ;;
        func_800A15F0) size=0x108 ;;
        func_800A18D0) size=0x10C ;;
        func_800A19DC) size=0x4C ;;
        func_800A1B44) size=0x9C ;;
        func_800A2B9C) size=0xD0 ;;
        func_800A2EF0) size=0x1C ;;
        func_800A2F0C) size=0xB0 ;;
        func_800A6B7C) size=0xA4 ;;
        func_800A8E84) size=0xB0 ;;
        func_800A8F34) size=0x120 ;;
        func_800A9660) size=0x58 ;;
        func_800A96B8) size=0x94 ;;
        func_800A9A98) size=0xCC ;;
        func_800ACF20) size=0xC0 ;;
        func_800ACFE0) size=0xA8 ;;
        func_800AD088) size=0xC4 ;;
        func_800B0D70) size=0xC8 ;;
        func_800ABE6C) size=0xCC ;;
        func_800A97FC) size=0xBC ;;
        func_800A9A44) size=0x54 ;;
        func_800AA5D0) size=0x94 ;;
        func_800B22F8) size=0x6C ;;
        func_800B6934) size=0xC0 ;;
        func_800B9F44) size=0x90 ;;
        func_800BDA30) size=0xC8 ;;
        func_800BF1A4) size=0x60 ;;
        func_800BF3EC) size=0x98 ;;
        func_800BFCA4) size=0x9C ;;
        func_800BFE4C) size=0x48 ;;
        func_800C04C8) size=0x9C ;;
        func_800C0564) size=0xA4 ;;
        func_800C0A6C) size=0x70 ;;
        func_800C0ADC) size=0x9C ;;
        func_800C0B78) size=0xA0 ;;
        func_800C0C38) size=0xC8 ;;
        func_800C13BC) size=0x64 ;;
        func_800C180C) size=0x12C ;;
        func_800C1E48) size=0xC0 ;;
        func_800EB838) size=0xFC ;;
        func_800ED4F4) size=0x148 ;;
        func_800E82AC) size=0x6C ;;
    esac
    python3 tools/trim_elf32_section.py \
        "build/us/src/${unit}.c.o" .text "$size" --alignment 4
done
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800A1290.c.o .rodata 0x14 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/8008E6E0.c.o .rodata 0x3C --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/8009D168.c.o .rodata 0x38 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/8011C254_controller_layout_data.c.o .rodata 0xE0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/8009D4B0.c.o .rodata 0x4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/8009D960.c.o .rodata 0x1C --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/8009EA70.c.o .rodata 0x20 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/8009EC0C.c.o .rodata 0x8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/8009F334.c.o .rodata 0x4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/8009F5AC.c.o .rodata 0x4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/8009F8A0.c.o .rodata 0xC --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800A9A98.c.o .rodata 0x19 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800ABE6C.c.o .rodata 0x4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800B6934.c.o .rodata 0x8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800BFE4C.c.o .rodata 0x8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/8011B318_hud_list_layout_data.c.o .rodata 0x268 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/8009EEE0_matrix_basic.c.o .rodata 0x4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/math/80114C80_random_dispatch_tables.c.o .rodata 0x31C --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/debug/80077C40_early_hw.c.o .text 0x164 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/debug/80077DA4_early_memory_read.c.o .text 0x22c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/debug/80078048_early_memory_write.c.o .text 0x1b8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/debug/80078200_early_remote_copy.c.o .text 0x74 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/debug/80078908_early_commands.c.o .text 0x1d4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/debug/80078C68_early_command_status.c.o .text 0x70 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/8007AC34_display_buffer.c.o .text 0x10c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/8007AD94_display_buffer_select.c.o .text 0x1c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/8007ADC0_controller_state.c.o .text 0x30 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/8007D500_mapped_record.c.o .text 0x58 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/8007A720_display_slot.c.o .text 0x3c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800A2B74_object_range.c.o .text 0x28 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C1094_menu_toggle.c.o .text 0x90 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C1420_menu_countdown.c.o .text 0x48 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800B9D4C_table_lookup.c.o .text 0xd8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CFDD0_results_assets_reload.c.o .text 0x288 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/runtime/800D0058_game_state_clear.c.o .text 0x18 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800D0814_spawn_ctl_index.c.o .text 0x44 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800D0960_spawn_ctl_alloc.c.o .text 0x80 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/audio/800D250C_audio_listener_update.c.o .text 0xd4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/audio/800D250C_audio_listener_update.c.o .rodata 0x10 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800D4D00_race_buffers_alloc.c.o .text 0xe0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/player/800D6E40_player_attach_effect_create.c.o .text 0xac --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/player/800D7CF4_player_attach_effect_matrix.c.o .text 0x6c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/player/800D7D60_player_attach_effect_matrix_cb.c.o .text 0x74 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800D8050_actor_collision_free.c.o .text 0x38 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800D8674_turret_message_handlers.c.o .text 0xe4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800D8F28_single_player_check.c.o .text 0x20 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800D91C0_trigger_zone_query.c.o .text 0x114 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800D97EC_minimap_layer_build.c.o .text 0x114 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/800D9A88_model_texture_find.c.o .text 0xc0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/800D9C38_model_bounds_center.c.o .text 0x118 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800DA340_debris_piece_draw.c.o .text 0x1b0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800DA4F0_debris_burst_spawn.c.o .text 0x16c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800DA4F0_debris_burst_spawn.c.o .rodata 0x4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800DA65C_debris_burst_spawn_tinted.c.o .text 0x174 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800DA65C_debris_burst_spawn_tinted.c.o .rodata 0x4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800DA984_debris_scatter_spawn.c.o .text 0x15c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/weapons/800DC214_projectile_model_draw.c.o .text 0x194 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/weapons/800DC3A8_projectile_model_create.c.o .text 0x28c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/weapons/800DC634_projectile_model_matrix.c.o .text 0xb8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/weapons/800DC634_projectile_model_matrix.c.o .rodata 0x4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/weapons/800DC6EC_projectile_model_matrix_cb.c.o .text 0xb8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/weapons/800DC804_projectile_trail_draw.c.o .text 0x164 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/weapons/800DC804_projectile_trail_draw.c.o .rodata 0x4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/weapons/800DD0D8_projectile_launch_delayed.c.o .text 0xe8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/weapons/800DD1C0_projectile_launch_delayed_tick.c.o .text 0xcc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/weapons/800DD1C0_projectile_launch_delayed_tick.c.o .rodata 0x8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/800DD290_model_mesh_partition.c.o .text 0x110 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800DD3A0_structure_create.c.o .text 0x354 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800DE4DC_spawner_target_query.c.o .text 0x50 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800DE930_unit_spawner_create.c.o .text 0x190 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800DEAC0_unit_spawner_update.c.o .text 0x604 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800DF33C_prop_multiplayer_filter.c.o .text 0x7c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800DF7A0_level_prop_points_find.c.o .text 0xfc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800E1540_foliage_prop_create.c.o .text 0x198 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800E1980_foliage_prop_handlers.c.o .text 0xcc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800E2018_turret_destroy.c.o .text 0x188 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800E21A0_turret_draw_create.c.o .text 0x380 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800E26A8_turret_message_handler.c.o .text 0x168 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800E2D74_turret_line_of_sight.c.o .text 0x98 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800E3404_wreck_timer_duration.c.o .text 0x5c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800E3404_wreck_timer_duration.c.o .rodata 0x4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800E462C_flag_capture_attempt.c.o .text 0x27c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800E462C_flag_capture_attempt.c.o .rodata 0x10 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800E4ECC_actor_kind16_link_clear.c.o .text 0x70 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/audio/800E5164_sound_emitter_delayed_spawn.c.o .text 0x84 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/audio/800E562C_ambient_sound_stop_first.c.o .text 0x9c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800E56D0_bridge_create_handlers.c.o .text 0x1f4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800E61E8_lightning_arc_update.c.o .text 0x304 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800E64F0_crate_model_randomize.c.o .text 0x50 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800E6540_crate_actor_attach.c.o .text 0x168 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800E759C_pending_list_flush.c.o .text 0x58 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800E7968_powerup_flag_players.c.o .text 0xa8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800E7DF8_powerup_count_refresh.c.o .text 0xe8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800E7EE0_pickup_actor_count.c.o .text 0x7c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/runtime/800E804C_game_mode_has_pickups.c.o .text 0x44 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800E8318_slist_remove_count.c.o .text 0x60 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800E92F0_mission_select_init.c.o .text 0x134 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800E9424_mission_entry_query.c.o .text 0x28 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800E9990_mission_actor_spawn.c.o .text 0x1c0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800E9990_mission_actor_spawn.c.o .rodata 0x38 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800E98F8_mission_time_bonus.c.o .text 0x98 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800E9E4C_mission_event_forward.c.o .text 0x2c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800EA964_building_target_query.c.o .text 0x5c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800EA9C0_building_destroy_on_hit.c.o .text 0xa8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800EAA68_building_damage_apply.c.o .text 0x14 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800EAC30_building_create.c.o .text 0x228 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800EAE58_building_anim_frame_tick.c.o .text 0x5c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800EAF6C_building_destroy.c.o .text 0x39c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800EAF6C_building_destroy.c.o .rodata 0xc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800EB720_impact_flash_spawn.c.o .text 0x9c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800EB934_impact_flash_expire.c.o .text 0x164 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/player/800EBCA8_player_projectile_launch.c.o .text 0xf8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800EC1C0_mission_counter_release.c.o .text 0x38 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800EC72C_splash_damage_falloff.c.o .text 0x5c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/weapons/800EC790_projectile_spawn_typed.c.o .text 0x158 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800ED010_shockwave_ring_spawn.c.o .text 0x9c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800ED1B0_shockwave_ring_draw.c.o .text 0x170 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800ED320_destructible_prop_create.c.o .text 0x1d4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800ED63C_destructible_anim_frame_tick.c.o .text 0x58 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/weapons/800ED730_projectile_target_query.c.o .text 0x44 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800ED774_destructible_prop_on_hit.c.o .text 0x48 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800ED7BC_destructible_prop_on_hit_alt.c.o .text 0x48 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800EDC00_prop_destroy_slot_release.c.o .text 0x1cc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800EE0B0_prop_target_query.c.o .text 0x38 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800EE0E8_prop_debris_burst_on_hit.c.o .text 0xd0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800EE1B8_prop_debris_burst_on_hit_alt.c.o .text 0xd0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800EB308_object_handlers.c.o .text 0x1f4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800EB308_object_handlers.c.o .rodata 0x100 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800ED804_message_dispatch.c.o .text 0x188 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800ED804_message_dispatch.c.o .rodata 0xfc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800EED90_segment_update.c.o .text 0x670 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800EED90_segment_update.c.o .rodata 0x20 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800F2184_hazard_trigger.c.o .text 0x104 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800F2184_hazard_trigger.c.o .rodata 0xc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800F67F0_sway_model_draw.c.o .text 0x474 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800F67F0_sway_model_draw.c.o .rodata 0x14 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800EE288_entity_message.c.o .text 0x200 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800EEADC_barrier_break_open.c.o .text 0x2b4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800EFBFC_particle_emitter_tail.c.o .text 0x6c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800EFC70_particle_emitter_create.c.o .text 0x1a0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800EFE10_particle_pool_init.c.o .text 0xb4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800F0064_particle_emitter_update.c.o .text 0x18c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800F0618_particle_free_list.c.o .text 0x40 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800F0930_particle_node_list.c.o .text 0xf0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/800F1770_anim_list_register_global.c.o .text 0x3c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800F1B30_hazard_actor_spawn.c.o .text 0x198 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800F1CC8_hazard_actor_spawn_simple.c.o .text 0xcc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800F265C_mine_message_handlers.c.o .text 0x324 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800F265C_mine_message_handlers.c.o .rodata 0xc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800F2BC0_powerup_pad_create.c.o .text 0x1f4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800F3098_powerup_pad_draw.c.o .text 0x170 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800F3208_prop_handlers.c.o .text 0xe4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800F32EC_barrel_handlers.c.o .text 0x240 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800F32EC_barrel_handlers.c.o .rodata 0x10 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800F36D0_falling_crate_update.c.o .text 0x1f0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800F36D0_falling_crate_update.c.o .rodata 0x4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800F38C0_decal_spawn_draw.c.o .text 0x2bc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/800F3B80_color_interpolate.c.o .text 0x184 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800F3D04_mesh_vertex_transform.c.o .text 0x274 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800F4FF0_tracer_spawn.c.o .text 0xc8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800F5270_effect_table_reset.c.o .text 0x28 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800F5E18_generator_damage_apply.c.o .text 0xf8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800F5F10_generator_message_damage.c.o .text 0x1f0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800F6100_generator_hit_query.c.o .text 0x44 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800F6144_generator_splash_damage.c.o .text 0x200 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800F6344_generator_damage_tick.c.o .text 0x174 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800F64B8_generator_dispatch_bonus.c.o .text 0x190 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800F67C8_effect_expire_100.c.o .text 0x28 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800F6ED0_wreck_debris_spawn.c.o .text 0x1bc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800F708C_wreck_debris_update.c.o .text 0xc4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/800F7150_anim_colors_set.c.o .text 0xac --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/800F71FC_anim_list_create.c.o .text 0x34 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/800F756C_anim_list_reset.c.o .text 0x10 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/800F757C_anim_list_register.c.o .text 0xcc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800F799C_spark_spawn.c.o .text 0xe4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800F799C_spark_spawn.c.o .rodata 0x10 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800F7BA4_smoke_puff_spawn.c.o .text 0x80 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800F7C30_flicker_prop_create.c.o .text 0xf4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800F7D24_flicker_prop_draw.c.o .text 0xf0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800F7E14_flicker_prop_message.c.o .text 0x50 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800F7E64_flicker_prop_message_cb.c.o .text 0x54 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800F7EC0_static_prop_create.c.o .text 0xac --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800F7F6C_static_prop_expire.c.o .text 0x18 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800F7F84_static_prop_draw.c.o .text 0x118 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/800F80E8_model_variant_get.c.o .text 0x120 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/800F8208_model_cache_globals.c.o .text 0x5c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/weapons/800F83C0_artillery_emplacement_update.c.o .text 0x218 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/weapons/800F83C0_artillery_emplacement_update.c.o .rodata 0xc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/weapons/800F85D8_artillery_emplacement_disable.c.o .text 0x18 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/weapons/800F85F0_artillery_emplacement_create.c.o .text 0x6c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/weapons/800F8660_artillery_projectile_create.c.o .text 0xcc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CFA50_results_status_flags.c.o .text 0x34 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CF738_results_ready_flags_c.c.o .text 0x70 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CF58C_results_ready_flags_b.c.o .text 0x3c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CF3E0_results_ready_flags_a.c.o .text 0x3c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CF218_results_option_codes.c.o .text 0x40 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CF198_results_return.c.o .text 0x80 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CF0CC_results_continue.c.o .text 0xcc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CE814_results_screen_setup.c.o .text 0x18c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CE188_results_time_compare.c.o .text 0x488 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CDD70_results_time_format.c.o .text 0x418 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CD85C_results_record_write.c.o .text 0x110 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CB1E4_controls_button_index_map.c.o .text 0x150 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CB110_results_assets_load.c.o .text 0xd4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CB0C0_race_widget_flag_set.c.o .text 0x4c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CAFA8_race_widget_reset.c.o .text 0x118 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CAED0_race_widget_clear.c.o .text 0xd8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CAD9C_race_widget_values.c.o .text 0x134 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CABC0_race_player_widget.c.o .text 0x1dc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CAB44_race_flag_queries.c.o .text 0x7c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CAA0C_race_popup_show.c.o .text 0x3c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CA3F0_race_timer_queries.c.o .text 0xb0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CA1A8_race_player_reset.c.o .text 0x114 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C98D8_race_display_value_set.c.o .text 0x10 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C962C_race_player_pair_set.c.o .text 0x54 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C95A0_race_player_message.c.o .text 0x8c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C9130_race_player_panel.c.o .text 0x11c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C98E8_race_bar_update.c.o .text 0x154 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C98E8_race_bar_update.c.o .rodata 0x4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C8EDC_race_slot_clear.c.o .text 0x24 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C8238_race_event_push.c.o .text 0x118 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C7514_race_state_reset.c.o .text 0x80 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C73A8_race_object_timestamps.c.o .text 0x104 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C726C_race_result_setup.c.o .text 0x13c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C6D68_race_hud_init.c.o .text 0x504 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C6920_race_assets_load.c.o .text 0x448 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C6844_hud_page_close.c.o .text 0x68 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C67BC_hud_page_open.c.o .text 0x88 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C6790_hud_page_show.c.o .text 0x2c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C674C_hud_page_exit_request.c.o .text 0x44 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C6544_hud_page_focus.c.o .text 0x70 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C4F98_hud_slot_icons_update.c.o .text 0xba4 --alignment 4
# Trim KMC tail padding so .rodata is exactly the original range (unit_rodata.tsv).
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C4F98_hud_slot_icons_update.c.o .rodata 0xe0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800EFB90_effect_message_damage_guarded.c.o .text 0x6c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800EFB90_effect_message_damage_guarded.c.o .rodata 0xfc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800F3F78_mesh_rings_draw.c.o .text 0xdfc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800F3F78_mesh_rings_draw.c.o .rodata 0x4c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/weapons/800F872C_artillery_target_track.c.o .text 0x380 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/weapons/800F872C_artillery_target_track.c.o .rodata 0x1c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/800F8264_model_in_draw_range.c.o .text 0x154 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/800F8264_model_in_draw_range.c.o .rodata 0x4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800F80A0_static_in_radius.c.o .text 0x48 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800F80A0_static_in_radius.c.o .rodata 0x4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800F7A80_spark_burst_update.c.o .text 0x124 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800F7A80_spark_burst_update.c.o .rodata 0x10 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/800F7870_anim_alpha_fade_draw.c.o .text 0x12c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/800F7870_anim_alpha_fade_draw.c.o .rodata 0x8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800F6650_generator_spawn.c.o .text 0x178 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800F5B3C_effect_beam_draw.c.o .text 0x2dc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800F577C_effect_burn_update.c.o .text 0x3c0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800F577C_effect_burn_update.c.o .rodata 0x10 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800F5548_effect_targets_damage.c.o .text 0x234 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800F5470_effect_targets_query.c.o .text 0xd8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800F5298_effect_prop_spawn.c.o .text 0x1d8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800F50B8_tracer_trail_update.c.o .text 0x1ac --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800F4D80_mesh_wave_update.c.o .text 0x270 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800F4D80_mesh_wave_update.c.o .rodata 0x2c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800F352C_barrel_explode.c.o .text 0x1a4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800F352C_barrel_explode.c.o .rodata 0x4c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800F2DB4_powerup_timer_update.c.o .text 0x2e4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800F2DB4_powerup_timer_update.c.o .rodata 0x20 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800F2980_mine_trigger_update.c.o .text 0x238 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800F2980_mine_trigger_update.c.o .rodata 0xc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800F2288_hazard_message_handler.c.o .text 0x270 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800F2288_hazard_message_handler.c.o .rodata 0x18 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800F24F8_object_state_query.c.o .text 0x164 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800F24F8_object_state_query.c.o .rodata 0xc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800F2050_hazard_model_draw.c.o .text 0x134 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800F1D94_hazard_state_update.c.o .text 0x2bc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800F1D94_hazard_state_update.c.o .rodata 0x20 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/800F17B0_anim_keyframes_apply.c.o .text 0x150 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/800F17B0_anim_keyframes_apply.c.o .rodata 0x8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800F7650_effect_motion_update.c.o .text 0x220 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800F7650_effect_motion_update.c.o .rodata 0x30 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800F11D0_particle_owner_message.c.o .text 0xa8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800F11D0_particle_owner_message.c.o .rodata 0x4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800F0ED0_particle_system_create.c.o .text 0x300 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800F0ED0_particle_system_create.c.o .rodata 0x4c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800F0B08_particle_hit_spawn.c.o .text 0x3c8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800F0B08_particle_hit_spawn.c.o .rodata 0x1c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800F0658_particle_smoke_update.c.o .text 0x2d8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800F0658_particle_smoke_update.c.o .rodata 0x14 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800EFEC4_particle_emitter_free.c.o .text 0x1a0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800EFEC4_particle_emitter_free.c.o .rodata 0x4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800EE8C0_prop_height_update.c.o .text 0x21c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800EE7F8_prop_spawn_pickup.c.o .text 0xc8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800EE688_prop_spawn_child.c.o .text 0x170 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800EE490_motion_scale_curve.c.o .text 0x1f8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800EE490_motion_scale_curve.c.o .rodata 0x18 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800F0A20_rotated_texture_coords.c.o .text 0xe8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800F0A20_rotated_texture_coords.c.o .rodata 0xc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800F6C70_effect_billboard_draw.c.o .text 0x260 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800ED0AC_shockwave_expand.c.o .text 0x104 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/weapons/800ECEBC_projectile_shell_draw.c.o .text 0x154 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800EC4A8_mission_objectives_update.c.o .text 0x284 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800EB7BC_impact_debris_spray.c.o .text 0x7c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800EA714_mission_marker_draw.c.o .text 0x1e0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800EA714_mission_marker_draw.c.o .rodata 0x60 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800EA14C_mission_targets_query.c.o .text 0xd8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800E9E80_mission_props_spawn.c.o .text 0x2cc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800E96B4_mission_flag_set.c.o .text 0x244 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800E944C_mission_code_parse.c.o .text 0x268 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/runtime/800E8090_game_team_compare.c.o .text 0x64 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800E80F4_multiplayer_actor_spawn.c.o .text 0x1b8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800E7F60_pickup_find_by_id.c.o .text 0xec --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800E75F4_pending_spawns_flush.c.o .text 0x174 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800E75F4_pending_spawns_flush.c.o .rodata 0x4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800E713C_crate_contents_spawn.c.o .text 0x274 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800E68BC_crate_owner_check.c.o .text 0x248 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800E68BC_crate_owner_check.c.o .rodata 0x8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800E6040_bridge_piece_spawn.c.o .text 0x1a8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800E6040_bridge_piece_spawn.c.o .rodata 0xc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800E58D0_bridge_segments_init.c.o .text 0x2e8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800E58D0_bridge_segments_init.c.o .rodata 0x18 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/audio/800E51E8_sound_emitter_draw.c.o .text 0x444 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/audio/800E51E8_sound_emitter_draw.c.o .rodata 0x14 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800E4F3C_actor_wreck_spawn_at.c.o .text 0x228 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800E4F3C_actor_wreck_spawn_at.c.o .rodata 0x8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800E4B84_flag_owner_score.c.o .text 0x21c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800E48E0_flag_owner_capture.c.o .text 0x2a4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800E4530_object_damage.c.o .text 0xfc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800E2E0C_wreck_ctl.c.o .text 0x190 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800E2AEC_turret_spawn_at.c.o .text 0x288 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800E2AEC_turret_spawn_at.c.o .rodata 0x8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800E29A4_wreck_spawn.c.o .text 0x148 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800E2810_target_search.c.o .text 0x194 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800E2810_target_search.c.o .rodata 0x4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800DF758_slot_entry_lookup.c.o .text 0x48 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800DF63C_slot_angle_classify.c.o .text 0x11c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800DF558_slot_entity_attach.c.o .text 0xe4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800DF0D0_slot_corners_build.c.o .text 0x26c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800DE7E8_spawner_message_handler.c.o .text 0x148 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800DE748_spawner_owner_score.c.o .text 0xa0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800DE52C_spawner_state_update.c.o .text 0x21c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800DE2FC_structure_owner_award.c.o .text 0x78 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800DDF04_structure_model_draw.c.o .text 0x3f8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800DDF04_structure_model_draw.c.o .rodata 0x68 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800DD6F4_structure_flicker_roll.c.o .text 0x68 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800DD6F4_structure_flicker_roll.c.o .rodata 0x8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/weapons/800DC968_projectile_fire.c.o .text 0x770 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/weapons/800DC968_projectile_fire.c.o .rodata 0x2c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/weapons/800DC7B0_projectile_life_tick.c.o .text 0x54 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/weapons/800DC7B0_projectile_life_tick.c.o .rodata 0x8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/weapons/800DAC34_projectile_bounce.c.o .text 0x57c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/weapons/800DAC34_projectile_bounce.c.o .rodata 0x38 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/800D9B50_model_bounds_compute.c.o .text 0xe8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800D9900_minimap_blips_spawn.c.o .text 0x188 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800D9900_minimap_blips_spawn.c.o .rodata 0x24 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800D942C_trigger_particles_update.c.o .text 0x3c0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800D942C_trigger_particles_update.c.o .rodata 0x40 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800D92E0_trigger_particles_spawn.c.o .text 0x14c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800D92E0_trigger_particles_spawn.c.o .rodata 0x38 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800D8F48_single_spawn_timer_update.c.o .text 0x278 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800D8F48_single_spawn_timer_update.c.o .rodata 0x8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800D8C60_turret_spawn_random.c.o .text 0x2c8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800D8C60_turret_spawn_random.c.o .rodata 0x8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800D8A80_turret_model_draw.c.o .text 0x1e0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800D89F8_turret_random_slot.c.o .text 0x88 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800D8940_turret_weighted_pick.c.o .text 0xb8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800D88F0_turret_weights_total.c.o .text 0x50 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800D8758_turret_state_messages.c.o .text 0x190 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800D8758_turret_state_messages.c.o .rodata 0x18 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800D84DC_actor_message_handler.c.o .text 0x198 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800D84DC_actor_message_handler.c.o .rodata 0xc8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800D8380_actor_timer_update.c.o .text 0x158 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800D8088_actor_model_draw.c.o .text 0x2f8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800D7DE0_effect_node_spawn.c.o .text 0x270 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/player/800D7638_player_menu_draw.c.o .text 0x6bc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/player/800D7544_player_cursor_anim.c.o .text 0xf4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/player/800D6EEC_player_menu_update.c.o .text 0x658 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800D6B80_effect_code_parse.c.o .text 0x2b4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800D69E0_effect_code_table.c.o .text 0x1a0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800D67F0_effect_draw.c.o .text 0x1f0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/script/800D5C80_script_particle_spawn.c.o .text 0x1ac --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/script/800D5C80_script_particle_spawn.c.o .rodata 0xc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800D56FC_hud_draw_list.c.o .text 0x580 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800D56FC_hud_draw_list.c.o .rodata 0x4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/script/800D53D4_script_event_finish.c.o .text 0x134 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/script/800D53D4_script_event_finish.c.o .rodata 0xd8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/script/800D441C_seq_command_dispatch.c.o .text 0x73c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/script/800D441C_seq_command_dispatch.c.o .rodata 0xc8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/script/800D404C_seq_spawn_events_update.c.o .text 0x3d0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/script/800D404C_seq_spawn_events_update.c.o .rodata 0xc8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/script/800D31DC_seq_event_script_tick.c.o .text 0x378 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/script/800D31DC_seq_event_script_tick.c.o .rodata 0xec --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/script/800D2B44_seq_spawn_script_tick.c.o .text 0x698 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/script/800D2B44_seq_spawn_script_tick.c.o .rodata 0xf0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/script/800D25E0_seq_script_tick.c.o .text 0x564 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/script/800D25E0_seq_script_tick.c.o .rodata 0xc8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800D1C90_spawn_object_command.c.o .text 0x87c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800D1C90_spawn_object_command.c.o .rodata 0x18c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800D1234_spawn_counters.c.o .text 0x7c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800D1140_spawn_nearest_type31.c.o .text 0xf4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800D1140_spawn_nearest_type31.c.o .rodata 0x4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800D104C_spawn_nearest_type28.c.o .text 0xf4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800D104C_spawn_nearest_type28.c.o .rodata 0x4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800D0F58_spawn_nearest_type1.c.o .text 0xf4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800D0F58_spawn_nearest_type1.c.o .rodata 0x4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800D09E0_hud_element_alloc.c.o .text 0x94 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800D05E0_hud_element_unlink.c.o .text 0x234 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CFBD8_results_columns_draw.c.o .text 0x140 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CFBD8_results_columns_draw.c.o .rodata 0x4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CF7A8_results_time_tick.c.o .text 0x2a8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CF7A8_results_time_tick.c.o .rodata 0x4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CF690_results_bonus_finish.c.o .text 0xa8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CF690_results_bonus_finish.c.o .rodata 0x4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CF5C8_results_bonus_tick.c.o .text 0xc8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CF5C8_results_bonus_tick.c.o .rodata 0x4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CF4E4_results_score_finish.c.o .text 0xa8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CF4E4_results_score_finish.c.o .rodata 0x4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CF41C_results_score_tick.c.o .text 0xc8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CF41C_results_score_tick.c.o .rodata 0x4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CF32C_results_deaths_tick.c.o .text 0xb4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CF32C_results_deaths_tick.c.o .rodata 0x8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CF258_results_kills_tick.c.o .text 0xd4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CF258_results_kills_tick.c.o .rodata 0x8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CCEC4_controller_slot_find.c.o .text 0x6b8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CCEC4_controller_slot_find.c.o .rodata 0x2c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CCA6C_controller_queue_push.c.o .text 0x458 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CCA6C_controller_queue_push.c.o .rodata 0x28 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CC574_controller_menu_input.c.o .text 0x4f8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CC574_controller_menu_input.c.o .rodata 0x28 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CC2F8_controller_slots_scan.c.o .text 0x27c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CA2BC_race_lap_times_clamp.c.o .text 0x134 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C8B74_race_player_icons_draw.c.o .text 0x368 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C8B74_race_player_icons_draw.c.o .rodata 0x10 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C8484_race_timer_update.c.o .text 0x2f8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C8484_race_timer_update.c.o .rodata 0x10 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C877C_race_marker_project.c.o .text 0x3f8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C877C_race_marker_project.c.o .rodata 0x28 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C7C10_race_map_draw.c.o .text 0x628 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C7C10_race_map_draw.c.o .rodata 0x34 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C74AC_race_state_init.c.o .text 0x68 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C0D00_hud_volume_adjust.c.o .text 0x394 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C0D00_hud_volume_adjust.c.o .rodata 0xC --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C30B4_hud_controls_page.c.o .text 0xF78 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C30B4_hud_controls_page.c.o .rodata 0x1D0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C65B4_hud_page_next.c.o .text 0x198 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CBE40_controller_save_slots.c.o .text 0x4B8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C7AA0_race_start_check.c.o .text 0x170 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C7AA0_race_start_check.c.o .rodata 0x34 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C7650_race_frame_border_draw.c.o .text 0x450 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C7650_race_frame_border_draw.c.o .rodata 0x14 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C68AC_hud_value_to_byte.c.o .text 0x68 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C68AC_hud_value_to_byte.c.o .rodata 0x8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C6280_hud_panel_select.c.o .text 0x2c4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C6280_hud_panel_select.c.o .rodata 0x1c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C5FB4_hud_panel_refresh.c.o .text 0x2cc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C5FB4_hud_panel_refresh.c.o .rodata 0x20 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C5D80_hud_panel_layout.c.o .text 0x234 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C5D80_hud_panel_layout.c.o .rodata 0x20 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C5B3C_hud_mode_cycle.c.o .text 0x244 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C5B3C_hud_mode_cycle.c.o .rodata 0x20 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C4594_hud_marker_update.c.o .text 0x240 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C4594_hud_marker_update.c.o .rodata 0x14 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C402C_hud_player_slots_cycle.c.o .text 0x1e0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800EFB30_effect_message_damage.c.o .text 0x60 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800EFB30_effect_message_damage.c.o .rodata 0x100 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800EF578_effect_segments_draw.c.o .text 0x1f8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800EF578_effect_segments_draw.c.o .rodata 0x40 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800EF400_effect_segment_append.c.o .text 0x178 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800EF400_effect_segment_append.c.o .rodata 0x1c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800EDF14_prop_message_shatter.c.o .text 0x19c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800EDF14_prop_message_shatter.c.o .rodata 0xbc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/800ED698_model_message_damage_destroy.c.o .text 0x98 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/800ED698_model_message_damage_destroy.c.o .rodata 0x100 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/800EB4FC_model_shielded_dispatch.c.o .text 0x218 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/800EB4FC_model_shielded_dispatch.c.o .rodata 0xfc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/800EAA7C_model_turret_dispatch.c.o .text 0x1b0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/800EAA7C_model_turret_dispatch.c.o .rodata 0xfc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/800EA8F4_model_message_damage_u8.c.o .text 0x70 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/800EA8F4_model_message_damage_u8.c.o .rodata 0x100 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/800E9CAC_model_mode_objective_message.c.o .text 0x1a0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/800E9CAC_model_mode_objective_message.c.o .rodata 0x2c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/800E9B50_model_pickup_create.c.o .text 0x15c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/800E9B50_model_pickup_create.c.o .rodata 0x38 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800E918C_slot_mode_value_get.c.o .text 0x15c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800E918C_slot_mode_value_get.c.o .rodata 0x6c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800E9030_slot_mode_description_get.c.o .text 0x15c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800E9030_slot_mode_description_get.c.o .rodata 0x70 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800E8F90_slot_mode_subtitle_get.c.o .text 0xa0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800E8F90_slot_mode_subtitle_get.c.o .rodata 0x20 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800E8E34_slot_mode_title_get.c.o .text 0x15c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800E8E34_slot_mode_title_get.c.o .rodata 0x70 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800E8C88_slot_mode_name_get.c.o .text 0x1ac --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800E8C88_slot_mode_name_get.c.o .rodata 0x70 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800E8380_slot_asset_ranges.c.o .text 0x908 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800E8380_slot_asset_ranges.c.o .rodata 0x70 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800E44C8_wreck_message_hit.c.o .text 0x68 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800E44C8_wreck_message_hit.c.o .rodata 0xbc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/player/800E1A4C_player_dispatch.c.o .text 0x158 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/player/800E1A4C_player_dispatch.c.o .rodata 0xfc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/player/800E18D8_player_message_hit.c.o .text 0xa8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/player/800E18D8_player_message_hit.c.o .rodata 0x100 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800DF3B8_slot_condition_check.c.o .text 0x1a0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800DF3B8_slot_condition_check.c.o .rodata 0xb8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/script/800D12B0_script_command_decode.c.o .text 0x9e0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/script/800D12B0_script_command_decode.c.o .rodata 0xf8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/script/800D3C64_seq_point_track.c.o .text 0x3e8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/script/800D3C64_seq_point_track.c.o .rodata 0xc0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/script/800D5E2C_script_particle_update.c.o .text 0x6dc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800D9D50_debris_spawn.c.o .text 0x488 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800D9D50_debris_spawn.c.o .rodata 0x5c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800DA1D8_debris_piece_update.c.o .text 0x168 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800DA1D8_debris_piece_update.c.o .rodata 0x4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800DA7D0_debris_group_spawn.c.o .text 0x1b4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800DA7D0_debris_group_spawn.c.o .rodata 0x4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/weapons/800DAAE0_projectile_spawn.c.o .text 0x154 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/weapons/800DB1B0_projectile_segment_spawn.c.o .text 0x538 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/weapons/800DB1B0_projectile_segment_spawn.c.o .rodata 0x70 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800DB6F0_track_angle_unit.c.o .text 0xb24 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800DB6F0_track_angle_unit.c.o .rodata 0xfc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800DD75C_structure_hit_dispatch.c.o .text 0xd0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800DD82C_structure_debris_spawn.c.o .text 0x6d8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800DD82C_structure_debris_spawn.c.o .rodata 0x70 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800DE374_structure_message.c.o .text 0x168 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800DE374_structure_message.c.o .rodata 0xfc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/script/800DF89C_entry_helpers.c.o .text 0x1c0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/vehicles/8008C5D8_tank_fire_weapon.c.o .text 0x2048 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/vehicles/8008C5D8_tank_fire_weapon.c.o .rodata 0x16c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800E16D8_foliage_prop_destroy.c.o .text 0x200 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800E16D8_foliage_prop_destroy.c.o .rodata 0x8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800E1BB0_turret_sweep.c.o .text 0x468 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800E1BB0_turret_sweep.c.o .rodata 0x18 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800E2520_turret_message_handlers.c.o .text 0x188 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800E2F9C_wreck_update.c.o .text 0x468 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800E2F9C_wreck_update.c.o .rodata 0x8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800E3FDC_entity_model_draw.c.o .text 0x4ec --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800E48A8_flag_position_query.c.o .text 0x38 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800E4DA0_flag_message_dispatch.c.o .text 0x12c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800E4DA0_flag_message_dispatch.c.o .rodata 0xbc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800E66A8_crate_particle_attach.c.o .text 0x214 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800E6B04_crate_unit.c.o .text 0x638 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800E6B04_crate_unit.c.o .rodata 0x8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800E73B0_crate_part_release.c.o .text 0x1ec --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800E7768_crate_burst_spawn.c.o .text 0x200 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800E7768_crate_burst_spawn.c.o .rodata 0xc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800E7A10_powerup_flag_messages.c.o .text 0x3e8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800E7A10_powerup_flag_messages.c.o .rodata 0x1c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/script/800D5508_seq_events_update.c.o .text 0x1f4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/script/800D5508_seq_events_update.c.o .rodata 0xd8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/script/800D520C_seq_level_header_load.c.o .text 0x1c8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/script/800D520C_seq_level_header_load.c.o .rodata 0x68 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/script/800D4DE0_seq_script_load.c.o .text 0x42c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/script/800D4DE0_seq_script_load.c.o .rodata 0x20 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/script/800D4B58_seq_event_start.c.o .text 0x1a8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/script/800D4B58_seq_event_start.c.o .rodata 0xd8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/script/800D3554_seq_event_spawn_tick.c.o .text 0x710 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/script/800D3554_seq_event_spawn_tick.c.o .rodata 0x240 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800D0DF8_spawn_effect_by_type.c.o .text 0x160 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800D0DF8_spawn_effect_by_type.c.o .rodata 0x2c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CB934_controls_bindings_load.c.o .text 0x50c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CB934_controls_bindings_load.c.o .rodata 0x9c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CB334_controls_bindings_save.c.o .text 0x600 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CB334_controls_bindings_save.c.o .rodata 0x28 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CA4A0_race_slot_set_digit.c.o .text 0x180 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CA4A0_race_slot_set_digit.c.o .rodata 0x20 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C975C_race_player_set_mode_icon.c.o .text 0x17c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C975C_race_player_set_mode_icon.c.o .rodata 0x3c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C9680_race_mode_icon_get.c.o .text 0xdc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C9680_race_mode_icon_get.c.o .rodata 0x40 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C924C_race_player_set_layout.c.o .text 0x354 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C924C_race_player_set_layout.c.o .rodata 0x40 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C9010_race_type_name_lookup.c.o .text 0x120 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C9010_race_type_name_lookup.c.o .rodata 0x40 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C8F00_race_player_set_vehicle_label.c.o .text 0x110 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C8F00_race_player_set_vehicle_label.c.o .rodata 0x30 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C4B24_hud_entry_set_label.c.o .text 0x90 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C4B24_hud_entry_set_label.c.o .rodata 0x20 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C48F0_hud_menu_entries_apply_settings.c.o .text 0x1cc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C48F0_hud_menu_entries_apply_settings.c.o .rodata 0x60 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/runtime/800C4F50_game_mode8_toggled.c.o .text 0x48 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C4E24_hud_page_focus_cycle.c.o .text 0x12c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C4ABC_hud_page_select.c.o .text 0x68 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C48C4_hud_alt_exit_request.c.o .text 0x2c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C485C_hud_list_close.c.o .text 0x68 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C47D4_hud_list_open.c.o .text 0x88 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C434C_hud_list_focus_cycle.c.o .text 0x248 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C42E4_hud_list_refresh.c.o .text 0x68 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C42A0_hud_exit_request.c.o .text 0x44 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C425C_hud_row_defaults.c.o .text 0x44 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C420C_hud_row_preset.c.o .text 0x50 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/runtime/8009EEA0_game_queue.c.o .text 0x38 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/8009F064_matrix_state.c.o .text 0x2c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C0850_menu_state.c.o .text 0x90 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/8009D144_mode_range.c.o .text 0x24 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/math/8009D6DC_angle_subtract.c.o .text 0x1c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/math/8009D72C_angle_between.c.o .text 0x30 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/math/8009D81C_angle_distance.c.o .text 0x34 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/math/8009D578_angle_fold.c.o .text 0x3c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/math/8009D850_angle_direction.c.o .text 0x50 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/8009DB0C_vector2_scale.c.o .text 0x20 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/8007B65C_render_submit.c.o .text 0x290 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/runtime/8007BCF0_asset_load.c.o .text 0x10c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/8007BDFC_video_mode.c.o .text 0xf4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/8007BEF0_texture_tile.c.o .text 0x474 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/8007D470_small_state.c.o .text 0x90 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/8007D558_small_state_copy.c.o .text 0x58 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/collision/8007D694_collision_noop.c.o .text 0x8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/runtime/8007D710_state_noop.c.o .text 0x8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/runtime/8007D720_state_modes.c.o .text 0xa4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/collision/8007E1FC_collision_fields.c.o .text 0x14 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/8007E778_object_query.c.o .text 0x30 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/80081FD8_object_defaults.c.o .text 0x2c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/80082B40_mode_owner.c.o .text 0x28 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/80082BD4_mode_transition.c.o .text 0x48 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/80082D60_pair_queue.c.o .text 0x38 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/80082FE0_object_disable.c.o .text 0x48 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/80083FCC_object_predicates.c.o .text 0x2c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/80084C50_object_direction.c.o .text 0x78 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800859A8_object_action.c.o .text 0x3c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/8009C284_session_queries.c.o .text 0x98 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/80098BC8.c.o .text 0x30 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/player/8009B35C_player_state_modes.c.o .text 0xd8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/8009B62C.c.o .text 0x68 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/math/8009D914_random_integer.c.o .text 0x4c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/8009DA34_vector2.c.o .text 0x7c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/8009E044_vector2_motion.c.o .text 0xa4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/8009EEE0_matrix_basic.c.o .text 0x6c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/8009F768_matrix_transform.c.o .text 0x138 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800A0750_lzari_decode.c.o .text 0x9f4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/8009FF1C_vector2_rotate.c.o .text 0x9c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/8009F1F4_matrix_vector.c.o .text 0x140 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/8009F4B4_matrix_multiply.c.o .text 0xf8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/runtime/800A1280_scheduler_context.c.o .text 0x10 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/runtime/800A134C_scheduler_state.c.o .text 0x38 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/runtime/800A179C_scheduler_events.c.o .text 0x134 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/runtime/800A1A28_scheduler_queue.c.o .text 0x11c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/runtime/800A2DFC_scheduler_misc.c.o .text 0x60 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800A4098_object_timing.c.o .text 0x34 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800A6ABC_object_setters.c.o .text 0xc0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800A7290_object_init.c.o .text 0x30 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800B044C.c.o .text 0x94 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800B04E0.c.o .text 0x114 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800B05F4.c.o .text 0xb4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800B06E0.c.o .text 0x690 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800B06E0.c.o .rodata 0xe4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/collision/800B0F4C_grid_node_remove.c.o .text 0x150 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800B109C.c.o .text 0x200 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800B14A8.c.o .text 0x168 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800B1610.c.o .text 0x58 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800B1668.c.o .text 0x230 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800B1DA8.c.o .text 0x550 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800B2364.c.o .text 0x124 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800B2890.c.o .text 0x788 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800B3368.c.o .text 0x94 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800B3504.c.o .text 0x244 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/collision/800B4684_collision_query.c.o .text 0x35c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/collision/800B4684_collision_query.c.o .rodata 0x10 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800B4F38.c.o .text 0x1f8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800B5A10.c.o .text 0x17c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800B5A10.c.o .rodata 0xc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/vehicles/800B5B8C_mover_reflect.c.o .text 0xbc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800B5D1C.c.o .text 0x8c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800B5DA8.c.o .text 0x188 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/vehicles/800B5F70_mover_collision_response.c.o .text 0x248 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800B61B8.c.o .text 0x528 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800B61B8.c.o .rodata 0x14 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/collision/800B739C_contact_side_test.c.o .text 0x118 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/math/800B8310_vector_angle_from_xy.c.o .text 0x98 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800B9E24.c.o .text 0x90 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800B9EB4.c.o .text 0x90 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800B9FD4.c.o .text 0x1e8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800BA330_world_resource_aggregate.c.o .text 0x390 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800BA6C0_world_loader.c.o .text 0xbe0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800BB2A0_world_bundle_resource_aggregate.c.o .text 0x29c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/800BB53C_common_model_loader.c.o .text 0x880 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800BBDC0.c.o .text 0x1ac0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800BBDC0.c.o .rodata 0x70 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800BD93C.c.o .text 0xf4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800BDAF8.c.o .text 0x1314 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800BDAF8.c.o .rodata 0x88 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800BEE0C.c.o .text 0x1f4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800BF798.c.o .text 0x74 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800AA8A8.c.o .text 0x238 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800AAAE0.c.o .text 0x134 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800AAAE0.c.o .rodata 0x4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800AAC14.c.o .text 0x28c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800AB4DC.c.o .text 0xb0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800AC0F4.c.o .text 0xa4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800ACE70.c.o .text 0x44 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800ACEB4.c.o .text 0x48 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800ACEFC.c.o .text 0x24 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800AD14C.c.o .text 0x55c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800AD14C.c.o .rodata 0x28 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800AE710.c.o .text 0x1dc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800AF364.c.o .text 0xd8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800B0268.c.o .text 0x6c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800B03F4.c.o .text 0x50 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800A8E3C.c.o .text 0x48 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800A9080.c.o .text 0x5e0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800A977C.c.o .text 0x80 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800A98B8.c.o .text 0x70 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800A9B64.c.o .text 0x84 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800A9C24.c.o .text 0xa8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800A9CCC.c.o .text 0x84 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800A9F10.c.o .text 0x148 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800A16F8.c.o .text 0xa4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800A1BE0.c.o .text 0x574 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/runtime/800A2154_task_message_broadcast.c.o .text 0x178 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800A2E5C.c.o .text 0x90 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800A2FBC.c.o .text 0x5a4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800A2FBC.c.o .rodata 0x18 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800A3758.c.o .text 0x940 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800A3758.c.o .rodata 0x28 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800A40CC_effect_sprite_key_draw.c.o .text 0x1fc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800A40CC_effect_sprite_key_draw.c.o .rodata 0x8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800A42C8_effect_sprite_ring_draw.c.o .text 0x1a0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/effects/800A42C8_effect_sprite_ring_draw.c.o .rodata 0x8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800A477C.c.o .text 0x10dc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800A477C.c.o .rodata 0x80 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800A5BD8.c.o .text 0x508 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800A5BD8.c.o .rodata 0x40 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800A61A0.c.o .text 0x180 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800A61A0.c.o .rodata 0x4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800A6320_camera_collision_resolve.c.o .text 0x268 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800A6320_camera_collision_resolve.c.o .rodata 0x28 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800A6588.c.o .text 0x534 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800A6588.c.o .rodata 0x2c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800A6C20_spotter_update.c.o .text 0x3b0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800A6C20_spotter_update.c.o .rodata 0x8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800A6FD0_spotter_frame_setup.c.o .text 0x5c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800A702C.c.o .text 0x64 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/player/800A7664_player_perspective_update.c.o .text 0x130 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800A7794.c.o .text 0x14 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800A8690.c.o .text 0x12c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800A87BC.c.o .text 0x1f4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800A89B0.c.o .text 0xc8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800A8A78_camera_view_select.c.o .text 0x9c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800A8B38_camera_mode_update.c.o .text 0x21c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800A8B38_camera_mode_update.c.o .rodata 0x3c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800A9D78_light_display_list_build.c.o .text 0x148 --alignment 4
for spec in \
    path/80082D98_path_sequence_init:0x184 unknown/80082F1C:0x7c unknown/80082F98:0x48 \
    gameplay/80096A54_font_glyph_draw:0x188 gameplay/80096E14_font_hex_draw:0x134 \
    unknown/80094F40:0x38 unknown/80094F78:0x44 \
    unknown/80095B50:0x18 unknown/80095B68:0x28 unknown/80095B90:0x54 \
    unknown/80095BE4:0x6c unknown/80095E7C:0x8c unknown/80096250:0x44 \
    unknown/8009660C:0xc8 unknown/800967F0:0x20 \
    unknown/80097508:0x28 unknown/80097530:0x2c \
    unknown/80097660:0x4c unknown/800976AC:0xe8 unknown/80097794:0x48 \
    unknown/800977DC:0x68 unknown/80097844:0xc8 unknown/8009790C:0x94 \
    unknown/800979A0:0x54 unknown/800979F4:0x78 unknown/80097A6C:0xb4 \
    unknown/80097B20:0x24 unknown/80097B44:0x24 unknown/80097B68:0x3c \
    unknown/80097BA4:0x20 unknown/80097BC4:0x58 unknown/80097C1C:0x68 \
    unknown/80097C84:0x34 unknown/80097CB8:0x10 unknown/80097CC8:0x4c \
    audio/80097D14_music_stream_queue:0xe4 unknown/80097EE4:0xd0 \
    unknown/8009813C:0x44 unknown/80098180:0x10 unknown/80098190:0x50 \
    unknown/800981E0:0x70 unknown/80098250:0xe4 unknown/80098334:0x38 \
    unknown/8009836C:0xc4 unknown/80098430:0x24 unknown/80098534:0x68 \
    unknown/80098AFC:0x30 unknown/80098B2C:0x14 unknown/80098B40:0x18 \
    unknown/80098B58:0x70 unknown/80098BF8:0xd0 \
    unknown/80098F24:0x98 unknown/80098FBC:0x6c unknown/80099028:0x58 \
    unknown/80099080:0xe0 unknown/800992E0:0xd0 unknown/800993B0:0xb4 \
    unknown/800996C4:0x94 unknown/80099758:0x2c unknown/80099784:0xa0 \
    unknown/80099830:0x24 unknown/80099854:0x54 unknown/800998A8:0x40 \
    unknown/80099F74:0x74 unknown/8009A650:0xa0 unknown/8009A6F0:0x8 \
    unknown/8009AD7C:0xbc
do
    unit="${spec%%:*}"
    size="${spec##*:}"
    python3 tools/trim_elf32_section.py \
        "build/us/src/code/${unit}.c.o" .text "${size}" --alignment 4
done
for spec in \
    unknown/80094880:0x6c0:0xd0 \
    unknown/80094FBC:0xb94:0x40 \
    unknown/80095C50:0x22c:0x18 \
    unknown/80096294:0x378:0x1c \
    unknown/800966D4:0x11c:0 \
    unknown/80096810:0x244:0x188 \
    unknown/800973E0:0x128:0 \
    unknown/80097560:0x100:0 \
    unknown/80097DF8:0xec:0 \
    unknown/800985A0:0x55C:0 \
    unknown/80098CC8:0x25c:0 \
    unknown/800991CC:0x114:0 \
    unknown/80099464:0x260:0 \
    unknown/800998E8:0x68c:0 \
    unknown/80099FE8:0x4e0:0x8 \
    player/8009A4C8_player_order_shuffle:0x188:0 \
    unknown/8009A6F8:0x5e4:0x38 \
    unknown/8009AE38:0x2b8:0x8 \
    unknown/8009B434:0x1f8:0 \
    unknown/8009C098:0x1ec:0x8
do
    unit="${spec%%:*}"
    rest="${spec#*:}"
    text_size="${rest%%:*}"
    rodata_size="${rest##*:}"
    python3 tools/trim_elf32_section.py \
        "build/us/src/code/${unit}.c.o" .text "${text_size}" --alignment 4
    if [ "${rodata_size}" != 0 ]; then
        python3 tools/trim_elf32_section.py \
            "build/us/src/code/${unit}.c.o" .rodata "${rodata_size}" --alignment 4
    fi
done
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/8009C31C_progress_level_advance.c.o .text 0x208 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/8009277C_matrix_scale_curve.c.o .text 0x220 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/8009277C_matrix_scale_curve.c.o .rodata 0x48 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800B87A0.c.o .text 0xd0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/collision/800B8870_grid_node_height.c.o .text 0x6c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/collision/800B93A4_grid_height_query.c.o .text 0x224 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/math/8009D5B4_angle_table_lookup.c.o .text 0x128 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/math/8009D5B4_angle_table_lookup.c.o .rodata 0x18 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/math/800B02D4_bounds_pair.c.o .text 0x120 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/800B9AB0_model_player_color.c.o .text 0x1b8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800A8B14_object_reset.c.o .text 0x24 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800A9054_object_flags.c.o .text 0x2c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800A974C_object_limit.c.o .text 0x30 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800A9BF0_object_table_color.c.o .text 0x34 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800A9D50_object_table_reset.c.o .text 0x28 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800AA598_object_table_lookup.c.o .text 0x2c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800B0444_gameplay_stub.c.o .text 0x8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800B5F30_turn_adjust.c.o .text 0x40 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800BFD40_hud_state.c.o .text 0x64 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800BF204_hud_tree_update.c.o .text 0x1e8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800BF000_hud_tree_remove.c.o .text 0x130 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C7594_race_mode_query.c.o .text 0xbc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C8350_race_hud_layout.c.o .text 0x134 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CD57C_controller_menu_state.c.o .text 0x2e0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800BFEA0_race_assets_init.c.o .text 0x550 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CD970_results_menu_callbacks.c.o .text 0x26c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CE610_results_panel_setup.c.o .text 0x204 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CE9A0_results_split_setup.c.o .text 0x72C --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/entities/800D0858_spawn_color_lookup.c.o .text 0x108 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C12B4_hud_key_nav.c.o .text 0x108 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C16B0_hud_slots_layout.c.o .text 0x118 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C1F08_controls_preset.c.o .text 0x2a4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C1938_controls_config.c.o .text 0x510 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C2284_hud_binding_select.c.o .text 0x1f8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800BF484_hud_tree_draw.c.o .text 0x314 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800BF484_hud_tree_draw.c.o .rodata 0x8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800BF80C_hud_frame.c.o .text 0x498 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800BF80C_hud_frame.c.o .rodata 0x10 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C041C_hud_mode_table.c.o .text 0xac --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C041C_hud_mode_table.c.o .rodata 0x20 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C0608_hud_mode_cycle_full.c.o .text 0x1f8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C0608_hud_mode_cycle_full.c.o .rodata 0x40 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C08E0_hud_exit_dispatch.c.o .text 0x184 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C08E0_hud_exit_dispatch.c.o .rodata 0x14 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C1484_hud_menu_open.c.o .text 0xf4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C1484_hud_menu_open.c.o .rodata 0x4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C2528_hud_option_select.c.o .text 0x2c4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C2528_hud_option_select.c.o .rodata 0x18 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800EAEB4.c.o .text 0xb8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800EBF80.c.o .text 0x240 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800EC1F8.c.o .text 0x2b0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800EDDCC.c.o .text 0x148 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800F7230.c.o .text 0x33c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/unknown/800F7230.c.o .rodata 0x5c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C2924_hud_list_select_full.c.o .text 0x77c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C2924_hud_list_select_full.c.o .rodata 0xc0 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C4BB4_hud_player_page.c.o .text 0x270 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C4BB4_hud_player_page.c.o .rodata 0x40 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CAA48_race_popup_setup.c.o .text 0xfc --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CAA48_race_popup_setup.c.o .rodata 0x4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CFA84_results_bar_step.c.o .text 0x154 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CFA84_results_bar_step.c.o .rodata 0x10 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CFD18_results_rank_label.c.o .text 0xb8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CDBE0_results_time_text.c.o .text 0x190 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800CDBE0_results_time_text.c.o .rodata 0x1c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800D0070_cheat_codes.c.o .text 0x568 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800D0070_cheat_codes.c.o .rodata 0x84 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C0800_hud_modes.c.o .text 0x50 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C0A64_hud_stub.c.o .text 0x8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C1124_hud_secondary.c.o .text 0x14 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C1190_hud_primary_modes.c.o .text 0x28 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C1468_hud_transition.c.o .text 0x1c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/gameplay/800C17C8_registry_lookup.c.o .text 0x44 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C247C_hud_ready.c.o .text 0x28 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C24A4_hud_clear.c.o .text 0x58 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C27EC_hud_navigation.c.o .text 0x120 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/player/800B06A8_player_color.c.o .text 0x30 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/script/800BD880_entry_scan.c.o .text 0x38 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/world/800BA1BC_world_loader_ref_walkers.c.o .text 0x174 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C1138_hud_callbacks.c.o .text 0x58 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C1578_hud_panel_callback.c.o .text 0x2c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C24FC_hud_list_callback.c.o .text 0x2c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/script/800BD8B8_entry_flags.c.o .text 0x84 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C03F0_hud_root_callback.c.o .text 0x2c --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C0C18_hud_layout.c.o .text 0x20 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C15A4_hud_list_trigger.c.o .text 0x14 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C290C_hud_selection_apply.c.o .text 0x18 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C30A0_hud_primary_trigger.c.o .text 0x14 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C15B8_hud_entry_values.c.o .text 0x80 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/frontend/800C1638_hud_list_reset.c.o .text 0x78 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/800B99C0_display_registry.c.o .text 0x38 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/800B9A4C_display_color.c.o .text 0x64 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/src/code/render/800B9C68_display_commands.c.o .text 0x44 --alignment 4
mkdir -p build/us/src/libultra build/us/asm/us/libultra
tools/bootstrap_ultralib.sh
mkdir -p build/us/asm/us/boot
for boot_unit in entry host_break rmon_panic_stub; do
    "${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
        -o "build/us/asm/us/boot/${boot_unit}.s.o" \
        "src/boot/${boot_unit}.s"
    "${tool_prefix}objcopy" --set-section-alignment .text=4 \
        "build/us/asm/us/boot/${boot_unit}.s.o"
done
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/boot/exception_context_save.s.o \
    src/boot/exception_context_save.s
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/boot/exception_vector_install.s.o \
    src/boot/exception_vector_install.s
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/boot/exception_handler.s.o \
    src/boot/exception_handler.s
"${tool_prefix}objcopy" --set-section-alignment .text=4 \
    build/us/asm/us/boot/exception_context_save.s.o
"${tool_prefix}objcopy" --set-section-alignment .text=4 \
    build/us/asm/us/boot/exception_vector_install.s.o
"${tool_prefix}objcopy" --set-section-alignment .text=4 \
    build/us/asm/us/boot/exception_handler.s.o
python3 tools/trim_elf32_section.py \
    build/us/asm/us/boot/exception_context_save.s.o .text 0x304 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/asm/us/boot/exception_vector_install.s.o .text 0xC4 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/asm/us/boot/exception_handler.s.o .text 0x350 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/asm/us/boot/entry.s.o .text 0x38 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/asm/us/boot/host_break.s.o .text 0xB8 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/asm/us/boot/rmon_panic_stub.s.o .text 0x8 --alignment 4
"${tool_prefix}as" -EB -march=vr4300 -mabi=32 -I include \
    -o build/us/asm/us/boot/exception_preamble.s.o \
    src/boot/exception_preamble.s
"${tool_prefix}objcopy" --set-section-alignment .text=4 \
    build/us/asm/us/boot/exception_preamble.s.o
python3 tools/trim_elf32_section.py \
    build/us/asm/us/boot/exception_preamble.s.o .text 0x118 --alignment 4
.toolchain/ido5.3/cc -c -Wab,-r4300_mul -G 0 -nostdinc \
    -woff 516,649,838,712 -mips3 -32 -O1 -D_MIPS_SZLONG=32 \
    -DBUILD_VERSION=VERSION_I -D_FINALROM -DNDEBUG \
    -I.toolchain/ultralib/include -I.toolchain/ultralib/include/PR \
    -I.toolchain/ultralib/include/compiler/ido -I.toolchain/ultralib/src \
    -I.toolchain/ultralib/src/os \
    -o build/us/asm/us/libultra/exceptasm.s.o src/libultra/exceptasm.s
python3 tools/fix_ido_symtab.py build/us/asm/us/libultra/exceptasm.s.o --mips3-32
python3 tools/trim_elf32_section.py \
    build/us/asm/us/libultra/exceptasm.s.o .text 0x910 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/asm/us/libultra/exceptasm.s.o .rodata 0x44 --alignment 4
python3 tools/trim_elf32_section.py \
    build/us/asm/us/libultra/exceptasm.s.o .data 0x20 --alignment 4

# Handwritten libultra 2.0I routines are retained as their authentic source
# objects.  IDO assembles these files; they are not compiler-generated C.
while read -r unit text_size asopt; do
    unit_flags=()
    # The game also has an earlier private copy with the public SDK name.
    # Keep this object's already-established unique link symbol.
    if [[ "$unit" == "getsr" ]]; then
        unit_flags=(-D__osGetSR=__osGetSR_80105DA0)
    fi
    .toolchain/ido5.3/cc -c -Wab,-r4300_mul -G 0 -nostdinc \
        -woff 516,649,838,712 -mips2 -o32 "$asopt" \
        -D_MIPS_SZLONG=32 -DBUILD_VERSION=VERSION_I \
        '-DBUILD_VERSION_STRING="2.0I"' -D_FINALROM -non_shared \
        -I.toolchain/ultralib/include \
        -I.toolchain/ultralib/include/compiler/ido \
        -I.toolchain/ultralib/include/PR \
        -I.toolchain/ultralib/src -I.toolchain/ultralib/src/os \
        "${unit_flags[@]}" \
        -o "build/us/asm/us/libultra/${unit}.s.o" \
        "src/libultra/${unit}.s"
    python3 tools/fix_ido_symtab.py \
        "build/us/asm/us/libultra/${unit}.s.o"
    python3 tools/trim_elf32_section.py \
        "build/us/asm/us/libultra/${unit}.s.o" .text "$text_size" --alignment 4
done <<'LIBULTRA_ASM_UNITS'
bcopy 0x310 -O2
bzero 0xA0 -O2
getcount 0x10 -O1
getsr 0x10 -O1
interrupt 0x40 -O1
invaldcache 0xB0 -O1
invalicache 0x80 -O1
maptlbrdb 0x60 -O1
setfpccsr 0x10 -O1
setintmask 0xA0 -O1
setsr 0x10 -O1
sqrtf 0x10 -O1
setcompare 0x10 -O1
probetlb 0xC0 -O1
writebackdcache 0x80 -O1
writebackdcacheall 0x30 -O1
LIBULTRA_ASM_UNITS
python3 tools/trim_elf32_section.py \
    build/us/asm/us/libultra/setintmask.s.o .rodata 0x80 --alignment 4

.toolchain/ido5.3/cc -c -Wab,-r4300_mul -G 0 -nostdinc \
    -woff 516,649,838,712 -mips2 -32 -O1 -D_MIPS_SZLONG=32 \
    -DBUILD_VERSION=VERSION_I -D_FINALROM -DNDEBUG \
    -I.toolchain/ultralib/include -I.toolchain/ultralib/include/PR \
    -I.toolchain/ultralib/include/compiler/ido -I.toolchain/ultralib/src \
    -o build/us/src/libultra/libm_vals.c.o src/libultra/libm_vals.s
python3 tools/fix_ido_symtab.py build/us/src/libultra/libm_vals.c.o
python3 tools/trim_elf32_section.py \
    build/us/src/libultra/libm_vals.c.o .rodata 0x10 --alignment 4
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Xcpluscomm \
    -Isrc/libultra -o build/us/src/libultra/vitbl.c.o src/libultra/vitbl.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/os_pi_manager.c.o src/libultra/os_pi_manager.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/os_dev_mgr.c.o src/libultra/os_dev_mgr.c
python3 tools/trim_elf32_section.py \
    build/us/src/libultra/os_dev_mgr.c.o .text 0x490 --alignment 16
.toolchain/ido5.3/cc -c -O3 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/al_resample.c.o src/libultra/al_resample.c
.toolchain/ido5.3/cc -c -O3 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/al_reverb.c.o src/libultra/al_reverb.c
.toolchain/ido5.3/cc -c -O3 -mips2 -Wab,-r4300_mul -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/al_synthesizer.c.o src/libultra/al_synthesizer.c
.toolchain/ido5.3/cc -c -O3 -mips2 -Wab,-r4300_mul -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/al_syn_alloc_fx.c.o src/libultra/al_syn_alloc_fx.c
# Retail kept the final multiply before `jr ra` and aligned the following
# function to eight bytes. Apply that verified assembler layout exactly once.
python3 tools/insert_elf32_section_bytes.py \
    build/us/src/libultra/al_reverb.c.o .text _filterBuffer 4 \
    --unschedule-return
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/os_ai_set_frequency.c.o src/libultra/os_ai_set_frequency.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/os_ai_set_next_buffer.c.o src/libultra/os_ai_set_next_buffer.c
python3 tools/trim_elf32_section.py \
    build/us/src/libultra/os_ai_set_next_buffer.c.o .data 0x10 --alignment 4
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/os_cart_rom_init.c.o src/libultra/os_cart_rom_init.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/os_cont_query.c.o src/libultra/os_cont_query.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/os_cont_read_data.c.o src/libultra/os_cont_read_data.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/os_controller.c.o src/libultra/os_controller.c
python3 tools/trim_elf32_section.py \
    build/us/src/libultra/os_controller.c.o .data 0x10 --alignment 4
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_epi_raw_read_io.c.o src/libultra/os_epi_raw_read_io.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_epi_raw_write_io.c.o src/libultra/os_epi_raw_write_io.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_pi_raw_read_io.c.o src/libultra/os_pi_raw_read_io.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_pi_raw_start_dma.c.o src/libultra/os_pi_raw_start_dma.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_recv_mesg.c.o src/libultra/os_recv_mesg.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_send_mesg.c.o src/libultra/os_send_mesg.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_set_event_mesg.c.o src/libultra/os_set_event_mesg.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_set_thread_pri.c.o src/libultra/os_set_thread_pri.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_set_timer.c.o src/libultra/os_set_timer.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_sp_task_yielded.c.o src/libultra/os_sp_task_yielded.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_dp_set_next_buffer.c.o src/libultra/os_dp_set_next_buffer.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_si_raw_start_dma.c.o src/libultra/os_si_raw_start_dma.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_sp_raw_start_dma.c.o src/libultra/os_sp_raw_start_dma.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_dequeue_thread.c.o src/libultra/os_dequeue_thread.c
python3 tools/trim_elf32_section.py \
    build/us/src/libultra/os_dequeue_thread.c.o .data 0x20 --alignment 4
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_vi_black.c.o src/libultra/os_vi_black.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_vi_init.c.o src/libultra/os_vi_init.c
python3 tools/trim_elf32_section.py \
    build/us/src/libultra/os_vi_init.c.o .data 0x70 --alignment 4
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_vi_get_current_framebuffer.c.o src/libultra/os_vi_get_current_framebuffer.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_vi_get_next_framebuffer.c.o src/libultra/os_vi_get_next_framebuffer.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_vi_manager.c.o src/libultra/os_vi_manager.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_timer.c.o src/libultra/os_timer.c
python3 tools/trim_elf32_section.py \
    build/us/src/libultra/os_timer.c.o .data 0x10 --alignment 4
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_vi_set_event.c.o src/libultra/os_vi_set_event.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_vi_set_mode.c.o src/libultra/os_vi_set_mode.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_vi_set_special_features.c.o src/libultra/os_vi_set_special_features.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_vi_swap_buffer.c.o src/libultra/os_vi_swap_buffer.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_vi_swap_context.c.o src/libultra/os_vi_swap_context.c
.toolchain/ido5.3/cc -c -Wab,-r4300_mul -G 0 -nostdinc -Xcpluscomm \
    -fullwarn -woff 516,649,838,712 -mips2 -o32 -D_MIPS_SZLONG=32 \
    -DBUILD_VERSION=VERSION_I -DBUILD_VERSION_STRING=\"2.0I\" -non_shared \
    -DNDEBUG -D_FINALROM -O3 -Isrc/libultra/ido -Isrc/libultra/ido/PR \
    -Isrc/libultra -o build/us/src/libultra/xprintf.c.o src/libultra/xprintf.c
.toolchain/ido5.3/cc -c -Wab,-r4300_mul -G 0 -nostdinc -Xcpluscomm \
    -fullwarn -woff 516,649,838,712 -mips2 -o32 -D_MIPS_SZLONG=32 \
    -DBUILD_VERSION=VERSION_I -DBUILD_VERSION_STRING=\"2.0I\" -non_shared \
    -DNDEBUG -D_FINALROM -O3 -Isrc/libultra/ido -Isrc/libultra/ido/PR \
    -Isrc/libultra -o build/us/src/libultra/xldtob.c.o src/libultra/xldtob.c
.toolchain/ido5.3/cc -c -O2 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/ldiv.c.o src/libultra/ldiv.c
.toolchain/ido5.3/cc -c -O2 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/litob.c.o src/libultra/litob.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_yield_thread.c.o src/libultra/os_yield_thread.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_virtual_to_physical.c.o src/libultra/os_virtual_to_physical.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_reset_global_int_mask.c.o src/libultra/os_reset_global_int_mask.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_set_global_int_mask.c.o src/libultra/os_set_global_int_mask.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_si_access_queue.c.o src/libultra/os_si_access_queue.c
python3 tools/trim_elf32_section.py \
    build/us/src/libultra/os_si_access_queue.c.o .data 0x10 --alignment 4
.toolchain/ido5.3/cc -c -O2 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/al_save_param.c.o src/libultra/al_save_param.c
python3 tools/trim_elf32_section.py \
    build/us/src/libultra/al_save_param.c.o .text 0x34 --alignment 4
.toolchain/ido5.3/cc -c -O2 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/al_save_pull.c.o src/libultra/al_save_pull.c
python3 tools/trim_elf32_section.py \
    build/us/src/libultra/al_save_pull.c.o .text 0x8C --alignment 4
.toolchain/ido5.3/cc -c -O2 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/gu_normalize.c.o src/libultra/gu_normalize.c
.toolchain/ido5.3/cc -c -O3 -mips2 -Wab,-r4300_mul -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/gu_rotate.c.o src/libultra/gu_rotate.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_sp_task.c.o src/libultra/os_sp_task.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_start_thread.c.o src/libultra/os_start_thread.c
.toolchain/ido5.3/cc -c -O2 -mips2 -Wab,-r4300_mul -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/sinf.c.o src/libultra/sinf.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/os_ai_device_busy.c.o src/libultra/os_ai_device_busy.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/os_ai_get_length.c.o src/libultra/os_ai_get_length.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/os_ai_get_status.c.o src/libultra/os_ai_get_status.c
.toolchain/ido5.3/cc -c -O2 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/al_copy.c.o src/libultra/al_copy.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/os_create_mesg_queue.c.o src/libultra/os_create_mesg_queue.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_create_thread.c.o src/libultra/os_create_thread.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_epi_start_dma.c.o src/libultra/os_epi_start_dma.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_destroy_thread.c.o src/libultra/os_destroy_thread.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_get_time.c.o src/libultra/os_get_time.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_jam_mesg.c.o src/libultra/os_jam_mesg.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_epi_raw_start_dma.c.o src/libultra/os_epi_raw_start_dma.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_leo_disk_init.c.o src/libultra/os_leo_disk_init.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/os_cont_crc.c.o src/libultra/os_cont_crc.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_pi_start_dma.c.o src/libultra/os_pi_start_dma.c
.toolchain/ido5.3/cc -c -O2 -mips2 -Wab,-r4300_mul -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/gu_mtx.c.o src/libultra/gu_mtx.c
.toolchain/ido5.3/cc -c -O2 -mips2 -Wab,-r4300_mul -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/gu_perspective.c.o src/libultra/gu_perspective.c
.toolchain/ido5.3/cc -c -O2 -mips2 -Wab,-r4300_mul -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/cosf.c.o src/libultra/cosf.c
.toolchain/ido5.3/cc -c -O3 -mips2 -Wab,-r4300_mul -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/gu_look_at.c.o src/libultra/gu_look_at.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_cont_ram_write.c.o src/libultra/os_cont_ram_write.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_cont_ram_read.c.o src/libultra/os_cont_ram_read.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_initialize.c.o src/libultra/os_initialize.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_motor.c.o src/libultra/os_motor.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_pfs_delete_file.c.o src/libultra/os_pfs_delete_file.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_pfs_file_state.c.o src/libultra/os_pfs_file_state.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_pfs_free_blocks.c.o src/libultra/os_pfs_free_blocks.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_pfs_get_status.c.o src/libultra/os_pfs_get_status.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_pfs_init_pak.c.o src/libultra/os_pfs_init_pak.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_pfs_is_plug.c.o src/libultra/os_pfs_is_plug.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_pfs_checker.c.o src/libultra/os_pfs_checker.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_pfs_read_write_file.c.o src/libultra/os_pfs_read_write_file.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_pfs_get_id_copy.c.o src/libultra/os_pfs_get_id_copy.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include -Isrc/libultra \
    -o build/us/src/libultra/os_pfs_find_file.c.o src/libultra/os_pfs_find_file.c
.toolchain/ido5.3/cc -c -O3 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/al_filter_new.c.o src/libultra/al_filter_new.c
.toolchain/ido5.3/cc -c -O3 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/al_heap_alloc.c.o src/libultra/al_heap_alloc.c
.toolchain/ido5.3/cc -c -O3 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/al_heap_init.c.o src/libultra/al_heap_init.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/os_pi_get_cmd_queue.c.o src/libultra/os_pi_get_cmd_queue.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/os_pi_access.c.o src/libultra/os_pi_access.c
python3 tools/trim_elf32_section.py \
    build/us/src/libultra/os_pi_access.c.o .data 0x10 --alignment 4
.toolchain/ido5.3/cc -c -O1 -mips3 -32 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/ll.c.o src/libultra/ll.c
python3 tools/set_elf32_mips_o32.py build/us/src/libultra/ll.c.o
.toolchain/ido5.3/cc -c -Wab,-r4300_mul -G 0 -nostdinc -Xcpluscomm \
    -fullwarn -woff 516,649,838,712 -mips2 -o32 -D_MIPS_SZLONG=32 \
    -DF3DEX_GBI -DBUILD_VERSION=VERSION_I \
    -DBUILD_VERSION_STRING=\"2.0I\" -non_shared -DNDEBUG -D_FINALROM -O3 \
    -Isrc/libultra -o build/us/src/libultra/sched.c.o src/libultra/sched.c
python3 tools/trim_elf32_section.py \
    build/us/src/libultra/sched.c.o .text 0x940 --alignment 4
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/os_get_thread_pri.c.o src/libultra/os_get_thread_pri.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/os_dp_device_busy.c.o src/libultra/os_dp_device_busy.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/os_si_device_busy.c.o src/libultra/os_si_device_busy.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/os_si_raw_read_io.c.o src/libultra/os_si_raw_read_io.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/os_si_raw_write_io.c.o src/libultra/os_si_raw_write_io.c
.toolchain/ido5.3/cc -c -O2 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/al_main.c.o src/libultra/al_main.c
python3 tools/trim_elf32_section.py \
    build/us/src/libultra/al_main.c.o .data 0x10 --alignment 4
.toolchain/ido5.3/cc -c -O2 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/sprintf.c.o src/libultra/sprintf.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/os_sp_set_pc.c.o src/libultra/os_sp_set_pc.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/os_sp_device_busy.c.o src/libultra/os_sp_device_busy.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/os_sp_set_status.c.o src/libultra/os_sp_set_status.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/os_sp_task_yield.c.o src/libultra/os_sp_task_yield.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/os_sp_get_status.c.o src/libultra/os_sp_get_status.c
.toolchain/ido5.3/cc -c -O2 -Wo,-loopunroll,0 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/string.c.o src/libultra/string.c
.toolchain/ido5.3/cc -c -O3 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -Isrc/libultra -o build/us/src/libultra/al_drvrnew.c.o src/libultra/al_drvrnew.c
.toolchain/ido5.3/cc -c -O3 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -Isrc/libultra -o build/us/src/libultra/al_aux_bus.c.o src/libultra/al_aux_bus.c
.toolchain/ido5.3/cc -c -O3 -mips2 -Wab,-r4300_mul -non_shared -G 0 -Iinclude -Isrc/code/include \
    -Isrc/libultra -o build/us/src/libultra/al_env.c.o src/libultra/al_env.c
.toolchain/ido5.3/cc -c -O3 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -Isrc/libultra -o build/us/src/libultra/al_load.c.o src/libultra/al_load.c
.toolchain/ido5.3/cc -c -O3 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -Isrc/libultra -o build/us/src/libultra/al_main_bus.c.o src/libultra/al_main_bus.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -Isrc/libultra -o build/us/src/libultra/os_pfs_allocate_file.c.o src/libultra/os_pfs_allocate_file.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -Isrc/libultra -o build/us/src/libultra/os_cont_pfs.c.o src/libultra/os_cont_pfs.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Xcpluscomm -Iinclude -Isrc/code/include \
    -Isrc/libultra -o build/us/src/libultra/os_leo_interrupt.c.o src/libultra/os_leo_interrupt.c
.toolchain/ido5.3/cc -c -O3 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/al_syn_delete.c.o src/libultra/al_syn_delete.c
.toolchain/ido5.3/cc -c -O1 -mips2 -non_shared -G 0 -Iinclude -Isrc/code/include \
    -o build/us/src/libultra/os_vi_get_current_context.c.o src/libultra/os_vi_get_current_context.c

# Constant pools recovered from the early gameplay units. Units compiled via
# the normalized-unit manifests are trimmed in those loops above.
for spec in \
    unknown/8007B8EC:0x8 \
    unknown/80085C30:0x4 \
    unknown/80085CC4:0x4 \
    unknown/80086700:0x18 \
    unknown/80087F2C:0x4 \
    unknown/80088000:0x4 \
    unknown/80088720:0x4 \
    unknown/80088ABC:0x4 \
    unknown/80088B18:0x4 \
    unknown/80088C70:0x4 \
    unknown/80088FD4:0x4 \
    unknown/80089008:0x4 \
    unknown/80089040:0x4 \
    unknown/80089094:0x4 \
    unknown/8008E620:0x4 \
    unknown/8008F78C:0x8 \
    unknown/8009660C:0x4 \
    unknown/80097EE4:0x18 \
    unknown/80098454:0x10 \
    unknown/80099F74:0x4
do
    unit="${spec%%:*}"
    size="${spec##*:}"
    python3 tools/trim_elf32_section.py \
        "build/us/src/code/${unit}.c.o" .rodata "$size" --alignment 4
done

"${tool_prefix}objcopy" -I binary -O elf32-tradbigmips -B mips \
    assets/extracted/us/ipl3.bin build/us/assets/extracted/us/ipl3.bin.o

if false; then
"${tool_prefix}nm" -u \
    build/us/asm/us/main_before_80077C40.s.o \
    build/us/src/code/debug/80077C40_early_hw.c.o \
    build/us/src/code/debug/80077DA4_early_memory_read.c.o \
    build/us/asm/us/main_80077FD0_to_80078048.s.o \
    build/us/src/code/debug/80078048_early_memory_write.c.o \
    build/us/src/code/debug/80078200_early_remote_copy.c.o \
    build/us/asm/us/main_80078274_to_80078908.s.o \
    build/us/src/code/debug/80078908_early_commands.c.o \
    build/us/asm/us/main_80078ADC_to_80078C68.s.o \
    build/us/src/code/debug/80078C68_early_command_status.c.o \
    build/us/asm/us/main_80078CD8_to_8007A710.s.o \
    build/us/src/code/unknown/8007A710.c.o \
    build/us/src/code/render/8007A720_display_slot.c.o \
    build/us/asm/us/main_8007A75C_to_8007AC34.s.o \
    build/us/src/code/render/8007AC34_display_buffer.c.o \
    build/us/asm/us/main_8007AD40_to_8007AD94.s.o \
    build/us/src/code/render/8007AD94_display_buffer_select.c.o \
    build/us/src/code/unknown/8007ADB0.c.o \
    build/us/src/code/frontend/8007ADC0_controller_state.c.o \
    build/us/asm/us/main_8007ADF0_to_8007B020.s.o \
    build/us/src/code/unknown/8007B020.c.o \
    build/us/src/code/render/8007B030_gfx_pool.c.o \
    build/us/asm/us/main_8007B0E4_to_8007B1F0.s.o \
    build/us/src/code/gameplay/8007B1F0_render_queue.c.o \
    build/us/src/code/gameplay/8007B65C_render_submit.c.o \
    build/us/asm/us/main_8007B8EC_to_8007BCF0.s.o \
    build/us/src/code/runtime/8007BCF0_asset_load.c.o \
    build/us/src/code/gameplay/8007BDFC_video_mode.c.o \
    build/us/src/code/gameplay/8007BEF0_texture_tile.c.o \
    build/us/src/code/gameplay/8007C364_texture_grid_tile_draw.c.o \
    build/us/src/code/collision/8007C718_grid_tile_walk.c.o \
    build/us/src/code/gameplay/8007C9B8_texture_grid_draw.c.o \
    build/us/src/code/gameplay/8007D470_small_state.c.o \
    build/us/src/code/gameplay/8007D500_mapped_record.c.o \
    build/us/src/code/gameplay/8007D558_small_state_copy.c.o \
    build/us/asm/us/main_8007D5B0_to_8007D694.s.o \
    build/us/src/code/collision/8007D694_collision_noop.c.o \
    build/us/asm/us/main_8007D69C_to_8007D710.s.o \
    build/us/src/code/runtime/8007D710_state_noop.c.o \
    build/us/asm/us/main_8007D718_to_8007D720.s.o \
    build/us/src/code/runtime/8007D720_state_modes.c.o \
    build/us/asm/us/main_8007D7C4_to_8007E1FC.s.o \
    build/us/src/code/collision/8007E1FC_collision_fields.c.o \
    build/us/asm/us/main_8007E210_to_8007E778.s.o \
    build/us/src/code/entities/8007E778_object_query.c.o \
    build/us/asm/us/main_8007E7A8_to_80081FD8.s.o \
    build/us/src/code/entities/80081FD8_object_defaults.c.o \
    build/us/asm/us/main_80082004_to_80082B40.s.o \
    build/us/src/code/gameplay/80082B40_mode_owner.c.o \
    build/us/asm/us/main_80082B68_to_80082BD4.s.o \
    build/us/src/code/gameplay/80082BD4_mode_transition.c.o \
    build/us/asm/us/main_80082C1C_to_80082D60.s.o \
    build/us/src/code/gameplay/80082D60_pair_queue.c.o \
    build/us/src/code/path/80082D98_path_sequence_init.c.o \
    build/us/src/code/unknown/80082F1C.c.o \
    build/us/src/code/unknown/80082F98.c.o \
    build/us/src/code/entities/80082FE0_object_disable.c.o \
    build/us/asm/us/main_80083028_to_80083FCC.s.o \
    build/us/src/code/entities/80083FCC_object_predicates.c.o \
    build/us/asm/us/main_80083FF8_to_80084C50.s.o \
    build/us/src/code/entities/80084C50_object_direction.c.o \
    build/us/src/code/ai/80084CC8_ai_target_bit_select.c.o \
    build/us/src/code/unknown/80085148.c.o \
    build/us/src/code/unknown/8008518C.c.o \
    build/us/src/code/unknown/80085250.c.o \
    build/us/src/code/ai/800852F8_ai_node_setup.c.o \
    build/us/src/code/unknown/8008543C.c.o \
    build/us/src/code/unknown/800854C4.c.o \
    build/us/src/code/world/800857F0_zone_spawn_query.c.o \
    build/us/src/code/entities/800859A8_object_action.c.o \
    build/us/asm/us/main_800859E4_to_8009C284.s.o \
    build/us/src/code/unknown/80094880.c.o \
    build/us/src/code/unknown/80094F40.c.o \
    build/us/src/code/unknown/80094F78.c.o \
    build/us/src/code/unknown/80094FBC.c.o \
    build/us/src/code/unknown/80095B50.c.o \
    build/us/src/code/unknown/80095B68.c.o \
    build/us/src/code/unknown/80095B90.c.o \
    build/us/src/code/unknown/80095BE4.c.o \
    build/us/src/code/unknown/80095C50.c.o \
    build/us/src/code/unknown/80095E7C.c.o \
    build/us/asm/us/main_80095F08_to_80096250.s.o \
    build/us/src/code/unknown/80096250.c.o \
    build/us/src/code/unknown/80096294.c.o \
    build/us/src/code/unknown/8009660C.c.o \
    build/us/src/code/unknown/800966D4.c.o \
    build/us/src/code/unknown/800967F0.c.o \
    build/us/src/code/unknown/80096810.c.o \
    build/us/src/code/gameplay/80096A54_font_glyph_draw.c.o \
    build/us/src/code/gameplay/80096BDC_font_number_draw.c.o \
    build/us/src/code/gameplay/80096E14_font_hex_draw.c.o \
    build/us/src/code/unknown/80096F48.c.o \
    build/us/asm/us/main_8009700C_to_800973E0.s.o \
    build/us/src/code/unknown/800973E0.c.o \
    build/us/src/code/unknown/80097508.c.o \
    build/us/src/code/unknown/80097530.c.o \
    build/us/asm/us/main_8009755C_to_80097560.s.o \
    build/us/src/code/unknown/80097560.c.o \
    build/us/src/code/unknown/80097660.c.o \
    build/us/src/code/unknown/800976AC.c.o \
    build/us/src/code/unknown/80097794.c.o \
    build/us/src/code/unknown/800977DC.c.o \
    build/us/src/code/unknown/80097844.c.o \
    build/us/src/code/unknown/8009790C.c.o \
    build/us/src/code/unknown/800979A0.c.o \
    build/us/src/code/unknown/800979F4.c.o \
    build/us/src/code/unknown/80097A6C.c.o \
    build/us/src/code/unknown/80097B20.c.o \
    build/us/src/code/unknown/80097B44.c.o \
    build/us/src/code/unknown/80097B68.c.o \
    build/us/src/code/unknown/80097BA4.c.o \
    build/us/src/code/unknown/80097BC4.c.o \
    build/us/src/code/unknown/80097C1C.c.o \
    build/us/src/code/unknown/80097C84.c.o \
    build/us/src/code/unknown/80097CB8.c.o \
    build/us/src/code/unknown/80097CC8.c.o \
    build/us/src/code/audio/80097D14_music_stream_queue.c.o \
    build/us/src/code/unknown/80097DF8.c.o \
    build/us/src/code/unknown/80097EE4.c.o \
    build/us/src/code/gameplay/80097FB4_spatial_sound_play.c.o \
    build/us/src/code/unknown/8009813C.c.o \
    build/us/src/code/unknown/80098180.c.o \
    build/us/src/code/unknown/80098190.c.o \
    build/us/src/code/unknown/800981E0.c.o \
    build/us/src/code/unknown/80098250.c.o \
    build/us/src/code/unknown/80098334.c.o \
    build/us/src/code/unknown/8009836C.c.o \
    build/us/src/code/unknown/80098430.c.o \
    build/us/src/code/unknown/80098454.c.o \
    build/us/src/code/unknown/80098534.c.o \
    build/us/asm/us/main_8009859C_to_800985A0.s.o \
    build/us/src/code/unknown/800985A0.c.o \
    build/us/src/code/unknown/80098AFC.c.o \
    build/us/src/code/unknown/80098B2C.c.o \
    build/us/src/code/unknown/80098B40.c.o \
    build/us/src/code/unknown/80098B58.c.o \
    build/us/src/code/unknown/80098BC8.c.o \
    build/us/src/code/unknown/80098BF8.c.o \
    build/us/src/code/unknown/80098CC8.c.o \
    build/us/src/code/unknown/80098F24.c.o \
    build/us/src/code/unknown/80098FBC.c.o \
    build/us/src/code/unknown/80099028.c.o \
    build/us/src/code/unknown/80099080.c.o \
    build/us/src/code/gameplay/80099160_text_character_map.c.o \
    build/us/src/code/unknown/800991CC.c.o \
    build/us/src/code/unknown/800992E0.c.o \
    build/us/src/code/unknown/800993B0.c.o \
    build/us/src/code/unknown/80099464.c.o \
    build/us/src/code/unknown/800996C4.c.o \
    build/us/src/code/unknown/80099758.c.o \
    build/us/src/code/unknown/80099784.c.o \
    build/us/asm/us/main_80099824_to_80099830.s.o \
    build/us/src/code/unknown/80099830.c.o \
    build/us/src/code/unknown/80099854.c.o \
    build/us/src/code/unknown/800998A8.c.o \
    build/us/src/code/unknown/800998E8.c.o \
    build/us/src/code/unknown/80099F74.c.o \
    build/us/src/code/unknown/80099FE8.c.o \
    build/us/src/code/player/8009A4C8_player_order_shuffle.c.o \
    build/us/src/code/unknown/8009A650.c.o \
    build/us/src/code/unknown/8009A6F0.c.o \
    build/us/src/code/unknown/8009A6F8.c.o \
    build/us/src/code/unknown/8009ACDC.c.o \
    build/us/src/code/unknown/8009AD7C.c.o \
    build/us/src/code/unknown/8009AE38.c.o \
    build/us/src/code/player/8009B0F0_player_state_build.c.o \
    build/us/src/code/player/8009B35C_player_state_modes.c.o \
    build/us/src/code/unknown/8009B434.c.o \
    build/us/src/code/unknown/8009B62C.c.o \
    build/us/src/code/gameplay/8009B694_match_result_check.c.o \
    build/us/src/code/unknown/8009C098.c.o \
    build/us/src/code/gameplay/8009C284_session_queries.c.o \
    build/us/src/code/gameplay/8009C31C_progress_level_advance.c.o \
    build/us/asm/us/main_8009C524_to_8009D144.s.o \
    build/us/src/code/gameplay/8009D144_mode_range.c.o \
    build/us/asm/us/main_8009D168_to_8009D578.s.o \
    build/us/src/code/math/8009D578_angle_fold.c.o \
    build/us/src/code/math/8009D5B4_angle_table_lookup.c.o \
    build/us/src/code/math/8009D6DC_angle_subtract.c.o \
    build/us/asm/us/main_8009D6F8_to_8009D72C.s.o \
    build/us/src/code/math/8009D72C_angle_between.c.o \
    build/us/src/code/unknown/8009D75C.c.o \
    build/us/src/code/math/8009D81C_angle_distance.c.o \
    build/us/src/code/math/8009D850_angle_direction.c.o \
    build/us/asm/us/main_8009D8A0_to_8009D914.s.o \
    build/us/src/code/math/8009D914_random_integer.c.o \
    build/us/asm/us/main_8009D960_to_8009DA34.s.o \
    build/us/src/code/gameplay/8009DA34_vector2.c.o \
    build/us/asm/us/main_8009DAB0_to_8009DB0C.s.o \
    build/us/src/code/gameplay/8009DB0C_vector2_scale.c.o \
    build/us/src/code/math/8009DB2C_vector_distance_normalize.c.o \
    build/us/src/code/math/8009DDF0_vector_angle.c.o \
    build/us/src/code/gameplay/8009E044_vector2_motion.c.o \
    build/us/asm/us/main_8009E0E8_to_8009EEA0.s.o \
    build/us/src/code/runtime/8009EEA0_game_queue.c.o \
    build/us/asm/us/main_8009EED8_to_8009EEE0.s.o \
    build/us/src/code/render/8009EEE0_matrix_basic.c.o \
    build/us/asm/us/main_8009EF4C_to_8009F064.s.o \
    build/us/src/code/render/8009F064_matrix_state.c.o \
    build/us/src/code/unknown/8009F090.c.o \
    build/us/src/code/render/8009F1F4_matrix_vector.c.o \
    build/us/src/code/unknown/8009F334.c.o \
    build/us/src/code/render/8009F4B4_matrix_multiply.c.o \
    build/us/asm/us/main_8009F5AC_to_8009F768.s.o \
    build/us/src/code/render/8009F768_matrix_transform.c.o \
    build/us/src/code/unknown/8009F8A0.c.o \
    build/us/asm/us/main_8009FCCC_to_8009FF1C.s.o \
    build/us/src/code/gameplay/8009FF1C_vector2_rotate.c.o \
    build/us/src/code/gameplay/8009FFB8_segment_billboard_matrix.c.o \
    build/us/asm/us/main_800A0744_to_800A0750.s.o \
    build/us/src/code/gameplay/800A0750_lzari_decode.c.o \
    build/us/asm/us/main_800A1144_to_800A1150.s.o \
    build/us/src/code/unknown/800A1150.c.o \
    build/us/src/code/runtime/800A1280_scheduler_context.c.o \
    build/us/src/code/unknown/800A1290.c.o \
    build/us/src/code/runtime/800A134C_scheduler_state.c.o \
    build/us/src/code/unknown/800A1384.c.o \
    build/us/src/code/unknown/800A140C.c.o \
    build/us/src/code/unknown/800A15F0.c.o \
    build/us/src/code/unknown/800A16F8.c.o \
    build/us/src/code/runtime/800A179C_scheduler_events.c.o \
    build/us/src/code/unknown/800A18D0.c.o \
    build/us/src/code/unknown/800A19DC.c.o \
    build/us/src/code/runtime/800A1A28_scheduler_queue.c.o \
    build/us/src/code/unknown/800A1B44.c.o \
    build/us/src/code/unknown/800A1BE0.c.o \
    build/us/src/code/runtime/800A2154_task_message_broadcast.c.o \
    build/us/src/code/runtime/800A22CC_task_class_init.c.o \
    build/us/src/code/entities/800A2B74_object_range.c.o \
    build/us/src/code/unknown/800A2B9C.c.o \
    build/us/src/code/collision/800A2C6C_contact_message_broadcast.c.o \
    build/us/src/code/runtime/800A2DFC_scheduler_misc.c.o \
    build/us/src/code/unknown/800A2E5C.c.o \
    build/us/asm/us/main_800A2EEC_to_800A2EF0.s.o \
    build/us/src/code/unknown/800A2EF0.c.o \
    build/us/src/code/unknown/800A2F0C.c.o \
    build/us/src/code/unknown/800A2FBC.c.o \
    build/us/src/code/effects/800A3560_effect_trail_draw.c.o \
    build/us/src/code/unknown/800A3758.c.o \
    build/us/src/code/entities/800A4098_object_timing.c.o \
    build/us/src/code/effects/800A40CC_effect_sprite_key_draw.c.o \
    build/us/src/code/effects/800A42C8_effect_sprite_ring_draw.c.o \
    build/us/src/code/unknown/800A4468.c.o \
    build/us/src/code/unknown/800A477C.c.o \
    build/us/src/code/effects/800A5858_effect_mesh_transform_draw.c.o \
    build/us/src/code/unknown/800A5BD8.c.o \
    build/us/src/code/unknown/800A60E0.c.o \
    build/us/asm/us/main_800A619C_to_800A61A0.s.o \
    build/us/src/code/unknown/800A61A0.c.o \
    build/us/src/code/gameplay/800A6320_camera_collision_resolve.c.o \
    build/us/src/code/unknown/800A6588.c.o \
    build/us/src/code/entities/800A6ABC_object_setters.c.o \
    build/us/src/code/unknown/800A6B7C.c.o \
    build/us/src/code/gameplay/800A6C20_spotter_update.c.o \
    build/us/src/code/gameplay/800A6FD0_spotter_frame_setup.c.o \
    build/us/src/code/unknown/800A702C.c.o \
    build/us/src/code/gameplay/800A7090_camera_shake_falloff.c.o \
    build/us/asm/us/main_800A728C_to_800A7290.s.o \
    build/us/src/code/entities/800A7290_object_init.c.o \
    build/us/src/code/gameplay/800A72C0_camera_perspective_setup.c.o \
    build/us/src/code/player/800A7664_player_perspective_update.c.o \
    build/us/src/code/unknown/800A7794.c.o \
    build/us/src/code/player/800A77A8_player_setup.c.o \
    build/us/src/code/unknown/800A8690.c.o \
    build/us/src/code/unknown/800A87BC.c.o \
    build/us/src/code/unknown/800A89B0.c.o \
    build/us/src/code/gameplay/800A8A78_camera_view_select.c.o \
    build/us/src/code/entities/800A8B14_object_reset.c.o \
    build/us/src/code/gameplay/800A8B38_camera_mode_update.c.o \
    build/us/src/code/unknown/800A8D54.c.o \
    build/us/src/code/unknown/800A8E3C.c.o \
    build/us/src/code/unknown/800A8E84.c.o \
    build/us/src/code/unknown/800A8F34.c.o \
    build/us/src/code/entities/800A9054_object_flags.c.o \
    build/us/src/code/unknown/800A9080.c.o \
    build/us/src/code/unknown/800A9660.c.o \
    build/us/src/code/unknown/800A96B8.c.o \
    build/us/src/code/entities/800A974C_object_limit.c.o \
    build/us/src/code/unknown/800A977C.c.o \
    build/us/src/code/unknown/800A97FC.c.o \
    build/us/src/code/unknown/800A98B8.c.o \
    build/us/asm/us/main_800A9928_to_800A9A44.s.o \
    build/us/src/code/unknown/800A9A44.c.o \
    build/us/src/code/unknown/800A9A98.c.o \
    build/us/src/code/unknown/800A9B64.c.o \
    build/us/asm/us/main_800A9BE8_to_800A9BF0.s.o \
    build/us/src/code/entities/800A9BF0_object_table_color.c.o \
    build/us/src/code/unknown/800A9C24.c.o \
    build/us/src/code/unknown/800A9CCC.c.o \
    build/us/src/code/entities/800A9D50_object_table_reset.c.o \
    build/us/src/code/gameplay/800A9D78_light_display_list_build.c.o \
    build/us/asm/us/main_800A9EC0_to_800A9F10.s.o \
    build/us/src/code/unknown/800A9F10.c.o \
    build/us/src/code/render/800AA058_area_lighting_build.c.o \
    build/us/src/code/entities/800AA598_object_table_lookup.c.o \
    build/us/asm/us/main_800AA5C4_to_800AA5D0.s.o \
    build/us/src/code/unknown/800AA5D0.c.o \
    build/us/src/code/render/800AA664_view_radius_visible.c.o \
    build/us/src/code/unknown/800AA8A8.c.o \
    build/us/src/code/unknown/800AAAE0.c.o \
    build/us/src/code/unknown/800AAC14.c.o \
    build/us/src/code/render/800AAEA0_view_segment_clip.c.o \
    build/us/src/code/unknown/800AB4DC.c.o \
    build/us/src/code/world/800AB58C_world_edge_register_unculled.c.o \
    build/us/src/code/world/800AB980_world_edge_register.c.o \
    build/us/src/code/unknown/800ABE6C.c.o \
    build/us/src/code/path/800ABF38_nearest_path_test.c.o \
    build/us/src/code/unknown/800AC0F4.c.o \
    build/us/src/code/path/800AC198_path_visibility_queries.c.o \
    build/us/src/code/render/800AC9E8_view_state_build.c.o \
    build/us/src/code/render/800ACCB4_view_project_point.c.o \
    build/us/asm/us/main_800ACE6C_to_800ACE70.s.o \
    build/us/src/code/unknown/800ACE70.c.o \
    build/us/src/code/unknown/800ACEB4.c.o \
    build/us/src/code/unknown/800ACEFC.c.o \
    build/us/src/code/unknown/800ACF20.c.o \
    build/us/src/code/unknown/800ACFE0.c.o \
    build/us/src/code/unknown/800AD088.c.o \
    build/us/src/code/unknown/800AD14C.c.o \
    build/us/src/code/unknown/800AD6A8.c.o \
    build/us/src/code/unknown/800AD9A8.c.o \
    build/us/src/code/unknown/800ADCA0.c.o \
    build/us/src/code/unknown/800ADFC8.c.o \
    build/us/src/code/render/800AE184_model_lod_draw.c.o \
    build/us/src/code/unknown/800AE4D0.c.o \
    build/us/src/code/unknown/800AE710.c.o \
    build/us/src/code/render/800AE8EC_model_view_draw.c.o \
    build/us/src/code/unknown/800AF364.c.o \
    build/us/src/code/gameplay/800AF43C_level_reset.c.o \
    build/us/src/code/world/800AF978_world_object_draw.c.o \
    build/us/src/code/unknown/800B0268.c.o \
    build/us/src/code/math/800B02D4_bounds_pair.c.o \
    build/us/src/code/unknown/800B03F4.c.o \
    build/us/src/code/gameplay/800B0444_gameplay_stub.c.o \
    build/us/src/code/unknown/800B044C.c.o \
    build/us/src/code/unknown/800B04E0.c.o \
    build/us/src/code/unknown/800B05F4.c.o \
    build/us/src/code/player/800B06A8_player_color.c.o \
    build/us/asm/us/main_800B06D8_to_800B06E0.s.o \
    build/us/src/code/unknown/800B06E0.c.o \
    build/us/src/code/unknown/800B0D70.c.o \
    build/us/src/code/collision/800B0E38_grid_node_insert.c.o \
    build/us/src/code/collision/800B0F4C_grid_node_remove.c.o \
    build/us/src/code/unknown/800B109C.c.o \
    build/us/asm/us/main_800B129C_to_800B14A8.s.o \
    build/us/src/code/unknown/800B14A8.c.o \
    build/us/src/code/unknown/800B1610.c.o \
    build/us/src/code/unknown/800B1668.c.o \
    build/us/src/code/collision/800B1898_grid_node_create.c.o \
    build/us/src/code/unknown/800B1DA8.c.o \
    build/us/src/code/unknown/800B22F8.c.o \
    build/us/src/code/unknown/800B2364.c.o \
    build/us/src/code/collision/800B2488_grid_collision_push.c.o \
    build/us/src/code/collision/80073074_grid_collision_constants.c.o \
    build/us/src/code/unknown/800B2890.c.o \
    build/us/src/code/collision/800B3018_grid_node_separation.c.o \
    build/us/src/code/unknown/800B3368.c.o \
    build/us/src/code/collision/800B33FC_grid_overlap_query.c.o \
    build/us/src/code/unknown/800B3504.c.o \
    build/us/src/code/collision/800B3748_grid_contact_query.c.o \
    build/us/src/code/collision/800B3B60_grid_segment_box_test.c.o \
    build/us/src/code/collision/800B4294_grid_segment_cell_test.c.o \
    build/us/src/code/collision/800B4684_collision_query.c.o \
    build/us/src/code/collision/800B49E0_grid_segment_walk.c.o \
    build/us/src/code/unknown/800B4F38.c.o \
    build/us/asm/us/main_800B5130_to_800B5728.s.o \
    build/us/src/code/collision/800B5728_grid_edge_points.c.o \
    build/us/src/code/unknown/800B5A10.c.o \
    build/us/src/code/vehicles/800B5B8C_mover_reflect.c.o \
    build/us/asm/us/main_800B5C48_to_800B5D1C.s.o \
    build/us/src/code/unknown/800B5D1C.c.o \
    build/us/src/code/unknown/800B5DA8.c.o \
    build/us/src/code/gameplay/800B5F30_turn_adjust.c.o \
    build/us/src/code/vehicles/800B5F70_mover_collision_response.c.o \
    build/us/src/code/unknown/800B61B8.c.o \
    build/us/src/code/vehicles/800B66E0_mover_advance.c.o \
    build/us/src/code/unknown/800B6934.c.o \
    build/us/src/code/entities/800B69F4_object_rotation_update.c.o \
    build/us/src/code/collision/800B6CC4_grid_corner_sweep.c.o \
    build/us/src/code/collision/800B6F40_grid_contact_resolve.c.o \
    build/us/src/code/frontend/80073120_hud_timing_constants.c.o \
    build/us/src/code/collision/800B739C_contact_side_test.c.o \
    build/us/src/code/vehicles/800B74B4_tank_collision_resolve.c.o \
    build/us/src/code/frontend/80073148_hud_timing_tail_constants.c.o \
    build/us/src/code/vehicles/800B8100_mover_step_response.c.o \
    build/us/src/code/hud_animation_limits.c.o \
    build/us/src/code/math/800B8310_vector_angle_from_xy.c.o \
    build/us/src/code/collision/800B83A8_grid_surface_height.c.o \
    build/us/src/code/unknown/800B87A0.c.o \
    build/us/src/code/collision/800B8870_grid_node_height.c.o \
    build/us/asm/us/main_800B88DC_to_800B9094.s.o \
    build/us/src/code/gameplay/800B9094_ground_corner_probe.c.o \
    build/us/src/code/collision/800B93A4_grid_height_query.c.o \
    build/us/asm/us/main_800B95C8_to_800B99AC.s.o \
    build/us/src/code/render/800B99C0_display_registry.c.o \
    build/us/asm/us/main_800B99F8_to_800B9A4C.s.o \
    build/us/src/code/render/800B9A4C_display_color.c.o \
    build/us/src/code/render/800B9AB0_model_player_color.c.o \
    build/us/asm/us/main_800B9B8C_to_800B9C68.s.o \
    build/us/src/code/render/800B9C68_display_commands.c.o \
    build/us/asm/us/main_800B9CAC_to_800B9D4C.s.o \
    build/us/src/code/gameplay/800B9D4C_table_lookup.c.o \
    build/us/src/code/unknown/800B9E24.c.o \
    build/us/src/code/unknown/800B9EB4.c.o \
    build/us/src/code/unknown/800B9F44.c.o \
    build/us/src/code/unknown/800B9FD4.c.o \
    build/us/src/code/world/800BA1BC_world_loader_ref_walkers.c.o \
    build/us/src/code/world/800BA330_world_resource_aggregate.c.o \
    build/us/src/code/world/800BA6C0_world_loader.c.o \
    build/us/src/code/world/800BB2A0_world_bundle_resource_aggregate.c.o \
    build/us/src/code/render/800BB53C_common_model_loader.c.o \
    build/us/asm/us/main_800BBDBC_to_800BBDC0.s.o \
    build/us/src/code/unknown/800BBDC0.c.o \
    build/us/src/code/script/800BD880_entry_scan.c.o \
    build/us/src/code/script/800BD8B8_entry_flags.c.o \
    build/us/src/code/unknown/800BD93C.c.o \
    build/us/src/code/unknown/800BDA30.c.o \
    build/us/src/code/unknown/800BDAF8.c.o \
    build/us/src/code/unknown/800BEE0C.c.o \
    build/us/src/code/frontend/800BF000_hud_tree_remove.c.o \
    build/us/asm/us/main_800BF130_to_800BF1A4.s.o \
    build/us/src/code/unknown/800BF1A4.c.o \
    build/us/src/code/frontend/800BF204_hud_tree_update.c.o \
    build/us/src/code/unknown/800BF3EC.c.o \
    build/us/src/code/frontend/800BF484_hud_tree_draw.c.o \
    build/us/src/code/unknown/800BF798.c.o \
    build/us/src/code/frontend/800BF80C_hud_frame.c.o \
    build/us/src/code/unknown/800BFCA4.c.o \
    build/us/src/code/frontend/800BFD40_hud_state.c.o \
    build/us/asm/us/main_800BFDA4_to_800BFE4C.s.o \
    build/us/src/code/unknown/800BFE4C.c.o \
    build/us/asm/us/main_800BFE94_to_800BFEA0.s.o \
    build/us/src/code/frontend/800BFEA0_race_assets_init.c.o \
    build/us/src/code/frontend/800C03F0_hud_root_callback.c.o \
    build/us/src/code/frontend/800C041C_hud_mode_table.c.o \
    build/us/src/code/unknown/800C04C8.c.o \
    build/us/src/code/unknown/800C0564.c.o \
    build/us/src/code/frontend/800C0608_hud_mode_cycle_full.c.o \
    build/us/src/code/frontend/800C0800_hud_modes.c.o \
    build/us/src/code/frontend/800C0850_menu_state.c.o \
    build/us/src/code/frontend/800C08E0_hud_exit_dispatch.c.o \
    build/us/src/code/frontend/800C0A64_hud_stub.c.o \
    build/us/src/code/unknown/800C0A6C.c.o \
    build/us/src/code/unknown/800C0ADC.c.o \
    build/us/src/code/unknown/800C0B78.c.o \
    build/us/src/code/frontend/800C0C18_hud_layout.c.o \
    build/us/src/code/unknown/800C0C38.c.o \
    build/us/src/code/frontend/800C0D00_hud_volume_adjust.c.o \
    build/us/src/code/frontend/800C1094_menu_toggle.c.o \
    build/us/src/code/frontend/800C1124_hud_secondary.c.o \
    build/us/src/code/frontend/800C1138_hud_callbacks.c.o \
    build/us/src/code/frontend/800C1190_hud_primary_modes.c.o \
    build/us/src/code/unknown/800C11B8.c.o \
    build/us/src/code/unknown/800C123C.c.o \
    build/us/src/code/frontend/800C12B4_hud_key_nav.c.o \
    build/us/src/code/unknown/800C13BC.c.o \
    build/us/src/code/frontend/800C1420_menu_countdown.c.o \
    build/us/src/code/frontend/800C1468_hud_transition.c.o \
    build/us/src/code/frontend/800C1484_hud_menu_open.c.o \
    build/us/src/code/frontend/800C1578_hud_panel_callback.c.o \
    build/us/src/code/frontend/800C15A4_hud_list_trigger.c.o \
    build/us/src/code/frontend/800C15B8_hud_entry_values.c.o \
    build/us/src/code/frontend/800C1638_hud_list_reset.c.o \
    build/us/src/code/frontend/800C16B0_hud_slots_layout.c.o \
    build/us/src/code/gameplay/800C17C8_registry_lookup.c.o \
    build/us/src/code/unknown/800C180C.c.o \
    build/us/src/code/frontend/800C1938_controls_config.c.o \
    build/us/src/code/unknown/800C1E48.c.o \
    build/us/src/code/frontend/800C1F08_controls_preset.c.o \
    build/us/src/code/frontend/800C247C_hud_ready.c.o \
    build/us/src/code/frontend/800C24A4_hud_clear.c.o \
    build/us/src/code/frontend/800C24FC_hud_list_callback.c.o \
    build/us/src/code/frontend/800C2528_hud_option_select.c.o \
    build/us/src/code/frontend/800C27EC_hud_navigation.c.o \
    build/us/src/code/frontend/800C290C_hud_selection_apply.c.o \
    build/us/src/code/frontend/800C2924_hud_list_select_full.c.o \
    build/us/src/code/frontend/800C30A0_hud_primary_trigger.c.o \
    build/us/src/code/frontend/800C30B4_hud_controls_page.c.o \
    build/us/src/code/frontend/800C402C_hud_player_slots_cycle.c.o \
    build/us/src/code/frontend/800C420C_hud_row_preset.c.o \
    build/us/src/code/frontend/800C425C_hud_row_defaults.c.o \
    build/us/src/code/frontend/800C42A0_hud_exit_request.c.o \
    build/us/src/code/frontend/800C42E4_hud_list_refresh.c.o \
    build/us/src/code/frontend/800C434C_hud_list_focus_cycle.c.o \
    build/us/src/code/frontend/800C4594_hud_marker_update.c.o \
    build/us/src/code/frontend/800C47D4_hud_list_open.c.o \
    build/us/src/code/frontend/800C485C_hud_list_close.c.o \
    build/us/src/code/frontend/800C48C4_hud_alt_exit_request.c.o \
    build/us/src/code/frontend/800C48F0_hud_menu_entries_apply_settings.c.o \
    build/us/src/code/frontend/800C4ABC_hud_page_select.c.o \
    build/us/src/code/frontend/800C4B24_hud_entry_set_label.c.o \
    build/us/src/code/frontend/800C4BB4_hud_player_page.c.o \
    build/us/src/code/frontend/800C4E24_hud_page_focus_cycle.c.o \
    build/us/src/code/runtime/800C4F50_game_mode8_toggled.c.o \
    build/us/src/code/frontend/800C4F98_hud_slot_icons_update.c.o \
    build/us/src/code/frontend/800C5B3C_hud_mode_cycle.c.o \
    build/us/src/code/frontend/800C5D80_hud_panel_layout.c.o \
    build/us/src/code/frontend/800C5FB4_hud_panel_refresh.c.o \
    build/us/src/code/frontend/800C6280_hud_panel_select.c.o \
    build/us/src/code/frontend/800C6544_hud_page_focus.c.o \
    build/us/src/code/frontend/800C65B4_hud_page_next.c.o \
    build/us/src/code/frontend/800C674C_hud_page_exit_request.c.o \
    build/us/src/code/frontend/800C6790_hud_page_show.c.o \
    build/us/src/code/frontend/800C67BC_hud_page_open.c.o \
    build/us/src/code/frontend/800C6844_hud_page_close.c.o \
    build/us/src/code/frontend/800C68AC_hud_value_to_byte.c.o \
    build/us/asm/us/main_800C6914_to_800C6918.s.o \
    build/us/asm/us/data/main_800C6918_textbin.s.o \
    build/us/src/code/frontend/800C6920_race_assets_load.c.o \
    build/us/src/code/frontend/800C6D68_race_hud_init.c.o \
    build/us/src/code/frontend/800C726C_race_result_setup.c.o \
    build/us/src/code/frontend/800C73A8_race_object_timestamps.c.o \
    build/us/src/code/frontend/800C74AC_race_state_init.c.o \
    build/us/src/code/frontend/800C7514_race_state_reset.c.o \
    build/us/src/code/frontend/800C7594_race_mode_query.c.o \
    build/us/src/code/frontend/800C7650_race_frame_border_draw.c.o \
    build/us/src/code/frontend/800C7AA0_race_start_check.c.o \
    build/us/src/code/frontend/800C7C10_race_map_draw.c.o \
    build/us/src/code/frontend/800C8238_race_event_push.c.o \
    build/us/src/code/frontend/800C8350_race_hud_layout.c.o \
    build/us/src/code/frontend/800C8484_race_timer_update.c.o \
    build/us/src/code/frontend/800C877C_race_marker_project.c.o \
    build/us/src/code/frontend/800C8B74_race_player_icons_draw.c.o \
    build/us/src/code/frontend/800C8EDC_race_slot_clear.c.o \
    build/us/src/code/frontend/800C8F00_race_player_set_vehicle_label.c.o \
    build/us/src/code/frontend/800C9010_race_type_name_lookup.c.o \
    build/us/src/code/frontend/800C9130_race_player_panel.c.o \
    build/us/src/code/frontend/800C924C_race_player_set_layout.c.o \
    build/us/src/code/frontend/800C95A0_race_player_message.c.o \
    build/us/src/code/frontend/800C962C_race_player_pair_set.c.o \
    build/us/src/code/frontend/800C9680_race_mode_icon_get.c.o \
    build/us/src/code/frontend/800C975C_race_player_set_mode_icon.c.o \
    build/us/src/code/frontend/800C98D8_race_display_value_set.c.o \
    build/us/src/code/frontend/800C98E8_race_bar_update.c.o \
    build/us/src/code/frontend/800C9A3C_race_results_hud_draw.c.o \
    build/us/src/code/frontend/800CA1A8_race_player_reset.c.o \
    build/us/src/code/frontend/800CA2BC_race_lap_times_clamp.c.o \
    build/us/src/code/frontend/800CA3F0_race_timer_queries.c.o \
    build/us/src/code/frontend/800CA4A0_race_slot_set_digit.c.o \
    build/us/src/code/frontend/800CA620_race_message_append.c.o \
    build/us/src/code/frontend/800CAA0C_race_popup_show.c.o \
    build/us/src/code/frontend/800CAA48_race_popup_setup.c.o \
    build/us/src/code/frontend/800CAB44_race_flag_queries.c.o \
    build/us/src/code/frontend/800CABC0_race_player_widget.c.o \
    build/us/src/code/frontend/800CAD9C_race_widget_values.c.o \
    build/us/src/code/frontend/800CAED0_race_widget_clear.c.o \
    build/us/src/code/frontend/800CAFA8_race_widget_reset.c.o \
    build/us/src/code/frontend/800CB0C0_race_widget_flag_set.c.o \
    build/us/asm/us/main_800CB10C_to_800CB110.s.o \
    build/us/src/code/frontend/800CB110_results_assets_load.c.o \
    build/us/src/code/frontend/800CB1E4_controls_button_index_map.c.o \
    build/us/src/code/frontend/800CB334_controls_bindings_save.c.o \
    build/us/src/code/frontend/800CB934_controls_bindings_load.c.o \
    build/us/src/code/frontend/800CBE40_controller_save_slots.c.o \
    build/us/src/code/frontend/800CC2F8_controller_slots_scan.c.o \
    build/us/src/code/frontend/800CC574_controller_menu_input.c.o \
    build/us/src/code/frontend/800CCA6C_controller_queue_push.c.o \
    build/us/src/code/frontend/800CCEC4_controller_slot_find.c.o \
    build/us/src/code/frontend/800CD57C_controller_menu_state.c.o \
    build/us/src/code/frontend/800CD85C_results_record_write.c.o \
    build/us/asm/us/main_800CD96C_to_800CD970.s.o \
    build/us/src/code/frontend/800CD970_results_menu_callbacks.c.o \
    build/us/asm/us/main_800CDBDC_to_800CDBE0.s.o \
    build/us/src/code/frontend/800CDBE0_results_time_text.c.o \
    build/us/src/code/frontend/800CDD70_results_time_format.c.o \
    build/us/src/code/frontend/800CE188_results_time_compare.c.o \
    build/us/src/code/frontend/800CE610_results_panel_setup.c.o \
    build/us/src/code/frontend/800CE814_results_screen_setup.c.o \
    build/us/src/code/frontend/800CE9A0_results_split_setup.c.o \
    build/us/src/code/frontend/800CF0CC_results_continue.c.o \
    build/us/src/code/frontend/800CF198_results_return.c.o \
    build/us/src/code/frontend/800CF218_results_option_codes.c.o \
    build/us/src/code/frontend/800CF258_results_kills_tick.c.o \
    build/us/src/code/frontend/800CF32C_results_deaths_tick.c.o \
    build/us/src/code/frontend/800CF3E0_results_ready_flags_a.c.o \
    build/us/src/code/frontend/800CF41C_results_score_tick.c.o \
    build/us/src/code/frontend/800CF4E4_results_score_finish.c.o \
    build/us/src/code/frontend/800CF58C_results_ready_flags_b.c.o \
    build/us/src/code/frontend/800CF5C8_results_bonus_tick.c.o \
    build/us/src/code/frontend/800CF690_results_bonus_finish.c.o \
    build/us/src/code/frontend/800CF738_results_ready_flags_c.c.o \
    build/us/src/code/frontend/800CF7A8_results_time_tick.c.o \
    build/us/src/code/frontend/800CFA50_results_status_flags.c.o \
    build/us/src/code/frontend/800CFA84_results_bar_step.c.o \
    build/us/src/code/frontend/800CFBD8_results_columns_draw.c.o \
    build/us/src/code/frontend/800CFD18_results_rank_label.c.o \
    build/us/src/code/frontend/800CFDD0_results_assets_reload.c.o \
    build/us/src/code/runtime/800D0058_game_state_clear.c.o \
    build/us/src/code/frontend/800D0070_cheat_codes.c.o \
    build/us/asm/us/main_800D05D8_to_800D05E0.s.o \
    build/us/src/code/frontend/800D05E0_hud_element_unlink.c.o \
    build/us/src/code/entities/800D0814_spawn_ctl_index.c.o \
    build/us/src/code/entities/800D0858_spawn_color_lookup.c.o \
    build/us/src/code/entities/800D0960_spawn_ctl_alloc.c.o \
    build/us/src/code/frontend/800D09E0_hud_element_alloc.c.o \
    build/us/src/code/entities/800D0A74_object_interpolation_update.c.o \
    build/us/src/code/entities/800D0DF8_spawn_effect_by_type.c.o \
    build/us/src/code/entities/800D0F58_spawn_nearest_type1.c.o \
    build/us/src/code/entities/800D104C_spawn_nearest_type28.c.o \
    build/us/src/code/entities/800D1140_spawn_nearest_type31.c.o \
    build/us/src/code/entities/800D1234_spawn_counters.c.o \
    build/us/src/code/script/800D12B0_script_command_decode.c.o \
    build/us/src/code/entities/800D1C90_spawn_object_command.c.o \
    build/us/src/code/audio/800D250C_audio_listener_update.c.o \
    build/us/src/code/script/800D25E0_seq_script_tick.c.o \
    build/us/src/code/script/800D2B44_seq_spawn_script_tick.c.o \
    build/us/src/code/script/800D31DC_seq_event_script_tick.c.o \
    build/us/src/code/script/800D3554_seq_event_spawn_tick.c.o \
    build/us/src/code/script/800D3C64_seq_point_track.c.o \
    build/us/src/code/script/800D404C_seq_spawn_events_update.c.o \
    build/us/src/code/script/800D441C_seq_command_dispatch.c.o \
    build/us/src/code/script/800D4B58_seq_event_start.c.o \
    build/us/src/code/frontend/800D4D00_race_buffers_alloc.c.o \
    build/us/src/code/script/800D4DE0_seq_script_load.c.o \
    build/us/src/code/script/800D520C_seq_level_header_load.c.o \
    build/us/src/code/script/800D53D4_script_event_finish.c.o \
    build/us/src/code/script/800D5508_seq_events_update.c.o \
    build/us/src/code/frontend/800D56FC_hud_draw_list.c.o \
    build/us/asm/us/main_800D5C7C_to_800D5C80.s.o \
    build/us/src/code/script/800D5C80_script_particle_spawn.c.o \
    build/us/src/code/script/800D5E2C_script_particle_update.c.o \
    build/us/src/code/unknown/800D6508.c.o \
    build/us/src/code/render/80074F94_model_ring_identity.c.o \
    build/us/src/code/path/80071120_path_waypoint_constants.c.o \
    build/us/src/code/object_mode_constants.c.o \
    build/us/src/code/tank_motion_constant.c.o \
    build/us/src/code/hud_scale_constant.c.o \
    build/us/src/code/frontend/80073EE4_race_bar_scale_constants.c.o \
    build/us/src/code/frontend/80073EF0_race_bar_ratio_constants.c.o \
    build/us/src/code/effects/800D67F0_effect_draw.c.o \
    build/us/src/code/effects/800D69E0_effect_code_table.c.o \
    build/us/src/code/effects/800D6B80_effect_code_parse.c.o \
    build/us/asm/us/main_800D6E34_to_800D6E40.s.o \
    build/us/src/code/player/800D6E40_player_attach_effect_create.c.o \
    build/us/src/code/player/800D6EEC_player_menu_update.c.o \
    build/us/src/code/player/800D7544_player_cursor_anim.c.o \
    build/us/src/code/player/800D7638_player_menu_draw.c.o \
    build/us/src/code/player/800D7CF4_player_attach_effect_matrix.c.o \
    build/us/src/code/player/800D7D60_player_attach_effect_matrix_cb.c.o \
    build/us/asm/us/main_800D7DD4_to_800D7DE0.s.o \
    build/us/src/code/effects/800D7DE0_effect_node_spawn.c.o \
    build/us/src/code/entities/800D8050_actor_collision_free.c.o \
    build/us/src/code/entities/800D8088_actor_model_draw.c.o \
    build/us/src/code/entities/800D8380_actor_timer_update.c.o \
    build/us/asm/us/main_800D84D8_to_800D84DC.s.o \
    build/us/src/code/entities/800D84DC_actor_message_handler.c.o \
    build/us/src/code/entities/800D8674_turret_message_handlers.c.o \
    build/us/src/code/entities/800D8758_turret_state_messages.c.o \
    build/us/asm/us/main_800D88E8_to_800D88F0.s.o \
    build/us/src/code/entities/800D88F0_turret_weights_total.c.o \
    build/us/src/code/entities/800D8940_turret_weighted_pick.c.o \
    build/us/src/code/entities/800D89F8_turret_random_slot.c.o \
    build/us/src/code/entities/800D8A80_turret_model_draw.c.o \
    build/us/src/code/entities/800D8C60_turret_spawn_random.c.o \
    build/us/src/code/gameplay/800D8F28_single_player_check.c.o \
    build/us/src/code/gameplay/800D8F48_single_spawn_timer_update.c.o \
    build/us/src/code/gameplay/800D91C0_trigger_zone_query.c.o \
    build/us/asm/us/main_800D92D4_to_800D92E0.s.o \
    build/us/src/code/gameplay/800D92E0_trigger_particles_spawn.c.o \
    build/us/src/code/gameplay/800D942C_trigger_particles_update.c.o \
    build/us/src/code/gameplay/800D97EC_minimap_layer_build.c.o \
    build/us/src/code/gameplay/800D9900_minimap_blips_spawn.c.o \
    build/us/src/code/render/800D9A88_model_texture_find.c.o \
    build/us/asm/us/main_800D9B48_to_800D9B50.s.o \
    build/us/src/code/render/800D9B50_model_bounds_compute.c.o \
    build/us/src/code/render/800D9C38_model_bounds_center.c.o \
    build/us/src/code/effects/800D9D50_debris_spawn.c.o \
    build/us/src/code/effects/800DA1D8_debris_piece_update.c.o \
    build/us/src/code/effects/800DA340_debris_piece_draw.c.o \
    build/us/src/code/effects/800DA4F0_debris_burst_spawn.c.o \
    build/us/src/code/effects/800DA65C_debris_burst_spawn_tinted.c.o \
    build/us/src/code/effects/800DA7D0_debris_group_spawn.c.o \
    build/us/src/code/effects/800DA984_debris_scatter_spawn.c.o \
    build/us/src/code/weapons/800DAAE0_projectile_spawn.c.o \
    build/us/src/code/weapons/800DAC34_projectile_bounce.c.o \
    build/us/src/code/weapons/800DB1B0_projectile_segment_spawn.c.o \
    build/us/src/code/gameplay/800DB6F0_track_angle_unit.c.o \
    build/us/src/code/weapons/800DC214_projectile_model_draw.c.o \
    build/us/src/code/weapons/800DC3A8_projectile_model_create.c.o \
    build/us/src/code/weapons/800DC634_projectile_model_matrix.c.o \
    build/us/src/code/weapons/800DC6EC_projectile_model_matrix_cb.c.o \
    build/us/asm/us/main_800DC7A4_to_800DC7B0.s.o \
    build/us/src/code/weapons/800DC7B0_projectile_life_tick.c.o \
    build/us/src/code/weapons/800DC804_projectile_trail_draw.c.o \
    build/us/src/code/weapons/800DC968_projectile_fire.c.o \
    build/us/src/code/weapons/800DD0D8_projectile_launch_delayed.c.o \
    build/us/src/code/weapons/800DD1C0_projectile_launch_delayed_tick.c.o \
    build/us/asm/us/main_800DD28C_to_800DD290.s.o \
    build/us/src/code/render/800DD290_model_mesh_partition.c.o \
    build/us/src/code/world/800DD3A0_structure_create.c.o \
    build/us/src/code/world/800DD6F4_structure_flicker_roll.c.o \
    build/us/src/code/world/800DD75C_structure_hit_dispatch.c.o \
    build/us/src/code/world/800DD82C_structure_debris_spawn.c.o \
    build/us/src/code/world/800DDF04_structure_model_draw.c.o \
    build/us/src/code/world/800DE2FC_structure_owner_award.c.o \
    build/us/src/code/world/800DE374_structure_message.c.o \
    build/us/src/code/entities/800DE4DC_spawner_target_query.c.o \
    build/us/src/code/entities/800DE52C_spawner_state_update.c.o \
    build/us/src/code/entities/800DE748_spawner_owner_score.c.o \
    build/us/src/code/entities/800DE7E8_spawner_message_handler.c.o \
    build/us/src/code/entities/800DE930_unit_spawner_create.c.o \
    build/us/src/code/entities/800DEAC0_unit_spawner_update.c.o \
    build/us/asm/us/main_800DF0C4_to_800DF0D0.s.o \
    build/us/src/code/frontend/800DF0D0_slot_corners_build.c.o \
    build/us/src/code/world/800DF33C_prop_multiplayer_filter.c.o \
    build/us/src/code/frontend/800DF3B8_slot_condition_check.c.o \
    build/us/src/code/frontend/800DF558_slot_entity_attach.c.o \
    build/us/src/code/frontend/800DF63C_slot_angle_classify.c.o \
    build/us/src/code/frontend/800DF758_slot_entry_lookup.c.o \
    build/us/src/code/gameplay/800DF7A0_level_prop_points_find.c.o \
    build/us/src/code/script/800DF89C_entry_helpers.c.o \
    build/us/src/code/script/800DFA5C_entry_script_dispatch.c.o \
    build/us/src/code/world/800E1540_foliage_prop_create.c.o \
    build/us/src/code/world/800E16D8_foliage_prop_destroy.c.o \
    build/us/src/code/player/800E18D8_player_message_hit.c.o \
    build/us/src/code/world/800E1980_foliage_prop_handlers.c.o \
    build/us/src/code/player/800E1A4C_player_dispatch.c.o \
    build/us/asm/us/main_800E1BA4_to_800E1BB0.s.o \
    build/us/src/code/entities/800E1BB0_turret_sweep.c.o \
    build/us/src/code/entities/800E2018_turret_destroy.c.o \
    build/us/src/code/entities/800E21A0_turret_draw_create.c.o \
    build/us/src/code/entities/800E2520_turret_message_handlers.c.o \
    build/us/src/code/entities/800E26A8_turret_message_handler.c.o \
    build/us/src/code/gameplay/800E2810_target_search.c.o \
    build/us/src/code/entities/800E29A4_wreck_spawn.c.o \
    build/us/src/code/entities/800E2AEC_turret_spawn_at.c.o \
    build/us/src/code/entities/800E2D74_turret_line_of_sight.c.o \
    build/us/src/code/entities/800E2E0C_wreck_ctl.c.o \
    build/us/src/code/entities/800E2F9C_wreck_update.c.o \
    build/us/src/code/entities/800E3404_wreck_timer_duration.c.o \
    build/us/asm/us/main_800E3460_to_800E3FDC.s.o \
    build/us/src/code/entities/800E3FDC_entity_model_draw.c.o \
    build/us/src/code/entities/800E44C8_wreck_message_hit.c.o \
    build/us/src/code/entities/800E4530_object_damage.c.o \
    build/us/src/code/world/800E462C_flag_capture_attempt.c.o \
    build/us/src/code/world/800E48A8_flag_position_query.c.o \
    build/us/src/code/world/800E48E0_flag_owner_capture.c.o \
    build/us/src/code/world/800E4B84_flag_owner_score.c.o \
    build/us/src/code/world/800E4DA0_flag_message_dispatch.c.o \
    build/us/src/code/entities/800E4ECC_actor_kind16_link_clear.c.o \
    build/us/src/code/entities/800E4F3C_actor_wreck_spawn_at.c.o \
    build/us/src/code/audio/800E5164_sound_emitter_delayed_spawn.c.o \
    build/us/src/code/audio/800E51E8_sound_emitter_draw.c.o \
    build/us/src/code/audio/800E562C_ambient_sound_stop_first.c.o \
    build/us/asm/us/main_800E56C8_to_800E56D0.s.o \
    build/us/src/code/world/800E56D0_bridge_create_handlers.c.o \
    build/us/asm/us/main_800E58C4_to_800E58D0.s.o \
    build/us/src/code/world/800E58D0_bridge_segments_init.c.o \
    build/us/src/code/effects/800E5BB8_lightning_path_subdivide.c.o \
    build/us/asm/us/main_800E603C_to_800E6040.s.o \
    build/us/src/code/world/800E6040_bridge_piece_spawn.c.o \
    build/us/src/code/effects/800E61E8_lightning_arc_update.c.o \
    build/us/asm/us/main_800E64EC_to_800E64F0.s.o \
    build/us/src/code/world/800E64F0_crate_model_randomize.c.o \
    build/us/src/code/world/800E6540_crate_actor_attach.c.o \
    build/us/src/code/world/800E66A8_crate_particle_attach.c.o \
    build/us/src/code/world/800E68BC_crate_owner_check.c.o \
    build/us/src/code/world/800E6B04_crate_unit.c.o \
    build/us/src/code/world/800E713C_crate_contents_spawn.c.o \
    build/us/src/code/world/800E73B0_crate_part_release.c.o \
    build/us/src/code/gameplay/800E759C_pending_list_flush.c.o \
    build/us/src/code/gameplay/800E75F4_pending_spawns_flush.c.o \
    build/us/src/code/world/800E7768_crate_burst_spawn.c.o \
    build/us/src/code/world/800E7968_powerup_flag_players.c.o \
    build/us/src/code/world/800E7A10_powerup_flag_messages.c.o \
    build/us/src/code/world/800E7DF8_powerup_count_refresh.c.o \
    build/us/src/code/gameplay/800E7EE0_pickup_actor_count.c.o \
    build/us/asm/us/main_800E7F5C_to_800E7F60.s.o \
    build/us/src/code/gameplay/800E7F60_pickup_find_by_id.c.o \
    build/us/src/code/runtime/800E804C_game_mode_has_pickups.c.o \
    build/us/src/code/runtime/800E8090_game_team_compare.c.o \
    build/us/src/code/gameplay/800E80F4_multiplayer_actor_spawn.c.o \
    build/us/src/code/unknown/800E82AC.c.o \
    build/us/src/code/gameplay/800E8318_slist_remove_count.c.o \
    build/us/asm/us/main_800E8378_to_800E8380.s.o \
    build/us/src/code/frontend/800E8380_slot_asset_ranges.c.o \
    build/us/src/code/frontend/800E8C88_slot_mode_name_get.c.o \
    build/us/src/code/frontend/800E8E34_slot_mode_title_get.c.o \
    build/us/src/code/frontend/800E8F90_slot_mode_subtitle_get.c.o \
    build/us/src/code/frontend/800E9030_slot_mode_description_get.c.o \
    build/us/src/code/frontend/800E918C_slot_mode_value_get.c.o \
    build/us/asm/us/main_800E92E8_to_800E92F0.s.o \
    build/us/src/code/frontend/800E92F0_mission_select_init.c.o \
    build/us/src/code/frontend/800E9424_mission_entry_query.c.o \
    build/us/src/code/frontend/800E944C_mission_code_parse.c.o \
    build/us/src/code/frontend/800E96B4_mission_flag_set.c.o \
    build/us/src/code/frontend/800E98F8_mission_time_bonus.c.o \
    build/us/src/code/frontend/800E9990_mission_actor_spawn.c.o \
    build/us/src/code/render/800E9B50_model_pickup_create.c.o \
    build/us/src/code/render/800E9CAC_model_mode_objective_message.c.o \
    build/us/src/code/frontend/800E9E4C_mission_event_forward.c.o \
    build/us/asm/us/boot/rmon_panic_stub.s.o \
    build/us/src/code/frontend/800E9E80_mission_props_spawn.c.o \
    build/us/src/code/frontend/800EA14C_mission_targets_query.c.o \
    build/us/asm/us/main_800EA224_to_800EA714.s.o \
    build/us/src/code/frontend/800EA714_mission_marker_draw.c.o \
    build/us/src/code/render/800EA8F4_model_message_damage_u8.c.o \
    build/us/src/code/world/800EA964_building_target_query.c.o \
    build/us/src/code/world/800EA9C0_building_destroy_on_hit.c.o \
    build/us/src/code/world/800EAA68_building_damage_apply.c.o \
    build/us/src/code/render/800EAA7C_model_turret_dispatch.c.o \
    build/us/asm/us/main_800EAC2C_to_800EAC30.s.o \
    build/us/src/code/world/800EAC30_building_create.c.o \
    build/us/src/code/world/800EAE58_building_anim_frame_tick.c.o \
    build/us/src/code/unknown/800EAEB4.c.o \
    build/us/src/code/world/800EAF6C_building_destroy.c.o \
    build/us/src/code/entities/800EB308_object_handlers.c.o \
    build/us/src/code/render/800EB4FC_model_shielded_dispatch.c.o \
    build/us/asm/us/main_800EB714_to_800EB720.s.o \
    build/us/src/code/effects/800EB720_impact_flash_spawn.c.o \
    build/us/src/code/effects/800EB7BC_impact_debris_spray.c.o \
    build/us/src/code/effects/800EB838_impact_debris_emit.c.o \
    build/us/src/code/effects/800EB934_impact_flash_expire.c.o \
    build/us/asm/us/main_800EBA98_to_800EBCA8.s.o \
    build/us/src/code/player/800EBCA8_player_projectile_launch.c.o \
    build/us/asm/us/main_800EBDA0_to_800EBF80.s.o \
    build/us/src/code/unknown/800EBF80.c.o \
    build/us/src/code/frontend/800EC1C0_mission_counter_release.c.o \
    build/us/src/code/unknown/800EC1F8.c.o \
    build/us/src/code/frontend/800EC4A8_mission_objectives_update.c.o \
    build/us/src/code/gameplay/800EC72C_splash_damage_falloff.c.o \
    build/us/asm/us/main_800EC788_to_800EC790.s.o \
    build/us/src/code/weapons/800EC790_projectile_spawn_typed.c.o \
    build/us/asm/us/main_800EC8E8_to_800ECEBC.s.o \
    build/us/src/code/weapons/800ECEBC_projectile_shell_draw.c.o \
    build/us/src/code/gameplay/800ED010_shockwave_ring_spawn.c.o \
    build/us/src/code/gameplay/800ED0AC_shockwave_expand.c.o \
    build/us/src/code/gameplay/800ED1B0_shockwave_ring_draw.c.o \
    build/us/src/code/world/800ED320_destructible_prop_create.c.o \
    build/us/asm/us/main_800ED4F4_to_800ED63C.s.o \
    build/us/src/code/world/800ED63C_destructible_anim_frame_tick.c.o \
    build/us/asm/us/main_800ED694_to_800ED698.s.o \
    build/us/src/code/render/800ED698_model_message_damage_destroy.c.o \
    build/us/src/code/weapons/800ED730_projectile_target_query.c.o \
    build/us/src/code/world/800ED774_destructible_prop_on_hit.c.o \
    build/us/src/code/world/800ED7BC_destructible_prop_on_hit_alt.c.o \
    build/us/src/code/gameplay/800ED804_message_dispatch.c.o \
    build/us/src/code/world/800EDC00_prop_destroy_slot_release.c.o \
    build/us/src/code/unknown/800EDDCC.c.o \
    build/us/src/code/world/800EDF14_prop_message_shatter.c.o \
    build/us/src/code/world/800EE0B0_prop_target_query.c.o \
    build/us/src/code/world/800EE0E8_prop_debris_burst_on_hit.c.o \
    build/us/src/code/world/800EE1B8_prop_debris_burst_on_hit_alt.c.o \
    build/us/src/code/entities/800EE288_entity_message.c.o \
    build/us/src/code/gameplay/800EE490_motion_scale_curve.c.o \
    build/us/src/code/world/800EE688_prop_spawn_child.c.o \
    build/us/src/code/world/800EE7F8_prop_spawn_pickup.c.o \
    build/us/src/code/world/800EE8C0_prop_height_update.c.o \
    build/us/src/code/world/800EEADC_barrier_break_open.c.o \
    build/us/src/code/gameplay/800EED90_segment_update.c.o \
    build/us/src/code/effects/800EF400_effect_segment_append.c.o \
    build/us/src/code/effects/800EF578_effect_segments_draw.c.o \
    build/us/asm/us/main_800EF770_to_800EFB30.s.o \
    build/us/src/code/effects/800EFB30_effect_message_damage.c.o \
    build/us/src/code/effects/800EFB90_effect_message_damage_guarded.c.o \
    build/us/src/code/effects/800EFBFC_particle_emitter_tail.c.o \
    build/us/asm/us/main_800EFC68_to_800EFC70.s.o \
    build/us/src/code/effects/800EFC70_particle_emitter_create.c.o \
    build/us/src/code/effects/800EFE10_particle_pool_init.c.o \
    build/us/src/code/effects/800EFEC4_particle_emitter_free.c.o \
    build/us/src/code/effects/800F0064_particle_emitter_update.c.o \
    build/us/src/code/unknown/800F01F0.c.o \
    build/us/src/code/effects/800F0618_particle_free_list.c.o \
    build/us/src/code/effects/800F0658_particle_smoke_update.c.o \
    build/us/src/code/effects/800F0930_particle_node_list.c.o \
    build/us/src/code/gameplay/800F0A20_rotated_texture_coords.c.o \
    build/us/src/code/effects/800F0B08_particle_hit_spawn.c.o \
    build/us/src/code/effects/800F0ED0_particle_system_create.c.o \
    build/us/src/code/effects/800F11D0_particle_owner_message.c.o \
    build/us/asm/us/main_800F1278_to_800F1770.s.o \
    build/us/src/code/render/800F1770_anim_list_register_global.c.o \
    build/us/asm/us/main_800F17AC_to_800F17B0.s.o \
    build/us/src/code/render/800F17B0_anim_keyframes_apply.c.o \
    build/us/asm/us/main_800F1900_to_800F1B30.s.o \
    build/us/src/code/world/800F1B30_hazard_actor_spawn.c.o \
    build/us/src/code/world/800F1CC8_hazard_actor_spawn_simple.c.o \
    build/us/src/code/world/800F1D94_hazard_state_update.c.o \
    build/us/src/code/world/800F2050_hazard_model_draw.c.o \
    build/us/asm/us/main_800F2184_to_800F2288.s.o \
    build/us/src/code/world/800F2288_hazard_message_handler.c.o \
    build/us/src/code/entities/800F24F8_object_state_query.c.o \
    build/us/src/code/gameplay/800F265C_mine_message_handlers.c.o \
    build/us/src/code/gameplay/800F2980_mine_trigger_update.c.o \
    build/us/asm/us/main_800F2BB8_to_800F2BC0.s.o \
    build/us/src/code/world/800F2BC0_powerup_pad_create.c.o \
    build/us/src/code/world/800F2DB4_powerup_timer_update.c.o \
    build/us/src/code/world/800F3098_powerup_pad_draw.c.o \
    build/us/asm/us/main_800F3208_to_800F32EC.s.o \
    build/us/src/code/world/800F32EC_barrel_handlers.c.o \
    build/us/src/code/world/800F352C_barrel_explode.c.o \
    build/us/src/code/gameplay/800F36D0_falling_crate_update.c.o \
    build/us/src/code/gameplay/800F38C0_decal_spawn_draw.c.o \
    build/us/asm/us/main_800F3B7C_to_800F3B80.s.o \
    build/us/src/code/render/800F3B80_color_interpolate.c.o \
    build/us/src/code/gameplay/800F3D04_mesh_vertex_transform.c.o \
    build/us/src/code/gameplay/800F3F78_mesh_rings_draw.c.o \
    build/us/asm/us/main_800F4D74_to_800F4D80.s.o \
    build/us/src/code/gameplay/800F4D80_mesh_wave_update.c.o \
    build/us/src/code/gameplay/800F4FF0_tracer_spawn.c.o \
    build/us/src/code/gameplay/800F50B8_tracer_trail_update.c.o \
    build/us/asm/us/main_800F5264_to_800F5270.s.o \
    build/us/src/code/effects/800F5270_effect_table_reset.c.o \
    build/us/src/code/effects/800F5298_effect_prop_spawn.c.o \
    build/us/src/code/effects/800F5470_effect_targets_query.c.o \
    build/us/src/code/effects/800F5548_effect_targets_damage.c.o \
    build/us/src/code/effects/800F577C_effect_burn_update.c.o \
    build/us/src/code/effects/800F5B3C_effect_beam_draw.c.o \
    build/us/src/code/gameplay/800F5E18_generator_damage_apply.c.o \
    build/us/src/code/gameplay/800F5F10_generator_message_damage.c.o \
    build/us/src/code/gameplay/800F6100_generator_hit_query.c.o \
    build/us/src/code/gameplay/800F6144_generator_splash_damage.c.o \
    build/us/src/code/gameplay/800F6344_generator_damage_tick.c.o \
    build/us/src/code/gameplay/800F64B8_generator_dispatch_bonus.c.o \
    build/us/asm/us/main_800F6648_to_800F6650.s.o \
    build/us/src/code/gameplay/800F6650_generator_spawn.c.o \
    build/us/src/code/effects/800F67C8_effect_expire_100.c.o \
    build/us/asm/us/main_800F67F0_to_800F6C70.s.o \
    build/us/src/code/effects/800F6C70_effect_billboard_draw.c.o \
    build/us/src/code/entities/800F6ED0_wreck_debris_spawn.c.o \
    build/us/src/code/entities/800F708C_wreck_debris_update.c.o \
    build/us/src/code/render/800F7150_anim_colors_set.c.o \
    build/us/src/code/render/800F71FC_anim_list_create.c.o \
    build/us/src/code/unknown/800F7230.c.o \
    build/us/src/code/render/800F756C_anim_list_reset.c.o \
    build/us/src/code/render/800F757C_anim_list_register.c.o \
    build/us/asm/us/main_800F7648_to_800F7650.s.o \
    build/us/src/code/effects/800F7650_effect_motion_update.c.o \
    build/us/src/code/render/800F7870_anim_alpha_fade_draw.c.o \
    build/us/src/code/gameplay/800F799C_spark_spawn.c.o \
    build/us/src/code/gameplay/800F7A80_spark_burst_update.c.o \
    build/us/src/code/gameplay/800F7BA4_smoke_puff_spawn.c.o \
    build/us/asm/us/main_800F7C24_to_800F7C30.s.o \
    build/us/src/code/effects/800F7C30_flicker_prop_create.c.o \
    build/us/src/code/effects/800F7D24_flicker_prop_draw.c.o \
    build/us/src/code/effects/800F7E14_flicker_prop_message.c.o \
    build/us/src/code/effects/800F7E64_flicker_prop_message_cb.c.o \
    build/us/asm/us/main_800F7EB8_to_800F7EC0.s.o \
    build/us/src/code/gameplay/800F7EC0_static_prop_create.c.o \
    build/us/src/code/gameplay/800F7F6C_static_prop_expire.c.o \
    build/us/src/code/gameplay/800F7F84_static_prop_draw.c.o \
    build/us/asm/us/main_800F809C_to_800F80A0.s.o \
    build/us/src/code/gameplay/800F80A0_static_in_radius.c.o \
    build/us/src/code/render/800F80E8_model_variant_get.c.o \
    build/us/src/code/render/800F8208_model_cache_globals.c.o \
    build/us/src/code/render/800F8264_model_in_draw_range.c.o \
    build/us/asm/us/main_800F83B8_to_800F83C0.s.o \
    build/us/src/code/weapons/800F83C0_artillery_emplacement_update.c.o \
    build/us/src/code/weapons/800F85D8_artillery_emplacement_disable.c.o \
    build/us/src/code/weapons/800F85F0_artillery_emplacement_create.c.o \
    build/us/asm/us/main_800F865C_to_800F8660.s.o \
    build/us/src/code/weapons/800F8660_artillery_projectile_create.c.o \
    build/us/src/code/weapons/800F872C_artillery_target_track.c.o \
    build/us/asm/us/main_800F8AAC_to_801029D0.s.o \
    build/us/src/libultra/os_ai_get_length.c.o \
    build/us/src/libultra/os_ai_get_status.c.o \
    build/us/asm/us/main_801029F0_to_80103160.s.o \
    build/us/src/libultra/os_ai_device_busy.c.o \
    build/us/asm/us/main_80103190_to_801037B0.s.o \
    build/us/src/libultra/al_copy.c.o \
    build/us/src/libultra/os_create_mesg_queue.c.o \
    build/us/src/libultra/os_create_thread.c.o \
    build/us/asm/us/main_801039B0_to_80104EC0.s.o \
    build/us/src/libultra/os_epi_start_dma.c.o \
    build/us/asm/us/main_80104FA0_to_801058B0.s.o \
    build/us/src/libultra/os_destroy_thread.c.o \
    build/us/src/libultra/al_filter_new.c.o \
    build/us/src/libultra/os_get_time.c.o \
    build/us/asm/us/main_80105A60_to_80105A70.s.o \
    build/us/src/libultra/al_heap_alloc.c.o \
    build/us/src/libultra/al_heap_init.c.o \
    build/us/asm/us/main_80105B10_to_80105F20.s.o \
    build/us/src/libultra/os_jam_mesg.c.o \
    build/us/asm/us/main_80106070_to_801068F0.s.o \
    build/us/src/libultra/os_epi_raw_start_dma.c.o \
    build/us/src/libultra/os_leo_disk_init.c.o \
    build/us/src/libultra/ll.c.o \
    build/us/asm/us/main_80106EE0_to_80107A30.s.o \
    build/us/src/libultra/gu_look_at.c.o \
    build/us/asm/us/main_80107D60_to_80108530.s.o \
    build/us/src/libultra/os_cont_ram_write.c.o \
    build/us/src/libultra/os_cont_ram_read.c.o \
    build/us/src/libultra/os_cont_crc.c.o \
    build/us/src/libultra/gu_mtx.c.o \
    build/us/asm/us/main_80109030_to_80109090.s.o \
    build/us/src/libultra/gu_perspective.c.o \
    build/us/src/libultra/cosf.c.o \
    build/us/asm/us/main_80109490_to_8010A9A0.s.o \
    build/us/src/libultra/os_pfs_delete_file.c.o \
    build/us/src/libultra/os_pfs_file_state.c.o \
    build/us/src/libultra/os_pfs_free_blocks.c.o \
    build/us/src/libultra/os_pfs_get_status.c.o \
    build/us/src/libultra/os_pfs_init_pak.c.o \
    build/us/src/libultra/os_pfs_checker.c.o \
    build/us/src/libultra/os_pfs_is_plug.c.o \
    build/us/src/libultra/os_pfs_read_write_file.c.o \
    build/us/src/libultra/os_pfs_get_id_copy.c.o \
    build/us/src/libultra/os_pfs_find_file.c.o \
    build/us/src/libultra/os_pi_start_dma.c.o \
    build/us/src/libultra/os_pi_get_cmd_queue.c.o \
    build/us/asm/us/main_8010CFA0_to_8010D660.s.o \
    build/us/src/libultra/os_get_thread_pri.c.o \
    build/us/src/libultra/os_pi_access.c.o \
    build/us/src/libultra/os_pi_raw_start_dma.c.o \
    build/us/src/libultra/os_recv_mesg.c.o \
    build/us/asm/us/main_8010D9C0_to_8010DCC0.s.o \
    build/us/src/libultra/os_reset_global_int_mask.c.o \
    build/us/src/libultra/al_reverb.c.o \
    build/us/src/libultra/gu_rotate.c.o \
    build/us/src/libultra/gu_normalize.c.o \
    build/us/src/libultra/al_save_param.c.o \
    build/us/src/libultra/al_save_pull.c.o \
    build/us/src/libultra/sched.c.o \
    build/us/src/libultra/os_dp_set_next_buffer.c.o \
    build/us/src/libultra/os_dp_device_busy.c.o \
    build/us/src/libultra/os_send_mesg.c.o \
    build/us/src/libultra/os_set_event_mesg.c.o \
    build/us/asm/us/main_8010F890_to_8010F8A0.s.o \
    build/us/src/libultra/os_set_global_int_mask.c.o \
    build/us/asm/us/main_8010F8F0_to_8010F9A0.s.o \
    build/us/src/libultra/os_set_thread_pri.c.o \
    build/us/src/libultra/os_set_timer.c.o \
    build/us/src/libultra/os_si_access_queue.c.o \
    build/us/src/libultra/sinf.c.o \
    build/us/src/libultra/os_si_raw_start_dma.c.o \
    build/us/src/libultra/os_si_device_busy.c.o \
    build/us/src/libultra/os_si_raw_read_io.c.o \
    build/us/src/libultra/os_si_raw_write_io.c.o \
    build/us/src/libultra/al_main.c.o \
    build/us/src/libultra/sprintf.c.o \
    build/us/src/libultra/os_sp_set_pc.c.o \
    build/us/src/libultra/os_sp_task.c.o \
    build/us/src/libultra/os_sp_device_busy.c.o \
    build/us/src/libultra/os_sp_raw_start_dma.c.o \
    build/us/src/libultra/os_sp_set_status.c.o \
    build/us/src/libultra/os_sp_task_yield.c.o \
    build/us/src/libultra/os_sp_task_yielded.c.o \
    build/us/src/libultra/os_sp_get_status.c.o \
    build/us/asm/us/main_80110550_to_80110560.s.o \
    build/us/src/libultra/os_start_thread.c.o \
    build/us/src/libultra/string.c.o \
    build/us/src/libultra/al_syn_delete.c.o \
    build/us/src/libultra/al_synthesizer.c.o \
    build/us/src/libultra/al_syn_alloc_fx.c.o \
    build/us/src/libultra/os_dequeue_thread.c.o \
    build/us/src/libultra/os_timer.c.o \
    build/us/asm/us/main_80111320_to_80111330.s.o \
    build/us/src/libultra/os_vi_black.c.o \
    build/us/src/libultra/os_vi_init.c.o \
    build/us/src/libultra/os_vi_get_current_framebuffer.c.o \
    build/us/src/libultra/os_vi_get_next_framebuffer.c.o \
    build/us/src/libultra/os_vi_manager.c.o \
    build/us/src/libultra/os_vi_get_current_context.c.o \
    build/us/src/libultra/os_virtual_to_physical.c.o \
    build/us/asm/us/main_80111950_to_80111A10.s.o \
    build/us/src/libultra/os_vi_set_event.c.o \
    build/us/src/libultra/os_vi_set_mode.c.o \
    build/us/src/libultra/os_vi_set_special_features.c.o \
    build/us/src/libultra/os_vi_swap_buffer.c.o \
    build/us/src/libultra/os_vi_swap_context.c.o \
    build/us/asm/us/main_80112060_to_80112110.s.o \
    build/us/src/libultra/xprintf.c.o \
    build/us/src/libultra/xldtob.c.o \
    build/us/src/libultra/ldiv.c.o \
    build/us/src/libultra/litob.c.o \
    build/us/src/libultra/os_yield_thread.c.o \
    build/us/asm/us/main_8011449C_to_80171000.s.o \
    > build/us/undefined_object_symbols.txt
fi

# Source-owned constant pools recovered from the remaining gameplay rodata.
while read -r unit rodata_size; do
    python3 tools/trim_elf32_section.py \
        "build/us/src/code/${unit}.c.o" .rodata "$rodata_size" --alignment 4
done <<'RODATA_UNITS'
script/800D5E2C_script_particle_update 0x38
entities/800E3FDC_entity_model_draw 0x48
entities/800D8088_actor_model_draw 0x44
frontend/800CC2F8_controller_slots_scan 0x2C
effects/800DA340_debris_piece_draw 0x44
effects/800DA984_debris_scatter_spawn 0x4
unknown/800C0C38 0x4
unknown/8007D5B0 0x8
unknown/80082004 0xC
unknown/80086190 0x4C
unknown/800867C4 0x38
unknown/80087798 0x4
unknown/800879F8 0x4
gameplay/80122384_gameplay_definition_data 0x99
frontend/800C1468_hud_transition 0x4
effects/800E61E8_lightning_arc_update 0x54
render/800D9C38_model_bounds_center 0x1C
player/800D7544_player_cursor_anim 0x8
player/800D7638_player_menu_draw 0x28
player/800D6EEC_player_menu_update 0x20
weapons/800DC3A8_projectile_model_create 0x44
weapons/800DC214_projectile_model_draw 0x4C
frontend/800DF63C_slot_angle_classify 0x8
entities/800D8A80_turret_model_draw 0x44
entities/800DEAC0_unit_spawner_update 0x44
gameplay/800F38C0_decal_spawn_draw 0x44
effects/800F5B3C_effect_beam_draw 0x48
effects/800F6C70_effect_billboard_draw 0x44
effects/800F5548_effect_targets_damage 0x1C
effects/800F7D24_flicker_prop_draw 0x44
world/800F2050_hazard_model_draw 0x44
effects/800EB7BC_impact_debris_spray 0x4
frontend/800E96B4_mission_flag_set 0xB
world/800F2BC0_powerup_pad_create 0xC
world/800F3098_powerup_pad_draw 0x48
weapons/800ECEBC_projectile_shell_draw 0x48
gameplay/800ED0AC_shockwave_expand 0x10
gameplay/800ED1B0_shockwave_ring_draw 0xC
gameplay/800ED010_shockwave_ring_spawn 0x4
gameplay/800EC72C_splash_damage_falloff 0xC
gameplay/800F7F84_static_prop_draw 0x44
effects/80116580_effect_runtime_tables 0xEC
RODATA_UNITS

find build/us/asm build/us/src -type f -name '*.o' -print0 \
    | xargs -0 "${tool_prefix}nm" -u \
    > build/us/undefined_object_symbols.txt
python3 tools/generate_linker_symbols.py build/us/symbols.ld \
    config/us/symbol_addrs.txt \
    build/us/undefined_syms_auto.txt \
    build/us/undefined_funcs_auto.txt \
    --undefined-list build/us/undefined_object_symbols.txt \
    --symbol rspbootTextEnd=0x800F8E80 \
    --symbol gspF3DEX_fifoTextStart=0x800F8E80 \
    --symbol gspF3DEX_fifoDataStart=0x80125EC0 \
    --symbol osDestroyThread=0x801058B0 \
    --symbol func_8E180004=0x8E180004 \
    --symbol func_80000000=0x80000000 \
    --symbol D_803A66C0=0x803A66C0

python3 tools/place_unit_rodata.py battletanx_ga.ld config/us/unit_rodata.tsv \
    build/us/battletanx_ga.placed.ld --bss-table config/us/unit_bss.tsv \
    --data-table config/us/unit_data.tsv
"${tool_prefix}ld.bfd" -EB --no-check-sections \
    -T build/us/symbols.ld -T build/us/battletanx_ga.placed.ld \
    -Map build/us/battletanx_ga.map \
    -o build/us/battletanx_ga.elf
"${tool_prefix}objcopy" -O binary -R '.unit_rodata_*' -R '.unit_data_*' \
    build/us/battletanx_ga.elf build/us/battletanx_ga.code.bin
python3 tools/splice_unit_rodata.py build/us/battletanx_ga.elf \
    config/us/unit_rodata.tsv build/us/battletanx_ga.code.bin \
    --data-table config/us/unit_data.tsv

actual_size="$(wc -c < build/us/battletanx_ga.code.bin)"
[[ "$actual_size" -eq 1052672 ]] || {
    echo "Reconstructed code region is $actual_size bytes; expected 1052672" >&2
    exit 1
}

echo "Built exact-reconstruction candidate: build/us/battletanx_ga.code.bin"
