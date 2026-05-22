# STATUS — scenario-first cycle 진행 상태

> 5 스킬 + deepen/tweak 이 각자 작업 끝에 한 줄씩 갱신 (AGENTS.md 룰 3.3).
> 사람이 매 세션 시작 시 가장 먼저 보는 곳.
>
> **append 규약**: 줄 추가는 항상 해당 섹션의 `*-INSERT` 마커 **바로 다음 줄**에 꽂는다 (아래 awk 패턴).
> 파일 끝 `echo >>` 는 금지 — 파일 끝은 누적 게이트 풀(머신 검증 대상)이라 오염된다.
> `awk -v l="$LINE" '1;/<!-- CYCLE-LOG-INSERT/{print l}' .harness/STATUS.md > .harness/STATUS.md.tmp && mv .harness/STATUS.md.tmp .harness/STATUS.md`

---

## ⚠️ Cycle lock — 한 번에 하나 (룰 3.4 반복 강제 — AGENTS.md + 여기 + 세션 종료 체크리스트)

`IN_PROGRESS:` 가 채워져 있는 동안 새 throw/deepen 시도하면 사전 점검에서 **멈춤**.
한 번에 하나만: throw-cycle `NNN-<slug>` **또는** deepen `deepen-NNN`.
해제: throw-cycle 은 그 NNN review_status=passed 또는 명시 폐기(REGRESSION-POLICY), deepen 은 review 재통과 시 자동 `(none)`.

머신 검증: `.harness/rules.json` 의 `single_active_cycle: true`.

## IN_PROGRESS
<!-- 형식: (none) | NNN-<slug> (throw-cycle) | deepen-NNN (deepen) -->
IN_PROGRESS: (none)

## WAITING_ON_USER
<!-- review 4단계가 본인 사용 대기로 멈춘 cycle. Claude 시뮬레이션 금지. -->
WAITING_ON_USER: (none)

## STUCK
<!-- goal 4단계가 escalate 한 cycle (STUCK.md 참조). -->
STUCK: (none)

## REVIEW_PENDING (deepen)
<!-- deepen 이 goal-green 후 배치 review 로 미룬 NNN. source of truth = expanded frontmatter `deepen_pending_review`. -->
<!-- /scenario-first-review --deepen-batch 가 전부 순회. 비어있지 않으면 새 throw 전 닫기 권고. -->
<!-- REVIEW-PENDING-INSERT — deepen 보류 NNN 은 이 줄 바로 다음에 삽입. 배치 review 통과 시 제거. -->

## BACKUPS
<!-- rerun/force 백업 추적 — 파일 자체는 .harness/.backups/ (gitignore). -->
<!-- 형식: - <ISO8601> <NNN> <원본> → <백업경로> -->
<!-- BACKUPS-INSERT — backup 줄은 이 줄 바로 다음에 삽입. 파일 끝 `echo >>` 금지. -->

---

## Cycle 로그
<!-- 5 스킬 작업 끝에 한 줄 append. 최신이 위. -->
<!-- 형식: - <ISO8601> NNN-XXX [throw|expand|spec|goal|review] <한 줄 요약> -->
<!-- CYCLE-LOG-INSERT — cycle 로그 줄은 이 줄 바로 다음에 삽입 (최신이 위). 파일 끝 `echo >>` 금지. -->

(none yet)

---

## 누적 게이트 풀 (review_status=passed)
<!-- goal 4단계가 누적 regression에 포함하는 NNN 목록. -->
<!-- REGRESSION-POLICY.md 의 통과 조건만 진입. -->
<!-- 형식: - NNN (passed at <ISO8601>) — <Job Story 한 줄> -->
<!-- POOL-INSERT — review_status=passed 인 NNN 만 이 줄 바로 다음에 삽입 (룰 3.1). 그 외 append 금지. -->

(none yet)
