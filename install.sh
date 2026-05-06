#!/usr/bin/env bash
# claude-buffer-sns 스킬 설치 스크립트
# 사용법: bash install.sh  또는  curl -fsSL <raw>/install.sh | bash

set -euo pipefail

SKILL_NAME="publish-to-sns"
TARGET_DIR="${HOME}/.claude/skills/${SKILL_NAME}"
REPO_URL="https://github.com/ninestonelee/claude-buffer-sns.git"

echo ""
echo "  📦 claude-buffer-sns 설치를 시작합니다"
echo ""

# 1. 의존성 체크
command -v claude >/dev/null 2>&1 || {
  echo "  ❌ Claude Code CLI가 설치되어 있지 않습니다."
  echo "     https://docs.claude.com/en/docs/claude-code 참고"
  exit 1
}

command -v git >/dev/null 2>&1 || { echo "  ❌ git이 필요합니다."; exit 1; }

# 2. 작업 디렉토리 결정
if [[ -f "SKILL.md" && -d "scripts" ]]; then
  # 이미 clone된 폴더에서 실행 중
  SOURCE_DIR="$(pwd)"
  echo "  ✓ 로컬 소스 사용: $SOURCE_DIR"
else
  # curl 파이프 등 원격 실행 — 임시 폴더에 clone
  TMP_DIR="$(mktemp -d)"
  echo "  ↓ 임시 폴더에 clone: $TMP_DIR"
  git clone --depth=1 "$REPO_URL" "$TMP_DIR/claude-buffer-sns" >/dev/null
  SOURCE_DIR="$TMP_DIR/claude-buffer-sns"
fi

# 3. 기존 스킬 백업
if [[ -d "$TARGET_DIR" ]]; then
  BACKUP_DIR="${TARGET_DIR}.backup-$(date +%Y%m%d-%H%M%S)"
  echo "  ⚠️  기존 스킬 발견 → 백업: $BACKUP_DIR"
  mv "$TARGET_DIR" "$BACKUP_DIR"
fi

# 4. 스킬 복사
mkdir -p "$TARGET_DIR"
cp -R "$SOURCE_DIR"/{SKILL.md,scripts,templates,examples,README.md,LICENSE,.env.example} "$TARGET_DIR"/ 2>/dev/null || true
chmod +x "$TARGET_DIR"/scripts/*.sh 2>/dev/null || true

# 5. .env 가이드
echo ""
echo "  ✅ 스킬 설치 완료: $TARGET_DIR"
echo ""
echo "  📋 다음 단계:"
echo ""
echo "  1. Buffer API 키 입력"
echo "       cd $TARGET_DIR"
echo "       cp .env.example .env"
echo "       \$EDITOR .env  # BUFFER_API_KEY 입력"
echo ""
echo "  2. Buffer MCP 등록 (user 스코프 필수)"
echo "       source $TARGET_DIR/.env"
echo "       claude mcp add buffer --scope user -- npx -y mcp-remote \\"
echo "         https://mcp.buffer.com/mcp \\"
echo "         --header \"Authorization: Bearer \$BUFFER_API_KEY\""
echo ""
echo "  3. Claude Code 재시작 후 사용"
echo "       (예) test 슬러그 발행해줘 — 인스타·스레드·링크드인 큐에 넣어"
echo ""
echo "  자세한 사용법: $TARGET_DIR/README.md"
echo ""
