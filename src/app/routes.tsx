import { createBrowserRouter } from "react-router";
import { SplashScreen } from "./screens/SplashScreen";
import { OnboardingScreen } from "./screens/OnboardingScreen";
import { NotificationPermissionScreen } from "./screens/NotificationPermissionScreen";
import { InitialRoutineSetupScreen } from "./screens/InitialRoutineSetupScreen";
import { HomeScreen } from "./screens/HomeScreen";
import { TodayProgressScreen } from "./screens/TodayProgressScreen";
import { SettingsScreen } from "./screens/SettingsScreen";

export const router = createBrowserRouter([
  {
    path: "/",
    Component: SplashScreen,
  },
  {
    path: "/onboarding",
    Component: OnboardingScreen,
  },
  {
    path: "/notification-permission",
    Component: NotificationPermissionScreen,
  },
  {
    path: "/routine-setup",
    Component: InitialRoutineSetupScreen,
  },
  {
    path: "/home",
    Component: HomeScreen,
  },
  {
    path: "/progress",
    Component: TodayProgressScreen,
  },
  {
    path: "/settings",
    Component: SettingsScreen,
  },
]);