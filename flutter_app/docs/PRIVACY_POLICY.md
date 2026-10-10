# 개인정보처리방침 / Privacy Policy

**최종 수정일: 2026년 10월 4일**

> Play Console의 "개인정보처리방침" 항목에는 **공개 URL**이 필요하다.
> 이 문서를 GitHub Pages, Notion 공개 페이지 등에 올린 뒤 그 주소를 입력한다.
>
> Google AdMob, Firebase Analytics, Firebase Crashlytics를 사용한다. «수집 안 함»으로 신고하지 않는다. 이 문서와 함께 Play Console의 다음 세 곳을
> 반드시 같이 갱신하고, 갱신한 뒤에 빌드를 올린다.
>
> - 앱 콘텐츠 > 광고: **광고 포함**
> - 데이터 안전성: 광고 SDK 항목과 함께 **앱 활동, 기기 또는 기타 ID, 충돌 로그·진단** 등 실제 SDK 수집 항목 반영
> - 개인정보처리방침 URL: `docs/privacy/index.html`의 공개 주소
>
> 문서와 실제 SDK가 어긋난 채 출시되면 정책 위반으로 앱이 정지된다.
> 되돌리는 비용이 가장 큰 항목이므로 순서를 지킨다.

---

## 한국어

### 1. 개요

LOOPET(이하 "앱")은 루틴 내용을 기기에 저장하고, 사용 현황 분석과 오류 진단을 위해 Firebase를 사용합니다.

앱은 계정이나 로그인을 요구하지 않으며, 개발자는 서버를 운영하지 않습니다.

다만 앱은 무료로 제공되며 화면 일부에 **Google AdMob 광고**를 표시합니다.
광고를 게재하기 위해 Google이 광고 식별자를 처리합니다 — 자세한 내용은 5장에 있습니다.

### 2. 수집하는 정보

앱은 이름, 이메일, 전화번호, 정밀 위치, 연락처, 사진을 요구하지 않습니다.
Firebase Analytics는 앱 실행·화면 방문·루틴 동작 등의 이벤트, 앱 인스턴스 식별자,
앱·기기 정보와 대략적인 지역 등을 처리합니다. Firebase Crashlytics는 충돌·오류의 유형과
스택, 앱·기기 정보 및 설치 식별자를 처리합니다. 개발자는 Firebase/Google Analytics
콘솔에서 이용 통계와 오류 보고서를 확인합니다. 루틴 제목·메모·알림 내용과 구매 영수증은
맞춤 분석 이벤트나 오류 보고서에 직접 첨부하지 않습니다.

광고 표시를 위해 Google AdMob이 광고 식별자(Android 광고 ID)와 대략적인 기기 정보를
처리합니다. 이 정보는 개발자에게 전달되지 않으며, 개발자는 광고 실적 통계(노출 수·수익)만
집계된 형태로 확인합니다.

### 3. 앱이 저장하는 데이터

사용자가 만든 루틴, 루틴 실행 기록, 앱 설정(언어·테마·알림)은 **사용자 기기 내부 저장소에만**
저장됩니다. 이 저장 내용 자체는 업로드하거나 광고 네트워크에 보내지 않습니다.
다만 루틴 생성·수정·삭제·완료·미루기·건너뛰기·되돌리기 같은 행동의 종류는
루틴 이름과 식별자 없이 Analytics 이벤트로 전송합니다.

앱을 삭제하면 저장된 데이터도 함께 삭제됩니다.

### 4. 권한

| 권한 | 용도 |
|------|------|
| 알림 | 사용자가 설정한 루틴 시작 시각에 알림을 표시합니다. 사용자가 거부하거나 설정에서 끌 수 있습니다. |
| 부팅 시 실행 · 진동 | 알림 기능에 딸린 권한입니다. 기기를 껐다 켜도 예약한 알림이 살아남고, 알림이 울릴 때 진동합니다. |
| 인터넷 · 네트워크 상태 | 광고, 구매 관련 통신, 사용 현황 분석과 오류 보고에 사용합니다. 루틴 원문은 전송하지 않습니다. |
| 광고 ID | Google AdMob이 광고를 게재하고 부정 클릭을 막는 데 사용합니다. |

