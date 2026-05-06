---
name: publish-to-sns
description: |
  Buffer를 통해 Instagram, Threads, LinkedIn 등 여러 SNS 채널에 콘텐츠를 동시 발행하는 Claude Code 스킬.
  사실 검증(factcheck) → 사람 승인(publish-gate) → Buffer MCP 발행 → 이력 기록의 4단 파이프라인.
  Use when the user asks to "발행해줘", "Buffer로 올려줘", "SNS에 게시", "post to social media via Buffer".
---

# publish-to-sns — Buffer 멀티채널 발행 스킬

## 개요

이 스킬은 콘텐츠 작성이 끝난 뒤 **여러 SNS 채널에 안전하게 발행**하는 마지막 단계를 담당한다.
"안전하게"의 의미는 두 가지다.

1. **사실 검증 게이트**: 발행 전 화이트리스트 대조로 환각·허위 사실 차단
2. **사람 명시 승인 게이트**: AI가 자동으로 발행 버튼을 누르지 않음

## 언제 사용하는가

- "이 콘텐츠 인스타/스레드/링크드인에 올려줘"
- "Buffer 큐에 넣어줘"
- "내일 오전 9시에 예약 발행"
- "3채널 동시 발행"

## 사전 요구사항

| 항목 | 필요 여부 | 설명 |
|---|---|---|
| Buffer 계정 | ✅ 필수 | https://buffer.com (무료 플랜 가능, 채널 3개까지) |
| Buffer API Key | ✅ 필수 | https://publish.buffer.com/settings/api 에서 발급 |
| Buffer MCP 등록 | ✅ 필수 | `claude mcp add buffer --scope user -- npx -y mcp-remote https://mcp.buffer.com/mcp --header "Authorization: Bearer $BUFFER_API_KEY"` |
| 연결된 SNS 채널 | ✅ 필수 | Buffer 대시보드에서 IG/Threads/LinkedIn 등 연결 |
| 콘텐츠 파일 | ✅ 필수 | `output/sns-caption-{slug}.md` 형식, 채널별 캡션 분리 표기 |
| 이미지 (IG) | ⬜ 옵션 | IG는 이미지 URL 필수 — 공개 URL 또는 Supabase Storage 업로드 결과 |
| events-whitelist | ⬜ 권장 | 사실 SoT 문서. 없으면 게이트 1단 스킵 가능 |

## 입력 파라미터

| 이름 | 필수 | 설명 | 예시 |
|---|---|---|---|
| **slug** | ✅ | 콘텐츠 슬러그 (output/sns-caption-{slug}.md 매칭) | `ai-marketing-20260506` |
| **channels** | ⬜ | 발행 대상 채널 (기본: 모든 연결된 채널) | `instagram,threads,linkedin` |
| **schedule** | ⬜ | 스케줄 모드 | `queue`(기본) / `now` / `2026-05-08T09:00+09:00` |
| **image** | ⬜ | 이미지 공개 URL (IG 채널 발행 시 필수) | `https://.../card-1.jpg` |
| **dry_run** | ⬜ | true면 발행 직전까지 검증만 | `true` |

## SNS 캡션 파일 포맷

`output/sns-caption-{slug}.md` 파일은 다음 구조를 따른다.

```markdown
# {제목}

## Instagram
{인스타용 캡션 — 줄바꿈 자유, 해시태그 5-7개}

## Threads
{스레드용 캡션 — 500자 이내 권장}

## LinkedIn
{링크드인용 캡션 — 전문적 톤, 해시태그 3-5개}
```

각 채널 섹션이 그대로 발행 본문이 된다.

## 워크플로우

### 단계 1: 사전 검증

1. `output/sns-caption-{slug}.md` 존재 확인
2. 각 채널 섹션이 비어있지 않은지 확인
3. IG가 channels에 포함되면 `image` 파라미터 또는 캡션 내 이미지 URL 확인

### 단계 2: Mechanical Gate 1 — Factcheck

