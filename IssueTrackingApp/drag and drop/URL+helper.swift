
import Foundation

//extension URL {
//    var imageURL: URL {
//        for query in query?.components(separatedBy: "&") ?? [] {
//            let queryComponents = query.components(separatedBy: "=")
//            if queryComponents.count == 2 {
//                if queryComponents[0] == "imgurl", let url = URL(string: queryComponents[1].removingPercentEncoding ?? "") {
//                    return url
//                }
//            }
//        }
//
//        if isFileURL {
//            var url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
//            url = url?.appendingPathComponent(self.lastPathComponent)
//            if url != nil {
//                return url!
//            }
//        }
//        return self.baseURL ?? self
//    }
//}
