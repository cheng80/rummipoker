"""No real browser: mocked runner commands and explicitly owned test children only."""
import os
from pathlib import Path
import subprocess
import signal
import socket
import sys
import time
import json
import importlib.util
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


def isolated_environment():
    # A developer's trace/profile/driver overrides must never escape test dirs.
    return {key: value for key, value in os.environ.items()
            if not key.startswith(('FULL_RUN_BOT_', 'CHROMEDRIVER_'))
            and key not in ('FLUTTER_BIN', 'BASH_ENV')}


class RunnerSafetyTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='bot-runner-test-')
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.bin = self.base / 'bin'
        self.bin.mkdir()
        self.profile = self.base / 'profile'
        self.profile.mkdir()
        (self.profile / 'sentinel').write_text('preserve')
        self.events = self.base / 'events'
        env_file = self.base / 'bash_env'
        env_file.write_text('''
kill() { echo "kill $*" >> "$TEST_EVENTS"; return 1; }
rm() { echo "rm $*" >> "$TEST_EVENTS"; }
''')
        self.env = dict(isolated_environment(), BASH_ENV=str(env_file),
                        PATH=f'{self.bin}:{os.environ["PATH"]}',
                        TEST_EVENTS=str(self.events),
                        FULL_RUN_BOT_PROGRESS_PORT='0',
                        FULL_RUN_BOT_BRIDGE_RESUME_LIMIT='0',
                        FLUTTER_BIN=str(self.bin / 'flutter'))
        self.mock('flutter', 'echo "flutter $*" >> "$TEST_EVENTS"; exit 7')
        self.mock('nc', '[[ "${@: -1}" == "4444" || "${@: -1}" == "${MOCK_BUSY_PORT:-}" ]]')
        self.mock('lsof', 'echo 987654')
        self.mock('ps', 'printf "%s\\n" "${MOCK_PS_ROWS:-}"')
        self.mock('sleep', 'exit 0')

    def mock(self, name, body):
        target = self.bin / name
        target.write_text('#!/bin/bash\n' + body + '\n')
        target.chmod(0o755)

    def run_runner(self, runner, profile=None, **env):
        self.events.unlink(missing_ok=True)
        result = subprocess.run(
            ['bash', str(ROOT / 'tools' / runner), '--skip-pub-get',
             '--browser-profile-dir', str(profile or self.profile),
             '--output-dir', str(self.base / 'output')],
            env=dict(self.env, **env), capture_output=True, text=True, timeout=15)
        events = self.events.read_text() if self.events.exists() else ''
        return result, events

    def test_external_web_port_is_not_killed(self):
        for runner in ('full_run_bot.sh', 'sub_run_bot.sh'):
            with self.subTest(runner=runner):
                result, events = self.run_runner(runner, MOCK_BUSY_PORT='7357')
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn('kill ', events)
                self.assertNotIn('flutter ', events)
                self.assertEqual((self.profile / 'sentinel').read_text(), 'preserve')

    def test_root_profile_rejected_before_cleanup(self):
        for runner in ('full_run_bot.sh', 'sub_run_bot.sh'):
            with self.subTest(runner=runner):
                result, events = self.run_runner(runner, profile='/')
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn('kill ', events)
                self.assertNotIn('rm ', events)
                self.assertNotIn('flutter ', events)

    def test_sibling_profile_is_not_killed(self):
        for runner in ('full_run_bot.sh', 'sub_run_bot.sh'):
            with self.subTest(runner=runner):
                result, events = self.run_runner(
                    runner, MOCK_PS_ROWS=f'987655 Chrome --user-data-dir={self.profile}-sibling/chrome')
                self.assertNotIn('kill ', events)

    def test_external_driver_and_progress_ports_fail_fast(self):
        for runner, busy in (('full_run_bot.sh', '4444'), ('sub_run_bot.sh', '4444'),
                             ('full_run_bot.sh', '7358')):
            with self.subTest(runner=runner, busy=busy):
                self.mock('nc', '[[ "${@: -1}" == "${MOCK_BUSY_PORT:-}" ]]')
                result, events = self.run_runner(runner, MOCK_BUSY_PORT=busy,
                                                FULL_RUN_BOT_PROGRESS_PORT='7358')
                self.assertNotEqual(result.returncode, 0)
                self.assertIn('already in use', result.stderr)
                self.assertNotIn('kill ', events)
                self.assertNotIn('flutter ', events)

    def test_busy_profile_is_not_cleared(self):
        for runner in ('full_run_bot.sh', 'sub_run_bot.sh'):
            with self.subTest(runner=runner):
                result, events = self.run_runner(
                    runner, MOCK_PS_ROWS=f'Chrome --user-data-dir={self.profile}/chrome')
                self.assertNotEqual(result.returncode, 0)
                self.assertIn('profile already in use', result.stderr)
                self.assertNotIn('rm ', events)
                self.assertNotIn('kill ', events)

    def test_invalid_mode_and_ports_are_rejected(self):
        for runner in ('full_run_bot.sh', 'sub_run_bot.sh'):
            for env in ({'FULL_RUN_BOT_FLUTTER_MODE': 'invalid'},
                        {'FULL_RUN_BOT_WEB_PORT': '0'},
                        {'FULL_RUN_BOT_WEB_PORT': '4444'},
                        {'FULL_RUN_BOT_WEB_PORT': '999999999999999999999'}):
                with self.subTest(runner=runner, env=env):
                    result, events = self.run_runner(runner, **env)
                    self.assertNotEqual(result.returncode, 0)
                    self.assertNotIn('kill ', events)
                    self.assertNotIn('flutter ', events)

    def test_full_runner_rejects_unowned_driver_option(self):
        result = subprocess.run(['bash', str(ROOT / 'tools/full_run_bot.sh'),
                                 '--no-start-chromedriver'], env=self.env,
                                capture_output=True, text=True, timeout=5)
        self.assertEqual(result.returncode, 1)
        self.assertIn('runner owns WebDriver', result.stderr)


class OwnedLifecycleTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='bot-owned-test-')
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.helper = ROOT / 'tools/full_run_bot_process.py'

    def alive(self, pid):
        result = subprocess.run(['ps', '-o', 'stat=', '-p', str(pid)],
                                capture_output=True, text=True)
        return bool(result.stdout.strip()) and not result.stdout.strip().startswith('Z')

    def wait_for(self, predicate):
        deadline = time.monotonic() + 10
        while time.monotonic() < deadline:
            if predicate():
                return
            time.sleep(0.02)
        self.fail('Timed out waiting for test-owned process state')

    def test_real_test_owned_listener_survives_preflight(self):
        with socket.socket() as listener:
            listener.bind(('127.0.0.1', 0))
            listener.listen()
            port = listener.getsockname()[1]
            for runner in ('full_run_bot.sh', 'sub_run_bot.sh'):
                with self.subTest(runner=runner):
                    env = dict(isolated_environment(), FULL_RUN_BOT_WEB_PORT=str(port),
                               FULL_RUN_BOT_PROGRESS_PORT='0')
                    env.pop('BASH_ENV', None)
                    result = subprocess.run(['bash', str(ROOT / 'tools' / runner),
                                             '--skip-pub-get', '--browser-profile-dir',
                                             str(self.base / runner), '--output-dir', str(self.base / 'logs')],
                                            env=env, capture_output=True, text=True, timeout=5)
                    self.assertEqual(result.returncode, 1)
                    self.assertIn(f'Bot port already in use: {port}', result.stderr)
                    self.assertEqual(listener.getsockname()[1], port)
                    # Drain nc's test connection, proving the listener is still ours.
                    listener.settimeout(1)
                    conn, _ = listener.accept()
                    conn.close()

    def test_owned_group_success_failure_interrupt_and_timeout(self):
        for mode in ('success', 'failure', 'interrupt', 'timeout'):
            with self.subTest(mode=mode):
                pidfile = self.base / f'{mode}.pid'
                child = ('import os,signal,time; '
                         'signal.signal(signal.SIGTERM, signal.SIG_IGN); '
                         f'open({str(pidfile)!r}, "w").write(str(os.getpid())); '
                         'time.sleep(60)')
                command = ('import subprocess,sys,time; '
                           f'subprocess.Popen([sys.executable,"-c",{child!r}]); '
                           'time.sleep(0.15); ' +
                           ('sys.exit(0)' if mode == 'success' else
                            'sys.exit(7)' if mode == 'failure' else 'time.sleep(60)'))
                proc = subprocess.Popen([sys.executable, str(self.helper), 'run',
                                         sys.executable, '-c', command],
                                        stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                        text=True)
                self.wait_for(pidfile.exists)
                pid = int(pidfile.read_text())
                if mode == 'interrupt':
                    proc.send_signal(signal.SIGINT)
                elif mode == 'timeout':
                    with self.assertRaises(subprocess.TimeoutExpired):
                        proc.wait(timeout=0.1)
                    proc.terminate()
                output, _ = proc.communicate(timeout=10)
                expected = {'success': 0, 'success_exit': 0, 'failure': 7, 'interrupt': 130, 'timeout': 143}[mode]
                self.assertEqual(proc.returncode, expected, output)
                self.wait_for(lambda: not self.alive(pid))

    def test_both_runners_clean_owned_children(self):
        for runner in ('full_run_bot.sh', 'sub_run_bot.sh'):
            for mode in ('success', 'success_exit', 'failure', 'interrupt', 'timeout'):
                with self.subTest(runner=runner, mode=mode):
                    case = self.base / f'{runner}-{mode}'
                    case.mkdir()
                    bin_dir = case / 'bin'
                    bin_dir.mkdir()
                    # Accelerate shell polling only; child lifecycle remains real.
                    sleep = bin_dir / 'sleep'
                    sleep.write_text('#!/bin/sh\nexec /bin/sleep 0.05\n')
                    sleep.chmod(0o755)
                    driver = bin_dir / 'chromedriver'
                    driver.write_text('#!' + sys.executable + "\n" +
                        'import os,socket,sys,time\n'
                        'from pathlib import Path\n'
                        's=socket.socket(); s.bind(("127.0.0.1",int(sys.argv[1].split("=")[1]))); s.listen()\n'
                        'Path(os.environ["TEST_CASE"],"driver.pid").write_text(str(os.getpid()))\n'
                        'time.sleep(60)\n')
                    driver.chmod(0o755)
                    flutter = bin_dir / 'flutter'
                    flutter.write_text('#!' + sys.executable + "\n" +
                        'import os,subprocess,sys,time,json\n'
                        'from pathlib import Path\n'
                        'base=Path(os.environ["TEST_CASE"])\n'
                        'base.joinpath("args.json").write_text(json.dumps(sys.argv[1:]))\n'
                        'child="import signal,time; signal.signal(signal.SIGTERM,signal.SIG_IGN); time.sleep(60)"\n'
                        'p=subprocess.Popen([sys.executable,"-c",child])\n'
                        'base.joinpath("child.pid").write_text(str(p.pid))\n'
                        'time.sleep(0.1)\n'
                        'print("FULL_RUN_BOT_CHECKPOINT_B64:dGVzdA==",flush=True)\n'
                        'mode=os.environ["TEST_MODE"]\n'
                        'if mode=="failure": sys.exit(7)\n'
                        'if mode=="success_exit": sys.exit(0)\n'
                        'if mode=="success": print("All tests passed!",flush=True)\n'
                        'time.sleep(60)\n')
                    flutter.chmod(0o755)
                    with socket.socket() as a, socket.socket() as b, socket.socket() as c:
                        a.bind(('127.0.0.1', 0)); b.bind(('127.0.0.1', 0)); c.bind(('127.0.0.1', 0))
                        web_port = a.getsockname()[1]
                        driver_port = b.getsockname()[1]
                        progress_port = c.getsockname()[1] if runner == 'full_run_bot.sh' else 0
                    env = dict(isolated_environment(), PATH=f'{bin_dir}:{os.environ["PATH"]}',
                               FLUTTER_BIN=str(flutter), CHROMEDRIVER_CMD=str(driver),
                               CHROMEDRIVER_PORT=str(driver_port), FULL_RUN_BOT_WEB_PORT=str(web_port),
                               FULL_RUN_BOT_PROGRESS_PORT=str(progress_port), FULL_RUN_BOT_BRIDGE_RESUME_LIMIT='0',
                               TEST_CASE=str(case), TEST_MODE=mode)
                    env.pop('BASH_ENV', None)
                    proc = subprocess.Popen(['bash', str(ROOT / 'tools' / runner),
                                             '--skip-pub-get', '--browser-profile-dir', str(case / 'profile'),
                                             '--output-dir', str(case / 'logs')],
                                            env=env, stdout=subprocess.PIPE,
                                            stderr=subprocess.STDOUT, text=True)
                    self.wait_for(lambda: (case / 'child.pid').exists() or proc.poll() is not None)
                    if proc.poll() is not None:
                        output, _ = proc.communicate()
                        self.fail(output)
                    if mode == 'interrupt':
                        proc.send_signal(signal.SIGINT)
                    elif mode == 'timeout':
                        with self.assertRaises(subprocess.TimeoutExpired):
                            proc.wait(timeout=0.1)
                        proc.terminate()
                    output, _ = proc.communicate(timeout=15)
                    expected = {'success': 0, 'success_exit': 0, 'failure': 7, 'interrupt': 130, 'timeout': 143}[mode]
                    self.assertEqual(proc.returncode, expected, output)
                    for name in ('driver.pid', 'child.pid'):
                        pid = int((case / name).read_text())
                        self.wait_for(lambda: not self.alive(pid))
                    self.assertFalse((case / 'profile/.full-run-bot.lock').exists())
                    if progress_port:
                        with self.assertRaises(OSError):
                            socket.create_connection(('127.0.0.1', progress_port), timeout=0.2)
                    args = json.loads((case / 'args.json').read_text())
                    self.assertIn('--profile', args)
                    self.assertIn('web-server', args)
                    self.assertIn(f'--web-browser-flag=--user-data-dir={case.resolve()}/profile/chrome', args)
                    if mode in ('success', 'success_exit', 'failure'):
                        self.assertIn('dGVzdA==', (case / 'profile/latest_checkpoint.env').read_text())


class ProfileLeaseTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='bot-profile-test-')
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name).resolve()
        spec = importlib.util.spec_from_file_location('bot_process', ROOT / 'tools/full_run_bot_process.py')
        self.helper = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.helper)

    def test_listener_must_be_an_owned_descendant(self):
        from unittest.mock import patch
        from types import SimpleNamespace
        for listeners, expected in (('102\n', True), ('200\n', False),
                                    ('102\n200\n', False), ('', False)):
            with self.subTest(listeners=listeners), \
                 patch.object(self.helper.subprocess, 'run',
                              return_value=SimpleNamespace(stdout=listeners)), \
                 patch.object(self.helper.subprocess, 'check_output',
                              return_value='100 1\n101 100\n102 101\n200 1\n'):
                self.assertEqual(self.helper.owns_port(100, 7357), expected)

    def test_chrome_singleton_lock_is_never_removed(self):
        chrome = self.base / 'profile/chrome'
        chrome.mkdir(parents=True)
        singleton = chrome / 'SingletonLock'
        singleton.symlink_to('host-999999')
        with self.assertRaises(ValueError):
            self.helper.acquire_profile(str(chrome.parent), 'owner')
        self.assertTrue(singleton.is_symlink())

    def test_invalid_profile_and_canonical_alias_lock(self):
        for raw in ('', '/', '/tmp/..', str(ROOT), str(Path.home())):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                self.helper.profile_path(raw)
        profile = self.helper.acquire_profile(str(self.base / 'profile'), 'owner')
        alias = self.base / 'alias'
        alias.symlink_to(profile, target_is_directory=True)
        with self.assertRaises(ValueError):
            self.helper.acquire_profile(str(alias), 'other')
        self.helper.release_profile(str(alias), 'other')
        self.assertTrue((profile / '.full-run-bot.lock').exists())
        self.helper.release_profile(str(alias), 'owner')
        self.assertFalse((profile / '.full-run-bot.lock').exists())

    def test_exact_profile_refused_but_sibling_allowed(self):
        from unittest.mock import patch
        profile = self.base / 'profile with space'
        with patch.object(self.helper.subprocess, 'check_output',
                          return_value=f'Chrome --user-data-dir="{profile}/chrome" --flag\n'):
            with self.assertRaises(ValueError):
                self.helper.acquire_profile(str(profile), 'owner')
        with patch.object(self.helper.subprocess, 'check_output',
                          return_value=f'Chrome --user-data-dir="{profile}-sibling/chrome" --flag\n'):
            self.helper.acquire_profile(str(profile), 'owner')
            self.helper.release_profile(str(profile), 'owner')


if __name__ == '__main__':
    unittest.main(verbosity=2)
