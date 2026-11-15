#!/usr/bin/env python3
"""Insert the Rainbow Keys blocks into index.html, privacy.html and terms.html.

Usage: add_rainbowkeys.py <dir-with-the-three-pages>
Works on the local homilabs_tools site/ copy and on copies downloaded from the live site, so only
Rainbow Keys is added to the live pages. Running it twice changes nothing.
Also copy web/img/rainbowkeys/icon.svg to <site>/img/rainbowkeys/icon.svg.
"""
import re
import sys
from pathlib import Path

DATE = '15 November 2026'

CARD = '''    <!-- ===== TOOL: Rainbow Keys ===== -->
    <article class="tool" id="rainbowkeys" style="--tool:#9b5cff">
      <div class="tool-head">
        <img src="img/rainbowkeys/icon.svg" alt="Rainbow Keys app icon" width="64" height="64">
        <div>
          <h3>Rainbow Keys: Toddler Piano</h3>
          <p class="tagline">Big rainbow keys, party lights and happy sounds</p>
        </div>
      </div>
      <p>A first piano for little hands: every key glows, the party bulbs ripple and stars fly up with each note.</p>
      <ul>
        <li>Five modes: piano, drums, silly sounds, magic nursery songs and a find-the-shining-key game</li>
        <li>Volume slider plus a grown-up limit for the loudest volume; soft lights, never fast strobes</li>
        <li>No login, no accounts; settings live behind a parent gate</li>
      </ul>
      <div class="chips">
        <span class="chip">Android</span>
        <span class="chip">Toddlers</span>
        <span class="chip">No login</span>
      </div>
      <div class="tool-foot">
        <span class="status soon">Coming soon to Google Play</span>
        <span class="tool-links"><a href="privacy.html#rainbowkeys">Privacy</a><a href="terms.html#rainbowkeys">Terms</a></span>
      </div>
    </article>
    <!-- ===== END TOOL: Rainbow Keys ===== -->

'''

TOC = '      <li><a href="#rainbowkeys">Rainbow Keys: Toddler Piano</a></li>\n'

PRIVACY = f'''  <!-- ===== APP: Rainbow Keys ===== -->
  <section id="rainbowkeys" class="app-block">
    <h2><img src="img/rainbowkeys/icon.svg" alt="" width="36" height="36">Rainbow Keys: Toddler Piano</h2>
    <p class="meta">Android · package com.homilabs.rainbowkeys · Section updated {DATE} (version 1.0.0)</p>

    <p><strong>Rainbow Keys is made for young children and collects no personal information.</strong> There is no
      account, no sign-in, no chat and no analytics, and the app never asks a child to type anything. All sounds are made
      inside the app. Rainbow Keys is free and shows one small ad from <strong>Google AdMob</strong>, only on the
      grown-ups settings screen, which a child can reach only by holding the gear button and answering a sum.
      No ads ever appear on the play screen.</p>

    <table>
      <tr class="head"><th>What Rainbow Keys uses</th><th>Why</th><th>Leaves your phone?</th></tr>
      <tr><td>Settings: mode, instrument, song, volume and loudest-volume limit, number of keys, key labels, lights,
        hide-modes and keep-screen-on choices</td><td>So the app opens the way you left it. Saved on your phone only;
        removed when you clear the app's data or uninstall it.</td><td data-label="Leaves your phone: ">No</td></tr>
      <tr><td>Advertising (Google AdMob), grown-ups screen only</td><td>To show one banner. Every ad request is marked as
        coming from an app for children, so Google serves only <strong>non-personalised, family-safe (rated G)</strong>
        ads and does not build an advertising profile. The app does not use or send the device's advertising ID.
        Google may still receive the IP address, basic device and app information and ad interactions to deliver and
        measure the ad and to prevent fraud.</td><td data-label="Leaves your phone: ">Yes, to Google, only when the
        grown-ups screen is open</td></tr>
    </table>

    <h3>Permissions</h3>
    <p>Only internet and network state, for the ad on the grown-ups screen. Rainbow Keys does not request location,
      contacts, camera, microphone, storage or phone access, and it does not use the advertising ID.</p>

    <h3>Children</h3>
    <p>Rainbow Keys is designed for children under 5 and follows Google Play's Families policy. We do not knowingly
      collect personal information from children. Links to this policy and to the terms are inside the grown-ups area,
      behind the parent gate.</p>

    <h3>Your choices</h3>
    <ul>
      <li>If you are in the European Economic Area, the UK or Switzerland, Google's consent form may appear; you can
        change your choice under <em>Grown-ups → Ad privacy options</em>.</li>
      <li>Clearing the app's data or uninstalling it removes all settings.</li>
    </ul>
    <p>Google's use of this data is covered by its own policy:
      <a href="https://policies.google.com/technologies/partner-sites">How Google uses information from sites or apps
      that use its services</a>.</p>
  </section>
  <!-- ===== END APP: Rainbow Keys ===== -->

'''

