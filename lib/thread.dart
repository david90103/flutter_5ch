import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:shift_jis/shift_jis.dart';
import 'package:translator/translator.dart';
import 'package:jdenticon_dart/jdenticon_dart.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:photo_view/photo_view.dart';

class Comments {
  int floor;
  String id;
  String date;
  String text;
  bool fold;
  Uint8List icon;
  List<String> images;

  Comments(int floor, String id, String date, String text) {
    this.floor = floor;
    this.id = id;
    this.date = date;
    this.text = text;
    this.fold = floor == 1 ? false : true;
    _extractImage(text);
  }

  _extractImage(t) {
    this.images = [];
    RegExp exp = new RegExp(
        r"h?t?t?p?s?:?\/?\/?i\.imgur\.com\/([a-zA-Z0-9]*)\.(jpg|png|gif)");
    Iterable matches = exp.allMatches(t);
    for (Match m in matches) {
      this.images.add("https://i.imgur.com/${m.group(1)}.${m.group(2)}");
    }
  }
}

class ThreadPage extends StatefulWidget {
  ThreadPage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _ThreadPageState createState() => _ThreadPageState();
}

class _ThreadPageState extends State<ThreadPage> {
  String t = '';
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
      var uriResponse = await client.get(link);
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
                return Column(children: <Widget>[
                  Card(
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
                  ),
                  comments[index].images.length > 0
                      ? Container(
                          margin: EdgeInsets.symmetric(horizontal: 5),
                          height: 30,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: List.generate(
                                comments[index].images.length, (i) {
                              return Padding(
                                padding: EdgeInsets.only(right: 3),
                                child: FlatButton(
                                  padding: EdgeInsets.symmetric(horizontal: 0),
                                  color: Colors.blueGrey[800],
                                  child: Text('Image ${i + 1}'),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(
                                        text: comments[index].images[i]));
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return PhotoView(
                                          imageProvider: NetworkImage(
                                              comments[index].images[i]),
                                        );
                                      },
                                    );
                                  },
                                ),
                              );
                            }),
                          ),
                        )
                      : Container(),
                ]);
              },
            )
          : Container(
              alignment: Alignment.center,
              child: Text('Loading...'),
            ),
    );
  }
}
