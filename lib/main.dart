// import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

var db;

// TODO:
// ✔ Color variable in database
// ✔ Update store color
// ✔ Sort variables (date)
// ✔ Deal with checked variables (cleanup)
// ✔ Add new store
// ✔ Delete stores
// Delete items
// ✔ Login
// Use geo data to sort stores
// Google Assistant tie-ins
// Personal and shared lists
bool logged_in = false;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // await FirebaseAuth.instance.signInWithEmailAndPassword(
  //     email: "test1@gmail.com", password: "password");
  // await FirebaseAuth.instance.createUserWithEmailAndPassword(
  //     email: "test1@gmail.com", password: "password");
  db = FirebaseFirestore.instance;
  // final costco = <String, dynamic>{
  //   "name": "costco",
  //   "items": {"Bread": false, "Milk": true, "Cheese": false, "Cucumbers": true},
  // };
  // db.collection("stores").add(costco);
  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user != null) {
      logged_in = true;
    } else {
      logged_in = false;
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        // colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // home: const MyHomePage(),
      routes: <String, WidgetBuilder>{
        '/': (_) => const Login(), // Login Page
        '/home': (_) => const MyHomePage(),
        '/user': (_) => const UserInfo(),
      },
      initialRoute: logged_in ? '/home' : '/',
    );
  }
}

class StoreItem {
  StoreItem(
      {required this.name,
      required this.map,
      required this.id,
      required this.storeColor});

  String name;
  Map<String, Map<String, dynamic>> map;
  String id;
  Color storeColor;

  void UpdateList() {
    print("update list");
    db.collection("stores").doc(id).update({"items": map});
  }

  void AddItem(String value) {
    map[value] = {
      "value": false,
      "timestamp": DateTime.now().millisecondsSinceEpoch
    };
    UpdateList();
  }

  void UpdateColor(Color newColor) {
    print("update color");
    db.collection("stores").doc(id).update({"color": newColor.value});
  }

  void UpdateName(String newName) {
    print("update name");
    db.collection("stores").doc(id).update({"name": newName});
  }

  void delete() async {
    await db.collection("stores").doc(id).delete();
  }

  void clearChecked() async {
    for (var key in map.keys) {
      if (map[key]!["value"] as bool) {
        db
            .collection("stores")
            .doc(id)
            .update({"items.${key}": FieldValue.delete()});
      }
    }
  }
}

class StoreList {
  List<StoreItem> list = [];

  Map<String, Map<String, dynamic>> processItems(Map<String, dynamic> inMap) {
    Map<String, Map<String, dynamic>> outMap = {};
    for (String key in inMap.keys) {
      outMap[key] = inMap[key];
    }
    return outMap;
  }

  StoreList(List<DocumentSnapshot> documents) {
    list = [];
    for (DocumentSnapshot doc in documents) {
      var data = (doc.data()! as Map);

      // TODO error catching
      list.add(StoreItem(
          name: data["name"],
          map: processItems(data["items"]),
          id: doc.id,
          storeColor: (data["color"] == null)
              ? const Color.fromARGB(255, 255, 0, 255)
              : Color(int.parse(data["color"].toString()))));
    }
  }

  void addStore(String name, Color color) {
    Map<String, dynamic> newStore = {
      "name": name,
      "items": {},
      "color": color.value,
    };
    print(newStore);
    db.collection("stores").add(newStore);
  }

