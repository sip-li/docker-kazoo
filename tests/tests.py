import unittest
import configparser

import testdocker
from testdocker import (
    ContainerTestMixinBase,
    ContainerTestMixin,
    CommandBase,
    CurlCommand,
    NetCatCommand,
    CatCommand,
    Container
)

class SupCommand(CommandBase):
    def __init__(self, module, function, *args):
        cmd = ['sup']
        cmd.append(module)
        cmd.append(function)
        if args:
            cmd.extend(args)
        self.cmd = ' '.join(cmd)


class TestKazooBasic(ContainerTestMixin, unittest.TestCase):
    """Run basic tests on kazoo container."""

    name = 'kazoo'
    tear_down = False
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
        amqp_hosts = self.container.env['RABBITMQ_HOSTS'].split(',')
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
                         '%s-%s' % (self.container.env['REGION'],
                                    self.container.env['DATACENTER'])
        )

    def test_correct_zone_in_kazoo_apps_section_of_config_ini(self):
        """Assert correct zone in kazoo_apps section of config.ini"""
        cmd = 'cat /etc/kazoo/core/config.ini'
        output = self.container.exec(cmd, output_only=True)
        parser = configparser.ConfigParser(strict=False)
        parser.read_string(output)
        self.assertEqual(parser.get('kazoo_apps', 'zone'),
                         '%s-%s' % (self.container.env['REGION'],
                                    self.container.env['DATACENTER'])
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


class TestKazooExtended(ContainerTestMixinBase, unittest.TestCase):
    """Run extended tests on kazoo container."""

    name = 'kazoo'
    tear_down = False

    def test_sup_create_master_account(self):
        """Assert sup crossbar_maintenance create_account was successful."""
        cmd = SupCommand('crossbar_maintenance', 'create_account', 'test', 'localhost', 'admin', 'secret')
        exit_code, output = self.container.exec(cmd)
        self.assertEqual(exit_code, 0)
        output = output.split('\n')
        self.assertRegex(output[0], r'^created new account')
        self.assertRegex(output[1], r'^created new account admin user')
        self.assertRegex(output[2], r'^promoting account')
        self.assertRegex(output[3], r'^updating master account id in system_config.accounts')

    def test_sup_load_media(self):
        """Assert sup kazoo_media_maintenance import_prompts was successful."""
        cmd = SupCommand('kazoo_media_maintenance', 'import_prompts', '/opt/kazoo/media/prompts/en/us', 'en-us')
        exit_code, output = self.container.exec(cmd)
        output = output.split('\n')
        self.assertEqual(exit_code, 0)
        self.assertGreater(len(output), 1)
        self.assertRegex(output[-2], r'^importing went successfully')

    def test_sup_init_apps(self):
        """Assert sup crossbar_maintenance init_apps was successful."""
        cmd = SupCommand('crossbar_maintenance', 'init_apps', '/var/www/html/monster-ui/apps', 'http://localhost:8000/v2')
        exit_code, output = self.container.exec(cmd)
        output = output.split('\n')
        self.assertEqual(exit_code, 0)
        self.assertGreater(len(output), 4)

    def test_sup_add_freeswitch_node(self):
        """Assert sup ecallmgr_maintenance add_fs_node was successful."""
        cmd = SupCommand('ecallmgr_maintenance', 'add_fs_node', 'freeswitch@freeswitch.local')
        exit_code, output = self.container.exec(cmd)
        self.assertEqual(exit_code, 0)
        self.assertGreater(len(output), 1)
        self.assertRegex(output, r'adding freeswitch@')

    def test_sup_add_sbc(self):
        """Assert sup ecallmgr_maintenance allow_sbc was successful."""
        kamailio = Container('kamailio')
        kamailio_host = 'kamailio.valuphone.local'
        cmd = SupCommand('ecallmgr_maintenance', 'allow_sbc', kamailio_host, kamailio.ip)
        exit_code, output = self.container.exec(cmd)
        self.assertEqual(exit_code, 0)
        self.assertGreater(len(output), 1)
        self.assertRegex(
            output,
            r'updating authoritative ACLs %s\(%s\/32\) to allow traffic' % (
                kamailio_host, kamailio.ip
            )
        )


if __name__ == '__main__':
    testdocker.main()
