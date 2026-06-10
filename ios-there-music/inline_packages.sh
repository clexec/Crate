#!/usr/bin/env bash
# ============================================================================
# inline_packages.sh
#
# Inlines YMAPI and YouTubeKit SPM packages into the Monk Xcode target
# so that `import YMAPI` / `import YouTubeKit` are no longer needed.
#
# Designed for Xcode projects using PBXFileSystemSynchronizedRootGroup
# (Xcode 16+), which auto-includes ALL .swift files under Monk/.
#
# WHAT IT DOES:
#   1. Copies YMAPI .swift sources  -> Monk/Services/YMAPI/   (preserving subdirs)
#   2. Copies YouTubeKit .swift sources -> Monk/Services/YouTubeKit/ (preserving subdirs)
#   3. Copies non-Swift resources (PrivacyInfo.xcprivacy, .js bundles)
#   4. Renames files whose basenames collide with existing Monk files (e.g. Track.swift -> YMTrack.swift)
#   5. Renames conflicting YMAPI TYPE names with YM prefix throughout ALL inlined YMAPI files
#   6. Removes `import YMAPI` and `import YouTubeKit` from Monk files
#   7. Replaces `YMAPI.Track` -> `YMTrack`, `YMAPI.Playlist` -> `YMPlaylist`, etc. in Monk files
#   8. Handles YouTubeKit types (already YT-prefixed, no type conflicts expected)
#
# USAGE (GitHub Actions):
#   chmod +x inline_packages.sh
#   ./inline_packages.sh
#
# The script is idempotent – safe to re-run (it cleans previous inlined dirs first).
# ============================================================================

set -euo pipefail

# ── Project paths ────────────────────────────────────────────────────────────
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
MONK_DIR="$PROJECT_ROOT/Monk"
YMAPI_SRC="$PROJECT_ROOT/Packages/YM-API/Sources/YMAPI"
YTKIT_SRC="$PROJECT_ROOT/Packages/YouTubeKit/Sources/YouTubeKit"

YMAPI_DEST="$MONK_DIR/Services/YMAPI"
YTKIT_DEST="$MONK_DIR/Services/YouTubeKit"

# ── Colours (for CI log readability) ────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INLINE]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# ── Pre-flight checks ───────────────────────────────────────────────────────
[[ -d "$MONK_DIR" ]]   || error "Monk/ directory not found at $MONK_DIR"
[[ -d "$YMAPI_SRC" ]]  || error "YMAPI sources not found at $YMAPI_SRC"
[[ -d "$YTKIT_SRC" ]]  || error "YouTubeKit sources not found at $YTKIT_SRC"

# ── Step 1: Clean any previous inlined directories ──────────────────────────
info "Cleaning previous inlined directories..."
rm -rf "$YMAPI_DEST" "$YTKIT_DEST"

# ── Step 2: Copy package sources into Monk/Services/ ────────────────────────
info "Copying YMAPI sources -> Monk/Services/YMAPI/ ..."
mkdir -p "$YMAPI_DEST"
# Use rsync for fast recursive copy preserving structure
rsync -a --include='*.swift' --include='*.xcprivacy' --exclude='*.md' --exclude='*.txt' "$YMAPI_SRC/" "$YMAPI_DEST/"

info "Copying YouTubeKit sources -> Monk/Services/YouTubeKit/ ..."
mkdir -p "$YTKIT_DEST"
rsync -a --include='*.swift' --include='*.js' --exclude='*.md' --exclude='*.txt' --exclude='*.yml' --exclude='*.plist' "$YTKIT_SRC/" "$YTKIT_DEST/"

# ── Step 3: Collect existing Monk file basenames (BEFORE adding inlined files) ─
info "Scanning existing Monk .swift file basenames for collision detection..."
MONK_BASENAMES_FILE=$(mktemp)
# Only scan the original Monk files (not the just-copied YMAPI/YouTubeKit dirs)
find "$MONK_DIR" -name '*.swift' -not -path "$YMAPI_DEST/*" -not -path "$YTKIT_DEST/*" -exec basename {} \; | sort -u > "$MONK_BASENAMES_FILE"
MONK_COUNT=$(wc -l < "$MONK_BASENAMES_FILE")
info "Found $MONK_COUNT existing Monk .swift basenames"

# ── Step 4: Rename colliding FILES in the inlined directories ────────────────
info "Checking for filename collisions..."

# --- YMAPI filename collisions with Monk ---
COLLISIONS_FOUND=0
while IFS= read -r f; do
    bn="$(basename "$f")"
    if rg -qx "$bn" "$MONK_BASENAMES_FILE" 2>/dev/null; then
        new_bn="YM${bn}"
        dir="$(dirname "$f")"
        mv "$f" "$dir/$new_bn"
        warn "  YMAPI filename collision: $bn -> $new_bn"
        COLLISIONS_FOUND=$((COLLISIONS_FOUND + 1))
    fi
done < <(find "$YMAPI_DEST" -name '*.swift')

