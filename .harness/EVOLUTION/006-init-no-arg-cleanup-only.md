---
id: 006
slug: init-no-arg-cleanup-only
date: 2026-05-20
status: applied
applied_commit:
  sfd: be7c2cc
risk_smell: none
---

# 006 — init 을 무인자 단일 정리 동작으로 축소 (복사 모드·B/C·인자 전부 제거)

## 1. 변경 (before/after)

**Before:**
- init 이 5개 동작: 무인자(복사) / `--from-template`(정리) / `--force` / `--dry-run` / `--check`.
- 무인자 = `$SCENARIO_FIRST_HOME` 에서 whitelist 복사 (빈 디렉터리 시작용, README 방법 B).
- README 에 A(template) / B(빈 디렉터리 init 복사) / C(수동 cp) 3개 진입 + "SFD 갱신 받기"(`--check`/`--force`) 섹션.

**After:**
- init = **무인자 단일 동작.** `/scenario-first-init` = clone 정리: placeholder 치환 + `.env.scenario` 생성 + E2E 결정 + SFD 메타(README·자기 ADR) 제거 + git commit.template. 멱등.
- `--from-template`/`--force`/`--dry-run`/`--check` 전부 제거. 복사 모드 제거.
- README: B/C + "갱신 받기" 섹션 삭제. A(template clone) 단일. init 은 무인자 선택 정리.
- 부수 정합: AGENTS §2 표 0번 init 설명 "복사" → "정리", sfd-architect 보호 대상 "init whitelist" → "init 정리 흐름".

## 2. 왜

사용자 결정 2건:
1. "기존 레포에 얹는(retrofit) 경우는 스킬이 필요없는 경우로 보임 — 지금 고려하지 말 것." → init 의 복사 모드는 retrofit/빈 디렉터리 전용이었으므로 존재 이유 소멸. B/C 도 동반 제거.
2. "인자 없는 init 이 디폴트 동작. 불필요한 인자 만들지 마." → ADR 005 가 만든 `--from-template` 는 불필요 — 그 정리 동작이 곧 무인자 디폴트여야 함.

template 이 THE 진입 경로(#001)이고 clone 사본은 시드를 이미 가지므로, init 의 역할은 "복사" 가 아니라 "clone 의 SFD 색 벗기기" 하나로 수렴. 인자 5개는 복사/갱신 모델의 잔재였고, 그 모델(retrofit·update-propagation)을 사용자가 보류하면서 인자도 같이 사라짐.

## 3. 영향 범위 grep 결과

```
skills/scenario-first-init/SKILL.md   # 전면 재작성 — 무인자 정리 1동작, 복사/whitelist/인자 절 제거
README.md                             # '## 새 프로젝트 시작' B/C/갱신 섹션 삭제, init 무인자로; '## 다음' --from-template→init
AGENTS.md:52                          # §2 표 0번 init 설명 복사→정리
.claude/agents/sfd-architect.md:19    # 보호 대상 'init whitelist' → 'init 정리 흐름'
```

적용 후 재grep:
```bash
grep -rn "from-template\|시드 복사\|whitelist\|SCENARIO_FIRST_HOME" . --include='*.md' | grep -v EVOLUTION/00
# 기대: AGENTS 의 --rerun/--force(별개 룰 3.2), push --force 금지 외 0
```

## 4. 보호 룰 점검

- [x] review 자동화 거부 — OK
- [x] cycle lock — OK (init 은 cycle 과 무관)
- [x] 누적 풀 진입 조건 — OK
- [x] 단방향 파이프라인 — OK
- [x] evidence 없이 passed 금지 — OK
- [x] 자동 트리거 금지 — OK (init 여전히 수동, 이젠 무인자)
- [x] Job Story 페르소나 금지 — OK
- [x] EVOLUTION ADR 의무 — OK (본 ADR)

위반 0. 기능 축소(복사·update-propagation·인자)지만 retrofit/update 를 사용자가 보류한 결과라 의도적.

## 5. 정당성 평가

- [x] 부담 감소 — 진입 3경로+인자 5개 → 단일 경로(template) + 무인자 init. 인지 부하 최소.
- [x] 거울 정합도 향상 — "template 이 THE 경로" 라는 #001 정체성에 init 의 형태까지 수렴. 말과 도구 일치.
- [ ] 검증 가능성 — 해당 약함.

risk_smell: none.

## 6. 적용 commit

| 레포 | atomic commit 단위 | hash |
|---|---|---|
| SFD | "refactor: init 을 무인자 단일 정리로 축소 (복사 모드·B/C·인자 제거) — ADR 006" | `be7c2cc` |

## 7. 검증 체크리스트 (적용 후)

- [ ] init SKILL 에 인자 표 없음 — `/scenario-first-init` 단일, 본문에 복사/whitelist/`$SCENARIO_FIRST_HOME` 없음
- [ ] README '새 프로젝트 시작' = template clone 단일 + 무인자 init 선택 정리, B/C/갱신 섹션 없음
- [ ] AGENTS §2 표 0번 = "정리", sfd-architect 보호 대상 = "init 정리 흐름"
- [ ] `grep -rn "from-template" . | grep -v EVOLUTION` → 0

## 8. 부수 효과 / 미해결

- **update-propagation 보류**: SFD 가 개선돼도 옛 프로젝트가 새 스킬 버전을 받는 경로가 이제 없음(복사/`--force` 제거). retrofit 과 함께 보류 — 필요해지면 별도 ADR 로 재설계(예: SFD 를 git remote 로 추가해 cherry-pick, 또는 전용 sync 도구).
- ADR 003~005 §8 의 "E2E 결정 로직 init/goal 중복" 은 여전 — 이제 init(정리) + goal 0번 2곳. 공통 추출 다음 ADR 후보.
- `--dry-run` 제거로 init 의 파일 삭제(SFD README·ADR) 미리보기 없음 — 단 삭제 대상이 SFD 자신 것으로 예측 가능하고 멱등이라 위험 낮음.
