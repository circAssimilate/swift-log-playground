import OSLog
import Zip

// Based on https://github.com/rewindai/time-travel/blob/b85553ad6b92f88473e17fd9a53ba2f1647df7ed/TimeTravel/Logger.swift#L34-L61
func getLogEntriesAsText(since: Date? = nil) throws -> String {
  try trace("getLogEntries") {
    let logs = try getLogEntries()

    let dateStyle = Date.ISO8601FormatStyle(
      dateSeparator: .dash,
      dateTimeSeparator: .space,
      timeSeparator: .colon,
      timeZoneSeparator: Date.ISO8601FormatStyle.TimeZoneSeparator.omitted,
      includingFractionalSeconds: true
    )

    print("[DEBUG] logs.count", logs.count)

    // Format logs
    let logMessages: [String] = logs.compactMap { entry in
      let date = entry.date.formatted(dateStyle)
      let line = [
        "[Info]",
        date,
        entry.subsystem,
        "[\(entry.category)]",
        entry.composedMessage,
      ].joined(separator: " ")
      return line
    }

    return logMessages.joined(separator: "\n")
  }
}

let MAX_LOG_ENTRIES = 1000
let SUBSYSTEM = Bundle.main.bundleIdentifier!

func test() throws {
  let store = try OSLogStore.local()
  let oneMinuteAgo = store.position(timeIntervalSinceEnd: -60.0)
  let entries = try store.getEntries(with: [], at: oneMinuteAgo, matching: nil)
  for e in entries {
    print(e.date, e.composedMessage)
  }
}

// https://steipete.com/posts/logging-in-swift/
private func getLogEntries(since: Date = Date().addingTimeInterval(-300)) throws -> [OSLogEntryLog] {
  try trace("getLogEntries") {
    // TODO(derek@rewind.ai) I guess this doesn't work due to permissions?
    // let store = try OSLogStore.local()
    let store = try OSLogStore.init(scope: .currentProcessIdentifier)
    let fiveMinutesAgo = store.position(date: Date().addingTimeInterval(-300))
    let allEntries = try store.getEntries(with: [], at: fiveMinutesAgo, matching: nil)

    // TODO(derek@rewind.ai) These feel unnecessary, right?
    // let allEntries = logStore.getEntries(matching: .
    // // Get all the logs from the last 5 minutes.
    // let sinceDate = trace("logStore.position") {
    //   // Get 5 minutes of logs
    //   logStore.position(date: since)
    // }
    //
    // // Fetch log objects.
    // let allEntries = try trace("logStore.getEntries") {
    //   try logStore.getEntries(at: sinceDate)
    // }

    print("[DEBUG] allEntries.underestimatedCount", allEntries.underestimatedCount)

    // Filter the log to be relevant for our specific subsystem
    // and remove other elements (signposts, etc).
    let results = allEntries
      .compactMap { $0 as? OSLogEntryLog }
      // TODO(derek@rewind.ai) Figure out
      // .filter { $0.subsystem == SUBSYSTEM }
    for result in results {
      print("[DEBUG] result.subsystem", result.subsystem)
    }
    if results.count > MAX_LOG_ENTRIES {
      return Array(results[(results.count - MAX_LOG_ENTRIES)...])
    }
    return results
  }
}

private var logFileName: String {
  let dateFormatter = DateFormatter()
  dateFormatter.dateFormat = "yyyy_MM_dd_HH_mm_ss"
  let today = dateFormatter.string(from: Date())
  return "playground_logs_\(today)"
}

func saveAndZipLogs(content: String) -> URL? {
  let now = Date().ISO8601Format()
  let tempFolder = FileManager.default.temporaryDirectory
  let logFileURL = tempFolder.appendingPathComponent("\(now).log")

  do {
    try content.write(to: logFileURL, atomically: false, encoding: .utf8)
    let zipFilePath = try Zip.quickZipFiles([logFileURL], fileName: logFileName)
    return zipFilePath

  } catch {
    print("ERROR: Failed writing log file for feedback form: \(error.localizedDescription)")
    return nil
  }
}
