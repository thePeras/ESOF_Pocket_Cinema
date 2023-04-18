import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:pocket_cinema/model/media.dart';
import 'package:pocket_cinema/view/common_widgets/add_button.dart';
import 'package:pocket_cinema/view/common_widgets/check_button.dart';
import 'package:pocket_cinema/view/search/widgets/search_result.dart';

import '../../testable_widget.dart';

void main() {
  group('SearchResult widget', () {
    const media = Media(
      '1',
      'Media Name',
      'assets/images/poster_image.jpg',
      'assets/images/background_image.jpg',
      '',
      '',
      '',
      MediaType.movie,
    );

    testWidgets('should display media information', (WidgetTester tester) async {
      await mockNetworkImagesFor(() => tester.pumpWidget(testableWidget(const SearchResult(media: media))));

      expect(find.text(media.name), findsOneWidget);
      expect(find.text(media.description), findsOneWidget);

      final posterImageFinder = find.byWidgetPredicate((widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).image is DecorationImage &&
          ((widget.decoration as BoxDecoration).image as DecorationImage)
              .image
              .toString()
              .contains(media.posterImage));
      expect(posterImageFinder, findsOneWidget);
    });

    testWidgets('CheckButton and AddButton', (WidgetTester tester) async {
      await mockNetworkImagesFor(() => tester.pumpWidget(testableWidget(const SearchResult(media: media))));

      expect(find.byType(CheckButton), findsOneWidget);
      expect(find.byType(AddButton), findsOneWidget);
    });
  });
}