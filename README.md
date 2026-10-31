# Paimana

Paimana is an Android-first tailoring workspace built with Flutter, Riverpod,
GoRouter, Dio, and Hive. Customer and order records are stored on-device so
they remain available without a network connection.

## Run

```powershell
Set-Location C:\Users\HP\Desktop\Paimana\paimana
flutter pub get
```

Without `API_BASE_URL`, the app stays in local-only mode: Hive-backed customer
and order data remains available, while sign-in and cloud sync are unavailable.
To enable the API, first configure and start the backend (see
[backend/README.md](./backend/README.md)), then pass its API v1 base URL when
running Flutter. For Chrome on this computer:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:4000/api/v1
```

For an Android emulator, use `http://10.0.2.2:4000/api/v1` (the emulator's
host-computer address). Find its device ID with `flutter devices`, then run:

```powershell
flutter run -d <emulator-device-id> --dart-define=API_BASE_URL=http://10.0.2.2:4000/api/v1
```

For a physical phone on the same network, replace `10.0.2.2` with this
computer's private LAN IPv4 address (find it with `ipconfig`; it may change),
for example `http://192.168.1.100:4000/api/v1`. That example address is not
necessarily your computer's address. The phone and computer must be on the
same Wi-Fi network. The backend listens on `0.0.0.0`; allow inbound TCP port
4000 through Windows Firewall on the private network if needed. Local HTTP is
enabled only in the Android debug manifest. Use HTTPS for deployed builds.

## IDE run configurations

### VS Code

The checked-in `.vscode/launch.json` includes Chrome and Android emulator
configurations. Select **Paimana (Chrome)** or **Paimana (Android emulator)**
from Run and Debug. For the emulator configuration, start an emulator and
select it in VS Code's device selector before launching. To use a physical
phone, select it there and replace the emulator URL in the launch
configuration's `toolArgs` with this computer's LAN URL.

### Android Studio

Android Studio does not use VS Code's `launch.json`. To configure it, open
**Run > Edit Configurations**, add a **Flutter** configuration, and set
**Dart entrypoint** to `lib/main.dart`. In **Additional run args**, enter the
appropriate argument:

```text
--dart-define=API_BASE_URL=http://localhost:4000/api/v1
```

Use `http://10.0.2.2:4000/api/v1` for an Android emulator, or
`http://<your-computer-LAN-IPv4>:4000/api/v1` for a physical phone. Find the
current IPv4 address with `ipconfig` and use the address for the active Wi-Fi
adapter. Save the configuration, select the desired Chrome or Android device,
and run it.
The API request and response contract is in [backend/docs/api.md](./backend/docs/api.md).
Flutter AI requests go to `POST /ai/{action}` on that backend; the app never
calls a model provider directly. AI output is editable and is not persisted.

## Validate

```powershell
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

## Current implementation

- Persistent offline customer and tailoring-order CRUD, including due dates,
  order statuses, and advance/outstanding amounts.
- Advance, partial and final payment history with offline queueing and
  transaction-backed order balance updates.
- Dashboard totals derived from saved records.
- Backend-only AI assistant actions and speech-to-text input.
- JWT access/refresh token storage and a Dio refresh interceptor.
- Account-scoped, AES-encrypted Hive records and an idempotent, retryable
  customer/order/payment sync queue. The encryption key is held in secure storage;
  existing plaintext Hive records are migrated on startup.
- Automatic queue retry when the app is open and connectivity returns, with a
  visible retry action if synchronization fails.

Offline-only records stay in a local workspace until an explicit account
import workflow is provided; they are not silently attached to a newly
authenticated account.

Firebase push notifications, measurement history and background
synchronization while the app is closed are separate features and are not
represented as implemented in this milestone.
