# AGENTS.md — {{PROJECT_NAME}}

이 레포는 **시나리오-First 개발 파이프라인 v2** 로 운영된다. 모든 에이전트(Claude Code / codex / cursor / 그 외) 는 작업 시작 전 이 문서를 읽고, 아래 워크플로와 운영 룰을 지킨다.

## 0. 한눈에

```
사용자 머리 ──► throw ──► expand ──► spec ──► goal ──► review ──► 다음 backbone
                  ↑                                          │  │
                  └──── (1) 시나리오 / (2) Spec / (3) 구현 ───┘  │
                          5 Whys 라우팅 (실패 시)                │
                                                                │ review_status=passed
                  ┌──────────────  deepen  ◄────────────────────┘
                  │  (post-MVP, depth: 통과 NNN 해상도 ↑, NNN별 순차)
                  └─► expanded 에 example 누적 ─► goal green ─► review 보류
                             여러 NNN 보류분 ─► review --deepen-batch (한 번에 검증)

         tweak (post-MVP, cosmetic: 행동 델타 없는 외관) ─► 게이트1=기존 풀 green 유지 + 게이트2=시각 evidence
```

- SoT는 코드도 spec도 아니고 **`scenarios/throws/NNN-*.md`의 Job Story**.
- 단방향. 양방향 동기 안 함. (deepen 은 역방향이 아니라 통과 NNN의 **재진입** — 같은 NNN에 example 추가 후 goal→review 로 다시 앞으로 흐름.)
- **3축**: breadth=`throw`(새 backbone) / depth=`deepen`(있는 걸 정밀하게) / cosmetic=`tweak`(외관, 행동 델타 없음). 둘 다 post-MVP. 구별 리트머스 = "새 GWT(Then)를 쓸 수 있나" — 있으면 deepen, 없으면 tweak.
- **한 번에 하나 (throw-cycle NNN 또는 deepen-NNN). 강제.** (tweak 은 cycle 아님 — lock 미점유, 단 실행 전 (none) 요구.)
- 자동 트리거 금지 — 모든 스킬은 사용자 호출 시에만.

## 1. 세션 시작 워크플로 (코드 작성 전 반드시 6단계)

```bash
# 1. 작업 디렉터리 확인
pwd

# 2. cycle 상태 읽기 (IN_PROGRESS / WAITING_ON_USER / STUCK)
cat .harness/STATUS.md

# 3. 세션 인계 읽기 (마지막 에이전트가 남긴 다음 액션)
cat .harness/HANDOFF.md

# 4. 최근 commit 검토
git log --oneline -5

# 5. 환경 부트스트랩 (멱등)
./init.sh

# 6. 누적 게이트 smoke (이미 빨강이면 새 cycle 시작 금지)
./init.sh verify
```

**기준선 검증이 이미 실패 중이면 먼저 수정**. 망가진 시작 상태 위에 새 cycle 쌓지 마라.

읽기 분기:
1. STATUS.md `IN_PROGRESS:` 가 채워져 있으면 → 그 cycle 의 단계 산출물 (`scenarios/specs/NNN/` 또는 `scenarios/expanded/NNN-*.md`) 까지 읽고 이어서.
2. 비어 있으면 → backlog.md 훑고 새 throw 후보 확인.
3. `WAITING_ON_USER:` 가 채워져 있으면 → review 대기 cycle 이니 본인 사용 입력 기다리기 (Claude 시뮬레이션 금지).

## 2. 스킬 (코어 5 + post-MVP 2) + init

| 단계 | 스킬 | 산출 |
|---|---|---|
| 0 | `/scenario-first-init` | (선택) clone 정리 — placeholder 치환 + `.env.scenario` 생성 + E2E 결정 + SFD 메타 제거 |
| 1 | `/scenario-first-throw "<자유 텍스트>"` | `scenarios/throws/NNN-*.md` |
| 2 | `/scenario-first-expand <NNN>` | `scenarios/expanded/NNN-*.md` (USM + Example Mapping + GWT) |
| 3 | `/scenario-first-spec <NNN>` | `scenarios/specs/NNN/{PRD,ARCHITECTURE,NONFUNC,OPS}.md` |
| 4 | `/scenario-first-goal <NNN>` | `tests/e2e/scenario-NNN/`, `scenarios/specs/NNN/{GOAL,STUCK}.md`, commits |
| 5 | `/scenario-first-review <NNN>` | `scenarios/specs/NNN/REVIEW.md` |
| depth | `/scenario-first-deepen <NNN>` | (post-MVP) 통과 NNN의 `expanded` 에 example in-place 누적 + goal/review 재실행 — 룰 3.10 |
| cosmetic | `/scenario-first-tweak "<의도>"` | (post-MVP) 행동 델타 없는 UI/UX 변경. 게이트1=기존 풀 green 유지, 게이트2=시각 evidence — 룰 3.11 |

