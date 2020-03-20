import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:jira_time/actions/api.dart';
import 'package:jira_time/generated/i18n.dart';
import 'package:jira_time/models/logtime.dart';
import 'package:jira_time/util/customDialog.dart';
import 'package:jira_time/util/storage.dart';
import 'package:jira_time/widgets/customSvg.dart';
import 'package:jira_time/widgets/customCard.dart';
import 'package:jira_time/util/dateTimePicker.dart';
import 'package:jira_time/util/string.dart';
import 'package:jira_time/widgets/endLine.dart';
import 'package:jira_time/widgets/loading.dart';
import 'package:jira_time/util/lodash.dart';
import 'package:jira_time/widgets/networkImageWithCookie.dart';
import 'package:jira_time/widgets/placeholderText.dart';
import 'package:jira_time/widgets/userDisplay.dart';

import 'log_timer.dart';

class Issue extends StatefulWidget {
  final String issueKey;

  const Issue(this.issueKey);

  @override
  _IssueState createState() => _IssueState(this.issueKey);
}

class _IssueState extends State<Issue> with SingleTickerProviderStateMixin  {
  final String issueKey;
  Map<String, dynamic> _issueData;
  List _issueComments;
  List _issueWorkLogs;
  Storage storage;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  GlobalKey<RefreshIndicatorState>();

  _IssueState(this.issueKey);

  @override
  void initState() {
    super.initState();
    // init issue data
    storage = Storage();
    fetchIssue(this.issueKey).then((issueData) {
      setState(() {
        this._issueData = issueData;
      });
    });
    fetchComments();
    fetchWorkLogs();
  }

  @override
  void dispose() {
    super.dispose();
  }


  fetchComments({clear: false}) {
    if (clear) {
      setState(() {
        this._issueComments = null;
      });
    }
    // fetch issue comments
    fetchIssueComments(this.issueKey).then((comments) {
      setState(() {
        this._issueComments = comments
          ..sort((a, b) {
            final DateTime aTime = DateTime.parse(a['updated']);
            final DateTime bTime = DateTime.parse(b['updated']);
            return bTime.compareTo(aTime);
          });
      });
    });
  }

  Future<void> fetchWorkLogs({clear: false}) async{
    if (clear) {
      setState(() {
        this._issueWorkLogs = null;
      });
    }
    // fetch issue work logs
    fetchIssueWorkLogs(this.issueKey).then((workLogs) {
      setState(() {
        this._issueWorkLogs = workLogs
          ..sort((a, b) {
            final DateTime aTime = DateTime.parse(a['started']);
            final DateTime bTime = DateTime.parse(b['started']);
            return bTime.compareTo(aTime);
          });
      });
      return;
    }).catchError((onError){
      return;
    });
    //return;
  }

