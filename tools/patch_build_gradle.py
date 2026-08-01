#!/usr/bin/env python3
"""Patches the `flutter create`-generated android/app/build.gradle(.kts) so that:

- When android/key.properties + android/app/upload-keystore.jks exist (written
  by CI from the ANDROID_KEYSTORE_B64 secret), release builds are signed with
  that keystore.
- Otherwise release builds fall back to debug signing so the APK is still
  installable (useful for testing without secrets).

Run after `flutter create --platforms=android .`.
Supports both the legacy Groovy (build.gradle) and the current Kotlin DSL
(build.gradle.kts) templates.
"""

import re
import sys


def patch_groovy(path: str, content: str) -> str:
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

    return content


def patch_kotlin(path: str, content: str) -> str:
    # Ensure the imports the loader needs are present.
    for imp, default in (
        ("java.util.Properties", "import java.util.Properties"),
        ("java.io.FileInputStream", "import java.io.FileInputStream"),
    ):
        if imp not in content and default not in content:
            content = re.sub(r"(?m)^(import .*;?\n)*", default + "\n", content, count=1)

    keystore_loader = """
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasKeystoreProperties = keystorePropertiesFile.exists()
if (hasKeystoreProperties) {
    val inputStream = FileInputStream(keystorePropertiesFile)
    try {
        keystoreProperties.load(inputStream)
    } finally {
        inputStream.close()
    }
}

"""
    if "keystorePropertiesFile" not in content:
        content = content.replace("android {", keystore_loader + "android {", 1)

    signing_block = """
    signingConfigs {
        create("release") {
            if (hasKeystoreProperties) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }
"""
    if "create(\"release\")" not in content:
        content = content.replace("android {", "android {" + signing_block, 1)

    release_signing = """signingConfig = if (hasKeystoreProperties) {
        signingConfigs.getByName("release")
    } else {
        signingConfigs.getByName("debug")
    }"""

    def indent_block(block: str, indent: str) -> str:
        return "\n".join(
            (indent + line if line else "") for line in block.splitlines()
        )

    match = re.search(
        r"(?m)^(\s*)signingConfig = signingConfigs\.getByName\(\"debug\"\)", content
    )
    if match:
        block = indent_block(release_signing, match.group(1))
        content = content[: match.start()] + block + content[match.end() :]
    elif "signingConfig" not in content:
        def _repl(m: re.Match) -> str:
            block = indent_block(release_signing, m.group(1) + "    ")
            return m.group(0) + "\n" + block

        content = re.sub(r"(?m)^(\s*)release \{", _repl, content, count=1)

    return content


def main() -> None:
    path = sys.argv[1] if len(sys.argv) > 1 else "android/app/build.gradle"
    with open(path, encoding="utf-8") as f:
        content = f.read()

    if path.endswith(".kts"):
        content = patch_kotlin(path, content)
    else:
        content = patch_groovy(path, content)

    with open(path, "w", encoding="utf-8") as f:
        f.write(content)

    print(f"patched {path}")


if __name__ == "__main__":
    main()