앱은 카메라, 마이크, 위치, 연락처, 외부 저장소 등 민감한 권한을 요구하지 않습니다.

### 5. 제3자 제공 및 광고

앱은 사용자 정보를 제3자에게 판매하거나 대여하지 않습니다.

앱은 운영 비용을 위해 **Google AdMob**(Google LLC) 광고를 표시합니다. AdMob은 광고를
게재하고 부정 클릭을 막기 위해 광고 식별자와 대략적인 기기 정보(기기 모델, 운영체제 버전,
대략적인 지역)를 수집·처리할 수 있습니다. 이 처리는 Google의 개인정보처리방침을 따릅니다:
<https://policies.google.com/privacy>

- 사용자가 만든 루틴·실행 기록·앱 설정은 **광고 네트워크로 전송되지 않습니다.**
- 기기 설정에서 광고 ID를 초기화하거나 삭제해 맞춤 광고를 끌 수 있습니다.
  (Android: 설정 > 개인정보 보호 > 광고)
- 유럽경제지역(EEA)·영국 사용자에게는 광고를 요청하기 **전에** Google 사용자 메시징
  플랫폼(UMP)을 통해 동의를 요청합니다. 동의하지 않으면 맞춤 광고를 요청하지 않습니다.

앱은 Google LLC의 **Firebase Analytics와 Crashlytics**를 사용합니다. Analytics의 광고 ID
수집과 맞춤 광고 신호는 비활성화합니다. AdMob의 광고 동의 절차는 별도로 유지합니다.
SDK 연동이 지원하는 표준 구매·광고 실적 이벤트도 자동 수집될 수 있습니다.
분석 데이터는 연결된 Analytics 속성의 보존 설정을 따릅니다. Crashlytics는 진단 데이터와
관련 식별자를 90일간 보관한 뒤 삭제 절차를 시작합니다. 앱 삭제는 기기의 로컬 데이터를
삭제하며, 이미 전송된 분석·진단 데이터까지 즉시 삭제하지는 않습니다. 관련 문의는
아래 이메일로 연락할 수 있습니다. Firebase의 처리 방식: <https://firebase.google.com/support/privacy>

### 6. 인앱 결제

일부 캐릭터 팩과, 광고 제거가 포함된 번들을 앱에서 살 수 있습니다. **결제는 Google Play가
처리하며**, 앱은 카드 번호·계좌 정보·청구지 주소를 받지 않습니다.

산 것을 제공하고 복원하기 위해 앱은 Google Play로부터 결제 결과(상품 ID, 구매 상태, 구매
식별자)를 받고, 어떤 팩을 가졌는지만 **기기 안에** 기록합니다. 구매는 Google 계정에 묶여 있어,
같은 계정으로 앱을 다시 설치하면 복원됩니다. 결제 정보의 처리는 Google의 개인정보처리방침을
따릅니다.

### 7. 아동의 개인정보

앱은 만 13세 미만 아동을 대상으로 하지 않으며, 아동의 개인정보를 의도적으로 수집하지 않습니다.

### 8. 문의

개인정보처리방침에 관한 문의: **jacoboh7307@gmail.com**

---

## English

### 1. Overview

LOOPET (the "App") stores routine content locally and uses Firebase for usage measurement and error diagnostics.

The App requires no account or login, and the developer operates no servers.

The App is free and displays **Google AdMob** advertising in part of the interface.
To serve those ads, Google processes an advertising identifier — see Section 5.

### 2. Information We Collect

The App does not request names, email addresses, phone numbers, precise location, contacts,
or photos. Firebase Analytics processes app activity, screen visits, routine action events,
app-instance identifiers, app/device information and approximate region. Firebase Crashlytics
processes crash/error types and stack traces, app/device information and installation identifiers.
The developer views usage reports and error reports in Firebase/Google Analytics. We do not
attach routine titles, notes, notification contents or purchase receipts to custom events or reports.

To display ads, Google AdMob processes an advertising identifier (the Android
Advertising ID) and coarse device information. This is not passed to the developer,
who sees only aggregate ad performance statistics (impressions and revenue).

