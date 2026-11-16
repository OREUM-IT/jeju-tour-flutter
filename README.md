# 오름잇 · OREUM IT — Flutter

[기존 서비스](https://jeju-tour-six.vercel.app)의 주요 화면을 Dart/Flutter로 다시 구현한 클라이언트입니다. 웹·Android·iOS 프로젝트를 포함합니다.

> 원본 `OREUM-IT/jeju-tour` 저장소에 접근할 수 없어 공개 화면, 배포된 클라이언트, 실제 API 응답을 기준으로 작성했습니다. **기존 서버 로직의 Dart 변환본은 아닙니다.** 일정 생성·경로 분석·기상·챌린지 판정은 기존 서비스 API에 연결합니다. 상세 범위는 [이전 내역](docs/MIGRATION.md)을 참고하세요.

## 실행

검증 환경: Flutter 3.47.6 / Dart 3.13.5. 의존성 버전은 `pubspec.lock`으로 고정합니다.

```sh
flutter pub get --enforce-lockfile
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn --no-wasm-dry-run
python scripts/preview.py --port 8080
```

브라우저에서 `http://127.0.0.1:8080`을 엽니다. 미리보기 서버는 `/api/*`를 기존 서비스로 프록시하므로 별도 CORS 설정이 필요 없습니다. Python 3.10 이상, 별도 Python 패키지 불필요.

Android·iOS:

```sh
flutter run -d <device-id>
```

기본 네이티브 API 주소는 `https://jeju-tour-six.vercel.app/api/`입니다. 다른 서버를 사용하려면:

```sh
flutter run -d <device-id> --dart-define=API_BASE_URL=https://your-backend.example/api/
```

웹은 기본적으로 같은 출처의 `/api/`를 사용합니다. 별도 주소로 빌드하면 해당 서버에 웹 앱 출처의 CORS 허용이 필요합니다. API 키와 비밀 값은 앱에 넣지 않습니다.

## 기능

- 등반 플래너: 기간·출발일·교통·등산로·속도·선호 장소·챌린지 단계, 실제 API 일정, 일차별 지도·시간표·대안 장소.
- 코스 빌더: 기존 장소 목록 검색·분류, 1~7일별 장소 선택·순서 변경, 영업시간 반영, 예상 시간표 생성.
- 내 일정: 기기 저장, 다시 열기, 삭제 및 되돌리기. 생성한 일정은 다시 API를 호출하지 않고 열 수 있습니다.
- 챌린지: 단계·코스 선택, 실제 GPS, 사진 촬영/선택, 원본 EXIF 추출 후 JPEG 축소, 출발/도착 인증, 기상 악화 하산, 서버 진행 현황·명예의 전당.
- 코스 그리기: 지도 지점 입력, 실행 취소/다시 실행, 프리셋, 거리·고도·경사·예상 시간, 고도 차트·길 안내, 저장 및 GPX 내용 복사.
- 실시간 기상: 지도 지점·현재 위치, 기상청 실황·초단기예보·관측소·특보, Open-Meteo 정상 예보.
- 한국어, 화면 크기에 따른 메뉴, 라이트·다크·시스템 테마.

코스 빌더의 이동 시간은 좌표 기반 추정치이며 실제 대중교통 시간표가 아닙니다. 지도에는 OpenStreetMap을 사용합니다.

## 웹 배포

Vercel에서 이 저장소를 **새 프로젝트**로 연결하면 `vercel.json`이 Flutter 빌드와 API 프록시를 설정합니다. 기존 사이트 설정을 변경할 필요가 없습니다. `scripts/build_web.sh`는 Flutter가 없는 빌드 환경에서 지정 버전의 공식 SDK를 내려받습니다. `FLUTTER_VERSION`으로 버전을 명시할 수 있습니다.

GitHub Actions는 분석·테스트·웹 빌드를 수행하고 `oreum-it-flutter-web` 산출물을 보관합니다. 자동 배포나 기존 Vercel 프로젝트 변경은 포함하지 않습니다.

## 데이터와 권한

- 내 일정과 테마·닉네임은 이 기기의 SharedPreferences에 저장됩니다. 브라우저/앱 데이터를 삭제하면 함께 지워집니다.
- 챌린지 인증은 동의 체크 후 인증 버튼을 누를 때 닉네임·GPS·사진을 기존 오름잇 서버로 전송합니다. 사진을 고르거나 위치를 측정하는 것만으로 전송하지 않습니다.
- 2026-11-16 확인 당시 기존 API의 저장 모드는 `memory`였습니다. 서버 재시작 시 인증 기록이 사라질 수 있습니다. 영구 저장과 사용자 계정은 별도 서버 작업이 필요합니다.
- 카메라·위치·사진 권한 설명을 Android/iOS에 설정했습니다. 실제 기기의 인증 제출과 iOS 빌드/서명은 별도 기기에서 확인해야 합니다.
- 로고·사진은 기존 오름잇 서비스의 자산입니다. 저장소 소유자의 기존 권리를 유지하며 임의의 오픈소스 라이선스를 부여하지 않습니다. 데이터 출처는 앱의 이용안내 → 데이터 출처에서 확인할 수 있습니다.

## 구조

```text
lib/core/       API, 모델, 기기 저장, 코스 시간표, GPS·사진 처리
lib/features/   플래너, 코스 빌더, 저장 일정, 챌린지, 경로, 기상
lib/ui/         공통 화면·지도
test/           API 오류·한글, 일정 계산·저장·사진, 반응형 위젯 테스트
scripts/        웹 빌드와 로컬 API 프록시
```
