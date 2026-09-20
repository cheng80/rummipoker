# Web 출시 빌드

## `/rummipoker/` 경로에 올릴 때

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
<meta property="og:image" content="https://cheng80.myqnapcloud.com/rummipoker/assets/assets/splash.png">
```

해당 파일은 원본 `assets/splash.png`가 웹 빌드 후
`rummipoker/assets/assets/splash.png`로 복사된 결과입니다.
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

**방법 A-1: NAS `/share/Web/rummipoker` 자동 배포**

NAS 웹서버에 `deploy_rummipoker.php`를 올린 뒤, 로컬에서 빌드/압축/업로드를 한 번에 실행할 수 있습니다.

```bash
tools/deploy_rummipoker_web.sh
```

배포 토큰 생성, `.env` 작성, NAS 서버측 env 파일 작성법은 `docs/release/rummipoker_nas_deploy.md`를 따릅니다.

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

개발 서버에서 debug fixture를 켜고 고정 포트로 눈검증하는 절차는
`docs/release/submission_kit/WEB_BUILD_GUIDE.md`의 "고정 포트 Chrome 눈검증"을 따른다.

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

### 웹 splash fade와 `flutter_native_splash` 재생성

웹 splash는 첫 Flutter 프레임 위에서 240ms 동안 서서히 사라집니다. 이 fade는 `web/index.html`의 `removeSplashFromWeb` 함수 안에 직접 넣은 코드입니다. 그런데 이 함수가 들어 있는 `<script id="splash-screen-script">` 블록은 `flutter_native_splash` 패키지가 만드는 블록입니다. 그래서 `dart run flutter_native_splash:create`를 다시 실행하면 이 블록이 패키지 원본으로 덮어써지고 fade가 조용히 사라집니다. 원본 함수는 splash 요소를 바로 `remove()`하므로 화면이 하드컷으로 바뀝니다.

1. 재생성 직후에 `git diff web/index.html`을 실행합니다.
2. diff에서 `removeSplashFromWeb` 함수가 `document.getElementById("splash")?.remove();` 세 줄짜리 원본으로 돌아가 있으면 fade가 빠진 것입니다. `transition = "opacity 240ms ease-out"` 줄이 diff에 삭제로 보여도 마찬가지입니다.
3. 아래 코드로 `removeSplashFromWeb` 함수와 바로 위 주석을 통째로 바꿉니다. 이 코드는 현재 `web/index.html`의 내용과 같습니다.

```html
    // T4: 첫 Flutter 프레임 위에서 splash를 짧게 fade한 뒤 지운다(하드컷 방지).
    // 동작 줄이기에서는 바로 지운다. transitionend가 오지 않아도 타이머로 지운다.
    function removeSplashFromWeb() {
      var nodes = ["splash", "splash-branding"]
        .map(function (id) { return document.getElementById(id); })
        .filter(Boolean);
      document.body.style.background = "transparent";
      var reduce = window.matchMedia &&
        window.matchMedia("(prefers-reduced-motion: reduce)").matches;
      if (reduce) {
        nodes.forEach(function (n) { n.remove(); });
        return;
      }
      nodes.forEach(function (n) {
        n.style.position = "fixed";
        n.style.inset = "0";
        n.style.zIndex = "2147483647";
        n.style.pointerEvents = "none";
        n.style.background = "#ffffff";
        n.style.transition = "opacity 240ms ease-out";
        requestAnimationFrame(function () {
          requestAnimationFrame(function () { n.style.opacity = "0"; });
        });
        setTimeout(function () { n.remove(); }, 320);
      });
    }
```

동작 줄이기(`prefers-reduced-motion: reduce`)에서는 fade 없이 바로 지웁니다. `transitionend`에 기대지 않고 320ms 타이머로도 지우므로 이벤트가 오지 않아도 splash가 남지 않습니다.

가장 쉬운 되돌리기 방법은 재생성 결과를 버리는 것입니다.

1. `git checkout -- web/index.html`로 fade가 들어 있던 파일을 복원합니다.
2. 재생성이 꼭 필요했던 변경(splash 이미지나 배경색 변경으로 바뀐 생성 부분)이 있다면 그 부분만 다시 반영합니다. `removeSplashFromWeb` 함수는 건드리지 않습니다.
3. `flutter build web --release --base-href /rummipoker/` 결과를 로컬 서버로 띄우고, 새로고침할 때 splash가 서서히 사라지는지 눈으로 확인합니다. 하드컷으로 사라지면 fade가 아직 빠져 있는 것입니다.

`web/index.html`의 splash `<script>` 위에도 이 절을 가리키는 한 줄 주석이 있습니다. 패키지가 그 주석까지 지울 수 있으므로 이 문서가 정본입니다.

### 관련 파일

- `web/index.html`: `<base href="$FLUTTER_BASE_HREF">` — 빌드 시 `--base-href` 값으로 치환됨
- `lib/router.dart`: GoRouter 경로 설정 (서브패스는 base-href로 자동 처리)
