#!/usr/bin/env python3
"""
Kenney의 CC0 오디오 팩에서 게임 효과음을 만들어 `assets/audio/sfx/`에 넣는다.

같은 입력이면 항상 같은 출력이 나오도록 만들었다. 팩을 내려받는 일, 앞쪽 무음을
잘라 내는 일, 길이를 자르는 일, 음량을 기존 효과음 수준으로 맞추는 일, 끝을
짧게 줄여 끊김을 없애는 일까지 한 번에 처리한다. 출처와 가공 내역을 적은
`assets/audio/sfx/CREDITS.md`도 이 스크립트가 함께 쓴다.

사전 요건: PATH에 ffmpeg 와 ffprobe 가 있어야 한다.

예시:
  # 팩을 내려받고 효과음을 다시 만든다
  python3 tools/build_sfx.py --src-root /tmp/sfx_src --download

  # 이미 받아 둔 팩으로 다시 만든다
  python3 tools/build_sfx.py --src-root /tmp/sfx_src

  # 무엇을 만들지만 보고 파일은 건드리지 않는다
  python3 tools/build_sfx.py --src-root /tmp/sfx_src --dry-run
"""

from __future__ import annotations

import argparse
import io
import re
import shutil
import subprocess
import sys
import tempfile
import urllib.request
import zipfile
from dataclasses import dataclass
from pathlib import Path

# 팩 하나가 kenney.nl의 어느 페이지에서 오는지. zip 주소에는 갱신될 때마다 바뀌는
# 해시가 들어 있어 주소를 적어 두지 않고 페이지에서 그때그때 찾아낸다.
PACK_PAGES = {
    "casino-audio": "https://kenney.nl/assets/casino-audio",
    "interface-sounds": "https://kenney.nl/assets/interface-sounds",
    "impact-sounds": "https://kenney.nl/assets/impact-sounds",
    "digital-audio": "https://kenney.nl/assets/digital-audio",
    "music-jingles": "https://kenney.nl/assets/music-jingles",
}

# 기존 효과음 7개를 volumedetect로 잰 값의 가운데. 새 효과음도 이 수준에 맞춘다.
TARGET_MEAN_DB = -22.0
PEAK_CEILING_DB = -1.0

# 무음으로 볼 기준. 이보다 작은 앞부분은 잘라 내 입력 직후 바로 소리가 나게 한다.
SILENCE_THRESHOLD_DB = -50.0

MP3_BITRATE = "128k"


@dataclass(frozen=True)
class Cut:
    """효과음 하나를 어떤 원본에서 어떻게 만드는지."""

    out: str
    pack: str
    source: str
    max_seconds: float
    family: str

    @property
    def is_wav(self) -> bool:
        return self.out.endswith(".wav")


