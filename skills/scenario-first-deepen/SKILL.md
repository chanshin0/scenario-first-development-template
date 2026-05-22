---
name: scenario-first-deepen
description: 시나리오-First 개발 depth 연산 (post-MVP 1→n). 이미 review_status=passed 인 기존 NNN의 "해상도"를 올린다 — MVP가 뭉갠 상세 동작(0건·소스다운·동률·품절·로딩·에러 등)을 새 GWT example 로 그 시나리오에 in-place 누적하고, 기존 goal 루프로 green 까지 구현한 뒤 review 를 재통과시킨다. throw(새 backbone, breadth)와 달리 던질 새 Job Story 가 없는 "기존 걸 깊게"(depth)를 모델링. backlog 의 `[deepen NNN]` 항목을 배치로 소비. 핵심 안전장치는 단조성 — example 을 추가만 하고 제거·약화하지 않으므로 잠긴 누적 풀을 회귀시킬 수 없다.
---

# scenario-first-deepen

## 목적

MVP(0→1)는 `throw → expand → spec → goal → review`로 walking skeleton 을 빠르게 세운다. 하지만 "실제 쓸 서비스"로 만들려면 이미 통과한 시나리오의 **상세 동작을 정확히 정의**해야 한다 — 검색 결과 0건이면? 한 소스가 죽으면? 가격 동률이면? 품절이면? 이것들은 *새 기능*(새 throw)이 아니라 *같은 시나리오의 정밀화*다.

`deepen`은 그 depth 연산이다:
- 입력 = `review_status: passed` 인 기존 NNN + 그 NNN을 깊게 할 항목들 (backlog `[deepen NNN]` 또는 inline)
- 동작 = 항목을 GWT example 로 만들어 `scenarios/expanded/NNN-*.md` 에 **in-place 누적** → 기존 goal 루프로 green → review 재통과
- 결과 = 같은 NNN, 더 높은 해상도. 새 NNN 안 만듦.

> **3축 모델** (FEEDBACK-INBOX candidate E): breadth=`throw`(새 backbone) / **depth=`deepen`(있는 걸 정밀하게)** / cosmetic=`tweak`(외관만). 행동 델타가 없으면(여백·문구·색) deepen 이 아니라 `tweak` — 리트머스는 tweak SKILL.md.

## 안전 원리 — 단조성 (이 스킬의 척추)

deepen 은 example/제약을 **추가만** 한다. 기존 example 은 한 글자도 안 바꾼다.
- → 게이트는 빡세지기만 한다 (약해지지 않음) → 잠긴 누적 풀을 **회귀시킬 수 없다**.
- → 그래서 deepen 중에도 그 NNN은 누적 풀에 그대로 남는다 (기존 example 불변이 전제, REGRESSION-POLICY).
- 새 example 이 기존 통과 example 을 깨면 = 새 요구가 잠긴 행동과 **충돌**(candidate C). 게이트 빨강으로 표면화 → review triage 에서 사용자가 결정 (deepen 이 임의 해소 금지).

## 트리거

수동 호출만 (자동 트리거 금지):

| 인자 | 동작 |
|---|---|
| `/scenario-first-deepen <NNN>` | backlog 의 `[deepen NNN]` 항목을 배치로 소비해 NNN 해상도 ↑ |
| `/scenario-first-deepen <NNN> "<inline 동작>"` | 항목을 인자로 직접 지정 (backlog 안 거침) |
| `/scenario-first-deepen 001,002,003` | 여러 NNN을 **순차로** 도는 invocation (각 NNN = 1 패스, 끝에 전부 REVIEW_PENDING) |
| `/scenario-first-deepen --dry-run <NNN>` | 추가할 GWT example 만 출력, 구현 안 함 |
| `/scenario-first-deepen --rerun <NNN>` | 직전 deepen 백업 후 재실행 |

