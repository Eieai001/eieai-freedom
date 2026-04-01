#!/bin/bash
set -euo pipefail

WORKSPACE="/Users/eieai/.openclaw/workspace-main"
MEMORY_DIR="$WORKSPACE/memory"
LONG_TERM_MEMORY="$WORKSPACE/MEMORY.md"
DEFAULT_ARM_HOST="ubuntu@144.24.73.140"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/output"
mkdir -p "$OUTPUT_DIR"

TARGET_DATE="$(date +%F)"
DRY_RUN=0
SKIP_REMOTE=0
MEMOS_SYNC=1
ARM_HOST="${ARM_HOST:-$DEFAULT_ARM_HOST}"
MEMOS_BASE_URL="${MEMOS_BASE_URL:-}"
MEMOS_TOKEN="${MEMOS_TOKEN:-}"
PAGE_SIZE="${MEMOS_PAGE_SIZE:-100}"

usage() {
  cat <<'EOF'
Daily summary -> Memos

Usage:
  ./daily-summary-to-memos.sh [options]

Options:
  --date YYYY-MM-DD   Summarize a specific day
  --dry-run           Generate summary and save locally, skip Memos sync
  --skip-remote       Do not SSH to ARM for remote status
  --arm-host HOST     Override ARM SSH target (default: ubuntu@144.24.73.140)
  --help              Show help

Required env for Memos sync:
  MEMOS_BASE_URL      e.g. https://memos.eieai.us.ci
  MEMOS_TOKEN         Bearer token for Memos API

Optional env:
  MEMOS_PAGE_SIZE     Default 100
EOF
}

log() {
  printf '[daily-summary] %s\n' "$1"
}

fail() {
  printf '[daily-summary] ERROR: %s\n' "$1" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --date)
      TARGET_DATE="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      MEMOS_SYNC=0
      shift
      ;;
    --skip-remote)
      SKIP_REMOTE=1
      shift
      ;;
    --arm-host)
      ARM_HOST="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      fail "Unknown argument: $1"
      ;;
  esac
done

DAY_MEMORY_FILE="$MEMORY_DIR/$TARGET_DATE.md"
[[ -f "$DAY_MEMORY_FILE" ]] || fail "Daily memory file not found: $DAY_MEMORY_FILE"
[[ -f "$LONG_TERM_MEMORY" ]] || fail "Long-term memory file not found: $LONG_TERM_MEMORY"

SUMMARY_FILE="$OUTPUT_DIR/daily-ai-infra-summary-$TARGET_DATE.md"
REMOTE_FILE="$OUTPUT_DIR/remote-status-$TARGET_DATE.txt"
META_FILE="$OUTPUT_DIR/memos-sync-$TARGET_DATE.json"

