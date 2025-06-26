from google.cloud import compute_v1
import time
import re
from datetime import datetime, timedelta


def filter_networks(networks, hours):
    ci_network = lambda name: re.match(r".*ml-.*-true$", name) or re.match(r".*ml-.*-false$", name)

    def check_creation_timestamp(creation_timestamp):
        creation_datetime = datetime.fromisoformat(creation_timestamp)
        now_datetime = datetime.now(creation_datetime.tzinfo)
        time_difference = now_datetime - creation_datetime
        return time_difference > timedelta(hours=hours)

    return list(filter(
        lambda network: ci_network(network.name) and check_creation_timestamp(network.creation_timestamp),
        networks
    ))


def run(project_id: str, hours: int) -> None:
    """
    Deletes all test VPC networks and their associated resources

    Args:
        project_id: The ID of the Google Cloud project.
    """
    # Initialize the Compute Engine client.
    network_client = compute_v1.NetworksClient()

    network_list_request = compute_v1.ListNetworksRequest(project=project_id)
    networks = network_client.list(request=network_list_request)
    filtered_networks = filter_networks(networks, hours)

    print(f"Networks to delete: {len(filtered_networks)}")
    for network in filtered_networks:
        delete_network_resources(project_id, network)
    print("Deletion process completed.")


