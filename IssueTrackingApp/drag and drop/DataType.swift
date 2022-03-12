
import Foundation

enum DataType: String, CaseIterable, Codable {
    
    case todo = "todo"
    case todoHeader = "todoHeader"
    case group = "group"
    case section = "section"
    
    static func type(string: String) -> DataType? {
        
        if string == todo.rawValue {
            return DataType.todo
        } else  if string == group.rawValue {
            return DataType.group
        } else  if string == section.rawValue {
            return DataType.section
        } else if string == todoHeader.rawValue {
            return DataType.todoHeader
        } else {
            return nil
        }
    }
}
