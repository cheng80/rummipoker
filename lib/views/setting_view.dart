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
import 'game/widgets/game_ui_palette.dart';

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
          border: Border.all(
            color: GameUiPalette.marketFrameBorder.withValues(alpha: 0.55),
            width: 1.2,
          ),
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
                        style: const TextStyle(
                          fontFamily: AssetPaths.fontNexonLv2Gothic,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: GameUiPalette.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        SoundManager.playSfx(AssetPaths.sfxBtnSnd);
                        context.pop();
                      },
                      icon: const Icon(Icons.close_rounded),
                      color: GameUiPalette.textPrimary,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: GameUiPalette.ink.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: GameUiPalette.textPrimary.withValues(
                          alpha: 0.10,
                        ),
                      ),
                    ),
                    child: Material(
                      color: GameUiPalette.transparent,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(8, 10, 8, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _SectionTitle(
                              icon: Icons.phone_android,
                              title: context.tr('sectionScreen'),
                            ),
                            _KeepScreenOnTile(
                              label: context.tr('keepScreenOn'),
                            ),
                            _LanguageSection(currentLocale: context.locale),
                            Divider(
                              color: GameUiPalette.textPrimary.withValues(
                                alpha: 0.18,
                              ),
                              height: 1,
                            ),
                            _SectionTitle(
                              icon: Icons.volume_up,
                              title: context.tr('sectionSound'),
                            ),
                            _BgmVolumeTile(label: context.tr('bgmVolume')),
                            _BgmMuteTile(label: context.tr('bgm')),
                            _SfxVolumeTile(label: context.tr('sfxVolume')),
                            _SfxMuteTile(label: context.tr('sfx')),
                            Divider(
                              color: GameUiPalette.textPrimary.withValues(
                                alpha: 0.18,
                              ),
                              height: 1,
                            ),
                            _SectionTitle(
                              icon: Icons.auto_awesome,
                              title: context.tr('sectionEffects'),
                            ),
                            const _EffectSettingsSection(),
                            if (InAppReviewService.hasStoreListingId) ...[
                              Divider(
                                color: GameUiPalette.textPrimary.withValues(
                                  alpha: 0.18,
                                ),
                                height: 1,
                              ),
                              _SectionTitle(
                                icon: Icons.star,
                                title: context.tr('rateApp'),
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.star_border,
                                  color: GameUiPalette.actionGoldBright,
                                ),
                                title: Text(
                                  context.tr('rateApp'),
                                  style: const TextStyle(
                                    fontFamily: AssetPaths.fontNexonLv2Gothic,
                                    fontSize: 16,
                                  ),
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
    return _MuteSwitch(
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
    return _MuteSwitch(
      label: label,
      value: value,
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
    return _MuteSwitch(
      label: label,
      value: value,
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
          label: context.tr('fxIntensity'),
          values: FxIntensity.values,
          selected: settings.fxIntensity,
          labelOf: (value) => context.tr(_intensityLabels[value]!),
          onSelected: notifier.setFxIntensity,
        ),
        _ChoiceTile<SettlementSpeed>(
          key: const ValueKey('setting-settlement-speed'),
          label: context.tr('settlementSpeed'),
          values: SettlementSpeed.values,
          selected: settings.settlementSpeed,
          labelOf: (value) => value == SettlementSpeed.instant
              ? context.tr('settlementSpeedInstant')
              : '${value.multiplier.toInt()}x',
          onSelected: notifier.setSettlementSpeed,
        ),
        _PlainSwitch(
          key: const ValueKey('setting-screen-shake'),
          icon: Icons.vibration,
          label: context.tr('screenShake'),
          value: settings.screenShakeEnabled,
          onChanged: notifier.setScreenShakeEnabled,
        ),
        _PlainSwitch(
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
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              context.tr('reduceMotionActive'),
              style: const TextStyle(
                fontFamily: AssetPaths.fontNexonLv2Gothic,
                fontSize: 13,
                color: GameUiPalette.disabledControl,
              ),
            ),
          ),
      ],
    );
  }
}

class _ChoiceTile<T> extends StatelessWidget {
  const _ChoiceTile({
    super.key,
    required this.label,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  final String label;
  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        label,
        style: const TextStyle(
          fontFamily: AssetPaths.fontNexonLv2Gothic,
          fontSize: 16,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final value in values)
              ChoiceChip(
                label: Text(
                  labelOf(value),
                  style: const TextStyle(
                    fontFamily: AssetPaths.fontNexonLv2Gothic,
                    fontSize: 14,
                  ),
                ),
                selected: value == selected,
                selectedColor: GameUiPalette.actionGoldBright.withValues(
                  alpha: 0.32,
                ),
                onSelected: (_) {
                  GameFeedback.play(GameCue.choiceSelect);
                  onSelected(value);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _PlainSwitch extends StatelessWidget {
  const _PlainSwitch({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(
        icon,
        color: value ? null : GameUiPalette.disabledControl,
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontFamily: AssetPaths.fontNexonLv2Gothic,
          fontSize: 16,
        ),
      ),
      value: value,
      onChanged: onChanged,
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
        for (final option in _options)
          ListTile(
            leading: Icon(
              _sameLocale(currentLocale, option.locale)
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: _sameLocale(currentLocale, option.locale)
                  ? GameUiPalette.actionGoldBright
                  : GameUiPalette.disabledControl,
            ),
            title: Text(
              context.tr(option.labelKey),
              style: const TextStyle(
                fontFamily: AssetPaths.fontNexonLv2Gothic,
                fontSize: 16,
              ),
            ),
            onTap: () async {
              GameFeedback.play(GameCue.choiceSelect);
              await context.setLocale(option.locale);
            },
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.icon});
  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: GameUiPalette.disabledControl),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: const TextStyle(
              fontFamily: AssetPaths.fontNexonLv2Gothic,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: GameUiPalette.disabledControl,
            ),
          ),
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
    return ListTile(
      title: Text(
        label,
        style: const TextStyle(
          fontFamily: AssetPaths.fontNexonLv2Gothic,
          fontSize: 16,
        ),
      ),
      subtitle: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 12,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
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

class _MuteSwitch extends StatelessWidget {
  const _MuteSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(
        value ? Icons.volume_off : Icons.volume_up,
        color: value ? GameUiPalette.disabledControl : null,
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontFamily: AssetPaths.fontNexonLv2Gothic,
          fontSize: 16,
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}