```bash
bash scripts/factcheck-gate.sh output/sns-caption-{slug}.md
```

- `_context/events-whitelist.md`가 있으면 캡션의 날짜·시간·정원·가격·URL을 화이트리스트와 grep 대조
- 미등록 표현 발견 시 exit 1 → **발행 중단**
- 화이트리스트 없으면 경고만 출력 후 통과

### 단계 3: Mechanical Gate 2 — Publish Gate

```bash
bash scripts/publish-gate.sh --slug {slug} --approved-by {사용자명}
```

- factcheck-gate 재실행 (이중 안전장치)
- `output/review-report-{slug}.md`에서 `✅ 발행가능` 리터럴 확인 (선택)
- `.audit/publish-approvals.jsonl`에 승인 로그 누적
- exit 0이면 단계 4로 진행

### 단계 4: Buffer MCP 발행

각 채널에 대해 순서대로:

1. `mcp__buffer__list_channels` 호출 → 사용자의 채널 ID 매핑 확인
2. `mcp__buffer__get_channel`로 타임존/스케줄 확인
3. `mcp__buffer__create_post` 호출:
   - `channelId`: list_channels에서 받은 정확한 ID
   - `text`: sns-caption 파일의 해당 채널 섹션
   - `media`: IG일 경우 이미지 URL
   - `schedulingType`: schedule 파라미터에 따라 `addToQueue` / `now` / `customScheduled`

4. 응답에서 발행 ID + URL을 `.audit/publish-history.jsonl`에 기록

### 단계 5: 결과 보고

발행 완료 후 다음 형식으로 사용자에게 보고:

```
✅ 발행 완료
- Instagram: https://buffer.com/post/...
- Threads: https://buffer.com/post/...
- LinkedIn: https://buffer.com/post/...

이력: .audit/publish-history.jsonl
```

## 안전 원칙 (절대 위반 금지)

1. **사용자 명시 승인 없이 발행하지 않는다.** "발행해줘", "올려줘" 같은 명시적 요청이 있어야 한다.
2. **API 키를 코드/로그에 출력하지 않는다.** `.env`에서만 읽는다.
3. **Mechanical Gate 통과 없이 Buffer MCP를 호출하지 않는다.**
4. **중복 발행을 방지한다.** `.audit/publish-history.jsonl`에 같은 slug+channel+date 조합이 있으면 중단.
5. **dry_run=true이면 단계 4를 건너뛴다.** (Mechanical Gate까지만 실행)

## 트러블슈팅

| 증상 | 원인 | 해결 |
|---|---|---|
| `mcp__buffer__*` 도구 없음 | MCP 미등록 또는 project 스코프로 등록 | **user 스코프**로 재등록 |
| IG 발행 시 "media required" 에러 | 이미지 URL 누락 | `image` 파라미터 또는 캡션에 URL 추가 |
| `customScheduled` 시 시간이 다름 | UTC로 전송됨 | KST는 `+09:00` 오프셋 명시 (`get_account` 응답의 timezone 신뢰) |
| `create_post` 시 채널 ID 에러 | 하드코딩된 ID 사용 | 매번 `list_channels` 호출해서 동적으로 가져오기 |

## 확장 아이디어

- **review-agent 연동**: 발행 직전 review-report 자동 생성·검증
- **이미지 자동 업로드**: 로컬 이미지를 Supabase/S3에 업로드 후 공개 URL을 IG에 사용
- **A/B 테스트**: 같은 콘텐츠를 다른 시간대에 큐잉, 성과 비교
- **회수(recall)**: `mcp__buffer__delete_post`로 발행 후 즉시 취소

## 라이선스 / 출처

- 라이선스: MIT
- 원본 설계: ChatSapiens 마케팅 에이전트 팀 (josh 프로젝트)
- 가드레일 설계 동기: 2026-04-18 환각 사건 (허구 CTA 3채널 공개 발행) → 본 스킬의 mechanical gate 도입
