import 'package:bot_toast/bot_toast.dart';
import 'package:calltrackinh/Admin/user_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AllUserScreen extends StatefulWidget {
  const AllUserScreen({super.key});

  @override
  State<AllUserScreen> createState() => _AllUserScreenState();
}

class _AllUserScreenState extends State<AllUserScreen> {
  final CollectionReference usersCollection =
  FirebaseFirestore.instance.collection('users');

  Future<void> deleteUser(String userId) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete User Confirmation", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text("Are you sure you want to proceed?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                // Perform user deletion here
                await usersCollection.doc(userId).delete();
                Navigator.pop(context);
                BotToast.showText(text: "User deleted successfully");
              },
              child: Text("Delete User",style: TextStyle(color: Colors.white),),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(preferredSize: Size(double.infinity,
          50), child: Center(child: Text("All Users",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18),))),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: usersCollection.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No users found'));
                }

                var users = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    var user = users[index];
                    String userId = user['id'];
                    // String userId = user.id;
                    String userName = user['username'];

                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                        ),
                        child: ListTile(
                          onTap: () => {
                            if(userId != null && userId.isNotEmpty){
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => UserDetailScreen(userId: userId,userName: userName,)),
                              )
                            }

                          },
                          style: ListTileStyle.list,
                          title: Text(userName),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteUser(userId),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
