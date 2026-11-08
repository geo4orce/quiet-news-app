import 'dart:convert';
import 'dart:io';

// This proof reads a permanent day so the source-link check also works on quiet days.
const proofDate = '2026-11-06';

typedef Source = ({String name, Uri url});
typedef Story = ({String headline, String body, List<Source> sources});
typedef Publication = ({DateTime day, List<Story> stories});

Never _invalid() => throw const FormatException('Invalid publication');

Map<String, dynamic> _object(Object? value, Set<String> fields) {
  if (value is! Map<String, dynamic> ||
      value.length != fields.length ||
      !fields.containsAll(value.keys)) {
    _invalid();
  }
  return value;
}

String _text(Object? value) {
  if (value is! String || value.trim().isEmpty) _invalid();
  return value;
}

DateTime _instant(Object? value) {
  final instant = DateTime.tryParse(_text(value));
  if (instant == null || !instant.isUtc || instant.toIso8601String() != value) {
    _invalid();
  }
  return instant;
}

Source _source(Object? value) {
  final source = _object(value, {'name', 'url'});
  final url = Uri.tryParse(_text(source['url']));
  if (url == null || url.scheme != 'https' || url.host.isEmpty) _invalid();
  return (name: _text(source['name']), url: url);
}

Story _story(Object? value) {
  final story = _object(value, {'headline', 'body', 'sources'});
  final sources = story['sources'];
  if (sources is! List || sources.isEmpty) _invalid();
  return (
    headline: _text(story['headline']),
    body: _text(story['body']),
    sources: sources.map(_source).toList(),
  );
}

Publication parseSavedDay(String json, String requestedDate) {
  final data = _object(jsonDecode(json), {
    'edition_date',
    'published_at',
    'expires_at',
    'stories',
  });
  final day = DateTime.tryParse('${requestedDate}T00:00:00.000Z');
  if (data['edition_date'] != requestedDate ||
      day == null ||
      day.toIso8601String() != '${requestedDate}T00:00:00.000Z') {
    _invalid();
  }
  if (!_instant(data['expires_at']).isAfter(_instant(data['published_at']))) {
    _invalid();
  }
  final stories = data['stories'];
  if (stories is! List || stories.length > 20) _invalid();
  return (day: day, stories: stories.map(_story).toList());
}

Future<Publication> loadProofDay() async {
  final client = HttpClient();
  try {
    return await _fetch(client).timeout(const Duration(seconds: 20));
  } finally {
    client.close(force: true);
  }
}

Future<Publication> _fetch(HttpClient client) async {
  final request = await client.getUrl(
    Uri.https('quietnews.ai', '/data/$proofDate.json'),
  );
  final response = await request.close();
  if (response.statusCode != HttpStatus.ok) {
    throw const HttpException('Day unavailable');
  }
  return parseSavedDay(await utf8.decoder.bind(response).join(), proofDate);
}
