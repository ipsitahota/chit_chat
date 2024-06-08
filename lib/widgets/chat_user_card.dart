import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frnds_chat/api/apis.dart';
import 'package:frnds_chat/helper/my_date_util.dart';
import 'package:frnds_chat/main.dart';
import 'package:frnds_chat/models/chat_user.dart';
import 'package:frnds_chat/models/message.dart';
import 'package:frnds_chat/screens/chat_screen.dart';
import 'package:frnds_chat/widgets/dialogs/profile_dialog.dart';

class ChatUserCard extends StatefulWidget {
  final ChatUser user;
  ChatUserCard({Key? key, required this.user}) : super(key: key);

  @override
  State<ChatUserCard> createState() => _ChatUserCardState();
}

class _ChatUserCardState extends State<ChatUserCard> {
  Message? _message;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: mq.width * .04, vertical: 4),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(user: widget.user),
            ),
          );
        },
        child: StreamBuilder(
          stream: APIS.getLastMessage(widget.user),
          builder: (context, snapshot) {
            final data = snapshot.data?.docs;
            final messages = data?.map((e) => Message.fromJson(e.data())).toList() ?? [];

            final List<Message> messagesWithTime = [];
            final List<Message> messagesWithoutTime = [];

            for (var message in messages) {
              if (message.sent != null) {
                messagesWithTime.add(message);
              } else {
                messagesWithoutTime.add(message);
              }
            }

            // Sort messages with timestamp
            messagesWithTime.sort((a, b) {
              if (a.sent != null && b.sent != null) {
                return b.sent!.compareTo(a.sent!);
              } else {
                return 0;
              }
            });

            // Combine both lists
            final List<Message> sortedMessages = [...messagesWithTime, ...messagesWithoutTime];

            if (sortedMessages.isNotEmpty) {
              _message = sortedMessages[0];
            }

            return ListTile(
              leading: InkWell(
                onTap: () {
                  showDialog(context: context, builder: (_) => ProfileDialog(user: widget.user));
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(mq.height * .3),
                  child: CachedNetworkImage(
                    width: mq.height * .055,
                    height: mq.height * .055,
                    imageUrl: widget.user.image,
                    errorWidget: (context, url, error) => CircleAvatar(child: Icon(CupertinoIcons.person)),
                  ),
                ),
              ),
              title: Text(widget.user.name),
              subtitle: _message != null
                  ? _message!.type == Type.image
                      ? RichText(
                          text: TextSpan(
                            children: [
                              WidgetSpan(
                                child: Icon(Icons.photo, size: 16),
                              ),
                              TextSpan(
                                text: ' Photo',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        )
                      : Text(
                          _message!.msg,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                  : Text(
                      widget.user.about,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
              trailing: _message == null
                  ? null
                  : _message!.read == null && _message!.fromid != APIS.user.uid
                      ? Container(
                          width: 15,
                          height: 15,
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.shade400,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        )
                      : Text(
                           MyDateUtil.getLastMessageTime(
                            context: context,
                            time: _message!.sent,
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
            );
          },
        ),
      ),
    );
  }
}