## 3. 운영 11룰 (반드시)

### 3.1 누적 게이트 통과 조건
`goal` 4단계의 자동 게이트는 NNN 시나리오뿐 아니라 `scenarios/expanded/*` 의 GWT 시나리오 전체를 누적해서 돌린다. 누적 풀 진입 조건:

> **`review_status: passed` 인 NNN만 누적 풀에 포함.**

`expanded` 만 됐지만 review 미통과인 NNN의 GWT는 제외. 폐기된 NNN 도 영구 제외. 자세한 정책은 `.harness/REGRESSION-POLICY.md`.

### 3.2 rerun 백업 경로 통일
모든 `--rerun`·`--force` 동작은 백업을 다음 경로에 만든다:

```
.harness/.backups/<NNN>/<ISO8601>/<원본파일경로>
```

이 경로는 gitignore. 추적은 STATUS.md `## BACKUPS` 섹션의 `BACKUPS-INSERT` 마커 다음 줄.

### 3.3 STATUS.md 갱신 책임
5 스킬 + deepen/tweak 은 각자 작업 끝에 `.harness/STATUS.md` 를 한 줄 갱신한다. 스킬을 실행한 에이전트가 책임.

형식:
```
- <ISO8601> NNN-XXX [throw|expand|spec|goal|review|deepen] <한 줄 요약>
- <ISO8601> [tweak] <변경 의도> (NNN 없음)
```

**어느 섹션에 꽂는가** (섹션 경계 오염 방지 — 파일 끝 `echo >>` 금지):
- cycle 로그 → `## Cycle 로그` 의 `CYCLE-LOG-INSERT` 마커 다음 줄 (최신이 위)
- backup 줄 → `## BACKUPS` 의 `BACKUPS-INSERT` 마커 다음 줄
- 통과 NNN → `## 누적 게이트 풀` 의 `POOL-INSERT` 마커 다음 줄 (review 만, 룰 3.1)

삽입은 마커 타게팅 awk 로 (파일 끝은 누적 게이트 풀 = 머신 검증 대상이라 맹목 append 시 오염):
```bash
awk -v l="$L" '1;/<!-- CYCLE-LOG-INSERT/{print l}' .harness/STATUS.md > .harness/STATUS.md.tmp && mv .harness/STATUS.md.tmp .harness/STATUS.md
```

### 3.4 cycle lock — 한 번에 한 NNN (반복 강제)

> 이 룰은 **AGENTS.md (여기) + STATUS.md 상단 + 세션 종료 체크리스트** 3곳에 반복 박힘. 그만큼 깨지기 쉬움.

`STATUS.md` 상단의 `IN_PROGRESS:` 라인은 단일 NNN만. 이미 차 있는데 새 NNN throw 시도하면 에이전트는 **사전 점검에서 멈춤**.

해제 조건:
- 그 NNN이 `review_status: passed` 또는
- 사용자가 명시 폐기 (`STATUS.md` 라인 제거 + REGRESSION-POLICY 폐기 절차)

머신 검증: `.harness/rules.json` 의 `single_active_cycle: true` 로 hook 가능.

### 3.5 routing의 NNN 재사용
`review` 가 5 Whys 후 라우팅할 때:

| 라우팅 | NNN |
|---|---|
| (1) 시나리오 오류 → throw 갱신 | **같은 NNN 백업 후 덮어쓰기** |
| (2) Spec 누락 → spec --rerun | 같은 NNN |
| (3) 구현 오류 → goal --resume | 같은 NNN |
| (신규 backbone 슬라이스) | **새 NNN** (현재 max + 1) |

throw 본문의 "기존 throws 카운트해서 다음 번호" 룰은 신규 throw에만 적용.

### 3.6 Story·보류 풀
`.harness/backlog.md` 는 다음을 모은다 (append-only):
- `expand`의 Example Mapping에서 🟨 Story 카드로 이월된 항목
- `spec`의 ARCH "보류" 슬롯의 결정

### 3.7 codex / cursor 트리거 규약
슬래시 못 쓰는 에이전트는 사용자 메시지 본문에서 인라인 트리거 인식:

```
[SCENARIO:throw] <자유 텍스트>
[SCENARIO:expand] NNN
[SCENARIO:spec] NNN
[SCENARIO:goal] NNN
[SCENARIO:review] NNN
[SCENARIO:architect] <변경 의도>     # sfd-architect 호출 (룰 3.9)
```

