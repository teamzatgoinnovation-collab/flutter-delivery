# Delivery — Flutter driver client

Last-mile driver app against ERPNext / `zatgo_core` delivery APIs.

**Stack:** Riverpod · GoRouter · `http` · Hive · geolocator · url_launcher · image_picker · `zatgo_dart_sdk`  
**Backend:** `zatgo_core.api.v1.delivery.*`

## Workflow (2A)

```
POS → Assigned → Accepted → Reached Restaurant → Picked Up → Out For Delivery → Delivered
                                                      ↘ Failed / Cancelled / Returned
Assigned → Rejected
```

## Phase 1B features

- Dashboard status counts + COD / points / distance
- Assigned stops only (via `boys.ensure` + `stops.list`)
- Status actions synced to ERPNext
- Simple **Mark delivered** (optional note — no signature/photo)
- Call / SMS / WhatsApp / Google Maps navigate
- GPS share via geolocator → `tracking.ping`
- Hive cache + outbox for offline prep
- Session prefs (base URL + last user hint)

## Dependency

```yaml
zatgo_dart_sdk:
  path: ../../../SharedSDK/dart_sdk
```

## Run

```bash
cd Clients/flutter/delivery
flutter pub get
flutter run --dart-define=FRAPPE_BASE_URL=https://erp.zatgo.online
```

Sign in with the courier ERPNext login from POS → Couriers.
