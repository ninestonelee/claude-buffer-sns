# SNS Caption Format — 표준 캡션 파일 형식

이 스킬은 `output/sns-caption-{slug}.md` 파일에서 채널별 캡션을 자동으로 분리합니다.
H2(`## ChannelName`) 섹션 단위로 파싱되니, 형식만 지켜주세요.

## 표준 형식

```markdown
# {제목 — 사람이 식별하기 위한 메타. 발행에는 사용 안 됨}

## Instagram
{인스타그램 본문}

해시태그는 본문 끝에 붙이거나 첫 댓글 분리 (Buffer 설정에 따라)

## Threads
{스레드 본문 — 500자 권장}

## LinkedIn
{링크드인 본문 — 전문적 톤, 줄바꿈 적극 활용}
```

## 채널 이름 규칙

H2 헤더는 정확히 다음 중 하나로 사용 (대소문자 무관):

| H2 헤더 | Buffer 채널 매칭 |
|---|---|
| `## Instagram` | Instagram 비즈니스 계정 |
| `## Threads` | Threads |
| `## LinkedIn` | LinkedIn (개인/페이지) |
| `## Facebook` | Facebook 페이지 |
| `## Twitter` 또는 `## X` | X (구 Twitter) |
| `## TikTok` | TikTok |

## 채널별 길이/팁

| 채널 | 권장 길이 | 비고 |
|---|---|---|
| Instagram | 125자 안에 핵심 + 본문은 2,200자까지 | 첫 줄이 가장 중요 |
| Threads | 500자 권장 (최대 500자) | 짧고 강한 후킹 |
| LinkedIn | 1,300~3,000자 | 전문성·인사이트 강조, 이모지 절제 |
| Facebook | 40~80자 짧을수록 도달 좋음 | 또는 길게 스토리텔링 |
| X | 280자 | 한국어는 절반 정도 |

## 이미지 포함 (Instagram)

이미지가 필요한 경우:

```markdown
## Instagram
{캡션 본문}

<!-- image: https://example.com/your-image.jpg -->
```

또는 발행 시 `image` 파라미터로 직접 전달.

## 좋은 예시

```markdown
# 5월 15일 무료 웨비나 안내

## Instagram
🚀 AI 마케팅, 어디서부터 시작해야 할지 막막하셨나요?

5월 15일 무료 웨비나에서 비개발자도 30분 만에 따라할 수 있는
AI 마케팅 자동화의 첫 걸음을 알려드립니다.

✅ 다루는 내용
- ChatGPT로 콘텐츠 기획하기
- 무료 도구 3가지로 SNS 자동 발행
- 실제 소상공인 적용 사례

신청은 프로필 링크에서 👆

#AI마케팅 #자동화 #ChatGPT #소상공인마케팅 #무료웨비나

## Threads
AI 마케팅 막막하시죠?
5월 15일 무료 웨비나 — 비개발자도 30분 만에.
링크는 프로필에 ↗️

## LinkedIn
AI 마케팅 자동화, 비개발자에게 어떻게 시작점을 만들어드릴 수 있을까?

지난 6개월 동안 100명이 넘는 비개발자 마케터를 인터뷰하며
공통 페인포인트를 정리했습니다. 그 결과를 오는 5월 15일 무료 웨비나에서
공유합니다.

다루는 내용:
- ChatGPT를 활용한 주제 기획 프레임워크
- 무료 도구 3가지로 구축하는 SNS 자동 발행 파이프라인
- B2B / 소상공인 적용 사례 비교

대상: 마케팅 담당자, 1인 창업자, 콘텐츠 운영자

신청: https://example.com/webinar

#AIMarketing #MarketingAutomation #ChatGPT #DigitalTransformation
```
