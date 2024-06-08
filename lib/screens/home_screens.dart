import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/apis.dart';
import '../helper/dialogs.dart';
import '../main.dart';
import '../models/chat_user.dart';
import '../widgets/chat_user_card.dart';
import 'profile_screen.dart';

//home screen -- where all available contacts are shown
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // for storing all users
  List<ChatUser> _list = [];

  // for storing searched items
  final List<ChatUser> _searchList = [];
  // for storing search status
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    APIS.getSelfInfo();

    //for updating user active status according to lifecycle events
    //resume -- active or online
    //pause  -- inactive or offline
    SystemChannels.lifecycle.setMessageHandler((message) {
      log('Message: $message');

      if (APIS.auth.currentUser != null) {
        if (message.toString().contains('resume')) {
          APIS.updateActiveStatus(true);
        }
        if (message.toString().contains('pause')) {
          APIS.updateActiveStatus(false);
        }
      }

      return Future.value(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      //for hiding keyboard when a tap is detected on screen
      onTap: FocusScope.of(context).unfocus,
      child: PopScope(
        //if search is on & back button is pressed then close search
        //or else simple close current screen on back button click
        canPop: !_isSearching,
        onPopInvoked: (_) async {
          if (_isSearching) {
            setState(() => _isSearching = !_isSearching);
          } else {
            Navigator.of(context).pop();
          }
        },

        child: Scaffold(
          //app bar
          appBar: AppBar(
            leading: const Icon(CupertinoIcons.home),
            title: _isSearching
                ? TextField(
                    decoration: const InputDecoration(
                        border: InputBorder.none, hintText: 'Name, Email, ...'),
                    autofocus: true,
                    style: const TextStyle(fontSize: 17, letterSpacing: 0.5),
                    //when search text changes then updated search list
                    onChanged: (val) {
                      //search logic
                      _searchList.clear();

                      for (var i in _list) {
                        if (i.name.toLowerCase().contains(val.toLowerCase()) ||
                            i.email.toLowerCase().contains(val.toLowerCase())) {
                          _searchList.add(i);
                          setState(() {
                            _searchList;
                          });
                        }
                      }
                    },
                  )
                : const Text('Chit Chat'),
            actions: [
              //search user button
              IconButton(
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                    });
                  },
                  icon: Icon(_isSearching
                      ? CupertinoIcons.clear_circled_solid
                      : Icons.search)),

              //more features button
              IconButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ProfileScreen(user: APIS.me!)));
                  },
                  icon: const Icon(Icons.more_vert))
            ],
          ),

          //floating button to add new user
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FloatingActionButton(
                onPressed: () {
                  _addChatUserDialog();
                },
                child: const Icon(Icons.add_comment_rounded)),
          ),

          //body
          body: RefreshIndicator(
             onRefresh: () async {
    // Add your refresh logic here
    // For example, you can reload data from your API or Firestore
    setState(() {
      // Update your data here
    });
  },
            child: StreamBuilder(
              stream: APIS.getMyUsersId(),
            
              //get id of only known users
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  //if data is loading
                  case ConnectionState.waiting:
                  case ConnectionState.none:
                    return const Center(child: CircularProgressIndicator());
            
                  //if some or all data is loaded then show it
                  case ConnectionState.active:
                  case ConnectionState.done:
                    return StreamBuilder(
                      stream: APIS.getAllUsers(
                          snapshot.data?.docs.map((e) => e.id).toList() ?? []),
            
                      //get only those user, who's ids are provided
                      builder: (context, snapshot) {
                        switch (snapshot.connectionState) {
                          //if data is loading
                          case ConnectionState.waiting:
                          case ConnectionState.none:
                            return const Center(child: CircularProgressIndicator());
            
                          //if some or all data is loaded then show it
                          case ConnectionState.active:
                          case ConnectionState.done:
                            final data = snapshot.data?.docs;
                            _list = data
                                    ?.map((e) => ChatUser.fromJson(e.data()))
                                    .toList() ??
                                [];
                                
                          
                          
                            if (_list.isNotEmpty) {
                              return ListView.builder(
                                  itemCount: _isSearching
                                      ? _searchList.length
                                      : _list.length,
                                  padding: EdgeInsets.only(top: mq.height * .01),
                                  physics:  BouncingScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    return ChatUserCard(
                                        user: _isSearching
                                            ? _searchList[index]
                                            : _list[index]);
                                  });
                            } else {
                              return const Center(
                                child: Text('To Start Chat Press Below',
                                    style: TextStyle(fontSize: 20)),
                              );
                            }
                        }
                      },
                    );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  // for adding new chat user
  void _addChatUserDialog() async {
  List<ChatUser> allUsers = [];
  try {
    // Fetch all users
    final snapshot = await APIS.firestore.collection('users').get();
    allUsers = snapshot.docs.map((doc) => ChatUser.fromJson(doc.data())).toList();

    // Get the current user's email
    final currentUserEmail = APIS.auth.currentUser?.email;

    // Remove the current user and already added users from the list
    allUsers.removeWhere((user) =>
        user.email == currentUserEmail || _list.any((existingUser) => existingUser.email == user.email));
  } catch (e) {
    log('Error fetching users: $e');
    Dialogs.showSnackbar(context, 'Failed to load users');
  }

  showDialog(
      context: context,
      builder: (_) {
        List<ChatUser> selectedUsers = [];
        String email = '';

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              contentPadding: EdgeInsets.only(bottom: 8,top: 8,left: 8,right:8 ),
              insetPadding: EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(
                    Icons.person_add,
                    color: Colors.deepPurple.shade400,
                    size: 28,
                  ),
                  Text('  Add User')
                ],
              ),
              
              content: SingleChildScrollView(
                child: Container(
                  width: 300, // Specify your desired width here
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        maxLines: null,
                        onChanged: (value) => email = value,
                        decoration: InputDecoration(
                          hintText: 'Email Id',
                          prefixIcon: Icon(Icons.email, color: Colors.deepPurple.shade400),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      SizedBox(
                        height: 200, // Specify your desired height here
                        child: Scrollbar(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: allUsers.length,
                            itemBuilder: (context, index) {
                              return CheckboxListTile(
                                value: selectedUsers.contains(allUsers[index]),
                                title: Text(allUsers[index].email),
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      selectedUsers.add(allUsers[index]);
                                    } else {
                                      selectedUsers.remove(allUsers[index]);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
               actions: [
                MaterialButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Cancel',
                        style: TextStyle(
                            color: Colors.deepPurple.shade400,
                            fontSize: 16))),
                MaterialButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      if (email.isNotEmpty) {
                        await APIS.addChatUser(email).then((value) {
                          if (!value) {
                            Dialogs.showSnackbar(
                                context, 'User does not Exists!');
                          }
                        });
                      }
                      for (var user in selectedUsers) {
                        await APIS.addChatUser(user.email).then((value) {
                          if (!value) {
                            Dialogs.showSnackbar(
                                context, 'User ${user.email} does not Exist!');
                          }
                        });
                      }
                    },
                    child: Text(
                      'Add',
                      style: TextStyle(
                          color: Colors.deepPurple.shade400, fontSize: 16),
                    ))
              ],
            );
          },
        );
      });
}


}
