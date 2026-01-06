#!/usr/bin/env bash
# Improved image pipeline based on main.sh.
# Optional env overrides:
#   INPUT_DIR=<path>   # defaults to ./s
#   OUTPUT_DIR=<path>  # defaults to ./s25
#   LOGO_PATH=<path>   # defaults to ./logo/c.png
#   GMIC_UPDATE_FILE=<path> # optional gmic stdlib; defaults to ~/.config/gmic/update326.gmic when present
#   JOBS=<n>           # parallel workers (auto-detected when unset)

set -euo pipefail

log() {
  printf '[%s] %s\n' "$(date +'%H:%M:%S')" "$*"
}

fail() {
  echo "Error: $*" >&2
  exit 1
}

detect_cpus() {
  if command -v getconf >/dev/null 2>&1; then
    getconf _NPROCESSORS_ONLN 2>/dev/null && return
  fi
  if command -v sysctl >/dev/null 2>&1; then
    sysctl -n hw.ncpu 2>/dev/null && return
  fi
  printf '4\n'
}

require_cmds() {
  for cmd in "$@"; do
    command -v "$cmd" >/dev/null 2>&1 || fail "Missing dependency: $cmd"
  done
}

run_parallel() {
  parallel "${PARALLEL_OPTS[@]}" "$@"
}

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

INPUT_DIR="${INPUT_DIR:-$SCRIPT_DIR/s}"
OUTPUT_DIR="${OUTPUT_DIR:-$SCRIPT_DIR/s25}"
LOGO_PATH="${LOGO_PATH:-$SCRIPT_DIR/logo/c.png}"
JOBS="${JOBS:-$(detect_cpus)}"
PARALLEL_OPTS=(--no-notice --halt soon,fail=1 --jobs "$JOBS")

STAGE_S1="$SCRIPT_DIR/s1"
STAGE_S3="$SCRIPT_DIR/s3"
STAGE_S6="$SCRIPT_DIR/s6"
STAGE_S7="$SCRIPT_DIR/s7"
STAGE_S9="$SCRIPT_DIR/s9"
STAGE_S17="$SCRIPT_DIR/s17"

ALL_STAGE_DIRS=()
for n in {1..25}; do
  ALL_STAGE_DIRS+=("$SCRIPT_DIR/s$n")
done

require_cmds parallel convert mogrify gmic
[[ -f "$LOGO_PATH" ]] || fail "Logo not found at $LOGO_PATH"

GMIC_UPDATE_FILE="${GMIC_UPDATE_FILE:-$HOME/.config/gmic/update326.gmic}"
GMIC_PREFIX="gmic"
USE_GMIC_UPDATE=false
if [[ -f "$GMIC_UPDATE_FILE" ]]; then
  GMIC_PREFIX+=' -m "'"$GMIC_UPDATE_FILE"'"'
  USE_GMIC_UPDATE=true
  log "Using gmic update file $GMIC_UPDATE_FILE"
else
  log "Warning: gmic update file not found at $GMIC_UPDATE_FILE; using built-in commands"
fi

log "Using $JOBS parallel jobs"

