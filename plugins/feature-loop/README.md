# feature-loop

작업 문서(스펙) → 구현 → 검증(jest·maestro) 루프를 에이전트가 돌리게 하는 Claude Code 플러그인.
React Native·Expo 같은 모바일 앱 프로젝트용.

| 스킬 | 하는 일 |
|---|---|
| `feature-spec` | 시안·기획으로 작업 문서를 쓰고 항목별 검증 층(jest·maestro·실기기)을 정한다. 승인 전까지 멈춘다 |
| `feature-verify` | 작업 문서의 검증 표대로 jest·maestro 를 돌리고 근거가 있는 항목만 체크한다 |
| `verify-screen` | 시뮬레이터·에뮬레이터 화면을 maestro 로 조작·확인한다 |

흐름: `feature-spec` → 구현(프로젝트에 시안 대조 스킬이 있으면 직후에 부른다) → `feature-verify`.

## 설치

```bash
claude plugin marketplace add zoeyul/claude-plugins
claude plugin install feature-loop@zoeyul-plugins
```

레포 전원에게 등록하려면 그 레포에서 `--scope project` 로 추가하고 생성된 `.claude/settings.json` 을
커밋한다. 폴더를 신뢰한 사람에게 마켓플레이스가 등록된다.

GitHub SSH 키가 없으면 `CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1` 로 HTTPS 로 받는다.

수정 사항을 받으려면 `version` 을 올린다. 같은 버전이면 설치한 사람은 캐시된 사본을 계속 쓴다.

## 프로젝트에 붙이기

설정 파일은 없다. 플러그인이 켜지는 범위는 설치 범위(user·project·local)가 정하고, 앱 폴더·앱 ID·
실행 명령·작업 문서 위치는 스킬이 프로젝트 파일(`app.json`·`package.json`·`CLAUDE.md` 등)과
기기에서 찾는다 — [references/project.md](references/project.md). 애매하면 그 자리에서 묻는다.

프로젝트가 직접 갖춰야 하는 것은 maestro 검증용뿐이다.

1. **maestro 설치** — `<plugin>/skills/verify-screen/scripts/setup-e2e.sh` (JVM 기반, 각자 설치)
2. **`.maestro/`** — `<appDir>/.maestro/` 에 `verify-screen/templates/` 의 `config.yaml`, `common/go-home.yaml` 을 두고 채운다
3. **테스트 계정** — `<appDir>/.maestro/.env` 에 본인 dev 계정. 다른 곳에서 쓰지 않는 비밀번호만

   ```
   MAESTRO_TEST_EMAIL='...'
   MAESTRO_TEST_PASSWORD='...'
   ```

4. **gitignore** — `.maestro/.env`, `.maestro/reports/`

### 로그인 서브플로우

앱마다 로그인 화면이 달라 템플릿을 두지 않는다. `<appDir>/.maestro/common/login.yaml` 을 프로젝트에서 만든다.

- 로그인 화면은 딥링크로 열어 어느 화면에서 불러도 같은 곳에서 시작한다
- 값은 `${MAESTRO_TEST_EMAIL}`·`${MAESTRO_TEST_PASSWORD}` 로만 쓴다
- 마지막 단언은 "로그인 화면이 사라졌다" 와 "로그인 실패 알림이 없다" 를 함께 본다 — 실패 알림이
  로그인 화면을 가려도 앞의 단언은 통과한다
- 선택자 문자열은 계층에서 복사한다(`verify-screen` 규칙)

## 회귀 묶음

레포에 남기는 maestro 플로우는 핵심 경로만, `tags: [regression]` 을 붙인다. 마이그레이션·배포 전에 돌린다.

```bash
<plugin>/skills/verify-screen/scripts/e2e.sh <appDir> --device <udid> \
  test .maestro --include-tags regression
```

## 알아둘 것

- **검증은 maestro CLI 로 한다.** maestro MCP 는 앱·시뮬레이터가 재시작되면 끊기고 사람이 `/mcp` 로
  재연결해야 한다. MCP `run` 응답에는 `MAESTRO_*` 값이 평문으로 찍힌다
- **외부 연동 확정 동작(결제·예약·호출·환불)은 플로우에서 누르지 않는다.** dev 에서도 외부로 요청이 나간다
- **앱을 재시작해 상태를 지우지 않는다.** 플로우가 시작 상태를 가정하지 않게 쓴다
