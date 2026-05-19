# REGRESSION POLICY — 누적 게이트 풀 통과 조건

> `scenario-first-goal` 의 자동 게이트는 **NNN 시나리오 + 누적된 모든 이전 시나리오**를 함께 돌린다.
> 이 풀에 들어가는 조건을 명시 — 안 명시하면 cycle 늘수록 게이트가 영원히 빨강.

## 통과 조건 (반드시 1개)

> **`scenarios/expanded/NNN-*.md` 의 frontmatter `review_status: passed` 인 NNN의 GWT 시나리오만 누적 풀에 포함.**

근거:
- `expanded` 만 됐고 review 미통과면 시나리오 자체가 본인 의도와 어긋날 수 있음 → 게이트로 두면 잘못된 정답을 강요
- `goal_status: passed` 만으로는 부족 — review에서 본인이 직접 사용해야 진짜 정답
- 따라서 **review 통과**가 누적 진입 조건

## 제외 조건 (다음 중 하나면 누적에서 빠짐)

| 조건 | 제외 시점 | 비고 |
|---|---|---|
| `review_status: failed` 인데 routed_to: throw | 영구 제외 | 시나리오 자체가 폐기됨 |
| `review_status: failed` routed_to: spec / goal | 임시 제외 | rerun 후 다시 review 통과해야 재진입 |
| frontmatter에 `archived: true` | 영구 제외 | 사용자가 명시 폐기 |
| `tests/e2e/scenario-NNN/` 디렉터리 삭제됨 | 자동 제외 | 폐기 시 디렉터리도 정리 |

## 폐기 절차

NNN 폐기 시 다음을 함께:

1. `scenarios/expanded/NNN-*.md` frontmatter에 `archived: true` 추가 (파일은 보존 — 기록용)
2. `tests/e2e/scenario-NNN/` 디렉터리 → `.harness/.backups/<NNN>/<ISO8601>/tests/` 로 이동
3. `.harness/STATUS.md`의 누적 게이트 풀 섹션에서 해당 NNN 제거
4. 폐기 사유 한 줄을 `.harness/backlog.md`에 append (잊혀짐 방지)

## 동기 책임

`scenario-first-review` 4단계가 통과/실패 판정 직후 위 정책에 따라:
- STATUS.md 누적 게이트 풀 갱신
- 필요 시 폐기 절차 실행
- HANDOFF.md 갱신

다른 스킬이 이 정책을 우회하면 누적 풀이 깨짐 → 다음 goal 실패.

## 트레이드오프

엄격한 조건 (= passed만) 의 단점:
- review 통과까지 시간 걸리는 cycle은 다른 goal 실행에 누적 보호 못 받음 → 본인이 의식적으로 cycle 종결 책임

완화한 조건 (= goal passed도 포함) 의 단점:
- 본인이 안 써 봤는데 게이트가 통과를 가정 → 가짜 정답 누적

**v2 default = 엄격**. 완화하려면 본인 명시 동의 (이 문서 수정 + AGENTS.md 2.1 갱신).