log "Preparing stage directories"
mkdir -p "$INPUT_DIR" "$OUTPUT_DIR"
for dir in "${ALL_STAGE_DIRS[@]}"; do
  mkdir -p "$dir"
  rm -rf "$dir"/*
done

shopt -s nullglob
INPUT_FILES=("$INPUT_DIR"/*.*)
shopt -u nullglob
(( ${#INPUT_FILES[@]} )) || fail "No input files found in $INPUT_DIR"

log "Resizing inputs to 2500x2500 and normalizing to png"
run_parallel 'convert {} -resize 2500x2500 {.}.png' ::: "${INPUT_FILES[@]}"
find "$INPUT_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' \) -delete

shopt -s nullglob
INPUT_FILES=("$INPUT_DIR"/*.*)
shopt -u nullglob
(( ${#INPUT_FILES[@]} )) || fail "No input files available after resize step"

log "Copying base images to $OUTPUT_DIR"
run_parallel 'convert {} "'"$OUTPUT_DIR"'/{/}"' ::: "${INPUT_FILES[@]}"

log "Applying logo overlay -> s9"
run_parallel 'convert {} "'"$LOGO_PATH"'" -alpha set -compose darken -composite "'"$STAGE_S9"'/{/}"' ::: "${INPUT_FILES[@]}"

shopt -s nullglob
FILES_S9=("$STAGE_S9"/*.*)
shopt -u nullglob
(( ${#FILES_S9[@]} )) || fail "Logo overlay step produced no files"

log "Exporting mon7 variants -> $OUTPUT_DIR"
run_parallel 'convert {} -set filename:new "'"$OUTPUT_DIR"'/{/.}mon7" "%[filename:new].png"' ::: "${FILES_S9[@]}"

log "Creating brightened layer -> s1"
run_parallel 'convert {} -modulate 100,250,100 "'"$STAGE_S1"'/{/}"' ::: "${FILES_S9[@]}"

shopt -s nullglob
FILES_S1=("$STAGE_S1"/*.*)
shopt -u nullglob
(( ${#FILES_S1[@]} )) || fail "Modulate step produced no files"

log "Softlight blending with logo layer -> s3"
run_parallel 'convert {1} "'"$STAGE_S9"'/{/}" -alpha set -channel A -evaluate set 100% -compose softlight -composite "'"$STAGE_S3"'/{/}"' ::: "${FILES_S1[@]}"

shopt -s nullglob
FILES_S3=("$STAGE_S3"/*.*)
shopt -u nullglob
(( ${#FILES_S3[@]} )) || fail "Softlight blend produced no files"

log "Applying AbstractFlood effect -> s6"
run_parallel 'gmic -input {1} -fx_AbstractFlood 1,10,7,2,0,10,5,3,255,255,255,255,0,300,10,90,0.7,0,0,0 -o "'"$STAGE_S6"'/{/}"' ::: "${FILES_S3[@]}"

shopt -s nullglob
FILES_S6=("$STAGE_S6"/*.*)
shopt -u nullglob
(( ${#FILES_S6[@]} )) || fail "AbstractFlood step produced no files"

log "Exporting mon7cpu1 variants -> $OUTPUT_DIR"
run_parallel 'convert {1} -set filename:new "'"$OUTPUT_DIR"'/{/.}mon7cpu1" "%[filename:new].png"' ::: "${FILES_S6[@]}"

log "Applying layer cake effect -> s7"
run_parallel 'gmic {1} -fx_layer_cake 4,360,0,75,50,50,3,1,0,30,0,3,0,0,50,50 -o "'"$STAGE_S7"'/{/}"' ::: "${FILES_S6[@]}"

shopt -s nullglob
FILES_S7=("$STAGE_S7"/*.*)
shopt -u nullglob
(( ${#FILES_S7[@]} )) || fail "Layer cake step produced no files"

log "Resizing layer cake results to 3000x3000"
run_parallel 'mogrify -resize 3000x3000 {1}' ::: "${FILES_S7[@]}"

log "Exporting mon7cpu1_cake variants -> $OUTPUT_DIR"
run_parallel 'convert {1} -set filename:new "'"$OUTPUT_DIR"'/{/.}mon7cpu1_cake" "%[filename:new].png"' ::: "${FILES_S7[@]}"

log "Applying custom deformation -> s17"
if $USE_GMIC_UPDATE; then
  run_parallel "$GMIC_PREFIX {1} -fx_custom_deformation \"(w+h)/30*cos(y*20/h)\",\"(w+h)/30*sin(x*20/w)\",1,1,3 -o \"$STAGE_S17/{/}\"" ::: "${FILES_S7[@]}"
else
  run_parallel 'gmic {1} +norm. . f.. "(w+h)/30*cos(y*20/h)" f. "(w+h)/30*sin(x*20/w)" a[-2,-1] c warp.. .,1,1,3,1 rm. mv. 0 -o "'"$STAGE_S17"'/{/}"' ::: "${FILES_S7[@]}"
fi

shopt -s nullglob
FILES_S17=("$STAGE_S17"/*.*)
shopt -u nullglob
(( ${#FILES_S17[@]} )) || fail "Custom deformation step produced no files"

log "Exporting mon7cpu1_cake_cartesian30 variants -> $OUTPUT_DIR"
run_parallel 'convert {1} -set filename:new "'"$OUTPUT_DIR"'/{/.}mon7cpu1_cake_cartesian30" "%[filename:new].png"' ::: "${FILES_S17[@]}"

log "Done. Final outputs are in $OUTPUT_DIR"
