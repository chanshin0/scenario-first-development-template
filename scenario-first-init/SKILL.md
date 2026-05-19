---
name: scenario-first-init
description: 시나리오-First 개발 0단계. 새 프로젝트(또는 기존 레포)에 5 스킬(throw/expand/spec/goal/review)이 안정적으로 동작할 하네스 v2 구조를 스캐폴딩한다. AGENTS.md/CLAUDE.md, init.sh, .env.scenario, .gitmessage, .gitignore 보강, `.scenarios/` 디렉터리 + STATUS/HANDOFF/REGRESSION-POLICY/backlog/judge-rubric, E2E 프레임워크 사전 결정·설치까지. 5 스킬의 운영 디테일(누적 게이트 정책, rerun 백업, cycle lock, NNN 재사용 룰)을 한 입구에 박는다.
---

# scenario-first-init

## 목적

5 스킬 (`throw` → `expand` → `spec` → `goal` → `review`) 이 실제 운영에서 깨지지 않도록, **시작 시점에 운영 layer를 한 번에 깔아 둔다**. 5 스킬은 각자 자기 단계만 알고 cycle 전체·세션 간 상태·게이트 누적 정책을 모른다 — init 가 그 빈칸을 채운다.

원리:
- 5 스킬의 정합성 보장에 필요한 운영 산출물을 **모두 templates/에서 복사** (즉흥 생성 금지 — 결정성 보존)
- 한 번만 실행 (idempotent하게 — 기존 파일이 있으면 건너뜀, `--force` 시 백업 후 덮어쓰기)
- E2E 프레임워크는 `goal` 실행 시점이 아니라 **여기서 사전 결정** (cycle 중간 멈춤 방지)

## 트리거

수동 호출만:

| 인자 | 동작 |
|---|---|
| `/scenario-first-init` | 현재 cwd에 v2 하네스 스캐폴딩 (기존 파일 보존) |
| `/scenario-first-init --force` | 기존 파일 백업 후 덮어쓰기 (`.scenarios/.backups/init/<ISO8601>/`) |
| `/scenario-first-init --dry-run` | 생성될 파일 목록과 변경 사항만 출력 |
| `/scenario-first-init --check` | 현재 레포의 하네스 상태 진단 (어떤 운영 산출물이 빠졌는지) |

자동 트리거 금지. 새 프로젝트 시작 시 본인이 1회.

## 사전 점검

```bash
test -d .git || echo "WARN: .git 없음 — git init 먼저 권장"
test -f package.json -o -f pyproject.toml -o -f Cargo.toml || echo "WARN: 프로젝트 매니페스트 없음 — 언어 결정 모호"
test -d .scenarios && echo "INFO: .scenarios 이미 존재 — 보존 모드"
```

## Workflow

### 1. 환경 진단

현재 cwd에서:

```bash
# 언어·매니페스트 감지
ls package.json pyproject.toml Cargo.toml go.mod 2>/dev/null

# E2E 프레임워크 후보 감지
grep -E "(playwright|cypress|cucumber|pytest-bdd|behave)" package.json pyproject.toml 2>/dev/null

# 기존 하네스 흔적
ls .scenarios/ AGENTS.md CLAUDE.md init.sh .env.scenario .gitmessage 2>/dev/null
```

결과를 사용자에게 한 표로 보고:

```
감지 결과:
- 언어:        TypeScript (package.json)
- E2E:         없음 — 선택 필요
- 기존 하네스: 없음
- git:         초기화됨
```

### 2. E2E 프레임워크 결정 (1회)

자동 감지된 게 있으면 그것 채택. 없으면 사용자에게 1회 묻기 (multiSelect 아님, 한 개):

| 옵션 | 적합 |
|---|---|
| Playwright | TS/JS 웹 앱 default |
| Cypress | TS/JS, 비주얼 디버깅 선호 |
| Cucumber.js | Gherkin 그대로 실행 |
| pytest-bdd | Python |
| behave | Python, 가장 BDD 친화적 |
| (수동) | 나중에 결정 — `.env.scenario`에 TBD 기록 |

결정 시 사용자에게 "지금 설치할까요?" 확인. 동의하면 매니페스트에 추가 + 설치 명령 실행. 거부하면 init.sh 안에 설치 명령만 남기고 실행 안 함.

### 3. 디렉터리 생성

```
.scenarios/
├── STATUS.md
├── HANDOFF.md
├── SESSION-LOG.md          # 세션 단위 로그 (cycle 단위 STATUS와 차원 분리)
├── REGRESSION-POLICY.md
├── backlog.md
├── judge-rubric.md
├── rules.json              # 머신 판독 룰
├── .backups/               # rerun 백업 통일 위치 (gitignore)
├── throws/
├── expanded/
└── specs/
    ├── _template/REVIEW.md # review 5단계가 NNN별로 복사해 채움
    └── NNN/                # PRD/ARCH/NONFUNC/OPS/GOAL/STUCK/REVIEW.md
tests/e2e/                  # goal이 scenario-NNN/ 으로 채움
```

