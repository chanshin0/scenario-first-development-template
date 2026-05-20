---
name: scenario-first-goal
description: 시나리오-First 개발 4단계. spec + 누적 GWT 시나리오를 게이트로 두고 goal-directed agentic loop을 실행한다. 1차 게이트는 GWT의 E2E 자동 변환(Playwright 등 — init이 결정), 2차 fallback은 LLM judge(`.harness/judge-rubric.md`), manual은 5단계로 분리. 누적 풀은 `.harness/REGRESSION-POLICY.md` 의 통과 조건 (`review_status: passed`) 만 포함. 진전 신호 3종(STUCK_RETRIES / NO_PROGRESS / MAX_ITERATIONS) 으로 thrashing 방지.
---

# scenario-first-goal

## 목적

`scenario-first-spec`이 만든 spec을 코드로 구현하되, **목표는 "GWT 시나리오 통과"** 이며 통과는 자동으로 측정한다. 사용자가 "맞나?" 물어볼 일 없이 게이트로 정답을 정의.

원리:
- 게이트 = **이번 시나리오 + 누적 풀(review_status=passed)** 통과 (regression이 이 조건에 흡수)
- 1차: GWT → E2E 자동 변환 (init이 결정한 프레임워크)
- Fallback: 자동 변환 불가 케이스만 LLM judge (`.harness/judge-rubric.md`)
- Manual은 4단계 게이트에 두지 않음 (5단계의 일 — `scenario-first-review`)

## 트리거

수동 호출만:

| 인자 | 동작 |
|---|---|
| `/scenario-first-goal <NNN>` | spec NNN 기반 goal loop 실행 |
| `/scenario-first-goal --dry-run <NNN>` | E2E 변환·계획만 출력, 구현 안 함 |
| `/scenario-first-goal --resume <NNN>` | 마지막 stuck 지점에서 재개 (review (3) 구현 오류 라우팅) |

자동 트리거 금지 — 비용 큼.

## 사전 점검

```bash
# 1. 하네스 깔렸나
test -d .harness && test -d scenarios || {
  echo "ERROR: /scenario-first-init 먼저"
  exit 1
}

# 2. spec 존재
test -d scenarios/specs/NNN || {
  echo "ERROR: scenarios/specs/NNN/ 없음 — /scenario-first-spec <NNN> 먼저"
  exit 1
}

# 3. expanded 존재 (이번 NNN)
test -f scenarios/expanded/NNN-*.md || {
  echo "ERROR: scenarios/expanded/NNN-*.md 없음"
  exit 1
}

# 4. env 로드 + E2E 명령 확인 (init이 .env.scenario 에 박아둠)
source .env.scenario 2>/dev/null || true
test -n "${SCENARIO_E2E_CMD:-}" || {
  echo "ERROR: SCENARIO_E2E_CMD 미설정 — /scenario-first-init 다시 또는 .env.scenario 확인"
  exit 1
}
```

## Workflow

### 1. 누적 풀 산정 (룰 3.1 + REGRESSION-POLICY)

`.harness/STATUS.md` 의 "## 누적 게이트 풀" 섹션에서 `review_status: passed` 인 NNN 목록 추출. 거기에 이번 NNN 추가.

폐기된 NNN(`archived: true`) 또는 review 미통과 NNN의 GWT는 **제외**.

### 2. GWT → E2E 자동 변환

위 누적 풀의 `scenarios/expanded/NNN-*.md` GWT 시나리오 전체 + 이번 NNN을 프로젝트 E2E 프레임워크의 테스트 파일로 변환.

#### 변환 매핑
| Gherkin | 변환 대상 |
|---|---|
| `Scenario:` | `test(...)` / `it(...)` / `def test_...` |
| `Given` | `beforeEach` / `fixture` / setup |
| `When` | 액션 호출 (page.click 등) |
| `Then` | assertion |

저장: `tests/e2e/scenario-<NNN>/`.

#### 자동 변환 불가 케이스

LLM judge fallback 대상으로 마킹 (`@llm-judge` 태그 또는 별도 디렉토리):
- 시각적 검증 ("디자인이 좋아 보인다" 류)
- 주관적 품질
- 매우 복잡한 상태 검증

### 3. 초기 구현 (Claude)

spec의 PRD + ARCH + NONFUNC + OPS를 읽고 구현 1차 시도:
- ARCH의 결정 lock 표 준수
- walking skeleton 순서대로
- 가장 작은 단위 commit (각 walking skeleton = 1 commit, `.gitmessage` 규약 따름)

### 4. 게이트 실행

```bash
./init.sh verify
# 내부적으로 $SCENARIO_E2E_CMD 호출 (init이 결정한 E2E 프레임워크)
```

결과 분석:
- 전체 PASS → 7번 (성공)
- 일부 FAIL → 5번 (반복 루프)
- 변환 불가 케이스 → 6번 (LLM judge)

### 5. 반복 루프 (실패 진단 + 수정)

failure 출력 분석:
- assertion 실패 → 구현 수정
- timeout → 구현 또는 시나리오의 When 액션 검토
- setup 실패 → Given 검토

수정 후 게이트 재실행. **commit은 매 반복마다** (`.gitmessage` 규약, 예: `fix: scenario-NNN.x.y assertion`).

#### Stuck detection (env 기반 — 진전 신호 3종)

비용($)은 stuck 의 결과 지표라 cap 으로 안 쓴다. 진전 신호로 직접 잡음.
어느 하나라도 트리거되면 STUCK 으로 escalate.

