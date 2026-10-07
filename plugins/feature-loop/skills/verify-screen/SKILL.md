---
name: verify-screen
description: >
  시뮬레이터·에뮬레이터에서 실제 화면을 maestro 로 조작하며 검증한다. 화면을 읽고,
  탭·입력·스크롤하고, 결과를 확인한다. "화면에서 확인해줘", "눌러봐", "이 기능 동작하는지 봐줘",
  "실제로 되는지 검증해줘" 같은 요청에 호출한다.
---

# 화면 검증 (Maestro)

이 스킬은 **떠 있는 앱을 조작하고 확인한다.** 앱 빌드·실행은 프로젝트의 앱 실행 스킬이나
문서가 있으면 그것을 따른다.

## 프로젝트 값

`<appDir>`·`<appId>` 는 `${CLAUDE_PLUGIN_ROOT}/references/project.md` 대로 프로젝트와 기기에서 찾는다.

`<appDir>/.maestro/` 구조(처음이면 `${CLAUDE_SKILL_DIR}/templates/` 를 복사해 시작한다):

```
<appDir>/.maestro/
├── config.yaml          # 하위 폴더 플로우 탐색, common/ 제외
├── common/              # runFlow 로 부르는 서브플로우 (출발점·로그인)
├── <기능>/<flow>.yaml   # 회귀 묶음 플로우 (tags: [regression])
├── .env                 # 테스트 계정 — gitignore
└── reports/             # 실행 리포트 — gitignore
```

## 전제 — maestro 설치

```bash
command -v maestro || ${CLAUDE_SKILL_DIR}/scripts/setup-e2e.sh
```

없으면 **설치를 안내하고 멈춘다.** 대신 실행하지 않는다 — 홈 디렉터리와 셸 설정을
건드리는 설치라 사용자가 결정할 일이다.

npm 패키지가 아니라 JVM 기반이라 devDependency 로 걸 수 없다. (npm 의 `maestro` 는
AWS Step Functions 용 다른 패키지이고 `bin` 이름이 같아 오히려 가린다.)

## CLI 와 MCP

**검증은 CLI 로 한다.** CLI 는 실행마다 드라이버를 새로 띄워, 앞 실행이 끊겨도 다음 실행이
선다. 사람 개입 없이 루프가 돈다.

MCP(`mcp__maestro__*`)는 사람이 옆에서 탐색할 때만 쓴다.

Maestro MCP 서버는 기기별 세션을 캐싱하면서 재생성 경로가 없다. 시뮬레이터가 재시작되거나
다른 도구가 같은 러너 앱을 띄우면 그 기기로 가는 이후 호출이 전부 실패하고, 서버를 통째로
재시작해야 풀린다. 드라이버 포트도 하드코딩이라 시뮬레이터가 여럿이면 엉뚱한 기기를 잡는다.

끊긴 MCP 는 **사람이 `/mcp` 로 재연결해야 한다.** 에이전트는 되살리지 못한다. 한 기기에서
MCP 와 CLI 를 번갈아 쓰지 않는다.

### 실행

```bash
set -o pipefail
${CLAUDE_SKILL_DIR}/scripts/e2e.sh <appDir> --device <udid> test <flow>.yaml 2>&1 \
  | sed -E 's/^(.*Input text).*\.\.\. /\1 [masked]... /'
echo "exit=$?"
```

`e2e.sh` 는 `<appDir>/.maestro/.env` 를 올리고 maestro 를 실행한다. `test` 면 HTML 리포트를
`<appDir>/.maestro/reports/` 에 남긴다. 리포트를 남기면 콘솔에는 요약만 나오므로 단계별 결과는
`~/.maestro/tests/<최신>/maestro.log` 에서 본다.

결과를 `COMPLETED|FAILED` 로만 거르지 않는다. 드라이버가 끊기면 FAILED 없이
`Device became unreachable` 로 끝난다 — 종료 코드와 에러 줄을 함께 본다.

### 테스트 계정

플로우는 `${MAESTRO_TEST_EMAIL}`·`${MAESTRO_TEST_PASSWORD}` 처럼 `MAESTRO_` 접두 변수로 쓴다
(maestro 는 이 접두의 셸 변수만 받는다). 값은 각자 `<appDir>/.maestro/.env` 에 넣는다(gitignore).
다른 곳에서 쓰지 않는 dev 전용 비밀번호만 넣는다. 앱 `.env` 에 넣지 않는다 — 앱 번들에 실릴 수 있다.

단계 로그의 `Input text` 줄에 값이 찍힌다. 가려서 본다(위 `sed`).

### 화면 보기

