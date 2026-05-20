---
id: 002
slug: repo-rename-template-suffix
date: 2026-05-20
status: applied
applied_commit:
  sfd: (이 ADR 가 들어간 commit hash)
  plugify: (Plugify README URL 갱신 commit hash)
risk_smell: none
---

# 002 — 레포명 변경: `scenario-first-development` → `scenario-first-development-template`

## 1. 변경 (before/after)

**Before:**
- GitHub 레포: `chanshin0/scenario-first-development`
- 로컬 디렉터리: `~/Projects/scenario-first-development`
- init 스킬 `$SCENARIO_FIRST_HOME` 기본값: `~/Projects/scenario-first-development`

**After:**
- GitHub 레포: `chanshin0/scenario-first-development-template`
- 로컬 디렉터리: `~/Projects/scenario-first-development-template`
- init 스킬 `$SCENARIO_FIRST_HOME` 기본값: `~/Projects/scenario-first-development-template`
- SFD git remote URL + Plugify README 의 GitHub 링크 모두 `-template`

**유지 (변경 없음):**
- 방법론 이름 "Scenario-First Development" / "SFD" (개념 — kebab 레포명과 분리)
- 5 스킬 이름 `scenario-first-{throw,expand,spec,goal,review}` (스킬은 방법론 단계명)
- 모든 cycle 동작·운영 룰·하네스 layer

## 2. 왜

자기완결 변환(#001) 후 이 레포의 정체성이 "방법론 정본 + 시드" 에서 **"방법론을 적용할 수 있는 GitHub template repository"** 로 명확해짐. `-template` 접미사로 정체성을 이름에 박아 거울 정합도를 올린다.

scaffold / seed / template 중 template 선택: GitHub 의 "Use this template" 기능과 1:1 매핑되어 진입 흐름(#001 의 핵심 가치 = 진입 장벽 최소화)을 이름이 직접 설명. 방법론 이름("Scenario-First Development")은 그대로 두어 개념과 레포 인스턴스를 분리.

## 3. 영향 범위 grep 결과

```
$ grep -rln "scenario-first-development" ~/Projects/scenario-first-development-template --include='*.md' --include='*.sh' --include='*.json'
README.md                                  # B/C/갱신 섹션 로컬 경로 3곳
.claude/agents/sfd-architect.md            # grep 예시 2곳
.harness/templates/EVOLUTION.md            # grep 예시 1곳
skills/scenario-first-init/SKILL.md        # $SCENARIO_FIRST_HOME 기본값 + 설명 6곳
.harness/EVOLUTION/001-*.md                # 시점 기록 — 갱신 안 함 (001 당시 경로 보존)
```

Plugify:
```
README.md                                  # github.com/chanshin0/scenario-first-development 링크 2곳
```

ADR 001 의 경로는 **의도적으로 갱신 안 함** — 001 은 122349c 시점 기록이고, 그때 레포명은 `scenario-first-development` 였음. 시점 기록은 그 시점의 사실을 보존 (룰 10.1 정신). 001 의 검증 명령을 오늘 재실행하려면 경로에 `-template` 를 붙여야 함.

## 4. 보호 룰 점검

- [x] review 자동화 거부 — OK (영향 0)
- [x] cycle lock 단일 NNN — OK
- [x] 누적 풀 진입 조건 — OK
- [x] 단방향 파이프라인 — OK
- [x] evidence 없이 passed 금지 — OK
- [x] 자동 트리거 금지 — OK
- [x] Job Story 페르소나 금지 — OK
- [x] EVOLUTION ADR 의무 (rule 3.9) — OK (본 ADR 이 #001 이후 첫 적용 사례 = 통로 정착 확인)

위반 0. 순수 식별자 변경 — 동작 명세 변경 없음.

## 5. 정당성 평가

- [x] 거울 정합도 향상 — 레포 정체성("template")을 이름에 박음. 내부 어휘와 외부 이름 일치.
- [ ] 부담 감소 — 해당 약함 (rename 자체는 일회 비용 있음, 단 URL redirect 로 완화)
- [ ] 검증 가능성 — 해당 없음

risk_smell: none. 단일 차원(거울 정합도) 개선이지만 #001 의 정체성 확정과 직결되어 정당.

## 6. 적용 commit

| 레포 | atomic commit 단위 | hash |
|---|---|---|
| SFD | "refactor: 레포명 -template 접미사 반영 (경로 레퍼런스 + ADR 002)" | (채움) |
| Plugify | "docs: SFD GitHub URL -template 반영" | (채움) |

## 7. 검증 체크리스트 (적용 후)

- [ ] `git -C ~/Projects/scenario-first-development-template remote get-url origin` → `...scenario-first-development-template.git`
- [ ] 로컬 디렉터리 `~/Projects/scenario-first-development-template` 존재, 옛 경로 없음
- [ ] `grep -rn "scenario-first-development[^-]" ~/Projects/scenario-first-development-template --include='*.md' --include='*.sh' --include='*.json'` → ADR 001 외 0 hit (001 은 시점 기록)
- [ ] Plugify README 의 GitHub 링크 2곳 `-template`
- [ ] `git push` 양 레포 성공
- [ ] GitHub redirect 동작 (옛 URL clone 시 새 URL 로)

## 8. 부수 효과 / 미해결

- GitHub 옛 URL 은 자동 redirect 되므로 #001 의 Plugify README 링크가 아니라도 당분간 동작. 단 명시 갱신이 거울 정합도에 맞음.
- 옛 경로로 clone 한 다른 머신·CI 가 있으면 remote set-url 필요 (현재 single-user 라 무시 가능).
