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
  - status: applied-on-branch (`harness/status-section-pollution-fix`, sfd-architect 검토 완료 → 마커+awk 타게팅 삽입으로 적용, 사람 diff 확인 후 푸쉬 대기. 근본 원인=모든 append가 파일 끝=누적 풀 섹션으로 떨어짐)

- [2026-05-21 / bookpile meta] 템플릿으로 개발하다 보면 템플릿 자체 피드백이 생기는데, 그걸 프로젝트와 분리해 템플릿 레포로 보내는 내장 채널이 없었음 — 이 인박스 자체가 그 대응.
  - 일반화 근거: clone은 git history를 미상속하므로 다운스트림에서 얻은 하네스 교훈이 업스트림 템플릿으로 환류될 경로가 구조적으로 없다. 모든 clone 사용자가 동일하게 겪는 메타 갭.
  - 제안 방향: 이 `.sfd-meta/FEEDBACK-INBOX.md` 채널을 템플릿에 내장(현재 작업) + AGENTS.md/README에 "하네스 피드백은 sfd-architect 게이트 전 단계로 여기 누적" 한 줄 안내 후보. sfd-architect 트리거 문서에 인박스 연계 검토.
  - status: candidate

- [2026-05-21 / bookpile (개발 중 [tpl]) · 2026-05-22 분해됨] MVP가 아이디어의 구현가능성을 증명한 뒤(0→1, walking skeleton+backbone), "실제 쓸 수 있는 서비스"로 만드는 단계 — UI/UX를 바꾸고 **상세 동작을 정확히 정의**하는 일 — 이 현재 구조에서 갈 곳이 없다. 처음엔 "post-MVP 미세조정에 시나리오가 과하다"로 잡았으나 사용자 논의로 분해한 결과, 진짜 갭은 cosmetic이 아니라 **"이미 통과한 시나리오의 해상도를 올리는 연산"의 부재**였다. MVP 시나리오는 저해상도(정상 케이스만)이고, 서비스는 고해상도(0건·소스다운·동률·품절·로딩·에러까지 정밀 정의)가 필요한데, throw는 "새 backbone"용이지 "기존 걸 깊게"가 아니라 던질 새 게 없다. 단방향+통과시잠금 구조는 시나리오를 *세우는* 데 최적화돼 *키우는* 연산이 없다.
  - 일반화 근거: 모든 clone은 MVP 증명 후 서비스화로 진입하고, 그때 "MVP가 뭉갠 디테일"이 우수수 쏟아진다(도메인 무관). 이 디테일은 새 기능이 아니라 같은 Job Story의 정밀화라 기존 throw에 안 맞는다. candidate C(잠긴 통과 시나리오 ↔ 새 시나리오 회귀 충돌)는 별개 버그가 아니라 **이 depth 연산 부재의 증상**이다 — 깊게 파는 동작이 없어 새 요구가 잠긴 것과 충돌.
  - 분해된 모델 (post-MVP 작업의 3축):
    - **breadth (새 기능)** = 기존 `throw` 그대로.
    - **depth (있는 걸 정밀하게)** = 신규 `deepen` — 기존 NNN 재진입해 Rules/Examples(GWT)를 **추가**. 핵심 속성:
      - **배치**: 한 번에 여러 항목(0건·소스다운·동률…)을 같이 정의. 단일 cycle 아님 → `single_active_cycle`(1 NNN 잠금)에서 면제 필요.
      - **포착≠처리 분리**: 디테일은 MVP 만드는 *중에* 튀어나오므로 멈추지 말고 `.harness/backlog.md`에 target NNN 달아 한 줄 던져둠. 서비스화 때 `deepen`이 backlog를 배치로 끌어와 태움.
      - **in-place 스키마**: example을 기존 시나리오 파일에 누적(버전/자식 001.1·001.2…는 배치 입력 시 폭발하므로 기각). 풀은 현재 example 집합 반영.
    - **cosmetic (외관만)** = 신규 `tweak` — 행동 델타 없는 UI/UX. 게이트 = 기존 풀 green 유지 + 수동 시각 승인. 새 GWT/NNN 없음. snapshot은 "변하길 원함"이라 자동 게이트가 아니라 수동 review로 본질이 뒤집힘에 주의.
  - 안전 원칙 (둘을 잠긴 풀과 양립시키는 열쇠): **단조성** — deepen은 example/제약을 *추가*만(약화 없음) → 게이트가 빡세지기만 → 잠긴 것 회귀 불가. tweak은 렌더링만 바꿈(행동 불변) → 풀 green이 안전망. 둘 다 기존 풀에 단조라 단방향+잠금 척추를 안 부순다.
  - 후속 sfd-architect 정식 게이트에서 정할 미결 (영향 grep + 보호 룰 점검 대상):
    1. deepen 배치 실패 입자: 부분 커밋(green 항목만 잠금 + 깬 것만 격리/재작업·throw 승격) vs 올-or-넛싱(하나 깨지면 배치 전체 보류).
    2. cycle lock 완화 형태: "throw 1개 OR deepen 배치 1개"로 재정의 — throw와 deepen-배치 동시 활성 허용 여부.
    3. backlog 항목 포맷: deepen 대상이 되려면 "어느 NNN을 깊게"라는 target 태그 규율 추가.
    4. tweak 게이트 2(시각)의 인프라: init(0)이 정한 E2E가 Playwright면 screenshot diff로 흡수, 아니면 순수 수동.
  - status: **3축 전부 구현됨** (2026-05-22, sfd-architect 룰 3.9 게이트 2회 통과). depth=`scenario-first-deepen`(룰 3.10, single_active_cycle 확장, deepen_monotonic, spec 보강 경로, 배치 부분커밋) + cosmetic=`scenario-first-tweak`(룰 3.11, 게이트1=기존 풀 green 재사용·게이트2=시각 evidence, lock 미점유). 남은 후속 candidate: (a) deepen 배치 부분커밋의 commit-attribution 머신 검증(enforcement=blocking 승격 시), (b) tweak 표면 커버리지 hard block(표면↔테스트 매핑 생기면 — 현재 soft warn).