# 소리 지도. 45개 cue를 계열로 묶고 계열마다 파일 하나를 만든다.
# 계열 안의 차이는 `game_feedback_cues.dart`에서 pitch로 낸다.
#
# 아주 짧은 UI 소리는 wav로 둔다. mp3 인코더가 파일 앞에 붙이는 패딩 때문에
# 손가락을 떼는 순간보다 소리가 늦게 들릴 수 있어서다.
CUTS = (
    Cut("UiToggle.wav", "interface-sounds", "Audio/toggle_001.ogg", 0.40, "토글·탭 전환"),
    Cut("PanelOpen.mp3", "interface-sounds", "Audio/open_004.ogg", 0.40, "모달 열림"),
    Cut("PanelClose.mp3", "interface-sounds", "Audio/close_004.ogg", 0.40, "모달 닫힘"),
    Cut("Deny.mp3", "interface-sounds", "Audio/error_008.ogg", 0.40, "거부"),
    Cut("TilePick.wav", "casino-audio", "Audio/card-slide-4.ogg", 0.25, "타일 집기"),
    Cut("TilePlace.wav", "casino-audio", "Audio/card-place-1.ogg", 0.30, "타일 놓기"),
    Cut("CardDraw.mp3", "casino-audio", "Audio/card-slide-1.ogg", 0.40, "드로우"),
    Cut("CardToss.mp3", "casino-audio", "Audio/card-shove-2.ogg", 0.50, "버리기"),
    Cut("LineLoad.mp3", "casino-audio", "Audio/chips-stack-3.ogg", 0.50, "줄 장전"),
    Cut("StationTick.wav", "interface-sounds", "Audio/confirmation_001.ogg", 0.35, "정산 단계"),
    Cut("ScoreTick.wav", "interface-sounds", "Audio/pluck_001.ogg", 0.20, "점수 카운트"),
    Cut("MultHit.mp3", "impact-sounds", "Audio/impactPunch_medium_000.ogg", 0.60, "배수 타격"),
    Cut("JesterFire.mp3", "digital-audio", "Audio/phaserUp3.ogg", 0.80, "Jester·Item 발동"),
    Cut("ScoreImpact.mp3", "impact-sounds", "Audio/impactPlate_heavy_000.ogg", 1.20, "최종 점수"),
    Cut("Gold.mp3", "casino-audio", "Audio/chips-collide-1.ogg", 1.00, "gold 거래"),
    Cut("Shuffle.mp3", "casino-audio", "Audio/card-shuffle.ogg", 1.20, "리롤"),
    Cut("BossIntro.mp3", "impact-sounds", "Audio/impactBell_heavy_000.ogg", 2.50, "Boss 등장"),
    Cut(
        "Reward.mp3",
        "music-jingles",
        "Audio/Steel jingles/jingles_STEEL00.ogg",
        1.50,
        "보상 공개",
    ),
)

CREDITS_HEADER = """<!-- tools/build_sfx.py 가 만든다. 직접 고치지 말고 스크립트를 고친 뒤 다시 실행한다. -->

# 효과음 출처

`assets/audio/sfx/`의 효과음이 어디에서 왔고 어떤 가공을 거쳤는지 적는다.

## 새로 넣은 효과음

원본은 모두 Kenney(<https://kenney.nl>)의 CC0 오디오 팩이다. CC0는 저작자 표시
의무가 없고 상업적으로 써도 된다. 팩마다 들어 있는 `License.txt`에서 직접
확인했다. 라이선스 전문은 <https://creativecommons.org/publicdomain/zero/1.0/>
에 있다.

공통 가공은 다음과 같다. mono 44.1kHz로 바꾸고, 앞쪽의 {threshold} 이하 무음을
잘라 입력 직후 바로 소리가 나게 했다. 계열마다 정한 상한까지 길이를 자르고,
상한에 걸려 잘린 소리는 끝에 짧은 fade out을 넣어 잘린 자리가 튀지 않게 했다.
원래 길이대로 끝나는 소리는 그대로 두었다. 음량은 기존 효과음
7개를 잰 값에 맞춰 평균 {mean} 수준으로 올리되 최대치가 {peak}를 넘지 않게
했다. 만드는 과정은 `tools/build_sfx.py` 하나에 들어 있다.

"""

CREDITS_FOOTER = """
## 원래 있던 효과음

`BtnSnd.mp3`, `Clear.mp3`, `Collect.mp3`, `Fail.mp3`, `Start.mp3`,
`TimeTic.mp3`, `TimeUp.wav`는 이 저장소에 먼저 있던 파일이다. 이번 작업에서
건드리지 않았고 출처 기록도 따로 남아 있지 않다.
"""


def run(cmd: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, check=True, capture_output=True, text=True)


def probe_duration(path: Path) -> float:
    out = run(
        [
            "ffprobe",
            "-v",
            "error",
            "-show_entries",
            "format=duration",
            "-of",
            "csv=p=0",
            str(path),
        ]
    ).stdout
    return float(out.strip())


