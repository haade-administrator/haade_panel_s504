# PanelLink — native service for SMT101 / Haade panels

A small native Android app (≈300 KB) that exposes the panel hardware to Home Assistant over MQTT:
RGB backlight, two relays, two inputs, temperature and humidity (and an optional light sensor).
It replaces the Flutter app in this repository for everyday use; the MQTT topics and discovery
unique_ids are the same, so existing Home Assistant entities and automations keep working.

## Why a rewrite

| Flutter app (1.2.1) | PanelLink (2.0.0) |
|---|---|
| MQTT lives only while the app screen is alive; *Back* or swiping it away stops everything | Foreground service, independent of any screen |
| Keep-alive never drops a dead connection (`disconnectOnNoResponsePeriod` is left at 0), so after a network or broker hiccup the app can stay "connected" to nothing; every retry posts a high-importance notification; only the first message of each `updates` batch is handled | Keep-alive 30 s drops a dead link, connect/subscribe deadlines, backoff 1–30 s, instant retry when the network returns, re-subscribes after every connect, one quiet notification |
| After a reboot an empty service starts, the app has to be opened by hand | Starts on boot and after updates, optional watchdog |
| `getevent -l` for **all** input devices (every touch included), one more process each time the screen is recreated | Reads only the two sensor devices with a blocking read — no CPU between measurements |
| IO polled 2× per second through Flutter channels, light sensor raising a notification every second | IO and light sensor optional, one quiet service notification |
| One panel per broker | Configurable node id and device name — several panels work side by side (#3) |

## Setup

1. Uninstall the old app (the signing key is different, so Android cannot update it in place).
2. Install `panellink.apk` from the [releases](../../releases) and open it once.
3. Enter the broker address, user and password, tap **Save and connect**.
4. Tap **Lift** next to *Background limits* so Android never throttles the service.

The status card shows the connection, temperature, humidity, backlight colour and relays.
Everything keeps running after the screen is closed.

Relays always start switched off after a restart of the panel or the service (safe for pulse loads);
the backlight comes back with its last colour.

## Several panels

Give every panel its own **MQTT ID** (for example `panel_kitchen`). Each ID has its own topics,
unique_ids and device in Home Assistant. When the ID of a panel changes, the app removes the
old discovery entries from the broker automatically.

## MQTT

| Topic (`<id>` = MQTT ID, default `haade_panel_s504`) | Payload |
|---|---|
| `<id>/availability` | `online` / `offline` (last will) |
| `<id>/led/set`, `<id>/led/state` | JSON light schema, `color_mode: rgb` |
| `<id>/switch/relay{1,2}/set`, `…/state` | `ON` / `OFF` |
| `<id>/binary_sensor/io{1,2}/state` | `ON` / `OFF` |
| `<id>/sensor/temperature` | `{"temperature": 23.5}` |
| `<id>/sensor/humidity` | `{"humidity": 41}` |
| `<id>/sensor/lux` | `{"lux": 120.0}` |

The app listens to `homeassistant/status` and announces everything again when Home Assistant restarts.

## Build

GitHub Actions (`.github/workflows/native-apk.yml`) builds a signed release APK on every push.
Locally: `cd native && gradle assembleRelease` (JDK 17, Android SDK 35).

---

### En bref (FR)

Application native légère qui relie le panneau à Home Assistant via MQTT : service au premier
plan qui démarre avec l'appareil, reconnexion MQTT fiable, capteurs lus sans consommer de CPU,
ID MQTT et nom configurables pour utiliser plusieurs panneaux, interface en français, anglais
et russe. Les topics et unique_id restent identiques à la version Flutter.
