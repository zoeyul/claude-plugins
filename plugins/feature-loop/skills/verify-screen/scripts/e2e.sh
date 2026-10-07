#!/bin/bash
set -euo pipefail

# maestro 를 <appDir>/.maestro/.env 의 테스트 계정(MAESTRO_*)과 함께 실행한다.
# maestro 는 파일을 읽지 않고 MAESTRO_ 접두 셸 변수만 받는다.
#
#   e2e.sh <appDir> --device <udid> test .maestro/<기능>/<flow>.yaml
#   e2e.sh <appDir> --device <udid> test .maestro --include-tags regression

if [ $# -lt 1 ] || [ ! -d "$1" ]; then
  echo "사용법: e2e.sh <appDir> <maestro 인자...>   (appDir 은 .maestro/ 가 놓인 폴더)" >&2
  exit 1
fi

cd "$1"
shift

ENV_FILE=".maestro/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "❌ $(pwd)/$ENV_FILE 가 없습니다. 본인 dev 계정으로 만드세요 (gitignore 할 것):" >&2
  echo "    MAESTRO_TEST_EMAIL='...'" >&2
  echo "    MAESTRO_TEST_PASSWORD='...'" >&2
  exit 1
fi

set -a
. "./$ENV_FILE"
set +a

# test 실행이면 리포트를 남긴다. 커밋하지 않는다(gitignore) — 결과 요약은 PR 에 적는다.
for arg in "$@"; do
  if [ "$arg" = "test" ]; then
    mkdir -p .maestro/reports
    exec maestro "$@" --format HTML-DETAILED --output ".maestro/reports/$(date +%Y%m%d-%H%M%S).html"
  fi
done

exec maestro "$@"