def probe_volume(path: Path) -> tuple[float, float]:
    """(mean_volume, max_volume)을 dB로 돌려준다."""
    proc = subprocess.run(
        ["ffmpeg", "-hide_banner", "-i", str(path), "-af", "volumedetect", "-f", "null", "-"],
        check=True,
        capture_output=True,
        text=True,
    )
    def pick(key: str) -> float:
        match = re.search(rf"{key}:\s*(-?[\d.]+) dB", proc.stderr)
        if not match:
            raise RuntimeError(f"{path.name}: volumedetect가 {key}를 내놓지 않았다")
        return float(match.group(1))

    return pick("mean_volume"), pick("max_volume")


def download_packs(src_root: Path) -> None:
    """팩 페이지에서 zip 주소를 찾아 내려받고 푼다. 이미 푼 팩은 건너뛴다."""
    for slug, page_url in PACK_PAGES.items():
        target = src_root / f"x_{slug}"
        if (target / "License.txt").exists():
            print(f"이미 있음: {slug}")
            continue
        print(f"내려받는 중: {slug}")
        with urllib.request.urlopen(page_url, timeout=60) as response:
            page = response.read().decode("utf-8", "replace")
        match = re.search(r"https://kenney\.nl/media/pages/assets/[^'\"]+\.zip", page)
        if not match:
            raise RuntimeError(f"{page_url}에서 zip 주소를 찾지 못했다")
        with urllib.request.urlopen(match.group(0), timeout=300) as response:
            payload = response.read()
        with zipfile.ZipFile(io.BytesIO(payload)) as archive:
            archive.extractall(target)
        license_text = (target / "License.txt").read_text("utf-8", "replace")
        if "CC0" not in license_text:
            raise RuntimeError(f"{slug}: License.txt에서 CC0를 확인하지 못했다")


def build_one(cut: Cut, src_root: Path, out_dir: Path) -> dict[str, object]:
    src = src_root / f"x_{cut.pack}" / cut.source
    if not src.exists():
        raise FileNotFoundError(f"원본이 없다: {src}")

    with tempfile.TemporaryDirectory() as tmp_name:
        tmp = Path(tmp_name)
        trimmed = tmp / "trimmed.wav"
        # 1단계: mono 44.1kHz로 바꾸고 앞 무음을 떼고 길이 상한까지 자른다.
        run(
            [
                "ffmpeg",
                "-hide_banner",
                "-loglevel",
                "error",
                "-y",
                "-i",
                str(src),
                "-af",
                (
                    "silenceremove=start_periods=1:start_threshold="
                    f"{SILENCE_THRESHOLD_DB}dB:start_silence=0:detection=peak,"
                    f"atrim=end={cut.max_seconds},asetpts=N/SR/TB"
                ),
                "-ac",
                "1",
                "-ar",
                "44100",
                "-c:a",
                "pcm_s16le",
                str(trimmed),
            ]
        )

        duration = probe_duration(trimmed)
        mean_db, max_db = probe_volume(trimmed)
        # 평균을 목표에 맞추되 최대치가 천장을 넘으면 그만큼만 올린다.
        gain_db = min(TARGET_MEAN_DB - mean_db, PEAK_CEILING_DB - max_db)
        # 길이 상한에 걸려 잘린 소리만 끝을 줄인다. 원래 길이대로 끝난 소리는
        # 이미 자연스럽게 잦아들고, 끝에서 가장 커지는 소리(열림 스윕 등)는
        # fade를 넣으면 정작 들려야 할 부분이 깎인다.
        was_cut = duration >= cut.max_seconds - 0.005
        fade = min(0.06, duration * 0.25) if was_cut else 0.0
        fade_start = max(0.0, duration - fade)
        filters = [f"volume={gain_db:.2f}dB"]
        if fade > 0:
            filters.append(f"afade=t=out:st={fade_start:.3f}:d={fade:.3f}")

        out_path = out_dir / cut.out
        encode = (
            ["-c:a", "pcm_s16le"]
            if cut.is_wav
            else ["-c:a", "libmp3lame", "-b:a", MP3_BITRATE]
        )
        # 2단계: 음량을 맞추고 끝을 짧게 줄인 뒤 최종 형식으로 굽는다.
        run(
            [
                "ffmpeg",
                "-hide_banner",
                "-loglevel",
                "error",
                "-y",
                "-i",
                str(trimmed),
                "-af",
                ",".join(filters),
                "-ac",
                "1",
                "-ar",
                "44100",
                *encode,
                str(out_path),
            ]
        )

    final_mean, final_max = probe_volume(out_path)
    return {
        "cut": cut,
        "duration": probe_duration(out_path),
        "bytes": out_path.stat().st_size,
        "mean_db": final_mean,
        "max_db": final_max,
        "gain_db": gain_db,
    }


