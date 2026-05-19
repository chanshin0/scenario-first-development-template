# STATUS — scenario-first cycle 진행 상태

> 5 스킬 각각이 작업 끝에 한 줄씩 갱신 (AGENTS.md 룰 3.3).
> 사람이 매 세션 시작 시 가장 먼저 보는 곳.

---

## ⚠️ Cycle lock — 한 번에 한 NNN (룰 3.4 반복 강제 — AGENTS.md + 여기 + 세션 종료 체크리스트)

`IN_PROGRESS:` 가 채워져 있는 동안 새 throw 시도하면 사전 점검에서 **멈춤**.
해제: 그 NNN review_status=passed, 또는 명시 폐기 (REGRESSION-POLICY 절차).

머신 검증: `.harness/rules.json` 의 `single_active_cycle: true`.

## IN_PROGRESS
IN_PROGRESS: (none)

## WAITING_ON_USER
<!-- review 4단계가 본인 사용 대기로 멈춘 cycle. Claude 시뮬레이션 금지. -->
WAITING_ON_USER: (none)

## STUCK
<!-- goal 4단계가 escalate 한 cycle (STUCK.md 참조). -->
STUCK: (none)

## BACKUPS
<!-- rerun/force 백업 추적 — 파일 자체는 .harness/.backups/ (gitignore). -->
<!-- 형식: - <ISO8601> <NNN> <원본> → <백업경로> -->

---

## Cycle 로그
<!-- 5 스킬 작업 끝에 한 줄 append. 최신이 위. -->
<!-- 형식: - <ISO8601> NNN-XXX [throw|expand|spec|goal|review] <한 줄 요약> -->

(none yet)

---

## 누적 게이트 풀 (review_status=passed)
<!-- goal 4단계가 누적 regression에 포함하는 NNN 목록. -->
<!-- REGRESSION-POLICY.md 의 통과 조건만 진입. -->
<!-- 형식: - NNN (passed at <ISO8601>) — <Job Story 한 줄> -->

(none yet)
