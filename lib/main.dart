import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:shift_jis/shift_jis.dart';
import 'package:translator/translator.dart';
import 'thread.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final routes = <String, WidgetBuilder>{
    '/': (context) => MyHomePage(),
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

class Threads {
  String title;
  String link;
  int comments;

  Threads(String title, String link, int c) {
    this.title = title;
    this.link = link;
    this.comments = c;
  }

  Threads.fromHtml(String str, String link) {
    RegExp exp = new RegExp(r"\d*:\s(.*?)\s\((\d*)\)");
    Match match = exp.firstMatch(str);

    this.title = match.group(1);
    this.comments = int.parse(match.group(2));
    this.link = link;
  }

  Map toJson() {
    return {'title': title, 'link': link};
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
  var threads = new List<Threads>();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    getThreadslist();
  }

  Future getThreadslist() async {
    try {
      var uriResponse = await client.get(baseUrl + '/nogizaka/subback.html');
      final decoded = await ShiftJis.decode(uriResponse.bodyBytes);
      var document = parse(decoded);

      setState(() {
        threads.clear();
        for (var thread in document.getElementById('trad').children) {
          threads.add(new Threads.fromHtml(
              thread.innerHtml, thread.attributes['href']));
          if (threads.length > 100) break;
        }
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  build(context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: threads.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              title: Text(threads[index].title),
              leading: Text(
                threads[index].comments.toString(),
                style: TextStyle(
                  color:
                      threads[index].comments > 99 ? Colors.red : Colors.grey,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pushNamed(context, '/thread',
                    arguments: threads[index].link);
              },
              onLongPress: () async {
                final translator = GoogleTranslator();
                var translation = await translator
                    .translate(threads[index].title, from: 'ja', to: 'zh-tw');
                setState(() {
                  threads[index].title = translation;
                });
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: getThreadslist,
        tooltip: 'Refresh',
        child: Icon(Icons.refresh),
        backgroundColor: Colors.purpleAccent,
      ),
    );
  }
}
