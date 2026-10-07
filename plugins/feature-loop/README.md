# feature-loop

작업 문서(스펙) → 구현 → 검증(jest·maestro) 루프를 에이전트가 돌리게 하는 Claude Code 플러그인.
React Native·Expo 같은 모바일 앱 프로젝트용.

| 스킬 | 하는 일 |
|---|---|
| `feature-spec` | 시안·기획으로 작업 문서를 쓰고 항목별 검증 층(jest·maestro·실기기)을 정한다. 승인 전까지 멈춘다 |
| `feature-verify` | 작업 문서의 검증 표대로 jest·maestro 를 돌리고 근거가 있는 항목만 체크한다 |
| `verify-screen` | 시뮬레이터·에뮬레이터 화면을 maestro 로 조작·확인한다 |

## 설치

```bash
claude plugin marketplace add git@github-zoeyul:zoeyul/claude-plugins.git
claude plugin install feature-loop@zoeyul-plugins
```

비공개 레포라 SSH 키가 있어야 한다. `owner/repo` 짧은 이름은 기본 `github.com` 키로 인증하므로
계정이 여럿이면 SSH 별칭 주소로 추가한다.

## 프로젝트에 붙이기

1. **maestro 설치** — `<plugin>/skills/verify-screen/scripts/setup-e2e.sh` (JVM 기반, 각자 설치)
2. **프로젝트 설정** — 루트에 `.feature-loop.json`

   ```json
   {
     "appDir": "apps/<app>",
     "appId": "<bundle id / package name>",
     "specsDir": "apps/<app>/docs/specs",
     "testingGuide": "apps/<app>/docs/testing.md"
   }
   ```

   `testingGuide` 는 선택. 없으면 스킬의 기본 표로 층을 정하고, 테스트를 레포에 남길지는 사람에게 묻는다
3. **`.maestro/`** — `<appDir>/.maestro/` 에 `verify-screen/templates/` 의 `config.yaml`, `common/go-home.yaml` 을 두고 채운다
4. **테스트 계정** — `<appDir>/.maestro/.env` 에 본인 dev 계정. 다른 곳에서 쓰지 않는 비밀번호만

   ```
   MAESTRO_TEST_EMAIL='...'
   MAESTRO_TEST_PASSWORD='...'
   ```

5. **gitignore** — `.maestro/.env`, `.maestro/reports/`

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
