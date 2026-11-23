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
if "android.permission.INTERNET" not in man:
    man = re.sub(r"(<manifest[^>]*>)", r'\1\n    <uses-permission android:name="android.permission.INTERNET"/>', man, count=1)
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
sys.exit(0)
