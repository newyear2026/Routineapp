/// 설정 화면에서 보여줄 오류의 **종류**.
///
/// 컨트롤러가 완성된 문장을 들고 있으면 번역이 UI 밖으로 새어 나간다
/// (PROJECT_RULES 4 — 화면 문자열은 화면에서 만든다). 컨트롤러는 무엇이
/// 실패했는지만 말하고, 문장은 화면이 현재 언어로 고른다.
enum SettingsError {
  load,
  saveNotifications,
  saveSound,
}
