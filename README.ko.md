# Scenario-First Development

*Read this in [English](README.md).*

### 적어둔 시나리오는 의도, 실제 경험은 증거 — 개발은 그 둘을 일치시키는 일이다.

AI 가 코드를 싸게 찍어내는 시대에, 진짜 어려운 건 *코드를 짜는 것*이 아니라 *"맞는 걸 만들었나"* 다. 코드는 다시 쓰이고 spec 은 deprecate 되지만, "이렇게 쓰고 싶다"는 사람의 생각만은 비교적 안 변한다. Scenario-First 는 그 한 줄을 정답(SoT)으로 두고 거기서 **거꾸로** 내려간다 — 시나리오에서 spec 을, spec 에서 코드를. 통과 여부는 사람의 "맞나?" 가 아니라 자동 게이트가 판정하고, 루프는 **네가 실제로 써봐야** 닫힌다 — "검증된 듯 쓸모없는" 결과물이 쌓이는 걸 막으려고.

이 레포는 **GitHub template** 이다. "Use this template" 으로 clone 하면 6 스킬 + 메타 에이전트가 이미 들어있다 — 외부 install·마켓플레이스·trust dialog 없음.

---

## 빠른 시작

```
1. GitHub 에서 "Use this template" → 새 레포 → clone
2. Claude Code 켜고 바로:  /scenario-first-throw "<첫 시나리오>"
```

이게 전부다. `throw`(1) → `expand`(2) → `spec`(3) 까지 그냥 흘러가면 된다.
**E2E 프레임워크는 처음 `/scenario-first-goal`(4) 돌릴 때 한 번만 물어본다** — 시작 시점에 정할 필요 없음.

