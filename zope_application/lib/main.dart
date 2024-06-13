import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

var db;

// TODO:
// ✔ Color variable in database
// ✔ Update store color
// ✔ Sort variables (date)
// Deal with checked variables (cleanup)
// ✔ Add new store
// ✔ Delete stores
// Delete items
// Login
// Use geo data to sort stores

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: "test1@gmail.com", password: "password");
  // await FirebaseAuth.instance.createUserWithEmailAndPassword(
  //     email: "test1@gmail.com", password: "password");
  db = FirebaseFirestore.instance;
  // final costco = <String, dynamic>{
  //   "name": "costco",
  //   "items": {"Bread": false, "Milk": true, "Cheese": false, "Cucumbers": true},
  // };
  // db.collection("stores").add(costco);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        // colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
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
              ? Color.fromARGB(255, 255, 0, 255)
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
  TextEditingController _nameFieldController = TextEditingController();
  TextEditingController _colorFieldController = TextEditingController();
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
                  decoration: InputDecoration(
                    hintText: "Store name",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(
                  height: 5,
                ),
                TextField(
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9]|[a-f]|[F-F]')),
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onChanged: (x) {
                    setState(() {
                      colorText = x;
                      color = colorText != ""
                          ? Color(int.parse(
                              "ff${colorText.padRight(7, '0').substring(0, 6)}",
                              radix: 16))
                          : Colors.amber;
                    });
                  },
                  style: TextStyle(fontFamily: "monospace"),
                  controller: _colorFieldController,
                  decoration: InputDecoration(
                      hintText: "HEX Color",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.circle,
                        shadows: [Shadow(blurRadius: 10, color: Colors.grey)],
                      ),
                      prefixIconColor: color),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  _nameFieldController.clear();
                  _colorFieldController.clear();
                  Navigator.pop(context);
                },
              ),
              FilledButton(
                child: Text('Add'),
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
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          widget.title,
          style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimary),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('This is a snackbar')));
            },
            icon: Icon(
              Icons.person_rounded,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text("Error");
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return Text("Loading");
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
                child: FilledButton(
                    onPressed: () {
                      _addStoreDialog(context);
                    },
                    child: Text("Add Store")),
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

class StoreThing extends StatelessWidget {
  StoreThing({super.key, required this.store});

  final StoreItem store;

  final _controller = TextEditingController();

  TextEditingController _nameFieldController = TextEditingController();
  TextEditingController _colorFieldController = TextEditingController();

  Future<void> _editStoreDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        _nameFieldController.text = store.name;
        _colorFieldController.text =
            store.storeColor.value.toRadixString(16).substring(1, 7);
        String colorText = _colorFieldController.text;
        Color color = Color(int.parse(
            "ff${colorText.padRight(7, '0').substring(1, 7)}",
            radix: 16));
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Store'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  autofocus: true,
                  controller: _nameFieldController,
                  decoration: InputDecoration(
                    hintText: "Store name",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(
                  height: 5,
                ),
                TextField(
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9]|[a-f]|[F-F]')),
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onChanged: (x) {
                    setState(() {
                      colorText = x;
                      color = colorText != ""
                          ? Color(int.parse(
                              "ff${colorText.padRight(7, '0').substring(1, 7)}",
                              radix: 16))
                          : Colors.amber;
                    });
                  },
                  style: TextStyle(fontFamily: "monospace"),
                  controller: _colorFieldController,
                  decoration: InputDecoration(
                      hintText: "HEX Color",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.circle,
                        shadows: [Shadow(blurRadius: 10, color: Colors.grey)],
                      ),
                      prefixIconColor: color),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text('Delete'),
                style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Please hold "Delete" to confirm')));
                },
                onLongPress: () {
                  store.delete();
                  _nameFieldController.clear();
                  _colorFieldController.clear();
                  Navigator.pop(context);
                },
              ),
              FilledButton(
                child: Text('Save'),
                onPressed: () {
                  // store.addStore(_nameFieldController.text, color);
                  store.UpdateColor(color);
                  store.UpdateName(_nameFieldController.text);
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
    ColorScheme colorScheme = ColorScheme.fromSeed(seedColor: store.storeColor);
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
                              SizedBox(
                                width: 8,
                              ),
                              Text(
                                store.name,
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
                      onEditingComplete: () {
                        FocusScope.of(context).unfocus();
                      },
                      onSubmitted: (value) {
                        store.AddItem(value);
                        _controller.clear();
                        myFocusNode.requestFocus();
                      },
                      onTapOutside: (event) {
                        FocusScope.of(context).unfocus();
                      },
                      decoration: InputDecoration(
                        fillColor: colorScheme.secondaryContainer,
                        filled: true,
                        prefixIcon: Icon(Icons.add),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        hintText: "New item",
                      ),
                    ),
                  ),
                  for (String key in store.map.keys.toList()
                    ..sort((a, b) {
                      // if ((store.map[b]!['value'] as bool) !=
                      //     (store.map[a]!['value'] as bool)) {
                      //   return (store.map[b]!['value'] as bool) ? -1 : 1;
                      // }
                      return (store.map[b]!['timestamp'] as int)
                          .compareTo(store.map[a]!['timestamp'] as int);
                    }))
                    InkWell(
                      onTap: () {
                        store.map[key]!['value'] = !store.map[key]!['value'];
                        store.UpdateList();
                      },
                      child: Row(
                        children: [
                          IgnorePointer(
                            child: Checkbox(
                              value: store.map[key]!['value'],
                              onChanged: (_) {},
                            ),
                          ),
                          Text(
                            key,
                            style: TextStyle(
                                color: store.map[key]!['value']
                                    ? Color.fromARGB(
                                        // colorScheme.onPrimaryContainer.alpha,
                                        100,
                                        colorScheme.onPrimaryContainer.red,
                                        colorScheme.onPrimaryContainer.green,
                                        colorScheme.onPrimaryContainer.blue)
                                    : colorScheme.onPrimaryContainer,
                                fontSize: 18,
                                decoration: store.map[key]!['value']
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none),
                          )
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 10,
          ),
        ],
      ),
    );
  }
}