### 3.8 jargon 정책
5 스킬이 사용하는 다음 용어는 **학습 완료로 간주** — 산출물 본문에 그대로 사용:

- Job Story / GWT (Given-When-Then) / Gherkin
- User Story Mapping (USM) / Backbone / Walking skeleton
- Example Mapping / Rule / Example / Question / Story 카드
- 5 Whys / regression / E2E

이 외 jargon은 사용자의 `~/.claude/CLAUDE.md` "본인 언어 + (괄호 jargon)" 패턴.

### 3.9 하네스 변경 통로 (sfd-architect 검토)

5 스킬·운영 룰·`rules.json`·하네스 layer·init 동작·`.env.scenario.example` 스키마·sfd-architect 자신 등 **하네스(템플릿 레이어) 자체** 를 바꾸려는 변경은 즉흥 변경 금지. "프로젝트 코드" 가 아니라 시스템을 건드릴 때의 안전 통로:

1. 사용자가 `/sfd-architect "<변경 의도>"` 호출 (또는 슬래시 안 쓰는 에이전트는 `[SCENARIO:architect] <text>`)
2. `sfd-architect` 가 영향 grep + 보호 룰 점검 + 정당성 평가 → 검토 보고 + commit message 초안 (검토 전용 — 코드 못 건드림)
3. 사용자 confirm
4. 메인 에이전트가 적용 + atomic commit (commit message 에 변경/근거/영향 기록) + 변경 키워드 재grep 으로 부정합 0 확인

**기록은 commit message** — 별도 ADR 파일 안 만든다. 하네스 진화 기록은 git history 가 권위이고, template clone 은 히스토리를 미상속하므로 이 기록이 다운스트림으로 새지 않는다.

대상이 cycle 산출물(`scenarios/throws|expanded|specs/*`, `tests/e2e/*`)·프로젝트 코드면 통로 밖 — 그냥 개발 또는 5 스킬의 일.

머신 검증: `.harness/rules.json` 의 `harness_change_via_architect: true`.

### 3.10 deepen — 통과 시나리오 해상도 올리기 (depth 연산)

MVP(0→1)가 세운 시나리오는 저해상도(정상 케이스). "실제 쓸 서비스"로 만들려면 상세 동작(0건·소스다운·동률·품절·로딩·에러)을 정밀하게 못 박아야 한다. 이건 새 기능(새 throw)이 아니라 **같은 시나리오의 정밀화** — `scenario-first-deepen` 이 담당.

- 대상: `review_status: passed` 인 NNN만 (미통과면 throw 파이프라인 먼저).
- 동작: backlog 의 `[deepen NNN]` 항목(또는 inline)을 GWT example 로 만들어 `scenarios/expanded/NNN-*.md` 에 **in-place 누적**(`resolution:` +1) → goal 재실행 → green 후 **review 보류**(`deepen_pending_review`). 새 NNN 안 만듦.
- **review 는 배치**: NNN별 순차로 goal 까지 태우고, review 는 `/scenario-first-review --deepen-batch` 로 보류분(REVIEW_PENDING)을 한자리에서 검증. 보류 창 동안 새 example 은 잠정 풀 멤버(REGRESSION-POLICY). 보류분 있으면 새 throw 전 닫기 권고.
- **단조성(hard rule)**: example 을 **추가만**. 기존 example/GWT 수정·제거·약화 금지. 이것이 잠긴 누적 풀 보호의 전제 — 위반 시 회귀 가능. deepen 중 NNN은 풀 유지 (REGRESSION-POLICY "deepen 중 풀 유지").
- cycle lock: deepen 은 `IN_PROGRESS: deepen-NNN` 로 lock 점유 (룰 3.4, `deepen-` prefix 로 throw-cycle 과 격리). throw 와 동시 불가.
- 새 example 이 잠긴 행동과 충돌하면(기존 example red) deepen 이 임의 해소 금지 → review triage.

머신 검증: `.harness/rules.json` 의 `single_active_cycle`(deepen-NNN 포함) + `deepen_monotonic`.

deepen 은 배치(여러 항목)를 받는다: green 도달 example 은 잠그고, STUCK 항목의 *이번 패스 추가분만* expanded 에서 철회해 backlog 환원(부분 커밋). 새 동작이 spec 디테일을 요구하면 터치한 슬롯만 보강(PRD 재작성 금지).

### 3.11 tweak — 행동 델타 없는 UI/UX 변경 (cosmetic 축)

MVP·deepen 으로 동작이 정의된 뒤의 외관 다듬기(여백·문구·색·정렬·인터랙션). `scenario-first-tweak` 이 담당 — Job Story·GWT 작성 없음.

