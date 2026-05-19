#!/usr/bin/env bash
# init.sh — scenario-first 하네스 부트스트랩
# 사용: ./init.sh  (멱등 — 여러 번 실행해도 안전)

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_ROOT"

echo "▶ scenario-first 하네스 부트스트랩"
echo "  cwd: $PROJECT_ROOT"

# 1. .env.scenario 로드 (있으면)
if [[ -f .env.scenario ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env.scenario
  set +a
  echo "✓ .env.scenario 로드"
else
  echo "⚠ .env.scenario 없음 — /scenario-first-init 다시 실행 권장"
fi

# 2. .scenarios/ 구조 보강
mkdir -p .scenarios/{throws,expanded,specs,.backups}
touch .scenarios/throws/.gitkeep
touch .scenarios/expanded/.gitkeep
touch .scenarios/specs/.gitkeep
echo "✓ .scenarios/ 구조 확인"

# 3. tests/e2e/ 보강
mkdir -p tests/e2e
touch tests/e2e/.gitkeep
echo "✓ tests/e2e/ 확인"

# 4. git commit template 등록
if [[ -d .git ]] && [[ -f .gitmessage ]]; then
  git config --local commit.template .gitmessage
  echo "✓ git commit.template = .gitmessage"
fi

# 5. E2E 프레임워크 설치 ({{E2E_FRAMEWORK}})
# 아래는 init이 선택한 프레임워크에 맞춰 채워짐. 미설치 시 주석 해제하고 실행.
#
# Playwright (TS/JS):
#   npm install -D @playwright/test
#   npx playwright install
#
# Cypress:
#   npm install -D cypress
#
# Cucumber.js:
#   npm install -D @cucumber/cucumber
#
# pytest-bdd:
#   pip install pytest-bdd
#
# behave:
#   pip install behave

echo ""
echo "✓ 부트스트랩 완료"
echo ""
echo "다음 단계:"
echo "  1. cat AGENTS.md   # 운영 8룰 확인"
echo "  2. cat .scenarios/STATUS.md"
echo "  3. /scenario-first-throw \"<첫 시나리오>\""