> **멀티-NNN 순차 처리** (`001,002,003`): 각 NNN을 차례로 full 패스(lock→example 누적→goal green→보류 표시→lock 해제)로 돌린다. **어느 순간에도 deepen-NNN은 하나만 활성**(cycle lock 불변 — 패스 사이 해제). 셋 다 끝나면 전부 `REVIEW_PENDING` → `/scenario-first-review --deepen-batch` 로 한 번에 검증. 규율: (a) 각 NNN 사전점검 독립 — `review_status: passed` 아닌 NNN은 skip + warn 후 나머지 진행. (b) 중간 NNN이 goal STUCK 나면 **거기서 멈추고 보고**(완료/보류 / STUCK / 미착수) — thrashing 방지, STUCK 풀고 나머지 재실행.

## 사전 점검

```bash
# 1. 하네스 깔렸나
test -d .harness && test -d scenarios || { echo "ERROR: /scenario-first-init 먼저"; exit 1; }

# 2. expanded 존재
test -f scenarios/expanded/NNN-*.md || { echo "ERROR: scenarios/expanded/NNN-*.md 없음 — deepen 은 기존 시나리오만"; exit 1; }

# 3. review_status=passed 인가 (deepen 은 통과한 시나리오만)
grep -qE "^review_status:[[:space:]]*passed" scenarios/expanded/NNN-*.md || {
  echo "ERROR: NNN 은 아직 review 통과 전. deepen 은 통과한 시나리오의 해상도만 올린다."
  echo "  → 미통과 NNN 은 throw→expand→spec→goal→review 파이프라인을 먼저 끝내라."
  exit 1
}

# 4. cycle lock — throw-cycle 또는 다른 deepen 이 진행 중이면 멈춤 (룰 3.4 확장)
grep -qE "^IN_PROGRESS: \(none\)$" .harness/STATUS.md || {
  echo "ERROR: 다른 cycle/deepen 진행 중 (STATUS.md IN_PROGRESS). 한 번에 하나 (cycle lock)."
  exit 1
}
```

## Workflow

### 1. cycle lock 채움 (deepen- prefix)

```bash
sed -i.bak -E "s|^IN_PROGRESS: \(none\)$|IN_PROGRESS: deepen-NNN|" .harness/STATUS.md && rm .harness/STATUS.md.bak
```

> `deepen-` prefix 는 throw-cycle 의 `NNN-<slug>` 와 격리하기 위함 (throw 게이트 anchor 와 충돌 방지). 이 형식이 채워지면 throw 사전점검이 정상적으로 멈춘다 (의도).

### 2. 항목 수집 (배치)

- `backlog.md` 에서 `[deepen NNN]` 태그 항목 전부 수집 + inline 인자.
- 0개면 사용자에게 "무엇을 깊게 할지" 한 줄 물음 (빈 deepen 거부).
- 각 항목 = "MVP가 안 정한 상세 동작" 하나.

### 3. Example Mapping 미니 → GWT (각 항목)

각 항목을 Example Mapping 의 Rule + Example 로 풀고 GWT(Given-When-Then)로 변환. throw 의 Job Story 는 **재사용**(새로 안 만듦) — 같은 시나리오의 새 example 일 뿐.

**백업 먼저** (룰 3.2):
```bash
TS=$(date -Iseconds)
mkdir -p ".harness/.backups/<NNN>/$TS"
cp scenarios/expanded/NNN-*.md ".harness/.backups/<NNN>/$TS/"
L="- $TS <NNN> scenarios/expanded/NNN-*.md → .harness/.backups/<NNN>/$TS/ (deepen)"
awk -v l="$L" '1;/<!-- BACKUPS-INSERT/{print l}' .harness/STATUS.md > .harness/STATUS.md.tmp && mv .harness/STATUS.md.tmp .harness/STATUS.md
```

`scenarios/expanded/NNN-*.md` 에 새 example **in-place 누적**:
- 기존 Rule 아래 새 Example 추가, 또는 새 Rule + Example 추가.
- GWT 시나리오 id 는 기존 체계 이어서 (예: 기존 NNN.3 까지면 NNN.4…).
- frontmatter 갱신: `resolution:` +1 (없으면 1로 보고 2 부여), `deepened_at: <ISO8601>`.

