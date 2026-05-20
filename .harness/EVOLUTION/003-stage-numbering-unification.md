---
id: 003
slug: stage-numbering-unification
date: 2026-05-20
status: applied
applied_commit:
  sfd: 68d72bc
risk_smell: none
---

# 003 — 파이프라인 단계 번호 통일 (정수 1–5, expand=2)

## 1. 변경 (before/after)

**Before — 두 번호 체계 혼재:**
- Scheme A (지배적): `init=0, throw=1, expand=2, spec=3, goal=4, review=5` — README 다이어그램·AGENTS 표·init 스킬 whitelist 가 사용
- Scheme B (잔재): `expand=1.5, spec=2, goal=3, review=4` — 일부 스킬 description + 본문 참조에 남음

같은 review 스킬 안에서도 description 은 "4단계"(B), 본문 라우팅은 "2단계(expand)·3단계(spec)"(A) 로 섞여 있었음.

**After — Scheme A 단일:**
```
init=0  throw=1  expand=2  spec=3  goal=4  review=5
```
모든 description·본문·문서가 이 정수 체계로 통일. "1.5단계" 표기 제거.

## 2. 왜

expand 가 throw(1)·spec 사이에 나중에 삽입되며 "1.5단계" 로 표기됐는데, 이후 README/AGENTS/init 은 정수 1–5 로 재번호하면서 스킬 description·본문 일부가 옛 "1.5/review=4" 체계로 남음. review 가 어디선 4단계, 어디선 5단계로 불려 **읽는 사람·에이전트가 단계를 혼동**. 결정성 원칙(매 cycle 같은 절차)의 자기 위반.

정수 1–5 선택: (a) 이미 지배적이고 (README/AGENTS/init 전부), (b) "1.5" 보다 정수가 명료, (c) 고치는 표면적이 최소(스킬 description·본문 잔재만). expand 가 bridge 라는 의미는 번호가 아니라 description 본문이 설명.

## 3. 영향 범위 grep 결과

```
$ grep -rn "[0-9]\.\?[0-9]*단계" skills/ AGENTS.md README.md
```

변경 대상 (scheme B → A):
```
skills/scenario-first-expand/SKILL.md:3      1.5단계 → 2단계
skills/scenario-first-spec/SKILL.md:3        2단계 → 3단계
skills/scenario-first-spec/SKILL.md:163      review 4단계 → review 5단계
skills/scenario-first-goal/SKILL.md:3        3단계 → 4단계 / manual은 4단계 → 5단계
skills/scenario-first-goal/SKILL.md:16       3단계 게이트 → 4단계 / 4단계의 일 → 5단계의 일
skills/scenario-first-goal/SKILL.md:216      4단계의 일 → 5단계의 일
skills/scenario-first-goal/SKILL.md:222      4단계에서 → 5단계에서
skills/scenario-first-review/SKILL.md:3      4단계 → 5단계
skills/scenario-first-review/SKILL.md:10     3단계까지 → 4단계까지
skills/scenario-first-review/SKILL.md:16     매 cycle 4단계 → 5단계
skills/scenario-first-review/SKILL.md:26     3단계 STUCK → 4단계 STUCK
skills/scenario-first-review/SKILL.md:248    3단계 누적 게이트 → 4단계
README.md:229                                review 4단계 → review 5단계
```

변경 없음 (이미 scheme A):
```
throw desc 1단계 / init desc 0단계 / init whitelist 1~5단계
goal:223 init 0단계 / goal:223 'E2E ... 이 단계' (서술)
review:122 1단계(throw) / review:123 2단계(expand)·3단계(spec)
README:130 goal 4단계·5번 review / README:202 review 5단계 / README:253 4단계 게이트(goal)
AGENTS:62 goal 4단계 / AGENTS §2 표 0~5
init:152 '2단계 결정값' = init 내부 workflow step (파이프라인 단계 아님 — 유지)
```

적용 후 재grep:
```bash
grep -rn "1\.5단계\|expand.*1\.5\|review 4단계\|매 cycle 4단계" skills/ README.md AGENTS.md
# 기대: 0 hit
```

## 4. 보호 룰 점검

- [x] review 자동화 거부 — OK (동작 변경 0, 표기만)
- [x] cycle lock — OK
- [x] 누적 풀 진입 조건 — OK
- [x] 단방향 파이프라인 — OK (단계 순서 불변, 번호 표기만 통일)
- [x] evidence 없이 passed 금지 — OK
- [x] 자동 트리거 금지 — OK
- [x] Job Story 페르소나 금지 — OK
- [x] EVOLUTION ADR 의무 — OK (본 ADR)

위반 0. 순수 표기 통일, 동작·순서 변경 없음.

## 5. 정당성 평가

- [x] 부담 감소 — review 가 4/5 로 오락가락하던 혼동 제거. 단일 체계.
- [x] 거울 정합도 향상 — 결정성 원칙(같은 절차 반복)을 문서 자신이 지킴.
- [ ] 검증 가능성 — 약함 (표기 문제)

risk_smell: none.

## 6. 적용 commit

| 레포 | atomic commit 단위 | hash |
|---|---|---|
| SFD | "docs: 파이프라인 단계 번호 정수 1–5 통일 (expand=2, review=5) — ADR 003" | `68d72bc` |

## 7. 검증 체크리스트 (적용 후)

- [ ] `grep -rn "1\.5단계" skills/ README.md AGENTS.md` → 0 hit
- [ ] `grep -rn "매 cycle 4단계\|review 4단계" skills/ README.md` → 0 hit
- [ ] expand=2 / spec=3 / goal=4 / review=5 가 모든 description 에 일관
- [ ] `.claude/skills/` symlink 가 갱신된 본문 반영 (symlink 라 자동)

## 8. 부수 효과 / 미해결

- init SKILL 의 내부 workflow step 번호("2단계 결정값" 등)는 파이프라인 단계와 별개 — 혼동 여지 있으면 다음 ADR 에서 init 내부 step 을 "step N" 으로 재명명 검토.