# --- YouTubeKit filename collisions with Monk ---
while IFS= read -r f; do
    bn="$(basename "$f")"
    if rg -qx "$bn" "$MONK_BASENAMES_FILE" 2>/dev/null; then
        new_bn="YT${bn}"
        dir="$(dirname "$f")"
        mv "$f" "$dir/$new_bn"
        warn "  YouTubeKit filename collision: $bn -> $new_bn"
        COLLISIONS_FOUND=$((COLLISIONS_FOUND + 1))
    fi
done < <(find "$YTKIT_DEST" -name '*.swift')

# --- Also check YMAPI <-> YouTubeKit internal filename collisions ---
# Build a list of YMAPI basenames
YMAPI_BN_FILE=$(mktemp)
find "$YMAPI_DEST" -name '*.swift' -exec basename {} \; | sort -u > "$YMAPI_BN_FILE"

while IFS= read -r f; do
    bn="$(basename "$f")"
    if rg -qx "$bn" "$YMAPI_BN_FILE" 2>/dev/null; then
        new_bn="YT${bn}"
        dir="$(dirname "$f")"
        mv "$f" "$dir/$new_bn"
        warn "  YMAPI<->YouTubeKit filename collision: $bn -> $new_bn (YouTubeKit)"
        COLLISIONS_FOUND=$((COLLISIONS_FOUND + 1))
    fi
done < <(find "$YTKIT_DEST" -name '*.swift')

rm -f "$MONK_BASENAMES_FILE" "$YMAPI_BN_FILE"

if [[ $COLLISIONS_FOUND -eq 0 ]]; then
    info "No filename collisions detected."
fi

# ── Step 5: Rename conflicting TYPE names in YMAPI inlined files ────────────
#
# These YMAPI types conflict with Monk types of the same name:
#   Track   -> YMTrack    (Monk has struct Track)
#   User    -> YMUser     (Monk has struct User)
#   Album   -> YMAlbum    (Monk has struct Album)
#   Artist  -> YMArtist   (Monk has struct Artist)
#   Playlist -> YMPlaylist (Monk has struct Playlist)
#   Genre   -> YMGenre    (Monk has struct Genre)
#
# These YMAPI types DON'T conflict with Monk but are renamed for safety:
#   Video   -> YMVideo
#   Search  -> YMSearch
#   Like    -> YMLike
#   Queue   -> YMQueue
#   Shot    -> YMShot
#
# We use Perl with \b word-boundary matching to avoid partial matches
# (e.g. "Track" matches but "TrackId", "TrackShort" do NOT).

info "Renaming conflicting YMAPI types in inlined files..."

# Build a single Perl command that does ALL renames in one pass.
# This is much faster than running perl separately for each type rename.
# Order matters: do longer names first, then shorter ones.
# Since none of these are substrings of each other (Playlist is not in Artist, etc.)
# the order actually doesn't matter for \b matching, but we keep it safe.

YM_TYPE_RENAMES=(
    "Playlist:YMPlaylist"
    "Artist:YMArtist"
    "Album:YMAlbum"
    "Genre:YMGenre"
    "Track:YMTrack"
    "Search:YMSearch"
    "Video:YMVideo"
    "User:YMUser"
    "Queue:YMQueue"
    "Like:YMLike"
    "Shot:YMShot"
)

# Build the Perl substitution expression
PERL_EXPR=""
for mapping in "${YM_TYPE_RENAMES[@]}"; do
    OLD="${mapping%%:*}"
    NEW="${mapping##*:}"
    info "  YMAPI type rename: $OLD -> $NEW"
    PERL_EXPR="${PERL_EXPR}s/\\b${OLD}\\b/${NEW}/g;"
done

# Apply ALL type renames in a single pass across ALL YMAPI files
find "$YMAPI_DEST" -name '*.swift' | xargs perl -pi -e "$PERL_EXPR"

# ── Step 6: Handle YouTubeKit type conflicts ────────────────────────────────
info "Checking YouTubeKit types for Monk conflicts..."
# YouTubeKit uses YT prefix for all its types (YTVideo, YTPlaylist, YTChannel,
# YTComment, YTCaption, etc.). No type name conflicts with Monk expected.
info "YouTubeKit types already YT-prefixed - no type renames needed."

# ── Step 7: Remove `import YMAPI` and `import YouTubeKit` from Monk files ──
info "Removing 'import YMAPI' and 'import YouTubeKit' from Monk files..."

find "$MONK_DIR" -name '*.swift' -not -path "$YMAPI_DEST/*" -not -path "$YTKIT_DEST/*" | \
    xargs perl -pi -e 's/^import YMAPI\s*\n//g; s/^import YouTubeKit\s*\n//g;'

# ── Step 8: Update Monk files to use renamed YMAPI types ────────────────────
# In Monk files, `YMAPI.Track` was used to disambiguate from the app's Track.
# Now that the YMAPI types are renamed, replace:
#   YMAPI.Track    -> YMTrack
#   YMAPI.Playlist -> YMPlaylist
#   YMAPI.Album    -> YMAlbum
# etc.

info "Updating Monk files to use renamed YMAPI types..."

