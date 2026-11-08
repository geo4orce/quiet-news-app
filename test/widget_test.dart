import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiet_news/main.dart';
import 'package:quiet_news/publication.dart';

const source = {'name': 'Example source', 'url': 'https://example.org/story'};

String fixture(List<Object> stories) => jsonEncode({
  'edition_date': proofDate,
  'published_at': '2026-11-07T09:08:13.553Z',
  'expires_at': '2026-11-08T10:00:00.000Z',
  'stories': stories,
});

Map<String, Object> story(Map<String, String> link) => {
  'headline': 'A saved headline',
  'body': 'A saved story.',
  'sources': [link],
};

void main() {
  testWidgets('the reader opens the HTTPS source from the saved story', (
    tester,
  ) async {
    Uri? opened;
    await tester.pumpWidget(
      QuietNews(
        load: () async => parseSavedDay(fixture([story(source)]), proofDate),
        open: (url) async {
          opened = url;
          return true;
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('A saved story.'), findsOneWidget);
    await tester.tap(find.text('Example source'));
    expect(opened.toString(), source['url']);
  });

  testWidgets('a failed load can retry and show a validated quiet day', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      QuietNews(
        load: () async {
          if (++attempts == 1) throw const FormatException();
          return parseSavedDay(fixture([]), proofDate);
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Quiet.'), findsNothing);
    expect(find.text('Error.'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Quiet.'), findsOneWidget);
  });

  test('refuses a different day and a non-HTTPS source', () {
    expect(
      () => parseSavedDay(fixture([]), '2026-11-05'),
      throwsFormatException,
    );
    expect(
      () => parseSavedDay(
        fixture([
          story({...source, 'url': 'file:///example'}),
        ]),
        proofDate,
      ),
      throwsFormatException,
    );
  });
}
