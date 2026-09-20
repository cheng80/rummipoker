import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/features/settings/settings_notifier.dart';
import '../resources/asset_paths.dart';
import '../resources/game_haptics.dart';
import '../resources/sound_manager.dart';
import '../services/game_settings.dart';
import '../services/in_app_review_service.dart';
import '../utils/common_ui.dart';
import '../widgets/fx/motion_policy.dart';
import '../widgets/phone_frame_scaffold.dart';
import 'game/game_feedback_cues.dart';
import 'game/game_presentation_timings.dart';
import 'game/widgets/game_ui_palette.dart';
import 'home_entry_widgets.dart';

/// 설정 화면. 볼륨, 음소거, 화면 꺼짐 방지 설정.
class SettingView extends StatelessWidget {
  const SettingView({super.key});

  @override
  Widget build(BuildContext context) {
    return PhoneFrameScaffold(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              GameUiPalette.settingGradientStart,
              GameUiPalette.settingGradientMid,
              GameUiPalette.settingGradientEnd,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: GameUiPalette.ink.withValues(alpha: 0.36),
              blurRadius: 28,
              spreadRadius: 4,
            ),
          ],
          border: Border.all(color: MenuSurface.border(alpha: 0.5), width: 1.2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr('settings'),
                        style: TextStyle(
                          fontFamily: AssetPaths.fontNexonLv2Gothic,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: MenuSurface.goldText.withValues(alpha: 0.96),
                        ),
                      ),
                    ),
                    GameIconButtonChip(
                      icon: Icons.close_rounded,
                      onPressed: () {
                        SoundManager.playSfx(AssetPaths.sfxBtnSnd);
                        context.pop();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Material(
                    color: GameUiPalette.transparent,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(2, 0, 2, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SectionTitle(
                            icon: Icons.phone_android,
                            title: context.tr('sectionScreen'),
                          ),
                          _KeepScreenOnTile(label: context.tr('keepScreenOn')),
                          _LanguageSection(currentLocale: context.locale),
                          _SectionTitle(
                            icon: Icons.volume_up,
                            title: context.tr('sectionSound'),
                          ),
                          _BgmVolumeTile(label: context.tr('bgmVolume')),
                          _BgmMuteTile(label: context.tr('bgm')),
                          _SfxVolumeTile(label: context.tr('sfxVolume')),
                          _SfxMuteTile(label: context.tr('sfx')),
                          _SectionTitle(
                            icon: Icons.auto_awesome,
                            title: context.tr('sectionEffects'),
                          ),
                          const _EffectSettingsSection(),
                          if (InAppReviewService.hasStoreListingId) ...[
                            _SectionTitle(
                              icon: Icons.star,
                              title: context.tr('rateApp'),
                            ),
                            _SettingRow(
                              icon: Icons.star_border,
                              label: context.tr('rateApp'),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: GameUiPalette.actionGoldText,
                              ),
                              onTap: () async {
                                final result =
                                    await InAppReviewService.openStoreListing();
                                if (!context.mounted) return;
                                if (result == false) {
                                  showTopNotice(
                                    context,
                                    context.tr('rateAppAfterRelease'),
                                  );
                                }
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KeepScreenOnTile extends ConsumerWidget {
  const _KeepScreenOnTile({required this.label});

  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(
      settingsNotifierProvider.select((state) => state.keepScreenOn),
    );
    final notifier = ref.read(settingsNotifierProvider.notifier);
    return _ToggleRow(
      icon: value ? Icons.screen_lock_portrait : Icons.stay_current_portrait,
      label: label,
      value: value,
      onChanged: notifier.setKeepScreenOn,
    );
  }
}

class _BgmVolumeTile extends ConsumerWidget {
  const _BgmVolumeTile({required this.label});

  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final volume = ref.watch(
      settingsNotifierProvider.select((state) => state.bgmVolume),
    );
    final muted = ref.watch(
      settingsNotifierProvider.select((state) => state.bgmMuted),
    );
    final notifier = ref.read(settingsNotifierProvider.notifier);
    return _VolumeSlider(
      label: label,
      value: volume,
      enabled: !muted,
      onChanged: notifier.setBgmVolume,
    );
  }
}

class _BgmMuteTile extends ConsumerWidget {
  const _BgmMuteTile({required this.label});

  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(
      settingsNotifierProvider.select((state) => state.bgmMuted),
    );
    final notifier = ref.read(settingsNotifierProvider.notifier);
    return _ToggleRow(
      icon: value ? Icons.volume_off : Icons.volume_up,
      label: label,
      value: value,
      dimmed: value,
      onChanged: notifier.setBgmMuted,
    );
  }
}

class _SfxVolumeTile extends ConsumerWidget {
  const _SfxVolumeTile({required this.label});

  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final volume = ref.watch(
      settingsNotifierProvider.select((state) => state.sfxVolume),
    );
    final muted = ref.watch(
      settingsNotifierProvider.select((state) => state.sfxMuted),
    );
    final notifier = ref.read(settingsNotifierProvider.notifier);
    return _VolumeSlider(
      label: label,
      value: volume,
      enabled: !muted,
      onChanged: notifier.setSfxVolume,
      onChangeEnd: (_) => SoundManager.playSfx(AssetPaths.sfxBtnSnd),
    );
  }
}

class _SfxMuteTile extends ConsumerWidget {
  const _SfxMuteTile({required this.label});

  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(
      settingsNotifierProvider.select((state) => state.sfxMuted),
    );
    final notifier = ref.read(settingsNotifierProvider.notifier);
    return _ToggleRow(
      icon: value ? Icons.volume_off : Icons.volume_up,
      label: label,
      value: value,
      dimmed: value,
      onChanged: notifier.setSfxMuted,
    );
  }
}

/// 연출 강도·정산 속도·흔들림·진동 설정.
class _EffectSettingsSection extends ConsumerWidget {
  const _EffectSettingsSection();

  static const _intensityLabels = <FxIntensity, String>{
    FxIntensity.off: 'fxIntensityOff',
    FxIntensity.normal: 'fxIntensityNormal',
    FxIntensity.strong: 'fxIntensityStrong',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);
    final reduceMotion =
        MediaQuery.of(context).disableAnimations || MotionPolicy.reduceMotion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ChoiceTile<FxIntensity>(
          key: const ValueKey('setting-fx-intensity'),
          chipKeyOf: (value) => ValueKey('setting-fx-intensity-${value.name}'),
          label: context.tr('fxIntensity'),
          values: FxIntensity.values,
          selected: settings.fxIntensity,
          labelOf: (value) => context.tr(_intensityLabels[value]!),
          onSelected: notifier.setFxIntensity,
        ),
        _ChoiceTile<SettlementSpeed>(
          key: const ValueKey('setting-settlement-speed'),
          chipKeyOf: (value) =>
              ValueKey('setting-settlement-speed-${value.name}'),
          label: context.tr('settlementSpeed'),
          values: SettlementSpeed.values,
          selected: settings.settlementSpeed,
          labelOf: (value) => value == SettlementSpeed.instant
              ? context.tr('settlementSpeedInstant')
              : '${value.multiplier.toInt()}x',
          onSelected: notifier.setSettlementSpeed,
        ),
        _ToggleRow(
          key: const ValueKey('setting-screen-shake'),
          icon: Icons.vibration,
          label: context.tr('screenShake'),
          value: settings.screenShakeEnabled,
          onChanged: notifier.setScreenShakeEnabled,
        ),
        _ToggleRow(
          key: const ValueKey('setting-haptics'),
          icon: Icons.touch_app,
          label: context.tr('haptics'),
          value: settings.hapticsEnabled,
          onChanged: (value) {
            notifier.setHapticsEnabled(value);
            if (value) GameHaptics.play(HapticGrade.select);
          },
        ),
        if (reduceMotion)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
            child: Text(
              context.tr('reduceMotionActive'),
              style: TextStyle(
                fontFamily: AssetPaths.fontNexonLv2Gothic,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: GameUiPalette.textPrimary.withValues(alpha: 0.6),
              ),
            ),
          ),
      ],
    );
  }
}

