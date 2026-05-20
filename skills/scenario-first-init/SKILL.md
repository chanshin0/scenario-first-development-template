---
name: scenario-first-init
description: 시나리오-First 개발 0단계 (선택). "Use this template" 로 clone 한 사본에서 SFD 색을 벗기는 1회 정리 — placeholder 치환 + `.env.scenario` 생성 + E2E 프레임워크 결정 + SFD 메타(README·자기 ADR) 제거 + git commit.template 등록. 인자 없음. 안 돌려도 throw~spec 은 진행되고 E2E 는 goal 0번이 처리하므로 강제 아님 — 미관/정체성 노이즈를 미리 치우고 싶을 때만.
---

# scenario-first-init

## 목적

`Use this template` 로 clone 한 사본은 시드 파일이 **이미 cwd 에 다 있다** (6 스킬·`.harness`·`scenarios/` 빈 디렉터리 등). 단 SFD 자신의 색이 묻어있다 — placeholder 미치환, SFD README·자기 ADR. init 은 그 색만 벗기는 **1회 정리** 다.

복사 안 함, 스캐폴딩 안 함 — clone 이 이미 했다. **인자 없음.** 멱등 (재실행 안전, 치울 게 없으면 no-op).

> 선택이다. 안 돌려도 `throw`(1)~`spec`(3) 은 그대로 동작하고, E2E 는 처음 `goal`(4) 이 알아서 결정한다. init 은 placeholder·SFD README·ADR 이 굴러다니는 게 거슬릴 때 미리 치우는 용도.

## 트리거

```
/scenario-first-init
```

수동 호출만. 인자 없음. 새 프로젝트에서 본인이 1회 (선택).

## 사전 점검

```bash
# .git 없으면 자동 init (commit.template 등록·atomic commit 의무 전제)
if [ ! -d .git ]; then
  echo "INFO: .git 없음 — git init 자동 실행"
  git init -q
fi
# 하네스 존재 확인 (clone 사본이면 이미 있음)
test -d .harness && test -d .claude/skills || {
  echo "WARN: 하네스/스킬 없음 — 이 cwd 는 SFD template clone 이 아닌 듯. init 은 clone 사본 정리 전용."
}
```

## Workflow

### 1. 환경 진단

```bash
ls package.json pyproject.toml Cargo.toml go.mod 2>/dev/null      # 언어
grep -E "(playwright|cypress|cucumber|pytest-bdd|behave)" package.json pyproject.toml 2>/dev/null  # E2E 후보
ls .env.scenario 2>/dev/null                                      # 이미 정리됐는지
grep -l "{{PROJECT_NAME}}\|{{E2E_FRAMEWORK}}" AGENTS.md .env.scenario.example 2>/dev/null  # 미치환 placeholder
```

한 표로 보고:

```
감지 결과:
- 언어:        TypeScript (package.json)
- E2E:         없음 — 선택 필요
- placeholder: AGENTS.md 미치환
- .env.scenario: 없음 (생성 예정)
```

### 2. E2E 프레임워크 결정 (1회)

자동 감지된 게 있으면 채택. 없으면 사용자에게 1회 묻기:

| 옵션 | 적합 |
|---|---|
| Playwright | TS/JS 웹 앱 default |
| Cypress | TS/JS, 비주얼 디버깅 선호 |
| Cucumber.js | Gherkin 그대로 실행 |
| pytest-bdd | Python |
| behave | Python, 가장 BDD 친화적 |
| (수동) | 나중에 결정 — `.env.scenario`에 TBD 기록 |

"지금 설치할까요?" 확인. 동의 시 매니페스트 추가 + 설치, 거부 시 명령만 남기고 실행 안 함.

#### 패키지 매니저 (JS/TS)

`command -v pnpm` 우선. 있으면 pnpm default (속도·디스크·strict). `pnpm-lock.yaml`→pnpm / `yarn.lock`→yarn / 둘 다 없으면 npm. lockfile 도 commit 대상. Python: `uv add` 또는 `pip install`.

### 3. placeholder 치환 + `.env.scenario` 생성

```bash
NAME=$(basename "$PWD")
TS=$(date -Iseconds)
# AGENTS.md 등 본문 치환
sed -i.bak "s/{{PROJECT_NAME}}/$NAME/g; s/{{CREATED_AT}}/$TS/g" AGENTS.md && rm AGENTS.md.bak
# .env.scenario 생성 (.example 기준, E2E 값 채움). .example 은 보존
sed "s/{{E2E_FRAMEWORK}}/<결정값>/g; s|{{E2E_TEST_CMD}}|<실행명령>|g" .env.scenario.example > .env.scenario
```

치환 대상 placeholder: `{{PROJECT_NAME}}` → cwd basename / `{{E2E_FRAMEWORK}}` → 2단계 결정값 / `{{E2E_TEST_CMD}}` → 프레임워크별 실행 명령 / `{{CREATED_AT}}` → ISO8601. AGENTS.md·init.sh·`.env.scenario` 에 남은 것 전부.

### 4. SFD 메타 제거

clone 사본에 묻어온 SFD **자신의** 것 — 새 프로젝트 것 아님:

```bash
rm -f README.md                          # SFD 방법론 설명서 (네 프로젝트 README 아님)
rm -f .harness/EVOLUTION/[0-9]*.md        # SFD 자신의 ADR (새 프로젝트는 001부터 자기 ADR 누적)
```

**제거 안 함** (전부 그대로 쓰는 자산): `.claude/skills/`·`.claude/agents/`·`.harness/`(ADR 본문 제외)·`scenarios/`·`tests/e2e/`·`init.sh`·`.gitmessage`·`rules.json`·`AGENTS.md`·`CLAUDE.md`·`.env.scenario.example`·`templates/EVOLUTION.md`. `scenarios/`·`tests/e2e/` 는 `.gitkeep` 만 있어 비울 것 없음.

### 5. git 후속

```bash
git config --local commit.template .gitmessage
grep -q "^.env.scenario$" .gitignore || echo ".env.scenario" >> .gitignore
grep -q "^.harness/.backups/$" .gitignore || echo ".harness/.backups/" >> .gitignore
```

### 6. 응답

```
✓ clone 정리 완료

- placeholder 치환: {{PROJECT_NAME}} → my-idea 등
- .env.scenario 생성 (E2E: Playwright)
- 제거: README.md (SFD 설명서), .harness/EVOLUTION/001~00N (SFD ADR)
- git commit.template 등록

다음:
  1. (선택) AGENTS.md 훑어 운영 9룰 확인
  2. git add . && git commit -m 'chore: scenario-first 하네스 정리'
  3. /scenario-first-throw "<첫 시나리오>"
```

## 산출

- 치환된 `AGENTS.md` 등 + 생성된 `.env.scenario`
- 제거된 SFD 메타 (`README.md`, 자기 ADR)
- `git config --local commit.template` 등록 + 갱신된 `.gitignore`
- 응답 요약

## 다음 단계

- `scenario-first-throw` — 첫 Job Story 캡처

## 금지 사항

- 복사·스캐폴딩 시도 (clone 이 이미 함 — init 은 정리 전용)
- 그대로 쓰는 자산(`.claude/skills/`·`.harness/` 정책 파일 등) 제거
- E2E 프레임워크를 사용자 확인 없이 임의 채택·설치
- `.env.scenario` 를 git 에 commit
- 인자 추가 (이 스킬은 무인자 단일 동작 — 새 모드 만들지 말 것)
