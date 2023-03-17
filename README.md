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

* **achievements**: this is the definition for the [achievements](https://github.com/gurtt/achievements/blob/main/source/achievements.lua#L14) in your game. These definitions must match the current schema version (except for the `value` field, which is ignored). Saved data will be updated to match this definition, including creating new achievements and deleting old ones.
* **minimumSchemaVersion**: if you've published your game with a previous version of the achievements library and now you're using a newer version, you'll need to specify this argument. It should be the oldest schema version number you published the game with. The library will handle updating any old saved data to the newest format. If you don't specify this argument, the library will consider any old data invalid and it will be discarded next time data is saved.

Once you've initialised the library, you can call methods to update your achievements:

* **grant()** will set a boolean achievement's value to `true`.
* **increment(number)** will increaase a numeric achievement's value by `number`, or `1` if not specified.
* **isGranted()** will check if an achievement has been granted.
* **set()** can be used to set an achievement's value to any specific (valid) value.
* **get()** can be used to get an achievement. This returns the whole achievement, not just the value.
* **save()** will persist your achievements data to storage. It's a good idea to call this during game lifecycle events.

While `set()` techically allows you to do things like un-grant boolean achievements and decrease numeric achievements, this is not encouraged as achievement progress shouldn't generally go backwards. Don't add mechanisms to clear achievements for players; achievements can be reset by deleting the game data in Settings.

## API

The source code is fully documented and should provide adequate guidance in your favourite editor.

