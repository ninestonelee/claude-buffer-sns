#!/usr/bin/env bash
# factcheck-gate.sh — 캡션 파일의 사실 표현이 events-whitelist에 등록되어 있는지 검사
#
# 사용법:
#   bash scripts/factcheck-gate.sh output/sns-caption-{slug}.md
#
# 검사 대상:
#   - 날짜 패턴 (YYYY-MM-DD, M/D, M월 D일)
#   - 시간 패턴 (HH:MM, HH시)
#   - 가격 패턴 (₩, 원, KRW, 숫자+,)
#   - URL 패턴 (https?://...)
#   - 정원 패턴 (선착순 N명, 정원 N명)
#
# 종료 코드:
#   0  통과 (또는 화이트리스트 미존재로 경고만 출력)
#   1  미등록 표현 발견 → 발행 중단
#   2  잘못된 사용

set -uo pipefail

CAPTION_FILE="${1:-}"

if [[ -z "$CAPTION_FILE" ]]; then
  echo "  ❌ 사용법: $0 <caption-file.md>" >&2
  exit 2
fi

if [[ ! -f "$CAPTION_FILE" ]]; then
  echo "  ❌ 파일을 찾을 수 없습니다: $CAPTION_FILE" >&2
  exit 2
fi

# 화이트리스트 위치 자동 탐색
WHITELIST=""
for candidate in "_context/events-whitelist.md" "events-whitelist.md" "../_context/events-whitelist.md"; do
  if [[ -f "$candidate" ]]; then
    WHITELIST="$candidate"
    break
  fi
done

if [[ -z "$WHITELIST" ]]; then
  echo "  ⚠️  events-whitelist.md를 찾을 수 없습니다."
  echo "     사실 검증을 건너뛰고 통과합니다 (점진적 도입 모드)."
  echo "     강력한 검증을 원하면 _context/events-whitelist.md를 만드세요."
  exit 0
fi

echo "  🔍 Factcheck Gate"
echo "     캡션: $CAPTION_FILE"
echo "     화이트리스트: $WHITELIST"
echo ""

VIOLATIONS=0

check_pattern() {
  local pattern_name="$1"
  local regex="$2"

  # 캡션에서 패턴 추출
  local matches
  matches=$(grep -oE "$regex" "$CAPTION_FILE" 2>/dev/null | sort -u || true)

  if [[ -z "$matches" ]]; then
    return 0
  fi

  while IFS= read -r match; do
    [[ -z "$match" ]] && continue

    # URL은 도메인 단위로 비교
    if [[ "$pattern_name" == "URL" ]]; then
      local domain
      domain=$(echo "$match" | sed -E 's|https?://([^/]+).*|\1|')
      if ! grep -qF "$domain" "$WHITELIST" 2>/dev/null; then
        echo "  🚫 미등록 $pattern_name: $match (도메인 $domain)"
        VIOLATIONS=$((VIOLATIONS + 1))
      fi
    else
      if ! grep -qF "$match" "$WHITELIST" 2>/dev/null; then
        echo "  🚫 미등록 $pattern_name: $match"
        VIOLATIONS=$((VIOLATIONS + 1))
      fi
    fi
  done <<< "$matches"
}

# 패턴별 검사
check_pattern "날짜(YMD)"   '[0-9]{4}-[0-9]{2}-[0-9]{2}'
check_pattern "날짜(M/D)"   '[0-9]{1,2}/[0-9]{1,2}'
check_pattern "날짜(한글)"  '[0-9]{1,2}월 ?[0-9]{1,2}일'
check_pattern "시간"        '[0-9]{1,2}:[0-9]{2}'
check_pattern "가격(원)"    '[0-9,]+ ?원'
check_pattern "정원"        '(선착순|정원) ?[0-9]+명'
check_pattern "URL"         'https?://[A-Za-z0-9._~:/?#@!$&'\''()*+,;=-]+'

echo ""
if [[ $VIOLATIONS -gt 0 ]]; then
  echo "  🚫 BLOCK — 미등록 사실 표현 ${VIOLATIONS}건 발견"
  echo "     해결: $WHITELIST 에 위 표현을 등록하거나, 캡션에서 제거하세요."
  exit 1
fi

echo "  ✅ Factcheck Gate 통과"
exit 0
