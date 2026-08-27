import akka.actor.ActorSystem
import akka.http.scaladsl.Http
import akka.http.scaladsl.model._
import akka.http.scaladsl.server.Directives._
import akka.stream.ActorMaterializer
import de.heikoseeberger.akkahttpjson4s.Json4sSupport._
import org.json4s.{DefaultFormats, JacksonJson4sSupport}
import org.json4s.native.Serialization
import scala.concurrent.ExecutionContextExecutor

case class Item(id: String, name: String)
case class ItemRequest(name: String)

object Main extends App with Json4sSupport {
  implicit val system: ActorSystem = ActorSystem("http-server")
  implicit val materializer: ActorMaterializer = ActorMaterializer()
  implicit val executionContext: ExecutionContextExecutor = system.dispatcher
  implicit val serialization: Serialization.type = Serialization
  implicit val formats: DefaultFormats.type = DefaultFormats

  var items: List[Item] = List()

  val route =
    pathEndOrSingleSlash {
      get {
        complete(Map("message" -> "Welcome to the Scala HTTP server"))
      }
    } ~
    path("health") {
      get {
        complete(Map("status" -> "healthy"))
      }
    } ~
    path("items") {
      get {
        complete(Map("items" -> items))
      } ~
      post {
        entity(as[ItemRequest]) { request =>
          val newItem = Item(s"item-${items.size + 1}", request.name)
          items = items :+ newItem
          complete(StatusCodes.Created, newItem)
        }
      } ~
      delete {
        items = List()
        complete(Map("removed" -> true))
      }
    } ~
    pathPrefix("") {
      pathEnd {
        get {
          complete(HttpEntity(ContentTypes.`text/html(UTF-8)`, "<h1>Scala HTTP Server</h1>"))
        }
      }
    }

  val port = Option(System.getenv("PORT")).getOrElse("8080").toInt
  val bindingFuture = Http().bindAndHandle(route, "0.0.0.0", port)
  println(s"Scala HTTP server running at http://localhost:$port/")
}