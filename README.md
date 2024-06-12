# zope

## Setup

1. Setup the dev container

2. run flutterfire configure
```
curl -sL https://firebase.tools | bash
firebase login
dart pub global activate flutterfire_cli
export PATH="$PATH":"$HOME/.pub-cache/bin"
flutterfire configure
```