# Build the Perl substitution expression for Monk files (YMAPI.Type -> YMType)
MONK_PERL_EXPR=""
for mapping in "${YM_TYPE_RENAMES[@]}"; do
    OLD="${mapping%%:*}"
    NEW="${mapping##*:}"
    MONK_PERL_EXPR="${MONK_PERL_EXPR}s/YMAPI\\.${OLD}\\b/${NEW}/g;"
done

find "$MONK_DIR" -name '*.swift' -not -path "$YMAPI_DEST/*" -not -path "$YTKIT_DEST/*" | \
    xargs perl -pi -e "$MONK_PERL_EXPR"

# ── Step 9: Update Monk files that reference YouTubeKit types ────────────────
# YouTubeKit types are already uniquely named (YTVideo, SearchResponse, etc.)
# No module-qualification was used in the code (just `import YouTubeKit`),
# so the bare type names already work in the same module.
info "YouTubeKit types already uniquely named - no Monk file updates needed."

# ── Step 10: Remove excessive blank lines left by deleted import statements ──
info "Cleaning up blank lines from removed import statements..."
find "$MONK_DIR" -name '*.swift' | xargs perl -pi -00 -e 's/\n{3,}/\n\n/g'

# ── Step 11: Verification ───────────────────────────────────────────────────
info "Running verification checks..."

ERRORS=0

# Check 1: No remaining import YMAPI / import YouTubeKit in Monk files
remaining_imports=$(rg -l 'import YMAPI|import YouTubeKit' "$MONK_DIR" --glob '!Services/YMAPI/**' --glob '!Services/YouTubeKit/**' --type swift 2>/dev/null || true)
if [[ -n "$remaining_imports" ]]; then
    echo -e "${RED}  FAIL:${NC} Found remaining 'import YMAPI/YouTubeKit' in: $remaining_imports"
    ERRORS=$((ERRORS + 1))
else
    info "  OK: No remaining 'import YMAPI' or 'import YouTubeKit' in Monk files"
fi

# Check 2: No remaining YMAPI.ModuleType references in Monk files
remaining_qualified=$(rg -l 'YMAPI\.' "$MONK_DIR" --glob '!Services/YMAPI/**' --type swift 2>/dev/null || true)
if [[ -n "$remaining_qualified" ]]; then
    warn "  WARN: Found remaining 'YMAPI.' references in Monk files: $remaining_qualified"
    warn "         These may be in comments or strings and might be harmless."
else
    info "  OK: No remaining 'YMAPI.' qualified references in Monk files"
fi

# Check 3: No duplicate basenames across the entire Monk/ tree
dup_check=$(find "$MONK_DIR" -name '*.swift' -exec basename {} \; | sort | uniq -d)
if [[ -n "$dup_check" ]]; then
    echo -e "${RED}  FAIL:${NC} Duplicate .swift basenames (will cause .o collision): $dup_check"
    ERRORS=$((ERRORS + 1))
else
    info "  OK: No duplicate .swift basenames in Monk/"
fi

# Check 4: Verify key renamed types exist in inlined files
for mapping in "${YM_TYPE_RENAMES[@]}"; do
    NEW="${mapping##*:}"
    if rg -q "\\bclass ${NEW}\\b" "$YMAPI_DEST" --type swift 2>/dev/null; then
        info "  OK: Found 'class $NEW' in YMAPI inlined files"
    else
        warn "  WARN: Did not find 'class $NEW' declaration in YMAPI inlined files (may be struct/enum)"
    fi
done

# Check 5: Verify the Monk app types still exist (weren't accidentally renamed)
for typ in Track User Album Artist Playlist Genre Comment Recommendation; do
    if rg -q "\\bstruct ${typ}\\b" "$MONK_DIR" --glob '!Services/YMAPI/**' --glob '!Services/YouTubeKit/**' --type swift 2>/dev/null; then
        info "  OK: Monk type '$typ' struct still exists"
    elif rg -q "\\benum ${typ}\\b" "$MONK_DIR" --glob '!Services/YMAPI/**' --glob '!Services/YouTubeKit/**' --type swift 2>/dev/null; then
        info "  OK: Monk type '$typ' enum still exists"
    else
        warn "  WARN: Monk type '$typ' not found as struct/enum (may be OK if not all are defined)"
    fi
done

# ── Summary ─────────────────────────────────────────────────────────────────
echo ""
echo "============================================"
info "Inline complete!"
echo "============================================"
echo ""
info "YMAPI sources   : $YMAPI_DEST/ ($(find "$YMAPI_DEST" -name '*.swift' | wc -l | tr -d ' ') .swift files)"
info "YouTubeKit sources: $YTKIT_DEST/ ($(find "$YTKIT_DEST" -name '*.swift' | wc -l | tr -d ' ') .swift files)"
echo ""
info "Type renames applied to YMAPI files:"
for mapping in "${YM_TYPE_RENAMES[@]}"; do
    OLD="${mapping%%:*}"
    NEW="${mapping##*:}"
    echo "  $OLD -> $NEW"
done
echo ""

if [[ $ERRORS -gt 0 ]]; then
    error "Verification failed with $ERRORS error(s). Review the output above."
else
    info "All verification checks passed."
fi
