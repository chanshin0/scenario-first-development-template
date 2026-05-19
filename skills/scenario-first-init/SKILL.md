---
name: scenario-first-init
description: 시나리오-First 개발 0단계. 빈 cwd (또는 기존 레포)에 하네스 layer + 5 스킬용 SoT 디렉터리를 스캐폴딩한다. scenario-first-development 레포의 시드 파일들(루트의 AGENTS.md/CLAUDE.md/init.sh 등 + .harness/ 운영 layer + scenarios/ 빈 SoT)을 cwd로 복사하며, 실제 cycle 산출물·.git·skills·README 는 제외. E2E 프레임워크 사전 결정·설치까지. 단방향 파이프라인의 0단계 도구.
---

# scenario-first-init

## 목적

`cp -r scenario-first-development my-idea` 의 자동화 + 안전판. 사용자가 빈 cwd 에서 호출하면 시드 파일만 골라서 복사 (`.git`, `skills/`, `README.md`, 실제 cycle 산출물 제외). 멱등 (기존 파일은 보존, `--force` 시 백업 후 덮어쓰기).

원리:
- 시드는 `scenario-first-development` 레포 자체에 활성 적용된 상태로 살아있음 → init 는 **whitelist 기반 복사** 만 (즉흥 생성 금지)
- E2E 프레임워크는 `goal` 실행 시점이 아니라 **여기서 사전 결정** (cycle 중간 멈춤 방지)
- 시드 출처는 `$SCENARIO_FIRST_HOME` 환경변수 (기본: `~/Projects/scenario-first-development`)

## 트리거

수동 호출만:

| 인자 | 동작 |
|---|---|
| `/scenario-first-init` | 현재 cwd 에 시드 복사 (기존 파일 보존) |
| `/scenario-first-init --force` | 기존 파일 백업 후 덮어쓰기 (`.harness/.backups/init/<ISO8601>/`) |
| `/scenario-first-init --dry-run` | 복사 대상·치환 사항만 출력 |
| `/scenario-first-init --check` | 현재 레포의 하네스 상태 진단 (어떤 시드가 빠졌는지) |

자동 트리거 금지. 새 프로젝트 시작 시 본인이 1회.

## 사전 점검

```bash
# .git 없으면 자동 init (커밋 가능한 상태로 진입 — `.gitmessage` 등록·atomic commit 의무를 위한 전제)
if [ ! -d .git ]; then
  echo "INFO: .git 없음 — git init 자동 실행"
  git init -q
fi
test -f package.json -o -f pyproject.toml -o -f Cargo.toml || echo "WARN: 프로젝트 매니페스트 없음 — 언어 결정 모호"
test -d .harness && echo "INFO: .harness 이미 존재 — 보존 모드"
SFH="${SCENARIO_FIRST_HOME:-$HOME/Projects/scenario-first-development}"
test -d "$SFH" || { echo "ERROR: 시드 레포 없음 ($SFH). SCENARIO_FIRST_HOME 설정 또는 clone 필요"; exit 1; }
```

## Workflow

### 1. 환경 진단

```bash
# 언어·매니페스트 감지
ls package.json pyproject.toml Cargo.toml go.mod 2>/dev/null

# E2E 프레임워크 후보 감지
grep -E "(playwright|cypress|cucumber|pytest-bdd|behave)" package.json pyproject.toml 2>/dev/null

# 기존 하네스 흔적
ls .harness/ scenarios/ AGENTS.md CLAUDE.md init.sh .env.scenario .gitmessage 2>/dev/null
```

사용자에게 한 표로 보고:

```
감지 결과:
- 언어:        TypeScript (package.json)
- E2E:         없음 — 선택 필요
- 기존 하네스: 없음
- git:         초기화됨
- 시드 출처:   ~/Projects/scenario-first-development
```

### 2. E2E 프레임워크 결정 (1회)

자동 감지된 게 있으면 그것 채택. 없으면 사용자에게 1회 묻기 (한 개):

