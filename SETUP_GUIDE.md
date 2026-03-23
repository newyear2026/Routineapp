# 루틴 타이머 앱 - Cursor 설정 가이드

## 1. 로컬 프로젝트 생성

```bash
npm create vite@latest routine-timer-app -- --template react-ts
cd routine-timer-app
```

## 2. 필요한 패키지 설치

```bash
npm install react-router lucide-react motion
npm install -D tailwindcss @tailwindcss/vite
```

## 3. 설정 파일들

### `vite.config.ts`
```typescript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [react(), tailwindcss()],
})
```

### `tailwind.config.js`
```javascript
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
```

### `src/index.css`
```css
@import "tailwindcss";

* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
```

### `src/styles/theme.css`
```css
/* 테마 관련 CSS 변수들 */
:root {
  /* 필요한 경우 커스텀 CSS 변수 추가 */
}
```

### `src/main.tsx`
```typescript
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './app/App'
import './index.css'
import './styles/theme.css'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
```

### `src/app/App.tsx`
```typescript
import { RouterProvider } from 'react-router';
import { router } from './routes';

function App() {
  return <RouterProvider router={router} />;
}

export default App;
```

### `index.html`
```html
<!doctype html>
<html lang="ko">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Routine Timer</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
```

## 4. 코드 파일 복사

Figma Make에서 다음 파일들을 복사하여 동일한 경로에 생성하세요:

### 컴포넌트
- `src/app/components/RoutineDetailSheet.tsx`

### 스크린
- `src/app/screens/SplashScreen.tsx`
- `src/app/screens/OnboardingScreen.tsx`
- `src/app/screens/NotificationPermissionScreen.tsx`
- `src/app/screens/InitialRoutineSetupScreen.tsx`
- `src/app/screens/HomeScreen.tsx`
- `src/app/screens/TodayProgressScreen.tsx`
- `src/app/screens/SettingsScreen.tsx`

### 라우팅
- `src/app/routes.tsx`

## 5. 실행

```bash
npm run dev
```

브라우저에서 `http://localhost:5173` 접속

## 6. 빌드 (배포용)

```bash
npm run build
```

빌드된 파일은 `dist/` 폴더에 생성됩니다.

## 주요 화면 경로

- `/` - 스플래시 화면
- `/onboarding` - 온보딩 (3단계)
- `/notification-permission` - 알림 권한 요청
- `/routine-setup` - 초기 루틴 설정
- `/home` - 메인 홈 화면 (원형 시간표)
- `/progress` - 오늘 진행률 화면
- `/settings` - 설정 화면

## 문제 해결

### 모듈을 찾을 수 없다는 에러
```bash
npm install
```

### Motion 관련 에러
Motion 패키지는 `motion/react`로 import 합니다:
```typescript
import { motion } from 'motion/react'
```

### React Router 관련 에러
`react-router-dom`이 아닌 `react-router`를 사용합니다:
```typescript
import { RouterProvider } from 'react-router'
```

## 추가 개발 팁

1. **Hot Reload**: Vite가 자동으로 변경사항을 감지하고 새로고침합니다
2. **TypeScript**: 타입 에러가 있어도 개발 서버는 실행됩니다
3. **디버깅**: Chrome DevTools의 React DevTools 확장 프로그램 사용 권장
4. **성능**: Production 빌드는 자동으로 최적화됩니다

## 다음 단계

- 실제 데이터 관리 (useState → Context API 또는 Zustand)
- 로컬 스토리지 연동
- 실제 알림 기능 구현
- 백엔드/Supabase 연동
- PWA 설정 (오프라인 지원)
