import SwiftUI

@Observable
class UrlStore {
    var serverUrl: String = "http://127.0.0.1:8000"
    var r2BucketUrl: String = "https://threadline.sheline.me/"
}
