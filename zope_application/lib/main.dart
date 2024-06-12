import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

var db;

// TODO:
// Color variable in database
// Sort variables (date)
// Deal with checked variables
// Add new store
// Delete things (items, stores)
// Login

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
      title: 'Flutter Demo',
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
  StoreItem({required this.name, required this.map, required this.id});
  // StoreItem.fromMap(Map<String, Object?> inMap)
  //     : this(
  //         name: inMap['name']! as String,
  //         map: inMap['items']! as Map<String, bool>,
  //       );
  // Map<String, Object?> toMap() {
  //   return {
  //     'name': name,
  //     'items': map,
  //   };
  // }

  String name;
  Map<String, dynamic> map;
  String id;

  void UpdateList() {
    print("update list");
    db.collection("stores").doc(id).update({"items": map});
  }

  void AddItem(String value) {
    map[value] = false;
    UpdateList();
  }
}

class StoreList {
  List<StoreItem> list = [];

  StoreList(List<DocumentSnapshot> documents) {
    list = [];
    for (DocumentSnapshot doc in documents) {
      var data = (doc.data()! as Map);

      // TODO error catching
      list.add(StoreItem(name: data["name"], map: data["items"], id: doc.id));
    }
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

  List<Widget> getStoreThings(StoreItem store) {
    List<Widget> list = [];

    // Store title card
    list.add(Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(store.name),
      ),
    ));

    // Text entry for new item
    var _controller = TextEditingController();
    list.add(Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 10.0, right: 8.0),
      child: TextField(
        controller: _controller,
        onEditingComplete: () {
          FocusScope.of(context).unfocus();
        },
        onSubmitted: (value) {
          store.AddItem(value);
          _controller.clear();
        },
        onTapOutside: (event) {
          FocusScope.of(context).unfocus();
        },
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.add),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          hintText: "New item",
        ),
      ),
    ));

    for (String key in store.map.keys) {
      list.add(InkWell(
        onTap: () {
          setState(() {
            store.map[key] = !store.map[key]!;
            store.UpdateList();
          });
        },
        child: Row(
          children: [
            Checkbox(
              value: store.map[key],
              onChanged: (bool? value) {
                setState(() {
                  store.map[key] = value!;
                  store.UpdateList();
                });
              },
            ),
            Text(key)
          ],
        ),
      ));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('This is a snackbar')));
              },
              icon: const Icon(Icons.person_rounded))
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
            StoreList stores = StoreList(documents);

            // Generate the widgets
            return ListView(children: [
              for (var store in stores.list) StoreThing(store: store)
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

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        // colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // Store title card
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Text(store.name),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 10.0, right: 8.0),
            child: TextField(
              controller: _controller,
              onEditingComplete: () {
                FocusScope.of(context).unfocus();
              },
              onSubmitted: (value) {
                store.AddItem(value);
                _controller.clear();
              },
              onTapOutside: (event) {
                FocusScope.of(context).unfocus();
              },
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.add),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                hintText: "New item",
              ),
            ),
          ),
          for (String key in store.map.keys.toList()..sort())
            InkWell(
              onTap: () {
                store.map[key] = !store.map[key]!;
                store.UpdateList();
              },
              child: Row(
                children: [
                  IgnorePointer(
                    child: Checkbox(
                      value: store.map[key],
                      onChanged: (_) {},
                    ),
                  ),
                  Text(key)
                ],
              ),
            )
        ],
      ),
    );
  }
}
