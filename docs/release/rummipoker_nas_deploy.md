# Rummi Poker 웹 배포

이 문서는 로컬에서 만든 Flutter 웹 빌드를 NAS 웹서버의 `/share/Web/rummipoker`에 올리는 방법을 설명한다. 명령어는 그대로 실행하고, 앞뒤 확인 단계도 순서대로 진행한다.

## 한눈에 보는 순서

```bash
flutter build web --release --base-href "/rummipoker/"
rm -rf rummipoker
mkdir -p rummipoker
cp -r build/web/* rummipoker/
zip -r rummipoker.zip rummipoker
curl로 deploy_rummipoker.php에 업로드
```

NAS의 PHP는 업로드된 `rummipoker.zip`을 `/share/Web` 아래에 받은 뒤, 기존 `/share/Web/rummipoker` 폴더를 삭제하고, 새 `rummipoker` 폴더로 압축을 해제한 뒤 업로드된 zip 파일을 삭제합니다.

## 1. 배포 토큰 생성

배포 API는 `/share/Web/rummipoker`를 삭제하고 교체할 수 있으므로 토큰이 필요합니다.

macOS 터미널에서 아래 명령으로 긴 랜덤 토큰을 생성합니다.

```bash
openssl rand -hex 32
```

출력 예:

```text
9f8b7c2d1e3a4b5c67890abcdef1234567890abcdef1234567890abcdef1234
```

이 값은 예시입니다. 실제로는 본인 터미널에서 생성된 값을 사용합니다.

## 2. NAS 서버측 env 파일 작성

NAS 웹서버에 아래 파일을 만듭니다.

```text
/share/Web/.rummipoker_deploy.env
```

내용:

```bash
RUMMIPOKER_DEPLOY_TOKEN=openssl_rand_hex_32_출력값
```

권장 권한:

```bash
chmod 600 /share/Web/.rummipoker_deploy.env
```

## 3. NAS에 PHP 파일 업로드

프로젝트 루트의 `deploy_rummipoker.php` 파일을 NAS 웹서버 루트에 업로드합니다.

```text
/share/Web/deploy_rummipoker.php
```

배포 URL:

```text
https://cheng80.myqnapcloud.com/deploy_rummipoker.php
```

NAS에 PHP CLI가 있으면 문법을 확인합니다.

```bash
php -l /share/Web/deploy_rummipoker.php
```

필요 조건:

- PHP `ZipArchive` 확장
- `/share/Web` 쓰기 권한
- PHP 업로드 제한이 `rummipoker.zip` 크기보다 클 것

관련 PHP 설정:

```ini
upload_max_filesize
post_max_size
max_execution_time
memory_limit
```

## 4. 로컬 `.env` 작성

프로젝트 루트의 `.env`에 배포 URL과 같은 토큰을 넣습니다.

```bash
RUMMIPOKER_DEPLOY_URL=https://cheng80.myqnapcloud.com/deploy_rummipoker.php
RUMMIPOKER_DEPLOY_TOKEN=openssl_rand_hex_32_출력값
```

`.env`는 `.gitignore`에 포함되어 커밋되지 않습니다.

권장 권한:

```bash
chmod 600 .env
```

새 환경을 만들 때는 예시 파일을 복사해 시작할 수 있습니다.

```bash
cp .env.example .env
```

## 5. 자동 배포 실행

프로젝트 루트에서 실행합니다.

```bash
tools/deploy_rummipoker_web.sh
```

터미널에는 단계별 진행 상태가 출력됩니다.

```text
[1/6] 환경 설정 확인
  - env file: /path/to/project/.env
  - deploy URL: https://cheng80.myqnapcloud.com/deploy_rummipoker.php
  - deploy token: configured (64 chars)

[2/6] Flutter 웹 릴리즈 빌드
  - base href: /rummipoker/
...

[5/6] NAS 업로드 및 서버 배포
  - HTTP 200
{"result":"OK","action":"deploy",...}

[6/6] 배포 결과 확인
  - server response: OK
  - public URL: https://cheng80.myqnapcloud.com/rummipoker/

Deploy complete.
```

실패하면 실패한 단계와 원인을 출력하고 종료합니다.

```text
ERROR at step: 환경 설정 확인
RUMMIPOKER_DEPLOY_TOKEN still has the placeholder value. Generate a real token with: openssl rand -hex 32
```

스크립트가 하는 일:

1. `flutter build web --release --base-href "/rummipoker/"` 실행
2. 로컬 `rummipoker/` 폴더가 있으면 삭제
3. `build/web/` 결과물을 로컬 `rummipoker/`에 복사
4. 로컬 `rummipoker.zip` 생성
5. `deploy_rummipoker.php`에 zip 업로드
6. NAS에서 기존 `/share/Web/rummipoker` 삭제 후 새 zip 압축 해제
7. NAS의 `/share/Web/rummipoker.zip` 삭제

다른 env 파일을 쓰려면:

```bash
tools/deploy_rummipoker_web.sh --env-file /path/to/deploy.env
```

일회성으로 URL이나 토큰을 넘기려면:

```bash
tools/deploy_rummipoker_web.sh \
  --deploy-url "https://cheng80.myqnapcloud.com/deploy_rummipoker.php" \
  --token "openssl_rand_hex_32_출력값"
```

## 6. 배포 확인

배포 성공 후 아래 URL을 확인합니다.

```text
https://cheng80.myqnapcloud.com/rummipoker/
```

성공 응답 예:

```json
{
  "result": "OK",
  "action": "deploy",
  "deploy_dir": "/share/Web/rummipoker",
  "public_url": "https://cheng80.myqnapcloud.com/rummipoker/",
  "message": "rummipoker 웹 빌드 배포가 완료되었습니다."
}
```

## 7. 오류 대응

토큰 오류:

```json
{
  "result": "Error",
  "errorMsg": "배포 토큰이 올바르지 않습니다."
}
```

확인할 것:

- 로컬 `.env`의 `RUMMIPOKER_DEPLOY_TOKEN`
- NAS `/share/Web/.rummipoker_deploy.env`의 `RUMMIPOKER_DEPLOY_TOKEN`
- 두 값이 완전히 같은지

ZipArchive 오류:

```json
{
  "result": "Error",
  "errorMsg": "PHP ZipArchive 확장이 필요합니다."
}
```

확인할 것:

- NAS PHP에 zip 확장이 켜져 있는지
- NAS 패키지 관리자 또는 PHP 설정에서 zip extension 활성화 가능 여부

업로드 크기 오류:

```json
{
  "result": "Error",
  "errorMsg": "업로드 파일 크기가 PHP 설정 한도를 초과했습니다."
}
```

확인할 것:

- `upload_max_filesize`
- `post_max_size`
- `rummipoker.zip` 실제 크기

## 8. 수동 업로드 테스트

이미 `rummipoker.zip`이 있는 상태에서 PHP만 테스트하려면:

```bash
curl -X POST "https://cheng80.myqnapcloud.com/deploy_rummipoker.php" \
  -H "X-Deploy-Token: $RUMMIPOKER_DEPLOY_TOKEN" \
  -F "file=@rummipoker.zip;type=application/zip"
```