```bash
xcrun simctl io <udid> screenshot <path>.png          # iOS 스크린샷 → Read 로 본다
adb -s <serial> exec-out screencap -p > <path>.png    # Android
maestro --device <udid> hierarchy --compact           # 계층 (선택자 문자열 복사용)
```

## 핵심 규칙

### 화면 파악은 스크린샷, 선택자는 계층

지금 화면이 어떤 상태인지는 **스크린샷으로 먼저 본다.** 조작 전에 한 번, 결과가 예상과
다르면 플로우를 다시 돌리기 전에 한 번.

계층으로는 잘 보이지 않는 것이 많다.

- 앱 밖 오버레이 — 시스템 alert, 비밀번호 저장 창. 화면을 가려도 앱 계층에 나오지 않을 수 있다
- 입력칸에 들어간 값 — iOS 계층에 나오지 않는다
- 토글·선택 상태가 실제로 바뀌었는지, 가림·겹침 같은 모양

계층은 **선택자 문자열을 복사할 때** 쓴다(아래 절). 둘이 다르면 화면을 믿는다 —
계층에 없는 것이 화면에 보이면 앱 밖 오버레이로 보고 계층을 더 뒤지지 않는다.

### 플로우는 시작 상태를 가정하지 않는다

플로우는 연달아 몇 번을 돌려도 같은 결과여야 한다. 앱을 재시작해 상태를 지우지 않는다 —
실사용처럼 세션을 이어 가야 상태가 쌓여 생기는 문제가 드러난다. 대신 플로우가 상태를 가정하지 않는다.

1. 정해진 출발점에서 시작한다 — `runFlow: ../common/go-home.yaml`
2. 화면 안의 요소는 위치를 가정하지 않고 찾은 뒤에 누르거나 단언한다 — `scrollUntilVisible`.
   탭 화면은 마운트가 유지돼 이전 스크롤이 남으므로, 위쪽 요소로 먼저 올린 뒤 아래로 찾는다

딥링크는 출발점으로 되돌리는 준비 단계에만 쓴다. 검증하려는 경로는 탭·버튼을 눌러 간다.

### 외부 연동 확정 동작은 누르지 않는다

결제·예약·호출·환불처럼 dev 에서도 외부 시스템에 요청이 나가는 버튼은 누르지 않는다.
확정 화면이 보이는 것까지만 단언한다.

### 검증하려던 상태를 날리지 않는다

(Expo dev client·React Native) 번들만 다시 올리면 될 때는 Metro 에 리로드를 보낸다.
세션도 Metro 연결도 유지된다.

```bash
curl -X POST http://localhost:8081/reload
```

무엇을 잃는지로 구분한다.

| | 잃는 것 |
|---|---|
| `/reload` | 없음 |
| `simctl terminate` + `launch`, `launchApp` | 메모리 상태 — **로그인 세션** |
| `clearState: true` | 저장소 + dev client 가 기억하는 **서버 주소** (Expo 런처로 떨어진다) |

로그인이 필요한 검증에서 앱을 다시 띄우면 매번 로그인부터 해야 한다. 그걸 모르고
조작하면 "토큰이 복원되지 않는다", "세션이 만료된다" 처럼 보이는데 **검증하느라 만든 상태다.**
앱 버그로 보고하기 전에 이것부터 의심한다.

### `COMPLETED` 는 성공이 아니다

Maestro 는 명령 전송에 성공하면 `COMPLETED` 를 낸다. **실제로 의도한 일이 일어났는지는
별개다.** 반드시 다음 중 하나로 확인한다.

```yaml
- tapOn: "<텍스트>"
- assertNotVisible: "<사라져야 할 것>"   # 또는
- assertVisible: "<나타나야 할 것>"
```

단언으로 잡기 어려운 것(토글 상태, 가림, 오버레이)은 스크린샷으로 확인한다.

`tapOn: point:` 는 계층을 우회해 **틀린 좌표에도 항상 COMPLETED** 를 낸다. 계층에 있는 요소는
텍스트로 지정한다. **계층에 없는 요소에만** 쓴다(앱 밖 오버레이 등). 누르기 전 스크린샷에서
좌표를 비율로 잡고(`"50%,62%"`), **누른 뒤 스크린샷으로 결과를 확인한다.**

### 선택자 문자열은 계층에서 복사한다

추측해서 쓰지 않는다. 먼저 읽는다.

```bash
maestro --device <udid> hierarchy --compact | grep -oE 'accessibilityText=[^;]{1,40}' | sort -u
```