def delete_network_resources(project_id, network) -> None:
    """
    Deletes all resources associated with a given VPC network.

    Args:
        project_id: The ID of the Google Cloud project.
        network: The VPC network.
    """
    # Initialize the clients
    network_client = compute_v1.NetworksClient()
    subnetwork_client = compute_v1.SubnetworksClient()
    global_address_client = compute_v1.GlobalAddressesClient()
    route_client = compute_v1.RoutesClient()
    firewall_client = compute_v1.FirewallsClient()

    print(f"({network.name}) Processing network: {network.name}")

    # 1. Delete Subnets
    for subnet in network.subnetworks:
        url_elems = subnet.split("/")
        idx = url_elems.index("regions")
        subnet_region = url_elems[idx + 1]
        subnet_name = url_elems[idx + 3]
        print(f"({network.name}) Deleting subnetwork: {subnet_name}")
        try:
            request = compute_v1.DeleteSubnetworkRequest(
                project=project_id,
                region=subnet_region,
                subnetwork=subnet_name,
            )
            subnetwork_deletion = subnetwork_client.delete(request=request)
            print(f"({network.name}) Subnetwork {subnet_name} deletion initiated")
            start_time = time.time()
            while subnetwork_deletion.status != compute_v1.types.Operation.Status.DONE and time.time() - start_time < 1*60:
                print(f"({network.name}) Waiting subnetwork {subnet_name} deletion...")
                time.sleep(5)
            print(f"({network.name}) Subnetwork {subnet_name} is deleted")
        except Exception as e:
            print(f"({network.name}) Error deleting subnetwork {subnet_name}: {e}")

    # 2. Remove peering
    print(f"({network.name}) Deleting peering")
    try:
        request = compute_v1.RemovePeeringNetworkRequest(
            network=network.name,
            project=project_id,
        )
        peering_removal = network_client.remove_peering(request=request)
        print(f"({network.name}) Peering removal initiated.")
        start_time = time.time()
        while peering_removal.status != compute_v1.types.Operation.Status.DONE and time.time() - start_time < 1*60:
            print(f"({network.name}) Waiting peering deletion...")
            time.sleep(5)
        print(f"({network.name}) Peering is removed")
    except Exception as e:
        print(f"({network.name}) Error deleting peering: {e}")


    # 3. Delete Global Addresses
    address_list_request = compute_v1.ListGlobalAddressesRequest(project=project_id)
    addresses = global_address_client.list(request=address_list_request)
    filtered_addresses = list(filter(
        lambda address: address.network.split("/")[-1] == network.name,
        addresses
    ))
    print(f"({network.name}) Prepare to delete global addresses: {len(filtered_addresses)}")
    for address in filtered_addresses:
        print(f"({network.name}) Deleting global address: {address.name}")
        try:
            delete_address_request = compute_v1.DeleteGlobalAddressRequest(
                project=project_id,
                address=address.name
            )
            address_deletion = global_address_client.delete(request=delete_address_request)
            print(f"({network.name}) Global address {address.name} deletion initiated.")
            start_time = time.time()
            while address_deletion.status != compute_v1.types.Operation.Status.DONE and time.time() - start_time < 1*60:
                print(f"({network.name}) Waiting global address {address.name} deletion...")
                time.sleep(5)
            print(f"({network.name}) Global address {address.name} is deleted")
        except Exception as e:
            print(f"({network.name}) Error deleting global address {address.name}: {e}")

    # 4. Delete Global Routes
    list_routes_request = compute_v1.ListRoutesRequest(project=project_id)
    routes = route_client.list(request=list_routes_request)
    filtered_routes = list(filter(
        lambda route: route.network.split("/")[-1] == network.name,
        routes
    ))
    print(f"({network.name}) Global routes to delete: {len(filtered_routes)}")
    for idx, route in enumerate(filtered_routes):
        print(f"({network.name}) Deleting route: {route.name}")
        try:
            delete_route_request = compute_v1.DeleteRouteRequest(
                project=project_id,
                route=route.name
            )
            route_deletion = route_client.delete(request=delete_route_request)
            print(f"({network.name}) Global route {route.name} deletion initiated.")
            start_time = time.time()
            while route_deletion.status != compute_v1.types.Operation.Status.DONE and time.time() - start_time < 1*60:
                print(f"({network.name}) Waiting route {route.name} deletion...")
                time.sleep(5)
            print(f"({network.name}) Route {route.name} is deleted")
        except Exception as e:
            print(f"({network.name}) Error deleting global route {route.name}: {e}")

    # 5. Delete Firewall Rules
    firewall_list_request = compute_v1.ListFirewallsRequest(project=project_id)
    firewalls = firewall_client.list(request=firewall_list_request)
    filtered_firewalls = list(filter(
        lambda firewall: firewall.network.split("/")[-1] == network.name,
        firewalls
    ))
    print(f"({network.name}) Firewalls rules to delete: {len(filtered_firewalls)}")
    for firewall in filtered_firewalls:
        print(f"({network.name}) Deleting firewall rule: {firewall.name}")
        try:
            delete_firewall_request = compute_v1.DeleteFirewallRequest(
                project=project_id,
                firewall=firewall.name
            )
            firewall_rules_deletion = firewall_client.delete(request=delete_firewall_request)
            print(f"({network.name}) Firewall rule {firewall.name} deletion initiated.")
            start_time = time.time()
            while firewall_rules_deletion.status != compute_v1.types.Operation.Status.DONE and time.time() - start_time < 1*60:
                print(f"({network.name}) Waiting firewall rule {firewall.name} deletion...")
                time.sleep(5)
            print(f"({network.name}) Firewall rules {firewall.name} is deleted")
        except Exception as e:
            print(f"({network.name}) Error deleting firewall rules {firewall.name}: {e}")

    # 6. Delete the VPC Network
    print(f"({network.name}) Delete the network: {network.name}")
    try:
        delete_network_request = compute_v1.DeleteNetworkRequest(
            project=project_id,
            network=network.name
        )
        network_deletion = network_client.delete(request=delete_network_request)
        print(f"({network.name}) Network {network.name} deletion initiated.")
        start_time = time.time()
        while network_deletion.status != compute_v1.types.Operation.Status.DONE and time.time() - start_time < 1*60:
            print(f"({network.name}) Waiting network {network.name} deletion...")
            time.sleep(5)
        print(f"({network.name}) Network {network.name} is deleted")
    except Exception as e:
        print(f"({network.name}) Error deleting network {network.name}: {e}")
