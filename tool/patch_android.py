"""Dijalankan otomatis oleh GitHub Actions setelah `flutter create`.
Mengatur nama aplikasi, izin internet, target SDK Play Store,
dan tanda tangan (keystore) untuk rilis Play Store."""
import os
import re
import sys

NAMA_APP = "Safari Maulid"
TARGET_SDK = "35"

man_path = "android/app/src/main/AndroidManifest.xml"
man = open(man_path, encoding="utf-8").read()
man = re.sub(r'android:label="[^"]*"', f'android:label="{NAMA_APP}"', man, count=1)
IZIN = """
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-feature android:name="android.hardware.camera" android:required="false"/>"""
if "android.permission.CAMERA" not in man:
    man = re.sub(r"(<manifest[^>]*>)", lambda m: m.group(1) + IZIN, man, count=1)
intents = """
        <intent><action android:name="android.intent.action.VIEW" /><data android:scheme="https" /></intent>
        <intent><action android:name="android.intent.action.VIEW" /><data android:scheme="http" /></intent>
        <intent><action android:name="android.intent.action.DIAL" /><data android:scheme="tel" /></intent>
        <intent><action android:name="android.intent.action.VIEW" /><data android:scheme="tel" /></intent>
    </queries>"""
if "</queries>" in man:
    man = man.replace("</queries>", intents.lstrip("\n"), 1)
else:
    man = man.replace("</manifest>", "    <queries>" + intents + "\n</manifest>", 1)
open(man_path, "w", encoding="utf-8").write(man)
print("Manifest OK")

kts = os.path.exists("android/app/build.gradle.kts")
g_path = "android/app/build.gradle.kts" if kts else "android/app/build.gradle"
g = open(g_path, encoding="utf-8").read()

g = re.sub(r"targetSdk(Version)?\s*=?\s*flutter\.targetSdkVersion", f"targetSdk = {TARGET_SDK}", g)
g = re.sub(r"compileSdk(Version)?\s*=?\s*flutter\.compileSdkVersion", f"compileSdk = {TARGET_SDK}", g)

if os.environ.get("KEYSTORE_BASE64", "").strip():
    if kts:
        blok = """    signingConfigs {
        create("release") {
            storeFile = file(System.getenv("KS_PATH"))
            storePassword = System.getenv("KEYSTORE_PASSWORD")
            keyAlias = System.getenv("KEY_ALIAS")
            keyPassword = System.getenv("KEY_PASSWORD")
        }
    }

    buildTypes {"""
        g = g.replace("    buildTypes {", blok, 1)
        g = g.replace('signingConfigs.getByName("debug")', 'signingConfigs.getByName("release")')
    else:
        blok = """    signingConfigs {
        release {
            storeFile file(System.getenv("KS_PATH"))
            storePassword System.getenv("KEYSTORE_PASSWORD")
            keyAlias System.getenv("KEY_ALIAS")
            keyPassword System.getenv("KEY_PASSWORD")
        }
    }

    buildTypes {"""
        g = g.replace("    buildTypes {", blok, 1)
        g = re.sub(r"signingConfig\s*=?\s*signingConfigs\.debug", "signingConfig = signingConfigs.release", g)
    print("Signing rilis: AKTIF (keystore dari GitHub Secrets)")
else:
    print("Signing rilis: memakai kunci debug (belum ada KEYSTORE_BASE64) - APK bisa dipasang, tapi belum bisa ke Play Store")

open(g_path, "w", encoding="utf-8").write(g)
print(g_path, "OK")


# ---------- MainActivity: saluran "safarimaulid/layar" agar layar tetap menyala di halaman kitab
import glob
akt = [f for f in glob.glob("android/app/src/main/**/MainActivity.*", recursive=True) if f.endswith((".kt", ".java"))]
if akt:
    path = akt[0]
    src = open(path, encoding="utf-8").read()
    paket = re.search(r"^package\s+([\w.]+)", src, re.M).group(1)
    kt_path = os.path.splitext(path)[0] + ".kt"
    if path != kt_path:
        os.remove(path)
    open(kt_path, "w", encoding="utf-8").write(f"""package {paket}

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {{
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {{
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "safarimaulid/layar")
            .setMethodCallHandler {{ call, result ->
                if (call.method == "nyala") {{
                    val nyala = call.arguments as? Boolean ?: false
                    runOnUiThread {{
                        if (nyala) window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        else window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    }}
                    result.success(null)
                }} else {{
                    result.notImplemented()
                }}
            }}
    }}
}}
""")
    print("MainActivity OK:", kt_path)
else:
    print("MainActivity tidak ditemukan")

sys.exit(0)
