import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_cinema/controller/lists_provider.dart';
import 'package:pocket_cinema/model/media.dart';
import 'package:pocket_cinema/model/search_navigation.dart';
import 'package:pocket_cinema/view/common_widgets/horizontal_media_list.dart';
import 'package:pocket_cinema/view/common_widgets/horizontal_media_list_shimmer.dart';
import 'package:pocket_cinema/view/common_widgets/shimmer.dart';

class ToWatchList extends ConsumerWidget {
  const ToWatchList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AsyncValue<List<Media>> toWatchList = ref.watch(toWatchListProvider);

    return toWatchList.when(
      data: (data) {
        if (data.isEmpty) {
          return Column(
            children: [
              const Text(
                "This list is empty.",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "Start searching content.",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  ),
                ),
              ElevatedButton(
                onPressed: () {
                  navigateToSearchPage(context);
                },
                child: const Text("Search"),
              ),
            ],
          );
        } else {
          return HorizontalMediaList(
            name: "In your pocket to Watch",
            media: data,
          );
        }
      },
      loading: () => const ShimmerEffect(child: HorizontalMediaListShimmer()),
      error: (error, stack) => Text(error.toString()),
    );
  }
}
