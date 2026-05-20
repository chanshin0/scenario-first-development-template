---
id: 004
slug: init-optional-clone-and-throw
date: 2026-05-20
status: applied
applied_commit:
  sfd: abed466
risk_smell: none
---

# 004 — init 을 선택 단계로: "clone → throw" 가 기본 진입

## 1. 변경 (before/after)

**Before:**
- 진입 경로 3개(A: template+init --from-template / B: 빈 디렉터리 init / C: 수동 cp) + 갱신 섹션이 README 상단을 차지.
- `throw` description: "하네스 layer 는 `/scenario-first-init` 으로 사전 설치 필수".
- `goal` 사전점검: `SCENARIO_E2E_CMD` 미설정이면 **에러** ("init 다시"). E2E 결정은 init(0단계) 전용.

**After:**
- 기본 진입 = **"Use this template" → clone → `/scenario-first-throw`** 단 2스텝. init 은 선택.
- B/C/갱신은 README `<details>` 접기로 이동.
- `throw` description: 하네스는 template clone 에 이미 포함 — 바로 호출. 빈 디렉터리 시작 때만 init 선행.
- `goal` 에 **0번 단계 추가**: `SCENARIO_E2E_CMD` 미설정이면 에러 대신 그 자리에서 1회 E2E 결정 + `.env.scenario` 생성 + placeholder 치환. init 의 E2E 로직과 동일.

## 2. 왜

자기완결 변환(#001)의 핵심 가치 = 진입 장벽 최소화. 그런데 README 가 진입 방법 3개 + init 필수처럼 제시해 정반대로 복잡해 보였음 (사용자 피드백: "시작 방법이 왤캐 어려워? 그냥 클론하고 개발 시작 안돼?").

분석: template clone 은 `.harness/` + `.claude/skills/` 6 스킬을 **이미 포함**하므로 init 의 "시드 복사" 가 불필요. throw(1)·expand(2)·spec(3) 은 init 없이 동작. init 이 진짜 load-bearing 한 건 `.env.scenario` + E2E 결정뿐인데, 이건 goal(4) 전에만 있으면 됨 → 시작 시점 강제할 이유 없음. E2E 결정을 goal 0번으로 옮기면 init 은 순수 선택(미리 정리하고 싶을 때)이 됨.

## 3. 영향 범위 grep 결과

```
README.md            # '## 새 프로젝트 시작' A/B/C → clone→throw 헤드라인 + <details>; '## 다음' 갱신
skills/scenario-first-throw/SKILL.md:3    # description '사전 설치 필수' → 'template 에 이미 포함'
skills/scenario-first-goal/SKILL.md:51    # 사전점검 4번 E2E 에러 → 0번 inline 결정으로
skills/scenario-first-goal/SKILL.md:금지   # 'E2E 결정 묻기 금지' → '이미 설정 시 재질문 금지, 미설정 1회는 정상'
```

`scenario-first-init` 스킬 자체는 변경 없음 — 여전히 빈 디렉터리/갱신용으로 유효. `--from-template` 모드도 보존(선택 정리용).

## 4. 보호 룰 점검

- [x] review 자동화 거부 — OK
- [x] cycle lock — OK (throw 사전점검의 IN_PROGRESS 검사 유지)
- [x] 누적 풀 진입 조건 — OK
- [x] 단방향 파이프라인 — OK (단계 순서·방향 불변)
- [x] evidence 없이 passed 금지 — OK
- [x] 자동 트리거 금지 — OK (E2E 0번도 goal 수동 호출 안에서만)
- [x] Job Story 페르소나 금지 — OK
- [x] EVOLUTION ADR 의무 — OK (본 ADR)

위반 0. E2E 결정 위치 이동(init→goal 0번)은 "init 0단계 결정" 룰의 완화지만, init 강제를 없애려는 본 변경의 핵심이라 의도적.

## 5. 정당성 평가

- [x] 부담 감소 — 진입 3스텝+init 필수 → 2스텝. README 인지 부하 대폭 감소.
- [x] 거울 정합도 향상 — #001 의 "진입 장벽 최소화" 가 실제 진입 흐름에 반영됨 (전엔 말과 실제가 어긋남).
- [ ] 검증 가능성 — 해당 약함.

risk_smell: none.

## 6. 적용 commit

| 레포 | atomic commit 단위 | hash |
|---|---|---|
| SFD | "feat: clone→throw 기본 진입 (init 선택화 + goal E2E inline) — ADR 004" | `abed466` |

## 7. 검증 체크리스트 (적용 후)

- [ ] README 상단이 clone→throw 2스텝, B/C/갱신은 `<details>` 안
- [ ] `throw` description 에 "사전 설치 필수" 문구 없음
- [ ] `goal` 에 "0. E2E 프레임워크 결정 (미설정 시 1회)" 단계 존재, 사전점검이 E2E 미설정에 에러 안 냄
- [ ] 빈 디렉터리 init 경로 + `--from-template` 여전히 문서에 있음 (선택 경로 보존)

## 8. 부수 효과 / 미해결

- goal 0번의 E2E 결정 로직이 init 의 그것과 중복 — 향후 공통 절차로 추출 검토(다음 ADR). 지금은 명세 중복 허용(둘 다 같은 결과).
- init 의 `--from-template` 모드는 이제 "선택 정리" 역할만 — 사용 빈도 낮으면 향후 통합/제거 검토.