def write_credits(rows: list[dict[str, object]], out_dir: Path) -> None:
    lines = [
        CREDITS_HEADER.format(
            threshold=f"{SILENCE_THRESHOLD_DB:g} dB",
            mean=f"{TARGET_MEAN_DB:g} dB",
            peak=f"{PEAK_CEILING_DB:g} dB",
        ),
        "| 파일 | 계열 | 원본 팩 | 원본 파일 | 라이선스 | 길이 | 최대 음량 | 용량 |",
        "|---|---|---|---|---|---|---|---|",
    ]
    for row in rows:
        cut: Cut = row["cut"]  # type: ignore[assignment]
        lines.append(
            f"| `{cut.out}` | {cut.family} | "
            f"[{cut.pack}]({PACK_PAGES[cut.pack]}) | `{cut.source}` | CC0 | "
            f"{row['duration']:.2f}초 | {row['max_db']:.1f} dB | "
            f"{int(row['bytes']) / 1024:.1f} KB |"
        )
    lines.append(CREDITS_FOOTER)
    (out_dir / "CREDITS.md").write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Kenney CC0 팩에서 효과음 만들기")
    parser.add_argument(
        "--src-root",
        type=Path,
        required=True,
        help="팩을 푼 폴더. 저장소 밖의 작업 폴더를 쓴다.",
    )
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=Path("assets/audio/sfx"),
        help="효과음을 넣을 폴더 (기본: assets/audio/sfx)",
    )
    parser.add_argument(
        "--download",
        action="store_true",
        help="팩이 없으면 kenney.nl에서 내려받는다",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="만들 파일 목록만 출력한다",
    )
    args = parser.parse_args()

    if args.dry_run:
        for cut in CUTS:
            print(f"{cut.out:<18} <- {cut.pack}/{cut.source}")
        return 0

    for tool in ("ffmpeg", "ffprobe"):
        if not shutil.which(tool):
            print(f"{tool} 를 찾을 수 없습니다. 설치 후 PATH에 넣어 주세요.", file=sys.stderr)
            return 1

    args.src_root.mkdir(parents=True, exist_ok=True)
    if args.download:
        download_packs(args.src_root)

    args.out_dir.mkdir(parents=True, exist_ok=True)
    rows = [build_one(cut, args.src_root, args.out_dir) for cut in CUTS]
    write_credits(rows, args.out_dir)

    total = sum(int(row["bytes"]) for row in rows)
    print(f"{'파일':<18} {'길이':>7} {'평균':>8} {'최대':>8} {'용량':>9}")
    for row in rows:
        cut: Cut = row["cut"]  # type: ignore[assignment]
        print(
            f"{cut.out:<18} {row['duration']:>6.2f}s "
            f"{row['mean_db']:>7.1f}dB {row['max_db']:>7.1f}dB "
            f"{int(row['bytes']) / 1024:>7.1f}KB"
        )
    print(f"합계 {total / 1024:.1f} KB")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
