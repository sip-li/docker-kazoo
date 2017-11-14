import unittest
import configparser
import sys

import testdocker

sys.modules['testdocker.mixins'].objects.Compose.DEFAULT_FILES = ()

from testdocker import (
    ContainerTestMixinBase,
    ContainerTestMixin,
    CommandBase,
    CurlCommand,
    NetCatCommand,
    CatCommand,
    Container
)


class TestKazooBasic(ContainerTestMixin, unittest.TestCase):
    """Run basic tests on kazoo container."""

    name = 'kazoo'
    tear_down = True
    test_patterns = [
        r"successfully connected to 'amqp://guest:guest@rabbitmq\.local",
        r'connected successfully to http://couchdb\.local:5984',
        r'connected successfully to http://couchdb\.local:5986',
        r"setting kazoo_apps cookie to 'test-cookie'",
        r'starting applications specified in environment variable KAZOO_APPS',
        'started plaintext API server',
        'Application crossbar started',
    ]
    test_tcp_ports = [5555, 8000, 24517]
    test_http_uris = ['http://localhost:8000']
    # compose_files = ['docker-compose-test.yaml']

    def test_correct_name_in_vm_args(self):
        """Assert correct erlang node name in /etc/kazoo/core/vm.args"""
        cmd = 'cat /etc/kazoo/core/vm.args'
        exit_code, output = self.container.exec(cmd)
        self.assertEqual(exit_code, 0)
        self.assertRegex(output, r'-name kazoo_apps')

    def test_correct_amqp_uris_in_config_ini(self):
        """Assert correct amqp_uri's in /etc/kazoo/core/config.ini"""
        cmd = 'cat /etc/kazoo/core/config.ini'
        output = self.container.exec(cmd, output_only=True)
        amqp_hosts = self.container.env['RABBITMQ_HOST'].split(',')
        patterns = [r'amqp://guest:guest@%s:5672' % h
                    for h in amqp_hosts]
        for pattern in patterns:
            with self.subTest(pattern=pattern):
                    self.assertRegex(output, pattern)

    def test_correct_bigcouch_ip_in_config_ini(self):
        """Assert correct ip in bigcouch section of config.ini"""
        cmd = 'cat /etc/kazoo/core/config.ini'
        output = self.container.exec(cmd, output_only=True)
        parser = configparser.ConfigParser(strict=False)
        parser.read_string(output)
        self.assertEqual(
            parser.get('bigcouch', 'ip')[1:-1],
            self.container.env['COUCHDB_HOST']
        )

    def test_correct_bigcouch_creds_in_config_ini(self):
        """Assert correct credentials in bigcouch section of config.ini"""
        cmd = 'cat /etc/kazoo/core/config.ini'
        output = self.container.exec(cmd, output_only=True)
        parser = configparser.ConfigParser(strict=False)
        parser.read_string(output)
        self.assertEqual(parser.get('bigcouch', 'username')[1:-1],
                         self.container.env['COUCHDB_USER'])
        self.assertEqual(parser.get('bigcouch', 'password')[1:-1],
                         self.container.env['COUCHDB_PASS'])
        self.assertEqual(parser.get('bigcouch', 'port'),
                         self.container.env['COUCHDB_DATA_PORT'])
        self.assertEqual(parser.get('bigcouch', 'admin_port'),
                         self.container.env['COUCHDB_ADMIN_PORT'])
        self.assertEqual(parser.get('bigcouch', 'cookie'),
                         self.container.env['ERLANG_COOKIE']
        )

    def test_correct_zone_in_zone_section_of_config_ini(self):
        """Assert correct zone in zone section of config.ini"""
        cmd = 'cat /etc/kazoo/core/config.ini'
        output = self.container.exec(cmd, output_only=True)
        parser = configparser.ConfigParser(strict=False)
        parser.read_string(output)
        self.assertEqual(parser.get('zone', 'name'),
                         '%s-%s' % (self.container.env['COUNTRY'],
                                    self.container.env['REGION'])
        )

    def test_correct_zone_in_kazoo_apps_section_of_config_ini(self):
        """Assert correct zone in kazoo_apps section of config.ini"""
        cmd = 'cat /etc/kazoo/core/config.ini'
        output = self.container.exec(cmd, output_only=True)
        parser = configparser.ConfigParser(strict=False)
        parser.read_string(output)
        self.assertEqual(parser.get('kazoo_apps', 'zone'),
                         '%s-%s' % (self.container.env['COUNTRY'],
                                    self.container.env['REGION'])
        )

    def test_correct_cookie_in_kazoo_apps_section_of_config_ini(self):
        """Assert correct cookie in kazoo_apps section of config.ini"""
        cmd = 'cat /etc/kazoo/core/config.ini'
        output = self.container.exec(cmd, output_only=True)
        parser = configparser.ConfigParser(strict=False)
        parser.read_string(output)
        self.assertEqual(parser.get('kazoo_apps', 'cookie'),
                         self.container.env['ERLANG_COOKIE']
        )

    def test_correct_host_in_kazoo_apps_section_of_config_ini(self):
        """Assert correct host in kazoo_apps section of config.ini"""
        cmd = 'cat /etc/kazoo/core/config.ini'
        output = self.container.exec(cmd, output_only=True)
        parser = configparser.ConfigParser(strict=False)
        parser.read_string(output)
        self.assertIn(parser.get('kazoo_apps', 'host'),
                      self.container.hostnames
        )

    def test_correct_console_log_level_in_log_section_of_config_ini(self):
        """Assert correct console log_level in log section of config.ini"""
        cmd = 'cat /etc/kazoo/core/config.ini'
        output = self.container.exec(cmd, output_only=True)
        parser = configparser.ConfigParser(strict=False)
        parser.read_string(output)
        self.assertEqual(parser.get('log', 'console'),
                         self.container.env['KAZOO_LOG_LEVEL']
        )


if __name__ == '__main__':
    testdocker.main()
