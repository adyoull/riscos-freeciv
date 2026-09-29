#!/bin/bash
# Compare the ICU-free string functions in utility/support.c (FREECIV_NO_ICU,
# patch 0001) with ICU itself, on the host: every nation and city name in
# Freeciv's rulesets plus some hand-picked Latin/Greek/Cyrillic/Vietnamese
# words, each compared with its next 60 neighbours in sorted order.
#   tests/no-icu/run.sh          (needs gcc and libicu-dev)
# Expected: full mismatches 0, strlcpy problems 0. A few n-limited
# mismatches are expected: ICU counts UTF-16 units before folding "ß" to
# "ss", our code counts folded characters.
set -e
. "$(dirname "$0")/../../build/env.sh"
FC=$SRC/freeciv-$FREECIV_TAG
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
python3 - "$FC/utility/support.c" "$T" <<'PY'
import sys
s=open(sys.argv[1]).read(); out=sys.argv[2]
a=s.index('/* Decode the code point at *s and advance *s past it. */')
b=s.index('/****', s.index('static int fc_utf8_casecmp', a))
open(out+'/no_icu_code.c','w').write(s[a:b])
k=s.index('#ifdef FREECIV_NO_ICU\n  size_t len;')+len('#ifdef FREECIV_NO_ICU\n')
e=s.index('#else  /* FREECIV_NO_ICU */',k)
open(out+'/no_icu_strlcpy.c','w').write(s[k:e].replace('fc_assert_ret_val','ASSERT'))
PY
gcc -O1 -I"$T" "$(dirname "$0")/harness.c" -o "$T/t" -licuuc
{ grep -h 'name *= *_("' "$FC"/data/nation/*.ruleset | sed 's/.*_("\(.*\)").*/\1/'
  grep -h '^ *"[^"]*",' "$FC"/data/nation/*.ruleset | sed 's/^ *"\([^"]*\)".*/\1/'
  printf 'ÄBC\näbc\nÉcole\nécole\nΣΟΦΙΑ\nσοφια\nσοφιας\nΣΟΦΙΑΣ\nМосква\nМОСКВА\nĐà Nẵng\nĐÀ NẴNG\nStraße\nSTRASSE\n'
} | sort -u > "$T/words"
"$T/t" < "$T/words" | tail -1
