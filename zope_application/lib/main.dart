import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

var db;

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
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class ShoppingItem {
  String name;
  bool checked;

  ShoppingItem(this.name, {this.checked = false});
}

class StoreItem {
  String name;
  List<ShoppingItem> list;

  StoreItem(this.name, this.list);
}

class StoreList {
  List<StoreItem> list = [];

  StoreList(var data) {
    list = [];
    for (var store in data) {
      StoreItem store_item = StoreItem(store["name"], []);
      for (var item in store["items"].keys) {
        ShoppingItem shopping_item =
            ShoppingItem(item, checked: store["items"][item]);
        store_item.list.add(shopping_item);
      }
      list.add(store_item);
    }
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  final String title = "Zope";

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Stream<QuerySnapshot> _firestoreStream =
      FirebaseFirestore.instance.collection('stores').snapshots();

  List<Widget> getStoreThings(StoreItem store) {
    List<Widget> list = [];

    // list.add(Card(
    list.add(Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(store.name),
      ),
    ));

    for (ShoppingItem item in store.list) {
      list.add(InkWell(
        onTap: () {
          setState(() {
            item.checked = !item.checked;
          });
        },
        child: Row(
          children: [
            Checkbox(
              value: item.checked,
              onChanged: (bool? value) {
                setState(() {
                  item.checked = value!;
                });
              },
            ),
            Text(item.name)
          ],
        ),
      ));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
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
            var data = snapshot.data!.docs
                .map((DocumentSnapshot document) => document.data());

            // Load the data into our structure
            print("Loaded data");
            StoreList stores = StoreList(data);

            // Generate the widgets
            return ListView(
              children: [for (var store in stores.list) getStoreThings(store)]
                  .expand((x) => x)
                  .toList(),
              // https://stackoverflow.com/questions/21826342/how-do-i-combine-two-lists-in-dart
            );
          }
        },
      ),
    );
  }
}
