# 프로젝트 값 찾기

feature-loop 스킬은 설정 파일을 두지 않는다. 필요한 값은 **지금 열린 프로젝트의 파일에서** 찾는다.
플러그인이 어디서 켜지는지는 설치 범위(user·project·local)가 정한다.

찾은 값은 어디에도 저장하지 않는다. 매번 프로젝트에서 다시 읽는다.

## 앱 폴더 `<appDir>`

앱 설정(`app.json`·`app.config.*`)이나 네이티브 프로젝트가 있는 폴더다. 의존성으로 찾지 않는다 —
모노레포의 공유 패키지도 `react-native` 를 의존성으로 가진다.

```bash
git ls-files | grep -E '(^|/)(app\.json|app\.config\.(js|ts)|ios/[^/]+\.xcodeproj/project\.pbxproj|android/app/build\.gradle)$'
```

- 하나면 그것이다
- 여럿이면(모노레포) 지금 작업 중인 파일·요청 내용으로 고른다. 프로젝트 문서에 쓰지 않는 앱이
  적혀 있으면 뺀다. 그래도 애매하면 묻는다

## 앱 ID `<appId>`

**기기에 실제로 깔린 앱이 기준이다.** 같은 앱의 변형(dev·staging·prod)이 여럿이면 ID 가 다르다.

1. 후보를 프로젝트에서 찾는다
   - Expo — `app.json` 의 `expo.ios.bundleIdentifier`·`expo.android.package`.
     `app.config.js|ts` 는 환경 변수에 따라 값이 바뀔 수 있으므로 분기를 읽는다
   - 네이티브 — `ios/*.xcodeproj/project.pbxproj` 의 `PRODUCT_BUNDLE_IDENTIFIER`,
     `android/app/build.gradle` 의 `applicationId`(+ flavor 의 `applicationIdSuffix`)
2. 기기에 깔린 것과 맞춘다

   ```bash
   xcrun simctl listapps <udid> | grep -E 'CFBundleIdentifier' | grep -iE '<후보 일부>'
   adb -s <serial> shell pm list packages | grep -iE '<후보 일부>'
   ```

   깔린 후보가 하나면 그것이다. 여럿이거나 없으면 묻는다

## 실행 명령 (앱을 띄울 때)

`<appDir>/package.json` 의 `scripts` 에서 찾는다 — Metro(`start`), iOS(`ios`), Android(`android`).
루트 `package.json` 에 앱으로 넘기는 스크립트가 있으면 그것을 써도 된다.

패키지 매니저는 lockfile 로 정한다 — `pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, `package-lock.json` → npm.
모노레포에서는 그 매니저의 필터로 앱을 지정한다(예: `pnpm --filter <앱 이름> start`).

스크립트가 무엇을 하는지 읽고 쓴다. 빌드 명령은 수십 분 걸리므로, 확실하지 않으면 실행 전에 확인받는다.

**Metro 포트**는 기본 8081 이다. `start` 스크립트에 `--port` 가 있으면 그 값이다. 아래에서 `<port>`.

## 작업 문서 폴더·테스트 기준

프로젝트의 `CLAUDE.md`·`AGENTS.md` 에 적혀 있으면 그것을 따른다.

- 작업 문서 폴더 — 없으면 기존 `docs/specs/` 같은 폴더를 찾고, 그래도 없으면 위치를 묻는다
- 테스트 기준(무엇을 jest 로, 무엇을 레포에 남기나) — 없으면 각 스킬의 기본 표를 쓰고,
  레포에 남길지는 묻는다

## 프로젝트가 직접 갖는 것

플러그인이 찾거나 만들 수 없다. 없으면 만드는 법을 안내한다.

- `<appDir>/.maestro/` 플로우 — `${CLAUDE_PLUGIN_ROOT}/skills/verify-screen/templates/` 로 시작해 앱에 맞게 채운다
- `<appDir>/.maestro/.env` 테스트 계정 — 각자 만든다(gitignore)
