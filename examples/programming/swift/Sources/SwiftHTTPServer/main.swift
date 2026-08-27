import Foundation
import Kitura

let router = Router()

router.get("/") { request, response, next in
    response.send(json: ["message": "Welcome to the Swift HTTP server"])
    next()
}

router.get("/health") { request, response, next in
    response.send(json: ["status": "healthy"])
    next()
}

let items = [[String: Any]]()
router.get("/items") { request, response, next in
    response.send(json: ["items": items])
    next()
}

router.post("/items") { request, response, next in
    guard let body = request.body, case .json(let json) = body else {
        response.status(.badRequest).send(json: ["error": "Invalid JSON"])
        return
    }

    guard let name = json["name"] as? String else {
        response.status(.badRequest).send(json: ["error": "name is required"])
        return
    }

    let item = ["id": "item-\(items.count + 1)", "name": name]
    var updatedItems = items
    updatedItems.append(item)
    response.status(.created).send(json: item)
    next()
}

Kitura.addHTTPServer(onPort: 8080, with: router)
Kitura.run()