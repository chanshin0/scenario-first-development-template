# Scenario-First Development

> "코드도 spec도 SoT가 아니다. **사용자가 결과를 어떻게 쓰는지의 narrative** 가 SoT다."

5개의 Claude Code 스킬 + 1개의 init 스킬로 구성된 결정성 있는 개발 파이프라인. Job Story 부터 GWT 자동 게이트까지 단방향으로 흐르며, 매 cycle 같은 절차를 반복해서 즉흥적 분해의 비용을 0으로 만든다.

이 레포는 **방법론 설명서 + `scenario-first-init` 스킬** 을 담는다. 나머지 5 스킬 (`throw`/`expand`/`spec`/`goal`/`review`) 은 [cc-skills-repo](https://github.com/chanshin0/cc-skills-repo) 의 `skills/scenario-first-*/` 에 있다.

## 설치

```bash
# init 스킬을 Claude Code 스킬 디렉터리로 심볼릭 링크
ln -s "$PWD/scenario-first-init" ~/.claude/skills/scenario-first-init

# 5 스킬은 cc-skills-repo 에서 따로 (각자 동기화 방식대로)
```

---

## 한눈에 — 5단계 파이프라인

```
사용자 머리
     │ "이렇게 쓰고 싶다"
     ▼
┌────────────┐  Job Story (When/I want to/so I can)
│ 1. throw   │──────────► .scenarios/throws/NNN-*.md
└────────────┘
     │
     ▼
┌────────────┐  USM backbone + walking skeleton
│ 2. expand  │  + Example Mapping (Rules/Examples/Questions/Stories)
│            │  + 메타 인터뷰 → GWT 시나리오
└────────────┘──────────► .scenarios/expanded/NNN-*.md
     │
     ▼
┌────────────┐  PRD + ARCHITECTURE + NONFUNC + OPS
│ 3. spec    │  (4슬롯 고정 템플릿)
└────────────┘──────────► .scenarios/specs/NNN/{PRD,ARCH,NONFUNC,OPS}.md
     │
     ▼
┌────────────┐  GWT → E2E 자동 변환 → 게이트 실행
│ 4. goal    │  (누적 시나리오 풀 + LLM judge fallback)
│            │  (cost budget + stuck detection)
└────────────┘──────────► tests/e2e/scenario-NNN/, GOAL.md or STUCK.md
     │
     ▼
┌────────────┐  사용자 직접 사용 + 체크리스트
│ 5. review  │  실패 시 5 Whys → (1)/(2)/(3) 라우팅
└────────────┘──────────► REVIEW.md
     │
     ├─ pass → 다음 backbone 슬라이스 (새 throw)
     └─ fail → (1) throw 갱신 / (2) spec --rerun / (3) goal --resume
```

전 단계 단방향. 양방향 동기 안 함. 한 번에 한 cycle (NNN).

---

## 왜 이렇게 만들었나 — 설계 원칙 4개

### 1. SoT 는 사용자 narrative, 코드도 spec도 아니다

코드는 시간이 지나며 다시 작성된다. Spec은 deprecate 된다. 사용자가 "이렇게 쓰고 싶다" 는 마음만 시간 지나도 (어느 정도) 안정적이다. 그 narrative를 외화(externalize)해서 SoT 로 둔다.

User Story 거부 이유:
- 페르소나 가정 ("개발자가 ...") — 가정한 페르소나가 본인이 아닐 때 잘못된 정답
- 사후 합리화 동기 ("효율을 높이기 위해") — 사용 순간의 진짜 동기 누락
- trigger 누락 — "언제 이 동작이 필요한가" 빠짐

Job Story (`When <상황>, I want to <동기>, so I can <결과>`) 는 세 약점 다 해결.

출처: Paul Adams @ Intercom 2013, Alan Klement 정리, JTBD(Clayton Christensen) 운동의 실무 표현.

### 2. 즉흥 분해 금지 — 매번 같은 결정성 있는 절차

Job Story 를 받은 다음 어떻게 GWT 까지 끌어내느냐가 매번 달라지면 결과 품질도 매번 다르다. 그래서:

- **USM (Jeff Patton 2014)**: backbone (시간순 큰 단계) + walking skeleton (각 단계 최소 동작 1개)
- **Example Mapping (Matt Wynne 2015)**: 각 walking skeleton 항목에 🟦 Rule / 🟩 Example / 🟥 Question / 🟨 Story 4색 카드
- **메타 인터뷰**: Question 카드를 사용자에게 한 번에 1개씩 — 모호함을 본인이 결정 가능한 지점까지 좁히기
- **GWT (Dan North 2006)**: Example 카드 → `Given/When/Then` 1:1 변환

이 4개 도구를 매 cycle 같은 순서로 — 결정성.

### 3. 게이트 = 시나리오, 사람이 아니다

"맞나?" 를 사람이 묻지 않게 한다. GWT 시나리오 자체가 정답 정의:

- 1차 게이트: GWT → E2E 프레임워크 (Playwright/Cypress/Cucumber/pytest-bdd/behave) 자동 변환
- 2차 fallback: 자동 변환 불가 케이스만 LLM judge (Then 그대로 인용해서 판정)
- Manual 검증은 4단계 게이트에 안 둠 — 5번 review 의 일

게이트는 **이번 시나리오 + 누적된 모든 이전 시나리오**. Regression 풀이 별도 게이트가 아니라 이 누적 풀에 흡수.

cost budget (`SCENARIO_GOAL_BUDGET=5` USD default) + stuck detection (3회 연속 실패 또는 10회 누적 iteration) 으로 thrashing 차단.

### 4. 본인이 직접 사용하지 않으면 시스템이 죽는다

자동 게이트 다 통과해도 본인이 안 쓰면 가짜 정답이다. "주기적 자동 MVP" 함정 — 검증된 듯한 쓸모없는 결과물이 쌓이는 패턴.

5번 review 가 이 함정의 마지막 차단:
- 체크리스트는 Job Story 의 `so I can ...` + walking skeleton 한 줄 (스스로 작성한 것)
- **Claude 는 시뮬레이션 금지** — 사용자가 돌아올 때까지 멈춤
- 실패 시 5 Whys 로 (1) 시나리오 / (2) Spec / (3) 구현 셋 중 하나로 라우팅
- 4번째 옵션 ("그냥 둬") 금지

이 단계 건너뛰면 1~4번 다 무의미해진다.

---

## 운영 layer — 5 스킬로는 부족한 8개 룰

5 스킬은 각자 자기 단계만 안다. cycle 전체·세션 간 상태·게이트 누적 정책은 모른다. `scenario-first-init` 스킬이 다음 운영 layer 를 한 번에 깔아 준다.

| # | 룰 | 산출물 |
|---|---|---|
| 1 | **누적 게이트 통과 조건** — `review_status: passed` 인 NNN의 GWT만 누적 풀 | `.scenarios/REGRESSION-POLICY.md` |
| 2 | **rerun 백업 통일** — `.scenarios/.backups/<NNN>/<ISO8601>/` | (gitignore 추가) |
| 3 | **STATUS.md 갱신 책임** — 5 스킬 각자 작업 끝에 한 줄 append | `.scenarios/STATUS.md` |
| 4 | **cycle lock** — 한 번에 한 NNN, IN_PROGRESS 라인 단일 강제 | `.scenarios/STATUS.md` |
| 5 | **routing의 NNN 재사용** — review (1)/(2)/(3) 라우팅은 같은 NNN, 신규 backbone 은 새 NNN | AGENTS.md 2.5 |
| 6 | **Story·보류 풀** — Example Mapping Story 카드 + ARCH 보류 결정 | `.scenarios/backlog.md` (append-only) |
| 7 | **codex/cursor 트리거 규약** — 슬래시 못 쓰는 에이전트용 `[SCENARIO:throw] <text>` | AGENTS.md 2.7 |
| 8 | **jargon 정책** — USM/Backbone/Walking skeleton/GWT 등은 학습 완료 간주 | AGENTS.md 2.8 |

자세한 정책 본문은 `scenario-first-init` 스킬의 [templates/](https://github.com/chanshin0/cc-skills-repo/tree/main/skills/scenario-first-init/templates) 참조.

---

## 디렉터리 구조 (init 가 깔아 주는 v2)

```
my-project/
├── AGENTS.md                       # 진입점 — 5 스킬 사용 + 운영 8룰
├── CLAUDE.md                       # AGENTS.md 가리킴
├── init.sh                         # E2E 의존성 + env 부트스트랩
├── .env.scenario                   # SCENARIO_GOAL_BUDGET 등 (gitignore)
├── .gitmessage                     # walking skeleton commit 규약
├── .gitignore                      # .scenarios/.backups/, .env.scenario 등
├── .scenarios/
│   ├── STATUS.md                   # IN_PROGRESS + WAITING_ON_USER + cycle 로그
│   ├── HANDOFF.md                  # 세션 인계
│   ├── REGRESSION-POLICY.md        # 누적 풀 정책
│   ├── backlog.md                  # Story + 보류 결정 풀
│   ├── judge-rubric.md             # LLM judge 공통 rubric
│   ├── .backups/<NNN>/<ts>/        # rerun 백업 (gitignore)
│   ├── throws/NNN-*.md
│   ├── expanded/NNN-*.md
│   └── specs/NNN/
│       ├── PRD.md
│       ├── ARCHITECTURE.md
│       ├── NONFUNC.md
│       ├── OPS.md
│       ├── GOAL.md or STUCK.md     # goal 결과
│       └── REVIEW.md               # review 결과
└── tests/e2e/scenario-NNN/         # goal 자동 생성
```

---

## 트레이드오프 — 이 방법론이 안 맞는 경우

| 안 맞음 | 이유 |
|---|---|
| 매우 작은 1회용 스크립트 | 5단계가 오버헤드 |
| 사용자가 본인이 아닐 때 (외주·납품) | review 4단계의 "본인 사용" 강제 깨짐 |
| 시나리오 자체를 빠르게 검증해야 할 때 | spike 등 별도 도구로 (이 방법론은 결정 후 단계) |
| 팀 협업이 주가 될 때 | "본인 cycle lock" 이 협업에 마찰 — 변형 필요 |
| 비결정적 결과물(생성형 AI, ML 모델) | GWT 의 deterministic Then 표현 어려움 |

맞는 경우:
- 본인 사용 도구·앱 개발
- "쓰는 모습" 이 비교적 안정적인 도메인
- Cycle 반복으로 backbone 슬라이스 채워가는 진화적 개발
- 본인이 직접 빌드 + 직접 사용 + 직접 평가하는 single-developer mode

---

## 참고한 사고들

| 출처 | 흡수한 것 |
|---|---|
| JTBD (Clayton Christensen) | "동기 + 결과" 가 narrative SoT |
| Job Story (Paul Adams, Alan Klement) | 페르소나 거부 + trigger 명시 |
| USM (Jeff Patton, 2014) | backbone + walking skeleton = MVP 슬라이스 |
| Example Mapping (Matt Wynne, 2015) | 4색 카드로 결정성 있는 시나리오 분해 |
| BDD GWT (Dan North, 2006) | 자동 게이트 단위 표현 |
| Spec Kit | 결정성 보존 룰 — 단 구조 강제 대신 **SoT 위치만 강제** (Spec Kit 과 차이) |
| Toyota 5 Whys | review 실패 라우팅 |
| Walking Skeleton (Alistair Cockburn) | 4단계 게이트 단위 |

---

## 다음

1. cc-skills-repo 의 5 스킬 + `scenario-first-init` 설치
2. 새 프로젝트에서 `/scenario-first-init`
3. AGENTS.md 훑기
4. `/scenario-first-throw "<첫 시나리오>"`

## 변경 이력

- v2 (현재) — 운영 8룰 + init 스킬 추가. 5 스킬은 그대로.
- v1 — 5 스킬만. 운영 layer 없음.
