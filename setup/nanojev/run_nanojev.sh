#!/usr/bin/env bash
# One-shot setup + run for NanoJev (model only, no dataset).
#
# Usage:
#   ./run_nanojev.sh                    # runs a built-in sample request
#   ./run_nanojev.sh request.json       # runs your own request file
#   ./run_nanojev.sh --serve            # HTTP endpoint (POST /api/evaluate), set up for your Wi-Fi
#
# Serve mode and the local network:
#   WSL2:         nothing to change on the Linux side. Run expose_nanojev_windows.ps1 once from
#                 Windows (PowerShell, administrator) to forward the port and open the firewall.
#   native Linux: passes --host 0.0.0.0 if the server supports it and opens the port in ufw
#                 for private address ranges only.
#
# The endpoint has NO authentication. Only use it on a network you trust.
#
# Env overrides:
#   NANOJEV_HOME           install dir (default: ~/nanojev)
#   NANOJEV_DEVICE         torch device (default: cuda:0, one-shot mode only)
#   NANOJEV_PORT           server port (default: 8765, --serve only)
#   NANOJEV_EXTERNAL_PORT  port other PCs use on WSL2 (default: NANOJEV_PORT + 1; only used in the printed hint)
#
# Needs: Linux or WSL2, python3 (+ venv module), git (--serve), an NVIDIA GPU with CUDA drivers.

set -euo pipefail

WORKDIR="${NANOJEV_HOME:-$HOME/nanojev}"
DEVICE="${NANOJEV_DEVICE:-cuda:0}"
PORT="${NANOJEV_PORT:-8765}"
EXTERNAL_PORT="${NANOJEV_EXTERNAL_PORT:-$((PORT + 1))}"
SERVE=0
REQUEST_FILE=""
for arg in "$@"; do
  case "$arg" in
    --serve) SERVE=1 ;;
    *) REQUEST_FILE="$arg" ;;
  esac
done
REPO_URL="https://github.com/TianyuCodings/NanoJev.git"
REQ_URL="https://raw.githubusercontent.com/TianyuCodings/NanoJev/main/requirements-toy.txt"

log() { printf '\n==> %s\n' "$*"; }

# ---- Local network access (serve mode) --------------------------------------
SERVER_EXTRA_ARGS=()

is_wsl() { grep -qi microsoft /proc/version 2>/dev/null; }

lan_setup() {
  if is_wsl; then
    log "Local network access (WSL2)"
    echo "Nothing to change on the Linux side: the server on 127.0.0.1:${PORT} is already reachable from Windows."
    echo "To reach it from other PCs on your Wi-Fi, run the Windows script once (PowerShell on the host PC):"
    echo "  powershell -ExecutionPolicy Bypass -File .\\expose_nanojev_windows.ps1 -Port ${PORT} -ExternalPort ${EXTERNAL_PORT}"
    echo "It asks for administrator rights. Other PCs then call http://<windows-lan-ip>:${EXTERNAL_PORT}/api/evaluate"
    echo "Re-run it if the PC's IP address changes. Test from another PC: Test-NetConnection <windows-lan-ip> -Port ${EXTERNAL_PORT}"
    echo "The endpoint has no authentication: only use it on a network you trust."
  else
    log "Local network access (Linux)"
    if grep -q -- '--host' "$WORKDIR/repo/scripts/serve_decisions.py"; then
      SERVER_EXTRA_ARGS+=(--host 0.0.0.0)
      echo "The server will listen on all interfaces (--host 0.0.0.0)."
    else
      echo "WARNING: serve_decisions.py does not appear to have a --host option, so it may stay on 127.0.0.1."
      echo "Check: grep -n 'host\|127.0.0.1' $WORKDIR/repo/scripts/serve_decisions.py"
    fi
    if command -v ufw >/dev/null 2>&1; then
      echo "Allowing port ${PORT} in ufw for private address ranges (sudo may ask for your password)."
      for range in 192.168.0.0/16 10.0.0.0/8 172.16.0.0/12; do
        sudo ufw allow from "$range" to any port "$PORT" proto tcp || true
      done
    else
      echo "ufw not found. If you use another firewall, allow TCP port ${PORT} from your local network yourself."
    fi
    local ip
    ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
    if [ -n "$ip" ]; then
      echo "Other PCs on your network can call http://${ip}:${PORT}/api/evaluate"
    fi
    echo "The endpoint has no authentication: only use it on a network you trust."
  fi
}

