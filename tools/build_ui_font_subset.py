#!/usr/bin/env python3
"""
UI에 쓰이는 글자 중 번들 폰트가 덮지 못하는 것만 담은 서브셋 폰트를 만든다.

번들 폰트 NEXON Lv2 Gothic 에는 한자 글리프가 없다(가나는 있다). 그래서 웹(CanvasKit) 빌드는
빠진 글자를 그릴 때마다 Google 서버에서 Noto fallback 폰트를 내려받는다. 내려받기 전에는
빈 네모로 보이고, 오프라인이나 Google Fonts 가 막힌 환경에서는 계속 네모로 남는다.
5개 locale 의 표시 문자열에 실제로 쓰인 글자만 모은 서브셋을 함께 번들해 그 의존을 없앤다.

글자 출처는 assets/translations/<locale>.json 과 assets/translations/data/<locale>/*.json 이다.
lib/ 에는 화면에 그리는 한자·가나 문자열이 없다(주석 제외).

원본 폰트는 저장소에 두지 않는다. OFL 라이선스의 Noto Sans CJK 를 따로 내려받아 경로로 넘긴다.
  curl -L -o /tmp/NotoSansCJKjp-Regular.otf \
    https://github.com/notofonts/noto-cjk/raw/main/Sans/OTF/Japanese/NotoSansCJKjp-Regular.otf

사전 요건: fonttools. 저장소 밖 가상환경에 설치해 쓴다.
  python3 -m venv /tmp/fontvenv && /tmp/fontvenv/bin/pip install fonttools

예시:
  /tmp/fontvenv/bin/python tools/build_ui_font_subset.py /tmp/NotoSansCJKjp-Regular.otf
  /tmp/fontvenv/bin/python tools/build_ui_font_subset.py /tmp/NotoSansCJKjp-Regular.otf --check-only
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
TRANSLATIONS_DIR = REPO_ROOT / "assets" / "translations"
BUNDLED_FONT_PATH = REPO_ROOT / "assets" / "fonts" / "NEXON Lv2 Gothic.ttf"
OUTPUT_PATH = REPO_ROOT / "assets" / "fonts" / "NotoSansCjkUiSubset-Regular.otf"
# 서브셋이 낡았는지 Dart 테스트가 검사할 수 있게 글자 목록을 함께 내보낸다.
# 앱 번들에 들어가지 않도록 assets/ 밖에 둔다.
COVERAGE_PATH = REPO_ROOT / "tools" / "ui_font_subset_coverage.txt"
COVERAGE_HEADER = (
    "# tools/build_ui_font_subset.py 가 생성한다. 직접 편집하지 않는다.\n"
    "# 번역 파일에 쓰인 글자를 두 목록으로 나눠 적는다.\n"
    "# test/resources/ui_font_subset_test.dart 가 두 목록의 합집합으로 낡음을 검사한다.\n"
)


def iter_strings(node: object):
    if isinstance(node, str):
        yield node
    elif isinstance(node, dict):
        for value in node.values():
            yield from iter_strings(value)
    elif isinstance(node, list):
        for value in node:
            yield from iter_strings(value)


def translation_files() -> list[Path]:
    files = sorted(TRANSLATIONS_DIR.glob("*.json"))
    files += sorted(TRANSLATIONS_DIR.glob("data/*/*.json"))
    if not files:
        raise SystemExit(f"번역 파일을 찾지 못했다: {TRANSLATIONS_DIR}")
    return files


def collect_ui_chars() -> set[str]:
    chars: set[str] = set()
    for path in translation_files():
        data = json.loads(path.read_text(encoding="utf-8"))
        for text in iter_strings(data):
            # 줄바꿈·공백 같은 제어 문자는 글리프가 필요 없다.
            chars.update(ch for ch in text if not ch.isspace())
    return chars


def cmap_of(font_path: Path) -> set[int]:
    from fontTools.ttLib import TTFont

    with TTFont(str(font_path), lazy=True) as font:
        return set(font.getBestCmap().keys())


def split_chars() -> tuple[set[str], set[str]]:
    """UI 글자를 (번들 폰트가 덮는 것, 서브셋이 덮어야 하는 것)으로 나눈다."""
    bundled_cmap = cmap_of(BUNDLED_FONT_PATH)
    ui_chars = collect_ui_chars()
    covered = {ch for ch in ui_chars if ord(ch) in bundled_cmap}
    missing = ui_chars - covered
    if not missing:
        raise SystemExit("서브셋에 넣을 글자를 찾지 못했다.")
    return covered, missing


def verify(font_path: Path, chars: set[str]) -> None:
    covered = cmap_of(font_path)
    missing = sorted(ch for ch in chars if ord(ch) not in covered)
    if missing:
        raise SystemExit(
            f"{font_path.name} 에 빠진 글자가 있다({len(missing)}개): {''.join(missing)}"
        )
    print(f"확인: {font_path.name} 가 필요한 글자 {len(chars)}개를 모두 담았다.")


def write_coverage(bundled: set[str], subset: set[str]) -> None:
    lines = [
        COVERAGE_HEADER,
        "# subset: 서브셋 폰트에 담은 글자\n",
        "".join(sorted(subset)) + "\n",
        "# bundled: 번들 폰트(NEXON Lv2 Gothic)가 덮는 글자 중 번역 파일에 쓰인 것\n",
        "".join(sorted(bundled)) + "\n",
    ]
    COVERAGE_PATH.write_text("".join(lines), encoding="utf-8")
    print(f"생성: {COVERAGE_PATH.relative_to(REPO_ROOT)} (subset {len(subset)}자, bundled {len(bundled)}자)")


def build(source: Path, chars: set[str]) -> None:
    from fontTools import subset

    options = subset.Options()
    options.layout_features = []
    options.name_IDs = ["*"]
    options.name_legacy = True
    options.notdef_outline = True
    options.recalc_bounds = True
    options.drop_tables += ["DSIG"]

    font = subset.load_font(str(source), options)
    subsetter = subset.Subsetter(options=options)
    subsetter.populate(text="".join(sorted(chars)))
    subsetter.subset(font)
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    subset.save_font(font, str(OUTPUT_PATH), options)
    font.close()
    size_kb = OUTPUT_PATH.stat().st_size / 1024
    print(f"생성: {OUTPUT_PATH.relative_to(REPO_ROOT)} ({size_kb:.1f} KB)")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("source", nargs="?", type=Path, help="원본 Noto Sans CJK 폰트 경로")
    parser.add_argument("--check-only", action="store_true", help="이미 만들어진 서브셋의 글자 포함 여부만 검사한다")
    args = parser.parse_args()

    bundled, subset_chars = split_chars()
    print(f"번역 파일의 글자 {len(bundled) + len(subset_chars)}개 중 서브셋이 덮어야 하는 글자 {len(subset_chars)}개")

    if args.check_only:
        if not OUTPUT_PATH.exists():
            raise SystemExit(f"서브셋이 없다: {OUTPUT_PATH}")
        verify(OUTPUT_PATH, subset_chars)
        return 0

    if args.source is None:
        parser.error("원본 폰트 경로가 필요하다 (--check-only 가 아니면).")
    if not args.source.exists():
        raise SystemExit(f"원본 폰트를 찾을 수 없다: {args.source}")

    verify(args.source, subset_chars)
    build(args.source, subset_chars)
    verify(OUTPUT_PATH, subset_chars)
    write_coverage(bundled, subset_chars)
    return 0


if __name__ == "__main__":
    sys.exit(main())