> **단조성 hard rule**: 기존 example/GWT 줄은 **읽기 전용**. 추가만. 기존 걸 고치거나 지우면 잠긴 풀 보호가 무효가 된다. 기존 example 을 바꿔야 한다면 그건 deepen 이 아니라 행동 변경 → throw 또는 review triage.

### 4. spec 보강 (필요 시만)

새 동작이 ARCH/NONFUNC/OPS 디테일을 요구하면 `scenarios/specs/NNN/` 의 **터치한 슬롯만** append/refine. 백업 먼저(룰 3.2). 가드레일:
- **PRD 재작성 금지** — 해당 슬롯에 새 동작분만 덧붙임.
- 필요 없으면 건너뜀 (대부분의 deepen 은 expanded example + goal 로 충분).

> 절차 상술은 일부러 비워둔다 — 어떤 슬롯을 언제 보강할지는 첫 deepen 실사용에서 관찰 후 굳힌다. 지금은 *허용 + 가드레일*만 (over-spec 회피).

### 5. goal 루프 재실행

`scenario-first-goal` 의 기계를 그대로 사용 (재구현 아님):
- 누적 풀(review_status=passed) + 이번 NNN의 **확장된** example 집합을 함께 E2E 변환·실행.
- 새 example 은 red 출발 → spec/구현으로 green 까지.
- 진전 신호 3종(STUCK_RETRIES / NO_PROGRESS / MAX_ITERATIONS) 그대로 — STUCK 시 `scenarios/specs/NNN/STUCK.md` 에 기록 후 escalate.
- 기존 example 이 깨지면(단조성 위반 신호 = 새 요구가 잠긴 것과 충돌) → 임의 수정 말고 review triage 로.

**배치 부분커밋**: N개 example 을 함께 태우되, 항목별 attribution 은 example 의 scenario id 로:
- green 도달 example → expanded 에 **유지(잠금)**.
- STUCK 항목 → 그 항목이 **이번 패스에서 추가한 example 만** expanded 에서 제거하고 backlog `[deepen NNN]` 로 환원 → 나머지 green 유지.
- commit 입자는 goal 의 "매 반복 commit" 규약(goal SKILL.md)에 위임.

> **단조성과 무모순**: 제거되는 건 *이번 패스에서 추가됐고 아직 통과/잠기지 않은* example 뿐. 잠긴(passed 시점 풀) example 은 절대 안 건드림 — 미수락 추가분 철회는 단조성 위반 아님(단조성의 본질 = "잠긴 것 불변"이지 "추가분 영구"가 아님).

### 6. review 보류 표시 (배치 review 로 미룸)

deepen 은 behavior 를 바꾸므로 review 재통과가 **반드시 필요**하다 — 단 **이 패스에서 하지 않는다.** review 는 끝에 한 번에 묶는다(배치). 그래야 여러 NNN 을 순차로 goal 까지 태운 뒤, "직접 써보는" 검증을 한자리에서 한다.

이 패스에서 하는 것:
- expanded frontmatter 에 `deepen_pending_review: <ISO8601>` 표시 (review_status 는 **안 건드림** — 이전 `passed` 유지). `resolution`/`deepened_at` 은 step 3 에서 이미 갱신.
- goal-green 한 새 example 은 expanded 에 남는다 → NNN 이 이미 풀에 있으므로 **다음 deepen 패스의 goal 게이트에 자동 포함**(잠정). 후속 패스가 이 보류 동작을 깨면 즉시 잡힘.

> **잠정 풀 멤버 (REGRESSION-POLICY)**: 보류 창 동안 새 example 은 goal-green 이나 *본인 미검증*이다. 배치 review 가 닫을 때까지 잠정. 룰 `regression_pool_passed_only` 와 무모순 — NNN 의 `review_status` 는 `passed` 그대로이고(deepen 이 안 내림), 새 example 은 그 passed NNN 의 파일에 얹혀 따라온다. 단 배치 review 를 안 돌리면 가짜-green 이 남으므로 REVIEW_PENDING 가시화 + throw soft warn 으로 강제 closure.

