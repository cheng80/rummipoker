// Runs the original JavaScript semantic-wrap library to produce reference data
// for the Dart port in lib/utils/semantic_wrap/.
//
// Two outputs:
//   1. test/fixtures/semantic_wrap_breaks.json - reference break offsets used by
//      test/utils/semantic_wrap_fixture_test.dart to check porting fidelity.
//   2. lib/utils/semantic_wrap/ko_title_model.dart - the Korean BudouX weights
//      transcribed into Dart. Regenerating keeps the weights byte-identical to
//      the upstream package instead of hand-copying 3 KB of numbers.
//
// The library is not vendored into this repository, so the caller points at a
// node_modules directory that has @semantic-wrap/core and @semantic-wrap/ko
// installed:
//
//   node tools/semantic_wrap/generate_semantic_wrap_fixture.mjs --lib <node_modules dir>
//
// Every width is measured with a fixed per-code-unit width so the reference data
// does not depend on a font. The Dart test measures the same way.

import { writeFileSync, mkdirSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { pathToFileURL } from "node:url";

const CHAR_WIDTH = 10;
const FIXTURE_PATH = "test/fixtures/semantic_wrap_breaks.json";
const MODEL_PATH = "lib/utils/semantic_wrap/ko_title_model.dart";

// Korean sample sentences. The first block is taken from this game's own text so
// the fixture covers the strings the widget actually has to lay out.
const SENTENCES = [
  // Boss rule text (lib/logic/rummi_poker_grid/boss_modifier.dart)
  "빨간 타일이 포함된 점수 라인은 35% 감소합니다.",
  "가로줄 점수가 25% 감소합니다.",
  "파란 타일이 포함된 점수 라인은 40% 감소합니다.",
  "검은 타일이 포함된 점수 라인은 40% 감소합니다.",
  "노란 타일이 포함된 점수 라인은 40% 감소합니다.",
  "세로줄 점수가 25% 감소합니다.",
  "대각선 점수가 25% 감소합니다.",
  "11~13 타일이 포함된 점수 라인은 35% 감소합니다.",
  "모든 점수 라인이 20% 감소합니다.",
  "첫 확정 점수 라인은 30% 감소합니다.",
  "오른쪽 끝 5칸에는 타일을 놓을 수 없습니다.",
  "맨 위 5칸에는 타일을 놓을 수 없습니다.",
  "이전 확정에서 사용한 족보를 다시 확정하면 점수 라인이 20% 감소합니다.",
  // Jester effect text (assets/translations/data/ko/jesters.json)
  "점수 라인의 노란 타일마다 점수 +15%.",
  "원 페어 이상 점수 라인을 확정하면 점수 +40%.",
  "스트레이트 이상 점수 라인을 확정하면 칩 +100.",
  "3장 이하 점수 라인을 확정하면 점수 +100%.",
  "빈 Jester 슬롯마다 1배 보너스.",
  "확정할 때마다 점수 +5%. 버릴 때마다 점수 -5%.",
  "점수 +100%. Station을 마칠 때마다 점수 -20%.",
  "이번 런에서 같은 족보를 확정한 횟수마다 점수 +5%.",
  "11~13 타일 없이 확정할 때마다 점수 +5%.",
  "점수 라인의 1, 2, 3, 5, 8 타일마다 점수 +40%.",
  "정산 시 남은 버림마다 골드 +2.",
  // Dialog titles and guidance (assets/translations/ko.json)
  "이번 런의 족보 레벨과 칩 성장을 봅니다.",
  "전투 기본 조작 안내를 다시 봅니다.",
  "손패 타일을 빈칸에 놓아 가로, 세로, 대각선 라인을 만듭니다.",
  "현재 선택으로 확정될 라인과 점수 변화를 확인합니다.",
  "확정, 선택 해제, 이동, 버림은 라인을 만들 때만 사용합니다.",
  "타일을 사고 Jester를 채운 다음 다음 Station으로 넘어갑니다.",
  // Plain Korean sentences that exercise ordinary phrase boundaries
  "게임을 저장하지 않고 타이틀 화면으로 돌아갑니다.",
  "현재 진행 중인 런을 포기하고 처음부터 다시 시작합니다.",
  "선택한 타일을 버리고 새 타일을 손패로 가져옵니다.",
  "아직 사용하지 않은 아이템이 보관함에 남아 있습니다.",
  "이 설정은 다음 런부터 적용되며 지금 진행 중인 런에는 영향을 주지 않습니다.",
  "화면 흔들림과 진동 세기는 설정에서 따로 조절할 수 있습니다.",
];

function parseArgs(argv) {
  const args = { lib: undefined };
  for (let index = 0; index < argv.length; index += 1) {
    if (argv[index] === "--lib") {
      args.lib = argv[index + 1];
      index += 1;
    } else if (argv[index] === "--help") {
      args.help = true;
    } else {
      throw new Error(`Unknown argument: ${argv[index]}`);
    }
  }
  return args;
}

const args = parseArgs(process.argv.slice(2));
if (args.help || !args.lib) {
  console.log(
    [
      "Usage: node tools/semantic_wrap/generate_semantic_wrap_fixture.mjs --lib <node_modules dir>",
      "",
      "  --lib   Directory that contains @semantic-wrap/core and @semantic-wrap/ko.",
      "          Install them with: npm i @semantic-wrap/core@0.4.0 @semantic-wrap/ko@0.4.0",
      "",
      `Writes ${FIXTURE_PATH} and ${MODEL_PATH}.`,
      "Run `dart format` on the Dart output afterwards; the committed file is formatted.",
    ].join("\n"),
  );
  process.exit(args.help ? 0 : 64);
}

const libRoot = resolve(args.lib);
const core = await import(
  pathToFileURL(`${libRoot}/@semantic-wrap/core/dist/index.js`).href
);
const koModels = await import(
  pathToFileURL(`${libRoot}/@semantic-wrap/ko/dist/models.js`).href
);

// @semantic-wrap/ko imports @semantic-wrap/core by package name, which only
// resolves inside that node_modules tree. Rebuilding the preset here from the
// raw weights avoids depending on the caller's resolution setup and keeps the
// penalties visible next to the Dart port that mirrors them.
const KO_LEVELS = [
  { name: "coarse", weights: koModels.koreanTitleCoarseModel, penalty: 0 },
  { name: "medium", weights: koModels.koreanTitleMediumModel, penalty: 0.35 },
  { name: "fine", weights: koModels.koreanTitleFineModel, penalty: 0.7 },
];
const koTitleModel = core.definePhraseModel({
  boundaryMode: "spaces",
  levels: KO_LEVELS.map((level) => ({
    name: level.name,
    predictor: core.createBudouxPredictor(level.weights),
    penalty: level.penalty,
  })),
  fallbackPenalty: 1,
});

const measureText = (text) => text.length * CHAR_WIDTH;

function widthsFor(text) {
  const full = text.length * CHAR_WIDTH;
  // Three widths per sentence: roughly two, three and four rendered lines.
  return [Math.round(full / 2), Math.round(full / 3), Math.round(full / 4)];
}

const cases = [];
for (const text of SENTENCES) {
  for (const maxWidth of widthsFor(text)) {
    const selection = core.selectLineBreaks({
      text,
      model: koTitleModel,
      maxWidth,
      measureText,
    });
    cases.push({
      text,
      maxWidth,
      breaks: [...selection.breaks],
      lines: [...selection.lines],
      applied: selection.applied,
      overflow: selection.overflow,
    });
  }
}

const fixture = {
  generator: "tools/semantic_wrap/generate_semantic_wrap_fixture.mjs",
  source: "@semantic-wrap/core and @semantic-wrap/ko, version 0.4.0, Apache-2.0",
  charWidth: CHAR_WIDTH,
  cases,
};
mkdirSync(dirname(FIXTURE_PATH), { recursive: true });
writeFileSync(FIXTURE_PATH, `${JSON.stringify(fixture, null, 2)}\n`);
console.log(`WROTE: ${FIXTURE_PATH} (${cases.length} cases)`);

function dartWeights(weights) {
  const groups = Object.entries(weights).map(([group, values]) => {
    const entries = Object.entries(values)
      .map(([feature, weight]) => `    ${JSON.stringify(feature)}: ${weight},`)
      .join("\n");
    return `  ${JSON.stringify(group)}: <String, int>{\n${entries}\n  },`;
  });
  return `<String, Map<String, int>>{\n${groups.join("\n")}\n}`;
}

const modelSource = `// GENERATED FILE - DO NOT EDIT.
// Regenerate with:
//   node tools/semantic_wrap/generate_semantic_wrap_fixture.mjs --lib <node_modules dir>
//   dart format lib/utils/semantic_wrap/ko_title_model.dart
//
// BudouX-format phrase boundary weights for Korean display text, copied from
// the @semantic-wrap/ko package, version 0.4.0.
// Copyright 2026 Woohyun Park. Licensed under the Apache License, Version 2.0.
// See third_party/semantic_wrap/ for the license and notice texts.
//
// The package documents these weights as an experimental model trained on 100
// Korean article titles. It never predicts a boundary inside a Korean word.

${KO_LEVELS.map(
  (level) =>
    `/// Level "${level.name}", penalty ${level.penalty}.\nconst Map<String, Map<String, int>> korean${level.name[0].toUpperCase()}${level.name.slice(1)}TitleWeights = ${dartWeights(level.weights)};`,
).join("\n\n")}
`;
mkdirSync(dirname(MODEL_PATH), { recursive: true });
writeFileSync(MODEL_PATH, modelSource);
console.log(`WROTE: ${MODEL_PATH} (run \`dart format\` on it)`);
