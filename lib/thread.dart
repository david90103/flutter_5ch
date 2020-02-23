import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:shift_jis/shift_jis.dart';
import 'package:translator/translator.dart';
import 'package:jdenticon_dart/jdenticon_dart.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Comments {
  int floor;
  String id;
  String date;
  String text;
  bool fold;
  Uint8List icon;

  Comments(int floor, String id, String date, String text) {
    this.floor = floor;
    this.id = id;
    this.date = date;
    this.text = text;
    this.fold = floor == 1 ? false : true;
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
  String baseUrl = 'https://mevius.5ch.net/test/read.cgi/nogizaka';
  var comments = new List<Comments>();
  var client = http.Client();
  static const int MAX_LENGTH = 60;

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
              int.parse(thread.getElementsByClassName('number').first.text),
              thread.getElementsByClassName('uid').first.text,
              thread.getElementsByClassName('date').first.text,
              thread.getElementsByClassName('escaped').first.text));
        }
      });
    } catch (e, stacktrace) {
      print(e + stacktrace);
    }
  }

  @override
  build(context) {
    return Scaffold(
      body: comments.length > 0
          ? ListView.builder(
              itemCount: comments.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    leading: SvgPicture.string(
                      Jdenticon.toSvg(comments[index].id),
                      fit: BoxFit.contain,
                      height: 32,
                      width: 32,
                    ),
                    title: Text(comments[index].fold &&
                            comments[index].text.length > MAX_LENGTH
                        ? comments[index].text.substring(0, MAX_LENGTH) +
                            ' ......'
                        : comments[index].text),
                    subtitle: Text(comments[index].floor.toString() +
                        ' ' +
                        comments[index].id +
                        ' ' +
                        comments[index].date),
                    onTap: () {
                      setState(() {
                        comments[index].fold = !comments[index].fold;
                      });
                    },
                    onLongPress: () async {
                      final translator = GoogleTranslator();
                      var translation = await translator.translate(
                          comments[index].text,
                          from: 'ja',
                          to: 'zh-tw');
                      setState(() {
                        comments[index].text = translation;
                      });
                    },
                  ),
                );
              },
            )
          : Container(
              alignment: Alignment.center,
              child: Text('Loading...'),
            ),
    );
  }
}
