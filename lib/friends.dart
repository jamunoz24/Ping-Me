import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// FRIENDS PAGE CLASS
class FriendsPage extends StatefulWidget {
  const FriendsPage({Key? key}) : super(key: key);
  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  // FRIEND LIST ENTRY WIDGET FUNCTION
  var firebaseUser = FirebaseAuth.instance.currentUser;
  final firestoreInstance = FirebaseFirestore.instance;
  final emailController = TextEditingController();
  List<dynamic>? friendsList;
  String friendUID = '';

  // Building FriendsList
  @override
  initState() {
    super.initState();
    _getFriendsList().whenComplete(() {
      setState(() {});
    });
  }

  _getFriendsList() async {
    await firestoreInstance
        .collection('friends')
        .doc(firebaseUser?.uid)
        .get()
        .then((value) {
      friendsList = value.data()!['friendsList'];
    });
  }

  // Error Codes
  bool _incompleteForm = false;
  bool _friendDoesNotExist = false;

  bool _switch = false;
  Widget friendEntry(String entry) => SwitchListTile(
        title: Text(entry, style: const TextStyle(color: Colors.black)),
        value: _switch,
        onChanged: (bool value) {
          setState(() {
            _switch = value;
          });
        },
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PingMates'),
        centerTitle: true,
      ),
      body: Center(
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: <Widget>[
            // ListView builder for friend entries
            if (friendsList != null) ...[
              for (var i in friendsList!) friendEntry(i.toString())
            ]
          ],
        ),
      ),
      // ADD FRIEND WINDOW
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) => AlertDialog(
                      title: const Text('Add Friend'),
                      content: TextField(
                        controller: emailController,
                        textAlign: TextAlign.center,
                        decoration:
                            const InputDecoration(labelText: 'Enter an Email'),
                      ),
                      actions: <Widget>[
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel')),
                        // ADD FRIEND BUTTON
                        TextButton(
                            onPressed: () async {
                              // First getting the friend UID to confirm it's existance
                              _incompleteForm = emailController.text == '';
                              if (!_incompleteForm) {
                                await firestoreInstance
                                    .collection('userIDs')
                                    .doc(emailController.text)
                                    .get()
                                    .then((snapshot) {
                                  friendUID = snapshot.data().toString();
                                });
                              }
                              _friendDoesNotExist =
                                  friendUID == 'null' || friendUID == '';
                              // Friend exists so now we add em
                              if (!_friendDoesNotExist) {
                                await firestoreInstance
                                    .collection('friends')
                                    .doc(firebaseUser?.uid)
                                    .update({
                                  // Appending to field array
                                  "friendsList": FieldValue.arrayUnion(
                                      [emailController.text]),
                                });
                                setState(() {});
                                Navigator.pop(context);
                              }
                            },
                            child: const Text('Ok'))
                      ]));
        },
      ),
    );
  }
}
