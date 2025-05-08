locals {
  zone_to_region = jsondecode(file("zone_to_region.json"))
  zone = one(compact([var.a3_mega_zone, var.a3_ultra_zone, var.a4_high_zone]))
  region = try(local.zone_to_region[local.zone], null)
}