  handleSubmitComments(String commentBody) async {
    // post to server
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => Loading(),
      );
      await addIssueComments(this.issueKey, commentBody);
      Navigator.of(context).pop(); // exit input dialog
      fetchComments(clear: true);
      Fluttertoast.showToast(msg: S.of(context).submitted_successful);
    } catch (e) {
      Fluttertoast.showToast(msg: S.of(context).error_happened);
      return null;
    } finally {
      Navigator.of(context).pop(); // exit fetching dialog
    }
  }

  handleOnLogTime(BuildContext context) async {
    final payload = this._issueData['fields'];
    LogTime logTime = LogTime(
        DateTime.now().millisecondsSinceEpoch,
        payload['description'] ?? this.issueKey,
        this.issueKey
    );
    if (storage.isCounting()) {
      logTime = storage.getCurrentLog();
    }else{
      await storage.setCounting(true);
      await storage.setLogTime(logTime);
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LogTimer(logTime, (logTime.issueKey == this.issueKey)),
      ),
    );
  }

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
        this.issueKey,
        workLogComment: workLogComment,
        started: started,
        timeSpentSeconds: timeSpentSeconds,
      );
      Navigator.of(context).pop(); // exit input dialog
      fetchWorkLogs(clear: true);
      Fluttertoast.showToast(msg: S.of(context).submitted_successful);
    } catch (e) {
      print((e as DioError).request.data);
      print((e as DioError).response.data);
      Fluttertoast.showToast(msg: S.of(context).error_happened);
      return null;
    } finally {
      Navigator.of(context).pop(); // exit fetching dialog
    }
  }

  Widget buildContent(BuildContext context) {
    final payload = this._issueData['fields'];
    final double textHeight = 16.0;
    final listItems = <Widget>[
      Container(
        padding: EdgeInsets.all(5),
        child: Text(
          payload['summary'],
          style: Theme.of(context).textTheme.title,
        ),
      ),
      Divider(),
      ListTile(
        title: Text(
          S.of(context).status,
          style: Theme.of(context).textTheme.title,
        ),
        trailing: Wrap(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(right: 2),
              height: textHeight,
              child: Image(
                  image: NetworkImageWithCookie(payload['status']['iconUrl'])),
            ),
            Text(
              $_get(
                payload,
                ['status', 'name'],
                defaultData: S.of(context).unspecified,
              ),
            ),
          ],
        ),
      ),
      ListTile(
        title: Text(
          S.of(context).issue_type,
          style: Theme.of(context).textTheme.title,
        ),
        trailing: Wrap(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(right: 2),
              height: textHeight,
              child: CustomSvg(
                $_get(payload, ['issuetype', 'iconUrl']),
                width: 16,
              ),
            ),
            Text(
              $_get(
                payload,
                ['issuetype', 'name'],
                defaultData: S.of(context).unspecified,
              ),
            ),
          ],
        ),
      ),
      ListTile(
        title: Text(
          S.of(context).priority,
          style: Theme.of(context).textTheme.title,
        ),
        trailing: Wrap(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(right: 2),
              height: textHeight,
              child: CustomSvg(
                $_get(payload, ['priority', 'iconUrl']),
                width: 16,
              ),
            ),
            Text(
              $_get(
                payload,
                ['priority', 'name'],
                defaultData: S.of(context).unspecified,
              ),
            ),
          ],
        ),
      ),
      Divider(),
      ListTile(
        title: Text(
          S.of(context).reporter,
          style: Theme.of(context).textTheme.title,
        ),
        trailing: UserDisplay(payload['reporter']),
      ),
      ListTile(
        title: Text(
          S.of(context).assignee,
          style: Theme.of(context).textTheme.title,
        ),
        trailing: UserDisplay(payload['assignee']),
      ),
    ];
    // add description if exist
    if (payload['description'] != null) {
      listItems.add(LargeItem(
        S.of(context).description,
        child: Text(payload['description']),
      ));
    }
    // add comments
    listItems.add(LargeItem(
      S.of(context).comments,
      createIcon: Icons.add,
      onTapCreateIcon: () async {
        showCustomDialog(
          context: context,
          child: CommentInput(
            onSubmit: this.handleSubmitComments,
          ),
          barrierDismissible: false,
        );
      },
      child: this._issueComments != null
          ? this._issueComments.length > 0
              ? Column(
                  children: this._issueComments.map((commentData) {
                    return CustomCard(
                      header: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          UserDisplay(commentData['updateAuthor']),
                        ],
                      ),
                      body: Text(commentData['body']),
                      updatedTime: commentData['updated'],
                      showHHmm: true,
                    );
                  }).toList(),
                )
              : PlaceholderText(S.of(context).no_data)
          : Loading(
              withoutContainer: true,
              backgroundColor: null,
            ),
    ));
    // add work logs
    listItems.add(LargeItem(
      S.of(context).work_logs,
      createIcon: Icons.add,
      onTapCreateIcon: () {
        this.handleOnLogTime(context);
      },
      child: this._issueWorkLogs != null
          ? this._issueWorkLogs.length > 0
              ? Column(
                  children: this._issueWorkLogs.map((workLogData) {
                    return CustomCard(
                      header: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          UserDisplay(workLogData['updateAuthor']),
                          Text(workLogData['timeSpent'],
                              style: Theme.of(context).textTheme.title),
                        ],
                      ),
                      body: Text(workLogData['comment'] ?? ''),
                      updatedTime: workLogData['started'],
                      showHHmm: true,
                    );
                  }).toList(),
                )
              : PlaceholderText(S.of(context).no_data)
          : Loading(
              withoutContainer: true,
              backgroundColor: null,
            ),
    ));
    listItems.add(EndLine(S.of(context).no_more_data));
    return Container(
      padding: EdgeInsets.all(5),
      child: ListView(
        children: listItems,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(this.issueKey),
      ),
      body: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: this.fetchWorkLogs,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: this._issueData != null ? this.buildContent(context) : Loading(),
          ))
      //body: this._issueData != null ? this.buildContent(context) : Loading(),
    );
  }
}

//body: this._issueData != null ? this.buildContent(context) : Loading(),

class LargeItem extends StatelessWidget {
  final String title;
  final IconData createIcon;
  final Function onTapCreateIcon;

  final Widget child;

  const LargeItem(this.title,
      {Key key, this.child, this.createIcon, this.onTapCreateIcon})
      : super(key: key);

