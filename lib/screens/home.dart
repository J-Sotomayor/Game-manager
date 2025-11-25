import 'package:flutter/material.dart';
import 'services/user_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UserService _userService = UserService();
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  loadUser() async {
    final doc = await _userService.getUser();
    final data = doc.data() as Map<String, dynamic>;
    setState(() {
      userData = data;
    });
  }

  String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return "Buenos días";
    } else if (hour >= 12 && hour < 18) {
      return "Buenas tardes";
    } else {
      return "Buenas noches";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Inicio"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundImage: userData!["photo"] != ""
                      ? NetworkImage(userData!["photo"])
                      : AssetImage("assets/profile.png") as ImageProvider,
                ),
                SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${getGreeting()},",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      "${userData!['name']} ${userData!['lastName']}",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              ],
            ),

            SizedBox(height: 30),

            Text(
              "Tus favoritos",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 10),

            if (userData!["favoritos"].isEmpty)
              Text("No tienes favoritos aún."),

            if (userData!["favoritos"].isNotEmpty)
              Column(
                children: userData!["favoritos"]
                    .take(3)
                    .map<Widget>((fav) => Card(
                          child: ListTile(
                            title: Text(fav),
                            trailing: Icon(Icons.star, color: Colors.amber),
                          ),
                        ))
                    .toList(),
              ),

            SizedBox(height: 20),

            ElevatedButton(
              child: Text("Ver todos los favoritos"),
              onPressed: () {
                Navigator.pushNamed(context, "/favoritos");
              },
            )
          ],
        ),
      ),
    );
  }
}
