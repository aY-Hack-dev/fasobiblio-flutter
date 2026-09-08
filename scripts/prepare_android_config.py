"""Prepare optional CI Android config without exposing keys in logs."""
import base64
import json
import os
from pathlib import Path

root = Path('android')
config = os.environ.get('FIREBASE_GOOGLE_SERVICES_JSON', '')
if config:
    value = json.loads(config)
    packages = [item.get('client_info', {}).get('android_client_info', {}).get('package_name') for item in value.get('client', [])]
    if 'com.fasobiblio.app' not in packages:
        raise SystemExit('Firebase configuration does not contain com.fasobiblio.app')
    (root / 'app/google-services.json').write_text(config)

names = ['ANDROID_KEYSTORE_BASE64', 'ANDROID_STORE_PASSWORD', 'ANDROID_KEY_ALIAS', 'ANDROID_KEY_PASSWORD']
values = {name: os.environ.get(name, '') for name in names}
if any(values.values()) and not all(values.values()):
    raise SystemExit('Incomplete Android signing configuration')
if all(values.values()):
    key = root / 'release-upload.jks'
    key.write_bytes(base64.b64decode(values['ANDROID_KEYSTORE_BASE64'], validate=True))
    key.chmod(0o600)
    def escape(value):
        return value.replace('\\', '\\\\').replace('\n', '\\n').replace('\r', '\\r').replace(' ', '\\ ')
    properties = root / 'key.properties'
    properties.write_text('storeFile=release-upload.jks\n' + '\n'.join([
        f'storePassword={escape(values["ANDROID_STORE_PASSWORD"])}',
        f'keyAlias={escape(values["ANDROID_KEY_ALIAS"])}',
        f'keyPassword={escape(values["ANDROID_KEY_PASSWORD"])}',
    ]) + '\n')
    properties.chmod(0o600)
    mode = 'Signature de publication configurée.'
else:
    mode = 'APK de test : signature de développement. Ne pas publier comme mise à jour de production.'
print(mode)
summary = os.environ.get('GITHUB_STEP_SUMMARY')
if summary:
    with open(summary, 'a') as stream:
        stream.write(mode + '\n\n')
