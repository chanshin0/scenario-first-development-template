---
id: 001
slug: self-contained-migration
date: 2026-05-19
status: applied
applied_commit:
  sfd: (채워질 예정 — 이 ADR 가 들어간 commit hash)
  plugify: (채워질 예정 — Plugify scenario-first 제거 commit hash)
risk_smell: none
---

# 001 — 자기완결 변환 (정본·시드 분리 폐기) + BUDGET → 진전 신호 3종

## 1. 변경 (before/after)

**Before:**
- 5 스킬(`throw`/`expand`/`spec`/`goal`/`review`) 정본은 [Plugify](https://github.com/chanshin0/Plugify) 마켓플레이스의 `scenario-first` 플러그인.
- SFD 는 init 스킬 + 하네스 시드만 보유. 새 사용자는 Plugify install + trust dialog + `cc-plugify` 등 외부 의존 거쳐야 5 스킬 사용 가능.
- goal 단계 stuck detection 에 `SCENARIO_GOAL_BUDGET` (비용 cap, default $5) 포함. 같은 변수가 정본(Plugify) + 시드(SFD `.env.scenario.example`) 두 곳에 박혀있었음.
- SFD `.claude/settings.json` 에 `extraKnownMarketplaces.plugify` + `enabledPlugins.scenario-first@plugify` 자동 등록.
- 시스템 명세 변경 통로 없음 — 변경이 사람 머릿속에만 박힘, 사후 박제 안 됨.

**After:**
- 6 스킬(`init` + `throw`/`expand`/`spec`/`goal`/`review`) 전부 SFD `skills/` 에 박힘. `.claude/skills/` 에 symlink 로 노출 → cwd 안에서 Claude Code 가 자동 인식 (마켓플레이스 의존 0).
- `.claude/agents/sfd-architect.md` 신규 — 시스템 명세 변경 메타 에이전트.
- SFD 가 GitHub template repository — 새 사용자는 "Use this template" → clone → `/scenario-first-init --from-template` → 사용.
- Plugify 에서 `skills/scenario-first-*` (5개) + `plugins/scenario-first/` 완전 제거. `marketplace.json` 의 `plugins` 배열은 빈 상태로 — Plugify 정체성은 "기타 도구 마켓플레이스" 로 좁힘.
- `SCENARIO_GOAL_BUDGET` 폐기. stuck detection 은 진전 신호 3종만:
  - `SCENARIO_GOAL_STUCK_RETRIES` (default 3) — 같은 실패 hash M회 연속
  - `SCENARIO_GOAL_NO_PROGRESS` (default 3) — PASS assertion count N회 동결
  - `SCENARIO_GOAL_MAX_ITERATIONS` (default 10) — 누적 iteration 상한
- AGENTS.md 운영 룰 8→9 — 3.9 = EVOLUTION ADR 통로. clean-state 체크리스트도 6→7 (EVOLUTION ADR 검증 추가).
- `.harness/rules.json` 에 `evolution_adr_required: true` 추가.
- `.harness/EVOLUTION/` 디렉터리 + `templates/EVOLUTION.md` 양식 신규. 이 ADR (001) 이 첫 사례.

## 2. 왜

2026-05-19 BUDGET → NO_PROGRESS 변경을 시드(SFD)만 갱신했을 때 정본(Plugify) 의 goal SKILL 은 옛 명세 그대로였음 → 같은 변수가 두 곳 박혀있어 5곳 누락 부정합 발생. 변경의 의미가 0이 된 채 푸시될 뻔함.

근본 원인 = **정본·시드 분리 모델**. 정본 갱신의 자동 반영 효익(SFD 5 스킬은 거의 안 고침)은 실질 가치 작고, 분리의 부담(부정합 위험 + 진입 장벽 + 메타 변경 통로 부담)은 큼.

자기완결로 전환하면:
- 변수·명세 grep 범위 = SFD 단일 레포 (부정합 재발 차단)
- 새 사용자 진입 5단계 → 3단계 (Plugify install / trust dialog / 마켓플레이스 update 모두 사라짐)
- 메타 변경(시스템 자기 진화) 통로 가벼움

함께 BUDGET 도 폐기 — 비용($)은 stuck 의 **결과** 지표라 cap 으로 안 잡는 게 옳음. 진전 신호 3종으로 stuck 을 직접 측정해야 의미 있음 (시도는 하는데 진전 0 / 같은 실패 반복 / 누적 상한 초과 모두 진전 신호 부재).

## 3. 영향 범위 grep 결과

### 자기완결 변환 (Plugify · plugify · scenario-first@plugify · extraKnownMarketplaces)

**SFD:**
```
README.md: 옛 v2/v3 변경 이력 라인에 "Plugify" 언급 (history 기록 — 보존)
.claude/agents/sfd-architect.md: description 안 "Plugify 의존 제거" 표현 (history 표현 — 보존)
.claude/settings.json: extraKnownMarketplaces.plugify + enabledPlugins.scenario-first@plugify  → 제거 대상
```

**Plugify:**
```
skills/scenario-first-{throw,expand,spec,goal,review}/  → 디렉터리 전체 제거
plugins/scenario-first/                                 → 디렉터리 전체 제거
.claude-plugin/marketplace.json                         → plugins 배열 비움
README.md                                               → scenario-first 입주 제거 + 정체성 재정의
```

### BUDGET → NO_PROGRESS

**SFD (이번 변경 후):**
```
.env.scenario.example: SCENARIO_GOAL_NO_PROGRESS=3  (이미 박힘)
skills/scenario-first-goal/SKILL.md: 진전 신호 3종 명세 + 측정 로직 + 금지 사항 갱신
skills/scenario-first-init/SKILL.md: .env.scenario.example 행 설명을 "진전 신호 3종 + E2E 명령" 으로
README.md: stuck detection 단락 — "진전 신호 3종" 으로 재서술
AGENTS.md: 5 환경 단락 — SCENARIO_GOAL_BUDGET → 진전 신호 3종
```

**Plugify (이번 변경 후):** 제거됨 (scenario-first 자체 제거).

적용 후 재grep 명령:
```bash
grep -rn "SCENARIO_GOAL_BUDGET" ~/Projects/scenario-first-development ~/Desktop/okestro/Plugify
# 기대: 이 ADR 본문 외 0 hit
grep -rn "scenario-first@plugify\|extraKnownMarketplaces" ~/Projects/scenario-first-development
# 기대: 0 hit (.claude/settings.json 갱신 완료 시)
```

## 4. 보호 룰 점검

- [x] review 자동화 거부 (AGENTS.md 6 금지) — OK (review 동작 변경 0)
- [x] cycle lock 단일 NNN (AGENTS.md 3.4) — OK (STATUS.md 양식 변경 0)
- [x] 누적 풀 진입 `review_status: passed` (AGENTS.md 3.1) — OK (REGRESSION-POLICY 변경 0)
- [x] 단방향 파이프라인 (rules.json) — OK (5단계 흐름 변경 0)
- [x] evidence 없이 passed 금지 (rules.json) — OK (rule 보존)
- [x] 자동 트리거 금지 (AGENTS.md 6) — OK + sfd-architect 자동 트리거 금지 항목 추가
- [x] Job Story 페르소나 금지 (rules.json) — OK
- [x] EVOLUTION ADR 의무 (rules.json) — OK + 본 ADR 이 첫 사례 (자기참조 적용)

위반 0. 자기참조(rule 3.9 도입 + 본 ADR 이 그 룰의 첫 사례) 는 의식 적용.

## 5. 정당성 평가

다음 3차원 모두 개선:

- [x] **부담 감소** — 같은 변수가 두 레포에 박히는 패턴 구조적 제거. grep 범위 단일 레포로 축소.
- [x] **검증 가능성 증가** — 진전 신호 3종은 측정 로직이 명세 박힘 (failure hash sha256-8 / PASS assertion count from reporter=json / iteration count). EVOLUTION ADR 자체가 변경 검증 슬롯 8개로 측정 가능성 증가.
- [x] **거울 정합도 향상** — "내가 만든 도구가 내 사고를 정확히 반영" — 부정합·외부 의존·즉흥 변경 채널이 모두 사라지고 본인 의도가 단일 레포에 박힘.

risk_smell: none.

## 6. 적용 commit

| 레포 | atomic commit 단위 | hash |
|---|---|---|
| SFD | "scenario-first: 자기완결 변환 (Plugify 정본 입주 + sfd-architect + EVOLUTION 통로 + BUDGET 폐기)" | (push 시 채움) |
| Plugify | "scenario-first: 5 스킬 + 플러그인 제거 (SFD 자기완결 이전 — SFD #001)" | (push 시 채움) |

## 7. 검증 체크리스트 (적용 후)

- [ ] `grep -rn "SCENARIO_GOAL_BUDGET" ~/Projects/scenario-first-development ~/Desktop/okestro/Plugify` — 본 ADR 외 0 hit
- [ ] `grep -rn "scenario-first@plugify\|extraKnownMarketplaces" ~/Projects/scenario-first-development` — 0 hit
- [ ] `ls ~/Desktop/okestro/Plugify/skills/scenario-first-*` — 0 디렉터리
- [ ] `ls ~/Desktop/okestro/Plugify/plugins/scenario-first` — 없음
- [ ] `ls ~/Projects/scenario-first-development/skills/scenario-first-*` — 6 디렉터리 (init + 5)
- [ ] `cat ~/Projects/scenario-first-development/.claude/agents/sfd-architect.md` — 존재
- [ ] `cat ~/Projects/scenario-first-development/.harness/templates/EVOLUTION.md` — 존재
- [ ] `cat ~/Projects/scenario-first-development/.harness/rules.json | jq .rules.evolution_adr_required.value` — `true`
- [ ] SFD `.claude/settings.json` 에 plugify/scenario-first@plugify 키 0건
- [ ] SFD README/AGENTS 에 "Plugify install" 안내 0건 (변경 이력 라인 제외)
- [ ] STATUS.md / SESSION-LOG.md / HANDOFF.md template 상태 (IN_PROGRESS/WAITING_ON_USER/STUCK 모두 (none), 로그 (none yet))
- [ ] scenarios/{throws,expanded,specs}/ + tests/e2e/ 에 `.gitkeep` 만
- [ ] GitHub Settings → "Template repository" 활성화 (사용자 수동)
- [ ] 양 레포 push 완료

## 8. 부수 효과 / 미해결 (다음 EVOLUTION 후보)

- **EVOLUTION 002 (후보)**: 진전 신호 3종 **구현** — failure hash 추출 로직, PASS assertion count 파싱(E2E reporter=json 강제), iteration 산출물 디렉터리, STUCK.md 자동 채움. 명세는 박혔지만 코드는 첫 cycle 돌릴 때 작성. 첫 cycle 의 결과로 부정확 확인 시 002 로 박을 것.
- **EVOLUTION 003 (후보)**: Plugify cc-plugify 의 정체성 좁힘. 현재 그 외 5 스킬(ai-readiness / improve-token-efficiency / presentation_slides / push-experience / self-review) 모두 마켓플레이스 등록 안 되어있어 cc-plugify 도 사실상 일시 무용. 향후 그 5 스킬 중 하나를 새 번들로 묶을 때 다룬다.
- **dogfooding 정착 확인**: 본 ADR 적용 commit 이후 새 시스템 명세 변경 시도가 실제로 `/sfd-architect` 호출로 시작되는지 관찰. 만약 직접 변경이 발생하면 룰 3.9 강화(rules.json enforcement: advisory → blocking) 검토.