> clone 직후엔 SFD 자신의 흔적(미치환 placeholder, 이 README)이 살짝 묻어있다. 거슬리면 `/scenario-first-init` 한 번으로 치운다 — 선택이고 멱등. (자세히는 아래 [clone 정리](#clone-정리) 참고.)

---

## 5단계 흐름

```
사용자 머리
     │ "이렇게 쓰고 싶다"
     ▼
┌────────────┐  Job Story (When / I want to / so I can)
│ 1. throw   │──────────► scenarios/throws/NNN-*.md
└────────────┘
     │
     ▼
┌────────────┐  USM backbone + walking skeleton
│ 2. expand  │  + Example Mapping (Rule/Example/Question/Story)
│            │  + 메타 인터뷰 → GWT 시나리오
└────────────┘──────────► scenarios/expanded/NNN-*.md
     │
     ▼
┌────────────┐  PRD + ARCHITECTURE + NONFUNC + OPS
│ 3. spec    │  (4슬롯 고정 템플릿)
└────────────┘──────────► scenarios/specs/NNN/{PRD,ARCH,NONFUNC,OPS}.md
     │
     ▼
┌────────────┐  GWT → E2E 자동 변환 → 게이트 실행
│ 4. goal    │  (누적 시나리오 풀 + LLM judge fallback)
│            │  (진전 신호 3종 stuck detection)
└────────────┘──────────► tests/e2e/scenario-NNN/, GOAL.md or STUCK.md
     │
     ▼
┌────────────┐  네가 직접 사용 + 체크리스트
│ 5. review  │  실패 시 5 Whys → (1)/(2)/(3) 라우팅
└────────────┘──────────► REVIEW.md
     │
     ├─ pass → 다음 backbone 슬라이스 (새 throw)
     └─ fail → (1) throw 갱신 / (2) spec 재실행 / (3) goal 재개
```

**단방향. 양방향 동기 없음. 한 번에 한 cycle (NNN).**

---

## 설계 철학 — 4 기둥

### 1. 정답은 코드도 spec도 아니라 "쓰는 모습" 이다

코드는 시간이 지나며 다시 쓰이고, spec 은 deprecate 된다. 하지만 *"이렇게 쓰고 싶다"* 는 마음은 비교적 안 변한다. 그래서 SoT(Source of Truth)를 그 **narrative** 에 두고, `scenarios/` 로 외화(externalize)한다.

왜 User Story 가 아니라 **Job Story** 인가:

| User Story 의 약점 | Job Story 가 메우는 법 |
|---|---|
| 페르소나 가정("개발자가…") — 그게 내가 아니면 정답이 틀어짐 | 페르소나 제거, **상황**으로만 |
| 사후 합리화 동기("효율을 위해") — 쓰는 순간의 진짜 동기 누락 | 동기를 그 순간으로 고정 |
| trigger 누락 — "언제 필요한가" 빠짐 | **When** 으로 trigger 명시 |

→ `When <상황>, I want to <동기>, so I can <결과>`

### 2. 분해를 즉흥으로 하지 않는다 — 매번 같은 절차

Job Story 에서 게이트까지 끌어내는 *방식*이 매번 다르면 결과 품질도 매번 다르다. 그래서 같은 4 도구를 같은 순서로 돌린다:

1. **USM** (Jeff Patton) — backbone(시간순 큰 단계) + walking skeleton(각 단계 최소 동작 1개)
2. **Example Mapping** (Matt Wynne) — 🟦 Rule / 🟩 Example / 🟥 Question / 🟨 Story 4색 카드
3. **메타 인터뷰** — Question 카드를 한 번에 1개씩 물어 모호함을 *결정 가능한 지점*까지 좁힘
4. **GWT** (Dan North) — Example 카드 → `Given/When/Then` 1:1 변환

결정성이 결과의 분산을 없앤다.

### 3. 게이트가 정답이다 — 사람이 "맞나?" 묻지 않는다

GWT 시나리오 자체가 정답의 정의다.

- **1차 게이트**: GWT → E2E 프레임워크(Playwright / Cypress / Cucumber / pytest-bdd / behave) 자동 변환
- **2차 fallback**: 자동 변환 불가한 것만 LLM judge (Then 을 그대로 인용해 판정)
- Manual 검증은 게이트에 안 둔다 — 그건 5번 review 의 일

게이트는 **이번 시나리오 + 누적된 모든 이전 시나리오**. regression 이 별도 게이트가 아니라 이 누적 풀에 흡수된다.

thrashing 은 **진전 신호 3종**으로 차단 — 비용($)이 아니라 진전 자체를 측정한다:
`STUCK_RETRIES`(같은 실패 hash 반복) · `NO_PROGRESS`(PASS 수 동결) · `MAX_ITERATIONS`(반복 상한).

### 4. 직접 안 쓰면 시스템이 죽는다

자동 게이트를 다 통과해도 *네가 안 쓰면* 가짜 정답이다 — "검증된 듯 쓸모없는 결과물"이 쌓이는 **주기적 자동 MVP 함정**.

5번 review 가 이 함정의 마지막 차단막이다:

- 체크리스트 = Job Story 의 `so I can…` + walking skeleton 한 줄 (네가 직접 쓴 것)
- **Claude 는 시뮬레이션 금지** — 네가 실제로 써볼 때까지 멈춤
- 실패하면 5 Whys 로 (1) 시나리오 / (2) spec / (3) 구현 중 하나로 라우팅
- "그냥 둬" 라는 4번째 옵션은 없다

이 단계를 건너뛰면 1~4 가 전부 무의미해진다.

---

## 언제 쓰고 · 언제 안 쓰나

**맞는 경우** — 본인이 직접 빌드·사용·평가하는 single-developer mode. "쓰는 모습"이 비교적 안정적인 도구·앱. cycle 을 반복하며 backbone 슬라이스를 채워가는 진화적 개발.

**안 맞는 경우**:

| 안 맞음 | 이유 |
|---|---|
| 매우 작은 1회용 스크립트 | 5단계가 오버헤드 |
| 사용자가 본인이 아닐 때 (외주·납품) | review 5단계의 "본인 사용" 강제가 깨짐 |
| 시나리오 자체를 빠르게 검증해야 할 때 | 한 건 시범 구현(spike) 등 별도 도구로 — 이 방법론은 *결정 후* 단계 |
| 팀 협업이 주가 될 때 | "본인 cycle lock" 이 협업에 마찰 — 변형 필요 |
| 비결정적 결과물(생성형 AI·ML) | GWT 의 deterministic Then 표현이 어려움 |

---

## 운영 layer — 5 스킬이 모르는 9 룰

5 스킬은 각자 자기 단계만 안다. cycle 전체·세션 간 상태·게이트 누적 정책·하네스 자기 진화는 모른다. `.harness/` 가 이 메타 layer 를 담당한다.

| # | 룰 | 위치 |
|---|---|---|
| 1 | **누적 게이트 통과 조건** — `review_status: passed` 인 NNN 만 누적 풀 | `REGRESSION-POLICY.md` |
| 2 | **rerun 백업 통일** — `.harness/.backups/<NNN>/<ISO8601>/` | (gitignore) |
| 3 | **STATUS.md 갱신 책임** — 5 스킬 각자 작업 끝에 한 줄 append | `STATUS.md` |
| 4 | **cycle lock** — 한 번에 한 NNN, `IN_PROGRESS` 단일 강제 | `STATUS.md` |
| 5 | **routing NNN 재사용** — (1)/(2)/(3) 은 같은 NNN, 신규 backbone 은 새 NNN | AGENTS.md 3.5 |
| 6 | **Story·보류 풀** — Example Mapping Story 카드 + ARCH 보류 결정 | `backlog.md` |
| 7 | **codex/cursor 트리거** — 슬래시 못 쓰는 에이전트용 `[SCENARIO:throw] …` | AGENTS.md 3.7 |
| 8 | **jargon 정책** — USM/Walking skeleton/GWT 등은 학습 완료 간주 | AGENTS.md 3.8 |
| 9 | **하네스 변경 통로** — 하네스를 고칠 땐 `/sfd-architect` 검토, 기록은 commit message | AGENTS.md 3.9 |

<details>
<summary>디렉터리 구조</summary>

```
my-project/
├── AGENTS.md            # 진입점 — 시작 6단계 + 운영 9룰 + 종료 5단계
├── CLAUDE.md            # AGENTS.md 가리킴
├── init.sh              # bootstrap / verify / start
├── .env.scenario        # 진전 신호 3종 + E2E 명령 (gitignore)
├── .gitmessage          # walking skeleton commit 규약
│
├── scenarios/                       ← SoT (시나리오 본문, 가시)
│   ├── throws/NNN-*.md
│   ├── expanded/NNN-*.md
│   └── specs/NNN/{PRD,ARCHITECTURE,NONFUNC,OPS}.md
│                        + GOAL.md|STUCK.md (goal 결과) · REVIEW.md (review 결과)
│
├── .harness/                        ← 운영 layer (메타, hidden)
│   ├── STATUS.md · SESSION-LOG.md · HANDOFF.md
│   ├── REGRESSION-POLICY.md · backlog.md · judge-rubric.md
│   ├── rules.json                   # 머신 판독 룰 (harness_change_via_architect 등)
│   ├── templates/{REVIEW.md, gitignore-additions}
│   └── .backups/<NNN>/<ts>/         # rerun 백업 (gitignore)
│
├── tests/e2e/scenario-NNN/          # goal 자동 생성
│
└── .claude/                         ← Claude Code project-local
    ├── skills/scenario-first-{init,throw,expand,spec,goal,review}/
    └── agents/sfd-architect.md      # 하네스 변경 검토 통로
```

**책임 분리**: `scenarios/` = SoT(사용자 사고의 단계별 본문, 매 단계 추가). `.harness/` = 운영 메타(상태·정책·로그).

</details>

<details id="clone-정리">
<summary>(선택) clone 정리 — <code>/scenario-first-init</code></summary>

clone 직후 새 레포엔 **그대로 쓸 자산**과 **SFD 색이 묻은 부분**이 섞여 있다:

| 그대로 쓰는 자산 | SFD 색 (정리 대상) |
|---|---|
| `.claude/skills/` 6 스킬 + `agents/sfd-architect` | `AGENTS.md` 의 `{{PROJECT_NAME}}` 등 placeholder |
| `.harness/` · 빈 `scenarios/`·`tests/e2e/` | `.env.scenario` 실파일 아직 없음 (`.example` 만) |
| `init.sh` · `.gitmessage` · `rules.json` | 이 `README.md` (= SFD 방법론 설명서, 네 README 아님) |

> SFD 가 이 템플릿을 진화시킨 기록은 **commit message** 에만 있다. `Use this template` 은 git 히스토리를 미상속하므로(clone 은 단일 fresh commit), 그 기록은 네 레포로 따라오지 않는다.

`/scenario-first-init` (인자 없음, 멱등) 이 오른쪽 칸을 치운다:
1. placeholder 치환 (`{{PROJECT_NAME}}`→레포명, E2E 값, 날짜)
2. `.env.scenario` 생성 + E2E 프레임워크 결정
3. SFD 방법론 `README.md` 제거 (네 README 는 따로)
4. git `commit.template` 등록

**안 돌려도 된다** — throw~spec 은 동작하고 E2E 는 goal 이 알아서 묻는다. 안 돌리면 미관 노이즈만 남을 뿐.

</details>

---

## 하네스를 바꾸려면 — sfd-architect

이 템플릿으로 개발하다가 *프로젝트 코드*가 아니라 **하네스 자체**(5 스킬·운영 룰·init 동작·`.env` 스키마)를 고치고 싶을 때가 있다. 그땐 직접 손대지 말고 안전 통로를 쓴다:

```
/sfd-architect "<바꾸고 싶은 것>"
```

`sfd-architect` 는 **검토만** 한다(코드 못 건드림) — 영향 grep + 보호 룰 점검 + 정당성 평가 후 검토 보고와 commit message 초안을 낸다. 적용은 네가 confirm 한 뒤 메인 에이전트가, **기록은 commit message** 에. (별도 ADR 파일 없음 — git history 가 권위이고 clone 으로 새지 않는다.)

---

## 참고한 사고들

| 출처 | 흡수한 것 |
|---|---|
| JTBD (Clayton Christensen) | "동기 + 결과" 가 narrative SoT |
| Job Story (Paul Adams, Alan Klement) | 페르소나 거부 + trigger 명시 |
| USM (Jeff Patton, 2014) | backbone + walking skeleton = MVP 슬라이스 |
| Example Mapping (Matt Wynne, 2015) | 4색 카드로 결정성 있는 분해 |
| BDD GWT (Dan North, 2006) | 자동 게이트 단위 표현 |
| Spec Kit | 결정성 보존 — 단 구조 강제 대신 **SoT 위치만 강제** |
| Toyota 5 Whys | review 실패 라우팅 |
| Walking Skeleton (Alistair Cockburn) | 게이트 단위 |
| Harness Engineering | 에이전트용 닫힌 루프 작업 시스템으로서의 `.harness/` |