### 3. Data Stored by the App

Routines you create, your routine history, and app settings (language, theme,
notifications) are stored **locally on your device.** These stored records are not uploaded or
sent to the ad network. Action types such as creating, editing, deleting, completing, snoozing,
skipping or undoing a routine are sent as Analytics events without routine names or identifiers.

Uninstalling the App deletes this data.

### 4. Permissions

| Permission | Purpose |
|------------|---------|
| Notifications | Shows a reminder when a routine you scheduled begins. You may deny this permission or disable it in Settings. |
| Run at startup · Vibration | Incidental to notifications, so scheduled reminders survive a restart and can vibrate when they fire. |
| Internet · Network state | Used for ads, purchase-related communication, analytics and error reports. Routine text is not transmitted. |
| Advertising ID | Used by Google AdMob to serve ads and prevent click fraud. |

The App requests no sensitive permission such as camera, microphone, location,
contacts, or external storage.

### 5. Third Parties and Advertising

We do not sell or rent user information to third parties.

To cover operating costs, the App displays ads from **Google AdMob** (Google LLC).
AdMob may collect and process an advertising identifier and coarse device information
(device model, OS version, approximate region) in order to serve ads and prevent click
fraud. That processing is governed by Google's privacy policy:
<https://policies.google.com/privacy>

- Your routines, completion history, and settings are **never sent to the ad network.**
- You can reset or delete your advertising ID in your device settings to opt out of
  personalized ads (Android: Settings > Privacy > Ads).
- Users in the European Economic Area and the United Kingdom are asked for consent
  through Google's User Messaging Platform (UMP) **before** any ad is requested. Without
  consent, no personalized ads are requested.

The App uses **Firebase Analytics and Crashlytics**, provided by Google LLC. Analytics
advertising-ID collection and personalized-advertising signals are disabled. AdMob consent
is handled separately. Analytics retention follows the linked property settings. Crashlytics
keeps diagnostic data and related identifiers for 90 days before starting deletion. Uninstalling
removes local app data, but does not immediately erase reports already sent. Contact the email
below about data handling. See <https://firebase.google.com/support/privacy>.
Analytics may also collect standard purchase or ad-performance events supported by SDK integrations.

### 6. In-App Purchases

Some character packs, and a bundle that also removes ads, can be bought in the App.
**Google Play handles the payment**; the App never receives your card number, bank
details, or billing address.

To deliver and restore what you bought, the App receives the purchase result from
Google Play (product ID, purchase state, purchase identifier) and records which packs
you own **on your device only**. Purchases are tied to your Google account, so
reinstalling with the same account restores them. Google's handling of payment
information is governed by Google's privacy policy.

### 7. Children's Privacy

The App is not directed at children under 13. We do not knowingly collect personal information from children.

### 8. Contact

Questions about this policy: **jacoboh7307@gmail.com**

---

## Español

### 1. Descripción general

LOOPET (la "Aplicación") guarda el contenido de las rutinas en el dispositivo y usa Firebase para medir el uso y diagnosticar errores.

La Aplicación no requiere cuenta ni inicio de sesión, y el desarrollador no opera servidores.

La Aplicación es gratuita y muestra publicidad de **Google AdMob** en parte de la interfaz.
Para mostrar esos anuncios, Google procesa un identificador de publicidad — consulta la sección 5.

### 2. Información que recopilamos

La Aplicación no solicita nombres, correos, teléfonos, ubicación precisa, contactos ni fotos.
Firebase Analytics procesa actividad de la aplicación, visitas a pantallas, acciones de rutinas,
identificadores de instancia, información de la aplicación y del dispositivo y región aproximada.
Firebase Crashlytics procesa tipos de errores y sus trazas, información técnica e identificadores
de instalación. El desarrollador consulta estadísticas e informes de errores en Firebase/Google
Analytics. No adjuntamos títulos, notas, contenido de notificaciones ni recibos de compra a eventos
personalizados o informes de errores.

