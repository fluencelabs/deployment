import testinfra.utils.ansible_runner
import pytest
import os

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
        os.environ["MOLECULE_INVENTORY_FILE"]).get_hosts("all")


def test_directories(host):
    d = host.file("/opt/molecule")

    assert d.is_directory
    assert d.exists
    assert d.user == "molecule"
    assert d.mode == 509


def test_files(host):
    f = host.file("/opt/molecule/foo")

    assert f.is_file
    assert f.exists
    assert f.content == b'bar'


@pytest.mark.parametrize("package", [
    "jq",
    "unzip",
    "python3-dev"
])
def test_is_package_is_installed(host, package):
    package = host.package(package)

    assert package.is_installed


@pytest.mark.parametrize("service", [
    "docker",
    "dnsmasq"
])
def test_service_is_running(host, service):
    service = host.service(service)

    assert service.is_running
    assert service.is_enabled


def test_user_cleanup(host):
    assert not host.user("deleted").exists


def test_user_created(host):
    assert host.user("molecule").exists
    assert host.user("molecule").uid == 666
    assert "docker" in host.user("molecule").groups


def test_sysctl(host):
    assert host.sysctl("vm.swappiness") == 1


def test_dnsmasq_docker_bind(host):
    assert host.socket("udp://172.17.0.1:53").is_listening


def test_limits(host):
    l = host.run("ulimit -Sn")

    assert l.stdout == '65536\n'
