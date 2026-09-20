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


def acquire_profile(raw, owner):
    path = profile_path(raw)
    # ps is used only to refuse an occupied profile, never to select kill targets.
    commands = subprocess.check_output(['ps', '-axww', '-o', 'command='], text=True)
    for target in {str(path), str(path / 'chrome'),
                   os.path.abspath(os.path.expanduser(raw)),
                   os.path.join(os.path.abspath(os.path.expanduser(raw)), 'chrome')}:
        pattern = r'--user-data-dir(?:=|\s+)[\"\']?' + re.escape(target) + r'(?:[\"\']?(?:\s|$))'
        if re.search(pattern, commands):
            raise ValueError(f'Browser profile already in use: {path}')
    if any((path / 'chrome' / name).is_symlink() or (path / 'chrome' / name).exists()
           for name in ('SingletonLock', 'SingletonSocket')):
        raise ValueError(f'Browser profile has a Chrome lock: {path}')
    path.mkdir(parents=True, exist_ok=True)
    lock = path / '.full-run-bot.lock'
    try:
        lock.mkdir()
    except FileExistsError:
        raise ValueError(f'Browser profile already leased: {path}') from None
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
            status = child.wait()
            os.write(write_fd, f'exit {status}\n'.encode())
            while True:
                signal.pause()
        except BaseException as error:
            print(f'Owned command failed: {error}', file=sys.stderr, flush=True)
            os.write(write_fd, b'exit 127\n')
            while True:
                signal.pause()
    os.close(write_fd)
    status = 127
    ready = False
    pending = b''
    try:
        while True:
            if ready and interrupted:
                status = 128 + interrupted[0]
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
            print(acquire_profile(sys.argv[2], sys.argv[3]))
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
