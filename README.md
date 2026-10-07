# claude-plugins

개인 Claude Code 플러그인 마켓플레이스 (`zoeyul-plugins`).

## 설치

```bash
claude plugin marketplace add zoeyul/claude-plugins
claude plugin install <plugin>@zoeyul-plugins
```

GitHub SSH 키가 없으면 `CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1` 로 HTTPS 로 받는다.

## 플러그인

| 플러그인 | 설명 |
|---|---|
| [`feature-loop`](plugins/feature-loop/README.md) | 작업 문서(스펙) → 구현 → 검증(jest·maestro) 루프. 모바일 앱 프로젝트용 |
