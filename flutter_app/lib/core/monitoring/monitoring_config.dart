class MonitoringConfig {
  final bool analyticsEnabled;
  final bool crashlyticsEnabled;
  final bool performanceEnabled;
  final bool consoleLogsEnabled;
  final bool fileLogsEnabled;
  final bool sendPII;

  const MonitoringConfig({
    this.analyticsEnabled = true,
    this.crashlyticsEnabled = true,
    this.performanceEnabled = true,
    this.consoleLogsEnabled = true,
    this.fileLogsEnabled = false,
    this.sendPII = false,
  });

  factory MonitoringConfig.development() {
    return const MonitoringConfig(
      analyticsEnabled: false,
      crashlyticsEnabled: false,
      performanceEnabled: false,
      consoleLogsEnabled: true,
      fileLogsEnabled: false,
      sendPII: false,
    );
  }

  factory MonitoringConfig.production() {
    return const MonitoringConfig(
      analyticsEnabled: true,
      crashlyticsEnabled: true,
      performanceEnabled: true,
      consoleLogsEnabled: false,
      fileLogsEnabled: true,
      sendPII: false,
    );
  }
}