| 옵션 | 적합 |
|---|---|
| Playwright | TS/JS 웹 앱 default |
| Cypress | TS/JS, 비주얼 디버깅 선호 |
| Cucumber.js | Gherkin 그대로 실행 |
| pytest-bdd | Python |
| behave | Python, 가장 BDD 친화적 |
| (수동) | 나중에 결정 — `.env.scenario`에 TBD 기록 |

결정 시 "지금 설치할까요?" 확인. 동의하면 매니페스트에 추가 + 설치 실행. 거부하면 init.sh 안에 설치 명령만 남기고 실행 안 함.

#### 패키지 매니저 선택 (JS/TS 진영)

`command -v pnpm` 으로 우선 점검. 있으면 **pnpm 사용 (default)** — 속도·디스크 효율·strict 의존성 해결로 npm 보다 우선.

| 매니페스트 상황 | 명령 |
|---|---|
| `pnpm-lock.yaml` 있음 또는 pnpm 설치됨 | `pnpm add -D <pkg>` |
| `yarn.lock` 있음 | `yarn add -D <pkg>` |
| 위 둘 다 없고 npm 만 가능 | `npm install --save-dev <pkg>` |

설치 후 lockfile 도 함께 commit 대상에 포함. `.gitignore` 의 `node_modules/` 는 시드에 이미 있음.

Python 진영(`pytest-bdd`, `behave`): `uv add` 또는 `pip install` (가상환경 권장).

### 3. 시드 whitelist 복사

`$SCENARIO_FIRST_HOME` 의 시드 파일/디렉터리를 cwd 로 복사. **기존 파일 보존** (`--force` 시 백업 후 덮어쓰기).

#### 복사 대상 (whitelist)

| 출처 (`$SCENARIO_FIRST_HOME/`) | 대상 (cwd) | 내용 |
|---|---|---|
| `AGENTS.md` | `./AGENTS.md` | 5 스킬 사용 + 운영 8룰 + 시작/종료 워크플로 |
| `CLAUDE.md` | `./CLAUDE.md` | AGENTS.md 가리킴 |
| `init.sh` | `./init.sh` | bootstrap / verify / start |
| `.env.scenario.example` | `./.env.scenario` | `SCENARIO_GOAL_BUDGET` 등 (사본은 `.env.scenario`, 시드는 `.example`) |
| `.gitmessage` | `./.gitmessage` | walking skeleton commit 규약 |
| `.harness/STATUS.md` | `.harness/STATUS.md` | cycle 진행 상태 + cycle lock |
| `.harness/SESSION-LOG.md` | `.harness/SESSION-LOG.md` | 세션 단위 로그 |
| `.harness/HANDOFF.md` | `.harness/HANDOFF.md` | 세션 인계 |
| `.harness/REGRESSION-POLICY.md` | `.harness/REGRESSION-POLICY.md` | 누적 풀 통과 조건 |
| `.harness/backlog.md` | `.harness/backlog.md` | Story · 보류 풀 |
| `.harness/judge-rubric.md` | `.harness/judge-rubric.md` | LLM judge fallback rubric |
| `.harness/rules.json` | `.harness/rules.json` | 머신 판독 룰 |
| `.harness/templates/REVIEW.md` | `.harness/templates/REVIEW.md` | review 5단계 NNN별 복사용 |
| `.harness/templates/gitignore-additions` | (append to `.gitignore`) | 하네스 관련 ignore 항목 |
| `.claude/settings.json` | `.claude/settings.json` | Plugify 마켓플레이스 + scenario-first 플러그인 자동 등록 (trust dialog 후 Claude Code 가 자동 install) |
| `scenarios/throws/.gitkeep` | `scenarios/throws/.gitkeep` | (디렉터리 시드) |
| `scenarios/expanded/.gitkeep` | `scenarios/expanded/.gitkeep` | (디렉터리 시드) |
| `scenarios/specs/.gitkeep` | `scenarios/specs/.gitkeep` | (디렉터리 시드) |
| `tests/e2e/.gitkeep` | `tests/e2e/.gitkeep` | (디렉터리 시드) |

#### 제외 (절대 복사 안 함)

