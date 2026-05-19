#!/usr/bin/env bash
# init.sh — scenario-first 하네스 부트스트랩 + verify/start
# 사용:
#   ./init.sh              # 부트스트랩 (멱등)
#   ./init.sh verify       # 누적 게이트 한 번 실행 (SCENARIO_E2E_CMD)
#   ./init.sh start        # 앱 실행 (SCENARIO_START_CMD)

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_ROOT"

# ── .env.scenario 로드 ──────────────────────────────────────
load_env() {
  if [[ -f .env.scenario ]]; then
    set -a
    # shellcheck disable=SC1091
    source .env.scenario
    set +a
  fi
}

# ── bootstrap (기본 동작) ────────────────────────────────────
bootstrap() {
  echo "▶ scenario-first 하네스 부트스트랩"
  echo "  cwd: $PROJECT_ROOT"

  load_env
  if [[ -f .env.scenario ]]; then
    echo "✓ .env.scenario 로드"
  else
    echo "⚠ .env.scenario 없음 — /scenario-first-init 다시 실행 권장"
  fi

  mkdir -p .scenarios/{throws,expanded,specs,.backups}
  touch .scenarios/throws/.gitkeep .scenarios/expanded/.gitkeep .scenarios/specs/.gitkeep
  echo "✓ .scenarios/ 구조 확인"

  mkdir -p tests/e2e
  touch tests/e2e/.gitkeep
  echo "✓ tests/e2e/ 확인"

  if [[ -d .git ]] && [[ -f .gitmessage ]]; then
    git config --local commit.template .gitmessage
    echo "✓ git commit.template = .gitmessage"
  fi

  # E2E 프레임워크 설치 ({{E2E_FRAMEWORK}})
  # 아래는 init 이 선택한 프레임워크에 맞춰 채워짐. 미설치 시 주석 해제.
  #
  # Playwright:    npm install -D @playwright/test && npx playwright install
  # Cypress:       npm install -D cypress
  # Cucumber.js:   npm install -D @cucumber/cucumber
  # pytest-bdd:    pip install pytest-bdd
  # behave:        pip install behave

  echo ""
  echo "✓ 부트스트랩 완료"
  echo ""
  echo "다음 단계:"
  echo "  1. cat AGENTS.md          # 운영 8룰 확인"
  echo "  2. cat .scenarios/STATUS.md"
  echo "  3. ./init.sh verify       # 누적 게이트 smoke"
  echo "  4. /scenario-first-throw \"<첫 시나리오>\""
}

# ── verify: 누적 게이트 한 번 실행 ───────────────────────────
verify() {
  load_env
  local cmd="${SCENARIO_E2E_CMD:-}"
  if [[ -z "$cmd" ]]; then
    echo "✗ SCENARIO_E2E_CMD 가 .env.scenario 에 없음" >&2
    echo "  E2E 프레임워크 설치 후 .env.scenario 갱신 필요." >&2
    exit 2
  fi
  echo "▶ verify: $cmd"
  # shellcheck disable=SC2086
  eval $cmd
}

# ── start: 앱 실행 ──────────────────────────────────────────
start() {
  load_env
  local cmd="${SCENARIO_START_CMD:-}"
  if [[ -z "$cmd" ]]; then
    echo "✗ SCENARIO_START_CMD 가 .env.scenario 에 없음" >&2
    echo "  앱 실행 명령 (e.g. npm run dev) 을 .env.scenario 에 추가." >&2
    exit 2
  fi
  echo "▶ start: $cmd"
  # shellcheck disable=SC2086
  exec $cmd
}

# ── 디스패치 ─────────────────────────────────────────────────
case "${1:-bootstrap}" in
  bootstrap|"") bootstrap ;;
  verify)       verify ;;
  start)        start ;;
  *)
    echo "사용: $0 [bootstrap|verify|start]" >&2
    exit 1
    ;;
esac
