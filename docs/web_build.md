# Web 릴리즈 빌드

## /rummipoker/ 서브패스에서 실행

앱을 `https://example.com/rummipoker/` 같은 서브패스에서 서비스할 때 사용합니다.

### 빌드 명령어

```bash
flutter build web --release --base-href "/rummipoker/"
```

### 용량 줄이기 옵션

번들 크기를 줄이려면 다음 옵션을 추가할 수 있습니다:

```bash
flutter build web --release --base-href "/rummipoker/" \
  --tree-shake-icons \
  --no-source-maps
```

| 옵션 | 설명 |
|------|------|
| `--tree-shake-icons` | 사용하지 않는 Material/Cupertino 아이콘 제거 (기본값일 수 있음) |
| `--no-source-maps` | 소스맵 미생성 → 디버깅용 파일 제외로 용량 감소 |
| `--minify` | JS/CSS 압축 (release 빌드에서 기본 적용) |

**용량 분석:**
```bash
flutter build web --release --base-href "/rummipoker/" --analyze-size
```
빌드 후 `build/web/` 내 `.json` 리포트로 어떤 모듈이 용량을 차지하는지 확인할 수 있습니다.

### 출력 경로

빌드 결과물은 `build/web/` 폴더에 생성됩니다.

### 공유 링크 미리보기 이미지

카카오톡 같은 공유 미리보기는 로딩 스플래시가 아니라 `web/index.html`의 Open Graph 메타 태그를 봅니다.

현재 공유 이미지는 다음 절대 URL로 고정합니다:

```html
<meta property="og:image" content="https://cheng80.myqnapcloud.com/rummipoker/splash/img/light-4x.png">
```

해당 파일은 `assets/splash.png`가 웹 빌드 후
`rummipoker/splash/img/light-4x.png`로 복사된 결과입니다.
공유 이미지가 이전 이미지로 보이면 앱 빌드 문제가 아니라 카카오톡/플랫폼의 링크 미리보기 캐시일 수 있습니다.

### 배포

**방법 A: 정적 호스팅 (GitHub Pages, Netlify 등)**

서버 설정을 할 수 없는 경우, `rummipoker` 폴더를 만들고 빌드 결과물을 그 안에 복사합니다:

```bash
# 빌드 후 rummipoker 폴더 생성 및 복사
flutter build web --release --base-href "/rummipoker/"
mkdir -p rummipoker && cp -r build/web/* rummipoker/
```

`rummipoker/` 폴더를 업로드하면 `https://example.com/rummipoker/` 에서 서비스됩니다.

**방법 B: Nginx/Apache 등 직접 설정 가능한 서버**

1. `build/web/` 폴더 전체를 웹 서버에 업로드합니다.
2. 서버에서 `/rummipoker/` 경로가 `build/web/` 내용을 가리키도록 설정합니다.

**예시 (Nginx):**
```nginx
location /rummipoker/ {
    alias /path/to/build/web/;
    try_files $uri $uri/ /rummipoker/index.html;
}
```

**예시 (Apache):**
```apache
Alias /rummipoker /path/to/build/web
<Directory /path/to/build/web>
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
    RewriteEngine On
    RewriteBase /rummipoker/
    RewriteRule ^index\.html$ - [L]
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteRule . /rummipoker/index.html [L]
</Directory>
```

### 로컬 확인

빌드 후 로컬에서 서브패스 동작을 확인하려면:

```bash
# Python으로 간단 서버 실행 (build/web에서)
cd build/web
python3 -m http.server 8080
```

그 다음 브라우저에서 `http://localhost:8080/rummipoker/` 로 접속합니다.

> **참고:** Python http.server는 서브패스 리다이렉트를 완벽히 처리하지 못할 수 있습니다. 실제 배포 환경과 비슷하게 테스트하려면 Nginx/Apache 등으로 확인하는 것이 좋습니다.

### base-href 규칙

- 반드시 `/`로 시작하고 `/`로 끝나야 합니다.
- 예: `"/rummipoker/"` ✅
- 예: `"/rummipoker"` ❌ (끝에 `/` 없음)
- 루트에서 서비스할 경우: `"/"`

### 관련 파일

- `web/index.html`: `<base href="$FLUTTER_BASE_HREF">` — 빌드 시 `--base-href` 값으로 치환됨
- `lib/router.dart`: GoRouter 경로 설정 (서브패스는 base-href로 자동 처리)
