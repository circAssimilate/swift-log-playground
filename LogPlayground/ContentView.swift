//
//  LogPlayground
//
//  Created by Derek Hammond on 11/28/22.
//

import Logging
import SwiftUI

// MARK: - Log Polyfills

let logger = LoggingOSLog(label: "LogPlayground")

func logInfo(
  _ message: Logger.Message,
  file: String = #file,
  function: String = #function,
  line: UInt = #line
) {
  logger.log(
    level: .info,
    message: message,
    metadata: nil,
    file: file,
    function: function,
    line: line
  )
}

func trace<T>(
  _ label: Logger.Message,
  fn: () throws -> T
) rethrows
-> T
{
  logInfo(label)
  return try fn()
}

struct ContentView: View {
  @State var logUrl: URL?
  var body: some View {
    VStack(spacing: 10) {
      Text("Log Playground")
        .font(.title)

      Button("Get Logs") {
        logInfo("First Log")
        logInfo("Second Log with int: \(1)")
        logInfo("Third Log")

        guard let logEntries = try? getLogEntriesAsText() else {
          return
        }

        print("[DEBUG] logEntries", logEntries)

        guard let logURL = saveAndZipLogs(content: logEntries) else {
          print("ERROR: Couldn't save log")
          return
        }
        print("[DEBUG] logURL", logURL)
        logUrl = logURL
      }

      if let urlString = logUrl?.absoluteString {
        Text(urlString)
          .textSelection(.enabled)
          .lineLimit(nil)
      }
    }
    .padding()
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
