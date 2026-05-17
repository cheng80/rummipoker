export const locales = ['ko', 'en'] as const;
export type Locale = (typeof locales)[number];

export type Slide = {
  id: string;
  eyebrow: Record<Locale, string>;
  headline: Record<Locale, string>;
  body: Record<Locale, string>;
  screenshot: Record<Locale, string>;
  align: 'left' | 'right';
  tone: 'hero' | 'battle' | 'growth' | 'market' | 'boss' | 'settlement';
};

export const slides: Slide[] = [
  {
    id: '01-title',
    eyebrow: { ko: 'Rummi Poker', en: 'Rummi Poker' },
    headline: {
      ko: '타일로 만드는\n포커 런',
      en: 'A poker run\nbuilt with tiles',
    },
    body: {
      ko: '숫자 타일을 놓고 매 런 다른 성장 루트를 찾아보세요.',
      en: 'Place number tiles and find a new growth path every run.',
    },
    screenshot: {
      ko: '/screenshots/ko/01-title.png',
      en: '/screenshots/en/01-title.png',
    },
    align: 'left',
    tone: 'hero',
  },
  {
    id: '02-battle-grid',
    eyebrow: { ko: 'Battle Grid', en: 'Battle Grid' },
    headline: {
      ko: '12개 라인을\n한 번에 계산',
      en: 'Score across\n12 board lines',
    },
    body: {
      ko: '한 줄이 아니라 보드 전체를 보며 큰 정산 타이밍을 만듭니다.',
      en: 'Plan the whole board, not just one line, before you cash in.',
    },
    screenshot: {
      ko: '/screenshots/ko/02-battle-grid.png',
      en: '/screenshots/en/02-battle-grid.png',
    },
    align: 'right',
    tone: 'battle',
  },
  {
    id: '03-run-growth',
    eyebrow: { ko: 'Run Growth', en: 'Run Growth' },
    headline: {
      ko: '완성한 조합이\n런 안에서 성장',
      en: 'Completed hands\ngrow the run',
    },
    body: {
      ko: '자주 완성한 족보가 다음 전투의 점수 기반이 됩니다.',
      en: 'The hands you complete become stronger inside the same run.',
    },
    screenshot: {
      ko: '/screenshots/ko/03-run-growth.png',
      en: '/screenshots/en/03-run-growth.png',
    },
    align: 'left',
    tone: 'growth',
  },
  {
    id: '04-market-build',
    eyebrow: { ko: 'Market', en: 'Market' },
    headline: {
      ko: 'Jester와 Item으로\n매번 다른 빌드',
      en: 'Build around\nJesters and Items',
    },
    body: {
      ko: '상점에서 보유 영역을 채우고 다음 전투의 해법을 바꿉니다.',
      en: 'Fill your slots in the Market and reshape the next battle.',
    },
    screenshot: {
      ko: '/screenshots/ko/04-market-build.png',
      en: '/screenshots/en/04-market-build.png',
    },
    align: 'right',
    tone: 'market',
  },
  {
    id: '05-boss-rule',
    eyebrow: { ko: 'Boss Rule', en: 'Boss Rule' },
    headline: {
      ko: '보스 제약에\n배치를 바꾸세요',
      en: 'Adapt your board\nto boss rules',
    },
    body: {
      ko: '같은 타일도 보스 규칙에 따라 전혀 다른 선택이 됩니다.',
      en: 'The same tiles ask for different plans when boss rules change.',
    },
    screenshot: {
      ko: '/screenshots/ko/05-boss-rule.png',
      en: '/screenshots/en/05-boss-rule.png',
    },
    align: 'left',
    tone: 'boss',
  },
  {
    id: '06-cash-out',
    eyebrow: { ko: 'Cash Out', en: 'Cash Out' },
    headline: {
      ko: '정산하고\n더 깊이 도전',
      en: 'Cash out,\nthen push deeper',
    },
    body: {
      ko: '보상을 챙기고 다음 스테이션, 또는 끝없는 도전으로 이어갑니다.',
      en: 'Claim rewards, enter the next station, or keep pushing deeper.',
    },
    screenshot: {
      ko: '/screenshots/ko/06-cash-out.png',
      en: '/screenshots/en/06-cash-out.png',
    },
    align: 'right',
    tone: 'settlement',
  },
];
