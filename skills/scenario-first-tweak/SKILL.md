---
name: scenario-first-tweak
description: 시나리오-First 개발 cosmetic 축 (post-MVP 1→n). 이미 동작하는 화면의 **행동 델타 없는 UI/UX 변경** — 여백·문구·색·정렬·폰트·마이크로 인터랙션 다듬기 — 를 위한 경량 트랙. Job Story·GWT 작성 없음. 게이트 1(자동) = 기존 누적 풀 green 유지(행동 안 바꿨다는 증명, 신규 게이트 아님), 게이트 2(수동) = 본인이 시각 결과를 직접 보고 evidence 승인. 누적 풀에 안 들어가고(새 NNN 아님) cycle lock 도 점유 안 한다. 핵심 구별: 새 GWT(Then 단언)를 쓸 수 있으면 deepen(행동), 못 쓰면 tweak(외관). tweak 이 풀을 깨면 사실 행동을 바꾼 것 → deepen/throw 로 승격.
---

# scenario-first-tweak

## 목적

MVP 가 서고 deepen 으로 상세 동작까지 정의된 뒤에도, "실제 쓸 서비스"는 **외관·감각**을 계속 다듬어야 한다 — 여백, 문구 톤, 색, 정렬 간격, 인터랙션 디테일. 이건 *행동*이 아니라 *렌더링*이라 `When/I want/so` + GWT 자동 게이트의 무게가 과하다. `tweak` 은 그 경량 트랙이다.

> **3축 모델** (FEEDBACK-INBOX candidate E): breadth=`throw`(새 backbone) / depth=`deepen`(있는 걸 정밀하게) / **cosmetic=`tweak`(외관만)**.

## tweak vs deepen — 리트머스 (호출 전 반드시)

**한 줄 판정: 새 GWT(Then 단언)를 쓸 수 있나?**

- **쓸 수 있다 → `deepen`** (행동). "0건이면 빈 상태를 보여준다", "소스 다운이면 나머지로 비교한다" — 단언 가능한 동작. example 을 추가하고 red→green.
- **못 쓴다(순수 외관·주관) → `tweak`**. "여백 8px", "버튼 색", "문구 톤" — `Then` 으로 박을 게 없다. 눈으로 보는 것 말곤 판정 기준이 없음.

| | deepen | tweak |
|---|--------|-------|
| 행동 델타 | 있음 | **없음** |
| 자동 게이트가 원하는 것 | 새 example red→**green** | 기존 풀 **green 유지** (= 행동 안 바꿨다는 증명) |
| 변경 자체 판정자 | 자동 E2E (Then) | **본인 눈** (수동 시각 승인) |
| 누적 풀 | NNN 해상도 ↑ | 미진입 (새 NNN 아님) |

**경계가 애매하면 풀이 판정한다**: tweak 으로 시작했는데 게이트 1(기존 풀)이 빨개지면 = 행동을 바꾼 것 = 사실 deepen 이었다 → 중단하고 `deepen`/`throw` 로 승격. 분류를 완벽히 할 필요 없음 — 잘못 분류하면 풀이 잡는다.

**경계 예시:**
- "에러 문구만 바꿈"(같은 조건·같은 에러) → tweak. "에러 *뜨는 조건* 바꿈" → deepen.
- "로딩 스피너 예쁘게" → tweak. "로딩 *상태 추가*"(When 로딩, Then 스피너) → deepen.
- "버튼 위치 옮김 + 클릭 동작 바꿈" → 쪼갠다: 위치=tweak, 동작=deepen.

## 트리거

수동 호출만 (자동 트리거 금지):

| 인자 | 동작 |
|---|---|
| `/scenario-first-tweak "<변경 의도>"` | 행동 델타 없는 UI/UX 변경 1건 (또는 한 세션 묶음) |
| `/scenario-first-tweak --batch "<의도1>" "<의도2>" …` | 여러 외관 변경 묶음 |

## 사전 점검

```bash
# 1. 하네스 깔렸나
test -d .harness && test -d scenarios || { echo "ERROR: /scenario-first-init 먼저"; exit 1; }

# 2. cycle/deepen 진행 중이 아닌가 (tweak 은 cycle 아님 — IN_PROGRESS 점유 안 하지만, 진행 중 cycle 사이에 끼면 그 게이트 풀이 흔들림)
grep -qE "^IN_PROGRESS: \(none\)$" .harness/STATUS.md || {
  echo "ERROR: throw-cycle/deepen 진행 중 (IN_PROGRESS). 그 단위 끝낸 뒤 tweak."
  exit 1
}

# 3. 기준선 — 손대기 전 누적 풀이 이미 green 인가 (tweak 의 행동-불변 증명은 'green→green' 이라야 의미)
./init.sh verify || { echo "ERROR: 기준선 게이트가 이미 빨강. tweak 전에 먼저 수정."; exit 1; }
```

> tweak 은 `IN_PROGRESS` 를 **점유하지 않는다** (cycle 아님 — 새 NNN/expanded 변경 없음). 단 실행 전 `(none)` 을 요구해 진행 중 cycle 과 안 겹치게 한다.

## Workflow

### 1. 변경 의도 확인

각 tweak = 한 줄 외관 변경 의도. 리트머스 재확인 — 단언할 행동이 생기면 멈추고 deepen 으로.

