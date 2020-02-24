import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:photo_view/photo_view.dart';
import 'dart:convert';
import 'thread.dart';
import 'board.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final routes = <String, WidgetBuilder>{
    '/': (context) => MyHomePage(),
    '/board': (context) => BoardPage(),
    '/thread': (context) => ThreadPage(),
  };

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF0175c2);
    const Color secondaryColor = Color(0xFF13B9FD);
    final ColorScheme colorScheme = const ColorScheme.dark().copyWith(
      primary: primaryColor,
      secondary: secondaryColor,
    );
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        accentColorBrightness: Brightness.dark,
        primaryColor: primaryColor,
        primaryColorDark: const Color(0xFF0050a0),
        primaryColorLight: secondaryColor,
        buttonColor: primaryColor,
        indicatorColor: Colors.white,
        toggleableActiveColor: const Color(0xFF6997DF),
        accentColor: secondaryColor,
        canvasColor: const Color(0xFF202124),
        scaffoldBackgroundColor: const Color(0xFF202124),
        backgroundColor: const Color(0xFF202124),
        errorColor: const Color(0xFFB00020),
        buttonTheme: ButtonThemeData(
          colorScheme: colorScheme,
          textTheme: ButtonTextTheme.primary,
        ),
      ),
      routes: routes,
    );
  }
}

class Category {
  String title;
  List boards;
  bool expand;

  Category(String t, List l) {
    this.title = t;
    this.boards = l;
    this.expand = false;
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String t = '';
  var client = http.Client();
  String baseUrl = 'https://mevius.5ch.net';
  var categories = new List<Category>();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    getThreadslist();
  }

  Future getThreadslist() async {
    Map boards = json.decode(
        await DefaultAssetBundle.of(context).loadString("assets/boards.json"));
    setState(() {
      boards.forEach((key, value) {
        categories.add(new Category(key, value));
      });
    });
  }

  @override
  build(context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return Card(
            child: ExpansionTile(
              title: Text(
                categories[index].boards.length.toString() + ' 掲示板',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
              leading: Text(
                categories[index].title,
                style: TextStyle(
                  color: Colors.blueAccent[100],
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              children: categories[index].boards.map(_buildTiles).toList(),
              trailing: Icon(Icons.keyboard_arrow_down),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return PhotoView(
                imageProvider: const NetworkImage(
                    'https://nogihub.gq/img/intro-carousel/2.jpg'),
              );
            },
          );
        },
        tooltip: 'Refresh',
        child: Icon(Icons.refresh),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  Widget _buildTiles(m) {
    return ListTile(
      title: Text(m['name']),
      onTap: () {
        Navigator.pushNamed(context, '/board', arguments: m['link']);
      },
    );
  }
}
