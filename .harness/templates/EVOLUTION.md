---
id: NNN
slug: {{kebab-case-slug}}
date: {{YYYY-MM-DD}}
status: draft | confirmed | applied | reverted
applied_commit:
  sfd: {{hash 또는 (none)}}
risk_smell: {{none | weak_justification | rule_violation | scope_creep}}
---

# NNN — {{한 줄 제목}}

## 1. 변경 (before/after)

**Before:**
- ...

**After:**
- ...

## 2. 왜

이 변경을 트리거한 사건·관찰·부정합 한 단락. 측정 가능한 결과가 있으면 박는다.

예: "2026-05-19 BUDGET → NO_PROGRESS 변경 시도 중 변수 한 개가 정본·시드 두 곳에 박혀있어 5곳 누락 부정합 발생. 같은 패턴 재발 위험."

## 3. 영향 범위 grep 결과

```
$ grep -rn "<keyword>" ~/Projects/scenario-first-development .
<출력 인라인>
```

위 hit 전부 변경 commit 에 포함됐는지 적용 후 재grep 으로 검증.

## 4. 보호 룰 점검

- [ ] review 자동화 거부 (AGENTS.md 6 금지) — OK / 위반: ...
- [ ] cycle lock 단일 NNN (AGENTS.md 3.4) — OK / 위반: ...
- [ ] 누적 풀 진입 `review_status: passed` (AGENTS.md 3.1) — OK / 위반: ...
- [ ] 단방향 파이프라인 (rules.json) — OK / 위반: ...
- [ ] evidence 없이 passed 금지 (rules.json) — OK / 위반: ...
- [ ] 자동 트리거 금지 (AGENTS.md 6) — OK / 위반: ...
- [ ] Job Story 페르소나 금지 (rules.json) — OK / 위반: ...
- [ ] EVOLUTION ADR 의무 (rules.json) — OK / 본 ADR 자체

위반 있으면 정당성 단락에 명시 + 사용자 의식 confirm.

## 5. 정당성 평가

다음 중 어느 차원의 개선인가:

- [ ] 부담 감소 (부정합·중복·모호함 제거)
- [ ] 검증 가능성 증가 (측정 가능한 결과 추가)
- [ ] 거울 정합도 향상 (본인 사고와 시스템 일치)

해당 없으면 `risk_smell: weak_justification` 표시 + 사용자 의식 결정.

## 6. 적용 commit

| 레포 | atomic commit 단위 | hash |
|---|---|---|
| SFD | ... | (적용 후 채움) |

## 7. 검증 체크리스트 (적용 후)

- [ ] 변경 키워드 grep 누락 0건 (`grep -rn "<old>" .` 0 hits)
- [ ] 보호 룰 재점검 통과
- [ ] `./init.sh verify` 통과
- [ ] STATUS.md / SESSION-LOG.md / HANDOFF.md 갱신
- [ ] 영향 받은 스킬·문서 일관성 (각 SKILL.md, AGENTS.md, README.md, rules.json)

## 8. 부수 효과 / 미해결

이 ADR 의 범위 밖이지만 발견된 사항. 다음 EVOLUTION 의 후보.
