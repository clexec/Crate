# Crate Music — Music App with Auth, Player, Search & Library (YM-API + YouTubeKit)

## What We're Building

A complete iOS music streaming app called **Crate Music** with a warm brown color palette. Full authentication (Apple, Google, Email), full-track music playback via native Swift sources (YM-API for Yandex Music, YouTubeKit for YouTube), personalized Home feed, Search with genres, Your Library, comments on tracks, queue management, and App Store-ready polish.

## Design & Visual Style

- **Color palette**: Warm browns — #D4A574 accent, #6B4423 secondary, #000000 background, #B3B3B3 text
- **Dark theme by default** with a light theme option in Settings
- **iOS native glass effects** — .ultraThinMaterial on tab bar, mini-player, and cards; .glassEffect() on iOS 26
- **Real SF Symbols icons** throughout — no drawn images, no emoji icons
- **Smooth spring animations** for player transitions and button presses
- **Minimalist layout** — album artwork is the hero on every screen

## Authentication

- Auth screen with Crate Music logo and three sign-in buttons
- **Sign in with Apple** — native AuthenticationServices, tokens in Keychain
- **Sign in with Google** — GoogleSignIn SDK ready with setup instructions for your client ID
- **Email/Password** — registration with password strength indicator, CryptoKit hashing, CoreData persistence
- **Forgot Password** — email entry, reset flow, new password creation
- **Profile** — display name, avatar, provider tracking, sign out with data cleanup

## Home Screen

- **Discover Weekly** — weekly recommendations card
- **Release Radar** — new releases from followed artists
- **Daily Mixes** — genre/mood playlists as horizontal scrolling cards
- **Recently Played** — horizontal scroll with album art
- **"Because you listened to..."** — recommendation cards based on history
- **Popular albums & playlists** — large hero cards

## Search Screen

- Active search bar with real-time results
- Genre category grid with colored tiles and SF Symbol icons
- Search results grouped by tracks, artists, albums, playlists
- Search history with swipe-to-delete

## Your Library

- Liked Songs, Saved Albums, Your Playlists, Following Artists
- Filters and sorting by name, recently added, duration

## Music Player

- **Mini Player** — above tab bar when playing, shows track/artist/art, Play/Pause and Skip
- **Full Player** — large animated artwork, all controls (Shuffle, Previous, Play/Pause, Next, Repeat), draggable progress bar, volume slider, audio visualizer, Like/Comment/Queue/Share buttons

## Details & Extras

- **Artist page** — header image, top tracks, albums, related artists, Follow button
- **Album page** — artwork header, metadata, full track list
- **Comments** — add/edit/delete per track, stored in CoreData
- **Context Menu** — long-press any track for Add to Playlist, Like, Go to Artist, Share, etc.
- **Queue** — drag-and-drop reorder, swipe to remove
- **Share** — system share sheet for tracks, albums, artists
- **Settings** — theme toggle, notifications, cache management, sign out

## Real Data Sources

- **YM-API (Yandex Music)** — full tracks, albums, artists (requires Yandex Plus subscription token)
- **YouTubeKit (YouTube)** — search and full audio playback, no API key required

## Architecture

- **MVVM + Repository Pattern + Dependency Injection**
- **50-55 files** across Models, ViewModels, Views, Services, Repositories, Managers, Utilities
- **Combine** for reactive state, **async/await** for networking
- **CoreData** for user data, **Keychain** for tokens, **UserDefaults** for preferences
- No stubs, no placeholders, no demo data — every file has real working code

## App Icon

Warm brown gradient background with a centered minimalist sound-wave symbol — sophisticated, modern, matching the brown palette.