소비된 backlog `[deepen NNN]` 항목은 처리 완료 표시/제거.

### 7. cycle lock 해제 + STATUS (REVIEW_PENDING 누적)

```bash
# lock 해제 — goal 후 해제(review 전). 다음 NNN deepen 이 이어서 가능.
sed -i.bak -E "s|^IN_PROGRESS: deepen-NNN$|IN_PROGRESS: (none)|" .harness/STATUS.md && rm .harness/STATUS.md.bak

# REVIEW_PENDING 에 NNN 누적 (배치 review 대기 — REVIEW-PENDING-INSERT 마커 다음)
L="- NNN (deepen pending since $(date -Iseconds)) — resolution N, +example K개"
awk -v l="$L" '1;/<!-- REVIEW-PENDING-INSERT/{print l}' .harness/STATUS.md > .harness/STATUS.md.tmp && mv .harness/STATUS.md.tmp .harness/STATUS.md

# Cycle 로그 (CYCLE-LOG-INSERT 마커 다음 — 파일 끝 append 금지, 룰 3.3)
L="- $(date -Iseconds) NNN [deepen] resolution N, +example K개, review 보류 (<항목 요약>)"
awk -v l="$L" '1;/<!-- CYCLE-LOG-INSERT/{print l}' .harness/STATUS.md > .harness/STATUS.md.tmp && mv .harness/STATUS.md.tmp .harness/STATUS.md
```

### 8. 응답

성공:
```
✓ deepen/NNN  resolution N  (+example K개, goal green, review 보류)
Next: 다른 NNN deepen → /scenario-first-deepen MMM
      보류분 한 번에 검증 → /scenario-first-review --deepen-batch
```

STUCK:
```
⚠ deepen/NNN  STUCK at scenario-NNN.x.y (<신호>)
진단: scenarios/specs/NNN/STUCK.md
Next: /scenario-first-review NNN --triage  (잠긴 행동과 충돌인지 확인)
```

## 산출

- 갱신된 `scenarios/expanded/NNN-*.md` (example 누적, `resolution` ↑, `deepen_pending_review` 표시) + 백업
- 확장된 `tests/e2e/scenario-NNN/` (goal 재실행 산출)
- 갱신된 `scenarios/specs/NNN/GOAL.md` (REVIEW.md 는 배치 review 때)
- 소비된 backlog `[deepen NNN]` 항목
- 갱신된 `.harness/STATUS.md` (lock 해제 + REVIEW_PENDING + cycle 로그)

## 다음 단계

- 다음 deepen 항목 → `/scenario-first-deepen NNN`
- 해상도 충분 + 새 능력 필요 → `/scenario-first-throw` (breadth)

## 금지 사항

- **단조성 위반** — 기존 example/GWT 를 고치거나 제거 (추가만 허용). 위반 시 잠긴 풀 보호 무효. ← 최우선 hard rule
- review 미통과 NNN 을 deepen (throw 파이프라인 먼저)
- deepen 중 다른 cycle/deepen 동시 진행 (cycle lock — 룰 3.4, `deepen-` prefix)
- `deepen-` prefix 없이 IN_PROGRESS 채우기 (throw anchor 충돌)
- POOL-INSERT 로 NNN 풀 줄 중복 추가 (이미 들어 있음)
- review 재통과를 Claude 가 시뮬레이션 (본인 사용 필수)
- 새 example 이 잠긴 행동과 충돌할 때 임의 해소 (review triage 로)
- 시나리오/example 을 게이트 통과 목적으로 깎기 (goal 과 동일 — 게이트가 정답)
- 자동 트리거 / `--no-verify` / `git push --force`
- STATUS.md 갱신 건너뛰기 / 파일 끝 `echo >>`
