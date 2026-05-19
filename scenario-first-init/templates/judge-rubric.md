# LLM Judge Rubric — scenario-first-goal fallback

> `scenario-first-goal` 4단계가 GWT 자동 변환 불가 시나리오를 LLM judge 로 판정할 때 쓰는 공통 rubric.
> **판정 기준은 시나리오의 Then을 그대로** — 새 기준 만들지 않는다.

## 판정 출력 (구조 고정)

```yaml
scenario_id: NNN.X.Y.Z
verdict: PASS | FAIL | UNCERTAIN
evidence:
  - <근거 1 (스크린샷 좌표·DOM 셀렉터·로그 라인 인용)>
  - <근거 2>
rationale: <Then을 인용하며 한 문장>
suggested_action: <FAIL/UNCERTAIN일 때만 — implementation_fix | scenario_clarify | spec_gap>
```

## 판정 절차

1. **Then 인용**: `.scenarios/expanded/NNN-*.md` 의 해당 시나리오 `Then` 한 줄 그대로 인용.
2. **근거 수집**: 결과물(스크린샷·HTML·DOM·로그) 에서 Then을 만족/불만족하는 구체 근거 추출. 추상 표현 금지.
3. **이진 판정**: PASS / FAIL 중 하나. 둘 다 강한 근거 있을 때만 UNCERTAIN.
4. **suggested_action**: FAIL이면 5 Whys 라우팅 후보 1개 제안 (review 4단계가 최종 결정).

## UNCERTAIN 처리

`.env.scenario` 의 `SCENARIO_JUDGE_UNCERTAIN_AS_STUCK=true` 면 STUCK으로 escalate. 권장값.

## 금지

- Then에 없는 기준 도입 ("디자인이 깔끔하다" 같은 사후 기준)
- 근거 없이 verdict
- PASS·FAIL 둘 다 약한 근거일 때 임의 PASS (UNCERTAIN이 정직)
- suggested_action 으로 시나리오 자체를 수정 — review 4단계의 일
- 다중 시나리오 한 번에 판정 — 시나리오당 1회

## 모델 권장

- 시각 검증: vision 모델 (Claude Opus / Sonnet 최신, GPT-4o 등)
- 텍스트·로그 검증: 일반 long-context 모델
- 비용 민감하면 Sonnet 4.6 / Haiku 4.5

`SCENARIO_JUDGE_MODEL` env로 고정 가능.
