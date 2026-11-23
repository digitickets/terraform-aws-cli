output "desired_capacity" {
  description = "The current desired capacity of the auto scaling group."
  value       = module.current_desired_capacity.result
}
