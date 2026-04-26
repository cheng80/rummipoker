import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../resources/asset_paths.dart';
import '../widgets/phone_frame_scaffold.dart';
import 'home_entry_widgets.dart';

class ArchiveView extends StatefulWidget {
  const ArchiveView({super.key, this.debugScrollPreset});

  final String? debugScrollPreset;

  @override
  State<ArchiveView> createState() => _ArchiveViewState();
}

class _ArchiveViewState extends State<ArchiveView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _applyDebugScrollPreset();
  }

  void _applyDebugScrollPreset() {
    if (!kDebugMode || widget.debugScrollPreset != 'bottom') return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 150), () {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PhoneFrameScaffold(
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '기록실',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AssetPaths.fontNexonLv2Gothic,
                fontSize: 38,
                color: Colors.white.withValues(alpha: 0.96),
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '기록, 수집, 통계 흐름을 나눠 둘 전용 화면의 첫 구조입니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            const HomeSection(
              title: '기록',
              subtitle: '플레이 결과와 최근 런 요약을 모아 둘 자리',
              child: Column(
                children: [
                  HomeSnapshotCard(
                    title: '예정 내용',
                    summary: '최근 런 결과, 최고 기록, 스테이지 도달 정보를 이 구역에 모읍니다.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const HomeSection(
              title: '수집',
              subtitle: '해금 요소와 카드성 데이터를 정리할 자리',
              child: Column(
                children: [
                  HomeSnapshotCard(
                    title: '예정 내용',
                    summary: '해금 카드, 발견 규칙, 수집 진행을 분리해 보여 줄 예정입니다.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const HomeSection(
              title: '통계',
              subtitle: '점수 흐름과 선택 패턴을 보는 자리',
              child: Column(
                children: [
                  HomeSnapshotCard(
                    title: '예정 내용',
                    summary: '평균 점수, 족보 빈도, 리롤/구매 경향 같은 누적 통계를 둘 예정입니다.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