  void clearChecked() {
    for (StoreItem store in list) {
      store.clearChecked();
    }
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  final String title = "Zɒpe";

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Stream<QuerySnapshot> _firestoreStream =
      FirebaseFirestore.instance.collection('stores').snapshots();

  // https://stackoverflow.com/questions/49778217/how-to-create-a-dialog-that-is-able-to-accept-text-input-and-show-result-in-flut
  // https://stackoverflow.com/questions/51962272/how-to-refresh-an-alertdialog-in-flutter
  final TextEditingController _nameFieldController = TextEditingController();
  final TextEditingController _colorFieldController = TextEditingController();
  late StoreList _stores;

  Future<void> _addStoreDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        String colorText = "";
        Color color = Colors.amber;
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add a new store'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  autofocus: true,
                  controller: _nameFieldController,
                  decoration: const InputDecoration(
                    hintText: "Store name",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                TextField(
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9]|[a-f]|[F-F]')),
                    LengthLimitingTextInputFormatter(6),
                    UpperCaseTextFormatter(),
                  ],
                  onChanged: (x) {
                    setState(() {
                      colorText = x;
                      color = colorText != ""
                          ? Color(int.parse("ff${colorText.padRight(6, '0')}",
                              radix: 16))
                          : Colors.amber;
                    });
                  },
                  style: const TextStyle(fontFamily: "monospace"),
                  controller: _colorFieldController,
                  decoration: InputDecoration(
                      hintText: "HEX Color",
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(
                        Icons.circle,
                        shadows: [Shadow(blurRadius: 10, color: Colors.grey)],
                      ),
                      prefixIconColor: color),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  _nameFieldController.clear();
                  _colorFieldController.clear();
                  Navigator.pop(context);
                },
              ),
              FilledButton(
                child: const Text('Add'),
                onPressed: () {
                  _stores.addStore(_nameFieldController.text, color);
                  _nameFieldController.clear();
                  _colorFieldController.clear();
                  Navigator.pop(context);
                },
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          widget.title,
          style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimary),
        ),
        actions: [
          IconButton.filledTonal(
            onPressed: () => Navigator.of(context).pushNamed("/user"),
            icon: Icon(
              Icons.person_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Text("Error");
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text("Loading");
          } else {
            // Get the data from firestore
            List<DocumentSnapshot> documents = snapshot.data!.docs
                .map((DocumentSnapshot document) => document)
                .toList();

            // Load the data into our structure
            print("Loaded data");
            _stores = StoreList(documents);

            // Generate the widgets
            return ListView(children: [
              for (var store in _stores.list) StoreThing(store: store),
              Padding(
                padding: const EdgeInsets.only(
                    left: 50.0, right: 50.0, top: 50.0, bottom: 50),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Please hold "Clear Checked" to confirm')));
                        },
                        onLongPress: () {
                          _stores.clearChecked();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                        child: const Text("Clear Checked")),
                    Spacer(),
                    FilledButton(
                        onPressed: () {
                          _addStoreDialog(context);
                        },
                        child: const Text("Add Store")),
                  ],
                ),
              )
            ]
                // https://stackoverflow.com/questions/21826342/how-do-i-combine-two-lists-in-dart
                );
          }
        },
      ),
    );
  }
}

class StoreThing extends StatefulWidget {
  const StoreThing({super.key, required this.store});

  final StoreItem store;

  @override
  State<StoreThing> createState() => _StoreThingState();
}

class _StoreThingState extends State<StoreThing> {
  final _controller = TextEditingController();

  final TextEditingController _nameFieldController = TextEditingController();
  final TextEditingController _colorFieldController = TextEditingController();

