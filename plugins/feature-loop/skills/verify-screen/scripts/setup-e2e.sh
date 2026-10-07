#!/bin/bash
set -euo pipefail

# Maestro 설치. 이미 있으면 버전만 알리고 끝낸다.
#
# npm 패키지가 아니라 JVM 기반이라 devDependency 로 걸 수 없다. npm 의 `maestro` 는
# AWS Step Functions 용 다른 패키지이고 bin 이름이 같아 설치하면 오히려 가린다.

if command -v maestro >/dev/null 2>&1; then
  echo "✅ maestro 가 이미 설치돼 있습니다 — $(maestro --version 2>/dev/null | head -1)"
  echo "   업그레이드하려면: curl -Ls https://get.maestro.mobile.dev | bash"
  exit 0
fi

echo "▶ Maestro 를 설치합니다 (~/.maestro)..."
curl -Ls "https://get.maestro.mobile.dev" | bash

echo ""
echo "설치가 끝났습니다. PATH 에 없다면 셸 설정에 아래를 넣으세요."
echo '    export PATH="$PATH":"$HOME/.maestro/bin"'
