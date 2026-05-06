# claude-buffer-sns

> Claude Code 스킬 — **Buffer를 통해 Instagram / Threads / LinkedIn 등 여러 SNS에 안전하게 동시 발행**합니다. 환각 방지 게이트 2단(사실 검증 + 사람 승인) 내장.

## 무엇을 해주나요?

콘텐츠 작성이 끝난 뒤, 이 스킬에게 **"발행해줘"** 한마디만 하면:

1. ✅ 사실 검증 게이트 (`factcheck-gate.sh`)로 캡션 속 날짜·정원·가격 등이 화이트리스트에 등록된 사실인지 자동 대조
2. ✅ 사람 명시 승인 게이트 (`publish-gate.sh`)로 자동 발행 방지
3. ✅ Buffer MCP로 IG/Threads/LinkedIn 등 여러 채널에 동시 게시
4. ✅ 발행 이력을 `.audit/publish-history.jsonl`에 자동 기록

## 왜 만들었나요?

마케팅 자동화에서 가장 무서운 건 AI가 **존재하지 않는 사실을 만들어 공개 발행**하는 것입니다. 실제로 2026년 4월, 본 스킬의 모태가 된 `josh` 프로젝트에서 AI가 허구의 "수요일 8시 설명회 선착순 50석" CTA를 생성해 인스타·스레드에 공개 발행되는 사고가 있었습니다.

이 스킬은 그 사고에서 학습한 가드레일을 누구나 쓸 수 있도록 일반화한 결과물입니다.

## 빠른 시작 (3분)

### 0. 사전 준비

- Claude Code 설치 (https://docs.claude.com/en/docs/claude-code)
- Buffer 계정 + API 키 발급 (https://publish.buffer.com/settings/api)
- Buffer 대시보드에서 발행할 SNS 채널(IG/Threads/LinkedIn 등) 연결

### 1. 스킬 설치

```bash
# 방법 A: curl 한 줄
curl -fsSL https://raw.githubusercontent.com/ninestonelee/claude-buffer-sns/main/install.sh | bash

# 방법 B: 수동 clone
git clone https://github.com/ninestonelee/claude-buffer-sns.git
cd claude-buffer-sns
bash install.sh
```

설치 스크립트가 다음을 수행합니다:

- `~/.claude/skills/publish-to-sns/`로 스킬 복사
- `.env.example` → `.env` 생성 (수동으로 키 입력 필요)
- Buffer MCP 등록 명령 출력

### 2. API 키 입력

```bash
cd ~/.claude/skills/publish-to-sns
cp .env.example .env
# .env 열고 BUFFER_API_KEY=your_key_here 작성
```

### 3. Buffer MCP 등록

```bash
source .env
claude mcp add buffer --scope user -- npx -y mcp-remote \
  https://mcp.buffer.com/mcp \
  --header "Authorization: Bearer $BUFFER_API_KEY"
```

> ⚠️ **`--scope user`** 가 중요합니다. 프로젝트 스코프로 등록하면 서브에이전트에서 MCP를 못 찾는 이슈가 있습니다.

### 4. 콘텐츠 파일 준비

`output/sns-caption-test.md`를 만들고 다음과 같이 작성:

```markdown
# 테스트 발행

## Instagram
인스타용 캡션입니다. 해시태그도 자유롭게.
#테스트 #claude #buffer

## Threads
스레드용 캡션. 500자 이내 권장.

## LinkedIn
링크드인용 캡션. 전문적인 톤으로.
```

### 5. 발행

Claude Code에서:

```
@publish-to-sns slug=test channels=instagram,threads,linkedin schedule=queue
```

또는 자연어로:

```
test 슬러그 발행해줘 — 인스타·스레드·링크드인 큐에 넣어
```

## 안전장치 둘러보기

### 게이트 1: 사실 검증 (`factcheck-gate.sh`)

`_context/events-whitelist.md`에 사실(이벤트 날짜·정원·가격·URL)을 등록해두면, 캡션의 모든 사실 표현이 화이트리스트에 있는지 자동 대조합니다.

```markdown
# events-whitelist.md
- 2026-05-15 19:00 무료 웨비나 "AI 마케팅 입문" — 정원 100명
- https://chatsapiens.com/webinar
- 가격: 49,000원
```

이 파일이 없으면 게이트는 경고만 출력하고 통과합니다(점진적 도입 가능).

### 게이트 2: 사람 명시 승인 (`publish-gate.sh`)

- factcheck를 재실행
- `output/review-report-{slug}.md`에서 `✅ 발행가능` 문구 확인 (선택)
- `.audit/publish-approvals.jsonl`에 승인 기록
- exit 0이면 발행 단계로 진행

## 폴더 구조

```
your-project/
├── .claude/
│   └── skills/
│       └── publish-to-sns/    # ← 이 스킬 (install.sh가 자동 배치)
├── _context/
│   └── events-whitelist.md     # 사실 SoT (선택)
├── output/
│   ├── sns-caption-{slug}.md   # 발행할 캡션 (필수)
│   └── review-report-{slug}.md # 검수 보고서 (선택)
├── .audit/
│   ├── publish-approvals.jsonl # 승인 로그 (자동 생성)
│   └── publish-history.jsonl   # 발행 이력 (자동 생성)
└── .env                        # BUFFER_API_KEY (절대 커밋 금지)
```

## 자주 묻는 질문

### Q. 무료인가요?
스킬 자체는 MIT 라이선스로 무료입니다. Buffer 무료 플랜으로도 채널 3개까지 사용 가능합니다.

### Q. 인스타그램 직접 API가 아니라 왜 Buffer인가요?
1. 인스타 직접 API는 Meta 비즈니스 인증/심사가 까다롭습니다.
2. Buffer는 큐잉·스케줄링·분석을 한 곳에서 처리합니다.
3. 한 콘텐츠를 여러 SNS에 일관되게 발행하기 좋습니다.

### Q. Threads도 되나요?
네, Buffer가 공식 지원합니다.

### Q. 자동으로 발행되나요?
**아니요**. 사람이 명시적으로 "발행해줘"라고 해야 합니다. AI가 임의로 발행하지 않도록 설계되었습니다.

### Q. 발행을 취소하려면?
Buffer 대시보드에서 직접 삭제하거나, `mcp__buffer__delete_post`로 코드에서 삭제 가능합니다.

## 보안 체크리스트

발행 시작 전 반드시 확인:

- [ ] `.env`가 `.gitignore`에 포함되어 있다
- [ ] API 키를 채팅창/공개 채널에 붙여넣지 않았다
- [ ] Buffer MCP는 user 스코프로 등록되어 있다
- [ ] 테스트 발행은 Buffer 큐에서 발행 직전 한 번 더 확인한다

## 라이선스

MIT — 자유롭게 사용·수정·배포 가능. 다만 본인의 발행 콘텐츠 책임은 본인에게 있습니다.

## 만든 사람

[ChatSapiens 원격 평생교육원](https://chatsapiens.com) — Josh (이석구)

마케팅 에이전트 팀 구축 워크숍 수강생을 위한 자료로 시작되었습니다.

## 기여

이슈/PR 환영합니다: https://github.com/ninestonelee/claude-buffer-sns/issues