  Future<void> _editStoreDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        _nameFieldController.text = widget.store.name;
        _colorFieldController.text = widget.store.storeColor.value
            .toRadixString(16)
            .substring(2, 8)
            .toUpperCase();
        String colorText = _colorFieldController.text;
        Color color = Color(int.parse("ff$colorText", radix: 16));
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Store'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  autofocus: true,
                  controller: _nameFieldController,
                  decoration: const InputDecoration(
                    hintText: "Store name",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                TextField(
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9]|[a-f]|[F-F]')),
                    LengthLimitingTextInputFormatter(6),
                    UpperCaseTextFormatter(),
                  ],
                  onChanged: (x) {
                    setState(() {
                      colorText = x;
                      color = colorText != ""
                          ? Color(int.parse("ff${colorText.padRight(6, '0')}",
                              radix: 16))
                          : Colors.amber;
                    });
                  },
                  style: const TextStyle(fontFamily: "monospace"),
                  controller: _colorFieldController,
                  decoration: InputDecoration(
                      hintText: "HEX Color",
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(
                        Icons.circle,
                        shadows: [Shadow(blurRadius: 10, color: Colors.grey)],
                      ),
                      prefixIconColor: color),
                ),
              ],
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Please hold "Delete" to confirm')));
                },
                onLongPress: () {
                  widget.store.delete();
                  _nameFieldController.clear();
                  _colorFieldController.clear();
                  Navigator.pop(context);
                },
                child: const Text('Delete'),
              ),
              FilledButton(
                child: const Text('Save'),
                onPressed: () {
                  // store.addStore(_nameFieldController.text, color);
                  widget.store.UpdateColor(color);
                  widget.store.UpdateName(_nameFieldController.text);
                  _nameFieldController.clear();
                  _colorFieldController.clear();
                  Navigator.pop(context);
                },
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme =
        ColorScheme.fromSeed(seedColor: widget.store.storeColor);
    FocusNode myFocusNode = FocusNode();
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: colorScheme,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: colorScheme.primaryContainer),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                // Store title card
                children: [
                  GestureDetector(
                    onLongPress: () {
                      _editStoreDialog(context);
                    },
                    child: Card(
                      // color: colorScheme.primary,
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: LinearGradient(
                              colors: [
                                // colorScheme.primary,
                                colorScheme.primary,
                                colorScheme.primary,
                                // store.storeColor,
                                // colorScheme.primary,
                              ],
                              // begin: Alignment.topLeft,
                              // end: Alignment.bottomRight,
                            )),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 8,
                              ),
                              Text(
                                widget.store.name,
                                style: TextStyle(
                                    color: colorScheme.onPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                              // Spacer(),
                              // Text(
                              //   store.map.keys
                              //       .toList()
                              //       .where((x) {
                              //         return !store.map[x]!['value'];
                              //       })
                              //       .length
                              //       .toString(),
                              //   style: TextStyle(
                              //       color: colorScheme.onPrimary,
                              //       fontSize: 18,
                              //       fontWeight: FontWeight.normal),
                              // ),
                              // SizedBox(
                              //   width: 8,
                              // )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        bottom: 8.0, left: 10.0, right: 8.0),
                    child: TextField(
                      focusNode: myFocusNode,
                      controller: _controller,
                      onSubmitted: (value) {
                        widget.store.AddItem(value);
                        _controller.clear();
                      },
                      onTapOutside: (event) {
                        FocusScope.of(context).unfocus();
                      },
                      decoration: InputDecoration(
                        fillColor: colorScheme.secondaryContainer,
                        filled: true,
                        prefixIcon: const Icon(Icons.add),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        hintText: "New item",
                      ),
                    ),
                  ),
                  for (String key in widget.store.map.keys.toList()
                    ..sort((a, b) {
                      // if ((store.map[b]!['value'] as bool) !=
                      //     (store.map[a]!['value'] as bool)) {
                      //   return (store.map[b]!['value'] as bool) ? -1 : 1;
                      // }
                      return (widget.store.map[b]!['timestamp'] as int)
                          .compareTo(widget.store.map[a]!['timestamp'] as int);
                    }))
                    InkWell(
                      onTap: () {
                        widget.store.map[key]!['value'] =
                            !widget.store.map[key]!['value'];
                        widget.store.UpdateList();
                      },
                      child: Row(
                        children: [
                          IgnorePointer(
                            child: Checkbox(
                              value: widget.store.map[key]!['value'],
                              onChanged: (_) {},
                            ),
                          ),
                          Flexible(
                            child: Text(
                              key,
                              style: TextStyle(
                                  color: widget.store.map[key]!['value']
                                      ? Color.fromARGB(
                                          // colorScheme.onPrimaryContainer.alpha,
                                          100,
                                          colorScheme.onPrimaryContainer.red,
                                          colorScheme.onPrimaryContainer.green,
                                          colorScheme.onPrimaryContainer.blue)
                                      : colorScheme.onPrimaryContainer,
                                  fontSize: 18,
                                  decoration: widget.store.map[key]!['value']
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none),
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          )
                        ],
                      ),
                    ),
                  const SizedBox(
                    height: 10,
                  )
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
        ],
      ),
    );
  }
}

