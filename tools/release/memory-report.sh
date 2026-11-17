#!/bin/sh
#
# Report where the static memory goes in a device build, as Markdown.
#
#   tools/release/memory-report.sh <build dir>
#
# Reads rockbox.elf, rockbox.map and the codec .elf files a normal `make`
# leaves in the build dir. Covers what the link map can tell: core section
# sizes, core IRAM split by area and by object, every DSP object's IRAM and
# code size, and each codec's IRAM. Runtime numbers (audio buffer, dircache,
# buflib free space) need the device's System > Debug menus.
#
# build.yml appends the output to the job summary. Needs gawk.

set -eu

dir=${1:?usage: memory-report.sh <build dir>}
size=${CROSS:-arm-elf-eabi-}size

# Every input section placed by the core link: "<section> <bytes> <object>".
# ld prints a long section name on a line of its own, with the address,
# size and object on the next.
sections() {
    gawk '
    function emit(sec, sz, obj) {
        sz = strtonum(sz)
        if (sz > 0) print sec, sz, obj
    }
    /^Linker script and memory map/ { on = 1; next }
    !on { next }
    /^ \.[^ ]+$/ { pend = $1; next }
    /^ \.[^ ]+ +0x[0-9a-f]+ +0x[0-9a-f]+ / { emit($1, $3, $4); pend = ""; next }
    pend != "" && /^ +0x[0-9a-f]+ +0x[0-9a-f]+ / { emit(pend, $2, $3) }
    { pend = "" }' "$dir/rockbox.map"
}

# Objects built from lib/rbcodec/dsp/. librbcodec.a also carries the
# metadata parsers, so the archive name alone does not say "dsp".
dsp=$(cd "$(dirname "$0")/../../lib/rbcodec/dsp" &&
      ls *.c *.S | sed 's/\.[cS]$/.o/' | tr '\n' ' ')

# Shared by the tables below. "lib/librbcodec.a(eq.o)" becomes area
# "dsp", object "eq.o".
lib='
BEGIN { n = split(DSP, d, " "); for (i = 1; i <= n; i++) isdsp[d[i]] = 1 }
function kind(sec) {
    if (sec ~ /^\.(icode|irodata|idata|ibss|qharray)/) return "iram"
    if (sec ~ /^\.(text|rodata|glue|init)/)            return "code"
    return "other"
}
function area(obj) {
    if (obj ~ /rbcodec/ && base(obj) in isdsp) return "dsp"
    if (obj ~ /rbcodec/)                       return "rbcodec other"
    if (obj ~ /(^|\/)apps\//)                  return "apps"
    if (obj ~ /firmware/)                      return "firmware"
    return "other"
}
function base(obj) {
    sub(/\)$/, "", obj); sub(/.*[\/(]/, "", obj); return obj
}
'

echo "## Memory report"
echo
echo "### Core sections"
echo
echo '```'
$size -A "$dir/rockbox.elf" | gawk 'NR > 2 && $2 > 0 { printf "%-14s %8d\n", $1, $2 }'
echo '```'
echo
echo "Core IRAM is 48KB (0xc000); codecs and plugins get the other 80KB."
echo
echo "### Core IRAM by area"
echo
echo "| Area | IRAM bytes | Code bytes |"
echo "| --- | ---: | ---: |"
sections | gawk -v DSP="$dsp" "$lib"'
    { k = kind($1); a = area($3); t[a, k] += $2; seen[a] = 1 }
    END { for (a in seen) printf "| %s | %d | %d |\n", a, t[a, "iram"], t[a, "code"] }' |
    sort -t'|' -k3 -rn
echo
echo "### Top 15 core IRAM users"
echo
echo "| Object | Area | IRAM bytes |"
echo "| --- | --- | ---: |"
sections | gawk -v DSP="$dsp" "$lib"'
    kind($1) == "iram" { o = base($3); t[o] += $2; ar[o] = area($3) }
    END { for (o in t) printf "| %s | %s | %d |\n", o, ar[o], t[o] }' |
    sort -t'|' -k4 -rn | head -15
echo
echo "### DSP objects"
echo
echo "| Object | IRAM bytes | Code bytes |"
echo "| --- | ---: | ---: |"
sections | gawk -v DSP="$dsp" "$lib"'
    area($3) == "dsp" { o = base($3); t[o, kind($1)] += $2; seen[o] = 1 }
    END { for (o in seen) printf "| %s | %d | %d |\n", o, t[o, "iram"], t[o, "code"] }' |
    sort -t'|' -k3 -rn
echo
echo "### Codec IRAM"
echo
echo "| Codec | IRAM bytes | Code bytes |"
echo "| --- | ---: | ---: |"
for elf in "$dir"/lib/rbcodec/codecs/*.elf; do
    [ -e "$elf" ] || continue
    $size -A "$elf" | gawk -v n="$(basename "$elf" .elf)" '
        $1 ~ /^\.i(ram|bss)/ { i += $2 }
        $1 ~ /^\.(text|rodata|data)$/ { t += $2 }
        END { printf "| %s | %d | %d |\n", n, i, t }'
done | sort -t'|' -k3 -rn
