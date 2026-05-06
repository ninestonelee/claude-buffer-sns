#!/usr/bin/env python3
"""
publish_to_buffer.py — Buffer MCP/REST 발행 헬퍼

이 스크립트는 sns-caption 파일에서 채널별 섹션을 분리하고,
호출자에게 표준화된 발행 페이로드를 출력한다.

본 스킬의 표준 흐름은 Buffer MCP를 사용하지만(Claude Code가 직접 호출),
이 헬퍼는 다음 두 용도로 쓰인다:

1. 캡션 파일을 채널별로 파싱해 stdout에 JSON 출력 → Claude가 그대로 사용
2. .audit/publish-history.jsonl에 발행 기록 누적

사용법:
  python3 scripts/publish_to_buffer.py parse <caption-file>
  python3 scripts/publish_to_buffer.py log <slug> <channel> <post_id> <post_url>
"""

import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path


def parse_caption(path: str) -> dict:
    """SNS 캡션 마크다운을 채널별 섹션으로 분리"""
    text = Path(path).read_text(encoding="utf-8")
    sections: dict[str, str] = {}

    # ## Instagram, ## Threads, ## LinkedIn 등의 H2 섹션을 찾는다
    pattern = re.compile(r"^##\s+([A-Za-z]+)\s*$", re.MULTILINE)
    matches = list(pattern.finditer(text))

    for i, m in enumerate(matches):
        channel = m.group(1).strip().lower()
        start = m.end()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
        body = text[start:end].strip()
        if body:
            sections[channel] = body

    return sections


def log_publish(slug: str, channel: str, post_id: str, post_url: str) -> None:
    """.audit/publish-history.jsonl에 발행 기록 추가"""
    audit_dir = Path(".audit")
    audit_dir.mkdir(exist_ok=True)
    log_file = audit_dir / "publish-history.jsonl"

    entry = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "slug": slug,
        "channel": channel,
        "post_id": post_id,
        "post_url": post_url,
    }

    with log_file.open("a", encoding="utf-8") as f:
        f.write(json.dumps(entry, ensure_ascii=False) + "\n")


def check_duplicate(slug: str, channel: str) -> bool:
    """같은 slug+channel 조합이 오늘 이미 발행되었는지 확인"""
    log_file = Path(".audit/publish-history.jsonl")
    if not log_file.exists():
        return False

    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    for line in log_file.read_text(encoding="utf-8").splitlines():
        try:
            entry = json.loads(line)
        except json.JSONDecodeError:
            continue
        if (
            entry.get("slug") == slug
            and entry.get("channel") == channel
            and entry.get("timestamp", "").startswith(today)
        ):
            return True
    return False


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__, file=sys.stderr)
        return 2

    cmd = sys.argv[1]

    if cmd == "parse":
        if len(sys.argv) != 3:
            print("사용법: parse <caption-file>", file=sys.stderr)
            return 2
        sections = parse_caption(sys.argv[2])
        print(json.dumps(sections, ensure_ascii=False, indent=2))
        return 0

    if cmd == "log":
        if len(sys.argv) != 6:
            print("사용법: log <slug> <channel> <post_id> <post_url>", file=sys.stderr)
            return 2
        log_publish(*sys.argv[2:])
        print(f"  ✅ 기록 완료: .audit/publish-history.jsonl")
        return 0

    if cmd == "check-duplicate":
        if len(sys.argv) != 4:
            print("사용법: check-duplicate <slug> <channel>", file=sys.stderr)
            return 2
        is_dup = check_duplicate(sys.argv[2], sys.argv[3])
        print("DUPLICATE" if is_dup else "OK")
        return 1 if is_dup else 0

    print(f"알 수 없는 명령: {cmd}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
