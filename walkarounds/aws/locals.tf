locals {
  auto_deploy_parameter = var.auto_deploy ? "true" : "false"
  ou_ids_parameter      = join(",", length(var.organizational_unit_ids) > 0 ? var.organizational_unit_ids : [var.root_organizational_unit_id])
  regions_parameter     = join(",", var.deployment_regions)
  account_ids_parameter = length(var.target_account_ids) == 0 ? "" : join(",", var.target_account_ids)

  # Use provided external_id or generate a new UUID
  external_id = var.external_id != "" ? var.external_id : random_uuid.external_id[0].result

  root_id = var.root_organizational_unit_id
  derived_ou_list = length(var.accuknox_explicit_ou_list) > 0 ? var.accuknox_explicit_ou_list : var.organizational_unit_ids

  accuknox_api_path_normalized = startswith(var.accuknox_api_path, "/") ? var.accuknox_api_path : "/${var.accuknox_api_path}"
  accuknox_request_url         = "${trim(var.accuknox_api_base_url, "/")}${local.accuknox_api_path_normalized}"
  accuknox_role_arn            = try(aws_cloudformation_stack.ak_security_audit.outputs["ManagementAccountRoleArn"], null)

  accuknox_request_body_object = {
    region                    = var.deployment_regions
    label                     = var.accuknox_label
    scan_asset_type           = var.accuknox_scan_asset_type
    account_selection_type    = var.accuknox_account_selection_type
    auto_connect_new_accounts = var.accuknox_auto_connect_new_accounts
    tag                       = var.accuknox_tag
    onboarding_method         = var.accuknox_onboarding_method
    role_arn                  = local.accuknox_role_arn
    root_id                   = local.root_id
    external_id               = local.external_id
    ou_list                   = local.derived_ou_list
  }

  accuknox_request_body = jsonencode(local.accuknox_request_body_object)

  # Simplified headers for terracurl
  accuknox_request_headers = {
    "accept"         = "*/*"
    "authorization"  = "Bearer ${var.accuknox_api_token}"
    "content-type"   = "application/json"
  }
}
