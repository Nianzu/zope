# zope

## Setup

1. Setup the dev container

2. Install android studio
Make sure x11-forwarding is working:
  `xhost +local:docker`
```
cd /workspaces/android-studio/bin
./studio.sh
``` 

3. run flutterfire configure
```
curl -sL https://firebase.tools | bash
firebase login
dart pub global activate flutterfire_cli
export PATH="$PATH":"$HOME/.pub-cache/bin"
cd /workspaces/zope/zope_application/
flutterfire configure
flutter pub get
```