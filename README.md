# 정산봇 랜딩 페이지

배민/쿠팡이츠 사장님을 대상으로 정산서 PDF를 엑셀로 변환하는 서비스 수요를 검증하기 위한 GitHub Pages용 정적 랜딩 페이지입니다.

## 구성

- `index.html`: Tailwind CDN과 Pretendard CDN을 사용하는 단일 페이지
- `.nojekyll`: GitHub Pages에서 Jekyll 처리를 건너뛰기 위한 빈 파일
- 백엔드, 실제 결제, AI/ML 라이브러리는 포함하지 않음
- 목표: 5일 안에 사전신청 이메일 10개 수집

## 로컬 미리보기

```bash
python -m http.server 8000
```

브라우저에서 `http://localhost:8000`으로 접속합니다.

## Formspree 설정

현재 이메일 폼은 placeholder URL을 사용합니다.

```html
action="https://formspree.io/f/YOUR_FORM_ID"
```

연결 방법:

1. https://formspree.io 에 가입합니다.
2. 새 Form을 만들고 수신 이메일을 인증합니다.
3. Formspree가 제공하는 endpoint URL을 복사합니다. 예: `https://formspree.io/f/abcdwxyz`
4. `index.html`의 form action을 아래처럼 교체합니다.

```html
action="https://formspree.io/f/abcdwxyz"
```

5. 변경 후 커밋하고 GitHub Pages에 다시 push합니다.

무료 플랜에서는 제출 수 제한이 있으므로, 검증 기준인 이메일 10개 수집에는 충분한지 Formspree 계정의 현재 플랜 조건을 확인하세요.

## GitHub Pages 배포

예상 저장소 이름은 `jeongsan-bot`입니다.

GitHub CLI가 설치되어 있고 `gh auth login`이 끝난 상태라면 아래 스크립트로 저장소 생성, push, Pages 활성화, 200 응답 확인까지 실행할 수 있습니다.

```powershell
powershell -ExecutionPolicy Bypass -File .\deploy-github-pages.ps1
```

GitHub CLI가 없다면 `repo`와 Pages 권한이 있는 토큰을 환경변수로 넣고 같은 스크립트를 실행할 수 있습니다.

```powershell
$env:GITHUB_TOKEN="ghp_..."
powershell -ExecutionPolicy Bypass -File .\deploy-github-pages.ps1
```

수동 배포 방법:

1. GitHub에 public repository `jeongsan-bot`을 생성합니다.
2. 로컬에서 `main` 브랜치로 push합니다.
3. GitHub repository의 `Settings > Pages`로 이동합니다.
4. Source를 `Deploy from a branch`로 설정합니다.
5. Branch는 `main`, folder는 `/root`를 선택하고 저장합니다.
6. 배포 URL은 아래 형식입니다.

```text
https://[username].github.io/jeongsan-bot
```

현재 GitHub 사용자명이 `MICONNM`이면 예상 URL은 다음과 같습니다.

```text
https://MICONNM.github.io/jeongsan-bot
```

## 나중에 도메인 변경하기

is-a.dev 같은 커스텀 도메인으로 옮길 때:

1. GitHub Pages 설정에서 Custom domain에 새 도메인을 입력합니다.
2. 저장하면 repository root에 `CNAME` 파일이 생성되거나, 직접 `CNAME` 파일을 만들 수 있습니다.
3. `CNAME` 파일 내용은 도메인만 한 줄로 적습니다.

```text
jeongsan-bot.is-a.dev
```

4. 도메인 제공처 또는 is-a.dev 설정에서 GitHub Pages가 요구하는 DNS 레코드를 연결합니다.
5. GitHub Pages에서 `Enforce HTTPS`가 활성화되는지 확인합니다.

## 주의

- 이 페이지는 시장 검증용입니다.
- 실제 결제 시스템은 Phase 2에서 붙입니다.
- PDF 변환 기능과 파일 업로드 기능은 아직 구현하지 않았습니다.
