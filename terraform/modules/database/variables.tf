variable "project_name" {
  description = "Project name used in database resource names."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnets used when publicly_accessible is true."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnets used when publicly_accessible is false."
  type        = list(string)
}

variable "security_group_id" {
  description = "Database security group ID."
  type        = string
}

variable "publicly_accessible" {
  description = "Whether PostgreSQL has a public endpoint."
  type        = bool
  default     = false
}

variable "database_name" {
  description = "Initial PostgreSQL database name."
  type        = string
  default     = "quotashark"
}

variable "database_username" {
  description = "PostgreSQL master username."
  type        = string
  default     = "quotashark_admin"
}

variable "engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "16"
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Initial storage in GiB."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum autoscaled storage in GiB."
  type        = number
  default     = 100
}

variable "backup_retention_days" {
  description = "Automated backup retention period."
  type        = number
  default     = 7
}

variable "multi_az" {
  description = "Whether to create a Multi-AZ database."
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Whether to protect the database from deletion."
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Whether to skip the final snapshot during deletion."
  type        = bool
  default     = false
}

variable "apply_immediately" {
  description = "Whether RDS modifications are applied immediately."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional database resource tags."
  type        = map(string)
  default     = {}
}

variable "password_rotation_enabled" {
  description = "Whether RDS manages and automatically rotates the master user password."
  type        = bool
  default     = true
}

variable "database_password" {
  description = "Static PostgreSQL master password. Required when password_rotation_enabled is false."
  type        = string
  sensitive   = true
  default     = null
  nullable    = true
}