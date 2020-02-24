import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:shift_jis/shift_jis.dart';
import 'package:translator/translator.dart';

class Threads {
  String title;
  String link;
  int comments;
  Color color;

  Threads(String title, String link, int c) {
    this.title = title;
    this.link = link;
    this.comments = c;
    if (c > 900)
      this.color = Colors.red;
    else if (c > 700)
      this.color = Colors.deepOrangeAccent;
    else if (c > 500)
      this.color = Colors.yellow;
    else if (c > 300)
      this.color = Colors.greenAccent;
    else if (c > 100)
      this.color = Colors.blue;
    else
      this.color = Colors.grey;
  }

  Threads.fromHtml(String str, String link) {
    RegExp exp = new RegExp(r"\d*:\s(.*?)\s\((\d*)\)");
    Match match = exp.firstMatch(str);

    this.title = match.group(1);
    this.link = link;
    int c = int.parse(match.group(2));
    this.comments = c;
    if (c > 900)
      this.color = Colors.red;
    else if (c > 700)
      this.color = Colors.deepOrangeAccent;
    else if (c > 500)
      this.color = Colors.yellow;
    else if (c > 300)
      this.color = Colors.greenAccent;
    else if (c > 100)
      this.color = Colors.blue;
    else
      this.color = Colors.grey;
  }

  Map toJson() {
    return {'title': title, 'link': link};
  }
}

class BoardPage extends StatefulWidget {
  BoardPage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _BoardPageState createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
  String t = '';
  String domain = '';
  String boardname = '';
  var client = http.Client();
  var threads = new List<Threads>();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    Future.delayed(Duration.zero, getThreadslist);
  }

  Future getThreadslist() async {
    var splt = ModalRoute.of(context).settings.arguments.toString().split('/');
    domain = splt[2];
    boardname = splt[3];
    try {
      var uriResponse =
          await client.get("https://$domain/$boardname/subback.html");
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
                  color: threads[index].color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pushNamed(context, '/thread',
                    arguments:
                        "https://$domain/test/read.cgi/$boardname/${threads[index].link}");
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