  Widget buildTitle(BuildContext context) {
    final List<Widget> titleItems = [
      Text(this.title, style: Theme.of(context).textTheme.title),
    ];
    if (this.createIcon != null) {
      titleItems.add(
        GestureDetector(
            onTap: this.onTapCreateIcon,
            child: Opacity(
              opacity: 0.66,
              child: Wrap(
                children: <Widget>[
                  Icon(this.createIcon),
                  Text(S.of(context).new_one),
                ],
              ),
            )),
      );
    }
    return Container(
      margin: EdgeInsets.only(top: 10, bottom: 20),
      child: Row(
        mainAxisAlignment: this.createIcon == null
            ? MainAxisAlignment.start
            : MainAxisAlignment.spaceBetween,
        children: titleItems,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Divider(),
          buildTitle(context),
          this.child,
        ],
      ),
    );
  }
}

class CommentInput extends StatelessWidget {
  GlobalKey _formKey = GlobalKey<FormState>();
  TextEditingController _commentController = TextEditingController();
  final Function onSubmit;

  CommentInput({Key key, this.onSubmit}) : super(key: key);

  handleSubmit() {
    final formState = _formKey.currentState as FormState;
    if (formState.validate()) {
      this.onSubmit(_commentController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: MediaQuery.of(context).size.width * .8,
        color: Theme.of(context).backgroundColor,
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey, //设置globalKey，用于后面获取FormState
          child: Wrap(
            children: <Widget>[
              Text(
                S.of(context).new_comments,
                style: Theme.of(context).textTheme.title,
              ),
              TextFormField(
                controller: this._commentController,
                autofocus: true,
                autovalidate: true,
                maxLines: 10,
                validator: (value) => value.length > 0
                    ? null
                    : S.of(context).validator_comment_required,
              ),
              Container(
                width: double.infinity,
                child: RaisedButton(
                  padding: EdgeInsets.all(15.0),
                  child: Text(S.of(context).submit),
                  color: Theme.of(context).primaryColor,
                  textColor: Colors.white,
                  onPressed: this.handleSubmit,
                ),
              )
            ],
          ),
        ));
  }
}

class WorkLogInput extends StatefulWidget {
  final Function onSubmit;
  final DateTime workTime;
  final Duration spent;


  WorkLogInput({Key key, this.onSubmit, this.workTime, this.spent}) : super(key: key);

  @override
  _WorkLogInputState createState() => _WorkLogInputState();
}

class _WorkLogInputState extends State<WorkLogInput> {
  GlobalKey _formKey = GlobalKey<FormState>();
  TextEditingController _workLogCommentController = TextEditingController();
  TextEditingController _workLogTimeController = TextEditingController();
  DateTime _workTime = DateTime.now();

  handleSubmit() {
    final formState = _formKey.currentState as FormState;
    if (formState.validate()) {
      this.widget.onSubmit(_workLogCommentController.text, widget.workTime,
          widget.spent.inSeconds);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: MediaQuery.of(context).size.width * .9,
        color: Theme.of(context).backgroundColor,
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey, //设置globalKey，用于后面获取FormState
          child: Wrap(
            children: <Widget>[
              // start time
              Text(
                S.of(context).work_start_time,
                style: Theme.of(context).textTheme.title,
              ),
              Container(
                margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.access_time),
                      Container(
                        alignment: Alignment.center,
                        margin: EdgeInsets.only(left: 10),
                        child: Text(formatDateTimeString(
                          context: context,
                          date: widget.workTime,
                          HHmm: true,
                        )),
                      ),
                    ],
                  ),

              ),
              // work time
              TextFormField(
                controller: _workLogTimeController..text = '${widget.spent.inHours.remainder(60).toString()}:${widget.spent.inMinutes.remainder(60).toString()}:${widget.spent.inSeconds.remainder(60).toString().padLeft(2, '0')}',
                autovalidate: true,
                enabled: false,
                decoration: InputDecoration(
                  labelText: "Time Spent",
                  hintText: S.of(context).work_time_hint,
                ),
                inputFormatters: [
                  BlacklistingTextInputFormatter(RegExp('[^0-9wdhm.]')),
                ],
                /*validator: (String content) {
                  if (content.length == 0) {
                    return S.of(context).validator_work_time_required;
                  }
                  if (parseWorkLogStr(content) == null) {
                    return S.of(context).validator_work_time_illegal;
                  }
                  return null;
                },*/
              ),
              Divider(),
              TextFormField(
                controller: this._workLogCommentController,
                decoration: InputDecoration(
                  labelText: S.of(context).describe_work,
                ),
                maxLines: 10,
              ),
              Container(
                width: double.infinity,
                child: RaisedButton(
                  padding: EdgeInsets.all(15.0),
                  child: Text(S.of(context).submit),
                  color: Theme.of(context).primaryColor,
                  textColor: Colors.white,
                  onPressed: this.handleSubmit,
                ),
              )
            ],
          ),
        ));
  }
}