- `$SCENARIO_FIRST_HOME/.git/` — 새 cwd 의 git 과 충돌
- `$SCENARIO_FIRST_HOME/skills/` — 스킬은 `~/.claude/skills/` 에 별도 symlink
- `$SCENARIO_FIRST_HOME/README.md` — 방법론 설명서는 시드 아님
- `$SCENARIO_FIRST_HOME/scenarios/throws/NNN-*.md` 등 — 시드 레포의 실제 cycle 산출물
- `$SCENARIO_FIRST_HOME/scenarios/expanded/NNN-*.md`
- `$SCENARIO_FIRST_HOME/scenarios/specs/NNN/` (NNN ≠ _template 인 모든 디렉터리)
- `$SCENARIO_FIRST_HOME/tests/e2e/scenario-*/` — 시드 레포의 실제 E2E
- `$SCENARIO_FIRST_HOME/.harness/.backups/` — 시드 레포의 백업
- `$SCENARIO_FIRST_HOME/.env.scenario` — 시드 레포의 실제 env

#### 복사 후 placeholder 치환

- `{{PROJECT_NAME}}` → cwd basename
- `{{E2E_FRAMEWORK}}` → 2단계 결정값
- `{{E2E_TEST_CMD}}` → 프레임워크별 실행 명령
- `{{CREATED_AT}}` → ISO8601

### 4. git 후속 조치

```bash
# .gitmessage 등록
git config --local commit.template .gitmessage

# .env.scenario gitignore 확인
grep -q "^.env.scenario$" .gitignore || echo ".env.scenario" >> .gitignore

# .harness/.backups/ gitignore 확인
grep -q "^.harness/.backups/$" .gitignore || echo ".harness/.backups/" >> .gitignore

# 첫 commit 안내 (실행 안 함)
echo "다음: git add . && git commit -m 'chore: scenario-first 하네스 init'"
```

### 5. 진단 (--check 단독 모드)

스캐폴딩 없이 현재 상태만 보고:

```
하네스 진단 (scenario-first)
─────────────────────────────────
✓ AGENTS.md
✓ .harness/STATUS.md
✗ .harness/REGRESSION-POLICY.md  ← 누락
✗ .gitmessage                    ← 누락 (commit 규약 미정)
⚠ .harness/STATUS.md             ← IN_PROGRESS 없음 (cycle lock 미적용)
✓ scenarios/{throws,expanded,specs}/
✓ tests/e2e/

권장: /scenario-first-init  (누락분만 채움, 기존 보존)
```

### 6. 응답

성공:
```
✓ scenario-first 하네스 스캐폴딩 완료

생성:
- AGENTS.md, CLAUDE.md, init.sh, .env.scenario, .gitmessage
- .harness/{STATUS,SESSION-LOG,HANDOFF,REGRESSION-POLICY,backlog,judge-rubric}.md
- .harness/rules.json, .harness/templates/REVIEW.md
- .claude/settings.json (Plugify 마켓플레이스 + scenario-first 플러그인 자동 등록)
- scenarios/{throws,expanded,specs}/, tests/e2e/

E2E 프레임워크: Playwright (설치 완료)
git 템플릿: 등록됨

다음 단계:
  1. AGENTS.md 한 번 훑어 운영 룰 확인
  2. .env.scenario 의 stuck detection 3종 cap (STUCK_RETRIES / NO_PROGRESS / MAX_ITERATIONS) 필요 시 조정
  3. git add . && git commit -m 'chore: scenario-first 하네스 init'
  4. Claude Code 재시작 → trust dialog 수락 → scenario-first@plugify 자동 install
  5. /scenario-first-throw "<첫 시나리오>"
```

## 산출

- 위 디렉터리·파일 일체 (whitelist)
- 갱신된 `.gitignore`
- `git config --local commit.template` 등록
- 응답 요약

## 다음 단계

- `scenario-first-throw` — 첫 Job Story 캡처

## 금지 사항

- whitelist 외 파일 임의 생성 (결정성 깎임)
- 기존 파일을 묵시적으로 덮어쓰기 (`--force` 없이는 절대)
- E2E 프레임워크 결정을 사용자 확인 없이 임의 채택
- `.env.scenario` 를 git 에 commit
- `.harness/.backups/` 를 git 에 commit
- 시드 레포의 실제 cycle 산출물 (NNN-*) 을 cwd 로 복사
