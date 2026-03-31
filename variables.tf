variable "cloud_id" {
  description = "ID облака в Yandex Cloud"
  type        = string
}

variable "folder_id" {
  description = "ID папки в Yandex Cloud"
  type        = string
}

variable "zone" {
  description = "Зона доступности для NAT и Bastion Host"
  type        = string
  default     = "ru-central1-a"
}

variable "ssh_public_key" {
  description = "SSH публичный ключ из переменных sourcecraft для CD"
  type        = string
  sensitive   = true
}