Para mostrar anuncios, Google AdMob procesa un identificador de publicidad (el ID de
publicidad de Android) e información aproximada del dispositivo. Esta información no llega
al desarrollador, que solo consulta estadísticas agregadas de rendimiento publicitario
(impresiones e ingresos).

### 3. Datos almacenados por la Aplicación

Las rutinas que creas, tu historial de rutinas y los ajustes (idioma, tema, notificaciones)
se guardan **en el almacenamiento local de tu dispositivo.** No subimos estos registros ni los
enviamos a la red publicitaria. Enviamos tipos de acciones (crear, editar, borrar, completar,
posponer, omitir o deshacer) como eventos de Analytics, sin nombres ni identificadores de rutinas.

Al desinstalar la Aplicación, estos datos se eliminan.

### 4. Permisos

| Permiso | Finalidad |
|---------|-----------|
| Notificaciones | Muestra un recordatorio cuando comienza una rutina que has programado. Puedes denegar este permiso o desactivarlo en los ajustes. |
| Ejecutar al inicio · Vibración | Complementan las notificaciones, para que los recordatorios programados sobrevivan a un reinicio y puedan vibrar al activarse. |
| Internet · Estado de la red | Se usan para anuncios, comunicación de compras, análisis e informes de errores. No se transmite el texto de las rutinas. |
| ID de publicidad | Google AdMob lo usa para mostrar anuncios y evitar clics fraudulentos. |

La Aplicación no solicita permisos sensibles como cámara, micrófono, ubicación, contactos
ni almacenamiento externo.

### 5. Terceros y publicidad

No vendemos ni alquilamos información de las personas usuarias a terceros.

Para cubrir los costes de funcionamiento, la Aplicación muestra anuncios de **Google AdMob**
(Google LLC). AdMob puede recopilar y procesar un identificador de publicidad e información
aproximada del dispositivo (modelo, versión del sistema operativo, región aproximada) con el
fin de mostrar anuncios y evitar clics fraudulentos. Ese tratamiento se rige por la política
de privacidad de Google: <https://policies.google.com/privacy>

- Tus rutinas, tu historial y tus ajustes **nunca se envían a la red publicitaria.**
- Puedes restablecer o eliminar tu ID de publicidad en los ajustes del dispositivo para
  desactivar los anuncios personalizados (Android: Ajustes > Privacidad > Anuncios).
- A las personas usuarias del Espacio Económico Europeo y del Reino Unido se les solicita
  consentimiento mediante la Plataforma de Mensajes al Usuario (UMP) de Google **antes** de
  solicitar cualquier anuncio. Sin consentimiento no se solicitan anuncios personalizados.

La Aplicación usa **Firebase Analytics y Crashlytics** de Google LLC. La recopilación del ID
publicitario y las señales de personalización publicitaria de Analytics están desactivadas;
el consentimiento de AdMob se gestiona por separado. La retención de Analytics depende de la
propiedad vinculada. Crashlytics conserva diagnósticos e identificadores relacionados durante
90 días antes de iniciar su eliminación. Desinstalar elimina los datos locales, pero no borra
inmediatamente los informes ya enviados. Para consultas, usa el correo indicado abajo.
Más información: <https://firebase.google.com/support/privacy>.
Analytics también puede recopilar eventos estándar de compras o rendimiento publicitario compatibles con las integraciones del SDK.

### 6. Compras dentro de la Aplicación

Algunos packs de personajes, y un paquete que además quita los anuncios, se pueden comprar
en la Aplicación. **Google Play procesa el pago**; la Aplicación nunca recibe tu número de
tarjeta, datos bancarios ni dirección de facturación.

Para entregar y restaurar lo que compraste, la Aplicación recibe de Google Play el resultado
de la compra (ID del producto, estado e identificador de la compra) y registra qué packs
tienes **solo en tu dispositivo**. Las compras están ligadas a tu cuenta de Google, así que
al reinstalar con la misma cuenta se restauran. El tratamiento de los datos de pago se rige
por la política de privacidad de Google.

### 7. Privacidad de los menores

La Aplicación no está dirigida a menores de 13 años y no recopilamos intencionadamente información personal de menores.

### 8. Contacto

Preguntas sobre esta política: **jacoboh7307@gmail.com**
