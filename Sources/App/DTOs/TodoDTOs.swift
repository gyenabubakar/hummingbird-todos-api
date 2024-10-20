struct CreateTodoDTO: Decodable {
  let title: String
  let order: Int?
}

struct UpdateTodoDTO: Decodable {
  let title: String?
  let order: Int?
  let completed: Bool?
}
