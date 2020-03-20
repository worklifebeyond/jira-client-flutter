import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:jira_time/actions/api.dart';
import 'package:jira_time/generated/i18n.dart';
import 'package:jira_time/models/logtime.dart';
import 'package:jira_time/util/customDialog.dart';
import 'package:jira_time/util/storage.dart';
import 'package:jira_time/widgets/loading.dart';

import 'issue.dart';

class LogTimer extends StatefulWidget {
  final LogTime logTime;
  final bool isFromCurrentIssue;

  @override
  _LogTimerState createState() => _LogTimerState();

  LogTimer(this.logTime, this.isFromCurrentIssue);
}

class _LogTimerState extends State<LogTimer> with TickerProviderStateMixin {
  AnimationController _controller;
  int levelClock = 663899990;
  Storage localStorage;

  int spent = 0;

  handleSubmitWorkLog(
      String workLogComment, DateTime started, int timeSpentSeconds) async {
    // post to server
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => Loading(),
      );
      await addIssueWorkLogs(
        widget.logTime.issueKey,
        workLogComment: workLogComment,
        started: started,
        timeSpentSeconds: timeSpentSeconds,
      );
      Navigator.of(context).pop(); // exit input dialog
      await localStorage.setCounting(false);
      Fluttertoast.showToast(msg: S.of(context).submitted_successful+"\n Please pull to refresh issue");
      Navigator.of(context).pop();
    } catch (e) {
      print((e as DioError).request.data);
      print((e as DioError).response.data);
      Fluttertoast.showToast(msg: S.of(context).error_happened);
      return null;
    } finally {
      Navigator.of(context).pop(); // exit fetching dialog
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    localStorage = Storage();
    spent =
        ((DateTime.now().millisecondsSinceEpoch - widget.logTime.startedAt) /
                1000)
            .round();
    _controller = AnimationController(
        vsync: this, duration: Duration(seconds: levelClock));

    _controller.forward();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.logTime.issueKey),
        ),
        body: Column(
          children: <Widget>[
            Container(
              width: MediaQuery.of(context).size.width,
              color: (widget.isFromCurrentIssue) ? Colors.teal : Colors.red,
              padding: EdgeInsets.all(6),
              child: Text(
                (widget.isFromCurrentIssue)
                    ? "Your Work Log is on progress"
                    : "Cannot create Work Log because you're in another Work Log. Please submit or cancel your current Work Log",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: (widget.isFromCurrentIssue) ? 18 : 14),
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 20),
            ),
            (widget.isFromCurrentIssue)
                ? Container()
                : Container(
                    margin: EdgeInsets.only(bottom: 10),
                    child: Text(
                      "Current Work Log",
                      style: TextStyle(
                          color: Colors.teal,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.left,
                    )),
            Text(
              "Description:",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.left,
            ),
            Text(
              '"${widget.logTime.taskName}"',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
            Container(
              margin: EdgeInsets.only(bottom: 2, top: 20),
              child: Text(
                "Time Spent:",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.left,
              ),
            ),
            Countdown(
                animation: StepTween(
              begin: spent, // THIS IS A USER ENTERED NUMBER
              end: levelClock,
            ).animate(_controller)),
            Container(
              margin: EdgeInsets.only(top: 30),
            ),
            Container(
              margin: EdgeInsets.only(left: 15, right: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  RaisedButton(
                    padding: EdgeInsets.only(
                        left: 50, right: 50, top: 15, bottom: 15),
                    child: Text(S.of(context).submit),
                    color: Theme.of(context).primaryColor,
                    textColor: Colors.white,
                    onPressed: () async {
                      Duration clockTimer = Duration(
                          seconds: ((DateTime.now().millisecondsSinceEpoch -
                                      widget.logTime.startedAt) /
                                  1000)
                              .round());
                      showCustomDialog(
                        context: context,
                        child: WorkLogInput(
                          onSubmit: this.handleSubmitWorkLog,
                          workTime: DateTime.fromMillisecondsSinceEpoch(widget.logTime.startedAt),
                          spent: clockTimer,
                        ),
                        barrierDismissible: false,
                      );
                    },
                  ),
                  RaisedButton(
                    padding: EdgeInsets.only(
                        left: 50, right: 50, top: 15, bottom: 15),
                    child: Text("Cancel"),
                    color: Colors.red,
                    textColor: Colors.white,
                    onPressed: () async {
                      await localStorage.setCounting(false);
                      Navigator.of(context).pop();
                    },
                  )
                ],
              ),
            ),
          ],
        ));
  }
}

class Countdown extends AnimatedWidget {
  Countdown({Key key, this.animation}) : super(key: key, listenable: animation);
  Animation<int> animation;

  @override
  build(BuildContext context) {
    Duration clockTimer = Duration(seconds: animation.value);

    String timerText =
        '${clockTimer.inHours.remainder(60).toString()}:${clockTimer.inMinutes.remainder(60).toString()}:${clockTimer.inSeconds.remainder(60).toString().padLeft(2, '0')}';

    return Text(
      "$timerText",
      style: TextStyle(
        fontSize: 62,
        color: Theme.of(context).primaryColor,
      ),
    );
  }
}
