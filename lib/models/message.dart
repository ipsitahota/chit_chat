import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  Message({
    required this.msg,
    required this.toid,
    required this.read,
    required this.type,
    required this.sent,
    required this.fromid,
  });
  late final String msg;
  late final String toid;
  late final DateTime? read;
  late final DateTime sent; 
  late final String fromid;
  late final Type type;

  Message.fromJson(Map<String, dynamic> json) {
    msg = json['msg'].toString();
    toid = json['toid'].toString();
    read = json['read'] ==null?null:(json['read'] as Timestamp).toDate();
    type = json['type'].toString() == Type.image.name ? Type.image : Type.text;
    sent = (json['sent'] as Timestamp).toDate();
    fromid = json['fromid'].toString();
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['msg'] = msg;
    data['toid'] = toid;
    data['read'] = read;
    data['type'] = type.name;
    data['sent'] = sent;
    data['fromid'] = fromid;
    return data;
  }
}

enum Type { text, image, video }
