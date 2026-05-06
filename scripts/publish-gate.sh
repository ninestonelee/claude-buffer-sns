#!/usr/bin/env bash
# publish-gate.sh — 발행 직전 사람 명시 승인 + factcheck 재실행 게이트
#
# 사용법:
#   bash scripts/publish-gate.sh --slug {slug} --approved-by {사용자명}
#
# 동작:
#   1) factcheck-gate.sh 재실행
#   2) (선택) output/review-report-{slug}.md에 '✅ 발행가능' 리터럴 확인
#   3) .audit/publish-approvals.jsonl에 승인 기록 누적
#   4) exit 0이면 호출자가 Buffer MCP 발행을 진행할 수 있음
#
# 종료 코드:
#   0  승인 — 발행 가능
#   1  factcheck 실패
#   2  review-report 없거나 발행불가 판정
#   3  잘못된 사용

set -uo pipefail

SLUG=""
APPROVER="${PUBLISH_APPROVER:-}"
SKIP_REVIEW="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --slug) SLUG="$2"; shift 2 ;;
    --approved-by) APPROVER="$2"; shift 2 ;;
    --skip-review) SKIP_REVIEW="true"; shift ;;
    *) echo "  ❌ 알 수 없는 인자: $1" >&2; exit 3 ;;
  esac
done

if [[ -z "$SLUG" || -z "$APPROVER" ]]; then
  echo "  ❌ 사용법: $0 --slug {slug} --approved-by {사용자명} [--skip-review]" >&2
  exit 3
fi

CAPTION_FILE="output/sns-caption-${SLUG}.md"
REVIEW_FILE="output/review-report-${SLUG}.md"
AUDIT_DIR=".audit"
APPROVAL_LOG="${AUDIT_DIR}/publish-approvals.jsonl"

if [[ ! -f "$CAPTION_FILE" ]]; then
  echo "  ❌ 캡션 파일이 없습니다: $CAPTION_FILE" >&2
  exit 3
fi

echo "  🛡️  Publish Gate"
echo "     슬러그: $SLUG"
echo "     승인자: $APPROVER"
echo ""

# 1) Factcheck 재실행
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if ! bash "${SCRIPT_DIR}/factcheck-gate.sh" "$CAPTION_FILE"; then
  echo "  🚫 Publish Gate 실패 — factcheck-gate에서 차단됨" >&2
  exit 1
fi

# 2) Review report 확인
if [[ "$SKIP_REVIEW" != "true" ]]; then
  if [[ -f "$REVIEW_FILE" ]]; then
    if grep -qF "✅ 발행가능" "$REVIEW_FILE"; then
      echo "  ✅ Review report에서 '✅ 발행가능' 확인"
    else
      echo "  🚫 Review report에 '✅ 발행가능' 리터럴이 없습니다: $REVIEW_FILE"
      echo "     해결: review-agent로 검수를 완료하거나, --skip-review 플래그 사용"
      exit 2
    fi
  else
    echo "  ⚠️  Review report 없음: $REVIEW_FILE (계속 진행 — 권장: review-agent 검수 후 재시도)"
  fi
fi

# 3) 승인 기록 누적
mkdir -p "$AUDIT_DIR"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
JSON_LINE=$(printf '{"timestamp":"%s","slug":"%s","approver":"%s","caption_file":"%s","review_file":"%s"}' \
  "$TIMESTAMP" "$SLUG" "$APPROVER" "$CAPTION_FILE" "$REVIEW_FILE")
echo "$JSON_LINE" >> "$APPROVAL_LOG"

echo ""
echo "  ✅ Publish Gate 통과 — 발행 진행 가능"
echo "     기록: $APPROVAL_LOG"
exit 0
