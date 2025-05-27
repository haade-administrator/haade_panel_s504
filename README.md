## 🚀 Connect Haade Panel s504 to HomeAssistant via MQTT connect

![Haade Panel s504](assets/description/haade-panel-s504.png)

### Bug Fixes Gallery app
connect to tablet:

```
adb tcpip 5555
adb connect your-ip:5555
adb root
adb shell
pm disable com.android.gallery3d/com.android.gallery3d.app.PackagesMonitor
pm list receivers -d | grep gallery
```

if you want enable put:
```
pm enable com.android.gallery3d/com.android.gallery3d.app.PackagesMonitor
adb shell pm list receivers | grep gallery3d
```

read unactivate composant:
```
adb shell pm list packages -d
```
