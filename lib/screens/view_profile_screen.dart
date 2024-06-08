import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Add import for flutter_screenutil package
import 'package:cached_network_image/cached_network_image.dart';
import 'package:frnds_chat/helper/my_date_util.dart';
import 'package:frnds_chat/models/chat_user.dart';

class ViewProfileScreen extends StatefulWidget {
  final ChatUser user;

  const ViewProfileScreen({Key? key, required this.user})
      : super(key: key); // Correct typo here

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen> {


  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context); // Initialize ScreenUtil for responsive UI
    var mq = MediaQuery.of(context).size; // Initialize mq to utilize ScreenUtil

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title:  Text(widget.user.name),
        ),
        floatingActionButton:  Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Joined On:',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                      fontSize: 16),
                    ),
                     Text(
                     MyDateUtil.getLastMessageTime(context: context, time: widget.user.createdAt,showYear: true,style: TextStyle(color: Colors.black54,fontSize: 16)),
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 16),
                    ),

                  ],
                ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: mq.width * .05),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(width: mq.width, height: mq.height * .03),
                ClipRRect(
                         borderRadius:
                             BorderRadius.circular(mq.height * .3),
                         child: CachedNetworkImage(
                           width: mq.height * .2,
                           height: mq.height * .2,
                           fit: BoxFit.cover,
                           imageUrl: widget.user.image,
                           errorWidget: (context, url, error) =>
                               CircleAvatar(
                             child: Icon(CupertinoIcons.person),
                           ),
                         ),
                       ),
                SizedBox(height: mq.height * .03),
                Text(
                  widget.user.email,
                  style: TextStyle(color: Colors.black87, fontSize: 16),
                ),
                SizedBox(height: mq.height * .02),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('About:',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                      fontSize: 16),
                    ),
                     Text(widget.user.about,
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 16),
                    ),

                  ],
                ),
           
              ],
            ),
          ),
        ),
      ),
    );
  }

}
