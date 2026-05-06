# 5분 퀵스타트 — 첫 번째 발행까지

## 1. 설치 (1분)

```bash
git clone https://github.com/ninestonelee/claude-buffer-sns.git
cd claude-buffer-sns
bash install.sh
```

## 2. Buffer 키 입력 (1분)

```bash
cd ~/.claude/skills/publish-to-sns
cp .env.example .env
# .env 열어서 BUFFER_API_KEY=... 입력
```

## 3. Buffer MCP 등록 (30초)

```bash
source .env
claude mcp add buffer --scope user -- npx -y mcp-remote \
  https://mcp.buffer.com/mcp \
  --header "Authorization: Bearer $BUFFER_API_KEY"
```

Claude Code 재시작.

## 4. 테스트 캡션 작성 (1분)

프로젝트 루트에서:

```bash
mkdir -p output
cat > output/sns-caption-hello.md <<'EOF'
# 첫 발행 테스트

## Instagram
안녕하세요! claude-buffer-sns 첫 발행 테스트입니다 🎉

#테스트 #claude #buffer

## Threads
첫 발행 테스트 — 잘 되나요?

## LinkedIn
claude-buffer-sns 스킬을 처음 시도해봅니다.
3개 채널 동시 발행이 잘 되는지 확인 중입니다.
EOF
```

## 5. Claude Code에서 발행 (30초)

Claude Code 채팅창에서:

```
hello 슬러그를 인스타·스레드·링크드인 큐에 발행해줘
```

또는 명시적으로:

```
@publish-to-sns slug=hello channels=instagram,threads,linkedin schedule=queue
```

Claude가 다음 순서로 진행합니다:

1. ✅ factcheck-gate (사실 검증) — 화이트리스트 없으면 경고만
2. ✅ publish-gate (사람 명시 승인) — 사용자가 확인하면 통과
3. ✅ Buffer MCP 호출 — 3채널 큐에 추가
4. ✅ 결과 보고 + `.audit/publish-history.jsonl`에 기록

## 다음 단계

- `_context/events-whitelist.md`를 만들어 사실 검증 강화
- `output/review-report-{slug}.md` 추가로 검수 게이트 가동
- 정기 발행 자동화 (cron / GitHub Actions와 결합)
