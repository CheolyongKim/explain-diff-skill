# explain-diff-skill

Hermes Agent 스킬 두 개를 모아둔 저장소입니다. 코드 diff / 브랜치 / PR을
풍부하고 인터랙티브한 설명으로 정리해 줍니다.

- **explain-diff-html** — 지정한 변경사항을 단일 HTML 파일(배경 · 직관 · 코드 · 퀴즈)
  로 설명합니다. CSS/JS가 내장된 자체 완결형 페이지가 생성됩니다.
- **explain-diff-notion** — 동일한 설명을 Notion 페이지로 만들어 URL을 돌려줍니다.
  (Notion MCP 도구가 필요합니다.)

## 설치

### Windows (PowerShell) — 가장 추천

```powershell
irm https://raw.githubusercontent.com/CheolyongKim/explain-diff-skill/main/install.ps1 | iex
```

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/CheolyongKim/explain-diff-skill/main/install.sh | bash
```

### npm (방법 3)

```bash
npm i -g explain-diff-skill
explain-diff-skill          # 설치 실행
# 또는 npx 로 한 번만:
npx explain-diff-skill
```

세 방법 모두 GitHub에서 `skills/` 디렉토리를 받아 Hermes Agent의 스킬 폴더에
복사합니다. 그 밖의 곳은 건드리지 않습니다.

## OpenAI Codex CLI 에서 사용하기

이 저장소의 스킬은 **Hermes Agent** 전용 형식(`skills/<name>/SKILL.md`)이라서,
Codex CLI는 이걸 그대로 읽지 못합니다. 대신 같은 동작을 하는 **Codex 플러그인**
두 개를 `plugins/` 에 함께 담아 두었고, 이 저장소 자체를 Codex **플러그인
마켓플레이스**로 등록할 수 있습니다.

```bash
# 1) 이 저장소를 Codex 마켓플레이스로 추가
codex plugin marketplace add https://github.com/CheolyongKim/explain-diff-skill.git

# 2) 플러그인 설치
codex plugin add explain-diff-html@explain-diff-skill
codex plugin add explain-diff-notion@explain-diff-skill

# 3) 새 Codex 세션 시작 — 평소처럼 자연어로 요청
```

- `explain-diff-html` : 변경사항을 단일 HTML 파일로 설명합니다.
- `explain-diff-notion` : Notion 페이지로 정리합니다. **Notion MCP 서버가 별도로
  필요**합니다 — `codex mcp add` 로 Notion MCP 서버를 먼저 연결하세요. (플러그인이
  인증 정보나 MCP 서버를 번들로 받지 않습니다.)

마켓플레이스 스냅샷을 최신으로 갱신하려면:

```bash
codex plugin marketplace upgrade explain-diff-skill
```

## 사용법

설치 후 Hermes Agent를 재시작(또는 `/skills`)하면 스킬이 로드됩니다. 그러면
평소처럼 자연어로 요청하세요:

- "이 브랜치의 변경사항을 HTML로 설명해줘"
- "이 PR을 Notion 페이지로 정리해줘"
- "diff를 이해하기 쉽게 interactive HTML로 만들어줘"

## 커스텀 설치 위치

기본적으로 Hermes 스킬 폴더를 자동으로 찾습니다. 다른 곳에 설치하고 싶으면
환경변수 `HERMES_SKILLS_DIR`를 지정하세요:

```powershell
$env:HERMES_SKILLS_DIR = 'D:\my-hermes\skills'
irm https://raw.githubusercontent.com/CheolyongKim/explain-diff-skill/main/install.ps1 | iex
```

## 저장소 구조

```
explain-diff-skill/
├── skills/                          # Hermes Agent 스킬 (원본)
│   ├── explain-diff-html/SKILL.md
│   └── explain-diff-notion/SKILL.md
├── plugins/                         # OpenAI Codex CLI 플러그인 (같은 동작)
│   ├── explain-diff-html/.codex-plugin/plugin.json
│   ├── explain-diff-html/skills/explain-diff/SKILL.md
│   ├── explain-diff-notion/.codex-plugin/plugin.json
│   └── explain-diff-notion/skills/explain-diff/SKILL.md
├── .agents/plugins/marketplace.json # Codex 플러그인 마켓플레이스 매니페스트
├── install.ps1      # Windows (irm | iex)
├── install.sh       # macOS / Linux
├── install-node.js  # npm bin 진입점
├── package.json
└── README.md
```

## 라이선스

MIT