generate_remote_status() {
  if [[ "$SKIP_REMOTE" -eq 1 ]]; then
    printf 'Remote status skipped by flag.\n' > "$REMOTE_FILE"
    return
  fi

  log "Collecting remote ARM status from $ARM_HOST"

  if ! ssh -o BatchMode=yes -o ConnectTimeout=8 -o StrictHostKeyChecking=accept-new "$ARM_HOST" '
    echo "== happy daemon status =="
    happy daemon status 2>&1 || true
    echo
    echo "== process snapshot =="
    ps aux | grep -E "happy|cloudflared|hapi|claude|codex|opencode|openclaw" | grep -v grep | head -20 || true
    echo
    echo "== recent happy logs =="
    tail -30 ~/.happy/logs/*.log 2>/dev/null | tail -50 || true
  ' > "$REMOTE_FILE" 2>&1; then
    printf 'Remote status unavailable from %s\n\n' "$ARM_HOST" > "$REMOTE_FILE"
    printf 'SSH collection failed or timed out.\n' >> "$REMOTE_FILE"
  fi
}

generate_summary() {
  log "Generating summary for $TARGET_DATE"
  python3 - "$TARGET_DATE" "$DAY_MEMORY_FILE" "$LONG_TERM_MEMORY" "$REMOTE_FILE" "$SUMMARY_FILE" <<'PY'
import json
import pathlib
import re
import sys
from collections import OrderedDict
from typing import Optional

TARGET_DATE, day_file, memory_file, remote_file, out_file = sys.argv[1:6]

day_text = pathlib.Path(day_file).read_text(encoding="utf-8")
long_term_text = pathlib.Path(memory_file).read_text(encoding="utf-8")
remote_text = pathlib.Path(remote_file).read_text(encoding="utf-8") if pathlib.Path(remote_file).exists() else ""

system_keywords = OrderedDict([
    ("OpenClaw", ["openclaw"]),
    ("Claude Code", ["claude code", "claude"]),
    ("OpenCode", ["opencode", "open code"]),
    ("Codex", ["codex"]),
    ("Oracle Cloud / ARM", ["oracle", "arm", "happy", "hapi", "cloudflared", "cloudflare tunnel", "ssh"]),
])

sensitive_patterns = [
    r"(?i)token",
    r"(?i)api key",
    r"(?i)access key",
    r"(?i)secret",
    r"(?i)password",
    r"(?i)主密码",
    r"(?i)邮箱:",
    r"(?i)bearer",
    r"(?i)sk-[A-Za-z0-9_-]+",
    r"(?i)eyJ[a-zA-Z0-9_-]{10,}",
    r"[A-Za-z0-9_-]{24,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}",
]

blocked_line_keywords = [
    "token", "主密码", "密码", "api key", "access key", "secret", "sk-", "邮箱:",
]

status_positive = ["✅", "完成", "成功", "正常", "运行中", "已安装", "已配置", "已完成", "工作正常", "可用"]
status_negative = ["❗", "⚠️", "失败", "错误", "问题", "待完成", "待确认", "待跟进", "未完成", "需", "不可", "中断", "阻塞"]
next_markers = ["待完成", "待后续跟进", "待确认", "下一步", "todo", "follow-up", "待做"]


def sanitize(line: str) -> Optional[str]:
    raw = line.strip()
    if not raw:
        return None
    raw = re.sub(r"^[-*]\s+", "", raw)
    raw = re.sub(r"^[0-9]+\.\s+", "", raw)
    lowered = raw.lower()
    if any(k in lowered for k in blocked_line_keywords):
        return None
    for pattern in sensitive_patterns:
        if re.search(pattern, raw):
            return None
    raw = re.sub(r"\s+", " ", raw)
    return raw[:240]


def detect_system(text: str):
    lowered = text.lower()
    hits = []
    for system, keywords in system_keywords.items():
        if any(keyword in lowered for keyword in keywords):
            hits.append(system)
    return hits

systems = {
    name: {"done": [], "blockers": [], "next": [], "signals": [], "status": "Gray"}
    for name in system_keywords
}

overall = []
follow_up = []
source_refs = [day_file]

current_h2 = ""
current_h3 = ""
current_system_context = []

for line in day_text.splitlines():
    if line.startswith("## "):
        current_h2 = sanitize(line[3:]) or ""
        current_h3 = ""
        current_system_context = detect_system(current_h2)
        continue
    if line.startswith("### "):
        current_h3 = sanitize(line[4:]) or ""
        current_system_context = detect_system(current_h3) or detect_system(current_h2)
        continue

    cleaned = sanitize(line)
    if not cleaned:
        continue

    explicit = detect_system(cleaned)
    matched_systems = explicit or current_system_context
    if not matched_systems and any(marker in cleaned for marker in ["今日成就", "今日反思", "重要更新", "重要发现", "完成项目"]):
        continue

    is_next = any(marker in cleaned for marker in next_markers) or re.match(r"^[0-9]+\. ", cleaned)
    is_negative = any(marker in cleaned for marker in status_negative)
    is_positive = any(marker in cleaned for marker in status_positive)

    if (line.startswith("- ") or line.startswith("* ") or re.match(r"^[0-9]+\. ", line.strip())) and len(overall) < 10:
        if matched_systems and not is_next and len(cleaned) > 8:
            overall.append(cleaned)

    for system in matched_systems:
        bucket = systems[system]
        bucket["signals"].append(cleaned)
        if is_next:
            bucket["next"].append(cleaned)
        elif is_negative:
            bucket["blockers"].append(cleaned)
        elif is_positive:
            bucket["done"].append(cleaned)
        else:
            if len(bucket["done"]) < 3:
                bucket["done"].append(cleaned)

for system, bucket in systems.items():
    score = len(bucket["done"]) - len(bucket["blockers"])
    if bucket["blockers"]:
        bucket["status"] = "Yellow" if score >= 0 else "Red"
    elif bucket["done"]:
        bucket["status"] = "Green"
    else:
        bucket["status"] = "Gray"

if remote_text.strip():
    remote_lines = []
    for line in remote_text.splitlines():
        cleaned = sanitize(line)
        if cleaned and not cleaned.startswith("=="):
            remote_lines.append(cleaned)
    remote_preview = remote_lines[:8]
    if remote_preview:
        systems["Oracle Cloud / ARM"]["signals"].extend(remote_preview)
        if any("unavailable" in s.lower() or "failed" in s.lower() for s in remote_preview):
            systems["Oracle Cloud / ARM"]["blockers"].append("Remote ARM status collection failed or timed out.")
            systems["Oracle Cloud / ARM"]["status"] = "Yellow"
        else:
            systems["Oracle Cloud / ARM"]["done"].append("Collected remote ARM runtime snapshot via SSH.")
    source_refs.append(remote_file)

for system in systems.values():
    for key in ["done", "blockers", "next", "signals"]:
        items = []
        seen = set()
        for item in system[key]:
            if item not in seen:
                seen.add(item)
                items.append(item)
        system[key] = items[:5]

if not overall:
    overall = ["No major update captured in daily memory."]

for bucket in systems.values():
    for item in bucket["next"]:
        if item not in follow_up:
            follow_up.append(item)
follow_up = follow_up[:5] or ["No explicit follow-up captured."]

key_signals = []
for name, bucket in systems.items():
    for item in bucket["signals"][:2]:
        tagged = f"{name}: {item}"
        if tagged not in key_signals:
            key_signals.append(tagged)
key_signals = key_signals[:10]

context_refs = []
for line in long_term_text.splitlines():
    cleaned = sanitize(line)
    if cleaned and any(token in cleaned.lower() for token in ["ssh 命令", "日志", "已有路由", "happy daemon", "claude code"]):
        context_refs.append(cleaned)
context_refs = context_refs[:5]

lines = []
lines.append(f"# Daily AI Infra Summary - {TARGET_DATE}")
lines.append("")
lines.append("## Overall")
for item in overall[:6]:
    lines.append(f"- {item}")
lines.append("")
lines.append("## By System")
for name, bucket in systems.items():
    lines.append("")
    lines.append(f"### {name}")
    lines.append(f"- Status: {bucket['status']}")
    if bucket["done"]:
        lines.append("- Done today:")
        for item in bucket["done"][:3]:
            lines.append(f"  - {item}")
    else:
        lines.append("- Done today:")
        lines.append("  - no major update")
    if bucket["blockers"]:
        lines.append("- Blocker:")
        for item in bucket["blockers"][:3]:
            lines.append(f"  - {item}")
    else:
        lines.append("- Blocker:")
        lines.append("  - none captured")
    if bucket["next"]:
        lines.append("- Next:")
        for item in bucket["next"][:3]:
            lines.append(f"  - {item}")
    else:
        lines.append("- Next:")
        lines.append("  - no explicit next step")

lines.append("")
lines.append("## Key Signals")
for item in key_signals[:8]:
    lines.append(f"- {item}")
if context_refs:
    lines.append("")
    lines.append("## Stable Context")
    for item in context_refs:
        lines.append(f"- {item}")
lines.append("")
lines.append("## Tomorrow / Follow-up")
for item in follow_up:
    lines.append(f"- {item}")
lines.append("")
lines.append("## Sources")
for ref in source_refs:
    lines.append(f"- {ref}")

pathlib.Path(out_file).write_text("\n".join(lines) + "\n", encoding="utf-8")
PY
}

sync_to_memos() {
  [[ "$MEMOS_SYNC" -eq 1 ]] || return 0
  [[ -n "$MEMOS_BASE_URL" ]] || fail "MEMOS_BASE_URL is required for sync"
  [[ -n "$MEMOS_TOKEN" ]] || fail "MEMOS_TOKEN is required for sync"

  local normalized_base title encoded_title list_json existing_count payload create_response
  normalized_base="${MEMOS_BASE_URL%/}"
  title="# Daily AI Infra Summary - $TARGET_DATE"
  encoded_title="$(python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1]))' "$title")"

  log "Checking for existing Memos entry"
  list_json="$(curl -fsS --noproxy '*' \
    -H "Authorization: Bearer $MEMOS_TOKEN" \
    "$normalized_base/api/v1/memos?pageSize=$PAGE_SIZE" )"

  existing_count="$(python3 - "$title" <<'PY' <<< "$list_json"
import json, sys
needle = sys.argv[1]
try:
    data = json.load(sys.stdin)
except Exception:
    print(0)
    raise SystemExit
items = []
if isinstance(data, dict):
    items = data.get('memos') or data.get('data') or []
elif isinstance(data, list):
    items = data
count = 0
for item in items:
    if not isinstance(item, dict):
        continue
    content = item.get('content', '')
    if needle in content:
        count += 1
print(count)
PY
)"

  if [[ "$existing_count" != "0" ]]; then
    log "Existing memo for $TARGET_DATE already found, skipping create"
    printf '{"date":"%s","status":"skipped","reason":"existing memo found"}\n' "$TARGET_DATE" > "$META_FILE"
    return 0
  fi

  log "Creating Memos entry"
  payload="$(python3 - "$SUMMARY_FILE" <<'PY'
import json, pathlib, sys
content = pathlib.Path(sys.argv[1]).read_text(encoding='utf-8')
body = {
  "content": content,
  "visibility": "PRIVATE",
  "tags": ["daily-summary", "openclaw", "claude-code", "codex", "oracle-cloud", "arm"],
}
print(json.dumps(body, ensure_ascii=False))
PY
)"

  create_response="$(curl -fsS --noproxy '*' \
    -X POST \
    -H "Authorization: Bearer $MEMOS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$payload" \
    "$normalized_base/api/v1/memos" )"

  printf '%s\n' "$create_response" > "$META_FILE"
  log "Memos entry created"
}

generate_remote_status
generate_summary
sync_to_memos

log "Summary saved to $SUMMARY_FILE"
if [[ "$MEMOS_SYNC" -eq 0 ]]; then
  log "Dry run complete"
fi
