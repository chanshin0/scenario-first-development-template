# REVIEW NNN — <Job Story 한 줄>

> `scenario-first-review` 4단계 산출물. **본인이 직접 사용** + **6범주 사전 평가** + **evidence 첨부** + **5 Whys 라우팅** (실패 시).
> 이 템플릿은 `.scenarios/specs/NNN/REVIEW.md` 로 저장.

---

## 1. 사용 체크리스트 (Job Story `so I can` + Walking skeleton)

- [ ] **so I can**: <Job Story so I can 절 그대로>
- [ ] 1.1 <walking skeleton 동작 — 실제 동작했는가>
- [ ] 2.1 <walking skeleton 동작>
- [ ] ...

---

## 2. 6범주 사전 평가 (evaluator-rubric)

| 범주 | 질문 | 점수 (0~2) | 비고 |
|---|---|---|---|
| 정확성 (Correctness) | 구현된 동작이 GWT 시나리오 Then 과 일치하는가? |  |  |
| 검증 (Verification) | 누적 게이트 + LLM judge 가 실제로 실행되고 PASS 했는가? |  |  |
| 범위 규율 (Scope discipline) | cycle 이 선택된 NNN backbone 슬라이스 안에 머물렀는가? (cycle lock 준수) |  |  |
| 신뢰성 (Reliability) | 결과가 `./init.sh verify` 재실행 후에도 PASS 유지되는가? |  |  |
| 유지보수성 (Maintainability) | 코드와 spec 4슬롯이 다음 cycle에서 충분히 이해 가능한가? |  |  |
| 핸드오프 준비성 (Handoff readiness) | 새 세션이 STATUS.md + HANDOFF.md + spec 만으로 작업을 이어받을 수 있는가? |  |  |

**합계**: __ / 12

**판정**:
- [ ] Accept (≥10)
- [ ] Revise (6~9) — 5 Whys 라우팅으로
- [ ] Block (≤5) — cycle 자체 폐기 검토

---

## 3. Evidence (passing_requires_evidence — 룰 3.4 머신 검증)

다음 중 **최소 2개 첨부**. 없으면 `review_status: passed` 표시 금지:

- [ ] **스크린샷 or 화면 녹화** 경로: `<예: .scenarios/specs/NNN/evidence/screenshot-001.png>`
- [ ] **goal 4단계 PASS 로그** 경로: `<예: .scenarios/specs/NNN/GOAL.md 참조>`
- [ ] **commit hash range**: `<예: abc123..def456>`
- [ ] **사용 narrative** (본인이 실제로 어떻게 썼는지 1~2문장): `<...>`
- [ ] **LLM judge 출력** (해당 시): `<rationale 인용>`
- [ ] (기타) `<설명>`: `<경로 또는 인용>`

---

## 4. 5 Whys 진단 (실패 시만)

증상에서 시작해 5번 "왜?":

```
[증상] <실패한 체크리스트 항목 또는 범주>

[왜 1] ...
[왜 2] ...
[왜 3] ...
[왜 4] ...
[왜 5] ...  ← 또는 결정 가능한 지점에서 stop
```

---

## 5. 라우팅 결정 (3분류 — 4번째 옵션 금지)

| 라우팅 | 조건 | 다음 단계 |
|---|---|---|
| **(1) 시나리오 오류** | Job Story·Example·GWT 표현이 본인 의도와 다름 | `/scenario-first-throw` 갱신 (같은 NNN) 또는 `/scenario-first-expand --rerun NNN` |
| **(2) Spec 누락** | 시나리오는 OK인데 spec에 빠진 슬롯 (PRD/ARCH/NONFUNC/OPS) | `/scenario-first-spec --rerun NNN` |
| **(3) 구현 오류** | 시나리오·spec OK인데 구현이 어긋남 | `/scenario-first-goal --resume NNN` |

**선택**: ( ) (1)  ( ) (2)  ( ) (3)

**근거**: <어떤 5 Why 단계가 결정 근거인가>

---

## 6. 결과

```yaml
review_status: passed | failed
routed_to: throw | expand | spec | goal | (none)
reviewed_at: <ISO8601>
total_score: <합계>/12
evidence_count: <첨부 개수>
```

`expanded/NNN-*.md` frontmatter 갱신:
```
review_status: <위 값>
routed_to: <위 값>
```

성공이면 → STATUS.md 의 누적 게이트 풀에 NNN 추가, 다음 backbone 슬라이스 throw 안내.
실패면 → 라우팅 명령 실행.

---

## 금지

- evidence 0개로 passed 표시 (룰: passing_requires_evidence)
- 6범주 사전 평가 일부 생략
- 5 Whys 5번 다 안 하고 1~2번에서 멈추기
- 라우팅 4번째 옵션 ("그냥 둬") 만들기
- Claude 가 본인 사용 단계 시뮬레이션
