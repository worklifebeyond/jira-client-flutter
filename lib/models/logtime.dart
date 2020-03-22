class LogTime {
  int startedAt;
  String taskName;
  String issueKey;
  String summary;

  LogTime(this.startedAt, this.taskName, this.issueKey, this.summary);

  LogTime.fromMap(Map<String, dynamic> m){
    this.issueKey = m['issue_key'];
    this.taskName = m['task_name'];
    this.startedAt = m['started_at'];
    this.summary = m['summary'];
  }

  toMap() {
    Map<String, dynamic> m = new Map();

    m['task_name'] = taskName;
    m['issue_key'] = issueKey;
    m['started_at'] = startedAt;
    m['summary'] = summary;

    return m;
  }

}