빈 디렉터리는 `.gitkeep`으로 commit 가능하게.

### 4. 운영 산출물 파일 복사

`templates/` 의 파일들을 cwd로 복사. **기존 파일이 있으면 건너뛰고 사용자에게 한 줄 보고** (`--force`면 백업 후 덮어쓰기):

| 템플릿 | 대상 | 내용 |
|---|---|---|
| `AGENTS.md` | `./AGENTS.md` | 5 스킬 사용 순서 + 운영 8룰 |
| `CLAUDE.md` | `./CLAUDE.md` | AGENTS.md 가리키는 한 줄 (또는 동일 사본) |
| `init.sh` | `./init.sh` | E2E 의존성·env 부트스트랩 |
| `env.scenario` | `./.env.scenario` | `SCENARIO_GOAL_BUDGET` 등 |
| `gitmessage` | `./.gitmessage` | walking skeleton commit 규약 |
| `gitignore-additions` | `./.gitignore` (append) | `.scenarios/.backups/`, `.env.scenario` 등 |
| `STATUS.md` | `.scenarios/STATUS.md` | IN_PROGRESS + WAITING_ON_USER + cycle lock 강조 |
| `HANDOFF.md` | `.scenarios/HANDOFF.md` | 세션 인계 |
| `SESSION-LOG.md` | `.scenarios/SESSION-LOG.md` | 세션 단위 로그 (cycle 단위 STATUS.md와 차원 분리) |
| `REGRESSION-POLICY.md` | `.scenarios/REGRESSION-POLICY.md` | 누적 풀 통과 조건 |
| `backlog.md` | `.scenarios/backlog.md` | Story 카드 + 보류 결정 풀 |
| `judge-rubric.md` | `.scenarios/judge-rubric.md` | LLM judge 공통 rubric |
| `REVIEW.md` | `.scenarios/specs/_template/REVIEW.md` | review 산출물 템플릿 (6범주 평가 + evidence 슬롯). review 5단계가 NNN별로 복사해 사용. |
| `rules.json` | `.scenarios/rules.json` | 머신 판독 룰 (single_active_cycle, passing_requires_evidence 등) |

복사 후 placeholder 치환:
- `{{PROJECT_NAME}}` → cwd basename
- `{{E2E_FRAMEWORK}}` → 2단계 결정값
- `{{E2E_TEST_CMD}}` → 프레임워크별 실행 명령
- `{{CREATED_AT}}` → ISO8601

### 5. git 후속 조치

```bash
# .gitmessage 등록
git config --local commit.template .gitmessage

# .env.scenario는 gitignore 됐는지 확인
grep -q "^.env.scenario$" .gitignore || echo ".env.scenario" >> .gitignore

# 첫 commit 제안 (실행은 안 함)
echo "다음 단계: git add . && git commit -m 'chore: scenario-first harness v2 init'"
```

### 6. 진단 (--check 단독 모드 시)

스캐폴딩 없이 현재 상태만 보고:

```
하네스 진단 (scenario-first v2)
─────────────────────────────────
✓ AGENTS.md
✓ .scenarios/STATUS.md
✗ .scenarios/REGRESSION-POLICY.md  ← 누락 (누적 게이트 정책 미정)
✗ .gitmessage                      ← 누락 (commit 규약 미정)
⚠ .scenarios/STATUS.md             ← IN_PROGRESS 없음 (cycle lock 미적용)

권장: /scenario-first-init  (누락분만 채움, 기존 보존)
```

### 7. 응답

성공:
```
✓ scenario-first v2 하네스 스캐폴딩 완료

생성:
- AGENTS.md, CLAUDE.md, init.sh
- .env.scenario, .gitmessage
- .scenarios/{STATUS,HANDOFF,REGRESSION-POLICY,backlog,judge-rubric}.md
- .scenarios/{throws,expanded,specs}/, .scenarios/.backups/
- tests/e2e/

E2E 프레임워크: Playwright (설치 완료)
git 템플릿: 등록됨

다음 단계:
  1. AGENTS.md 한 번 훑어 운영 룰 확인
  2. .env.scenario의 SCENARIO_GOAL_BUDGET 조정 (기본 $5)
  3. git add . && git commit -m 'chore: scenario-first harness v2 init'
  4. /scenario-first-throw "첫 시나리오"
```

## 산출

- 위 디렉터리·파일 일체
- 갱신된 `.gitignore`
- `git config --local commit.template` 등록
- 응답 요약

## 다음 단계

- `scenario-first-throw` — 첫 Job Story 캡처

## 금지 사항

- `templates/` 외부에서 즉흥적으로 파일 내용 생성 (결정성 깎임)
- 기존 파일을 묵시적으로 덮어쓰기 (`--force` 없이는 절대)
- E2E 프레임워크 결정을 사용자 확인 없이 임의 채택
- `.env.scenario`를 git에 commit
- `.scenarios/.backups/`를 git에 commit
- AGENTS.md 운영 8룰을 부분만 깔기 — 전부 한 번에
