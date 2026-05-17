'use client';

import { toPng } from 'html-to-image';
import { useMemo, useRef, useState } from 'react';
import { locales, slides, type Locale, type Slide } from '../data/slides';

const exportWidth = 1290;
const exportHeight = 2796;

const toneLabels: Record<Slide['tone'], string> = {
  hero: 'Start',
  battle: 'Score',
  growth: 'Grow',
  market: 'Build',
  boss: 'Adapt',
  settlement: 'Endless',
};

export default function ScreenshotsPage() {
  const [locale, setLocale] = useState<Locale>('ko');
  const [selectedId, setSelectedId] = useState(slides[0].id);
  const selectedSlide = useMemo(
    () => slides.find((slide) => slide.id === selectedId) ?? slides[0],
    [selectedId],
  );
  const nodeRef = useRef<HTMLDivElement>(null);

  async function exportCurrent() {
    if (!nodeRef.current) return;
    const dataUrl = await toPng(nodeRef.current, {
      pixelRatio: 1,
      cacheBust: true,
      canvasWidth: exportWidth,
      canvasHeight: exportHeight,
      width: exportWidth,
      height: exportHeight,
      backgroundColor: '#0B1110',
    });
    const link = document.createElement('a');
    link.href = dataUrl;
    link.download = `${selectedSlide.id}-${locale}.png`;
    link.click();
  }

  return (
    <main>
      <section className="stageWrap">
        <ScreenshotCanvas
          canvasRef={nodeRef}
          slide={selectedSlide}
          locale={locale}
        />
      </section>

      <section className="toolbar" aria-label="Screenshot controls">
        <div className="toolbarGroup">
          <label>
            Locale
            <select
              value={locale}
              onChange={(event) => setLocale(event.target.value as Locale)}
            >
              {locales.map((entry) => (
                <option key={entry} value={entry}>
                  {entry.toUpperCase()}
                </option>
              ))}
            </select>
          </label>
          <label>
            Slide
            <select
              value={selectedId}
              onChange={(event) => setSelectedId(event.target.value)}
            >
              {slides.map((slide) => (
                <option key={slide.id} value={slide.id}>
                  {slide.id}
                </option>
              ))}
            </select>
          </label>
        </div>
        <button type="button" onClick={exportCurrent}>
          Export PNG
        </button>
      </section>

      <section className="previewRail">
        {slides.map((slide) => (
          <button
            key={slide.id}
            type="button"
            className={slide.id === selectedId ? 'thumb active' : 'thumb'}
            onClick={() => setSelectedId(slide.id)}
          >
            <span>{slide.id.slice(0, 2)}</span>
            {toneLabels[slide.tone]}
          </button>
        ))}
      </section>
    </main>
  );
}

function ScreenshotCanvas({
  slide,
  locale,
  canvasRef,
}: {
  slide: Slide;
  locale: Locale;
  canvasRef: React.RefObject<HTMLDivElement | null>;
}) {
  const lines = slide.headline[locale].split('\n');
  return (
    <div
      ref={canvasRef}
      className={`canvas tone-${slide.tone} align-${slide.align}`}
    >
      <div className="texture" />
      <div className="brandRow">
        <img src="/app-icon.png" alt="" />
        <div>
          <strong>Rummi Poker</strong>
          <span>{slide.eyebrow[locale]}</span>
        </div>
      </div>

      <div className="copyBlock">
        <p className="eyebrow">{slide.eyebrow[locale]}</p>
        <h1>
          {lines.map((line) => (
            <span key={line}>{line}</span>
          ))}
        </h1>
        <p className="body">{slide.body[locale]}</p>
      </div>

      <div className="phoneCluster" aria-label={`${slide.id} app screenshot`}>
        <div className="phoneShadow" />
        <div className="phoneFrame">
          <img className="phoneScreen" src={slide.screenshot[locale]} alt="" />
          <div className="phoneGlare" />
        </div>
      </div>
    </div>
  );
}