TERMS = f'''  <!-- ===== APP: Rainbow Keys ===== -->
  <section id="rainbowkeys" class="app-block">
    <h2><img src="img/rainbowkeys/icon.svg" alt="" width="36" height="36">Rainbow Keys: Toddler Piano</h2>
    <p class="meta">Additional terms for Rainbow Keys · updated {DATE}</p>

    <h3>Grown-ups in charge</h3>
    <p>Rainbow Keys is a free toy for young children to use with an adult nearby. Keep play sessions short, take breaks
      from the screen, and set a comfortable "Loudest volume allowed" in the grown-ups area. For small ears, keep the volume
      low, especially with headphones.</p>

    <h3>Lights</h3>
    <p>The lights glow and fade; they do not strobe. If a child is sensitive to flashing or moving light, choose
      <em>Gentle</em> or <em>Calm</em> lights in the grown-ups area, and stop using the app if you notice any discomfort.</p>

    <h3>Device care</h3>
    <p>Toddlers can drop or tap phones hard. Use a protective case and supervise play. You can use Android's
      "App pinning" to keep a child inside the app.</p>

    <h3>Music and sounds</h3>
    <p>All sounds are synthesized by the app. The tunes are traditional nursery songs in the public domain. The app, its
      artwork and its characters are original HomiLabs work.</p>
  </section>
  <!-- ===== END APP: Rainbow Keys ===== -->

'''


def insert_before(text, anchor, block, page):
    i = text.find(anchor)
    if i < 0:
        sys.exit(f'{page}: anchor not found: {anchor!r}')
    line_start = text.rfind('\n', 0, i) + 1
    return text[:line_start] + block + text[line_start:]


def main(folder):
    d = Path(folder)

    p = d / 'index.html'
    t = p.read_text()
    if 'id="rainbowkeys"' not in t:
        t = insert_before(t, '<!-- ===== ADD A NEW TOOL =====', CARD, p)
        p.write_text(t)

    for name, section, anchor in (
        ('privacy.html', PRIVACY, '<!-- ===== ADD A TOOL: copy the Beam block above, change id="SLUG", the icon, name, package'),
        ('terms.html', TERMS, '<!-- ===== ADD A TOOL: copy the Beam block above, change id="SLUG", the icon, name and the tool'),
    ):
        p = d / name
        t = p.read_text()
        if 'id="rainbowkeys"' in t:
            continue
        t = insert_before(t, '<!-- ADD A TOOL: <li><a href="#SLUG">NAME</a></li> -->', TOC, p)
        t = insert_before(t, anchor, section, p)
        t = re.sub(r'Last updated \d{1,2} [A-Z][a-z]+ \d{4}', f'Last updated {DATE}', t, count=1)
        p.write_text(t)
    print(f'{folder}: Rainbow Keys present in all three pages')


if __name__ == '__main__':
    main(sys.argv[1] if len(sys.argv) > 1 else 'site')
