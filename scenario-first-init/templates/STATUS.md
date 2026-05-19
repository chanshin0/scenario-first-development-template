# STATUS — scenario-first cycle 진행 상태

> 이 파일은 5 스킬 각각이 작업 끝에 한 줄씩 갱신한다. **AGENTS.md 운영 룰 2.3·2.4 강제**.
> 사람이 매 세션 시작 시 먼저 보는 곳.

## IN_PROGRESS
<!-- 동시 진행 가능 cycle 단 1개. 비어 있으면 새 throw 가능. -->
IN_PROGRESS: (none)

## WAITING_ON_USER
<!-- review 4단계가 사용자 사용 대기로 멈춘 cycle. -->
WAITING_ON_USER: (none)

## STUCK
<!-- goal 4단계가 escalate 한 cycle (STUCK.md 참조). -->
STUCK: (none)

## BACKUPS
<!-- rerun/force 백업 추적 — 파일 자체는 .scenarios/.backups/ (gitignore). -->
<!-- 형식: - <ISO8601> <NNN> <원본> → <백업경로> -->

---

## Cycle 로그
<!-- 5 스킬 작업 끝에 한 줄 append. 최신이 위. -->
<!-- 형식: - <ISO8601> NNN-XXX [throw|expand|spec|goal|review] <한 줄 요약> -->

(none yet)

---

## 누적 게이트 풀 (review_status=passed)
<!-- goal 4단계가 누적 regression에 포함하는 NNN 목록. -->
<!-- 형식: - NNN (passed at <ISO8601>) — <Job Story 한 줄> -->

(none yet)
