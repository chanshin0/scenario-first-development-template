# FEEDBACK-INBOX

이 파일은 **이 템플릿(scenario-first-development-template)으로 clone 한 프로젝트들을 실제로 돌리며 나온 "하네스(템플릿 레이어) 피드백 후보"** 를 누적하는 곳이다. 적재 기준은 단 하나 — *clone 전반에 일반화되는가*: 5 스킬·운영 룰·`rules.json`·`.harness/*` layer·`.env.scenario` 스키마·init·`sfd-architect` 등 하네스 본체에 참인 신호만 들어온다. 특정 프로젝트 도메인에만 참인 것은 버린다(애매하면 버린다 — 보수적 기본값=프로젝트). 여기 항목은 전부 `status: candidate` 이며, **이 파일에 적힌 것만으로는 하네스가 바뀌지 않는다**. 실제 변경은 이후 사용자가 `sfd-architect` 정식 검토(영향 grep + 보호 룰 점검 + 정당성 평가) 게이트를 거쳐 결정한다.

---

## 후보 (candidate)

- [2026-05-21 / bookpile 004] goal(4단계) 자동 게이트가 fixture 모드로만 돌아, "외부 API가 응답에 X를 준다"는 가정 버그를 원천적으로 못 잡는다 — fixture seed와 그 seed를 검사하는 E2E가 같은 가정을 공유해 가짜 green이 됨. 004에서 표지·정가가 라이브에 안 떠서 review(5단계)에서야 드러남(001에서도 라이브 어댑터를 review 직전 활성화한 유사 패턴).
  - 일반화 근거: 외부 API·스크레이핑·서드파티 응답에 의존하는 프로젝트라면 어느 clone에서나 fixture 게이트는 자기 전제를 검증할 수 없다. 도메인(알라딘)과 무관한 게이트 설계의 구조적 한계.
  - 제안 방향: `scenario-first-goal` 스킬 또는 `.harness` layer에, expand/spec에 외부 응답 의존 `[추정]`이 있으면 "실제 응답 모양 샘플 → 파서/어댑터 추출" 단위 게이트(네트워크 없이 라이브 추출 로직 검증)를 goal에서 함께 요구하는 절차 후보. judge-rubric 또는 REGRESSION-POLICY에 "외부 가정은 fixture만으로 닫지 말 것" 명문화 후보.
  - status: candidate

- [2026-05-21 / bookpile 003·004] (강점 확인) review(5단계, 본인이 직접 라이브 사용)가 4단계 fixture 게이트가 못 본 결함을 두 번 잡아냄 — 003 도메인 의미 오류(겹침 권수 오정의·정렬 누락), 004 라이브 갭(표지·정가 미구현). 둘 다 5 Whys로 올바른 단계(expand / goal)로 라우팅됨.
  - 일반화 근거: "본인이 직접 사용하는 검증 단계를 자동 게이트와 분리한다"는 review 단계 설계가 자동화가 못 보는 현실 갭을 잡는다는 것은 어느 clone에나 참인 방법론 강점. 도메인 무관.
  - 제안 방향: 변경 후보 아님 — `scenario-first-review` 5단계 분리 설계가 의도대로 작동한다는 긍정 신호로 보존. 후속 변경 검토 시 "5단계 자동화하지 말 것"(AGENTS.md 6 금지)의 근거 사례로 인용 가능.
  - status: candidate

- [2026-05-21 / bookpile 003] goal resume 중 새 시나리오(겹침 정렬)가 이미 통과해 누적 풀에 잠긴 시나리오(001.5.1.2)와 충돌(회귀)했고, "잠긴 시나리오를 건드리지 않고" 새 뷰모드를 분리해 해소함. 방법론에 "새 시나리오가 잠긴 통과 시나리오와 충돌할 때 어떻게 푸나"에 대한 명시 가이드가 없었음.
  - 일반화 근거: 누적 게이트 풀(`review_status: passed`만 진입)은 모든 clone이 cycle을 쌓으며 갖게 되는 구조이고, 새 요구가 잠긴 시나리오와 부딪치는 회귀 충돌은 도메인과 무관하게 반복된다.
  - 제안 방향: `REGRESSION-POLICY.md` 또는 `scenario-first-goal` 스킬에 "잠긴 통과 시나리오와 새 시나리오가 충돌할 때의 해소 절차"(예: 잠긴 시나리오 불변 유지 + 신규 동작을 모드/분기로 분리, 또는 명시적 폐기 절차로 잠금 해제) 가이드 추가 후보.
  - status: candidate

