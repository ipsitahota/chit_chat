import 'dart:developer';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frnds_chat/api/apis.dart';
import 'package:frnds_chat/helper/dialogs.dart';
import 'package:frnds_chat/helper/my_date_util.dart';
import 'package:frnds_chat/main.dart';
import 'package:frnds_chat/models/message.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

class MessageCard extends StatefulWidget {
  const MessageCard({super.key, required this.message});

  final Message message;

  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  // late bool isMe;

  // @override
  // void initState() {
  //   super.initState();
  //   isMe = APIS.user.uid == widget.message.fromid;
  // }

  @override
  Widget build(BuildContext context) {
    bool isMe = APIS.user.uid == widget.message.fromid;
    return InkWell(
      onLongPress: () {
        _showBottomSheet(isMe);
      },
      child: isMe ? _myMessage() : _yourMessage(),
    );
  }

  Widget _yourMessage() {
    if (widget.message.read == null) {
      APIS.updateMessageReadStatus(widget.message).then((_) {
        setState(() {
          widget.message.read = DateTime.now();
        });
      }).catchError((error) {
        log('Failed to update local message read status: $error');
      });
      log('message read updated');
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Container(
            padding: EdgeInsets.all(widget.message.type == Type.image
                ? mq.width * .03
                : mq.width * .04),
            margin: EdgeInsets.symmetric(
                horizontal: mq.width * .04, vertical: mq.height * .01),
            decoration: BoxDecoration(
              color: Colors.white60,
              border: Border.all(color: Colors.grey.shade900),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: widget.message.type == Type.text
                ? Text(widget.message.msg,
                    style: TextStyle(fontSize: 15, color: Colors.black87))
                : ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: CachedNetworkImage(
                      imageUrl: widget.message.msg,
                      placeholder: (context, url) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (context, url, error) =>
                          Icon(Icons.image, size: 70),
                    ),
                  ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(right: mq.width * .04),
          child: Text(
            MyDateUtil.getFormattedmsgTime(
                context: context, time: widget.message.sent),
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ),
      ],
    );
  }

  Widget _myMessage() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(
        children: [
          SizedBox(width: mq.width * .04),
          if (widget.message.read != null)
            Icon(Icons.done_all_rounded, color: Colors.blue, size: 20),
          SizedBox(
            width: 2,
          ),
          Text(
            MyDateUtil.getFormattedmsgTime(
                context: context, time: widget.message.sent),
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
      Flexible(
        child: Container(
          padding: EdgeInsets.all(widget.message.type == Type.image
              ? mq.width * .03
              : mq.width * .04),
          margin: EdgeInsets.symmetric(
              horizontal: mq.width * .04, vertical: mq.height * .01),
          decoration: BoxDecoration(
              color: Colors.deepPurple.shade400,
              border: Border.all(color: Colors.deepPurple.shade900),
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                  bottomLeft: Radius.circular(30))),
          child: widget.message.type == Type.text
              ? Text(widget.message.msg,
                  style: TextStyle(fontSize: 15, color: Colors.black87))
              : ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: CachedNetworkImage(
                    imageUrl: widget.message.msg,
                    placeholder: (context, url) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.image,
                      size: 70,
                    ),
                  ),
                ),
        ),
      ),
    ]);
  }

  void _showBottomSheet(bool isMe) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (_) {
        return SingleChildScrollView(
          // Wrap the ListView with SingleChildScrollView
          child: GestureDetector(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 4,
                    margin: EdgeInsets.symmetric(
                      vertical: mq.height * .015,
                      horizontal: mq.width * .4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  widget.message.type == Type.text
                      ? _OptionItem(
                          icon: Icon(
                            Icons.copy_all_rounded,
                            color: Colors.deepPurple.shade400,
                            size: 26,
                          ),
                          name: 'Copy Text',
                          onTap: () async {
                            await Clipboard.setData(
                              ClipboardData(text: widget.message.msg),
                            ).then((value) {
                              Navigator.pop(context);
                              Dialogs.showSnackbar(context, 'Text Copied!');
                            });
                          },
                        )
                      : _OptionItem(
                          icon: Icon(
                            Icons.download_rounded,
                            color: Colors.deepPurple.shade400,
                            size: 26,
                          ),
                          name: 'Save Image',
                          onTap: () async {
                            try {
                              log('Image Url: ${widget.message.msg}');
                              var response = await NetworkAssetBundle(
                                Uri.parse(widget.message.msg),
                              ).load("");
                              var byteData = response.buffer.asUint8List();
                              await ImageGallerySaver.saveImage(
                                byteData,
                                quality: 60,
                                name: "Chit_Chat",
                              );
                              Navigator.pop(context);
                              Dialogs.showSnackbar(
                                context,
                                'Image Successfully Saved!',
                              );
                            } catch (e) {
                              log('ErrorWhileSavingImg: $e');
                            }
                          },
                        ),
                  if (isMe)
                    Divider(
                      color: Colors.black54,
                      endIndent: mq.width * .04,
                      indent: mq.width * .04,
                    ),
                  if (widget.message.type == Type.text && isMe)
                    _OptionItem(
                      icon: Icon(
                        Icons.edit,
                        color: Colors.deepPurple.shade400,
                        size: 26,
                      ),
                      name: 'Edit Message',
                      onTap: () {
                        Navigator.pop(context);
                        _showMessageUpdateDialog();
                      },
                    ),
                  if (isMe)
                    _OptionItem(
                      icon: Icon(
                        Icons.delete_forever,
                        color: Colors.red,
                        size: 26,
                      ),
                      name: 'Delete Message',
                      onTap: () async {
                        await APIS.deleteMessage(widget.message).then((value) {
                          Navigator.pop(context);
                          Dialogs.showSnackbar(
                            context,
                            'Deleted Successfully!',
                          );
                          Navigator.pop(context);
                        });
                      },
                    ),
                  Divider(
                    color: Colors.black54,
                    endIndent: mq.width * .04,
                    indent: mq.width * .04,
                  ),
                  _OptionItem(
                    icon: Icon(Icons.remove_red_eye, color: Colors.blue),
                    name:
                        'Sent At: ${MyDateUtil.getFormattedmsgTime(context: context, time: widget.message.sent)}',
                    onTap: () {},
                  ),
                  _OptionItem(
                    icon: Icon(Icons.remove_red_eye, color: Colors.green),
                    name: widget.message.read == null
                        ? 'Read At: Not seen yet'
                        : 'Read At: ${MyDateUtil.getFormattedmsgTime(context: context, time: widget.message.read!)}',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }




  void _showMessageUpdateDialog() {
    String updatedMsg = widget.message.msg;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        contentPadding: EdgeInsets.zero, // Set contentPadding to zero
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.message,
              color: Colors.deepPurple.shade400,
              size: 28,
            ),
            Text(' Update Message'),
          ],
        ),
        content: Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 10),
          child: TextFormField(
            initialValue: updatedMsg,
            maxLines: null,
            onChanged: (value) => updatedMsg = value,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
        actions: [
          MaterialButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.deepPurple.shade400, fontSize: 16),
            ),
          ),
          MaterialButton(
            onPressed: () {
              Navigator.pop(context);
              APIS.updateMessage(widget.message, updatedMsg);
              Dialogs.showSnackbar(
                context,
                'Message Updated Successfully',
              );
            },
            child: Text(
              'Update',
              style: TextStyle(color: Colors.deepPurple.shade400, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionItem extends StatelessWidget {
  final Icon icon;
  final String name;
  final VoidCallback onTap;

  const _OptionItem(
      {required this.icon, required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: () => onTap(),
        child: Padding(
          padding: EdgeInsets.only(
              left: mq.width * .05,
              top: mq.height * .015,
              bottom: mq.height * .015),
          child: Row(children: [
            icon,
            Flexible(
                child: Text('    $name',
                    style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                        letterSpacing: 0.5)))
          ]),
        ));
  }
}