/// 설정 항목 한 줄. 어두운 패널 위 아이콘·라벨·오른쪽 조작부다.
class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.label,
    this.icon,
    this.trailing,
    this.below,
    this.onTap,
    this.dimmed = false,
  });

  final String label;
  final IconData? icon;
  final Widget? trailing;
  final Widget? below;
  final VoidCallback? onTap;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    final trailing = this.trailing;
    final below = this.below;
    final labelColor = GameUiPalette.textPrimary.withValues(
      alpha: dimmed ? 0.52 : 0.94,
    );
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (label.isNotEmpty || trailing != null)
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 18,
                    color: dimmed
                        ? GameUiPalette.disabledControl
                        : MenuSurface.goldText.withValues(alpha: 0.86),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: AssetPaths.fontNexonLv2Gothic,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: labelColor,
                    ),
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 10), trailing],
              ],
            ),
          if (below != null) ...[
            if (label.isNotEmpty || trailing != null) const SizedBox(height: 6),
            below,
          ],
        ],
      ),
    );
    final panel = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: MenuSurface.panelFill(alpha: 0.56),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: MenuSurface.border(alpha: 0.24)),
        ),
        child: content,
      ),
    );
    final onTap = this.onTap;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: onTap == null
          ? panel
          : PressFeedback(
              onTap: onTap,
              haptic: null,
              builder: (context, tap) => Material(
                color: GameUiPalette.transparent,
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                child: InkWell(onTap: tap, child: panel),
              ),
            ),
    );
  }
}

/// 게임 스타일 토글. 줄 전체가 탭 영역이다.
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.dimmed,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  /// 흐리게 보일 조건. 비우면 꺼진 상태를 흐리게 한다.
  final bool? dimmed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: label,
      child: _SettingRow(
        icon: icon,
        label: label,
        dimmed: dimmed ?? !value,
        trailing: _TogglePill(value: value),
        onTap: () {
          GameFeedback.play(GameCue.choiceSelect);
          onChanged(!value);
        },
      ),
    );
  }
}

