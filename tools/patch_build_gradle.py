#!/usr/bin/env python3
"""Patches the `flutter create`-generated android/app/build.gradle so that:

- When android/key.properties + android/app/upload-keystore.jks exist (written
  by CI from the ANDROID_KEYSTORE_B64 secret), release builds are signed with
  that keystore.
- Otherwise release builds fall back to debug signing so the APK is still
  installable (useful for testing without secrets).

Run after `flutter create --platforms=android .`.
"""

import re
import sys


def main() -> None:
    path = sys.argv[1] if len(sys.argv) > 1 else "android/app/build.gradle"
    with open(path, encoding="utf-8") as f:
        content = f.read()

    keystore_loader = """def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

"""

    signing_block = """    signingConfigs {
        release {
            if (keystorePropertiesFile.exists()) {
                keyAlias keystoreProperties['keyAlias']
                keyPassword keystoreProperties['keyPassword']
                storeFile file(keystoreProperties['storeFile'])
                storePassword keystoreProperties['storePassword']
            }
        }
    }

"""

    # 1. Insert keystore loader right before the `android {` block.
    content = content.replace("android {", keystore_loader + "android {", 1)

    # 2. Insert signingConfigs into the android block.
    content = content.replace("android {", "android {" + "\n" + signing_block, 1)

    # 3. Point the release build type at our signing config (fallback: debug).
    release_signing = """        release {
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.release
            } else {
                signingConfig = signingConfigs.debug
            }
        }"""
    content = re.sub(
        r"release\s*\{[^}]*signingConfig[^}]*\}",
        release_signing,
        content,
        count=1,
    )

    with open(path, "w", encoding="utf-8") as f:
        f.write(content)

    print(f"patched {path}")


if __name__ == "__main__":
    main()
