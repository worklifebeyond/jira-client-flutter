class LogTime {
  int startedAt;
  String taskName;
  String issueKey;

  LogTime(this.startedAt, this.taskName, this.issueKey);

  LogTime.fromMap(Map<String, dynamic> m){
    this.issueKey = m['issue_key'];
    this.taskName = m['task_name'];
    this.startedAt = m['started_at'];
  }

  toMap() {
    Map<String, dynamic> m = new Map();

    m['task_name'] = taskName;
    m['issue_key'] = issueKey;
    m['started_at'] = startedAt;

    return m;
  }

}