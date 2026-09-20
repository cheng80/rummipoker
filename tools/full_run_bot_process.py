#!/usr/bin/env python3
"""Owned command groups and profile leases shared by both bot runners (POSIX)."""
import os
from pathlib import Path
import re
import select
import signal
import subprocess
import sys
import time


def profile_path(raw):
    path = Path(raw).expanduser().resolve()
    # Never allow a fresh run to clear a root, home, checkout, or their ancestors.
    protected = {Path('/'), Path('/tmp').resolve(), Path.home().resolve()}
    protected.update(Path.cwd().resolve().parents)
    protected.add(Path.cwd().resolve())
    if not raw or any(ord(c) < 32 for c in raw) or path in protected or len(path.parts) < 3:
        raise ValueError(f'Unsafe browser profile dir: {raw}')
    return path


def process_started_at(pid):
    """Wall-clock start time of a live PID, or None when it cannot be read."""
    started = subprocess.run(['ps', '-o', 'lstart=', '-p', str(pid)],
                             capture_output=True, text=True,
                             env=dict(os.environ, LC_ALL='C')).stdout
    try:
        return time.mktime(time.strptime(' '.join(started.split()),
                                         '%a %b %d %H:%M:%S %Y'))
    except ValueError:
        return None


def lease_is_stale(lock):
    """A lease outlives its owner when SIGKILL, a closed terminal, or a reboot
    skips the runner's EXIT trap. Reclaim it only when the recorded PID is gone,
    or when the PID is alive but started after the lease was taken, which means
    the number was recycled onto an unrelated process."""
    owner_file = lock / 'owner'
    if not owner_file.exists():
        # Nothing records the owner, so nothing can ever release this lease.
        return True
    try:
        pid = int(owner_file.read_text().split(':')[0])
        leased_at = owner_file.stat().st_mtime
    except (OSError, ValueError):
        # An owner we cannot check may still be alive: refuse instead of stealing.
        return False
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return True
    except PermissionError:
        return False
    started = process_started_at(pid)
    return started is not None and started > leased_at + 2


def acquire_profile(raw, owner, fresh=False):
    path = profile_path(raw)
    # ps is used only to refuse an occupied profile, never to select kill targets.
    commands = subprocess.check_output(['ps', '-axww', '-o', 'command='], text=True)
    for target in {str(path), str(path / 'chrome'),
                   os.path.abspath(os.path.expanduser(raw)),
                   os.path.join(os.path.abspath(os.path.expanduser(raw)), 'chrome')}:
        pattern = r'--user-data-dir(?:=|\s+)[\"\']?' + re.escape(target) + r'(?:[\"\']?(?:\s|$))'
        if re.search(pattern, commands):
            raise ValueError(f'Browser profile already in use: {path}')
    # A Chrome that died without cleaning up leaves this lock behind, so it only
    # proves the profile is unusable as is. A fresh run deletes the whole chrome/
    # directory later and must not be refused here; a resume keeps it and must be.
    # Either way the lock itself is never removed at lease time. The --user-data-dir
    # scan above is what refuses a profile a live Chrome is actually holding.
    if not fresh and any((path / 'chrome' / name).is_symlink() or (path / 'chrome' / name).exists()
                         for name in ('SingletonLock', 'SingletonSocket')):
        raise ValueError(f'Browser profile has a Chrome lock: {path}')
    path.mkdir(parents=True, exist_ok=True)
    lock = path / '.full-run-bot.lock'
    try:
        lock.mkdir()
    except FileExistsError:
        if not lease_is_stale(lock):
            raise ValueError(f'Browser profile already leased: {path} (remove {lock} '
                             'only after checking its owner file)') from None
        # Remove only what acquire itself creates, never an unexpected tree.
        (lock / 'owner').unlink(missing_ok=True)
        lock.rmdir()
        try:
            lock.mkdir()
        except FileExistsError:
            raise ValueError(f'Browser profile already leased: {path} ({lock})') from None
    try:
        (lock / 'owner').write_text(owner)
    except BaseException:
        lock.rmdir()
        raise
    return path


def release_profile(raw, owner):
    lock = profile_path(raw) / '.full-run-bot.lock'
    if (lock / 'owner').is_file() and (lock / 'owner').read_text() == owner:
        (lock / 'owner').unlink()
        lock.rmdir()