`.env.scenario` 변수:
- `SCENARIO_GOAL_STUCK_RETRIES` (기본 3) — 같은 시나리오 ID 의 같은 실패 hash 가 M회 연속 반복되면 STUCK (같은 실패 반복)
- `SCENARIO_GOAL_NO_PROGRESS` (기본 3) — 누적 풀 PASS assertion count 가 N회 iteration 동안 동결되면 STUCK (시도는 하는데 진전 0)
- `SCENARIO_GOAL_MAX_ITERATIONS` (기본 10) — 누적 iteration N회 초과 시 STUCK (무한 루프 방지 안전망)

#### 측정 로직 (명세 — 구현은 첫 cycle 후 EVOLUTION 002 로)

- 실패 hash: failure 의 `(scenario_id, assertion_message_normalized)` 튜플의 sha256 앞 8자
- PASS assertion count: 누적 풀 + 이번 NNN 전체 테스트 실행 결과의 `passed` 합산 (E2E reporter=json 출력 파싱)
- iteration: 한 번의 게이트 실행(`./init.sh verify`) = 1 iteration

이 측정 로직 자체가 부정확하면 다음 EVOLUTION ADR 로 처리. 이번 단계에선 명세 정합.

Escalate 시: `scenarios/specs/NNN/STUCK.md`에 진단 기록 (트리거된 신호 + 측정값 + 마지막 N 회 commit hash + 마지막 실패 로그) 후 사용자에게 보고.

### 6. LLM judge fallback (선택)

자동 변환 불가 시나리오에 한해, `.harness/judge-rubric.md` 의 양식대로 판정:

- Claude(또는 `SCENARIO_JUDGE_MODEL`) 가 결과물(스크린샷·HTML·DOM·로그)을 보고 GWT의 Then을 판정
- 판정 기준은 시나리오의 Then을 그대로 사용 — 새 기준 만들지 않음
- 출력 구조 (rubric 강제):
  ```yaml
  scenario_id: NNN.X.Y.Z
  verdict: PASS | FAIL | UNCERTAIN
  evidence: [...]
  rationale: ...
  ```
- UNCERTAIN은 `.env.scenario` 의 `SCENARIO_JUDGE_UNCERTAIN_AS_STUCK` 따라 처리 (기본 true → escalate)

### 7. 성공 결과 기록

`scenarios/specs/NNN/GOAL.md` 생성:
```markdown
# Goal 실행 결과

- 시나리오 NNN: PASS
- 누적 풀 (review_status=passed): <목록> 모두 PASS
- iteration 수: N
- 진전 신호 측정값: STUCK_RETRIES=a/M, NO_PROGRESS=b/N (마지막 PASS count=c), MAX_ITERATIONS=d/L
- commit 범위: <hash range>
- E2E 변환 위치: tests/e2e/scenario-NNN/

## LLM judge 사용 시나리오
<목록 + judge-rubric.md 양식의 verdict + evidence + rationale 인용>
```

expanded frontmatter 갱신:
```
goal_status: passed
goal_at: <ISO8601>
```

### 8. STATUS.md 갱신 (룰 3.3)

```bash
echo "- $(date -Iseconds) NNN [goal] PASS (iteration N, 누적 K)" >> .harness/STATUS.md
```

STUCK 시:
```bash
sed -i.bak -E "s|^STUCK:.*|STUCK: NNN at <scenario-id>|" .harness/STATUS.md && rm .harness/STATUS.md.bak
echo "- $(date -Iseconds) NNN [goal] STUCK at <scenario-id> (<트리거된 신호>)" >> .harness/STATUS.md
```

### 9. 응답

성공:
```
✓ goal/NNN  PASS (누적 K개 모두 통과, iteration N회)
Next: /scenario-first-review NNN  (본인 직접 사용)
```

Escalate:
```
⚠ goal/NNN  STUCK at scenario-NNN.x.y (<트리거된 신호: STUCK_RETRIES | NO_PROGRESS | MAX_ITERATIONS>)
진단: scenarios/specs/NNN/STUCK.md
Next: /scenario-first-review NNN --triage
```

## 산출

- `tests/e2e/scenario-NNN/` (자동 생성된 E2E)
- `scenarios/specs/NNN/GOAL.md` 또는 `STUCK.md`
- commit history (각 walking skeleton 단위, `.gitmessage` 규약)
- 갱신된 expanded frontmatter
- 갱신된 `.harness/STATUS.md`

## 다음 단계

- `scenario-first-review` — 본인 직접 사용 + 5 Whys 라우팅

## 금지 사항

- 누적 풀에 review 미통과 NNN 포함 (REGRESSION-POLICY 위반)
- Manual 테스트를 게이트에 끼우기 (5단계의 일)
- Stuck detection 비활성화 (thrashing 위험)
- 진전 신호 3종 (`STUCK_RETRIES` / `NO_PROGRESS` / `MAX_ITERATIONS`) 비활성화 — 명시 동의 없이 금지
- LLM judge로 자동 변환 가능 케이스 처리 (LLM 의존도 증가)
- LLM judge 가 `.harness/judge-rubric.md` 양식 벗어남
- `--no-verify`, `git push --force` 등 안전장치 우회
- 시나리오 임의 수정 — 게이트가 정답이므로 시나리오를 못 통과한다고 시나리오를 깎으면 안 됨 (5단계에서 사용자가 결정)
- E2E 프레임워크 결정을 이 단계에서 묻기 (init이 0단계에서 결정 — 미설정이면 init 다시)
- 하네스 미설치 상태에서 강행
- STATUS.md 갱신 건너뛰기
