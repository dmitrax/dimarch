#!/usr/bin/env bash
# install/apps/scribe.sh
# dimarch-scribe — local speech-to-text toolkit (whisper.cpp + Vulkan/RADV)
#
# Optional app, not part of the numbered phases — install on demand.
# AMD GPU only (RADV Vulkan backend). Builds whisper.cpp from source, so
# this takes real time/CPU — not a quick package install like the other
# apps in this directory.
#
# See https://github.com/dmitrax/dimarch-scribe for the full project.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$REPO_ROOT/install/utils/helpers.sh"

SCRIBE_REPO_DIR="$HOME/Projects/dimarch-scribe"
WHISPER_BUILD_DIR="$HOME/builds/whisper.cpp"
MODEL_DIR="$HOME/.local/share/dimarch-scribe/models"
MODEL_NAME="medium"

if command -v scribe &>/dev/null; then
    info "scribe already installed — skipping"
    echo ""
    echo "  scribe video.mp4"
    exit 0
fi

# ── System dependencies ─────────────────────────────────────────────────────

info "Installing system dependencies..."
sudo pacman -S --needed --noconfirm \
    python \
    python-pipx \
    ffmpeg \
    cmake \
    vulkan-headers \
    spirv-headers

pipx ensurepath

ok "System dependencies installed"

# ── Clone dimarch-scribe ─────────────────────────────────────────────────────

if [[ -d "$SCRIBE_REPO_DIR" ]]; then
    info "dimarch-scribe already cloned at ${SCRIBE_REPO_DIR} — not touching it"
else
    info "Cloning dimarch-scribe..."
    mkdir -p "$(dirname "$SCRIBE_REPO_DIR")"
    git clone https://github.com/dmitrax/dimarch-scribe "$SCRIBE_REPO_DIR"
    ok "Cloned to ${SCRIBE_REPO_DIR}"
fi

# ── Build whisper.cpp with Vulkan ───────────────────────────────────────────

if command -v whisper-cli &>/dev/null; then
    info "whisper-cli already built — skipping"
else
    info "Building whisper.cpp with Vulkan support (this takes a while)..."
    bash "${SCRIBE_REPO_DIR}/scripts/build-whisper-cpp-vulkan.sh"
    ok "whisper.cpp built, whisper-cli installed to ~/.local/bin/"
fi

# ── Download model ───────────────────────────────────────────────────────────

if [[ -f "${MODEL_DIR}/ggml-${MODEL_NAME}.bin" ]]; then
    info "Model '${MODEL_NAME}' already downloaded — skipping"
else
    info "Downloading Whisper model '${MODEL_NAME}'..."
    mkdir -p "$MODEL_DIR"
    bash "${WHISPER_BUILD_DIR}/models/download-ggml-model.sh" "$MODEL_NAME" "$MODEL_DIR"
    ok "Model downloaded to ${MODEL_DIR}"
fi

# ── Install scribe / dscribe ─────────────────────────────────────────────────

info "Installing dimarch-scribe (editable pipx install)..."
pipx install -e "$SCRIBE_REPO_DIR" --python /usr/bin/python
ok "dimarch-scribe installed"

# ── Done ──────────────────────────────────────────────────────────────────

info "Done"
echo ""
echo "  scribe video.mp4                    # → video.md next to the source"
echo "  scribe video.mp4 --lang ru --save x  # → \$SCRIBE_SAVE_DIR/x.md"
echo ""
echo "  Thunar's \"Transcribe with scribe\" right-click action (deployed by"
echo "  06-dotfiles.sh's xfce tree) will now work instead of showing the"
echo "  \"not installed\" notice."