def owns_port(owner_pid, port):
    """Check listener ancestry after startup; never use listener PIDs to kill."""
    listeners = subprocess.run(
        ['lsof', '-nP', '-t', f'-iTCP:{port}', '-sTCP:LISTEN'],
        capture_output=True, text=True,
    ).stdout.split()
    rows = subprocess.check_output(['ps', '-ax', '-o', 'pid=,ppid='], text=True)
    parents = dict(map(int, row.split()) for row in rows.splitlines() if row.strip())
    if not listeners:
        return False
    for listener in listeners:
        pid = int(listener)
        seen = set()
        while pid != owner_pid:
            if pid in seen or pid not in parents:
                return False
            seen.add(pid)
            pid = parents[pid]
    return True


def reset_signals():
    for sig in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP):
        signal.signal(sig, signal.SIG_DFL)


def cleanup_own_group():
    """Tear down the group this keeper created with setsid, itself included."""
    group = os.getpgid(0)
    os.killpg(group, signal.SIGTERM)
    time.sleep(0.3)
    os.killpg(group, signal.SIGKILL)
    os._exit(0)  # Unreachable, but the keeper must never fall into parent code.


def wait_until_orphaned():
    """Keeper backstop. The keeper normally waits for its parent to tear the group
    down, but SIGKILL on the parent skips that. Poll instead of blocking forever:
    once the parent is gone, clean up this keeper's group and exit, so no
    chromedriver or Chrome is left holding a port."""
    while os.getppid() != 1:
        time.sleep(0.1)
    cleanup_own_group()


def run_owned(command):
    """Keep a live group leader until cleanup, so a reused PID is never targeted.

    The keeper reports the command status but stays alive. Its parent terminates
    the complete owned group before reaping the keeper, including orphaned
    grandchildren. No process-name, profile-substring, or port-based killing.
    """
    interrupted = []
    for sig in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP):
        signal.signal(sig, lambda number, frame: interrupted.append(number))
    read_fd, write_fd = os.pipe()
    keeper = os.fork()
    if keeper == 0:
        os.close(read_fd)
        os.setsid()
        for sig in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP):
            signal.signal(sig, signal.SIG_IGN)
        try:
            os.write(write_fd, b'ready\n')
            child = subprocess.Popen(command, preexec_fn=reset_signals)
            # Poll rather than block in wait(): the parent can be SIGKILLed while
            # the command is still running, and nothing would wake a blocked wait.
            while child.poll() is None:
                if os.getppid() == 1:
                    cleanup_own_group()
                time.sleep(0.1)
            os.write(write_fd, f'exit {child.returncode}\n'.encode())
            wait_until_orphaned()
        except BrokenPipeError:
            cleanup_own_group()
        except BaseException as error:
            print(f'Owned command failed: {error}', file=sys.stderr, flush=True)
            try:
                os.write(write_fd, b'exit 127\n')
            except OSError:
                pass
            wait_until_orphaned()
    os.close(write_fd)
    status = 127
    ready = False
    pending = b''
    try:
        while True:
            if ready and interrupted:
                status = 128 + interrupted[0]
                break
            # A SIGKILLed runner cannot signal us, so notice it ourselves.
            if os.getppid() == 1:
                break
            readable, _, _ = select.select([read_fd], [], [], 0.1)
            if not readable:
                continue
            data = os.read(read_fd, 4096)
            if not data:
                break
            pending += data
            lines = pending.split(b'\n')
            pending = lines.pop()
            finished = False
            for line in lines:
                if line == b'ready':
                    ready = True
                elif line.startswith(b'exit '):
                    status = int(line[5:])
                    status = status if status >= 0 else 128 - status
                    finished = True
            if finished:
                break
    finally:
        # keeper is our unreaped direct child: its PID/group cannot be recycled.
        if ready:
            try:
                os.killpg(keeper, signal.SIGTERM)
                time.sleep(0.3)
                os.killpg(keeper, signal.SIGKILL)
            except ProcessLookupError:
                pass
        else:
            try:
                os.kill(keeper, signal.SIGKILL)
            except ProcessLookupError:
                pass
        os.waitpid(keeper, 0)
        os.close(read_fd)
    return status


if __name__ == '__main__':
    try:
        if sys.argv[1] == 'acquire':
            print(acquire_profile(sys.argv[2], sys.argv[3],
                                  fresh=sys.argv[4:5] == ['fresh']))
        elif sys.argv[1] == 'release':
            release_profile(sys.argv[2], sys.argv[3])
        elif sys.argv[1] == 'owns-port':
            sys.exit(0 if owns_port(int(sys.argv[2]), int(sys.argv[3])) else 1)
        elif sys.argv[1] == 'run':
            sys.exit(run_owned(sys.argv[2:]))
        else:
            raise ValueError('Expected acquire, release, or run')
    except (ValueError, OSError) as error:
        print(error, file=sys.stderr)
        sys.exit(1)
