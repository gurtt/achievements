# Achievements for Playdate

A fully-featured and ready-to-use achievement system for Playdate games.

## Concepts

This project provides a framework for creating and managing achievements within a Playdate game. It supports two types of achievements: boolean and numeric.

**Boolean achievements** have two possible states: granted or not granted. They're useful for tracking things like progression through a story or other one-off events (eg. "Squash your first bug").

**Numeric achievements** are the state of an integer quanity against a finite maximum quanity. They're useful for tracking things like actions done repeatedly or finite collections (eg. "Squash 100 bugs" or "Squash one of every kind of bug").

## Installation

The best way to install and update achievements is using [toybox](https://codeberg.org/DidierMalenfant/toybox.py). To install achievements, run:

```
toybox add gurtt/achievements
toybox update
```

## Usage

First, initialise achievements by calling `init()` near the start of your game. You'll need to provide some info up front:

* **achievements**: this is the definition for the achievements in your game. These definitions must match the current schema version (except for the `value` field, which is ignored). Saved data will be updated to match this definition, including creating new achievements and deleting old ones.

Once you've initialised the library, you can call methods to update your achievements:

* **grant()** will set a boolean achievement's value to `true`.
* **increment(number)** will increaase a numeric achievement's value by `number`, or `1` if not specified.
* **isGranted()** will check if an achievement has been granted.
* **set()** can be used to set an achievement's value to any specific (valid) value.
* **get()** can be used to get an achievement. This returns the whole achievement, not just the value.
* **save()** will persist your achievements data to storage. It's a good idea to call this during game lifecycle events.

While `set()` techically allows you to do things like un-grant boolean achievements and decrease numeric achievements, this is not encouraged as achievement progress shouldn't generally go backwards. Don't add mechanisms to clear achievements for players; achievements can be reset by deleting the game data in Settings.

### Updating achievements

Players expect achievements to be consistent and stable in a game, even between updates or other changes, even if you update your game or add new content. The achievements library relies on the `id` of your achievements to keep track of them and tell them apart, so keep these stable. IDs must be unique, but only within your game.

The definitions you pass to `init` are authoritative. If the library detects saved achievements that aren't defined, they will be discarded. Similarly, if the saved data for an achievement doesn't match a definition (for example, there is a saved boolean achievement that you've since redefined as a numeric achievement), it will be discarded.

If you change the version of the library you use in your game, and that version uses a different achievements schema, any saved data with a different schema version will be discarded unless you enable migration. The schema version aligns with the major version of this library.

Migration is enabled when you specify a `minimumSchemaVersion` in `init`. This should be the earliest schema version your game was shared with. For example:

* If you made your game using v2.0.1, and you later publish an update using v4.1.0, you should set `minimumSchemaVersion` to 2.
* If you made your game using v2.0.1, and you later publish an update using v2.5.0, you don't need to set a `minimumSchemaVersion`.

When you enable migration, the achievements library will automatically handle updating any saved data in old versions (as long as they're at or above the minimum version). The previous advice about using consistent IDs still applies. Data will always be saved in the latest format for the version of the library you're using, so you can't go backwards.

You should only enable migration if you need to, and you should use the highest minimum version you can. This helps to cut down on the size of your game by excluding any unneeded migration code (to be verified).

## API

The source code is fully documented and should provide adequate guidance in your favourite editor.