- [2026-05-21 / bookpile 004] 같은 cycle 내에서 throw가 expand 전에 대화로 두 번 재정의됨(검색-책별 → 묶음 3합계 비교 → 단일책 3출처 비교). throw에는 review(1) 라우팅용 `--update`는 있으나, expand 전 throw 반복(throw:refine)이 일급 절차가 아니라 그냥 덮어쓰기였음.
  - 일반화 근거: throw를 expand 전에 다듬는 일은 SoT를 잡는 1단계의 본질적 행위로, 어느 clone에서나 일어난다. `--update`(review 후 라우팅)와 expand 전 refine은 의미가 다른데 후자가 일급 절차로 부재.
  - 제안 방향: `scenario-first-throw` 스킬에 expand 전 반복을 위한 `throw:refine`(또는 동등) 일급 절차 추가 후보 — 백업/STATUS 한 줄 기록 규율을 `--update`와 동일하게 적용. rules.json의 단계 정의에 반영 검토.
  - status: candidate

- [2026-05-21 / bookpile 002·003·004] STATUS.md에 `echo >>`로 append하다 보니 cycle 로그 줄·backup 줄이 "누적 게이트 풀(review_status=passed)" 섹션 안으로 섞여 들어가는 포맷 오염이 반복 발생(현재 STATUS.md에서도 누적 풀 섹션에 throw/backup/goal 로그 줄이 혼입 확인됨).
  - 일반화 근거: STATUS.md 양식과 "5 스킬이 끝에 한 줄 append" 규율은 하네스 layer 자체이며, append를 텍스트로 하는 한 어느 clone에서나 섹션 경계가 무너질 수 있다. 도메인 무관한 양식·규율 마찰.
  - 제안 방향: `.harness/STATUS.md` 양식에 섹션 앵커/머신 검증 추가, 또는 5 스킬의 append를 자유 텍스트 대신 정해진 섹션(Cycle 로그 / 누적 풀 / BACKUPS)에 꽂는 헬퍼·규율로 강제하는 후보. rules.json에 "누적 풀 섹션은 NNN passed 항목만" 검증 룰 추가 검토.
  - status: candidate

- [2026-05-21 / bookpile meta] 템플릿으로 개발하다 보면 템플릿 자체 피드백이 생기는데, 그걸 프로젝트와 분리해 템플릿 레포로 보내는 내장 채널이 없었음 — 이 인박스 자체가 그 대응.
  - 일반화 근거: clone은 git history를 미상속하므로 다운스트림에서 얻은 하네스 교훈이 업스트림 템플릿으로 환류될 경로가 구조적으로 없다. 모든 clone 사용자가 동일하게 겪는 메타 갭.
  - 제안 방향: 이 `.sfd-meta/FEEDBACK-INBOX.md` 채널을 템플릿에 내장(현재 작업) + AGENTS.md/README에 "하네스 피드백은 sfd-architect 게이트 전 단계로 여기 누적" 한 줄 안내 후보. sfd-architect 트리거 문서에 인박스 연계 검토.
  - status: candidate

- [2026-05-21 / bookpile (개발 중 [tpl])] 시나리오-First 파이프라인(Job Story→GWT)은 MVP를 빠르게 세우는 데(=0→1, walking skeleton+backbone) 적합하고 그 목적은 빠르게 달성되지만, MVP 이후 단계 — 이미 동작하는 화면의 UI/UX 미세 조정, 작은 세부 기능 추가·변형 — 에서는 "When 상황, I want 동기, so 결과" + GWT 자동 게이트의 무게가 작업 대비 과해 적절하지 않다. 이 1→n(refinement) 단계를 위한 확장이 필요하다는 신호.
  - 일반화 근거: 모든 clone은 MVP가 서고 review를 통과한 뒤 "이미 있는 동작을 다듬는" 단계로 진입한다. throw→expand→spec→goal→review 5단계는 새 backbone(새 시나리오)을 세우는 데 최적화돼 있어, 기존 시나리오에 매달리지 않는 미세 조정(여백·문구·정렬·인터랙션 디테일)에는 GWT 1:1 매핑이 잘 안 붙고 자동 게이트도 의미가 옅다. 도메인(알라딘/책)과 무관한 방법론의 라이프사이클 갭. 단, "post-MVP에는 시나리오가 부적절"이라는 강한 주장은 [추정] 경량 GWT/시각 회귀로 흡수 가능한 부분과 진짜 갭인 부분이 섞여 있을 수 있어, 후속 검토에서 분해 필요.
  - 제안 방향(후보, 단정 아님): (a) MVP 이후 작은 조정을 위한 경량 트랙 — 예: `throw:tweak`(GWT 강제 없이 변경 의도 한 줄 + 시각/수동 evidence만)을 일급 절차로 추가; (b) UI/UX 미세 조정용 게이트를 GWT E2E 대신 시각 회귀(스냅샷)·수동 review 중심으로 전환하는 `scenario-first-goal` 분기; (c) review(5단계)는 그대로 두되 expand/spec을 "기존 시나리오 변형"일 때 축약하는 모드. 어느 쪽이든 누적 게이트 풀·review_status:passed 진입 조건은 보존 전제. 실제 채택은 sfd-architect 정식 검토(영향 grep + 보호 룰 점검)에서 결정.
  - status: candidate
