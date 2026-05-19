# AGENTS.md — {{PROJECT_NAME}}

이 레포는 **시나리오-First 개발 파이프라인 v2** 로 운영된다. 모든 에이전트(Claude Code / codex / cursor / 그 외) 는 작업 시작 전 이 문서를 읽고, 아래 운영 룰을 지킨다.

## 0. 한눈에

```
사용자 머리 ──► throw ──► expand ──► spec ──► goal ──► review ──► 다음 backbone
                  ↑                                                  │
                  └──── (1) 시나리오 / (2) Spec / (3) 구현 ──────────┘
                          5 Whys 라우팅 (실패 시)
```

- SoT는 코드도 spec도 아니고 **`.scenarios/throws/NNN-*.md`의 Job Story**.
- 단방향. 양방향 동기 안 함.
- 한 번에 한 cycle (NNN).
- 자동 트리거 금지 — 모든 스킬은 사용자 호출 시에만.

## 1. 5 스킬 + init

| 단계 | 스킬 | 산출 |
|---|---|---|
| 0 | `/scenario-first-init` | 이 파일 + `.scenarios/` 구조 + env + git 후크 |
| 1 | `/scenario-first-throw "<자유 텍스트>"` | `.scenarios/throws/NNN-*.md` |
| 2 | `/scenario-first-expand <NNN>` | `.scenarios/expanded/NNN-*.md` (USM + Example Mapping + GWT) |
| 3 | `/scenario-first-spec <NNN>` | `.scenarios/specs/NNN/{PRD,ARCHITECTURE,NONFUNC,OPS}.md` |
| 4 | `/scenario-first-goal <NNN>` | `tests/e2e/scenario-NNN/`, `.scenarios/specs/NNN/{GOAL,STUCK}.md`, commits |
| 5 | `/scenario-first-review <NNN>` | `.scenarios/specs/NNN/REVIEW.md` |

## 2. 운영 8룰 (반드시)

### 2.1 누적 게이트 통과 조건
`goal` 4단계의 자동 게이트는 NNN 시나리오뿐 아니라 `.scenarios/expanded/*` 의 GWT 시나리오 전체를 누적해서 돌린다. 누적 풀에 포함되는 조건은:

> **`review_status: passed` 인 NNN만 누적 풀에 포함.**

- `expanded` 단계까지 갔지만 review를 통과하지 못한 NNN의 GWT는 누적에서 **제외**.
- 폐기된 NNN(review에서 (1) 시나리오 오류로 throw 갱신·삭제된 경우)은 누적에서 영구 제외.
- 자세한 정책은 `.scenarios/REGRESSION-POLICY.md`.

### 2.2 rerun 백업 경로 통일
모든 `--rerun`·`--force` 동작은 백업을 다음 경로에 만든다:

```
.scenarios/.backups/<NNN>/<ISO8601>/<원본파일경로>
```

이 경로는 gitignore. 추적은 STATUS.md `BACKUPS:` 섹션에 한 줄.

### 2.3 STATUS.md 갱신 책임
5 스킬은 각자 작업 끝에 `.scenarios/STATUS.md` 를 한 줄 갱신한다. 갱신 의무는 스킬 본문이 아니라 **이 AGENTS.md가 강제** — 스킬을 실행한 에이전트가 책임.

갱신 형식:
```
- <ISO8601> NNN-XXX [throw|expand|spec|goal|review] <한 줄 요약>
```

### 2.4 cycle lock (한 번에 한 NNN)
`STATUS.md` 상단의 `IN_PROGRESS:` 라인은 단일 NNN만. 이미 차 있는데 새 NNN throw 시도하면 에이전트는 **사전 점검에서 멈춤**.

해제 조건:
- 그 NNN이 `review_status: passed` 또는
- 사용자가 명시적으로 폐기 (`STATUS.md`에서 라인 제거)

### 2.5 routing의 NNN 재사용
`review` 가 5 Whys 후 라우팅할 때:

| 라우팅 | NNN |
|---|---|
| (1) 시나리오 오류 → throw 갱신 | **같은 NNN 백업 후 덮어쓰기** |
| (2) Spec 누락 → spec --rerun | 같은 NNN |
| (3) 구현 오류 → goal --resume | 같은 NNN |
| (신규 backbone 슬라이스) | **새 NNN** (현재 max + 1) |

throw 본문의 "기존 throws 카운트해서 다음 번호" 룰은 신규 throw에만 적용.

### 2.6 Story·보류 풀
`.scenarios/backlog.md` 는 다음을 모은다 (append-only):
- `expand`의 Example Mapping에서 🟨 Story 카드로 이월된 항목
- `spec`의 ARCH "보류" 슬롯의 결정

다음 cycle의 throw 후보. 잊혀짐 방지.

### 2.7 codex / cursor 트리거 규약
슬래시 못 쓰는 에이전트는 사용자 메시지 본문에서 인라인 트리거 인식:

```
[SCENARIO:throw] <자유 텍스트>
[SCENARIO:expand] NNN
[SCENARIO:spec] NNN
[SCENARIO:goal] NNN
[SCENARIO:review] NNN
```

이걸 보면 해당 스킬과 동일하게 동작 (스킬 본문 그대로 따름).

### 2.8 jargon 정책
5 스킬이 사용하는 다음 용어는 **학습 완료로 간주** — 산출물 본문에 그대로 사용:

- Job Story / GWT (Given-When-Then) / Gherkin
- User Story Mapping (USM) / Backbone / Walking skeleton
- Example Mapping / Rule / Example / Question / Story 카드
- 5 Whys / regression / E2E

이 외의 jargon은 사용자의 `~/.claude/CLAUDE.md` "본인 언어 + (괄호 jargon)" 패턴 따름.

## 3. 환경

- `.env.scenario` — `SCENARIO_GOAL_BUDGET` 등. `source .env.scenario` 또는 direnv.
- `.gitmessage` — walking skeleton commit 규약. `git config --local commit.template .gitmessage` 로 등록됨.
- E2E 프레임워크: **{{E2E_FRAMEWORK}}** (실행: `{{E2E_TEST_CMD}}`)

## 4. 금지

- 자동 트리거 (모든 5 스킬 + init)
- `.scenarios/` 외부에 cycle 산출물 저장
- `--no-verify`, `git push --force`
- regression을 별도 게이트로 분리 (누적 풀에 흡수)
- 본인 사용 단계(review)를 Claude가 시뮬레이션
- routing 4번째 옵션 ("그냥 둬") 만들기
- 한 cycle 중 다른 cycle 동시 진행 (cycle lock)

## 5. 다음 단계

1. `.env.scenario` 의 `SCENARIO_GOAL_BUDGET` 조정
2. `.scenarios/STATUS.md` 한 번 훑기
3. `/scenario-first-throw "<첫 시나리오>"`