- **deepen 과 구별 (리트머스)**: 새 GWT(Then 단언)를 쓸 수 있으면 `deepen`(행동), 못 쓰면(순수 외관·주관) `tweak`. 헷갈리면 게이트 1 이 판정 — tweak 이 풀을 깨면 행동을 바꾼 것 → deepen/throw 로 승격.
- **게이트 1 (자동)**: 기존 누적 풀 green 유지 = 행동 안 바꿨다는 증명. 기존 풀 **재사용**(신규 게이트 아님 — 누적 풀 밖 분리 금지에 부합).
- **게이트 2 (수동)**: 본인이 시각 결과 직접 보고 evidence 승인(`scenarios/tweaks/`). evidence 없이 완료 표시 금지(review 와 같은 강도).
- cycle lock **미점유**(cycle 아님 — 새 NNN/expanded 없음), 단 실행 전 `IN_PROGRESS=(none)` 요구. 누적 풀 **미진입**(새 NNN 아님). cycle 로그 태그 `[tweak]`.
- 표면 커버리지: soft warn (풀 미커버 표면은 행동 변화를 게이트 1 이 못 잡음 → 의심되면 deepen/throw). hard block 은 표면↔테스트 매핑 생기면 후속.

머신 검증: `.harness/rules.json` 의 `single_active_cycle`(tweak 미점유 단서).

## 4. 세션 종료 워크플로 (반드시 5단계 + clean-state 7체크)

```
1. STATUS.md 갱신 — 이 세션에서 진행한 cycle 단계 추가
2. SESSION-LOG.md 에 이번 세션 항목 append (날짜·목표·완료·증거·위험·다음단계)
3. HANDOFF.md 갱신 — 다음 에이전트가 할 일 한 줄
4. 미해결 위험·차단 항목을 backlog.md 또는 HANDOFF.md 에 기록
5. 안전한 상태면 commit (.gitmessage 템플릿 따름)
```

### Clean-state 체크리스트 (commit 전 반드시)

- [ ] **cycle lock** — `IN_PROGRESS:` 가 (none) 또는 단일 NNN-<slug>(throw-cycle) 또는 단일 deepen-NNN (반복 강제 룰 3.4)
- [ ] `./init.sh` 가 여전히 작동 (표준 시작 경로)
- [ ] `./init.sh verify` 가 여전히 통과 (표준 검증 경로)
- [ ] STATUS.md 가 이번 세션 작업을 반영
- [ ] expanded/spec/goal 단계 산출물 중 미완성인 상태로 남은 게 없음
- [ ] 다음 세션이 manual 수정 없이 `./init.sh` 만으로 계속 가능
- [ ] **하네스 변경 통로 준수** — 이번 세션이 하네스(템플릿 레이어)를 건드렸다면 sfd-architect 검토를 거쳤고 commit message 에 변경/근거/영향이 기록됨 (룰 3.9)

체크 안 끝나면 commit 안 함 — 깨끗하게 정리부터.

## 5. 환경

- `.env.scenario` — 진전 신호 3종(`SCENARIO_GOAL_STUCK_RETRIES` / `NO_PROGRESS` / `MAX_ITERATIONS`) + E2E 명령. `source .env.scenario` 또는 direnv.
- `.gitmessage` — walking skeleton commit 규약. 등록됨.
- `.harness/rules.json` — 머신 판독 룰 (single_active_cycle, passing_requires_evidence, do_not_skip_verification, harness_change_via_architect 등). hook 으로 검증 가능.
- 하네스 변경은 `sfd-architect` 통로 (룰 3.9). 기록은 commit message — 별도 ADR 파일 없음.
- E2E 프레임워크: **{{E2E_FRAMEWORK}}** (실행: `./init.sh verify` 또는 직접 `{{E2E_TEST_CMD}}`)

## 6. 금지

- 자동 트리거 (모든 7 스킬 — throw/expand/spec/goal/review/deepen/tweak + init + sfd-architect)
- `scenarios/` 외부에 cycle 산출물 저장
- `--no-verify`, `git push --force`
- regression을 별도 게이트로 분리 (누적 풀에 흡수)
- 본인 사용 단계(review)를 Claude가 시뮬레이션
- routing 4번째 옵션 ("그냥 둬") 만들기
- 한 cycle 중 다른 cycle 동시 진행 (cycle lock — 룰 3.4)
- evidence 없이 review_status를 passed 로 표시 (룰: passing_requires_evidence)
- clean-state 체크 미통과 상태에서 commit
- **하네스(템플릿 레이어) 변경을 sfd-architect 검토 없이 즉흥 적용** (룰 3.9)
