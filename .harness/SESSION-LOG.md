# SESSION-LOG — 세션 단위 작업 로그

> **STATUS.md 와 차원이 다름**:
> - STATUS.md = cycle (NNN) 단위 진행
> - SESSION-LOG.md = 세션 단위 (한 세션에 여러 cycle 만질 수도, 한 cycle 이 여러 세션 걸칠 수도)
>
> 세션 종료 워크플로 2단계에서 한 항목 append. 최신이 위.

---

## 세션 양식

```markdown
### 세션 NNN  (<YYYY-MM-DD>  <에이전트: Claude Code / codex / cursor / human>)

- 목표: <이 세션에서 진행하려 한 cycle 단계>
- 진행한 cycle: <NNN-list, [stage]>
- 완료: <체크리스트>
- 검증 실행: <./init.sh verify 결과 — PASS / FAIL / skip 사유>
- 수집된 evidence: <REVIEW.md evidence 슬롯 갱신 여부>
- commits: <hash range>
- 갱신된 산출물: <파일 목록>
- 미해결 위험·차단: <목록 또는 (none)>
- 다음 최적 단계: <한 줄>
```

---

## 로그 (최신이 위)

(none yet)
