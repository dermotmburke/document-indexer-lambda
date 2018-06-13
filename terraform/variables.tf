
variable "appEnv" { }

variable "accessKey" {
}
variable "secretKey" {
}
variable "region" {
  default = "us-east-1"
}

variable "runtime" {
  default = "java8"
}

variable "timeout" {
  default = "300"
}

variable "memorySize" {
  default = "2048"
}

variable "lambdaFunctionHandler" {
  default = "com.buildit.document.DocumentIndexer::handleRequest"
}

variable "lambdaFunctionBucket" {
  default = "com.buildit.document.DocumentIndexer::handleRequest"
}

variable "lambdaFunctionName" {}

variable "artifactId" {}

variable "version" {}

variable "indexHost" {}