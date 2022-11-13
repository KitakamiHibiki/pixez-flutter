import 'dart:math';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pixez/component/pixiv_image.dart';
import 'package:pixez/lighting/lighting_store.dart';
import 'package:pixez/main.dart';
import 'package:pixez/models/illust.dart';
import 'package:pixez/network/api_client.dart';
import 'package:pixez/page/river/river_provider.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

final illustsProvider =
    StateNotifierProvider<IllustListNotifier, List<Illusts>>((ref) {
  return IllustListNotifier(
      ref, ApiSource(futureGet: () => apiClient.getRecommend()));
});

class RiverPage extends HookConsumerWidget {
  @override
  Widget build(Object context, WidgetRef ref) {
    final illusts = ref.watch(illustsProvider);
    final scrollController = useScrollController();
    useEffect(() {
      scrollController.addListener(() {
        if (scrollController.hasClients) {
          if (scrollController.position.atEdge) {
            if (scrollController.position.pixels != 0) {
              ref.read(illustsProvider.notifier).next();
            }
          }
        }
      });
      ref.read(illustsProvider.notifier).fetch();
    }, [scrollController]);
    // ref.read(illustsProvider.notifier).fetch();

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: _buildTopIndicator(),
        ),
        SliverWaterfallFlow(
          gridDelegate: _buildGridDelegate(ref.context),
          delegate: _buildSliverChildBuilderDelegate(ref.context, illusts),
        )
      ],
    );
  }

  Widget _buildTopIndicator() {
    return Container(
      height: 60.0,
      child: Center(
        child: Text(
          "Top",
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  SliverChildBuilderDelegate _buildSliverChildBuilderDelegate(
      BuildContext context, List<Illusts> illusts) {
    return SliverChildBuilderDelegate((BuildContext context, int index) {
      final illust = illusts[index];
      return Card(
        child: PixivImage(illust.imageUrls.medium),
      );
    }, childCount: illusts.length);
  }

  SliverWaterfallFlowDelegate _buildGridDelegate(context) {
    var count = 2;
    if (userSetting.crossAdapt) {
      count = _buildSliderValue(context);
    } else {
      count = (MediaQuery.of(context).orientation == Orientation.portrait)
          ? userSetting.crossCount
          : userSetting.hCrossCount;
    }
    return SliverWaterfallFlowDelegateWithFixedCrossAxisCount(
      crossAxisCount: count,
    );
  }

  int _buildSliderValue(context) {
    final currentValue =
        (MediaQuery.of(context).orientation == Orientation.portrait
                ? userSetting.crossAdapterWidth
                : userSetting.hCrossAdapterWidth)
            .toDouble();
    var nowAdaptWidth = max(currentValue, 50.0);
    nowAdaptWidth = min(nowAdaptWidth, 2160.0);
    final screenWidth = MediaQuery.of(context).size.width;
    final result = max(screenWidth / nowAdaptWidth, 1.0).toInt();
    return result;
  }
}