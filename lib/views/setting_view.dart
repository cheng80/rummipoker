import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../resources/asset_paths.dart';
import '../resources/sound_manager.dart';
import '../services/game_settings.dart';
import '../services/in_app_review_service.dart';

/// 설정 화면. 볼륨, 음소거, 화면 꺼짐 방지 설정.
class SettingView extends StatefulWidget {
  const SettingView({super.key});

  @override
  State<SettingView> createState() => _SettingViewState();
}

class _SettingViewState extends State<SettingView> {
  late double _bgmVolume;
  late double _sfxVolume;
  late bool _bgmMuted;
  late bool _sfxMuted;
  late bool _keepScreenOn;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _bgmVolume = GameSettings.bgmVolume;
      _sfxVolume = GameSettings.sfxVolume;
      _bgmMuted = GameSettings.bgmMuted;
      _sfxMuted = GameSettings.sfxMuted;
      _keepScreenOn = GameSettings.keepScreenOn;
    });
  }

  void _applyKeepScreenOn() {
    if (GameSettings.keepScreenOn) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('settings')),
        titleTextStyle: const TextStyle(
          fontFamily: AssetPaths.fontAngduIpsul140,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Column(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionTitle(
                icon: Icons.phone_android,
                title: context.tr('sectionScreen'),
              ),
              _MuteSwitch(
                label: context.tr('keepScreenOn'),
                value: _keepScreenOn,
                onChanged: (v) {
                  setState(() {
                    _keepScreenOn = v;
                    GameSettings.keepScreenOn = v;
                    _applyKeepScreenOn();
                  });
                },
              ),
              Divider(color: Colors.white.withValues(alpha: 0.3), height: 1),
              _SectionTitle(
                icon: Icons.volume_up,
                title: context.tr('sectionSound'),
              ),
              _VolumeSlider(
                label: context.tr('bgmVolume'),
                value: _bgmVolume,
                enabled: !_bgmMuted,
                onChanged: (v) {
                  setState(() {
                    _bgmVolume = v;
                    GameSettings.bgmVolume = v;
                    SoundManager.applyBgmVolume();
                  });
                },
              ),
              _MuteSwitch(
                label: context.tr('bgm'),
                value: _bgmMuted,
                onChanged: (v) {
                  setState(() {
                    _bgmMuted = v;
                    GameSettings.bgmMuted = v;
                    if (v) {
                      SoundManager.pauseBgm();
                    } else {
                      SoundManager.playBgmIfUnmuted();
                    }
                  });
                },
              ),
              _VolumeSlider(
                label: context.tr('sfxVolume'),
                value: _sfxVolume,
                enabled: !_sfxMuted,
                onChanged: (v) {
                  setState(() {
                    _sfxVolume = v;
                    GameSettings.sfxVolume = v;
                  });
                },
              ),
              _MuteSwitch(
                label: context.tr('sfx'),
                value: _sfxMuted,
                onChanged: (v) {
                  setState(() {
                    _sfxMuted = v;
                    GameSettings.sfxMuted = v;
                  });
                },
              ),
              Divider(color: Colors.white.withValues(alpha: 0.3), height: 1),
              _SectionTitle(icon: Icons.star, title: context.tr('rateApp')),
              ListTile(
                leading: const Icon(Icons.star_border, color: Colors.amber),
                title: Text(
                  context.tr('rateApp'),
                  style: const TextStyle(
                    fontFamily: AssetPaths.fontAngduIpsul140,
                    fontSize: 16,
                  ),
                ),
                onTap: () async {
                  final result = await InAppReviewService.openStoreListing();
                  if (!context.mounted) return;
                  if (result == false) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.tr('rateAppAfterRelease'))),
                    );
                  }
                },
              ),
              Divider(color: Colors.white.withValues(alpha: 0.3), height: 1),
              _SectionTitle(icon: Icons.public, title: context.tr('language')),
              ListTile(
                title: Text(
                  context.tr('langKo'),
                  style: const TextStyle(
                    fontFamily: AssetPaths.fontAngduIpsul140,
                    fontSize: 16,
                  ),
                ),
                trailing: context.locale == const Locale('ko')
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () => context.setLocale(const Locale('ko')),
              ),
              ListTile(
                title: Text(
                  context.tr('langEn'),
                  style: const TextStyle(
                    fontFamily: AssetPaths.fontAngduIpsul140,
                    fontSize: 16,
                  ),
                ),
                trailing: context.locale == const Locale('en')
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () => context.setLocale(const Locale('en')),
              ),
              ListTile(
                title: Text(
                  context.tr('langJa'),
                  style: const TextStyle(
                    fontFamily: AssetPaths.fontAngduIpsul140,
                    fontSize: 16,
                  ),
                ),
                trailing: context.locale == const Locale('ja')
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () => context.setLocale(const Locale('ja')),
              ),
              ListTile(
                title: Text(
                  context.tr('langZhCN'),
                  style: const TextStyle(
                    fontFamily: AssetPaths.fontAngduIpsul140,
                    fontSize: 16,
                  ),
                ),
                trailing: context.locale == const Locale('zh', 'CN')
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () => context.setLocale(const Locale('zh', 'CN')),
              ),
              ListTile(
                title: Text(
                  context.tr('langZhTW'),
                  style: const TextStyle(
                    fontFamily: AssetPaths.fontAngduIpsul140,
                    fontSize: 16,
                  ),
                ),
                trailing: context.locale == const Locale('zh', 'TW')
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () => context.setLocale(const Locale('zh', 'TW')),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
            Icon(icon, size: 20, color: Colors.grey),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: const TextStyle(
              fontFamily: AssetPaths.fontAngduIpsul140,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
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
  });

  final String label;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        label,
        style: const TextStyle(
          fontFamily: AssetPaths.fontAngduIpsul140,
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
        child: Slider(value: value, onChanged: enabled ? onChanged : null),
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
        color: value ? Colors.grey : null,
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontFamily: AssetPaths.fontAngduIpsul140,
          fontSize: 16,
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}
