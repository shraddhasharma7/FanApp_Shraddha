import 'package:fan_app_shraddha/Start.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:developer';
import 'package:uuid/uuid.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late User user;
  bool isloggedin = false;

  checkAuthentification() async {
    _auth.authStateChanges().listen((user) async {
      if (user == null) {
        Navigator.of(context).pushReplacementNamed("start");
      } else {
        getUserData(user.uid).then((QuerySnapshot docs) {
          if (docs.docs.isNotEmpty) {
            var test = docs.docs[0].data();

            if (test['role'] == 'admin') hideWidget();
          }
        });
      }
    });
  }

  getUserData(String userID) {
    print('user id is');
    print(userID);
    return FirebaseFirestore.instance
        .collection('userList')
        .where('user id', isEqualTo: userID)
        .get();
  }

  bool _canShowButton = false;

  void hideWidget() {
    setState(() {
      _canShowButton = !_canShowButton;
    });
  }

  getUser() async {
    User firebaseUser = _auth.currentUser;
    await firebaseUser.reload();
    firebaseUser = _auth.currentUser;

    if (firebaseUser != null) {
      setState(() {
        this.user = firebaseUser;
        this.isloggedin = true;
      });
    }
  }

  signOut() async {
    _auth.signOut();

    final googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
  }

  @override
  void initState() {
    super.initState();
    this.checkAuthentification();
    this.getUser();
  }

  TextEditingController _textFieldController = TextEditingController();
  Future<void> _displayTextInputDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Message'),
            content: TextField(
              onChanged: (value) {
                setState(() {
                  valueText = value;
                });
              },
              controller: _textFieldController,
              decoration: InputDecoration(hintText: "Add your post here.."),
            ),
            actions: <Widget>[
              ElevatedButton(
                child: Text('CANCEL'),
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
              ElevatedButton(
                child: Text('POST MESSAGE'),
                onPressed: () {
                  FirebaseFirestore.instance.collection('postList').add({
                    'message': valueText,
                    'date': new DateTime.now(),
                    'messageId': Uuid().v4()
                  });
                  setState(() {
                    codeDialog = valueText;
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          );
        });
  }

  late String codeDialog;
  late String valueText;

  showSignoutAlert() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(title: Text('SIGN OUT'), actions: <Widget>[
            ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Cancel')),
            ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  signOut();
                },
                child: Text('OK'))
          ]);
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Home Screen"),
          actions: <Widget>[
            ElevatedButton(
                style: ElevatedButton.styleFrom(primary: Colors.blue),
                onPressed: showSignoutAlert,
                child: Text(
                  'Signout',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ))
          ],
        ),
        body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('postList')
              .orderBy('message', descending: false)
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
            return ListView(
              children: snapshot.data!.docs.map((document) {
                return Container(
                  child: Center(child: Text(document['message'])),
                  height: 50,
                );
              }).toList(),
            );
          },
        ),
        floatingActionButton: !_canShowButton
            ? const SizedBox.shrink()
            : FloatingActionButton(
                onPressed: () {
                  _textFieldController.text = "";
                  _displayTextInputDialog(context);
                },
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                ),
              ));
  }
}
