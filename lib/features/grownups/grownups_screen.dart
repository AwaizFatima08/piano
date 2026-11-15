import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../ads/ads.dart';
import '../../app/services.dart';

/// Settings for parents. Reached only through the gear + parent gate. The
/// app's only ad (a banner) lives here, never on the play screen.
class GrownupsScreen extends StatefulWidget {
  const GrownupsScreen({super.key, required this.services});
  final Services services;

  @override
  State<GrownupsScreen> createState() => _GrownupsScreenState();
}

class _GrownupsScreenState extends State<GrownupsScreen> {
  Settings get s => widget.services.settings;
  bool _privacyOptions = false;

  @override
  void initState() {
    super.initState();
    s.addListener(_rebuild);
    widget.services.ads.privacyOptionsRequired.then((v) {
      if (mounted) setState(() => _privacyOptions = v);
    });
  }

  @override
  void dispose() {
    s.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  Future<void> _open(String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open $url')));
    }
  }

  Widget _segments<T>(String title, T value, Map<T, String> options, void Function(Settings, T) set) {
    return ListTile(
      title: Text(title),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SegmentedButton<T>(
          showSelectedIcon: false,
          segments: [for (final e in options.entries) ButtonSegment(value: e.key, label: Text(e.value))],
          selected: {value},
          onSelectionChanged: (v) => s.update((x) => set(x, v.first)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grown-ups')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    title: const Text('Loudest volume allowed'),
                    subtitle: Slider(
                      key: const Key('max-volume'),
                      value: s.maxVolume,
                      min: 0.2,
                      divisions: 16,
                      label: '${(s.maxVolume * 100).round()} %',
                      onChanged: (v) => s.update((x) => x.maxVolume = v),
                    ),
                    trailing: Text('${(s.maxVolume * 100).round()} %'),
                  ),
                  _segments<int>('Number of keys', s.keyCount, {5: '5 big keys', 8: '8 keys'}, (x, v) => x.keyCount = v),
                  _segments<KeyLabels>('On the keys', s.labels, {
                    KeyLabels.animals: '🐱 Animals',
                    KeyLabels.letters: 'C D E',
                    KeyLabels.solfa: 'Do Re Mi',
                    KeyLabels.colours: 'Colours only',
                  }, (x, v) => x.labels = v),
                  _segments<LightsLevel>('Lights', s.lights, {
                    LightsLevel.party: '✨ Party',
                    LightsLevel.gentle: '🌙 Gentle',
                    LightsLevel.calm: 'Calm',
                  }, (x, v) => x.lights = v),
                  SwitchListTile(
                    title: const Text('Hide the mode buttons'),
                    subtitle: const Text('Keeps the child in the current mode'),
                    value: s.hideModes,
                    onChanged: (v) => s.update((x) => x.hideModes = v),
                  ),
                  SwitchListTile(
                    title: const Text('Keep the screen on while playing'),
                    value: s.keepAwake,
                    onChanged: (v) => s.update((x) => x.keepAwake = v),
                  ),
                  const Divider(),
                  const ListTile(
                    title: Text('Tip: pin the app'),
                    subtitle: Text(
                      'Android "App pinning" (Settings → Security) keeps a toddler inside Rainbow Keys. '
                      'Lights are soft fades, never fast strobes; choose Gentle or Calm for sensitive eyes.',
                    ),
                  ),
                  ListTile(
                    title: const Text('Privacy policy'),
                    subtitle: const Text('No login, no accounts. Settings stay on this device.'),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _open(kPrivacyUrl),
                  ),
                  ListTile(
                    title: const Text('Terms of use'),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _open(kTermsUrl),
                  ),
                  if (_privacyOptions)
                    ListTile(
                      title: const Text('Ad privacy options'),
                      onTap: widget.services.ads.showPrivacyOptions,
                    ),
                  const ListTile(
                    title: Text('Rainbow Keys $kAppVersion'),
                    subtitle: Text('Made by HomiLabs. All sounds are made by us, from scratch.'),
                  ),
                ],
              ),
            ),
            AdBannerSlot(ads: widget.services.ads, placement: AdPlacement.grownupsBanner),
          ],
        ),
      ),
    );
  }
}
