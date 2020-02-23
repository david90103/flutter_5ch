import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:shift_jis/shift_jis.dart';
import 'package:translator/translator.dart';

class Comments {
  String id;
  String date;
  String text;

  Comments(String id, String date, String text) {
    this.id = id;
    this.date = date;
    this.text = text;
  }

  // Comments.fromHtml(String str, String link) {
  //   RegExp exp = new RegExp(r"\d*:\s(.*?)\s\((\d*)\)");
  //   Match match = exp.firstMatch(str);

  //   this.id = match.group(1);
  //   this.comments = int.parse(match.group(2));
  //   this.link = link;
  // }
}

class ThreadPage extends StatefulWidget {
  ThreadPage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _ThreadPageState createState() => _ThreadPageState();
}

class _ThreadPageState extends State<ThreadPage> {
  String t = '';
  var client = http.Client();
  String baseUrl = 'https://mevius.5ch.net/test/read.cgi/nogizaka';
  var comments = new List<Comments>();

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, getCommentslist);
  }

  Future getCommentslist() async {
    String link = ModalRoute.of(context).settings.arguments;
    try {
      var uriResponse = await client.get(baseUrl + '/' + link);
      final decoded = await ShiftJis.decode(uriResponse.bodyBytes);
      var document = parse(decoded);

      setState(() {
        comments.clear();
        for (var thread in document.getElementsByClassName('post')) {
          comments.add(new Comments(
              thread.getElementsByClassName('uid').first.text,
              thread.getElementsByClassName('date').first.text,
              thread.getElementsByClassName('escaped').first.text));
        }
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  build(context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Thread List"),
      ),
      body: ListView.builder(
        itemCount: comments.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              title: Text(comments[index].text),
              subtitle: Text(comments[index].id + ' ' + comments[index].date),
              onTap: () {
                // Navigator.pushNamed(context, '/thread',
                //     arguments: comments[index].link);
              },
              onLongPress: () async {
                final translator = GoogleTranslator();
                var translation = await translator
                    .translate(comments[index].text, from: 'ja', to: 'zh-tw');
                setState(() {
                  comments[index].text = translation;
                });
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: getCommentslist,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}