# ---- 1. Sanity checks -------------------------------------------------------
command -v python3 >/dev/null || { echo "python3 not found"; exit 1; }
python3 -c "import venv" 2>/dev/null || {
  echo "python3 venv module missing. On Ubuntu/WSL2: sudo apt install python3-venv"
  exit 1
}
if command -v nvidia-smi >/dev/null; then
  nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
else
  echo "WARNING: nvidia-smi not found. The model expects a CUDA GPU."
fi

mkdir -p "$WORKDIR"
cd "$WORKDIR"

# ---- 2. Virtualenv + dependencies ------------------------------------------
if [ ! -f .venv/bin/activate ]; then
  log "Creating virtualenv"
  rm -rf .venv .deps_installed
  python3 -m venv .venv
fi
# shellcheck disable=SC1091
source .venv/bin/activate

if [ ! -f .deps_installed ]; then
  log "Installing dependencies"
  python -m pip install --upgrade pip
  curl -fsSL "$REQ_URL" -o requirements-toy.txt
  python -m pip install -r requirements-toy.txt huggingface_hub
  touch .deps_installed
else
  log "Dependencies already installed (delete $WORKDIR/.deps_installed to redo)"
fi

# ---- 3. Runner script -------------------------------------------------------
cat > run_model.py <<'PY'
import json
import os
import sys

from huggingface_hub import snapshot_download

DEVICE = os.environ.get("NANOJEV_DEVICE", "cuda:0")
MODEL_DIR = os.path.join(os.getcwd(), "model")

# Download the checkpoint + inference source only (no dataset). Skips files already present.
path = snapshot_download(
    "C-Tianyu/NanoJev",
    revision="unified-games-v1",
    token=False,
    local_dir=MODEL_DIR,
    allow_patterns=[
        "best.safetensors",
        "config.json",
        "backbone_config/*",
        "tokenizer/*",
        "source/*",
    ],
)

if len(sys.argv) > 1 and sys.argv[1] == "--download-only":
    print("Model ready at", path)
    sys.exit(0)

sys.path.insert(0, os.path.join(path, "source", "scripts"))
from predict_toy_decisions import DecisionPredictor  # noqa: E402

model = DecisionPredictor(
    path,
    device_name=DEVICE,
    precision="bf16",
    disable_native_triton=True,
)

if len(sys.argv) > 1:
    with open(sys.argv[1], "r", encoding="utf-8") as f:
        request = json.load(f)
else:
    request = {
        "states": [
            {
                "id": "example",
                "state": "The target is left of the aim.",
                "questions": {
                    "action": {
                        "type": "choice",
                        "instructions": "Choose the next action.",
                        "criteria": {
                            "left": "Move the aim left.",
                            "right": "Move the aim right.",
                            "shoot": "Fire.",
                            "noop": "Wait.",
                        },
                    }
                },
            }
        ]
    }

answer = model.predict(request)
print(json.dumps(answer, indent=2, default=str))
PY

# ---- 4. Run -----------------------------------------------------------------
if [ "$SERVE" -eq 1 ]; then
  command -v git >/dev/null || { echo "git not found (needed once to fetch serve_decisions.py)"; exit 1; }

  log "Downloading model (first run only)"
  python run_model.py --download-only

  # The server script lives in the GitHub repo, so fetch a shallow copy (code only, small).
  if [ ! -d repo/.git ]; then
    log "Fetching server code"
    git clone --depth 1 "$REPO_URL" repo
  fi

  lan_setup

  log "Starting server on http://127.0.0.1:${PORT}  (POST /api/evaluate) - Ctrl+C to stop"
  cd repo
  exec python scripts/serve_decisions.py \
    --checkpoint-dir "$WORKDIR/model" \
    --web-root web \
    --port "$PORT" \
    --disable-native-triton \
    ${SERVER_EXTRA_ARGS[@]+"${SERVER_EXTRA_ARGS[@]}"}
fi

log "Downloading model (first run only) and running"
if [ -n "$REQUEST_FILE" ]; then
  # Resolve relative path against the caller's directory
  case "$REQUEST_FILE" in
    /*) ;;
    *) REQUEST_FILE="$OLDPWD/$REQUEST_FILE" ;;
  esac
  NANOJEV_DEVICE="$DEVICE" python run_model.py "$REQUEST_FILE"
else
  NANOJEV_DEVICE="$DEVICE" python run_model.py
fi