> **`--batch`**: 여러 외관 변경을 묶을 때 — 의도들을 다 적고 2번(적용)을 의도별로, 3번(게이트1)은 **전부 적용 후 한 번** 돌린다(다 cosmetic 이라 풀 green 이 "아무것도 행동 안 바꿈"을 한 방에 증명). 4번(시각 evidence)은 변경별로. 빨강이면 어느 변경이 행동을 바꿨는지 이등분으로 좁혀 그것만 deepen/throw 로.

### 2. 변경 적용

UI/스타일 코드 수정. 가장 작은 단위 commit (`.gitmessage` 규약). (`--batch` 면 의도별 commit.)

### 3. 게이트 1 (자동) — 기존 누적 풀 green 유지

```bash
./init.sh verify
```

- **green 유지 → 행동 안 바꿨다는 증명.** 4번으로.
- **빨강 → 행동을 바꾼 것.** 이건 tweak 이 아니다 → 변경 되돌리고 `deepen`/`throw` 로 승격.

> 게이트 1 은 **기존 누적 풀을 그대로 재사용**한다. 새 게이트를 신설하는 게 아니다 (regression 별도 게이트 분리 금지 — AGENTS 6 금지에 부합). tweak 은 풀에 새 시나리오를 안 더한다.

### 4. 게이트 2 (수동) — 본인 시각 승인

변경 자체(외관이 의도대로 됐나)는 자동으로 판정 불가 — 본인이 직접 본다:
- 스크린샷 / 전후 비교 / 실제 화면 확인.
- evidence 를 `scenarios/tweaks/<날짜>-<slug>.md` 에 기록 (`.harness/templates/REVIEW.md` 의 evidence 슬롯 양식 차용 — 최소 1개 시각 evidence).
- **evidence 없이 tweak 완료 표시 금지** (review 의 passing_requires_evidence 와 같은 강도).

> Playwright 등 스냅샷 도구가 있으면(init 이 정한 E2E) 전후 스크린샷 diff 로 보조. 없으면 순수 수동 확인. 어느 쪽이든 *판정자는 본인 눈* — Claude 시뮬레이션 금지.

### 5. 표면 커버리지 (soft warn)

tweak 은 누적 풀이 커버하는 표면의 외관만 안전하다. 풀이 안 보는 표면을 만지면 행동 변화를 게이트 1 이 못 잡는다 — 그 경우 게이트 2(본인 눈)가 최종 방어선이지만, 의심되면 tweak 말고 `deepen`/`throw`.

> hard block(표면-커버리지 머신 판정)은 현재 하네스에 표면↔테스트 매핑이 없어 불가 — soft warn 으로 둔다. 매핑이 생기면 승격 (FEEDBACK-INBOX 후속 candidate).

### 6. STATUS.md 갱신 (룰 3.3)

```bash
# cycle 로그에 [tweak] (CYCLE-LOG-INSERT 마커 다음 — 파일 끝 echo >> 금지). NNN 없음.
L="- $(date -Iseconds) [tweak] <변경 의도 한 줄> (풀 green 유지, 시각 evidence)"
awk -v l="$L" '1;/<!-- CYCLE-LOG-INSERT/{print l}' .harness/STATUS.md > .harness/STATUS.md.tmp && mv .harness/STATUS.md.tmp .harness/STATUS.md
```

> `IN_PROGRESS` 안 건드림 (점유 안 함). 누적 풀(POOL-INSERT) 안 건드림 (새 NNN 아님).

### 7. 응답

```
✓ tweak  <변경 의도>  (누적 풀 K개 green 유지, 시각 evidence: scenarios/tweaks/...)
```

승격 시:
```
⤴ tweak → deepen/throw  "<의도>" 가 행동을 바꿈 (게이트 1 빨강 / 단언할 Then 생김)
변경 되돌림. Next: /scenario-first-deepen <NNN> 또는 /scenario-first-throw
```

## 산출

- UI/스타일 코드 변경 + commit (`.gitmessage` 규약)
- `scenarios/tweaks/<날짜>-<slug>.md` (시각 evidence)
- 갱신된 `.harness/STATUS.md` (cycle 로그 `[tweak]`)

## 다음 단계

- 다른 외관 변경 → `/scenario-first-tweak`
- 행동을 바꿔야 함 → `/scenario-first-deepen <NNN>` (있는 시나리오 정밀화) 또는 `/scenario-first-throw` (새 backbone)

## 금지 사항

- **행동 델타가 있는데 tweak 으로 처리** — 새 GWT(Then)를 쓸 수 있으면 deepen. ← 최우선
- 게이트 1(기존 풀)이 빨강인데 tweak 으로 강행 — 행동 바뀐 것, 되돌리고 승격
- 게이트 2 시각 evidence 없이 완료 표시 (본인 사용 필수 — Claude 시뮬레이션 금지)
- 누적 풀(POOL-INSERT)에 tweak 항목 추가 (새 NNN 아님)
- `IN_PROGRESS` 점유 (cycle 아님)
- throw-cycle/deepen 진행 중(`IN_PROGRESS≠(none)`)에 tweak 끼우기
- regression 을 누적 풀 밖 별도 게이트로 분리 (게이트 1 은 기존 풀 재사용)
- 자동 트리거 / `--no-verify` / `git push --force`
- STATUS.md 파일 끝 `echo >>` (CYCLE-LOG-INSERT 마커 사용)
