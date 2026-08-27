name := "ScalaHTTPServer"

version := "0.1"

scalaVersion := "2.13.8"

libraryDependencies ++= Seq(
  "com.typesafe.akka" %% "akka-http"   % "10.2.9",
  "com.typesafe.akka" %% "akka-stream" % "2.6.18",
  "de.heikoseeberger" %% "akka-http-json4s" % "1.39.2",
  "org.json4s"        %% "json4s-native" % "4.0.5"
)