class _TogglePill extends StatelessWidget {
  const _TogglePill({required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 26,
      child: AnimatedContainer(
        duration: GamePresentationTimings.choiceSelect,
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: value
              ? MenuSurface.gold.withValues(alpha: 0.9)
              : GameUiPalette.ink.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: value
                ? MenuSurface.goldBright
                : GameUiPalette.disabledControl.withValues(alpha: 0.8),
            width: 1.4,
          ),
        ),
        child: AnimatedAlign(
          duration: GamePresentationTimings.choiceSelect,
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: value
                    ? GameUiPalette.textOnGold
                    : GameUiPalette.textPrimary.withValues(alpha: 0.72),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 값이 몇 개뿐인 설정을 게임 칩으로 고른다.
class _ChoiceTile<T> extends StatelessWidget {
  const _ChoiceTile({
    super.key,
    required this.label,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.chipKeyOf,
  });

  final String label;
  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;
  final ValueChanged<T> onSelected;
  final Key Function(T value)? chipKeyOf;

  @override
  Widget build(BuildContext context) {
    return _SettingRow(
      label: label,
      below: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final value in values)
            SettingChoiceChip(
              key: chipKeyOf?.call(value),
              label: labelOf(value),
              selected: value == selected,
              onTap: () {
                GameFeedback.play(GameCue.choiceSelect);
                onSelected(value);
              },
            ),
        ],
      ),
    );
  }
}

/// 설정·언어 선택 칩. 고른 칩은 금색으로 채운다.
class SettingChoiceChip extends StatelessWidget {
  const SettingChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: PressFeedback(
        onTap: onTap,
        haptic: null,
        builder: (context, tap) => Material(
          color: GameUiPalette.transparent,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: tap,
            child: AnimatedContainer(
              duration: GamePresentationTimings.choiceSelect,
              curve: Curves.easeOut,
              constraints: const BoxConstraints(minHeight: 36),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? MenuSurface.gold
                    : MenuSurface.panelFill(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? MenuSurface.goldBright
                      : MenuSurface.border(alpha: 0.3),
                  width: selected ? 1.6 : 1,
                ),
              ),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: AssetPaths.fontNexonLv2Gothic,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: selected
                        ? GameUiPalette.textOnGold
                        : GameUiPalette.textPrimary.withValues(alpha: 0.86),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageSection extends StatelessWidget {
  const _LanguageSection({required this.currentLocale});

  final Locale currentLocale;

  static const _options = <_LanguageOption>[
    _LanguageOption(Locale('ko'), 'langKo'),
    _LanguageOption(Locale('en'), 'langEn'),
    _LanguageOption(Locale('ja'), 'langJa'),
    _LanguageOption(Locale('zh', 'CN'), 'langZhCN'),
    _LanguageOption(Locale('zh', 'TW'), 'langZhTW'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(icon: Icons.language, title: context.tr('language')),
        _SettingRow(
          label: '',
          below: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in _options)
                SettingChoiceChip(
                  key: ValueKey('setting-language-${option.labelKey}'),
                  label: context.tr(option.labelKey),
                  selected: _sameLocale(currentLocale, option.locale),
                  onTap: () async {
                    GameFeedback.play(GameCue.choiceSelect);
                    await context.setLocale(option.locale);
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  bool _sameLocale(Locale a, Locale b) {
    return a.languageCode == b.languageCode && a.countryCode == b.countryCode;
  }
}

class _LanguageOption {
  const _LanguageOption(this.locale, this.labelKey);

  final Locale locale;
  final String labelKey;
}

/// 설정 구획 제목. 타이틀 화면과 같은 제목 + 가는 구분선이다.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.icon});
  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: MenuSurface.goldText.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: TextStyle(
              fontFamily: AssetPaths.fontNexonLv2Gothic,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
              color: MenuSurface.goldText.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: MenuSurface.divider())),
        ],
      ),
    );
  }
}

class _VolumeSlider extends StatelessWidget {
  const _VolumeSlider({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.onChangeEnd,
  });

  final String label;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return _SettingRow(
      label: label,
      dimmed: !enabled,
      trailing: Text(
        '${(value * 100).round()}%',
        style: TextStyle(
          fontFamily: AssetPaths.fontNexonLv2Gothic,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: enabled ? MenuSurface.goldText : GameUiPalette.disabledControl,
        ),
      ),
      below: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 10,
          activeTrackColor: MenuSurface.gold,
          inactiveTrackColor: GameUiPalette.ink.withValues(alpha: 0.42),
          disabledActiveTrackColor: GameUiPalette.disabledControl,
          disabledInactiveTrackColor: GameUiPalette.ink.withValues(alpha: 0.3),
          thumbColor: MenuSurface.goldBright,
          disabledThumbColor: GameUiPalette.disabledControl,
          overlayColor: MenuSurface.gold.withValues(alpha: 0.18),
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
          trackShape: const RoundedRectSliderTrackShape(),
        ),
        child: Slider(
          value: value,
          onChanged: enabled ? onChanged : null,
          onChangeEnd: enabled ? onChangeEnd : null,
        ),
      ),
    );
  }
}
