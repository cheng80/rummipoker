#!/usr/bin/env python3
"""
설정 화면의 언어 이름(日本語·简体中文·繁體中文)에 쓰이는 글자만 담은 서브셋 폰트를 만든다.

번들 폰트 NEXON Lv2 Gothic 에는 가나와 한자 글리프가 없다. 그래서 웹(CanvasKit) 빌드는
빠진 글자를 그릴 때마다 Google 서버에서 Noto fallback 폰트를 내려받는다. 내려받기 전에는
빈 네모로 보이고, 오프라인이나 Google Fonts 가 막힌 환경에서는 계속 네모로 남는다.
필요한 글자만 담은 수십 KB 짜리 서브셋을 함께 번들해 그 의존을 없앤다.

원본 폰트는 저장소에 두지 않는다. OFL 라이선스의 Noto Sans CJK 를 따로 내려받아 경로로 넘긴다.
  curl -L -o /tmp/NotoSansCJKjp-Regular.otf \
    https://github.com/notofonts/noto-cjk/raw/main/Sans/OTF/Japanese/NotoSansCJKjp-Regular.otf

사전 요건: fonttools. 저장소 밖 가상환경에 설치해 쓴다.
  python3 -m venv /tmp/fontvenv && /tmp/fontvenv/bin/pip install fonttools

예시:
  /tmp/fontvenv/bin/python tools/build_lang_name_font_subset.py /tmp/NotoSansCJKjp-Regular.otf
  /tmp/fontvenv/bin/python tools/build_lang_name_font_subset.py /tmp/NotoSansCJKjp-Regular.otf --check-only
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
TRANSLATIONS_DIR = REPO_ROOT / "assets" / "translations"
OUTPUT_PATH = REPO_ROOT / "assets" / "fonts" / "NotoSansCjkLangNames-Regular.otf"
# 번들 폰트에 없는 글자가 들어가는 번역 키. 언어 이름 목록은 lib/views/setting_view.dart 의 _LanguageSection 과 같다.
LABEL_KEYS = ("langJa", "langZhCN", "langZhTW")
BUNDLED_FONT_PATH = REPO_ROOT / "assets" / "fonts" / "NEXON Lv2 Gothic.ttf"


def collect_required_chars() -> set[str]:
    """언어 이름에 쓰이는 글자 중 번들 폰트가 덮지 못하는 것만 모은다."""
    bundled = cmap_of(BUNDLED_FONT_PATH)
    chars: set[str] = set()
    for path in sorted(TRANSLATIONS_DIR.glob("*.json")):
        data = json.loads(path.read_text(encoding="utf-8"))
        for key in LABEL_KEYS:
            value = data.get(key)
            if not value:
                raise SystemExit(f"번역 키가 비어 있다: {path.name} / {key}")
            chars.update(ch for ch in value if ord(ch) not in bundled)
    if not chars:
        raise SystemExit("서브셋에 넣을 글자를 찾지 못했다.")
    return chars


def cmap_of(font_path: Path) -> set[int]:
    from fontTools.ttLib import TTFont

    with TTFont(str(font_path), lazy=True) as font:
        return set(font.getBestCmap().keys())


def verify(font_path: Path, chars: set[str]) -> None:
    covered = cmap_of(font_path)
    missing = sorted(ch for ch in chars if ord(ch) not in covered)
    if missing:
        raise SystemExit(
            f"{font_path.name} 에 빠진 글자가 있다: {''.join(missing)} "
            f"({', '.join('U+%04X' % ord(ch) for ch in missing)})"
        )
    print(f"확인: {font_path.name} 가 필요한 글자 {len(chars)}개를 모두 담았다.")


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

    chars = collect_required_chars()
    print(f"필요한 글자 {len(chars)}개: {''.join(sorted(chars))}")

    if args.check_only:
        if not OUTPUT_PATH.exists():
            raise SystemExit(f"서브셋이 없다: {OUTPUT_PATH}")
        verify(OUTPUT_PATH, chars)
        return 0

    if args.source is None:
        parser.error("원본 폰트 경로가 필요하다 (--check-only 가 아니면).")
    if not args.source.exists():
        raise SystemExit(f"원본 폰트를 찾을 수 없다: {args.source}")

    verify(args.source, chars)
    build(args.source, chars)
    verify(OUTPUT_PATH, chars)
    return 0


if __name__ == "__main__":
    sys.exit(main())
