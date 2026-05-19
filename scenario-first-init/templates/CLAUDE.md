# CLAUDE.md

이 레포는 시나리오-First 개발 파이프라인으로 운영된다. 작업 시작 전 [`AGENTS.md`](AGENTS.md) 를 읽고 운영 8룰을 지킨다.

핵심 한 줄:
- SoT = `.scenarios/throws/NNN-*.md` 의 Job Story
- 파이프라인: throw → expand → spec → goal → review (단방향)
- 한 번에 한 cycle (NNN)
- 자동 트리거 금지

자세한 규칙은 [`AGENTS.md`](AGENTS.md), 설계·철학은 별도 레포 [scenario-first-development](https://github.com/chanshin0/scenario-first-development) (방법론 설명서).
