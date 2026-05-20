---
id: 005
slug: from-template-spec-and-clone-state-docs
date: 2026-05-20
status: applied
applied_commit:
  sfd: (이 ADR 가 들어간 commit hash)
risk_smell: none
---

# 005 — `--from-template` 정식 정의 + clone 직후 상태/정리 설명

## 1. 변경 (before/after)

**Before:**
- `--from-template` 모드가 init 스킬 description·원리 문단에만 언급되고 **명령 표·workflow 에는 없었음**. 동작이 반쪽 정의 — 에이전트가 호출해도 정확히 뭘 정리할지 명세 부재.
- README 가 clone 정리에 plain `/scenario-first-init` 를 안내(ADR 004) — 그런데 plain init 은 `$SCENARIO_FIRST_HOME` 복사 로직이라 clone 사본엔 부적합.
- README 가 "clone 직후 어떤 상태인지" + "init 이 무엇을 정리하는지" 를 설명 안 함 → 사용자 혼란 (B/C 차이·init 역할 불명확).

**After:**
- init 스킬 명령 표에 `--from-template` 행 추가 + **"`--from-template` 모드" workflow 절** 신설 (정리 동작 5종 + 제거 안 하는 자산 명시).
- README clone 정리를 `/scenario-first-init --from-template` 로 정정.
- README 에 **clone 직후 상태 표**(그대로 쓰는 자산 vs SFD 색) + init 이 오른쪽 칸을 어떻게 치우는지 4단계 추가.
- README `<details>` 의 A/B/C 를 "파일을 새 디렉터리에 넣는 방법만 다름" 으로 재프레이밍 + B↔A 차이 명시.

동작 자체(throw~spec 무-init 진행, goal 0번 E2E)는 ADR 004 그대로 — 본 ADR 은 `--from-template` 의 정리 동작을 **명시화**하고 진입 문서를 자기설명적으로 만든 것.

## 2. 왜

사용자 피드백: "다른 시작 방법이 잘 이해가 안가. 미리 정리한다는게 설명이 필요해 — 처음 클론받으면 어떤 상태인데 init 이 이걸 어떻게 정리하는지."

근본 원인: (a) ADR 004 가 init 을 선택화하면서 `--from-template` 의 정식 정의를 안 채움 — README 는 그걸 쓰라는데 스킬엔 workflow 없음 (부정합). (b) "clone 직후 상태" 라는 암묵 지식이 문서에 없어, 사용자가 init 의 정리 대상을 그릴 수 없었음. 묵시→명시화 위반.

## 3. 영향 범위 grep 결과

```
skills/scenario-first-init/SKILL.md   # 명령 표 + '--from-template 모드' workflow 절 신설
README.md                             # '## 새 프로젝트 시작': clone 상태 표 + 정리 4단계 + A/B/C 재프레이밍; '## 다음' init→--from-template
```

`--from-template` 언급 위치 (적용 후 일관):
```
init SKILL: 명령 표 + 모드 workflow + 원리 문단
README: 헤드라인 아래 정리 섹션 + <details> A/B/C + ## 다음
EVOLUTION/001,004: 시점 기록 (그대로)
```

## 4. 보호 룰 점검

- [x] review 자동화 거부 — OK
- [x] cycle lock — OK
- [x] 누적 풀 진입 조건 — OK
- [x] 단방향 파이프라인 — OK
- [x] evidence 없이 passed 금지 — OK
- [x] 자동 트리거 금지 — OK (init 여전히 수동)
- [x] Job Story 페르소나 금지 — OK
- [x] EVOLUTION ADR 의무 — OK (본 ADR)

위반 0. 명시화 + 문서. 동작 신규 없음(반쪽 정의를 완성).

## 5. 정당성 평가

- [x] 부담 감소 — README/스킬 부정합(plain init vs --from-template) 제거.
- [x] 검증 가능성 증가 — `--from-template` 정리 대상이 표로 명세 → 에이전트가 결정적으로 실행 가능.
- [x] 거울 정합도 향상 — "clone 직후 상태" 암묵 지식을 명시화 (묵시→명시 원칙).

risk_smell: none.

## 6. 적용 commit

| 레포 | atomic commit 단위 | hash |
|---|---|---|
| SFD | "docs: --from-template 정식 정의 + clone 상태/정리 설명 — ADR 005" | (채움) |

## 7. 검증 체크리스트 (적용 후)

- [ ] init SKILL 명령 표에 `--from-template` 행 + "`--from-template` 모드" workflow 절 존재
- [ ] README '새 프로젝트 시작' 에 clone 상태 표 + 정리 4단계 + A/B/C 재프레이밍
- [ ] README 의 clone 정리 안내가 `--from-template` (plain init 아님)
- [ ] `grep -n "미리 정리.*scenario-first-init$" README.md` → plain init 안내 잔존 0

## 8. 부수 효과 / 미해결

- ADR 004 §8 에 적은 "init 의 E2E 결정과 goal 0번의 E2E 결정 중복" 은 여전 — `--from-template` 도 같은 E2E 로직을 참조하므로 3곳(init copy / init --from-template / goal 0번)이 같은 절차를 가리킴. 공통 절차 추출은 다음 ADR 후보로 유지.