- **라벨은 `text` 가 아니라 `accessibilityText` 에 있다**(iOS). `text` 만 보면 "계층이 비었다" 고 오판한다
- **유니코드 문자를 그대로 쓴다.** 예: `Don’t Allow` 의 아포스트로피는 U+2019 다. ASCII `'` 로 쓰면 못 찾는다
- **`text:` 는 full-string regex 다.** 부분 문자열은 매치되지 않는다. 전체 문자열을 쓰거나 `"앞부분.*"`
  처럼 앵커를 건다. `.` 은 줄바꿈과 맞지 않으므로 여러 줄 라벨은 `[\\s\\S]*` 로 받는다.
  `?`·`[`·`(` 같은 정규식 기호는 이스케이프한다
- **`accessibilityText` 는 선택자가 아니다.** 넘길 때는 `text:` 로 매핑한다
- **같은 문자열이 여러 곳에 있으면**(탭 이름과 메뉴 항목 등) 위치 관계(`below`·`leftOf`)나 그 화면에만
  있는 요소로 구분한다. 화면 제목이 같은 서로 다른 화면도 그 화면에만 있는 요소로 단언한다
- **헤더 뒤에 가려진 요소도 "보인다" 로 잡힌다.** 누르기 전 `scrollUntilVisible` 에 `centerElement: true`

### 시스템 alert

iOS 권한 요청(알림·ATT) 같은 시스템 alert 는 앱이 아니라 springboard 소속이다.

```yaml
appId: com.apple.springboard
---
- tapOn: "Don’t Allow"
```

`simctl privacy` 로는 notifications·tracking 을 끌 수 없다(`Operation not permitted`).
Android 권한 창은 앱 계층에서 바로 누를 수 있다.

## 절차

1. **본다** — 스크린샷으로 지금 화면 상태를 파악한다
2. **선택자를 읽는다** — 누를 것·단언할 것의 문자열을 계층에서 복사한다
3. **조작한다** — 플로우를 임시 디렉터리에 쓰고 `e2e.sh` 로 돌린다
4. **확인한다** — `assertVisible`/`assertNotVisible`. 결과가 이상하면 다시 돌리기 전에 스크린샷
5. **보고한다** — 통과·실패를 근거(요소·스크린샷)와 함께

레포에 남길 플로우가 아니면 임시 디렉터리에 쓴다. 회귀 묶음에 넣을 핵심 경로만
`<appDir>/.maestro/<기능>/` 에 `tags: [regression]` 을 붙여 둔다.

## 자주 걸리는 것

| 증상 | 원인·대응 |
|---|---|
| 계층에 앱 요소가 거의 없음 | 앱 밖 오버레이가 가리고 있다. 스크린샷으로 무엇인지 본다 |
| 첫 화면이 안 뜸 | (dev 빌드) 번들을 받는 중. `extendedWaitUntil` 로 기다린다 |
| dev 메뉴(`Reload`·`Open JS debugger`)가 보임 | dev 메뉴가 열려 있다. 닫기 버튼 문자열을 계층에서 읽어 닫는다 |
| 새로 설치한 앱에 알림 권한·dev client 안내가 뜸 | 첫 실행 상태다. 검증 전에 닫는다 |
| `launchApp` 이 FAILED | 다른 기기를 집었다. 기기가 여러 개면 `--device <udid>` 로 지정한다 (`maestro list-devices`) |
| iOS `launchApp` 이 `SBMainWorkspace` 거부 | 앱 바이너리 아키텍처가 안 맞는다. `lipo -archs <app>/<binary>` 로 확인한다 |
| 요청이 안 나가거나 데이터가 비어 보임 | **먼저 설치 상태를 의심한다.** 같은 앱의 변형(dev·staging 등)이 여럿 깔려 있으면 어느 앱을 조작했는지 알 수 없다. `<appId>` 하나만 남긴다 |
| 로그인 뒤 iOS `Save Password?` 창이 화면을 가림 | 앱 계층에 안 나온다. 시뮬레이터 설정 › General › AutoFill & Passwords 에서 `AutoFill Passwords and Passkeys` 를 끄면 뜨지 않았다(1회 확인). 이미 떠 있으면 스크린샷으로 좌표를 잡아 `Not Now` 를 누른다 |
| `Connection refused` / `DeviceUnreachableException` / `device offline` | 드라이버·기기 연결이 끊겼다. 기기 상태를 확인하고 다시 실행하면 CLI 가 드라이버를 새로 띄운다 |

## 하지 않을 것

- `COMPLETED` 만 보고 성공이라고 보고하지 않는다
- 계층에 있는 요소를 `tapOn: point:` 로 누르지 않는다
- 계층에서 확인하지 않은 문자열로 `assertVisible` 하지 않는다
- 실패를 "도구가 안 된다" 로 결론 내기 전에 문자열·appId 를 먼저 의심한다
- 계층에 없다고 화면에 없다고 결론 내지 않는다 — 스크린샷을 먼저 본다
- 검증하느라 만든 상태(재시작으로 날아간 세션 등)를 앱 버그로 보고하지 않는다
