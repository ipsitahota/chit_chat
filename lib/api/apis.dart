import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:frnds_chat/models/chat_user.dart';
import 'package:frnds_chat/models/message.dart';

class APIS {
  static FirebaseAuth auth = FirebaseAuth.instance;

  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  static FirebaseStorage storage = FirebaseStorage.instance;

  static ChatUser? me;
  static User get user => auth.currentUser!;

  static Future<bool> userExists() async {
    return (await firestore.collection('users').doc(user.uid).get()).exists;
  }

  static Future<void> getSelfInfo() async {
    await firestore.collection('users').doc(user.uid).get().then((user) async {
      if (user.exists) {
        me = ChatUser.fromJson(user.data()!);
        await getfirebaseMessagingToken();

        APIS.updateActiveStatus(true);
        log('My Data: ${user.data()!}');
      } else {
        await createUser().then((value) => getSelfInfo());
      }
    });
  }

  static Future<void> createUser() async {
    final time = DateTime.now(); //used for below user time

    final chatUser = ChatUser(
        image: user.photoURL.toString(),
        about: "Hey am using Chit chat!",
        name: user.displayName.toString(),
        createdAt: time,
        id: user.uid,
        lastActive: time,
        isOnline: false,
        email: user.email.toString(),
        pushToken: '');
    return await firestore
        .collection('users')
        .doc(user.uid)
        .set(chatUser.toJson());
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getMyUsersId() {
    return firestore
        .collection('users')
        .doc(user.uid)
        .collection('my_users')
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers(List<String> userIds) {
  log('\nUserIds:$userIds');
  if (userIds.isNotEmpty) {
    return firestore
        .collection('users')
        .where('id', whereIn: userIds)
        .snapshots();
  } else {
    // Return an empty stream or handle this case based on your application's logic
    return Stream.empty();
  }
}





  static Future<void> updateuserInfo() async {
    await firestore
        .collection('users')
        .doc(user.uid)
        .update({'name': me?.name, 'about': me?.about});
  }

  static Future<void> updateprofilePicture(File file) async {
    final ext = file.path.split('.').last;
    log('extension: $ext');

    final ref = storage.ref().child('profile-pictures/${user.uid}.$ext');

    await ref
        .putFile(file, SettableMetadata(contentType: 'image?$ext'))
        .then((p0) {
      log('Data Transferred:${p0.bytesTransferred / 1000} kb');
    });
    me?.image = await ref.getDownloadURL();
    await firestore
        .collection('users')
        .doc(user.uid)
        .update({'image': me?.image});
  }

  // Modify the getAllMessages method to ensure proper message retrieval
static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(ChatUser user) {
  return firestore.collection('chats/${getConversationID(user.id)}/messages/')
      .orderBy('sent', descending: true)
      .snapshots();
}



  static String getConversationID(String id) => user.uid.hashCode <= id.hashCode
      ? '${user.uid}_$id'
      : '${id}_${user.uid}';


//------------------------------------------------------------------------------------------------------------------------------------
  static Future<void> sendMessage(ChatUser chatUser, String msg, Type type) async {
    final time = DateTime.now();
    final Message message = Message(
      msg: msg,
      toid: chatUser.id,
      read: null,
      type: type,
      sent: time,
      fromid: user.uid,
    );

    final ref = firestore.collection('chats/${getConversationID(chatUser.id)}/messages/');
    try {
        await ref.doc(time.millisecondsSinceEpoch.toString()).set(message.toJson());
        log('Message sent successfully');
    } catch (error) {
        log('Failed to send message: $error');
    }
}


//---------------------------------------------------------------------------------------------------------------------------------


  // Modify the sendFirstMessage method to ensure proper message sending
static Future<void> sendFirstMessage(ChatUser chatUser, String msg, Type type) async {
    try {
        final senderDocRef = firestore.collection('users').doc(user.uid).collection('my_users').doc(chatUser.id);
        final receiverDocRef = firestore.collection('users').doc(chatUser.id).collection('my_users').doc(user.uid);

        log('Checking if sender and receiver documents exist...');
        final senderDocSnapshot = await senderDocRef.get();
        final receiverDocSnapshot = await receiverDocRef.get();

        log('Sender Doc Exists: ${senderDocSnapshot.exists}');
        log('Receiver Doc Exists: ${receiverDocSnapshot.exists}');

        if (!senderDocSnapshot.exists) {
            log('Creating sender document...');
            await senderDocRef.set({});
            log('Sender document created');
        }

        if (!receiverDocSnapshot.exists) {
            log('Creating receiver document...');
            await receiverDocRef.set({});
            log('Receiver document created');
        }

        log('Double-checking the receiver document creation...');
        final newReceiverDocSnapshot = await receiverDocRef.get();
        if (!newReceiverDocSnapshot.exists) {
            log('Receiver document creation failed.');
            return;
        }

        log('Sending the message...');
        await sendMessage(chatUser, msg, type);
        log('Message sent successfully');
    } catch (error) {
        log('Error sending first message: $error');
    }
}





  static Future<void> updateMessageReadStatus(Message message) async {
    try {
      //log('seen');
      final docRef = firestore
          .collection('chats/${getConversationID(message.fromid)}/messages/')
          .doc(message.sent.millisecondsSinceEpoch.toString());

      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        await docRef.update({'read': DateTime.now()});
        log('Message read status updated in Firestore');
      } else {
        log('Document not found: ${docRef.path}');
      }
    } catch (e) {
      log('Failed to update message read status: $e');
    }
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessage(
      ChatUser user) {
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages/')
        .orderBy('sent', descending: true)
        .limit(1)
        .snapshots();
  }

  static Future<void> sendChatImage(ChatUser chatUser, File file) async {
    final ext = file.path.split('.').last;
    final ref = storage.ref().child(
        'images/${getConversationID(chatUser.id)}/${DateTime.now().millisecondsSinceEpoch}.$ext');

    await ref
        .putFile(file, SettableMetadata(contentType: 'image?$ext'))
        .then((p0) {
      log('Data Transferred:${p0.bytesTransferred / 1000} kb');
    });

    final imageUrl = await ref.getDownloadURL();
    await sendMessage(chatUser, imageUrl, Type.image);
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getUsersInfo(
      ChatUser chatUser) {
    return firestore
        .collection('users')
        .where('id', isEqualTo: chatUser.id)
        .snapshots();
  }

  static Future<void> updateActiveStatus(bool isOnline) async {
    print("----------------------------------$isOnline");
    firestore.collection('users').doc(user.uid).update({
      'is_online': isOnline,
      'last_active': DateTime.now(),
      'push_token': me?.pushToken,
    });
  }

  static FirebaseMessaging fmessaging = FirebaseMessaging.instance;
  static Future<void> getfirebaseMessagingToken() async {
    await fmessaging.requestPermission();

    await fmessaging.getToken().then((t) {
      if (t != null) {
        me?.pushToken = t;
        log('Push Token:$t');
      }
    });
  }

 static Future<void> deleteMessage(Message message) async {
    try {
      final docRef = firestore
          .collection('chats/${getConversationID(message.toid)}/messages/')
          .doc(message.sent.millisecondsSinceEpoch.toString());

      await docRef.delete();

      // If message type is an image, delete it from Firebase Storage
      if (message.type == Type.image) {
        await storage.refFromURL(message.msg).delete();
      }

      log('Message deleted successfully');
    } catch (e) {
      log('Failed to delete message: $e');
    }
  }

  static Future<void> updateMessage(Message message, String updatedMsg) async {
    try {
      final docRef = firestore
          .collection('chats/${getConversationID(message.toid)}/messages/')
          .doc(message.sent.millisecondsSinceEpoch.toString());

      await docRef.update({'msg': updatedMsg});

      log('Message updated successfully');
    } catch (e) {
      log('Failed to update message: $e');
    }
  }

 static Future<bool> addChatUser(String email) async {
  // Trim and convert email to lowercase
  email = email.trim().toLowerCase();

  // Log the email being searched
  log('Searching for user with email: $email');

  final data = await firestore
      .collection('users')
      .where('email', isEqualTo: email)
      .get();

  // Log the results of the query
  log('Data: ${data.docs}');

  if (data.docs.isNotEmpty && data.docs.first.id != user.uid) {
    log('User exists: ${data.docs.first.data()}');
    firestore
        .collection('users')
        .doc(user.uid)
        .collection('my_users')
        .doc(data.docs.first.id)
        .set({});
    return true;
  } else {
    // Log that the user does not exist
    log('User does not exist or trying to add self');
    return false;
  }
}


}
