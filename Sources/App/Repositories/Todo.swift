import Foundation
import Hummingbird

struct Todo {
  var id: UUID
  var title: String
  var order: Int?
  var url: String
  var completed: Bool

  init(id: UUID, title: String, url: String) {
    self.id = id
    self.title = title
    self.url = url
    self.order = nil
    self.completed = false
  }

  init(id: UUID, title: String, url: String, order: Int?) {
    self.id = id
    self.title = title
    self.url = url
    self.order = order
    self.completed = false
  }
}

extension Todo: ResponseEncodable, Decodable, Equatable {}
