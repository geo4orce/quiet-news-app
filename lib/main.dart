import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import 'publication.dart';

const paper = Color(0xfff4f1e9);
const ink = Color(0xff18211d);
const accent = Color(0xff0c5852);

void main() => runApp(const QuietNews());

class QuietNews extends StatelessWidget {
  const QuietNews({
    super.key,
    this.load = loadProofDay,
    this.open = openSource,
  });

  final Future<Publication> Function() load;
  final Future<bool> Function(Uri) open;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Quiet News',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: accent, primary: accent),
      scaffoldBackgroundColor: paper,
    ),
    home: Reader(load: load, open: open),
  );
}

Future<bool> openSource(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

class Reader extends StatefulWidget {
  const Reader({super.key, required this.load, required this.open});
  final Future<Publication> Function() load;
  final Future<bool> Function(Uri) open;

  @override
  State<Reader> createState() => _ReaderState();
}

class _ReaderState extends State<Reader> {
  late Future<Publication> day = widget.load();

  Future<void> open(Uri url) async {
    try {
      if (await widget.open(url)) return;
    } catch (_) {
      // A device may have no application registered to handle web links.
    }
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open source.')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: SvgPicture.asset(
                  'assets/quiet-news.svg',
                  width: 42,
                  height: 42,
                  semanticsLabel: 'Quiet News',
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 20),
              FutureBuilder<Publication>(
                future: day,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Align(
                      alignment: Alignment.centerLeft,
                      child: CircularProgressIndicator(
                        semanticsLabel: 'Loading news',
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Error.'),
                        TextButton(
                          onPressed: () {
                            final nextDay = widget.load();
                            setState(() {
                              day = nextDay;
                            });
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    );
                  }
                  final publication = snapshot.requireData;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          MaterialLocalizations.of(
                            context,
                          ).formatFullDate(publication.day),
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 30,
                            color: ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (publication.stories.isEmpty) const Text('Quiet.'),
                      for (final story in publication.stories) ...[
                        Semantics(
                          header: true,
                          child: Text(
                            story.headline,
                            style: const TextStyle(
                              fontFamily: 'serif',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: ink,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          story.body,
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 18,
                            height: 1.5,
                            color: ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          children: [
                            for (final source in story.sources)
                              TextButton(
                                onPressed: () => open(source.url),
                                child: Text(source.name),
                              ),
                          ],
                        ),
                        const Divider(height: 36),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