// The login page
class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController nameFieldController = TextEditingController();
    TextEditingController pwdFieldController = TextEditingController();

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              LayoutBuilder(builder: (context, constraint) {
                return Icon(
                  Icons.shopping_bag_outlined,
                  size: 200,
                  color: Theme.of(context).colorScheme.primary,
                );
              }),
              const SizedBox(
                height: 20,
              ),
              TextField(
                controller: nameFieldController,
                decoration: const InputDecoration(
                  fillColor: Colors.white,
                  filled: true,
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(
                      // borderRadius: ,
                      ),
                  hintText: "E-Mail",
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              TextField(
                obscureText: true,
                controller: pwdFieldController,
                decoration: const InputDecoration(
                  fillColor: Colors.white,
                  filled: true,
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(
                      // borderRadius: ,
                      ),
                  hintText: "Password",
                ),
              ),
              const SizedBox(
                height: 10,
              ),

              // The button on pressed, logs-in the user to and shows Home Page
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                        onPressed: () async {
                          bool error = false;
                          try {
                            await FirebaseAuth.instance
                                .createUserWithEmailAndPassword(
                                    email: nameFieldController.text,
                                    password: pwdFieldController.text);
                          } catch (e) {
                            error = true;
                            String errorMessage = "Unknown sign up error";

                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              duration: const Duration(seconds: 5),
                              content: Text(
                                errorMessage,
                                style: TextStyle(
                                    fontSize: 15,
                                    color:
                                        Theme.of(context).colorScheme.onError),
                              ),
                              backgroundColor:
                                  Theme.of(context).colorScheme.error,
                            ));
                          }
                          if (!error) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              duration: const Duration(seconds: 5),
                              content: Text(
                                "Signup Successful! Please log in.",
                                style: TextStyle(
                                    fontSize: 15, color: Colors.white),
                              ),
                              backgroundColor: Colors.green,
                            ));
                          }
                        },
                        // Navigator.of(context).pushNamed("/signUp"),
                        child: const Text("SignUp")),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: FilledButton(
                        onPressed: () async {
                          bool error = false;
                          try {
                            await FirebaseAuth.instance
                                .signInWithEmailAndPassword(
                                    email: nameFieldController.text,
                                    password: pwdFieldController.text);
                          } on FirebaseAuthException catch (e) {
                            error = true;
                            String errorMessage = "Unknown login error";
                            if (e.code == 'user-not-found') {
                              errorMessage = "No user found for that email.";
                            } else if (e.code == 'invalid-credential') {
                              errorMessage =
                                  "Wrong password provided for that user.";
                            } else if (e.code == 'invalid-email') {
                              errorMessage = "Email is badly formatted.";
                            }
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              duration: const Duration(seconds: 5),
                              content: Text(
                                errorMessage,
                                style: TextStyle(
                                    fontSize: 15,
                                    color:
                                        Theme.of(context).colorScheme.onError),
                              ),
                              backgroundColor:
                                  Theme.of(context).colorScheme.error,
                            ));
                          }
                          if (!error) {
                            Navigator.of(context).pushReplacementNamed("/home");
                          }
                        },
                        child: const Text("Login")),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// The user info page
class UserInfo extends StatelessWidget {
  const UserInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "User info",
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimary),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton.filledTonal(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.primary,
            ),
          )
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              LayoutBuilder(builder: (context, constraint) {
                return Icon(
                  Icons.question_mark_rounded,
                  size: 200,
                  color: Theme.of(context).colorScheme.primary,
                );
              }),
              FilledButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed("/");
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    "Log out",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
